"""Run with python3 tests/test_skill_policy.py; only temporary repositories change."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts/sync_skill_policy.py"
SKILL = ".agents/skills/example/SKILL.md"
METADATA = ".agents/skills/example/agents/openai.yaml"
MANUAL = "---\nname: example\ndescription: Example\ndisable-model-invocation: true\n---\nBody\n"
AUTOMATIC = MANUAL.replace("disable-model-invocation: true\n", "")
POLICY = "policy:\n  allow_implicit_invocation: false\n"


class SkillPolicyTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="skill policy ")
        self.addCleanup(self.temp.cleanup)
        self.repo = Path(self.temp.name)
        self.run_command("git", "init", "-q")
        self.run_command("git", "config", "user.name", "Test")
        self.run_command("git", "config", "user.email", "test@example.invalid")
        self.run_command("git", "config", "commit.gpgsign", "false")

    def run_command(self, *args, ok=True, env=None):
        result = subprocess.run(args, cwd=self.repo, capture_output=True, text=True, env=env)
        self.assertEqual(result.returncode == 0, ok, result.stdout + result.stderr)
        return result

    def sync(self, *args, ok=True, env=None):
        return self.run_command("uv", "run", str(SCRIPT), *args, ok=ok, env=env)

    def write(self, path, content):
        target = self.repo / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")

    def test_generation_removal_and_idempotence(self):
        self.write(SKILL, MANUAL)
        self.sync("--check", ok=False)
        self.sync("--write")
        self.assertEqual((self.repo / METADATA).read_text(), POLICY)
        timestamp = (self.repo / METADATA).stat().st_mtime_ns
        self.sync("--write")
        self.assertEqual((self.repo / METADATA).stat().st_mtime_ns, timestamp)
        self.sync("--check")
        for source in (AUTOMATIC, MANUAL.replace(": true", ": false")):
            self.write(SKILL, source)
            self.write(METADATA, POLICY)
            self.sync("--write")
            self.assertFalse((self.repo / METADATA).exists())
            self.sync("--check")

    def test_preserves_metadata_and_comments(self):
        self.write(SKILL, MANUAL)
        other = '# UI metadata\ninterface:\n  display_name: "Example" # keep\ndependencies:\n  tools: []\n'
        self.write(METADATA, other + 'policy:\n  products: [CODEX] # keep products\n')
        self.sync("--write")
        generated = (self.repo / METADATA).read_text()
        self.assertIn(other, generated)
        self.assertIn("products: [CODEX] # keep products", generated)
        self.assertIn("allow_implicit_invocation: false", generated)
        self.write(SKILL, AUTOMATIC)
        self.sync("--write")
        generated = (self.repo / METADATA).read_text()
        self.assertIn(other, generated)
        self.assertIn("products: [CODEX] # keep products", generated)
        self.assertNotIn("allow_implicit_invocation", generated)

    def test_existing_policy_is_corrected(self):
        self.write(SKILL, MANUAL)
        self.write(METADATA, POLICY.replace(": false", ": true"))
        self.sync("--check", ok=False)
        self.sync("--write")
        self.assertEqual((self.repo / METADATA).read_text(), POLICY)

    def test_flow_mapping_and_shared_alias_preserve_other_settings(self):
        self.write(SKILL, MANUAL)
        self.write(METADATA, 'defaults: &shared {allow_implicit_invocation: true}\npolicy: *shared\n')
        self.sync("--write")
        result = (self.repo / METADATA).read_text()
        self.assertIn("allow_implicit_invocation: true", result)
        self.assertIn("allow_implicit_invocation: false", result)
        self.sync("--check")

    def test_invalid_yaml_or_types_never_write(self):
        self.write(".agents/skills/aaa/SKILL.md", MANUAL)
        for source in (
            MANUAL.replace(": true", ': "true"'),
            MANUAL.replace(": true", ": null"),
            MANUAL.replace(": true", ": ["),
            MANUAL.replace(": true", ": true\ndisable-model-invocation: false"),
            MANUAL.removeprefix("---\n"),
            MANUAL.replace("---\nBody", "Body"),
        ):
            with self.subTest(source=source):
                self.write(SKILL, source)
                self.sync("--write", ok=False)
                self.assertFalse((self.repo / ".agents/skills/aaa/agents/openai.yaml").exists())
        self.write(SKILL, MANUAL)
        for content in ("policy: [", "policy: null\n", 'policy:\n  allow_implicit_invocation: "false"\n',
                        "policy:\n  allow_implicit_invocation: false\n  allow_implicit_invocation: true\n"):
            with self.subTest(content=content):
                self.write(METADATA, content)
                self.sync("--write", ok=False)
                self.assertEqual((self.repo / METADATA).read_text(), content)
                self.assertFalse((self.repo / ".agents/skills/aaa/agents/openai.yaml").exists())

    def test_staged_check_detects_unstaged_generated_file(self):
        self.write(SKILL, MANUAL)
        self.run_command("git", "add", SKILL)
        self.sync("--write")
        self.sync("--check")
        before = self.run_command("git", "diff", "--cached").stdout
        result = self.sync("--check", "--staged", ok=False)
        self.assertIn(METADATA, result.stderr)
        self.assertEqual(self.run_command("git", "diff", "--cached").stdout, before)
        self.run_command("git", "add", METADATA)
        self.sync("--check", "--staged")

    def test_partial_staging_reads_index_not_worktree(self):
        self.write(SKILL, AUTOMATIC)
        self.run_command("git", "add", SKILL)
        self.write(SKILL, MANUAL)
        self.sync("--write")
        self.run_command("git", "add", METADATA)
        self.sync("--check")
        self.sync("--check", "--staged", ok=False)
        self.run_command("git", "add", SKILL)
        self.write(SKILL, "invalid working tree contents")
        self.sync("--check", "--staged")
        self.sync("--check", ok=False)

    def test_staged_flag_removal_requires_metadata_removal(self):
        self.write(SKILL, MANUAL)
        self.sync("--write")
        self.run_command("git", "add", ".")
        self.write(SKILL, AUTOMATIC)
        self.run_command("git", "add", SKILL)
        self.sync("--write")
        self.sync("--check", "--staged", ok=False)
        self.run_command("git", "add", "-u")
        self.sync("--check", "--staged")

    def test_alternate_index_is_respected(self):
        self.write(SKILL, MANUAL)
        self.run_command("git", "add", SKILL)
        env = {**os.environ, "GIT_INDEX_FILE": str(self.repo / ".git/alternate-index")}
        self.run_command("git", "read-tree", "--empty", env=env)
        self.sync("--check", "--staged", env=env)
        self.sync("--check", "--staged", ok=False)

    def test_symlink_metadata_is_rejected(self):
        self.write(SKILL, MANUAL)
        self.write("external.yaml", "interface: {}\n")
        target = self.repo / METADATA
        target.parent.mkdir(parents=True)
        target.symlink_to(self.repo / "external.yaml")
        self.sync("--write", ok=False)
        self.run_command("git", "add", ".")
        self.sync("--check", "--staged", ok=False)
        self.assertEqual((self.repo / "external.yaml").read_text(), "interface: {}\n")

    def test_orphan_metadata_is_rejected(self):
        self.write(METADATA, POLICY)
        self.sync("--write", ok=False)

    def test_actual_pre_commit_hook(self):
        (self.repo / "scripts").mkdir()
        shutil.copy(SCRIPT, self.repo / "scripts" / SCRIPT.name)
        shutil.copy(ROOT / "lefthook.yml", self.repo / "lefthook.yml")
        self.run_command("lefthook", "install")
        self.write(SKILL, MANUAL)
        self.run_command("git", "add", ".")
        self.run_command("git", "commit", "-m", "must fail", ok=False)
        self.sync("--write")
        self.run_command("git", "commit", "-m", "still not staged", ok=False)
        self.run_command("git", "add", METADATA)
        self.run_command("git", "commit", "-m", "consistent policy")


if __name__ == "__main__":
    unittest.main()
