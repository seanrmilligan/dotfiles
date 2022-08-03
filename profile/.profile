# Executed by the command interpreter for login shells.

# The shell searches all directories specified in $PATH for the command entered
# by the user. Colon-separated list.
#
# Add a directory in the $HOME folder to the front of $PATH for scripts and
# binaries of our own. We put this directory at the front to give precedence to
# commands in this folder when commands of the same name live in more than one
# place.
if [ -d "$HOME/bin" ]; then
  PATH="$HOME/bin:$PATH"
fi

# Attach to a tmux session. Create the session if there isn't one.
if [ -z "$TMUX" ]; then
  tmux new-session -A -s main
fi

# Check if we're running bash
if [ -n "$BASH_VERSION" ]; then
  # Execute .bashrc if it exists
  if [ -f "$HOME/.bashrc" ]; then
    source "$HOME/.bashrc"
  fi
fi
