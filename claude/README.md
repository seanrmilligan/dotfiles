# Claude Code

User-wide Claude Code configuration.

```
claude/
└─ .claude/
   ├─ CLAUDE.md                | Global Claude instructions
   ├─ settings.json            | model, theme, hooks, statusline, permissions
   ├─ skills/                  | Global Claude skills
   |  ├─ <skill-name-1>
   |  |  └─ SKILL.md
   |  └─ <skill-name-2>
   |     └─ SKILL.md
   └─ statusline-command.sh    | statusline generator (akin to a shell prompt)

```

## Types of Settings

**User** (`$HOME/.claude/`): preferences that follow the user across every repo:

- model
- theme
- notification hooks
- statusline
- cross-language skills
- permissions for tools that are broadly applicable or harmless:
  - `git`
  - `gh`
  - readonly invocations
  - etc.

**Machine** (`settings.local.json`): A machine-specific copy of `settings.json`:

- installed plugins

**Project** (`<repo>/.claude/`):

- build commands
- test commands
- language-specific lint hooks
- `.mcp.json` servers
- (project-level) `CLAUDE.md` files.
