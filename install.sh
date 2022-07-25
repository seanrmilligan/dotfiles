#!/bin/bash

while ! command -v stow 2>&1 > /dev/null
do
  read -r -p "GNU Stow not installed. Install? [y/N] " option
  if [ "$option" == "y" ] || [ "$option" == "Y" ]
  then
      sudo apt install stow
  else
    exit 1
  fi
done

mkdir --parents $HOME/.config/terminator
mkdir --parents $HOME/.config/sublime-text-3/Packages/User
stow --dir=$HOME/dotfiles --target=$HOME bash gdb nano sublime terminator tmux vim
