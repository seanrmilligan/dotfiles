#!/usr/bin/env bash
# Custom Antigravity CLI statusline
# Receives JSON payload on stdin, outputs ANSI-formatted powerline string.
#
# Payload schema (discovered from live CLI):
#   .model.display_name              — e.g. "Claude Opus 4.6 (Thinking)"
#   .workspace.current_dir           — e.g. "/home/sean"
#   .context_window.used_percentage  — e.g. 28.77
#   .context_window.context_window_size — e.g. 250000
#   .context_window.total_input_tokens  + .total_output_tokens
#   .quota."3p-5h".remaining_fraction   — 0.0–1.0 (third-party model 5h window)
#   .quota."3p-5h".reset_in_seconds
#   .quota."3p-weekly".remaining_fraction
#   .quota."gemini-5h".remaining_fraction
#   .quota."gemini-weekly".remaining_fraction

set -euo pipefail

input="$(cat)"

# --- Extract fields ---
model="$(echo "$input" | jq --raw-output '.model.display_name // .model.id // "?"')"
workspace="$(echo "$input" | jq --raw-output '.workspace.current_dir // .workspace.project_dir // "?"')"

# Context window
ctx_used_pct="$(echo "$input" | jq --raw-output '.context_window.used_percentage // "?"')"
ctx_total="$(echo "$input" | jq --raw-output '.context_window.context_window_size // "?"')"
ctx_input="$(echo "$input" | jq --raw-output '.context_window.total_input_tokens // 0')"
ctx_output="$(echo "$input" | jq --raw-output '.context_window.total_output_tokens // 0')"

# Quota — pick the most relevant bucket based on model
# Third-party models (Claude, etc.) use "3p-*"; Gemini models use "gemini-*"
# Show the 5-hour rolling window (the binding constraint)
q5h_remaining="$(echo "$input" | jq --raw-output '(.quota["3p-5h"].remaining_fraction // .quota["gemini-5h"].remaining_fraction // empty)')"
q5h_reset_s="$(echo "$input" | jq --raw-output '(.quota["3p-5h"].reset_in_seconds // .quota["gemini-5h"].reset_in_seconds // empty)')"
qweek_remaining="$(echo "$input" | jq --raw-output '(.quota["3p-weekly"].remaining_fraction // .quota["gemini-weekly"].remaining_fraction // empty)')"

# --- Shorten workspace to ~ path ---
if [[ "$workspace" == "$HOME"* ]]; then
  workspace="~${workspace#"$HOME"}"
fi
# Truncate if still long
if [[ "${#workspace}" -gt 30 ]]; then
  workspace="…/$(basename "$workspace")"
fi
# Handle bare home dir
if [[ "$workspace" == "~" ]]; then
  workspace="~"
fi

# --- Format token counts with K/M suffix ---
format_tokens() {
  local val="$1"
  if [[ "$val" == "?" || -z "$val" ]]; then
    echo "?"
    return
  fi
  if [[ "$val" -ge 1000000 ]] 2>/dev/null; then
    printf "%.0fM" "$(echo "scale=1; $val / 1000000" | bc)"
  elif [[ "$val" -ge 1000 ]] 2>/dev/null; then
    printf "%.0fK" "$(echo "scale=1; $val / 1000" | bc)"
  else
    echo "$val"
  fi
}

# --- Format seconds to human-readable duration ---
format_duration() {
  local secs="$1"
  if [[ -z "$secs" || "$secs" == "null" ]]; then
    echo "?"
    return
  fi
  local h m
  h=$(( secs / 3600 ))
  m=$(( (secs % 3600) / 60 ))
  if [[ "$h" -gt 0 ]]; then
    printf "%dh%02dm" "$h" "$m"
  else
    printf "%dm" "$m"
  fi
}

# --- Format remaining fraction to percentage ---
format_pct() {
  local frac="$1"
  if [[ -z "$frac" || "$frac" == "null" ]]; then
    echo "?"
    return
  fi
  # Invert: show used percentage (100% = depleted)
  printf "%.0f%%" "$(echo "(1 - $frac) * 100" | bc)"
}

# Context window display
ctx_tokens="$(( ctx_input + ctx_output ))"
ctx_tokens_fmt="$(format_tokens "$ctx_tokens")"
ctx_total_fmt="$(format_tokens "$ctx_total")"

# Round used_percentage for display
if [[ "$ctx_used_pct" != "?" ]]; then
  ctx_pct_fmt="$(printf "%.0f" "$ctx_used_pct")"
else
  ctx_pct_fmt="?"
fi

# Quota display
q5h_pct_fmt="$(format_pct "${q5h_remaining:-}")"
q5h_reset_fmt="$(format_duration "${q5h_reset_s:-}")"
qweek_pct_fmt="$(format_pct "${qweek_remaining:-}")"

# --- Determine quota color based on 5h remaining fraction ---
# remaining_fraction: 1.0 = full, 0.0 = empty
quota_color="32"  # green — healthy
if [[ -n "$q5h_remaining" && "$q5h_remaining" != "null" ]]; then
  # Compare as integer percentage (used = 1 - remaining)
  q5h_used_int="$(printf "%.0f" "$(echo "(1 - $q5h_remaining) * 100" | bc)")"
  if [[ "$q5h_used_int" -ge 90 ]]; then
    quota_color="31"   # red — critical (≥90% used)
  elif [[ "$q5h_used_int" -ge 70 ]]; then
    quota_color="33"   # yellow — warning (≥70% used)
  fi
fi

# --- ANSI helpers ---
reset=$'\e[0m'
bold=$'\e[1m'
fg_black=$'\e[30m'

bg_blue=$'\e[44m'
bg_magenta=$'\e[45m'
bg_cyan=$'\e[46m'
bg_green=$'\e[42m'
bg_yellow=$'\e[43m'
bg_red=$'\e[41m'

# Powerline separator (U+E0B0 — requires Nerd Font)
sep=$'\xee\x82\xb0'

# --- Determine quota segment background ---
case "$quota_color" in
  31) bg_quota="$bg_red"    ; fg_quota=$'\e[31m' ;;
  33) bg_quota="$bg_yellow" ; fg_quota=$'\e[33m' ;;
  *)  bg_quota="$bg_green"  ; fg_quota=$'\e[32m' ;;
esac

# --- Render powerline segments ---
out=""

# Segment 1 — Model (blue)
out+="${bg_blue}${fg_black}${bold} ◆ ${model} ${reset}"
out+="${bg_magenta}\e[34m${sep}${reset}"

# Segment 2 — Workspace (magenta)
out+="${bg_magenta}${fg_black}${bold}  ${workspace} ${reset}"
out+="${bg_cyan}\e[35m${sep}${reset}"

# Segment 3 — Context Window (cyan)
out+="${bg_cyan}${fg_black}${bold} 󰞒 ${ctx_tokens_fmt}/${ctx_total_fmt} (${ctx_pct_fmt}%) ${reset}"
out+="${bg_quota}\e[36m${sep}${reset}"

# Segment 4 — Quota (green/yellow/red)
out+="${bg_quota}${fg_black}${bold} 󰄶 5h:${q5h_pct_fmt} ↻${q5h_reset_fmt} │ wk:${qweek_pct_fmt} ${reset}"
out+="${fg_quota}${sep}${reset}"

echo -ne "$out"
