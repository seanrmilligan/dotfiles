# ########################################
# If not running interactively, skip this file
# ########################################
case $- in
    *i*) ;;
      *) return;;
esac

# ########################################
# HISTORY SETTINGS
# ########################################

# Control what goes into the bash history.
# Ignore:
#   (1) duplicate lines
#   (2) lines starting with a space
# See bash(1) for more options
HISTCONTROL=ignoreboth

# Append to the history file rather than overwriting it.
# Useful for running multiple instances of bash concurrently.
# If not set, the last instance overwrites the HISTFILE with its history.
# If set, all instances append their histories to the HISTFILE.
# History is written to the HISTFILE upon shell exit.
shopt -s histappend

# Set the HISTSIZE and HISTFILESIZE.
# HISTSIZE controls the in-memory history of the shell session.
# HISTFILESIZE controls the history stored in the HISTFILE between sessions.
# See bash(1) for more options
HISTSIZE=1000
HISTFILESIZE=2000

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

