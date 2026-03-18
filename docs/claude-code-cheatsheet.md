# Claude Code チートシート

Claude Code（CLI）の主要機能をまとめたリファレンスです。

---

## キーボードショートカット

### 基本操作

| キー | 説明 |
|------|------|
| `Ctrl+C` | 入力 / 生成をキャンセル |
| `Ctrl+D` | セッション終了（EOF） |
| `Ctrl+L` | 画面クリア（会話は保持） |
| `Ctrl+G` | プロンプトをエディタで開く |
| `Ctrl+R` | コマンド履歴の逆引き検索 |
| `Ctrl+S` | プロンプトをスタッシュ / 復元 |
| `Esc` × 2 | 直前のメッセージまで巻き戻し |

### モード切替 / モデル

| キー | 説明 |
|------|------|
| `Shift+Tab` / `Alt+M` | パーミッションモード切替（Default → Plan → AcceptEdits） |
| `Option+P` | モデル切替（プロンプト維持） |
| `Option+T` | 拡張思考（Extended Thinking）トグル |

### マルチライン入力

| キー | 説明 |
|------|------|
| `\` + `Enter` | 全ターミナル共通 |
| `Option+Enter` | macOS デフォルト |
| `Shift+Enter` | iTerm2 / WezTerm / Ghostty / Kitty |
| `Ctrl+J` | ラインフィード文字 |

### エージェント / タスク管理

| キー | 説明 |
|------|------|
| `Ctrl+B` | 実行中タスクをバックグラウンドへ |
| `Ctrl+T` | タスクリスト表示トグル |
| `Ctrl+F` × 2 | バックグラウンドエージェントを全停止 |

### テキスト編集

| キー | 説明 |
|------|------|
| `Ctrl+K` | カーソルから行末まで削除 |
| `Ctrl+U` | 行全体を削除 |
| `Ctrl+Y` | 削除テキストをペースト |
| `Alt+B` / `Alt+F` | 単語単位でカーソル移動 |

### その他

| キー | 説明 |
|------|------|
| `Ctrl+V` | クリップボードから画像貼り付け |
| `Ctrl+O` | verbose 出力トグル |
| `@` | ファイルパス補完 |
| `!` | 直接 Bash 実行（結果をコンテキストに追加） |

---

## スラッシュコマンド

### セッション管理

| コマンド | 説明 |
|----------|------|
| `/clear` | 会話履歴をクリア |
| `/compact [指示]` | 会話を圧縮（指示で圧縮方針を指定可） |
| `/resume [session]` | セッションを再開 |
| `/branch [name]` | 会話のブランチを作成 |
| `/rename [name]` | セッション名を変更 |
| `/export [file]` | 会話をテキストエクスポート |
| `/rewind` | 直前のポイントまで巻き戻し |
| `/exit` | セッション終了 |

### 設定 / 情報

| コマンド | 説明 |
|----------|------|
| `/config` | 設定画面を開く |
| `/model [model]` | モデル選択・変更 |
| `/effort [level]` | エフォートレベル設定（low / medium / high / max / auto） |
| `/fast [on\|off]` | Fast モードトグル |
| `/theme` | カラーテーマ変更 |
| `/color [color]` | プロンプトバーの色変更 |
| `/vim` | Vim 編集モードトグル |
| `/keybindings` | キーバインド設定を開く |
| `/terminal-setup` | ターミナルキーバインド設定 |
| `/permissions` | パーミッションルール管理 |
| `/sandbox` | サンドボックスモードトグル |
| `/status` | バージョン・モデル・接続状態 |
| `/cost` | トークン使用量 |
| `/usage` | プラン使用量・レート制限 |
| `/extra-usage` | レート制限時の追加使用量設定 |
| `/context` | コンテキスト使用量を可視化 |
| `/privacy-settings` | プライバシー設定（Pro/Max） |

### コード / ファイル操作

| コマンド | 説明 |
|----------|------|
| `/add-dir <path>` | 作業ディレクトリを追加 |
| `/diff` | コミットされていない変更のインタラクティブ diff |
| `/copy [N]` | 直近の応答をクリップボードにコピー |
| `/plan` | プランモードに入る |
| `/security-review` | 保留中の変更のセキュリティ分析 |

### 認証

| コマンド | 説明 |
|----------|------|
| `/login` | サインイン |
| `/logout` | サインアウト |

### MCP / 連携

| コマンド | 説明 |
|----------|------|
| `/mcp` | MCP サーバー管理 |
| `/chrome` | Chrome 連携設定 |
| `/ide` | IDE 連携管理 |
| `/plugin` | プラグイン管理 |
| `/reload-plugins` | プラグイン再読み込み |
| `/install-github-app` | GitHub Actions 連携セットアップ |
| `/install-slack-app` | Slack アプリ連携 |
| `/pr-comments [PR]` | GitHub PR コメント取得 |
| `/remote-control` | claude.ai からのリモート操作を許可 |
| `/desktop` | Desktop アプリでセッション継続（macOS/Windows） |
| `/mobile` | モバイルアプリの QR コード表示 |

### メモリ / 設定ファイル

| コマンド | 説明 |
|----------|------|
| `/memory` | CLAUDE.md の編集・auto-memory の管理 |
| `/doctor` | インストール状態の診断 |
| `/init` | CLAUDE.md の初期化 |

### ユーティリティ

| コマンド | 説明 |
|----------|------|
| `/btw <質問>` | 会話に影響しないサイド質問 |
| `/help` | ヘルプ表示 |
| `/feedback` | フィードバック送信 |
| `/release-notes` | リリースノート表示 |
| `/stats` | 使用統計の可視化 |
| `/insights` | セッション分析レポート生成 |
| `/hooks` | Hook 設定の確認 |
| `/agents` | エージェント設定の管理 |
| `/skills` | 利用可能なスキル一覧 |
| `/tasks` | バックグラウンドタスク管理 |
| `/voice` | プッシュトゥトーク音声入力トグル |
| `/stickers` | Claude Code ステッカー注文 |

---

## CLI フラグ / オプション

### セッション

| フラグ | 説明 |
|--------|------|
| `claude` | インタラクティブセッション開始 |
| `claude "prompt"` | 初期プロンプト付きで開始 |
| `-p` / `--print` | 非対話モード（結果出力して終了） |
| `-c` / `--continue` | 直近のセッションを再開 |
| `-r` / `--resume` | 指定セッションを再開 |
| `-n` / `--name` | セッション名を設定 |
| `-w` / `--worktree` | Git worktree で隔離起動 |
| `--session-id` | セッション UUID を指定 |
| `--fork-session` | 既存セッションを複製して再開 |

### モデル / パフォーマンス

| フラグ | 説明 |
|--------|------|
| `--model` | モデル指定（opus, sonnet, haiku） |
| `--effort` | エフォートレベル |
| `--fast [on\|off]` | Fast モード |
| `--fallback-model` | プライマリモデル過負荷時のフォールバック |

### パーミッション

| フラグ | 説明 |
|--------|------|
| `--permission-mode` | パーミッションモード指定（default / plan / acceptEdits / dontAsk / bypassPermissions） |
| `--dangerously-skip-permissions` | 全パーミッションをスキップ（要注意） |
| `--allowedTools` | 自動許可するツール |
| `--disallowedTools` | ブロックするツール |

### システムプロンプト

| フラグ | 説明 |
|--------|------|
| `--system-prompt` | デフォルトプロンプトを置換 |
| `--append-system-prompt` | デフォルトプロンプトに追記 |
| `--system-prompt-file` | ファイルからプロンプト読み込み |
| `--append-system-prompt-file` | ファイルからプロンプトに追記 |

### 入出力

| フラグ | 説明 |
|--------|------|
| `--output-format` | 出力形式（text / json / stream-json） |
| `--input-format` | 入力形式（text / stream-json） |
| `--json-schema` | JSON スキーマに沿った出力（print モード） |
| `--max-turns` | エージェントターン数の上限（print モード） |
| `--max-budget-usd` | 最大予算（print モード） |

### MCP / ツール

| フラグ | 説明 |
|--------|------|
| `--mcp-config` | MCP 設定 JSON を読み込み |
| `--strict-mcp-config` | 指定 MCP のみ使用 |
| `--tools` | 使用可能なツールを制限 |
| `--add-dir` | 追加の作業ディレクトリ |
| `--settings` | 追加設定ファイルの読み込み |
| `--plugin-dir` | プラグインディレクトリ指定 |
| `--chrome` / `--no-chrome` | Chrome 連携の有効化 / 無効化 |

### エージェント

| フラグ | 説明 |
|--------|------|
| `--agent` | エージェント指定 |
| `--agents` | カスタムサブエージェントを JSON で定義 |
| `--teammate-mode` | エージェントチーム表示モード（auto / in-process / tmux） |

### リモート / 特殊モード

| フラグ | 説明 |
|--------|------|
| `--remote` | claude.ai 上にリモートセッション作成 |
| `--remote-control` | claude.ai からのリモート操作を許可 |
| `--teleport` | Web セッションをローカルに移行 |
| `--from-pr` | GitHub PR に紐づくセッションを再開 |
| `--ide` | IDE 自動接続 |
| `--init` / `--init-only` | 初期化 Hook の実行（`--init-only` は実行後終了） |

### デバッグ

| フラグ | 説明 |
|--------|------|
| `--debug` | デバッグモード有効化 |
| `--verbose` | 詳細出力 |
| `-v` / `--version` | バージョン表示 |

---

## パーミッションモード

| モード | ファイル編集 | コマンド実行 | 用途 |
|--------|-------------|-------------|------|
| `default` | 確認あり | 確認あり | 通常利用 |
| `acceptEdits` | 自動許可 | 確認あり | 編集中心の作業 |
| `plan` | 不可 | 不可 | 分析・計画のみ |
| `dontAsk` | 事前許可のみ | 事前許可のみ | CI/CD 向け |
| `bypassPermissions` | 全許可 | 全許可 | 要注意 |

---

## パーミッションルール

### 書式

```
Tool                        # 全操作を許可
Tool(specifier)             # 特定操作のみ許可
Tool(pattern*)              # ワイルドカード
```

### 例

| ルール | 対象 |
|--------|------|
| `Bash(git log *)` | `git log` 系コマンド |
| `Bash(npm run *)` | `npm run` 系コマンド |
| `Read(/src/**)` | src/ 配下の読み取り |
| `Edit(/docs/**)` | docs/ 配下の編集 |
| `WebFetch(domain:example.com)` | 特定ドメインへの fetch |
| `mcp__server__tool` | 特定 MCP ツール |

### パスパターン

| パターン | 意味 |
|----------|------|
| `//path` | ファイルシステムルートからの絶対パス |
| `~/path` | ホームディレクトリからのパス |
| `/path` | プロジェクトルートからの相対パス |
| `./path` | カレントディレクトリからの相対パス |

### settings.json での設定

```json
{
  "permissions": {
    "allow": ["Read", "Bash(git log *)"],
    "ask": ["Bash(git push *)"],
    "deny": ["Bash(rm -rf *)"]
  }
}
```

優先順: **deny > ask > allow**

---

## 設定ファイル

| スコープ | パス | 共有 |
|----------|------|------|
| ユーザー | `~/.claude/settings.json` | No |
| プロジェクト | `.claude/settings.json` | Yes（git 管理） |
| ローカル | `.claude/settings.local.json` | No（gitignore） |
| CLAUDE.md（ユーザー） | `~/.claude/CLAUDE.md` | No |
| CLAUDE.md（プロジェクト） | `.claude/CLAUDE.md` | Yes |
| ルールファイル | `.claude/rules/*.md` | Yes |
| MCP 設定 | `.claude/.mcp.json` | Yes |
| キーバインド | `.claude/keybindings.json` | - |
| メモリ | `~/.claude/memory/` | No |

---

## Hooks

### イベント一覧

| イベント | トリガー |
|----------|----------|
| `SessionStart` | セッション開始 |
| `InstructionsLoaded` | CLAUDE.md 読み込み時 |
| `UserPromptSubmit` | ユーザープロンプト送信前 |
| `PreToolUse` | ツール実行前 |
| `PermissionRequest` | パーミッション確認ダイアログ表示時 |
| `PostToolUse` | ツール実行後 |
| `PostToolUseFailure` | ツール実行失敗後 |
| `PreCompact` / `PostCompact` | コンテキスト圧縮の前後 |
| `Stop` | セッション終了 |
| `SubagentStart` / `SubagentStop` | サブエージェントのライフサイクル |
| `WorktreeCreate` / `WorktreeRemove` | Git worktree の作成 / 削除 |

### 設定例

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{ "type": "command", "command": "~/scripts/pre_bash.sh" }]
      }
    ]
  }
}
```

---

## よく使うワークフロー

### セッション再開

```bash
claude -c                    # 直近のセッション
claude -r "session-name"     # 名前で指定
claude -r                    # インタラクティブに選択
```

### パイプ入力

```bash
cat file.txt | claude -p "要約して"
git diff | claude -p "レビューして"
```

### Plan モードで分析

```bash
claude --permission-mode plan
# またはセッション中に Shift+Tab で切替
```

### Worktree で並列作業

```bash
claude -w feature-auth       # 隔離された worktree で作業
```

### カスタムシステムプロンプト

```bash
claude --append-system-prompt "TypeScript で書いて"
```

---

## 環境変数

| 変数 | 説明 |
|------|------|
| `ANTHROPIC_API_KEY` | API キー |
| `ANTHROPIC_BASE_URL` | API ベース URL |
| `CLAUDE_MODEL` | デフォルトモデル |
| `CLAUDE_EFFORT` | デフォルトエフォートレベル |
| `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS` | バックグラウンドタスク無効化 |
| `CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR` | cwd を維持 |
| `BASH_DEFAULT_TIMEOUT_MS` | Bash タイムアウト（デフォルト: 1200000ms） |
| `BASH_MAX_TIMEOUT_MS` | Bash 最大タイムアウト |
