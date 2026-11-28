#!/usr/bin/env bash
# Claude Code statusLine command — two lines:
#   1. directory + git branch/state, converted from the ~/.bashrc
#      `set_prompt` / `set_color_prompt` PS1 setup
#   2. session cost + current model and reasoning effort
#
# Both lines are left-aligned. An earlier revision right-aligned line 2 against
# $COLUMNS, but the status bar is inset and shares its row with system
# notifications, so the tail kept getting clipped with an ellipsis.
#
# Notes on the conversion:
#   - The original prompt showed a colored dot for the exit code of the last
#     shell command. Claude Code's status line has no concept of a "last
#     command exit code", so that segment has been omitted.
#   - Everything else (directory formatting relative to $WORKSPACE_ROOT / $HOME,
#     the current git branch or commit hash, and the dirty/unpushed/clean
#     status dot) has been preserved.
#   - Width checks use $COLUMNS, which Claude Code sets before running this
#     script. `tput cols` does not work here: stdout is captured, not a tty.

# --- tunable ----------------------------------------------------------------
# Columns held back from the right edge when deciding whether the second line
# fits. $COLUMNS is the full terminal width, but the status bar is inset by the
# interface's own spacing. Both lines are left-aligned, so this only controls how
# early the second line drops detail to avoid wrapping — it costs nothing to
# keep a little generous.
RIGHT_MARGIN=${CLAUDE_STATUSLINE_RIGHT_MARGIN:-6}
# ----------------------------------------------------------------------------

input=$(cat)

# Diagnostic: set CLAUDE_STATUSLINE_RULER=1 to render a column ruler the full
# width of $COLUMNS instead of the status line. Read off the last digit still
# visible in the terminal to get the real usable width, then set RIGHT_MARGIN to
# ($COLUMNS - that width). Tens columns show their tens digit, fives show '|'.
if [ -n "${CLAUDE_STATUSLINE_RULER:-}" ]; then
  ruler=""
  for ((i = 1; i <= ${COLUMNS:-80}; i++)); do
    if [ $((i % 10)) -eq 0 ]; then
      ruler+="$(( (i / 10) % 10 ))"
    elif [ $((i % 5)) -eq 0 ]; then
      ruler+="|"
    else
      ruler+="."
    fi
  done
  printf 'COLUMNS=%s %s' "${COLUMNS:-unset}" "$ruler"
  exit 0
fi

