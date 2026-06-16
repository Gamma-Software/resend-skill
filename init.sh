#!/usr/bin/env bash
# init.sh — scaffold a new skill from this template.
# Run ONCE right after creating a repo from Gamma-Software/skill-template.
#
#   ./init.sh <skill-slug> ["Skill Name"] [repo-name]
#
# - <skill-slug>  kebab-case, becomes SKILL.md `name` and the skills/ dir name
# - "Skill Name"  human title (defaults to the slug, Title-Cased)
# - repo-name     the GitHub repo name (defaults to "<slug>-skill")
#
# Replaces the SKILL_SLUG / SKILL_NAME / SKILL_REPO placeholders across the repo,
# then deletes itself.
set -euo pipefail

slug="${1:-}"
[ -n "$slug" ] || { echo "usage: ./init.sh <skill-slug> [\"Skill Name\"] [repo-name]" >&2; exit 1; }
case "$slug" in *[!a-z0-9-]*) echo "slug must be kebab-case [a-z0-9-]" >&2; exit 1;; esac

name="${2:-$(echo "$slug" | tr '-' ' ')}"
repo="${3:-${slug}-skill}"

# BSD/GNU sed compatible in-place edit
sed_i() { if sed --version >/dev/null 2>&1; then sed -i "$@"; else sed -i '' "$@"; fi; }

files=$(grep -rl -e SKILL_SLUG -e SKILL_NAME -e SKILL_REPO . \
  --exclude-dir=.git --exclude=init.sh 2>/dev/null || true)
for f in $files; do
  sed_i -e "s/SKILL_REPO/${repo}/g" -e "s/SKILL_SLUG/${slug}/g" -e "s/SKILL_NAME/${name}/g" "$f"
done

echo "Scaffolded skill '${slug}' (repo ${repo}, title \"${name}\")."
echo "Next: write SKILL.md (description line drives triggering), then:"
echo "  git rm init.sh && git commit -am 'chore: scaffold from skill-template'"
rm -- "$0"
