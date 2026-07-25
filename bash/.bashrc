#!/usr/bin/env bash

# ##############################################################################
# If not running interactively, skip this file
# ##############################################################################
case $- in
  *i*) ;;
    *) return;;
esac

# ##############################################################################
# UTILITY FUNCTIONS
# ##############################################################################

err() {
  echo "$*" >&2
}

is_valid_directory() {
  # Declare a nameref to capture the name of the environment variable passed.
  declare -n ENV_VARIABLE=$1

  if [ -z "$ENV_VARIABLE" ]; then
    err "${!ENV_VARIABLE} is not set."
    return 1
  fi

  if [ ! -e "$ENV_VARIABLE" ]; then
    err "${!ENV_VARIABLE} ($ENV_VARIABLE) directory does not exist."
    return 2
  fi

  if [ ! -d "$ENV_VARIABLE" ]; then
    err "${!ENV_VARIABLE} ($ENV_VARIABLE) is not a directory."
    return 3
  fi

  return 0
}

# ##############################################################################
# WORKSPACES
# ##############################################################################

export WORKSPACE_ROOT="$HOME/projects"

cdw() {
  if ! is_valid_directory WORKSPACE_ROOT; then
    return $?
  fi

  if [ -d "$WORKSPACE_ROOT/$1" ]; then
    cd "$WORKSPACE_ROOT/$1"
  else
    err "No such workspace '$1'"
  fi
}

lsw() {
  if ! is_valid_directory WORKSPACE_ROOT; then
    return $?
  fi

  find "$WORKSPACE_ROOT" -maxdepth 1 -mindepth 1 -type d -printf "%f\n"
}

rmw() {
  if ! is_valid_directory WORKSPACE_ROOT; then
    return $?
  fi

  if [ -d "$WORKSPACE_ROOT/$1" ]; then
    rm -rf "${WORKSPACE_ROOT}/$1"
  fi
}

_cdw_autocomplete() {
    # COMP_WORDS is the array of words typed into the current prompt
    # COMP_CWORD is the index of the current word
    local current_word="${COMP_WORDS[COMP_CWORD]}"

    # Determine:
    #   - $relative_path: the path under $WORKSPACE_ROOT completed so far.
    #   - $next_path_segment: the next partially completed part of the path.
    # If no slash was typed, the relative path is empty. The next path segment
    #   is the current word (e.g. "dotfi"). This only happens in the
    #   $WORKSPACE_ROOT.
    # Otherwise, the relative path is everything up to the final slash
    #   ("dotfiles/") while the next path segment is the part after the last
    #   slash (e.g., "gi" in "dotfiles/gi"). This happens in subdirectories of
    #   $WORKSPACE_ROOT

    if [ "${current_word#*/*}" = "$current_word" ]; then
      local relative_path=""
      local next_path_segment="$current_word"
    else
      local relative_path="${current_word%/*}"
      local next_path_segment="${current_word##*/}"
    fi

    # Change to the $WORKSPACE_ROOT in a subshell.
    #
    # There, generate suggestions as if we were prompting for autocomplete in
    # the $WORKSPACE_ROOT. If we have already completed some amount of a path,
    # the $relative_path will be non-empty, so append a slash and the path.
    # This will allow us to generate suggestions for the $next_path_segment.
    #
    # Return the suggestions as an array so that `cdw` can have autocomplete
    # for the $WORKSPACE_ROOT while in any directory. Place the $relative_path
    # stripped off earlier back on so that the accepted suggestion uses the
    # entire construction ("dotfiles/git/") not just the suggestion for the
    # $next_path_segment ("gi" -> "git/").
    #
    # See `man bash` for more on mapfile and compgen.
    mapfile -t COMPREPLY < <(
      cd "$WORKSPACE_ROOT${relative_path:+/$relative_path}" 2>/dev/null &&
      compgen -d -S/ -- "$next_path_segment" |
        sed "s|^|${relative_path:+$relative_path/}|"
    )
}

# Register _cdw_autocomplete as the autocomplete for `cdw`
complete -o nospace -F _cdw_autocomplete cdw

# ##############################################################################
# WORKSPACE @ EXPANSION
# ##############################################################################

