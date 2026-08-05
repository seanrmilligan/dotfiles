# AI

Claude Code configuration: skills, and notes on what belongs where.

Managed by git, installed by GNU Stow.

## GNU Stow

This README assumes a working knowledge of GNU Stow. Installing files via GNU
Stow is covered more in the [configs README.md](../configs/README.md).

## Layout

```
experimental/user/sean.milligan/ai/
├─ install-claude.sh
├─ claude/                   | the "claude" GNU Stow package
│  ├─ .claude/
│  │  ├─ skills/
│  │  │  ├─ <skill-name>/
│  │  │  │  ├─ SKILL.md      | the skill itself
```

## Installing

```sh
cd $HOME/projects/experimental/user/sean.milligan/ai &&
  ./install-claude.sh
```

## Skills

- A skill is a directory under `.claude/skills/` containing a `SKILL.md`.
- A skill has a yaml document at the top called "frontmatter". While all fields
  are optional, Claude benefits from a `name` and a `description`. Claude reads
  the description to decide when the skill is relevant, so it should say both
  what the skill does and when to use it.
- User-level skills in `~/.claude/skills/` are available in every project.
