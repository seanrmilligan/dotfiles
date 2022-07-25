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

# Control what goes into the bash history.
# Ignore:
#   (1) duplicate lines
#   (2) lines starting with a space
# See bash(1) for more options
HISTCONTROL=ignoreboth

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

# Bash executes the PROMPT_COMMAND env variable before each new prompt.
# Before each new prompt, do the following:
#   1. Append the previously run command to the end of the HISTFILE. This
#      shares the current shell session's commands with other sessions.
#   2. Read the contents of HISTFILE into the current shell session's history.
#      This keeps the shell up to date with what other sessions have shared.
#   3. Execute set_prompt (see .bash_prompt) to generate the prompt string.
PROMPT_COMMAND='history -a; history -r; set_prompt'

# ########################################
# WINDOW SETTINGS
# ########################################

# Check the window size after each command.
# Updates the values of LINES and COLUMNS with the new window dimensions.
shopt -s checkwinsize

# ########################################
# ALIAS SETTINGS
# ########################################

# Load aliases from a separate file.
if [ -f ~/.bash_aliases ]; then
  source ~/.bash_aliases
fi

# ########################################
# PROMPT SETTINGS
# ########################################

if [ -f ~/.bash_prompt ]; then
  source ~/.bash_prompt
fi

# ########################################
# BASH COMPLETION
# ########################################
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
