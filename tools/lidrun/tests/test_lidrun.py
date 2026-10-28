import fcntl
import os
from pathlib import Path
import signal
import subprocess
import tempfile
import time
import unittest

BINARY = Path(__file__).resolve().parents[1] / 'build/lidrun-test'


class LidrunTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.env = dict(os.environ, LIDRUN_TEST_DIR=str(self.root))
        self.write('setting', '0\n')
        self.write('ac', '1\n')
        self.write('battery', '80\n')
        self.processes = []

    def tearDown(self):
        for name in ['pause_auth', 'pause_guard', 'pause_ready', 'pause_commit']:
            self.write(name, '0\n')
        for process in self.processes:
            if process.poll() is None:
                process.terminate()
                try:
                    process.communicate(timeout=7)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.communicate()
        if (self.root / 'state').exists():
            (self.root / 'fail0').unlink(missing_ok=True)
            self.invoke('off')
        self.tmp.cleanup()

    def write(self, name, content):
        path = self.root / name
        pending = path.with_name(path.name + '.new')
        pending.write_text(content)
        pending.replace(path)

    def invoke(self, *args):
        return subprocess.run([str(BINARY), *args], env=self.env,
                              capture_output=True, text=True, timeout=30)

    def start(self, operation='on'):
        process = subprocess.Popen([str(BINARY), operation], env=self.env,
                                   stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                   text=True, start_new_session=True)
        self.processes.append(process)
        return process

    def on(self):
        result = self.invoke('on')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('lidrun: on', result.stdout)
        self.assertEqual((self.root / 'setting').read_text(), '1\n')
        return tuple(map(int, (self.root / 'pids').read_text().split()))

    def until(self, condition, timeout=8):
        end = time.monotonic() + timeout
        while time.monotonic() < end:
            if condition():
                return
            time.sleep(.025)
        self.fail('condition did not become true')

    def restored(self):
        self.until(lambda: (self.root / 'setting').read_text() == '0\n' and
                   not (self.root / 'state/journal').exists())

    def children(self, pid):
        output = subprocess.run(['/bin/ps', '-axo', 'pid=,ppid='],
                                capture_output=True, text=True).stdout
        return [int(row[0]) for line in output.splitlines()
                if len(row := line.split()) == 2 and int(row[1]) == pid]

    def alive(self, pid):
        result = subprocess.run(['/bin/ps', '-p', str(pid), '-o', 'stat='],
                                capture_output=True, text=True)
        return result.returncode == 0 and not result.stdout.strip().startswith('Z')

    def test_on_returns_with_detached_monitors_and_off_waits_for_exit(self):
        guardian, watchdog = self.on()
        time.sleep(1.2)
        self.assertTrue(self.alive(guardian))
        self.assertTrue(self.alive(watchdog))
        self.assertEqual((self.root / 'setting').read_text(), '1\n')
        for pid in [guardian, watchdog]:
            sid = subprocess.check_output(['/bin/ps', '-p', str(pid), '-o', 'sess='], text=True)
            self.assertTrue(sid.strip())
        result = self.invoke('off')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.restored()
        self.until(lambda: not self.alive(guardian) and not self.alive(watchdog))
        self.assertEqual(self.invoke('off').returncode, 0)

    def test_battery_start_and_ac_removal_continue(self):
        self.write('ac', '0\n')
        self.on()
        time.sleep(1.2)
        self.assertEqual((self.root / 'setting').read_text(), '1\n')
        self.assertEqual(self.invoke('off').returncode, 0)
        self.write('ac', '1\n')
        self.on()
        self.write('ac', '0\n')
        time.sleep(1.2)
        self.assertEqual((self.root / 'setting').read_text(), '1\n')

    def test_low_battery_restores_without_restarting(self):
        self.on()
        self.write('battery', '10\n')
        time.sleep(1.2)
        self.assertEqual((self.root / 'setting').read_text(), '1\n')
        self.write('ac', '0\n')
        self.restored()
        self.write('battery', '80\n')
        time.sleep(1.2)
        self.assertEqual((self.root / 'setting').read_text(), '0\n')

    def test_unsafe_initial_power_refused(self):
        for ac, battery in [('0\n', '10\n'), ('unknown\n', '80\n'), ('1\n', 'unknown\n')]:
            with self.subTest(ac=ac, battery=battery):
                self.write('ac', ac)
                self.write('battery', battery)
                self.assertEqual(self.invoke('on').returncode, 125)
                self.assertFalse((self.root / 'state/journal').exists())

    def test_unknown_power_or_external_setting_change_restores(self):
        for name in ['ac', 'battery', 'setting']:
            with self.subTest(name=name):
                self.write('ac', '1\n')
                self.write('battery', '80\n')
                self.on()
                self.write(name, '0\n' if name == 'setting' else 'unknown\n')
                self.restored()
                self.assertEqual(self.invoke('off').returncode, 0)

    def test_duplicate_on_preserves_active_generation(self):
        self.on()
        pids = (self.root / 'pids').read_text()
        self.assertEqual(self.invoke('on').returncode, 125)
        self.assertEqual((self.root / 'pids').read_text(), pids)
        self.assertEqual((self.root / 'setting').read_text(), '1\n')

    def test_off_on_race_is_serialized(self):
        self.on()
        off = subprocess.Popen([str(BINARY), 'off'], env=self.env, stdout=subprocess.PIPE,
                               stderr=subprocess.PIPE, text=True)
        self.processes.append(off)
        result = self.invoke('on')
        out, err = off.communicate(timeout=10)
        self.assertEqual(off.returncode, 0, err)
        self.assertIn(result.returncode, [0, 125], result.stderr)
        if result.returncode == 0:
            self.assertEqual((self.root / 'setting').read_text(), '1\n')
        else:
            self.restored()

    def test_initial_one_and_journal_free_off_preserve_foreign_setting(self):
        self.write('setting', '1\n')
        self.assertEqual(self.invoke('on').returncode, 125)
        self.assertEqual(self.invoke('off').returncode, 0)
        self.assertEqual(self.invoke('recover').returncode, 0)
        self.assertEqual((self.root / 'setting').read_text(), '1\n')

    def test_enable_failure_restores(self):
        self.write('fail1', '')
        self.assertEqual(self.invoke('on').returncode, 125)
        self.restored()

    def test_restore_failure_retains_journal_and_recover_retries(self):
        self.on()
        self.write('fail0', '')
        self.assertEqual(self.invoke('off').returncode, 125)
        self.assertTrue((self.root / 'state/journal').exists())
        self.assertEqual(self.invoke('on').returncode, 125)
        (self.root / 'fail0').unlink()
        self.assertEqual(self.invoke('recover').returncode, 0)
        self.restored()

    def test_each_monitor_sigkill_restores(self):
        for index in [0, 1]:
            with self.subTest(index=index):
                pids = self.on()
                os.kill(pids[index], signal.SIGKILL)
                self.restored()
                self.assertEqual(self.invoke('off').returncode, 0)
                self.until(lambda: not any(self.alive(pid) for pid in pids))

    def test_both_monitors_lost_off_recovers(self):
        guardian, watchdog = self.on()
        os.kill(guardian, signal.SIGSTOP)
        os.kill(watchdog, signal.SIGSTOP)
        os.kill(guardian, signal.SIGKILL)
        os.kill(watchdog, signal.SIGKILL)
        self.assertEqual(self.invoke('off').returncode, 0)
        self.restored()

    def test_monitor_term_restores(self):
        for index in [0, 1]:
            pids = self.on()
            os.kill(pids[index], signal.SIGTERM)
            self.restored()
            self.assertEqual(self.invoke('off').returncode, 0)

    def test_auth_failure_and_cancellation(self):
        self.write('auth_fail', '1\n')
        self.assertEqual(self.invoke('on').returncode, 125)
        self.write('auth_fail', '0\n')
        self.write('pause_auth', '1\n')
        process = self.start()
        self.until(lambda: (self.root / 'pause_auth.started').exists())
        process.terminate()
        process.communicate(timeout=7)
        self.assertEqual(process.returncode, 143)
        self.restored()

    def test_auth_ignoring_cancel_is_bounded(self):
        self.write('pause_auth', '1\n')
        self.write('auth_ignore_term', '1\n')
        process = self.start()
        self.until(lambda: (self.root / 'pause_auth.started').exists())
        auth = self.children(process.pid)[0]
        try:
            process.terminate()
            self.assertEqual(process.wait(timeout=7), 125)
        finally:
            os.kill(auth, signal.SIGKILL)
        _, stderr = process.communicate(timeout=3)
        self.assertIn('unconfirmed', stderr)
        self.restored()

    def test_off_and_recover_wait_for_auth_before_operation_deadline(self):
        for operation in ['off', 'recover']:
            with self.subTest(operation=operation):
                self.on()
                (self.root / 'pause_auth.started').unlink(missing_ok=True)
                self.write('pause_auth', '1\n')
                process = self.start(operation)
                self.until(lambda: (self.root / 'pause_auth.started').exists())
                # The test build's operation deadline is two seconds; auth has no deadline.
                time.sleep(2.3)
                self.assertIsNone(process.poll())
                self.assertEqual((self.root / 'setting').read_text(), '1\n')
                self.write('pause_auth', '0\n')
                stdout, stderr = process.communicate(timeout=7)
                self.assertEqual(process.returncode, 0, stderr)
                self.assertIn('lidrun: off', stdout)
                self.restored()

    def test_off_and_recover_auth_cancellation_preserves_active_monitors(self):
        for operation in ['off', 'recover']:
            with self.subTest(operation=operation):
                self.on()
                (self.root / 'pause_auth.started').unlink(missing_ok=True)
                self.write('pause_auth', '1\n')
                process = self.start(operation)
                self.until(lambda: (self.root / 'pause_auth.started').exists())
                process.terminate()
                process.communicate(timeout=7)
                self.assertEqual(process.returncode, 143)
                self.assertEqual((self.root / 'setting').read_text(), '1\n')
                self.write('pause_auth', '0\n')
                self.assertEqual(self.invoke('off').returncode, 0)

    def test_late_off_auth_after_bounded_cancellation_cannot_stop_monitors(self):
        for operation in ['off', 'recover']:
            with self.subTest(operation=operation):
                self.on()
                (self.root / 'pause_auth.started').unlink(missing_ok=True)
                self.write('pause_auth', '1\n')
                self.write('auth_ignore_term', '1\n')
                process = self.start(operation)
                self.until(lambda: (self.root / 'pause_auth.started').exists())
                auth = self.children(process.pid)[0]
                try:
                    process.terminate()
                    self.assertEqual(process.wait(timeout=7), 125)
                    self.assertTrue(self.alive(auth))
                    self.write('pause_auth', '0\n')
                    self.until(lambda: not self.alive(auth))
                    _, stderr = process.communicate(timeout=3)
                    self.assertIn('unconfirmed', stderr)
                    self.assertEqual((self.root / 'setting').read_text(), '1\n')
                    self.assertFalse((self.root / 'state/stop').exists())
                finally:
                    if self.alive(auth):
                        os.kill(auth, signal.SIGKILL)
                    self.write('pause_auth', '0\n')
                    self.write('auth_ignore_term', '0\n')
                self.assertEqual(self.invoke('off').returncode, 0)

    def test_off_cancel_during_control_lock_wait_does_not_stop_monitors(self):
        self.on()
        with (self.root / 'state/control').open('r+') as control:
            fcntl.flock(control, fcntl.LOCK_EX)
            process = self.start('off')
            self.until(lambda: bool(self.children(process.pid)))
            time.sleep(.2)
            process.terminate()
            process.communicate(timeout=7)
            self.assertEqual(process.returncode, 143)
            self.assertFalse((self.root / 'state/stop').exists())
        self.assertEqual((self.root / 'setting').read_text(), '1\n')
        self.assertEqual(self.invoke('off').returncode, 0)

    def test_off_timeout_during_control_lock_wait_does_not_stop_monitors(self):
        guardian, watchdog = self.on()
        with (self.root / 'state/control').open('r+') as control:
            fcntl.flock(control, fcntl.LOCK_EX)
            process = self.start('off')
            self.until(lambda: bool(self.children(process.pid)))
            helper = self.children(process.pid)[0]
            self.assertEqual(process.wait(timeout=8), 125)
            try:
                self.assertFalse(self.alive(helper))
            finally:
                fcntl.flock(control, fcntl.LOCK_UN)
                self.until(lambda: not self.alive(helper))
            stdout, stderr = process.communicate(timeout=3)
            self.assertNotIn('lidrun: off', stdout)
            self.assertIn('unconfirmed', stderr)
        time.sleep(.3)
        self.assertEqual((self.root / 'setting').read_text(), '1\n')
        self.assertFalse((self.root / 'state/stop').exists())
        self.assertTrue(self.alive(guardian))
        self.assertTrue(self.alive(watchdog))
        self.assertEqual(self.invoke('off').returncode, 0)

    def test_cancel_after_enable_before_ready(self):
        self.write('pause_ready', '1\n')
        process = self.start()
        self.until(lambda: (self.root / 'pause_ready.started').exists())
        self.assertEqual((self.root / 'setting').read_text(), '1\n')
        process.terminate()
        self.write('pause_ready', '0\n')
        process.communicate(timeout=7)
        self.assertEqual(process.returncode, 143)
        self.restored()

    def test_launcher_sigkill_after_ready_before_commit_rolls_back(self):
        self.write('pause_commit', '1\n')
        process = self.start()
        self.until(lambda: (self.root / 'pause_commit.started').exists())
        self.assertEqual((self.root / 'setting').read_text(), '1\n')
        launcher = self.children(process.pid)[0]
        os.kill(launcher, signal.SIGKILL)
        self.restored()
        self.write('pause_commit', '0\n')
        process.communicate(timeout=7)
        self.assertEqual(process.returncode, 125)

    def test_watchdog_lost_before_commit_is_not_success(self):
        self.write('pause_commit', '1\n')
        process = self.start()
        self.until(lambda: (self.root / 'pause_commit.started').exists())
        _, watchdog = map(int, (self.root / 'pids').read_text().split())
        os.kill(watchdog, signal.SIGKILL)
        self.restored()
        self.write('pause_commit', '0\n')
        stdout, _ = process.communicate(timeout=7)
        self.assertEqual(process.returncode, 125)
        self.assertNotIn('lidrun: on', stdout)

    def test_cancel_during_guard_preparation(self):
        self.write('pause_guard', '1\n')
        process = self.start()
        self.until(lambda: (self.root / 'pause_guard.started').exists())
        process.terminate()
        time.sleep(.1)
        self.write('pause_guard', '0\n')
        process.communicate(timeout=7)
        self.assertEqual(process.returncode, 143)
        self.restored()

    def test_cli_sigkill_before_commit_rolls_back(self):
        self.write('pause_commit', '1\n')
        process = self.start()
        self.until(lambda: (self.root / 'pause_commit.started').exists())
        process.kill()
        process.communicate(timeout=7)
        self.restored()

    def test_terminal_session_disappears_after_commit(self):
        process = self.start()
        stdout, stderr = process.communicate(timeout=7)
        self.assertEqual(process.returncode, 0, stderr)
        self.assertIn('lidrun: on', stdout)
        # The entire original CLI process group/session is gone.
        self.assertFalse(self.alive(process.pid))
        time.sleep(1.2)
        self.assertEqual((self.root / 'setting').read_text(), '1\n')
        self.assertEqual(self.invoke('off').returncode, 0)

    def test_startup_off_waits_for_commit_then_stops_new_generation(self):
        self.write('pause_commit', '1\n')
        process = self.start()
        self.until(lambda: (self.root / 'pause_commit.started').exists())
        off = subprocess.Popen([str(BINARY), 'off'], env=self.env,
                               stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        self.processes.append(off)
        time.sleep(.15)
        self.assertIsNone(off.poll())
        self.write('pause_commit', '0\n')
        process.communicate(timeout=7)
        off.communicate(timeout=7)
        self.assertEqual(process.returncode, 0)
        self.assertEqual(off.returncode, 0)
        self.restored()

    def test_unsafe_state_and_journal_rejected(self):
        state = self.root / 'state'
        state.mkdir(mode=0o755)
        (state / 'journal').symlink_to(self.root / 'setting')
        self.assertEqual(self.invoke('off').returncode, 125)
        (state / 'journal').unlink()
        self.write('state/journal', 'bad journal\n')
        (state / 'journal').chmod(0o600)
        self.assertEqual(self.invoke('off').returncode, 125)
        (state / 'journal').unlink()
        state.chmod(0o777)
        self.assertEqual(self.invoke('on').returncode, 125)
        state.chmod(0o755)

    def test_invalid_stop_marker_refused(self):
        self.on()
        (self.root / 'state/stop').symlink_to(self.root / 'setting')
        self.assertEqual(self.invoke('off').returncode, 125)
        self.restored()
        (self.root / 'state/stop').unlink()

    def test_status_help_and_old_interface_rejected(self):
        self.assertEqual(self.invoke('status').stdout, 'SleepDisabled=0 AC=yes Battery=80%\n')
        self.assertEqual(self.invoke('--help').returncode, 0)
        self.assertEqual(self.invoke('run', '--timeout', '10', '--', 'true').returncode, 125)
        self.write('battery', 'unknown\n')
        self.assertEqual(self.invoke('status').returncode, 125)
        self.assertIn('unknown', self.invoke('status').stdout)


if __name__ == '__main__':
    unittest.main()
