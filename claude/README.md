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

## User vs. Project settings

- **User**: preferences that follow the user across every repo: model, theme,
  notification hooks, statusline, cross-language skills, and permissions for
  tools that are safe everywhere (`gh`, `git` reads, package managers,
  read-only system inspection).
- **Project** (`<repo>/.claude/`): build/test commands, language-specific lint
  hooks, `.mcp.json` servers, and `AGENTS.md` (with `CLAUDE.md` as a one-line
  `@AGENTS.md` include so all agents share it).

A note on **`settings.local.json`**: This file is meant to be an untracked,
per-machine version of `settings.json`. Claude appends newly approved
permissions to this file; promote the durable ones into `settings.json` by hand
from time to time.
