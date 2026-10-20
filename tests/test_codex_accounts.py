"""python3 tests/test_codex_accounts.py — stub CLI, temporary homes, no authentication."""
import json
import os
from pathlib import Path
import pty
import select
import signal
import sqlite3
import subprocess
import sys
import tempfile
import termios
import time

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / '.local/bin/cxs'
FUNCTIONS = ROOT / '.config/zsh/functions/codex.zsh'


def main():
    with tempfile.TemporaryDirectory(prefix='codex accounts ') as temporary:
        home = Path(temporary).resolve()
        binary = home / 'bin/codex'
        binary.parent.mkdir()
        binary.write_text('''#!/usr/bin/env python3
import json, os, signal, sys, time
if 'wait' in sys.argv:
    print('ready', flush=True)
    signal.signal(signal.SIGTERM, lambda *_: (print(os.getenv('CODEX_HOME'), flush=True), sys.exit(42)))
    time.sleep(30)
print(json.dumps({'args': sys.argv[1:], 'home': os.getenv('CODEX_HOME'),
                  'sqlite': os.getenv('CODEX_SQLITE_HOME')}))
sys.exit(7 if 'fail' in sys.argv else 0)
''')
        binary.chmod(0o755)
        installed = home / '.local/bin/cxs'
        installed.parent.mkdir(parents=True)
        installed.symlink_to(SCRIPT)
        env = dict(os.environ, HOME=str(home), PATH=str(binary.parent) + ':' + os.environ['PATH'])
        env.pop('CODEX_HOME', None)
        env.pop('CODEX_SQLITE_HOME', None)

        def run(*args, ok=True, input=None, custom_env=None):
            result = subprocess.run([sys.executable, str(SCRIPT), *args[:1], str(binary), *args[1:]],
                                    env=custom_env or env, input=input, text=True, capture_output=True)
            assert (result.returncode == 0) == ok, (args, result.stdout, result.stderr)
            return result

        def shell(*args, ok=True):
            result = subprocess.run(['zsh', '-f', '-c', 'source "$1"; shift; codex "$@"',
                                     'test', str(FUNCTIONS), *args], env=env, text=True, capture_output=True)
            assert (result.returncode == 0) == ok, result.stderr
            return result

        def menu(keys, custom_env=None, ok=True, size=(24, 80)):
            master, slave = pty.openpty()
            termios.tcsetwinsize(slave, size)
            attributes = termios.tcgetattr(slave)
            process = subprocess.Popen(
                [sys.executable, str(SCRIPT), 'switch', str(binary)],
                env=custom_env or dict(env, TERM='xterm-256color'),
                stdin=slave, stdout=slave, stderr=slave)
            output = b''
            try:
                deadline = time.monotonic() + 5
                ready = '↑↓ Move · Enter Select · Esc Cancel'.encode()
                while ready not in output and b'cxs:' not in output:
                    assert time.monotonic() < deadline, output
                    if select.select([master], [], [], 0.1)[0]:
                        output += os.read(master, 65536)
                if ready in output:
                    if keys is None:
                        process.send_signal(signal.SIGINT)
                    else:
                        os.write(master, keys)
                deadline = time.monotonic() + 5
                while process.poll() is None:
                    assert time.monotonic() < deadline, output
                    if select.select([master], [], [], 0.1)[0]:
                        try:
                            output += os.read(master, 65536)
                        except OSError:
                            break
                assert (process.wait(timeout=5) == 0) == ok, output
                while select.select([master], [], [], 0)[0]:
                    output += os.read(master, 65536)
                restored = termios.tcgetattr(slave)
                # The PTY sets transient PENDIN while canonical input is restored.
                restored[3] &= ~termios.PENDIN
                attributes[3] &= ~termios.PENDIN
                assert restored == attributes, (attributes, restored, output)
                assert b'\x1b[?25h' in output
                for forbidden in (b'\x1b[?1049h', b'\x1b[?47h', b'\x1b[2J', b'\x1b[3J'):
                    assert forbidden not in output
                return output
            finally:
                if process.poll() is None:
                    process.kill()
                    process.wait()
                os.close(master)
                os.close(slave)

        shared = home / '.codex'
        (shared / 'agents').mkdir(parents=True)
        (shared / 'rules').mkdir()
        for name in ('config.toml', 'hooks.json', 'keybindings.json', 'AGENTS.md'):
            (shared / name).write_text('model="stub"' if name == 'config.toml' else 'shared settings')
        (shared / 'agents/reviewer.toml').write_text('role')
        (shared / 'auth.json').write_text('DO NOT COPY')
        (shared / 'history.jsonl').write_text('DO NOT COPY')
        args = ['resume', '--last', 'prompt with spaces', '--', '-literal']
        assert json.loads(shell(*args).stdout) == {'args': args, 'home': None, 'sqlite': None}
        no_python = subprocess.run(['zsh', '-f', '-c',
                                    'python3() { return 99; }; source "$1"; codex --version',
                                    'test', str(FUNCTIONS)], env=env, text=True, capture_output=True)
        assert no_python.returncode == 0, no_python.stderr
        assert json.loads(no_python.stdout)['args'] == ['--version']
        explicit = dict(env, CODEX_HOME=str(home / 'explicit'))
        assert json.loads(run('run', '--version', custom_env=explicit).stdout)['home'] == explicit['CODEX_HOME']

        run('switch', 'add', 'first')
        run('switch', 'add', 'second')
        registry = home / '.config/codex-accounts/accounts.json'
        data = json.loads(registry.read_text())
        first = Path(data['accounts']['first'])
        second = Path(data['accounts']['second'])
        assert data['selected'] == 'default'
        for account in (first, second):
            assert (account / 'config.toml').is_symlink()
            assert (account / 'agents').is_symlink()
            for name in ('sessions', 'archived_sessions', 'history.jsonl', 'session_index.jsonl',
                         'attachments', 'visualizations', 'thread-writer-locks', 'rollout-migrations',
                         'state_5.sqlite', 'goals_1.sqlite', 'thread_history_1.sqlite'):
                assert (account / name).is_symlink()
                assert (account / name).resolve() == (shared / name).resolve()
            for name in ('auth.json', 'plugins', 'skills', 'cache'):
                assert not (account / name).exists()
        assert (shared / 'sessions').is_dir()
        with sqlite3.connect(first / 'state_5.sqlite') as database:
            assert database.execute('pragma journal_mode=wal').fetchone()[0] == 'wal'
            database.execute('create table check_shared (value text)')
            database.execute('insert into check_shared values ("shared")')
            database.commit()
            assert (shared / 'state_5.sqlite-wal').exists()
            assert not (first / 'state_5.sqlite-wal').exists()
            with sqlite3.connect(second / 'state_5.sqlite') as reader:
                assert reader.execute('select value from check_shared').fetchone()[0] == 'shared'
        (first / 'queue.sqlite').write_text('local queue')
        assert not (shared / 'queue.sqlite').exists()
        assert not (second / 'queue.sqlite').exists()
        selected = subprocess.run(['zsh', '-f', '-c', 'source "$1"; cxs first',
                                   'test', str(FUNCTIONS)], env=env, text=True, capture_output=True)
        assert selected.returncode == 0, selected.stderr
        result = json.loads(shell(*args).stdout)
        assert result['home'] == str(first) and result['sqlite'] == str(first)
        assert result['args'][4:] == args
        assert 'cli_auth_credentials_store="file"' in result['args']
        assert 'sqlite_home=' + json.dumps(str(first)) in result['args']
        assert not any('mcp_servers.node_repl' in arg for arg in result['args'])
        (shared / 'config.toml').write_text('[mcp_servers.node_repl]\ncommand="stub"\n')
        node = json.loads(shell('--version').stdout)['args']
        assert 'mcp_servers.node_repl.env.CODEX_HOME=' + json.dumps(str(first)) in node
        override = json.loads(shell('-c', 'cli_auth_credentials_store="keyring"').stdout)['args']
        assert override.index('cli_auth_credentials_store="file"') < override.index('cli_auth_credentials_store="keyring"')
        for command in (['help', 'resume'], ['sandbox', '/usr/bin/printf', '%s\\n', 'hello']):
            assert json.loads(shell(*command).stdout)['args'][6:] == command
        alias = subprocess.run(['zsh', '-f', '-c',
                                '''source "$1"; alias cx='codex --sandbox workspace-write'; shift; eval 'cx "$@"' ''',
                                'test', str(FUNCTIONS), 'resume', '--last'],
                               env=env, text=True, capture_output=True)
        assert alias.returncode == 0, alias.stderr
        assert json.loads(alias.stdout)['args'][6:] == ['--sandbox', 'workspace-write', 'resume', '--last']
        assert shell('fail', ok=False).returncode == 7
        assert '❯ first \x1b[32m*\x1b[0m'.encode() in menu(b'\x1bOB\r')
        assert json.loads(registry.read_text())['selected'] == 'second'
        menu(b'\x1bOA\r')
        assert json.loads(registry.read_text())['selected'] == 'first'
        menu(b'\x1b[B\r')
        assert json.loads(registry.read_text())['selected'] == 'second'
        menu(b'\x1b[A\r')
        assert json.loads(registry.read_text())['selected'] == 'first'
        menu(b'\r')
        assert json.loads(registry.read_text())['selected'] == 'first'
        before = registry.read_bytes()
        for keys in (b'\x1bOB\x1b', b'\x1b[B\x03', None):
            menu(keys)
            assert registry.read_bytes() == before
        for choice in ('\n', ''):
            result = run('switch', input=choice, ok=False)
            assert 'use cxs NAME' in result.stderr
            assert registry.read_bytes() == before
        output = menu(b'', custom_env=dict(env, TERM='dumb'), ok=False)
        assert b'use cxs NAME' in output
        assert registry.read_bytes() == before
        menu(b'', size=(3, 20), ok=False)
        assert registry.read_bytes() == before
        extended = json.loads(before)
        extended['accounts'].update({f'account{i}': str(home / f'account{i}') for i in range(10)})
        registry.write_text(json.dumps(extended))
        extended_before = registry.read_bytes()
        menu(b'\x1b[B' * 8 + b'\x1b', size=(7, 44))
        assert registry.read_bytes() == extended_before
        registry.write_bytes(before)
        no_tools = dict(env, PATH='')
        menu(b'\x1bOA\r', custom_env=dict(no_tools, TERM='xterm-256color'))
        assert json.loads(registry.read_text())['selected'] == 'default'
        run('switch', 'second', custom_env=no_tools)
        assert json.loads(registry.read_text())['selected'] == 'second'
        assert json.loads(run('switch', 'login', 'first').stdout)['args'][6:] == ['login']
        assert json.loads(registry.read_text())['selected'] == 'second'
        run('switch', 'default')
        assert json.loads(shell('--version').stdout)['home'] is None
        for name in ('../escape', '/absolute', '.', 'with space', 'default'):
            run('switch', 'add', name, ok=False)
        run('switch', 'add', 'app', str(shared), ok=False)
        run('switch', 'add', 'duplicate', str(first), ok=False)
        run('switch', 'add', 'outside', '/tmp/outside-codex-test', ok=False)
        (home / 'escape').symlink_to('/tmp', target_is_directory=True)
        run('switch', 'add', 'escape', str(home / 'escape/account'), ok=False)
        conflict = home / 'conflict'
        conflict.mkdir()
        (conflict / 'hooks.json').write_text('preserve')
        run('switch', 'add', 'conflict', str(conflict), ok=False)
        assert (conflict / 'hooks.json').read_text() == 'preserve'
        assert not (conflict / 'config.toml').is_symlink()
        assert 'conflict' not in json.loads(registry.read_text())['accounts']
        recursive = home / 'recursive-conflict'
        (recursive / 'rules').mkdir(parents=True)
        (shared / 'rules/first.rules').write_text('shared rule')
        (shared / 'rules/nested').mkdir()
        (shared / 'rules/nested/conflict.rules').write_text('shared rule')
        (recursive / 'rules/nested').mkdir()
        (recursive / 'rules/nested/conflict.rules').write_text('preserve')
        run('switch', 'add', 'recursive', str(recursive), ok=False)
        assert not (recursive / 'rules/first.rules').is_symlink()
        assert (recursive / 'rules/nested/conflict.rules').read_text() == 'preserve'
        assert 'recursive' not in json.loads(registry.read_text())['accounts']
        linked = home / 'linked-state'
        linked.mkdir()
        (linked / 'auth.json').symlink_to(shared / 'auth.json')
        run('switch', 'add', 'linked', str(linked), ok=False)
        assert 'linked' not in json.loads(registry.read_text())['accounts']
        history_home = home / 'history-conflict'
        history_home.mkdir()
        (history_home / 'history.jsonl').write_text('preserve local history')
        run('switch', 'add', 'history', str(history_home))
        assert (history_home / 'history.jsonl').read_text() == 'preserve local history'
        assert not (history_home / 'sessions').is_symlink()
        run('switch', 'history')
        assert json.loads(shell('--version').stdout)['sqlite'] == str(history_home)
        (history_home / 'sessions').symlink_to(shared / 'sessions')
        run('switch', 'history', ok=False)
        (history_home / 'sessions').unlink()
        wal_home = home / 'wal-conflict'
        wal_home.mkdir()
        (wal_home / 'state_5.sqlite-wal').write_text('preserve WAL')
        run('switch', 'add', 'wal', str(wal_home))
        assert (wal_home / 'state_5.sqlite-wal').read_text() == 'preserve WAL'
        legacy = home / '.codex-cli'
        (legacy / 'agents').mkdir(parents=True)
        (legacy / 'agents/reviewer.toml').symlink_to(shared / 'agents/reviewer.toml')
        (legacy / 'auth.json').write_text('preserve existing auth')
        run('switch', 'add', 'cli', str(legacy))
        assert (legacy / 'auth.json').read_text() == 'preserve existing auth'
        run('switch', 'first')
        proc = subprocess.Popen(['python3', str(SCRIPT), 'run', str(binary), 'wait'],
                                env=env, text=True, stdout=subprocess.PIPE)
        assert proc.stdout.readline().strip() == 'ready'
        run('switch', 'second')
        proc.send_signal(signal.SIGTERM)
        assert proc.wait(timeout=5) == 42
        assert proc.stdout.read().strip() == str(first)
        assert (shared / 'auth.json').read_text() == 'DO NOT COPY'
        assert (shared / 'history.jsonl').read_text() == 'DO NOT COPY'
        assert registry.stat().st_mode & 0o777 == 0o600
        # Setup is idempotent and preserves unrelated files at the install destination.
        (home / '.claude/agents').mkdir(parents=True)
        (home / '.claude/skills').mkdir()
        function_link = home / '.config/zsh/functions/codex.zsh'
        for _ in range(2):
            setup = subprocess.run(['sh', str(ROOT / 'setup_codex.sh')], env=env,
                                   text=True, capture_output=True)
            assert setup.returncode == 0, setup.stderr
            assert function_link.resolve() == FUNCTIONS.resolve()
        function_link.unlink()
        function_link.write_text('preserve user function')
        setup = subprocess.run(['sh', str(ROOT / 'setup_codex.sh')], env=env,
                               text=True, capture_output=True)
        assert setup.returncode == 0, setup.stderr
        assert function_link.read_text() == 'preserve user function'
    print('codex account tests passed')


if __name__ == '__main__':
    main()
