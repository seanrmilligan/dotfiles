#!/usr/bin/env bash

set -e

DOTFILES_ROOT=$(dirname "$0")

err() {
  echo "Error: $*" >&2
}

usage() {
  echo "Usage: $(basename "$0") [--headless | --desktop]"
  echo
  echo "Install packages on this machine. The machine type selected determines"
  echo "whether graphical applications are installed:"
  echo "  --headless  Servers and other machines without a graphical session."
  echo "  --desktop   Machines with a graphical session."
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
  cp "$DOTFILES_ROOT/$1" "/etc/apt/sources.list.d/$(basename "$1")"
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

if [ "$(id -u)" -ne 0 ]; then
  err "Must run as root."
  exit 1
fi

# No machine type supplied as a flag. Ask for one.
while [ -z "$machine_type" ]; do
  read -r -p "Is this a (h)eadless or (d)esktop machine? " option
  case "$option" in
    h | H | headless) machine_type="headless" ;;
    d | D | desktop)  machine_type="desktop"  ;;
    *) err "Please answer 'h' or 'd'." ;;
  esac
done

echo "Installing packages for a $machine_type machine."

# ##############################################################################
# COMMON PACKAGES
# ##############################################################################

apt install        \
  bat              \
  curl             \
  gcc              \
  gdb              \
  gh               \
  gpg              \
  jq               \
  make             \
  shellcheck       \
  sl               \
  source-highlight \
  stow             \
  wget

# Install Docker
if ! command -v docker &> /dev/null
then
  install_key \
    "https://download.docker.com/linux/ubuntu/gpg" \
    "/etc/apt/keyrings/docker.gpg"

  configure_source "docker/docker.sources"

  apt update

  apt install             \
    docker-ce             \
    docker-ce-cli         \
    containerd.io         \
    docker-buildx-plugin  \
    docker-compose-plugin
fi

# ##############################################################################
# HEADLESS PACKAGES
# ##############################################################################

if [ "$machine_type" = "headless" ]; then
  # tmux keeps sessions alive by ignoring SIGHUP when signing out of a server.
  apt install \
    tmux
fi

# ##############################################################################
# DESKTOP PACKAGES
# ##############################################################################

if [ "$machine_type" = "desktop" ]; then
  apt install     \
    ghostty       \
    gnome-keyring

  # Install Sublime Text
  if ! command -v subl &> /dev/null; then
    install_key \
      "https://download.sublimetext.com/sublimehq-pub.gpg" \
      "/etc/apt/keyrings/sublimehq.gpg"

    configure_source "sublime/sublime-text.sources"

    apt update

    apt install sublime-text sublime-merge
  fi

  # Install VS Code
  if ! command -v code &> /dev/null
  then
    install_key \
      "https://packages.microsoft.com/keys/microsoft.asc" \
      "/etc/apt/keyrings/microsoft.gpg"

    configure_source "vscode/vscode.sources"

    apt update

    apt install code
  fi

  # Install Google Chrome
  if ! command -v google-chrome-stable &> /dev/null
  then
    chrome_installer="${TMPDIR:-/tmp}/google-chrome-stable.deb"

    curl https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
      --location \
      --output="$chrome_installer"

    apt install "$chrome_installer"
  fi

  # Install GitKraken
  # GitKraken will not register with apt for automatic updates, so do not guard
  # against its binary already being installed. Instead, run this every time.
  # Check that gitkraken is not running to prevent any disruption.
  if pgrep -x "gitkraken" > /dev/null
  then
    err "GitKraken is open. Close it before updating."
  else
    gitkraken_installer="${TMPDIR:-/tmp}/gitkraken-amd64.deb"

    curl https://release.gitkraken.com/linux/gitkraken-amd64.deb \
      --location                                                 \
      --output="$gitkraken_installer"

    apt install "$gitkraken_installer"
  fi
fi
