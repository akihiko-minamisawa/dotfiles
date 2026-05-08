#!/bin/sh
# Claude Code statusline script
# Segments: model | git branch (if any) | tokens | context% | 5h limit | 7d limit

# ANSI color codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
DIM='\033[2m'
RESET='\033[0m'

input=$(cat)

# 1. Model display name
model=$(echo "$input" | jq -r '.model.display_name // "unknown"')

# 2. Git branch — run against the reported cwd
raw_dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
git_branch=""
if [ -n "$raw_dir" ] && [ -d "$raw_dir" ]; then
  git_branch=$(git -C "$raw_dir" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
fi

# 3. Token usage (cumulative input + output for the session)
total_in=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
total_out=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
total_tokens=$((total_in + total_out))

# 4. Context window usage percentage
ctx_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -z "$ctx_pct" ]; then
  win_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
  cur_in=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // empty')
  if [ -n "$win_size" ] && [ -n "$cur_in" ] && [ "$win_size" -gt 0 ] 2>/dev/null; then
    ctx_pct=$(echo "$cur_in $win_size" | awk '{printf "%.1f", ($1/$2)*100}')
  fi
fi
if [ -z "$ctx_pct" ]; then
  ctx_pct=0
fi

# 5. Rate limits (5-hour and 7-day)
five_h_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_h_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
seven_d_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
seven_d_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# Helper: pick color by percentage
pct_color() {
  p=$(printf '%.0f' "${1:-0}")
  if [ "$p" -ge 80 ]; then printf '%s' "$RED"
  elif [ "$p" -ge 50 ]; then printf '%s' "$YELLOW"
  else printf '%s' "$GREEN"
  fi
}

# Helper: seconds → "2d3h15m", "3h15m", or "45m"
fmt_duration() {
  secs="$1"
  d=$((secs / 86400))
  h=$(( (secs % 86400) / 3600 ))
  m=$(( (secs % 3600) / 60 ))
  if [ "$d" -gt 0 ]; then
    printf '%dd%dh%02dm' "$d" "$h" "$m"
  elif [ "$h" -gt 0 ]; then
    printf '%dh%02dm' "$h" "$m"
  else
    printf '%dm' "$m"
  fi
}

# Helper: build a 20-cell bar graph string from a percentage (float)
# Usage: result=$(mk_bar 57.5)
mk_bar() {
  total_eighths=$(awk -v p="$1" 'BEGIN { v=(p*160/100)+0.5; printf "%d", v }')
  [ "$total_eighths" -gt 160 ] && total_eighths=160
  [ "$total_eighths" -lt 0 ]   && total_eighths=0
  bar=""
  i=0
  while [ "$i" -lt 20 ]; do
    cell=$((total_eighths - i * 8))
    [ "$cell" -gt 8 ] && cell=8
    [ "$cell" -lt 0 ] && cell=0
    case "$cell" in
      0) bar="${bar}░" ;;
      1) bar="${bar}▏" ;;
      2) bar="${bar}▎" ;;
      3) bar="${bar}▍" ;;
      4) bar="${bar}▌" ;;
      5) bar="${bar}▋" ;;
      6) bar="${bar}▊" ;;
      7) bar="${bar}▉" ;;
      8) bar="${bar}█" ;;
    esac
    i=$((i + 1))
  done
  printf '%s' "$bar"
}

# Build output using printf for ANSI portability
SEP="${DIM} | ${RESET}"

# Model segment (cyan)
printf "${CYAN}%s${RESET}" "$model"

# Git branch segment (green), only if present
if [ -n "$git_branch" ]; then
  printf "${SEP}${GREEN}%s${RESET}" "$git_branch"
fi

# Token count segment (yellow), formatted as k/M
fmt_tokens=$(awk -v n="$total_tokens" 'BEGIN {
  if (n >= 1000000) printf "%.1fM", n/1000000;
  else if (n >= 1000)  printf "%.1fk", n/1000;
  else                 printf "%d",   n;
}')
printf "${SEP}${YELLOW}%s${RESET}" "$fmt_tokens"

# Context % segment — bar graph + percentage
ctx_pct_int=$(printf '%.0f' "$ctx_pct")
CTX_COLOR=$(pct_color "$ctx_pct")
ctx_bar=$(mk_bar "$ctx_pct")
printf "${SEP}${CTX_COLOR}ctx:%s %d%%${RESET}" "$ctx_bar" "$ctx_pct_int"

# 5-hour rate limit segment — bar graph + percentage + time to reset
if [ -n "$five_h_pct" ]; then
  five_h_int=$(printf '%.0f' "$five_h_pct")
  FIVE_COLOR=$(pct_color "$five_h_pct")
  five_bar=$(mk_bar "$five_h_pct")

  reset_str=""
  if [ -n "$five_h_reset" ]; then
    now=$(date +%s)
    remaining=$((five_h_reset - now))
    if [ "$remaining" -gt 0 ]; then
      reset_str=" $(fmt_duration "$remaining")"
    fi
  fi

  printf "${SEP}${FIVE_COLOR}5h:%s %d%%%s${RESET}" "$five_bar" "$five_h_int" "$reset_str"
else
  printf "${SEP}${DIM}5h:--${RESET}"
fi

# 7-day rate limit segment — bar graph + percentage + time to reset
if [ -n "$seven_d_pct" ]; then
  seven_d_int=$(printf '%.0f' "$seven_d_pct")
  SEVEN_COLOR=$(pct_color "$seven_d_pct")
  seven_bar=$(mk_bar "$seven_d_pct")

  seven_reset_str=""
  if [ -n "$seven_d_reset" ]; then
    now=$(date +%s)
    remaining=$((seven_d_reset - now))
    if [ "$remaining" -gt 0 ]; then
      seven_reset_str=" $(fmt_duration "$remaining")"
    fi
  fi

  printf "${SEP}${SEVEN_COLOR}7d:%s %d%%%s${RESET}" "$seven_bar" "$seven_d_int" "$seven_reset_str"
else
  printf "${SEP}${DIM}7d:--${RESET}"
fi

printf "${RESET}"

