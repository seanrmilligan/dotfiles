# #############################################################################
# If not running interactively, skip this file
# #############################################################################
case $- in
  *i*) ;;
    *) return;;
esac

# #############################################################################
# HISTORY SETTINGS
# #############################################################################

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

# #############################################################################
# TMUX
# #############################################################################

set_tmux_pane_title() {
  if [ ! -z $TMUX ]; then
    tmux select-pane -t $TMUX_PANE -T $1
  fi
}

set_tmux_window_name() {
  if [ ! -z $TMUX ]; then
    tmux rename-window "$(basename $PWD)"
  fi
}

# #############################################################################
# THE PROMPT
# #############################################################################

# Bash executes the PROMPT_COMMAND env variable before each new prompt.
# Before each new prompt, do the following:
#   1. Append the previously run command to the end of the HISTFILE. This
#      shares the current shell session's commands with other sessions.
#   2. Read the contents of HISTFILE into the current shell session's history.
#      This keeps the shell up to date with what other sessions have shared.
#   3. Execute set_prompt (see .bash_prompt) to generate the prompt string.
#   4. If inside tmux, display the exit code of the last command in the title.
prompt_command() {
  # Commands in this function alter $? and $PIPESTATUS.
  # Save the true results from the command that was just run by the user.
  local exit_code=$?
  local pipe_status=("${PIPESTATUS[@]}")

  history -a
  history -r
  set_prompt
  set_tmux_window_name
  set_tmux_pane_title $exit_code
}

PROMPT_COMMAND='prompt_command'

# #############################################################################
# WINDOW SETTINGS
# #############################################################################

# Check the window size after each command.
# Updates the values of LINES and COLUMNS with the new window dimensions.
shopt -s checkwinsize

# #############################################################################
# ALIAS SETTINGS
# #############################################################################

# Load aliases from a separate file.
if [ -f ~/.bash_aliases ]; then
  source ~/.bash_aliases
fi

# #############################################################################
# PROMPT SETTINGS
# #############################################################################

if [ -f ~/.bash_prompt ]; then
  source ~/.bash_prompt
fi

# #############################################################################
# BASH COMPLETION
# #############################################################################
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
shopt -s globstar

# `less`, one of the most popular tools for browsing file contents, only
# handles text files well by default. More advanced file formats often contain
# text as well, just in an enriched or binary form.
#
# `lesspipe` helps make `less` more friendly for non-text files which still
# have text embedded, such as PDFs and zipped/compressed files.
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"
