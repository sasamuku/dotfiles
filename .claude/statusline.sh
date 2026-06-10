#!/bin/bash
# Claude Code statusline: dir/branch + model / context / 5h・7d rate limits / session・daily cost
# stdin JSON spec: https://code.claude.com/docs/en/statusline

input=$(cat)

# 区切りは \x1f (タブは IFS 空白扱いで空フィールドが潰れるため)
IFS=$'\x1f' read -r model effort cwd project ctx cost fh_pct fh_reset sd_pct sd_reset < <(echo "$input" | jq -r '[
  (.model.display_name // "Claude"),
  (.effort.level // ""),
  (.workspace.current_dir // .cwd),
  (.workspace.project_dir // ""),
  (.context_window.remaining_percentage // "" | tostring),
  (.cost.total_cost_usd // "" | tostring),
  (.rate_limits.five_hour.used_percentage // "" | tostring),
  (.rate_limits.five_hour.resets_at // "" | tostring),
  (.rate_limits.seven_day.used_percentage // "" | tostring),
  (.rate_limits.seven_day.resets_at // "" | tostring)
] | join("\u001f")')

DIM=$'\033[2m'; RST=$'\033[0m'
CYAN=$'\033[36m'; YELLOW=$'\033[33m'
SEP="${DIM} | ${RST}"

# Nerd Font グリフ (UTF-8 バイトで定義。エディタ事故での欠落防止)
I_DIR=$'\xef\x81\xbb'        # nf-fa-folder      U+F07B
I_BRANCH=$'\xee\x9c\xa5'     # nf-dev-git_branch U+E725
I_MODEL=$'\xf3\xb0\x9a\xa9'  # nf-md-robot       U+F06A9
I_5H=$'\xef\x80\x97'         # nf-fa-clock_o     U+F017
I_7D=$'\xef\x81\xb3'         # nf-fa-calendar    U+F073
I_COST=$'\xef\x83\x96'       # nf-fa-money       U+F0D6
I_EFFORT=$'\xef\x83\xa4'     # nf-fa-tachometer  U+F0E4

# コンテキスト残量に応じた電池アイコン (nf-fa-battery_* U+F240-F244)
ctx_icon() {
  local r=${1%%.*}
  if [ "$r" -ge 85 ]; then printf '\xef\x89\x80'
  elif [ "$r" -ge 60 ]; then printf '\xef\x89\x81'
  elif [ "$r" -ge 35 ]; then printf '\xef\x89\x82'
  elif [ "$r" -ge 10 ]; then printf '\xef\x89\x83'
  else printf '\xef\x89\x84'; fi
}

# 使用率に応じた色 (<50 緑, <80 黄, >=80 赤)
pct_color() {
  local p=${1%%.*}
  if [ "$p" -ge 80 ]; then printf '\033[31m'
  elif [ "$p" -ge 50 ]; then printf '\033[33m'
  else printf '\033[32m'; fi
}

# 当日コスト (ccusage, 5 分キャッシュ・バックグラウンド更新)
daily_cost() {
  local cache="/tmp/claude_statusline_daily_$(date +%Y%m%d)_$(id -u)"
  local now mtime
  now=$(date +%s)
  mtime=$(stat -f %m "$cache" 2>/dev/null || echo 0)
  if [ $((now - mtime)) -gt 300 ]; then
    touch "$cache"
    (bunx ccusage daily --since "$(date +%Y%m%d)" --json 2>/dev/null \
      | jq -r '.totals.totalCost // empty' > "$cache.tmp" && mv "$cache.tmp" "$cache") &
  fi
  cat "$cache" 2>/dev/null
}

# USD→JPY レート (frankfurter.dev = ECB 公表値, 日次キャッシュ・バックグラウンド更新)
usd_jpy_rate() {
  local cache="/tmp/claude_statusline_usdjpy_$(id -u)"
  local now mtime
  now=$(date +%s)
  mtime=$(stat -f %m "$cache" 2>/dev/null || echo 0)
  if [ $((now - mtime)) -gt 86400 ]; then
    touch "$cache"
    (curl -s --max-time 3 "https://api.frankfurter.dev/v1/latest?base=USD&symbols=JPY" \
      | jq -r '.rates.JPY // empty' > "$cache.tmp" && [ -s "$cache.tmp" ] && mv "$cache.tmp" "$cache") &
  fi
  cat "$cache" 2>/dev/null
}
JPY_RATE=$(usd_jpy_rate)

# レート取得済みなら円 (整数・カンマ区切り)、なければドル
fmt_cost() {
  if [ -n "$JPY_RATE" ]; then
    LC_ALL=en_US.UTF-8 printf "¥%'.0f" "$(awk -v u="$1" -v r="$JPY_RATE" 'BEGIN{print u*r}')"
  else
    printf '$%.2f' "$1"
  fi
}

# Line 1: 📁 dir (project 配下のサブディレクトリなら project/相対パス) | ⎇ branch
if [ -n "$project" ] && [ "$cwd" != "$project" ] && [[ "$cwd" == "$project"/* ]]; then
  rel_path="$(basename "$project")/${cwd#"$project"/}"
else
  rel_path=$(basename "$cwd")
fi
line1="${I_DIR} ${CYAN}${rel_path}${RST}"
if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
  line1+="${SEP}${YELLOW}${I_BRANCH} ${branch:-detached}${RST}"
fi
printf '%s\n' "$line1"

# Line 2: model | style | ctx% | 5h | 7d | session cost | daily cost
line2="${I_MODEL} ${model}"
[ -n "$effort" ] && line2+="${SEP}${I_EFFORT} ${effort}"
[ -n "$ctx" ] && line2+="${SEP}$(ctx_icon "$ctx") $(pct_color "$((100 - ${ctx%%.*}))")${ctx}%%${RST}"
if [ -n "$fh_pct" ]; then
  line2+="${SEP}${I_5H} 5h $(pct_color "$fh_pct")$(awk -v p="$fh_pct" 'BEGIN{printf "%.0f", 100-p}')%%${RST} ${DIM}↻$(date -r "$fh_reset" '+%H:%M')${RST}"
fi
if [ -n "$sd_pct" ]; then
  line2+="${SEP}${I_7D} 7d $(pct_color "$sd_pct")$(awk -v p="$sd_pct" 'BEGIN{printf "%.0f", 100-p}')%%${RST} ${DIM}↻$(date -r "$sd_reset" '+%-m/%-d %H:%M')${RST}"
fi
[ -n "$cost" ] && line2+="${SEP}${I_COST} $(fmt_cost "$cost") ${DIM}(session)${RST}"
daily=$(daily_cost)
[ -n "$daily" ] && line2+="${SEP}${I_COST} $(fmt_cost "$daily") ${DIM}(daily)${RST}"
printf "$line2\n"