# Expand @ at the beginning of a word to $WORKSPACE_ROOT/, similar to how the
# shell expands ~ to $HOME. The expansion happens inline in the readline buffer
# so you can see the full path before the command runs.
#
# Examples:
#   cat @dotfiles/.bashrc   ->  cat /home/sean/projects/dotfiles/.bashrc
#   ls @dotfiles/bash/      ->  ls /home/sean/projects/bash/
#
# Only expands @ at word boundaries (after whitespace or at the start of the
# line) to avoid mangling patterns like user@host or email addresses.

_expand_workspace_at() {
  if [[ -z "$WORKSPACE_ROOT" ]]; then
    return
  fi

  local line="$READLINE_LINE"
  local result=""
  local i=0
  local len=${#line}
  local prev_is_space=1  # Start of line counts as a word boundary.

  # Walk the line character by character, replacing @ at word boundaries.
  while (( i < len )); do
    local char="${line:i:1}"

    if (( prev_is_space )) && [[ "$char" == "@" ]]; then
      result+="$WORKSPACE_ROOT/"
      # Track the cursor shift: we replaced 1 char (@) with N chars.
      if (( READLINE_POINT > i )); then
        (( READLINE_POINT += ${#WORKSPACE_ROOT} ))  # +len, -1 for @, +1 for /
      fi
    else
      result+="$char"
    fi

    if [[ "$char" == " " || "$char" == $'\t' ]]; then
      prev_is_space=1
    else
      prev_is_space=0
    fi

    (( i++ ))
  done

  READLINE_LINE="$result"
}

_expand_workspace_at_and_space() {
  _expand_workspace_at

  # Insert a space at the cursor position.
  READLINE_LINE="${READLINE_LINE:0:READLINE_POINT} ${READLINE_LINE:READLINE_POINT}"
  (( READLINE_POINT++ ))
}

_expand_workspace_at_and_accept() {
  _expand_workspace_at

  # Accept the line (simulate pressing Enter). The bind for \C-j below uses
  # a two-key sequence: first it calls this function via \C-x\C-a, then it
  # sends \C-j (newline) to actually execute the command. This avoids the
  # problem where bind -x swallows the keypress.
  #
  # This function only performs the expansion; the actual accept-line is
  # handled by the readline binding below.
  :
}

# Bind Space to expand-then-space.
bind -x '"\C-x\C-s": _expand_workspace_at_and_space'
bind '"\x20": "\C-x\C-s"'

# Bind Enter to expand-then-accept.
# \C-x\C-a runs the expansion function, then \C-j (newline) accepts the line.
bind -x '"\C-x\C-a": _expand_workspace_at_and_accept'
bind '"\C-m": "\C-x\C-a\C-j"'

# Bind Tab to complete @workspace paths without flicker.
# If the word under the cursor starts with @, handle completion entirely within
# a single bind -x call using compgen under $WORKSPACE_ROOT. This avoids the
# intermediate readline redraws that a multi-step expand -> complete -> collapse macro
# would cause. For words without @, the function returns without modifying the
# buffer and readline's built-in complete (chained after in the macro) fires
# normally.

_at_tab_complete() {
  local before="${READLINE_LINE:0:READLINE_POINT}"
  local current_word="${before##* }"

  # At the start of the line there is no leading space to strip.
  if [[ "$READLINE_POINT" -gt 0 && "$before" != *" "* ]]; then
    current_word="$before"
  fi

  # Only handle @-prefixed words.
  if [[ "$current_word" != @* || -z "$WORKSPACE_ROOT" ]]; then
    return
  fi

  local partial="${current_word#@}"
  local search_dir="$WORKSPACE_ROOT"
  local dir_part=""
  local base_part="$partial"

  # Split into directory and basename components for nested paths like
  # @dotfiles/bash/.ba  ->  dir_part="dotfiles/bash"  base_part=".ba"
  if [[ "$partial" == */* ]]; then
    dir_part="${partial%/*}"
    base_part="${partial##*/}"
    search_dir="$WORKSPACE_ROOT/$dir_part"
  fi

  # Generate completions (files and directories).
  local completions=()
  if [[ -d "$search_dir" ]]; then
    mapfile -t completions < <(
      cd "$search_dir" 2>/dev/null &&
      compgen -f -- "$base_part" | sort
    )
  fi

  if [[ ${#completions[@]} -eq 0 ]]; then
    return
  fi

  local prefix_part="${READLINE_LINE:0:READLINE_POINT - ${#current_word}}"
  local after_part="${READLINE_LINE:READLINE_POINT}"

  if [[ ${#completions[@]} -eq 1 ]]; then
    # Single match — complete it fully.
    local match="${completions[0]}"
    local completed="@${dir_part:+$dir_part/}${match}"
    if [[ -d "$search_dir/$match" ]]; then
      completed+="/"
    fi
    READLINE_LINE="${prefix_part}${completed}${after_part}"
    READLINE_POINT=$(( ${#prefix_part} + ${#completed} ))
  else
    # Multiple matches — complete to the longest common prefix and display
    # the candidates.
    local common="${completions[0]}"
    local comp
    for comp in "${completions[@]:1}"; do
      local i=0
      while (( i < ${#common} && i < ${#comp} )) && \
            [[ "${common:i:1}" == "${comp:i:1}" ]]; do
        (( i++ ))
      done
      common="${common:0:i}"
    done

    local completed="@${dir_part:+$dir_part/}${common}"
    READLINE_LINE="${prefix_part}${completed}${after_part}"
    READLINE_POINT=$(( ${#prefix_part} + ${#completed} ))

    # Print candidates below the prompt. Append / to directories for clarity.
    local display=()
    local c
    for c in "${completions[@]}"; do
      if [[ -d "$search_dir/$c" ]]; then
        display+=("$c/")
      else
        display+=("$c")
      fi
    done

    echo
    printf '%s\n' "${display[@]}" | column 2>/dev/null ||
      printf '%s\n' "${display[@]}"
  fi
}

bind -x '"\C-x\C-t": _at_tab_complete'
bind '"\C-x\C-r": complete'
bind '"\t": "\C-x\C-t\C-x\C-r"'

rewrite_workspace_path_in_history() {
  # Replace "$WORKSPACE_ROOT/" with "@" in the last history entry.
  # This ensures all commands consistently refer to @workspace using '@' format,
  # even those executed with the absolute path "$WORKSPACE_ROOT/workspace".
  if [ -n "$WORKSPACE_ROOT" ]; then
    # Get the last command written to the histfile.
    #   Turn off the timestamp: HISTTIMEFORMAT=''
    #   Strip the histfile entry number.
    local last_command=$(HISTTIMEFORMAT='' history 1 | sed 's/^ *[0-9]* *//')

    # Replace all instances of "$WORKPLACE_ROOT/" with "@" in the $last_command.
    local modified_command="${last_command//$WORKSPACE_ROOT\//@}"

    if [ "$modified_command" != "$last_command" ]; then
      # Delete the most recent command in history ($last_command).
      history -d -1
      # Save the modified command.
      history -s "$modified_command"
    fi
  fi
}

# ##############################################################################
# GIT
# ##############################################################################

is_repository() {
  git rev-parse --is-inside-work-tree > /dev/null 2>&1
}

get_commit_branch_or_hash() {
  # Get an identifier for the current commit:
  #   - the current branch, or
  #   - the commit hash (if we are in a detached HEAD state.)
  # Even in the case of a newly initialized, empty repository, this will still
  # point to the default branch such as master or main, but not a real commit.

  git symbolic-ref --short -q HEAD || # current branch
  git rev-parse --short HEAD 2>/dev/null # commit hash
}

get_latest_commit_hash() {
  local hash_algo=$(git rev-parse --show-object-format)
  local empty_commit_hash=""

  # For a given hashing algorithm, git has a static, well known hash for
  # representing a newly initialized repository with no commits.
  case "$hash_algo" in
    "sha1")
      empty_commit_hash="4b825dc642cb6eb9a060e54bf8d69288fbee4904"
      ;;
    "sha256")
      empty_commit_hash="6efc71244b74872f232490b39678e71869e90479b634c03847f938d825c4e976"
      ;;
  esac

  # HEAD may either point to a valid commit (common case), or to nothing.
  # If it points to nothing, it is because the repository is newly initialized
  # and has no commits. In this case we set the latest commit hash to the well-
  # known empty repository hash.
  git rev-parse --verify HEAD 2>/dev/null ||
    echo "$empty_commit_hash"
}

has_unpushed_commits() {
  # Check for unpushed commits.
  # Verify HEAD exists to prevent errors in empty repositories.
  # We are considered "unpushed" if:
  #   - There is no upstream configured (e.g., a newly created local branch).
  #   - We are ahead of the configured upstream branch.
  if git rev-parse --verify HEAD >/dev/null 2>&1; then
    if ! git rev-parse --verify @{upstream} >/dev/null 2>&1 ||
        [ "$(git rev-list --count @{upstream}..HEAD 2>/dev/null)" -gt 0 ]; then
      return 0
    fi
  fi

  return 1
}

has_untracked_files() {
  # Check for untracked files.
  # Untracked files are treated differently than tracked files, but for our
  # purposes we want to treat the state of the repository as "dirty".
  # Pipe to `head` to exit early. Non-zero output length is sufficient to say
  # that there are untracked files, so we only need one line for proof.
  local untracked_files=$(
    git ls-files --others --exclude-standard |
    head -n 1
    )
  [ -n "$untracked_files" ]
}

get_repository_state() {
  # Refresh the git index.
  # This eliminates false positives from files that have a more recent last
  # modified time than git knows about, yet no content diff.
  git update-index -q --refresh

  if has_untracked_files; then
    # There are untracked files; the repository is dirty.
    echo "dirty"
    return 0
  fi

  if ! git diff-index --quiet "$(get_latest_commit_hash)" --; then
    # There are changes in tracked files; the repository is dirty.
    echo "dirty"
    return 0
  fi

  if has_unpushed_commits; then
    # There are unpushed changes or an unpushed new branch.
    echo "unpushed"
    return 0
  fi

  # All changes have been committed and pushed; the repository is clean.
  echo "clean"
  return 0
}

# ##############################################################################
# HISTORY SETTINGS
# ##############################################################################

# Control what goes into the bash history. Colon-separated list.
# Options:
#   erasedups:   erase any duplicate lines anywhere
#   ignoredups:  ignore duplicate consecutive lines
#   ignorespace: ignore lines starting with a space
#   ignoreboth:  combine the two preceding options
# See bash(1) for more options
HISTCONTROL=ignoreboth

# Ignore certain uninteresting commands. Colon-separated list.
HISTIGNORE="ls:history"

# Append to the history file rather than overwriting it. This is useful for
# running multiple sessions of bash concurrently. Without this, each session of
# bash overwrites the HISTFILE (and thus the history of the previous sessions)
# with its own history.
# By default, history is written to the HISTFILE upon shell exit. This behavior
# is changed below by modifying PROMPT_COMMAND.
shopt -s histappend

# Set the HISTSIZE and HISTFILESIZE.
# HISTSIZE controls the in-memory history of the shell session.
# HISTFILESIZE controls the history stored in the HISTFILE between sessions.
# See bash(1) for more options
HISTSIZE=20000
HISTFILESIZE=20000

# Set the HISTTIMEFORMAT.
# Controls the timestamp format of the history command.
# [YYYY-MM-DD HH:MM:SS-ZZZZ]
HISTTIMEFORMAT="[%F %T%z] "

# ##############################################################################
# TMUX
# ##############################################################################

set_tmux_pane_title() {
  if [ -n "$TMUX" ]; then
    tmux select-pane -t "$TMUX_PANE" -T "$1"
  fi
}

set_tmux_window_name() {
  if [ -n "$TMUX" ]; then
    tmux rename-window "$(basename "$PWD")"
  fi
}

# ##############################################################################
# THE PROMPT
# ##############################################################################

# Create the prompt
# Special values:
# \u user
# \h hostname
# \w working directory
set_prompt() {
  local exit_code="$1"
  local commit_name=""
  local repository_state=""

  # Check if the current directory is a git repository.
  if is_repository; then
    commit_name=$(get_commit_branch_or_hash)
    repository_state=$(get_repository_state)
  fi

  case "$PWD" in
    ${WORKSPACE_ROOT}/*)
      # The root directory for projects.
      # Format paths in $WORKSPACE_ROOT as @workspace/
      local current_directory="@${PWD/$WORKSPACE_ROOT\//}"
      ;;
    ${HOME}*)
      # User's home directory.
      # Format paths in $HOME as ~/ instead of /home/$(whoami)
      local current_directory="~${PWD/$HOME/}"
      ;;
    *)
      # Anywhere else. Leave directory as-is.
      local current_directory="$PWD"
      ;;
  esac

  # If TERM is set to a color-enabled terminal, turn on the color prompt.
  case "$TERM" in
    xterm-color   | \
    xterm-ghostty | \
    *-256color    )
      set_color_prompt "$exit_code" "$commit_name" "$repository_state"
      ;;
    *)
      set_plain_prompt "$exit_code" "$commit_name" "$repository_state"
      ;;
  esac
}

# Prompt color ranges:
# 30-37 foreground
# 40-47 background
# 90-97 high intensity foreground
# 100-107 high intensity background
#
# Prompt colors:
# 0 - Black
# 1 - Red
# 2 - Green
# 3 - Yellow
# 4 - Blue
# 5 - Purple
# 6 - Cyan
# 7 - White
#
# Bold bit:
# 0 - Normal
# 1 - Bold
#
# Format:
# \[\e[BOLD_BIT;COLOR\]

set_color_prompt() {
  local exit_code="$1"
  local git_head="$2"
  local repository_state="$3"

  local BLACK="\[\e[0;30m\]"
  local BLACKBOLD="\[\e[1;30m\]"
  local RED="\[\e[0;31m\]"
  local REDBOLD="\[\e[1;31m\]"
  local REDLIGHT="\[\e[0;91m\]"
  local GREEN="\[\e[0;32m\]"
  local GREENBOLD="\[\e[1;32m\]"
  local GREENLIGHT="\[\e[0;92m\]"
  local YELLOW="\[\e[0;33m\]"
  local YELLOWBOLD="\[\e[1;33m\]"
  local BLUE="\[\e[0;34m\]"
  local BLUEBOLD="\[\e[1;34m\]"
  local BLUELIGHT="\[\e[0;94m\]"
  local PURPLE="\[\e[0;35m\]"
  local PURPLEBOLD="\[\e[1;35m\]"
  local CYAN="\[\e[0;36m\]"
  local CYANBOLD="\[\e[1;36m\]"
  local WHITE="\[\e[0;37m\]"
  local WHITEBOLD="\[\e[1;37m\]"
  local RESET="\[\e[0m\]"

  if [ "$exit_code" -eq 0 ]; then
    local EXIT_CODE_INDICATOR="$GREEN●$RESET"
  else
    local EXIT_CODE_INDICATOR="$RED● $exit_code$RESET"
  fi

  case "$repository_state" in
    "dirty")
      local GIT_STATUS_INDICATOR="$RED●$RESET"
      ;;
    "unpushed")
      local GIT_STATUS_INDICATOR="$YELLOW●$RESET"
      ;;
    "clean")
      local GIT_STATUS_INDICATOR="$GREEN●$RESET"
      ;;
    *)
      local GIT_STATUS_INDICATOR="$WHITE●$RESET"
      ;;
  esac

  export PS1="$EXIT_CODE_INDICATOR $BLUELIGHT$current_directory$RESET ${git_head:+"($git_head $GIT_STATUS_INDICATOR) "}$ "
}

set_plain_prompt() {
  local exit_code="$1"
  local git_head="$2"
  local repository_state="$3"

  export PS1="[$exit_code] $current_directory ${git_head:+"($git_head -> $repository_state) "}$ "
}

# ##############################################################################
# POST-COMMAND HOOKS
# ##############################################################################

# Bash executes the PROMPT_COMMAND env variable after each command is run.
# This makes it useful as a post-command hook. After each command:
#   1. Rewrite paths starting with "$WORKSPACE_ROOT/" to start with "@". Perform
#      this on the in-memory history before it is written to disk.
#   2. Append the previously run command to the end of the HISTFILE. This
#      shares the current shell session's commands with other sessions.
#   3. Read the contents of HISTFILE into the current shell session's history.
#      This keeps the shell up to date with what other sessions have written.
#   4. Execute set_prompt to generate the prompt string.
#   5. If inside tmux, display the exit code of the last command in the title.
prompt_command() {
  # Commands in this function alter $? and $PIPESTATUS.
  # Save the true results from the command that was just run by the user.
  local exit_code=$?
  local pipe_status=("${PIPESTATUS[@]}")

  rewrite_workspace_path_in_history
  history -a
  history -r

  set_prompt $exit_code
  set_tmux_window_name
  set_tmux_pane_title $exit_code
}

PROMPT_COMMAND='prompt_command'

# ##############################################################################
# WINDOW SETTINGS
# ##############################################################################

# Check the window size after each command.
# Updates the values of LINES and COLUMNS with the new window dimensions.
shopt -s checkwinsize

# ##############################################################################
# BASH COMPLETION
# ##############################################################################
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    source /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    source /etc/bash_completion
  fi
fi

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
shopt -s globstar

# ##############################################################################
# PAGER
# ##############################################################################

export PAGER="less"

# The successor to `more`, because as they say, `less` is `more`.

# `less`, one of the most popular tools for browsing file contents, only
# handles text files well by default. More advanced file formats often contain
# text as well, just in an enriched or binary form.
#
# `lesspipe` helps make `less` more friendly for non-text files which still
# have text embedded, such as PDFs and zipped/compressed files.
if [ -x /usr/bin/lesspipe ]; then
  eval "$(SHELL=/bin/sh lesspipe)"
fi


# -F: Automatically quit when the content is less than the screen height.
# -N: Show line numbers.
# -Q: Do not ring the bell upon scrolling to the beginning or end of the file.
# -R: Print ANSI control characters to enable shell syntax highlighting.
# -S: Prefer horizontal scrolling over line wrapping.
if [ -x /usr/bin/source-highlight ]; then
  export LESSOPEN="|/usr/share/source-highlight/src-hilite-lesspipe.sh %s"
  export LESS="-F -N -Q -R -S"
fi

# ##############################################################################
# BATCAT
# ##############################################################################

# The tool `batcat` occupies a space somewhere between "enhanced `cat`" (insofar
# as `cat` gets used improperly to print contents to the console rather than its
# original purpose to concatenate files) and  "`less` but  without having to
# configure as much." It applies syntax highlighting, adds line numbers and a
# header, and feeds that into the PAGER for viewing.

# Let `bat` invoke `batcat`, over a conflicting package of the same name.
alias bat='batcat'

# Override the settings for `less` set in the PAGER section.
# As `batcat` provides built-in line numbering and syntax highlighting, we don't
# need `less` to also apply the same when used as the PAGER for `batcat`.
export BAT_PAGER="less -F -n -Q -S"

# ##############################################################################
# VS CODE
# ##############################################################################

code() {
  # Intercept invocations of VS Code.
  #
  # If the directory passed to VS Code contains exactly one `*.code-workspace`
  # file, open the `*.code-workspace` file instead of the directory itself.
  #
  # Only intercept the unambiguous case: a single argument.
  # e.g.: `code .`, `code ~/projects/dotfiles`, etc.
  #
  # Any other invocation (non-directory argument, or with flags and options) is
  # passed through to VS Code untouched.
  if [ "$#" -eq 1 ] && [ -d "$1" ]; then
    local -a workspace_files
    mapfile -t workspace_files < <(find "$1" -maxdepth 1 -name "*.code-workspace" 2>/dev/null)
    if [ "${#workspace_files[@]}" -eq 1 ]; then
      command code "${workspace_files[0]}"
      return
    fi
  fi

  command code "$@"
}

# ##############################################################################
#  BASH ALIASES
# ##############################################################################

if [ -x /usr/bin/dircolors ]; then
  alias ls='ls --color=auto'
  alias dir='dir --color=auto'
  alias vdir='vdir --color=auto'
  alias grep='grep --color=auto'
  alias fgrep='fgrep --color=auto'
  alias egrep='egrep --color=auto'
fi
