---
name: SKILL_SLUG
description: ONE sentence — what the skill does AND when to trigger it. Pack trigger phrases a user would actually type ("do X", "fix Y", "set up Z") right into this line; the agent matches on it. Keep it specific and verb-led. Replace this whole block.
---

# Skill Title

One-paragraph orientation: what this skill installs/does and the shape of the
work. Lead with the outcome, not the mechanism.

```
Step1 → Step2 → [human-in-the-loop gate] → Step3 → Verify → Clean up
```

## 1. <First phase>

Concrete, ordered instructions the agent follows. Prefer imperative voice
("Copy X", "Run Y", "Read one generated file and spot-check"). State the *why*
only where a future maintainer would otherwise simplify away something
load-bearing.

## 2. <Second phase>

- Bullet the decision points (single repo vs. workspace, language coverage…).
- Reference bundled assets by path: `assets/<file>`, `scripts/<file>`.
- Call out the human-in-the-loop gates explicitly if any.

## 3. Validate

Don't declare success blind. List the gates: syntax, a real run, an edge-case
check, and a measured recall/behavior check. A gate exists because skipping it
shipped a bug at least once — say so.

## 4. Report

Summarize for the user: what was installed/changed, measurements, a
gate/pass/evidence table, and what was skipped.

<!--
TEMPLATE NOTES (delete this block when authoring):
- `name` MUST be the kebab-case slug and MUST match the repo skill dir name.
- `description` is the single most important line — it drives triggering.
  Write it last, after the body exists. Front-load trigger phrases.
- Keep SKILL.md lean; push long material into references/*.md, code into
  scripts/ or assets/. The agent reads references on demand.
- Run the skill-creator skill to lint description quality if available.
-->
