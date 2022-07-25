#!/bin/bash

mkdir --parents $HOME/.config/terminator
mkdir --parents $HOME/.config/sublime-text-3/Packages/User
stow --dir=$HOME/dotfiles --target=$HOME bash gdb nano tmux vim
stow --dir=$HOME/dotfiles --target=$HOME/.config/terminator terminator
stow --dir=$HOME/dotfiles --target=$HOME/.config/sublime-text-3/Packages/User sublime
