# claude

User-wide Claude Code configuration, installed to `$HOME/.claude` by GNU Stow.

```
claude/
└─ .claude/
   ├─ CLAUDE.md                | global instructions for every project
   ├─ settings.json            | model, theme, hooks, statusline, permissions
   ├─ statusline-command.sh    | statusline renderer (mirrors .bashrc prompt)
   └─ skills/<name>/SKILL.md   | user-level skills, available in every project
```

## Installing

```sh
stow claude
```

`install-dotfiles.sh` creates `$HOME/.claude/skills` first so Stow links
individual files rather than folding whole directories — `$HOME/.claude` also
holds runtime state (sessions, history, caches) that must not land in the repo.

## Migrating from the old package

This supersedes `~/projects/experimental/user/sean.milligan/ai/` and its
`install-claude.sh`. That package stowed `~/.claude/skills/shell-script-review`,
which conflicts here. Unstow it first:

```sh
stow --delete --dir="$HOME/projects/experimental/user/sean.milligan/ai" \
  --target="$HOME" claude
```

Then delete `ai/claude/` and `ai/install-claude.sh` from that repo, keeping
`ai/README.md` and `ai/CLAUDE.md` if the notes are still wanted there.

## What belongs here vs. in a project

- **Here**: preferences that follow the user across every repo — model, theme,
  notification hooks, statusline, cross-language skills, and permissions for
  tools that are safe everywhere (`gh`, `git` reads, package managers,
  read-only system inspection).
- **In the project** (`<repo>/.claude/`, tracked by that repo): build/test
  commands, language-specific lint hooks, `.mcp.json` servers, and `AGENTS.md`
  (with `CLAUDE.md` as a one-line `@AGENTS.md` include so all agents share it).
- **`settings.local.json`** (untracked, per machine): left out of this package
  on purpose. Claude appends newly approved permissions there; promote the
  durable ones into `settings.json` here by hand.

## Permissions

`settings.json` merges the allowlists that had accumulated in
`~/.claude/settings.local.json` and in each repo's
`.claude/settings.local.json`. One-shot entries were dropped: absolute paths
under `/home/sean` or `/tmp/claude-*`, specific patch/ticket IDs, `node -e`
and `python3 -c` one-liners, ad-hoc `mongod` and `curl` invocations, and
timestamped `journalctl` queries. Redundant narrow entries were collapsed into
the glob that already covers them (e.g. `npm run *` into `npm *`).
