#!/bin/bash

mkdir --parents $HOME/.config/terminator
mkdir --parents $HOME/.config/sublime-text/Packages/User
stow --restow --dir=$HOME/dotfiles --target=$HOME bash gdb git nano profile ssh tmux vim
stow --restow --dir=$HOME/dotfiles --target=$HOME/.config/terminator terminator
stow --restow --dir=$HOME/dotfiles --target=$HOME/.config/sublime-text/Packages/User sublime