# Join on US (0x1f) rather than tab: bash treats tab as IFS whitespace and
# collapses runs of it, which silently shifts the fields whenever one is empty
# (e.g. a model with no `effort`).
IFS=$'\x1f' read -r cwd model_name effort thinking cost < <(
  printf '%s' "$input" | jq -r '[
    .workspace.current_dir,
    (.model.display_name // ""),
    (.effort.level // ""),
    (.thinking.enabled // false | tostring),
    (.cost.total_cost_usd // "" | tostring)
  ] | join("")'
)

WORKSPACE_ROOT="$HOME/projects"

case "$cwd" in
  "$WORKSPACE_ROOT"/*)
    # Format paths in $WORKSPACE_ROOT as @workspace/
    current_directory="@${cwd#"$WORKSPACE_ROOT"/}"
    ;;
  "$HOME"*)
    # Format paths in $HOME as ~/ instead of /home/<user>
    current_directory="~${cwd#"$HOME"}"
    ;;
  *)
    current_directory="$cwd"
    ;;
esac

git_head=""
repository_state=""

# Use --no-optional-locks so the status line never blocks on/competes for the
# repository lock with other git processes.
if git -C "$cwd" --no-optional-locks rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git_head=$(git -C "$cwd" --no-optional-locks symbolic-ref --short -q HEAD 2>/dev/null || \
             git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)

  hash_algo=$(git -C "$cwd" --no-optional-locks rev-parse --show-object-format 2>/dev/null)
  case "$hash_algo" in
    sha256) empty_commit_hash="6efc71244b74872f232490b39678e71869e90479b634c03847f938d825c4e976" ;;
    *)      empty_commit_hash="4b825dc642cb6eb9a060e54bf8d69288fbee4904" ;;
  esac
  latest_commit=$(git -C "$cwd" --no-optional-locks rev-parse --verify HEAD 2>/dev/null || echo "$empty_commit_hash")

  untracked=$(git -C "$cwd" --no-optional-locks ls-files --others --exclude-standard 2>/dev/null | head -n 1)

  if [ -n "$untracked" ]; then
    repository_state="dirty"
  elif ! git -C "$cwd" --no-optional-locks diff-index --quiet "$latest_commit" -- 2>/dev/null; then
    repository_state="dirty"
  elif git -C "$cwd" --no-optional-locks rev-parse --verify HEAD >/dev/null 2>&1 && {
         ! git -C "$cwd" --no-optional-locks rev-parse --verify '@{upstream}' >/dev/null 2>&1 || \
         [ "$(git -C "$cwd" --no-optional-locks rev-list --count '@{upstream}..HEAD' 2>/dev/null)" -gt 0 ]
       }; then
    repository_state="unpushed"
  else
    repository_state="clean"
  fi
fi

BLUELIGHT='\033[0;94m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
WHITE='\033[0;37m'
GREY='\033[0;90m'
RESET='\033[0m'

case "$repository_state" in
  dirty)    GIT_STATUS_COLOR="$RED" ;;
  unpushed) GIT_STATUS_COLOR="$YELLOW" ;;
  clean)    GIT_STATUS_COLOR="$GREEN" ;;
  *)        GIT_STATUS_COLOR="$WHITE" ;;
esac

DOT=$'\xe2\x97\x8f'

# Line 1.
if [ -n "$git_head" ]; then
  first_line="${BLUELIGHT}${current_directory}${RESET} (${git_head} ${GIT_STATUS_COLOR}${DOT}${RESET})"
else
  first_line="${BLUELIGHT}${current_directory}${RESET}"
fi

# Line 2: "$1.23 · Claude Opus 5 (1M · Thinking · High)". Every parenthetical
# tag is
# optional — `effort` is absent on models without the effort parameter, and
# `thinking.enabled` can be false.
SEP=$'\xc2\xb7'

# `display_name` can itself carry a parenthetical, e.g. "Opus 5 (1M context)".
# Pull it out so it can join the single qualifier list rather than producing a
# second bracketed group ("Claude Opus 5 (1M context) (Thinking · High)").
model_base="$model_name"
context_tag=""
case "$model_name" in
  *' ('*')')
    model_base="${model_name%% (*}"
    context_tag="${model_name##* (}"
    context_tag="${context_tag%)}"
    # "1M context" reads as just "1M" once it sits alongside Thinking / effort.
    context_tag="${context_tag% context}"
    ;;
esac

if [ -z "$model_base" ]; then
  model_full=""
else
  case "$model_base" in
    Claude*) model_full="$model_base" ;;
    *)       model_full="Claude $model_base" ;;
  esac
fi

thinking_tag=""
[ "$thinking" = "true" ] && thinking_tag="Thinking"

case "$effort" in
  xhigh) effort_tag="XHigh" ;;
  "")    effort_tag="" ;;
  *)     effort_tag="${effort^}" ;;
esac

# Session cost. This is Claude Code's own client-side estimate of what this
# session has spent, and it resets to $0 when /clear starts a new session — it
# is not a bill and not a month-to-date total.
cost_label=""
if [ -n "$cost" ]; then
  cost_label=$(printf '$%.2f' "$cost" 2>/dev/null) || cost_label=""
fi

# Assemble "<model> (<tag> · <tag> · …)" from whichever tags are non-empty.
compose() {
  local model="$1"; shift
  local joined=""
  local tag
  for tag in "$@"; do
    [ -z "$tag" ] && continue
    if [ -z "$joined" ]; then joined="$tag"; else joined="${joined} ${SEP} ${tag}"; fi
  done
  if [ -z "$model" ]; then
    printf '%s' "$joined"
  elif [ -n "$joined" ]; then
    printf '%s (%s)' "$model" "$joined"
  else
    printf '%s' "$model"
  fi
}

with_cost() {
  local body="$1"
  if [ -n "$cost_label" ] && [ -n "$body" ]; then
    printf '%s %s %s' "$cost_label" "$SEP" "$body"
  elif [ -n "$cost_label" ]; then
    printf '%s' "$cost_label"
  else
    printf '%s' "$body"
  fi
}

# Candidates from richest to leanest. The first one that fits the usable width
# is used, so the segment degrades deliberately instead of being clipped with an
# ellipsis by the status bar.
candidates=(
  "$(with_cost "$(compose "$model_full" "$context_tag" "$thinking_tag" "$effort_tag")")"
  "$(with_cost "$(compose "$model_full" "$thinking_tag" "$effort_tag")")"
  "$(with_cost "$(compose "$model_base" "$thinking_tag" "$effort_tag")")"
  "$(with_cost "$(compose "$model_base" "$effort_tag")")"
  "$(compose "$model_base" "$effort_tag")"
  "$(compose "$model_base")"
  ""
)

cols=${COLUMNS:-0}

# The second line has its whole row to itself, so it is left-aligned and needs
# no padding arithmetic — the ladder below only guards against wrapping on a
# genuinely narrow terminal. With COLUMNS unset, keep the richest form: there is
# no reason to drop detail we cannot prove won't fit.
second_plain="${candidates[0]}"
if [ "$cols" -gt 0 ]; then
  for candidate in "${candidates[@]}"; do
    second_plain="$candidate"
    [ -z "$candidate" ] && break
    [ ${#candidate} -le $((cols - RIGHT_MARGIN)) ] && break
  done
fi

# Line 1: directory + git. Line 2: session cost + model. Each printed line
# renders as its own row in the status area.
if [ -n "$second_plain" ]; then
  printf "${first_line}\n${GREY}%s${RESET}" "$second_plain"
else
  printf "${first_line}"
fi
