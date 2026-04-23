---
name: copy-resume
description: Copies `claude -r <session-id> --fork-session` for the current session to the clipboard. Use when the user wants to fork the current session into a new branch from another terminal, or asks to copy the fork command, session id, or `/fork` command.
disable-model-invocation: true
allowed-tools: Bash(bash -c *)
---

# Copy Resume

現在のセッションから分岐 (fork) するコマンド `claude -r <session-id> --fork-session` を pbcopy する。`/fork` と同等の挙動を別ターミナルで行うためのもの。

## タスク

以下を **そのまま** 1 回の Bash 呼び出しで実行する:

```bash
bash -c '
PROJECT_DIR=$(pwd | sed "s|[/.]|-|g")
SESSION_FILE=$(ls -t ~/.claude/projects/"${PROJECT_DIR}"/*.jsonl 2>/dev/null | head -1)
if [ -z "$SESSION_FILE" ]; then
  echo "error: no session file found for $(pwd)" >&2
  exit 1
fi
SESSION_ID=$(basename "$SESSION_FILE" .jsonl)
CMD="claude -r $SESSION_ID --fork-session"
printf "%s" "$CMD" | pbcopy
echo "copied: $CMD"
'
```

出力の `copied: ...` 行をそのままユーザーへ返す。それ以上の説明は不要。

## 備考

- Claude Code の session JSONL はファイル名が sessionId になっている (`~/.claude/projects/<encoded-cwd>/<session-id>.jsonl`)
- encoded-cwd は `pwd` の `/` と `.` を `-` に変換したもの (先頭は元々 `/` なので自動的に `-` 始まりになる)
- スキル実行中は現セッションが最新更新なので `ls -t | head -1` で取れる
- zsh の nomatch エラーを避けるため `bash -c` で実行する
