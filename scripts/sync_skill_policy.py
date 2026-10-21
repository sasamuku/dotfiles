# /// script
# requires-python = ">=3.10"
# dependencies = ["ruamel.yaml==0.19.1"]
# ///
"""Sync shared skill invocation policy; --check --staged reads only Git's index."""

import argparse
from copy import deepcopy
from io import StringIO
from pathlib import Path
import re
import subprocess
import sys
import tempfile

from ruamel.yaml import YAML
from ruamel.yaml.error import YAMLError

SKILL_FILES = re.compile(r"\.agents/skills/[^/]+/(SKILL\.md|agents/openai\.yaml)")
FLAG = "disable-model-invocation"
POLICY = "allow_implicit_invocation"


def git(root, *args):
    return subprocess.run(
        ["git", "-C", str(root), *args], check=True, capture_output=True
    ).stdout


def read_files(root, staged):
    files = {}
    if staged:
        for entry in git(root, "ls-files", "--stage", "-z", "--", ".agents/skills").split(b"\0"):
            if not entry:
                continue
            info, raw_path = entry.split(b"\t", 1)
            path = raw_path.decode("utf-8")
            if not SKILL_FILES.fullmatch(path):
                continue
            mode, _, stage = info.split()
            if stage != b"0" or mode not in (b"100644", b"100755"):
                raise ValueError(f"{path}: unresolved conflict or non-regular file in index")
            files[path] = git(root, "show", f":{path}").decode("utf-8")
    else:
        for pattern in (".agents/skills/*/SKILL.md", ".agents/skills/*/agents/openai.yaml"):
            for path in sorted(root.glob(pattern)):
                for part in (path, *path.parents):
                    if part == root:
                        break
                    if part.is_symlink():
                        raise ValueError(f"{part}: symlinks are not supported in skill sources")
                files[path.relative_to(root).as_posix()] = path.read_text(encoding="utf-8")
    return files


def mapping(yaml, text, path):
    try:
        value = yaml.load(text)
    except YAMLError as error:
        raise ValueError(f"{path}: {error}") from error
    if not isinstance(value, dict):
        raise ValueError(f"{path}: expected a YAML mapping")
    return value


def expected_metadata(skill, original, path):
    yaml = YAML()
    yaml.preserve_quotes = True
    lines = skill.splitlines(keepends=True)
    if not lines or lines[0].strip() != "---":
        raise ValueError(f"{path}: missing opening frontmatter delimiter")
    end = next((i for i in range(1, len(lines)) if lines[i].strip() == "---"), None)
    if end is None:
        raise ValueError(f"{path}: missing closing frontmatter delimiter")
    frontmatter = mapping(yaml, "".join(lines[1:end]), path)
    manual = frontmatter.get(FLAG, False)
    if type(manual) is not bool:
        raise ValueError(f"{path}: {FLAG} must be true or false")

    metadata_path = str(Path(path).parent / "agents/openai.yaml")
    data = mapping(yaml, original, metadata_path) if original is not None else {}
    policy = data.get("policy", {})
    if not isinstance(policy, dict):
        raise ValueError(f"{metadata_path}: policy must be a mapping")
    if POLICY in policy and type(policy[POLICY]) is not bool:
        raise ValueError(f"{metadata_path}: {POLICY} must be true or false")
    if (manual and policy.get(POLICY) is False) or (not manual and POLICY not in policy):
        return original

    # A policy alias must not change metadata elsewhere in the document.
    policy = deepcopy(policy)
    if manual:
        policy[POLICY] = False
    else:
        del policy[POLICY]
    if policy:
        data["policy"] = policy
    else:
        del data["policy"]
    if not data:
        return None
    output = StringIO()
    yaml.dump(data, output)
    return output.getvalue()


def write_metadata(root, name, text):
    path = root / name
    for part in (path, *path.parents):
        if part == root:
            break
        if part.is_symlink():
            raise ValueError(f"{part}: refusing to write through a symlink")
    if text is None:
        path.unlink()
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", dir=path.parent, delete=False) as stream:
        temp = Path(stream.name)
        try:
            stream.write(text)
            stream.close()
            temp.chmod(path.stat().st_mode & 0o777 if path.exists() else 0o644)
            temp.replace(path)
        finally:
            temp.unlink(missing_ok=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--write", action="store_true")
    mode.add_argument("--check", action="store_true")
    parser.add_argument("--staged", action="store_true")
    args = parser.parse_args()
    if args.staged and not args.check:
        parser.error("--staged requires --check")

    root = Path(git(Path.cwd(), "rev-parse", "--show-toplevel").decode().strip())
    files = read_files(root, args.staged)
    changes = {}
    for path, original in sorted(files.items()):
        if path.endswith("/agents/openai.yaml"):
            source = str(Path(path).parent.parent / "SKILL.md")
            if source not in files:
                raise ValueError(f"{path}: missing {source}")
            continue
        target = str(Path(path).parent / "agents/openai.yaml")
        expected = expected_metadata(original, files.get(target), path)
        if expected != files.get(target):
            changes[target] = expected

    if args.write:
        for path, text in changes.items():
            write_metadata(root, path, text)
            print(f"{'Removed' if text is None else 'Updated'} {path}")
    elif changes:
        print("Skill invocation policy is out of sync:", file=sys.stderr)
        for path in changes:
            print(f"  {path}", file=sys.stderr)
        print("Run: uv run scripts/sync_skill_policy.py --write", file=sys.stderr)
        print("Review and stage the source and metadata changes, then retry.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        print(f"Skill policy error: {error}", file=sys.stderr)
        sys.exit(1)
