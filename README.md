# SKILL_NAME

> **This is a template.** Click **Use this template** on GitHub (or
> `gh repo create <you>/<skill>-skill --template Gamma-Software/skill-template`),
> then run `./init.sh <skill-slug>` and fill in `SKILL.md`. Delete this banner
> when done.

A one-line pitch of the skill, as a skill for Claude Code (and any agent that
supports skills — OpenCode, Codex, Cursor).

```
Step1 → Step2 → [human gate] → Step3 → Verify → Clean up
```

## How it works

1. First thing it does.
2. Second thing.
3. Validates with measurements, then reports.

## Install

```bash
npx add-skill Gamma-Software/SKILL_REPO           # all detected agents
npx add-skill Gamma-Software/SKILL_REPO --global  # globally
```

Or manually:

```bash
git clone https://github.com/Gamma-Software/SKILL_REPO.git
ln -s "$PWD/SKILL_REPO" ~/.claude/skills/SKILL_SLUG   # or copy it
```

## Usage

Describe the task — it auto-triggers on the phrases in `SKILL.md`'s
`description` — or run `/SKILL_SLUG`.

| Agent | Global path | Project path |
|-------|-------------|--------------|
| Claude Code | `~/.claude/skills/SKILL_SLUG/` | `.claude/skills/SKILL_SLUG/` |
| OpenCode | `~/.config/opencode/skill/SKILL_SLUG/` | `.opencode/skill/SKILL_SLUG/` |
| Codex | `~/.codex/skills/SKILL_SLUG/` | `.codex/skills/SKILL_SLUG/` |
| Cursor | `~/.cursor/skills/SKILL_SLUG/` | `.cursor/skills/SKILL_SLUG/` |

## Structure

```
SKILL_REPO/
├── SKILL.md              # the skill itself (frontmatter + procedure)
├── scripts/              # executable helpers the skill calls (optional)
├── assets/              # templates/files the skill copies into a project (optional)
├── references/          # long material the agent reads on demand (optional)
└── evals/               # trigger / behavior evals (optional)
```

## Requirements

- List runtime deps here (e.g. Node 18+, bash 3.2+, git).

## License

MIT
