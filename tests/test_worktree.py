"""Run with python3 tests/test_worktree.py; only temporary repositories are modified."""
import json
import os
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
WT = ROOT / '.config/zsh/functions/wt.zsh'
HOOK = ROOT / '.claude/hooks/hook_worktree_create.sh'


def run(args, cwd, *, ok=True, **kwargs):
    result = subprocess.run(args, cwd=cwd, text=True, capture_output=True, **kwargs)
    assert (result.returncode == 0) == ok, (args, result.stdout, result.stderr)
    return result


def wt(repo, *args, ok=True, **kwargs):
    return run(['zsh', '-f', '-c', 'source "$1"; shift; wt "$@"', 'test', str(WT), *args], repo, ok=ok, **kwargs)


def git(repo, *args):
    return run(['git', *args], repo)


def agent(repo, name, *, ok=True):
    return run(['bash', str(HOOK)], repo, ok=ok, input=json.dumps({'name': name, 'cwd': str(repo)}))


def main():
    with tempfile.TemporaryDirectory(prefix='wt-test-') as tmp:
        parent = Path(tmp).resolve()
        repo = parent / "repo with space's"
        repo.mkdir()
        git(repo, 'init', '-b', 'main')
        git(repo, 'config', 'user.name', 'Worktree test')
        git(repo, 'config', 'user.email', 'test@example.invalid')
        git(repo, 'commit', '--allow-empty', '-m', 'initial')

        def checkout(branch):
            return parent / (repo.name + '-' + branch.replace('/', '-'))

        # Same shell, cwd, environment, and stdout contract across all entry points.
        (repo / '.env').write_text('example=value\n')
        init = repo / '.wt_hook.sh'
        init.write_text('''items=(bash zero-based)
[[ "${items[0]}" == bash ]]
[[ "$PWD" == "$WT_WORKTREE_PATH" ]]
cp "$WT_PROJECT_ROOT/.env" .env
printf '%s' "$WT_BRANCH_NAME" > initialized
printf 'hook log\\n'
''')
        wt(repo, 'add', 'feat.one')
        git(repo, 'branch', 'existing')
        wt(repo, 'co', 'existing')
        result = agent(repo, 'agent')
        assert result.stdout == str(checkout('agent')) + '\n'
        for branch in ('feat.one', 'existing', 'agent'):
            assert (checkout(branch) / '.env').read_text() == 'example=value\n'
            assert (checkout(branch) / 'initialized').read_text() == branch

        # Failures retain the checkout, but never return success or continue the hook.
        init.write_text('false\nprintf bad > should-not-exist\n')
        wt(repo, 'add', 'failed', ok=False)
        git(repo, 'branch', 'failed-co')
        wt(repo, 'co', 'failed-co', ok=False)
        assert agent(repo, 'failed-agent', ok=False).stdout == ''
        for branch in ('failed', 'failed-co', 'failed-agent'):
            assert checkout(branch).is_dir()
            assert not (checkout(branch) / 'should-not-exist').exists()
        wt(repo, 'add', 'failed', ok=False)
        wt(repo, 'co', 'failed', ok=False)
        agent(repo, 'failed-agent', ok=False)
        init.unlink()

        # Literal branch matching, spaces in paths, and safe removal.
        wt(repo, 'add', 'featXone')
        wt(repo, 'remove', 'feat.one', ok=False)
        assert (checkout('feat.one') / 'initialized').exists()
        wt(repo, 'remove', 'featXone')
        assert not checkout('featXone').exists()
        wt(repo, 'remove', 'main', ok=False)
        wt(checkout('failed'), 'remove', 'failed', ok=False)
        wt(repo, 'remove', '-D', 'main', ok=False)
        wt(checkout('failed'), 'remove', '-D', 'failed', ok=False)
        wt(repo, 'remove', '-D', ok=False)
        wt(repo, 'remove', '-X', 'failed', ok=False)
        wt(repo, 'remove', '-D', 'failed', 'extra', ok=False)

        # Explicit force removes dirty files and an unmerged branch together.
        wt(repo, 'add', 'force-delete')
        forced = checkout('force-delete')
        (forced / 'tracked').write_text('committed')
        git(forced, 'add', 'tracked')
        git(forced, 'commit', '-m', 'unmerged commit')
        (forced / 'tracked').write_text('uncommitted')
        (forced / 'untracked').write_text('untracked')
        wt(repo, 'remove', 'force-delete', ok=False)
        assert (forced / 'tracked').read_text() == 'uncommitted'
        assert (forced / 'untracked').exists()
        wt(repo, 'remove', '-D', 'force-delete')
        assert not forced.exists()
        run(['git', 'show-ref', '--verify', 'refs/heads/force-delete'], repo, ok=False)

        wt(repo, 'add', 'unmerged')
        git(checkout('unmerged'), 'commit', '--allow-empty', '-m', 'unmerged work')
        wt(repo, 'remove', 'unmerged', ok=False)
        git(repo, 'show-ref', '--verify', 'refs/heads/unmerged')

        # Picker consumes NUL-delimited paths, and Ctrl+D uses the same safe removal.
        fake_bin = parent / 'bin'
        fake_bin.mkdir()
        fzf = fake_bin / 'fzf'
        fzf.write_text('#!/bin/sh\ncat >/dev/null\nprintf "%s\\0%s\\0" "$PICK_KEY" "$PICK_PATH"\n')
        fzf.chmod(0o755)
        env = {**os.environ, 'PATH': str(fake_bin) + os.pathsep + os.environ['PATH'],
               'PICK_KEY': '', 'PICK_PATH': str(checkout('feat.one'))}
        result = run(['zsh', '-f', '-c', 'source "$1"; wt; pwd', 'test', str(WT)], repo, env=env)
        assert result.stdout.strip() == str(checkout('feat.one'))
        env['PICK_KEY'] = 'ctrl-d'
        wt(repo, ok=False, env=env)
        assert (checkout('feat.one') / 'initialized').exists()

        # clean handles Git's checked-out branch marker and preserves dirty worktrees.
        wt(repo, 'clean', ok=False, input='y\n')
        for branch in ('failed', 'failed-co', 'failed-agent'):
            assert not checkout(branch).exists()
        assert checkout('feat.one').exists()
        git(repo, 'show-ref', '--verify', 'refs/heads/unmerged')

        # master is supported when main does not exist.
        git(repo, 'branch', '-m', 'main', 'master')
        wt(repo, 'add', 'merged-master')
        wt(repo, 'clean', ok=False, input='y\n')
        assert not checkout('merged-master').exists()
        wt(repo, 'remove', 'master', ok=False)
        wt(repo, 'remove', '-D', 'master', ok=False)

        # A failed checkout/fetch must not change cwd or report success.
        git(repo, 'branch', 'collision')
        checkout('collision').mkdir()
        (checkout('collision') / 'occupied').touch()
        wt(repo, 'co', 'collision', ok=False)
        wt(repo, 'co', 'missing-remote-branch', ok=False)
        print('worktree regression checks passed')


if __name__ == '__main__':
    main()
