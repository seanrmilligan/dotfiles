#!/usr/bin/env bash

input=$(cat)

cwd=$(echo "$input" | jq -r '.cwd')
model=$(echo "$input" | jq -r '.model.display_name')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Compute display path (mirror .bashrc logic)
home="$HOME"
workspace_root="$home/projects"

case "$cwd" in
  "$workspace_root"/*)
    display_dir="@${cwd#"$workspace_root"/}"
    ;;
  "$home"*)
    display_dir="~${cwd#"$home"}"
    ;;
  *)
    display_dir="$cwd"
    ;;
esac

# ANSI colors (matching .bashrc set_color_prompt)
BLUELIGHT="\e[0;94m"
GREEN="\e[0;32m"
RESET="\e[0m"

# Git branch and state (skip locks to avoid contention)
git_head=""
git_dot=""
if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git_head=$(git -C "$cwd" symbolic-ref --short -q HEAD 2>/dev/null \
             || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)

  # Determine repo state (dirty / unpushed / clean)
  git -C "$cwd" update-index -q --refresh 2>/dev/null
  if [ -n "$(git -C "$cwd" ls-files --others --exclude-standard 2>/dev/null | head -n1)" ] \
     || ! git -C "$cwd" diff-index --quiet HEAD -- 2>/dev/null; then
    git_dot="\e[0;31m●\e[0m"   # red = dirty
  elif git -C "$cwd" rev-parse --verify HEAD >/dev/null 2>&1 \
       && { ! git -C "$cwd" rev-parse --verify @{upstream} >/dev/null 2>&1 \
            || [ "$(git -C "$cwd" rev-list --count @{upstream}..HEAD 2>/dev/null)" -gt 0 ]; }; then
    git_dot="\e[0;33m●\e[0m"   # yellow = unpushed
  else
    git_dot="\e[0;32m●\e[0m"   # green = clean
  fi
fi

# Context usage indicator
ctx_part=""
if [ -n "$used_pct" ]; then
  ctx_int=$(printf '%.0f' "$used_pct")
  ctx_part=" ctx:${ctx_int}%"
fi

# Assemble the line
if [ -n "$git_head" ]; then
  printf "${GREEN}●${RESET} ${BLUELIGHT}%s${RESET} (%s %b)  %s%s\n" \
    "$display_dir" "$git_head" "$git_dot" "$model" "$ctx_part"
else
  printf "${GREEN}●${RESET} ${BLUELIGHT}%s${RESET}  %s%s\n" \
    "$display_dir" "$model" "$ctx_part"
fi
