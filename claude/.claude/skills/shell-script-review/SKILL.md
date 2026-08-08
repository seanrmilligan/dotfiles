---
name: Shell Script Review
description: >-
  Review shell scripts for correctness and convention violations — shebangs,
  set -o errexit/nounset/pipefail, unset-variable defaults, quoting,
  script-directory resolution, and the executable bit. Use when reviewing or
  writing shell scripts, including shell files that appear within a larger
  pull request.
when_to_use: >-
  Reviewing .sh files, bash scripts, or git hooks; auditing a PR that touches
  shell code.
allowed-tools: Bash(shellcheck *)
paths:
  - "**/*.sh"
  - "**/.git/hooks/*"
  - "**/hooks/*"
---

# Shell Script Review

Unless stated otherwise, all findings should be considered blocking.

## Executable Scripts

- A shebang must be present at the top of any script file that can be executed.
- Always prefer `#!/usr/bin/env bash` over `#!/bin/bash`
- Ensure committed scripts have the executable bit set.

## Shellopts

The following shell options should be enabled just after the shebang.

```bash
set -o errexit   # exit immediately on errors
set -o nounset   # exit immediately upon encountering an unset variable
set -o pipefail  # surface errors in pipes (not just the last exit code)
```

## Variables

### Unset Variables

- When `nounset` is set, any expansion of a variable that might be unset must
  supply a default (`${var:-}`) or be guarded.
- Unless an empty value is meaningful, prefer to use `${var:-default}` over `${var-default}`
  - `${var:-default}` substitutes when unset or empty
  - `${var-default}` substitutes when unset (and so preserves empty string).

## Linting

- Scripts should pass `shellcheck`.
- Scripts should conform to https://google.github.io/styleguide/shellguide.html
  - Findings of this type should be considered non-blocking.

## Absolute and relative path handling

Scripts should be runnable from anywhere.

- Relative paths inherit the cwd of the user, not the directory of the script.
  Scripts that use relative paths should consider whether they intend for them
  to be relative to the cwd or the script directory, and apply the following in
  the case of the latter:
  ```bash
  script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
  ```

- Scripts that invoke `git` should handle invocations made from outside of the
  repository:
  ```bash
  git -C "$repo_root" ...
  ```

- Scripts in git repositories that perform operations relative to the repository
  root can combine the previous two. This way, scripts can be invoked outside of
  the repository and yet operate on paths relative to the repository:
  ```bash
  script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
  repo_root=$(git -C "$script_dir" rev-parse --show-toplevel)
  # Example:
  rm -rf "$repo_root/bin"
  rm -rf "$repo_root/out"
  ```

## Flags, Switches, and Options

Flags and switches are names for command line arguments that lack a value.
Options are command line arguments that have a value.

- To encourage self-documenting code, use the long form of flags and switches when available
- To encourage self-documenting code, use the long form of options when available.
