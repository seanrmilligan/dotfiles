# Add a directory for the shell to search for commands.
# Helpful as a place to store utility scripts you want to run from anywhere.
# Add to the front of $PATH to give precedence to ours when conflicts arise.
PATH=$HOME/bin:$PATH

# Attach to a tmux session. Create the session if there isn't one.
if [ -z "$TMUX" ]; then
  tmux new-session -A -s main
fi

source $HOME/.bashrc
