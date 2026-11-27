---
name: router
description: Routes plain-language requests to the right skill chain so the user never has to name a skill. Use whenever someone asks to fix, debug, build, add, implement, review, check before a PR, ship, commit, push, audit, secure, design or polish UI, explain a codebase, draw a diagram, plan, or poke holes in a plan, and they did not name a skill.
---

# Workflow router

People talk in plain words. Pick the workflow from intent, name it in one line ("Workflow: debug"), then run the steps. Don't ask which skill to use.

## Precedence

1. The repo's own rules win: `CLAUDE.md`, `AGENTS.md`, `.claude/rules/`, `.cursor/rules/`, `CONTRIBUTING.md`.
2. Process skills (brainstorming, writing-plans, test-driven-development) are for non-trivial features and multi-step changes. Skip them for questions, lookups, config, installs and small fixes.
3. If a skill in a chain isn't installed, do that step yourself and keep going. Never stop just because a skill is missing.
4. Never ask what the code or context can answer. One question at a time, with your recommendation first.

## Workflows

| They say something like | Chain |
|---|---|
| "fix / debug / why is X broken / this throws" | `superpowers:systematic-debugging` → failing repro test → root-cause fix (grep every caller first) → `workflows:pre-pr` quick → `superpowers:verification-before-completion` → summary |
| "build / add / implement X" | `superpowers:brainstorming` only if the ask is ambiguous → `superpowers:writing-plans` (skip under 3 files) → `superpowers:test-driven-development` → `workflows:pre-pr` quick → summary |
| "review this / is this ok / check my changes" | `workflows:pre-pr` full, review steps only (no shipping) → ranked findings → offer fixes |
| "pre-pr / before I push / is this ready / ready for review" | `workflows:pre-pr` full |
| "ship it / commit / push / open a PR" | `workflows:pre-pr` (full, or quick for docs-only diffs) → commit → ask before pushing → PR body with `mattpocock-skills:pr` if they want a PR |
| any UI or design work: build, redesign, polish, restyle, animate, critique, landing page | `workflows:design-workflow` |
| writing or reviewing code in a Next.js App Router repo | `workflows:nextjs-stack` alongside the chain above |
| "explain this codebase / onboard me / how does X connect to Y" (large repo) | `workflows:codebase-map` |
| "audit the repo / what can I delete / tech debt" | `ponytail:ponytail-audit` if installed, else the `workflows:simplify-reviewer` agent across the repo |
| "security check / is this safe" | `security-audit` skill, focused on what they point at |
| "draw / diagram this" | `diagram-design:diagram-design` |
| "grill me / poke holes in this plan" | `mattpocock-skills:grilling` |
| "plan this / spec this" | `superpowers:writing-plans` |
| marketing, copy, SEO, launch, pricing | the matching `marketing-skills:*` skill, if installed |

## Shipping defaults (repo rules override)

- Commit on the current branch. Don't commit straight to the default branch unless the repo works that way.
- Match the repo's commit style: read `git log --oneline -10` first.
- Stage only files that belong to the change. Never stage `.env*`, local overrides, editor folders or build output.
- Ask before every push unless the repo's rules say pushing is pre-approved. Never force-push a shared branch. Never use `--no-verify`.
- After pushing, report branch, commit SHA and the PR link if one exists.

## Finishing any workflow

End with what now works, how to try it, anything skipped or unchecked, and one concrete next step.
