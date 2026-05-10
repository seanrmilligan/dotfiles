#!/bin/sh

# Executed by the command interpreter for login shells.

# The shell searches all directories listed in $PATH for the command entered.
# $PATH is a colon-separated list.
#
# Add a directory in the $HOME folder to the front of $PATH for personal
# scripts, binaries, and symlinks.
#
# Putting the directory at the front of the list gives it precedence as the
# shell stops searching after it finds the first match.

add_to_path() {
  if [ -d "$1" ]; then
    case "$PATH" in
      *"$1"*)
        # $1 is already in path, skip.
        ;;
      *)
        PATH="$1:$PATH"
        ;;
    esac
  fi
}

add_to_path "$HOME/bin"
add_to_path "$HOME/.local/bin"

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
