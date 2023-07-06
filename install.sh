#!/bin/bash

while ! command -v stow > /dev/null 2>&1
do
  read -r -p "GNU Stow not installed. Install? [y/N] " option
  if [ "$option" == "y" ] || [ "$option" == "Y" ]
  then
    sudo apt install stow
  else
    exit 1
  fi
done

# Stow will create symlinks as high up the directory structure as possble if any
# part of the path does not exist. Here we thwart this behavior by creating the
# paths ourselves, meaning Stow will only create a symlink for the files we wish
# to install. We do this so that if we install a file before we install the
# corresponding program, we don't end up with a symlinked directory. This avoids
# files being written back to the repository as the app creates caches, logs,
# etc. in its (symlinked) folder.
mkdir --parents $HOME/.config/terminator
mkdir --parents $HOME/.config/sublime-text-3/Packages/User

# Stow will not set up symlinks for the files we wish to install if they already
# exist locally. The --adopt flag tells Stow to take in the local file over our
# version, making it safe to set up the symlink. We then revert any changes this
# introduced -- we do want to install our version of the file, after all.
stow --adopt --dir=$HOME/dotfiles --target=$HOME \
  bash gdb git nano profile ssh sublime terminator tmux vim
git -C $HOME/dotfiles checkout . > /dev/null 2>&1
