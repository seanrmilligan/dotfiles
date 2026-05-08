#!/usr/bin/env bash

set -e

DOTFILES_ROOT=$(dirname "$0")

err() {
  echo "Error: $*" >&2
}

if [ "$(id -u)" -ne 0 ]; then
  err "Must run as root."
  exit 1
fi

apt install        \
  gcc              \
  ghostty          \
  gnome-keyring    \
  gpg              \
  jq               \
  make             \
  shellcheck       \
  source-highlight \
  stow             \
  tmux             \
  wget

# Install Sublime Text
if ! command -v subl &> /dev/null
then
  wget https://download.sublimetext.com/sublimehq-pub.gpg \
    --quiet                                               \
    --output-document=-                                   | # - -> stdout
    gpg --output=/usr/share/keyrings/sublimehq.gpg        \
      --dearmor                                           \
      --yes                                                 # overwrite ok

  cp "$DOTFILES_ROOT/sublime-text.sources" \
    /etc/apt/sources.list.d/sublime-text.sources

  apt update

  apt install sublime-text
fi

# Install VS Code
if ! command -v code &> /dev/null
then
  wget https://packages.microsoft.com/keys/microsoft.asc \
    --quiet                                              \
    --output-document=-                                  | # - -> stdout
    gpg --output=/usr/share/keyrings/microsoft.gpg       \
      --dearmor                                          \
      --yes                                                # overwrite ok

  # Copy apt sources rather than symlink through stow.
  # The '_apt' user must have read access to the file, and the '_apt' user
  # will not have access to the /home/$(whoami)/dotfiles directory.
  cp "$DOTFILES_ROOT/vscode.sources" \
    /etc/apt/sources.list.d/vscode.sources

  apt update

  apt install code
fi

