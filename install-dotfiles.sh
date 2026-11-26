#!/bin/bash

set -e

err() {
  echo "$*" >&2
}

usage() {
  echo "Usage: $(basename "$0") [--headless | --desktop]"
  echo
  echo "Symlink dotfiles for this machine. Dotfiles common to all machines are"
  echo "always installed. The machine type selects the remaining dotfiles:"
  echo "  --headless  Servers and other machines without a graphical session."
  echo "  --desktop   Machines with a graphical session."
  echo
  echo "If no machine type is given, you will be prompted for one."
}

# ##############################################################################
# MACHINE TYPE
# ##############################################################################

machine_type=""

# Machine types are mutually exclusive. Repeating the same flag is harmless, but
# supplying both is an error rather than letting the last one silently win.
set_machine_type() {
  if [ -n "$machine_type" ] && [ "$machine_type" != "$1" ]; then
    err "--headless and --desktop are mutually exclusive."
    usage >&2
    exit 1
  fi
  machine_type="$1"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --headless)
      set_machine_type "headless"
      ;;
    --desktop)
      set_machine_type "desktop"
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      err "Unknown option '$1'"
      usage >&2
      exit 1
      ;;
  esac
  shift
done

while ! command -v stow > /dev/null 2>&1
do
  read -r -p "GNU Stow not installed. Install? [y/N] " option
  if [ "$option" == "y" ] || [ "$option" == "Y" ]
  then
    sudo apt install stow
  else
    err "Did not install GNU Stow."
    exit 1
  fi
done

# No machine type supplied as a flag. Ask for one.
while [ -z "$machine_type" ]; do
  read -r -p "Is this a (h)eadless or (d)esktop machine? " option
  case "$option" in
    h | H | headless) machine_type="headless" ;;
    d | D | desktop)  machine_type="desktop"  ;;
    *) err "Please answer 'h' or 'd'." ;;
  esac
done

echo "Installing dotfiles for a $machine_type machine."

# Stow will create symlinks as high up the directory structure as possble if any
# part of the path does not exist. Here we thwart this behavior by creating the
# paths ourselves, meaning Stow will only create a symlink for the files we wish
# to install. We do this so that if we install a file before we install the
# corresponding program, we don't end up with a symlinked directory. This avoids
# files being written back to the repository as the app creates caches, logs,
# etc. in its (symlinked) folder.
mkdir --parents $HOME/.claude/skills
mkdir --parents $HOME/.config/
mkdir --parents $HOME/.gemini/antigravity-cli

if [ "$machine_type" = "desktop" ]; then
  mkdir --parents $HOME/.config/sublime-text-3/Packages/User
  mkdir --parents $HOME/.config/terminator
fi

packages=(
  antigravity
  bash
  claude
  gdb
  git
  nano
  profile
  ssh
  tmux
  vim
)

if [ "$machine_type" = "desktop" ]; then
  packages+=(
    ghostty
    rider
    sublime
    terminator
  )
fi

# Stow will not set up symlinks for the files we wish to install if they already
# exist locally. The --adopt flag tells Stow to take in the local file over our
# version, making it safe to set up the symlink. We then revert any changes this
# introduced -- we do want to install our version of the file, after all.
stow --adopt --dir=$HOME/dotfiles --target=$HOME "${packages[@]}"

git -C $HOME/dotfiles checkout . > /dev/null 2>&1
