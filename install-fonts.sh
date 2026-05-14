#!/usr/bin/env bash

set -e


# #############################################################################
# JetBrains Mono
# #############################################################################


# Options:
#   --fail Don't print the returned page if the HTTP status is an error code.
#   --silent Don't print progress bars to the console.
#   --show-error Do give a cURL error message if the fetch fails.
#   --location Follow HTTP 300-range redirects.
curl  https://raw.githubusercontent.com/JetBrains/JetBrainsMono/master/install_manual.sh \
  --fail       \
  --silent     \
  --show-error \
  --location   |
    bash
