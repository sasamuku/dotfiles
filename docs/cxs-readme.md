# CXS: Codex CLI account switcher

CXS selects the account home used by the next `codex` launch in Zsh. New accounts share settings and history with the standard `~/.codex` home used by the App and `default`. Authentication, operational state, memories, plugins, and system skills remain local to each account. Homes with existing local history keep it separate; CXS does not merge or overwrite it.

## Setup

Requires Zsh, Python 3.11 or later, and the Codex CLI on `PATH`.

From the dotfiles repository, after the normal [dotfiles setup](../README.md#quick-start):

```sh
sh setup_codex.sh
source ~/.config/zsh/functions/codex.zsh
```

The setup script requires `~/.claude/agents` and `~/.claude/skills`; run `setup_dotfiles.sh` first if they are missing. New Zsh sessions load the functions through `.zshrc`.

## Add, authenticate, and select

```sh
cxs add work       # Create a home at ~/.local/share/codex-accounts/work
cxs login work     # Authenticate this account with Codex login
cxs work           # Select it for subsequent launches
codex
```

`add` and `login` do not change the selected account. Account names accept 1–64 letters, digits, underscores, or hyphens, starting with a letter or digit. `default` is reserved.

| Command | Result |
| --- | --- |
| `cxs` | Use Up/Down arrows and Enter in an inline menu; cyan `❯` highlights the choice, green `*` marks the current account, and Esc or Ctrl+C cancels |
| `cxs NAME` | Select a registered account |
| `cxs default` | Return to the normal Codex environment |
| `cxs add NAME [HOME]` | Register a new or existing account home |
| `cxs login NAME` | Run `codex login` in the specified account home |

Selection is stored in `~/.config/codex-accounts/accounts.json` and applies to later launches from other shells too. Running Codex processes keep their current account. Existing aliases that invoke the `codex` function also use the selection.

The compact menu starts at the current account and preserves the surrounding terminal output. It uses Python's standard library with no additional picker dependency. The terminal must be interactive and at least 44 columns by 4 rows; longer lists scroll within the menu. If the terminal cannot display the menu, selection is preserved; use `cxs NAME` instead.

## Register an existing home

```sh
cxs add work "$HOME/.codex-work"
cxs work
codex
```

An existing home's authentication stays in place. If it already contains local history, CXS keeps that history and its SQLite location separate; launching and switching remain available. See [Existing history](#existing-history) before attempting to combine it with shared history. Its path must be inside your home directory, separate from `~/.codex` and the registry, and must not overlap another registered account home.

CXS refuses to replace conflicting settings or links and rejects symlinks for account state such as `auth.json`. If registration fails, inspect the reported conflict before retrying; move conflicting settings aside yourself if you want to use the shared settings.

## Shared settings and history

When present, these entries are linked from `~/.codex` on registration, selection, login, and launch:

```text
config.toml
hooks.json
keybindings.json
AGENTS.md
rules/
agents/
```

Existing account directories such as `agents/` are retained, with missing shared entries linked inside them. Conflicting files are not overwritten. Editing a linked setting changes the shared setting.

Account homes without local history also link these entries to `~/.codex`:

```text
sessions/
archived_sessions/
session_index.jsonl
history.jsonl
attachments/
visualizations/
thread-writer-locks/
rollout-migrations/
state_5.sqlite
goals_1.sqlite
thread_history_1.sqlite
```

CXS sets `CODEX_HOME` to the account home, uses file-based credentials there, and sets both `CODEX_SQLITE_HOME` and the `sqlite_home` CLI setting to the account home. Only the three listed history databases link to `~/.codex`; other databases remain local, including queue and memory state. If the shared config defines `mcp_servers.node_repl`, its `CODEX_HOME` is overridden for that account. Authentication, daemon state, memories, and queues are not shared. CXS refuses a mixture of linked shared history and local history.

## Existing history

CXS keeps existing local history separate and refuses a mixture of local history and links to shared history. Neither CXS nor `setup_codex.sh` automatically merges existing history, and CXS includes no migration command.

If you need to combine existing history with `~/.codex`, quit all Codex CLI processes and the Codex App, back up every affected home, and keep Codex closed throughout the migration. Plan the migration for your existing data before changing files or links.

## Notes

- `cxs default` adds no account overrides. Existing `CODEX_HOME` or `CODEX_SQLITE_HOME` environment values still apply.
- Use the Zsh `codex` function. `command codex`, an absolute executable path, and launches outside this shell integration bypass CXS.
- Explicit CLI configuration overrides are forwarded after CXS's defaults and can override them. Shared configuration that points to external state locations also needs review if separation matters.
- Registration and selection stay local; account names, paths, and credentials do not belong in dotfiles.
- CXS has no remove or rename command.
