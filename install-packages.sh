#!/usr/bin/env bash

set -e

DOTFILES_ROOT=$(dirname "$0")

err() {
  echo "Error: $*" >&2
}

# Key locations:
# - /etc/apt/keyrings
#   For keys installed by the user. Apt will only trust these keys for
#   individual packages specified in the signed-by field of a .sources file.
# - /etc/apt/trusted.gpg.d/
#   Deprecated. Apt trusts these keys implicitly for all repositories.
#   Compromised keys could be used to sign any package and be trusted.
# - /usr/share/keyrings
#   For keys installed via package manager. Apt will only trust these keys for
#   individual packages specified in the signed-by field of a .sources file.
install_key() {
  local public_key_url="$1"
  local key_install_path="$2"

  # Comments:
  # --output-document=- sends the fetched data to stdout
  # --dearmor decodes an ascii-encoded key to raw binary
  #   Therefore, there is an assumption that keys fetched are ascii-encoded.
  # --yes grants permission to overwrite the key if it exists
  wget "$public_key_url"             \
    --quiet                          \
    --output-document=-              |
    gpg --output="$key_install_path" \
      --dearmor                      \
      --yes
}


# Source files
configure_source() {
  # Copy apt sources rather than symlink through stow.
  # The '_apt' user must have read access to the file, and the '_apt' user
  # will not have access to the /home/$(whoami)/dotfiles directory.
  cp "$DOTFILES_ROOT/$1" "/etc/apt/sources.list.d/$1"
}

if [ "$(id -u)" -ne 0 ]; then
  err "Must run as root."
  exit 1
fi

apt install        \
  bat              \
  gcc              \
  gh               \
  ghostty          \
  gnome-keyring    \
  gpg              \
  jq               \
  make             \
  shellcheck       \
  sl               \
  source-highlight \
  stow             \
  tmux             \
  wget

# Install Sublime Text
if ! command -v subl &> /dev/null; then
  install_key \
    "https://download.sublimetext.com/sublimehq-pub.gpg" \
    "/etc/apt/keyrings/sublimehq.gpg"

  configure_source "sublime-text.sources"

  apt update

  apt install sublime-text sublime-merge
fi

# Install VS Code
if ! command -v code &> /dev/null
then
  install_key \
    "https://packages.microsoft.com/keys/microsoft.asc" \
    "/etc/apt/keyrings/microsoft.gpg"

  configure_source "vscode.sources"

  apt update

  apt install code
fi

# Install Docker
if ! command -v docker &> /dev/null
then
  install_key \
    "https://download.docker.com/linux/ubuntu/gpg" \
    "/etc/apt/keyrings/docker.gpg"

  configure_source "docker.sources"

  apt update

  apt install             \
    docker-ce             \
    docker-ce-cli         \
    containerd.io         \
    docker-buildx-plugin  \
    docker-compose-plugin
fi

# Install Google Chrome
if ! command -v google-chrome-stable &> /dev/null
then
  chrome_installer="$TMPDIR/google-chrome-stable.deb"

  curl https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    --location
    --output="$chrome_installer"

  apt install "$chrome_installer"
fi
