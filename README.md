# claude-workflows

A Claude Code setup you can hand to your own Claude. You talk in plain words ("fix this", "is this ready for a PR?", "polish this screen"), and it picks and chains the right skills:
- a full pre-PR gate that works for any language or stack
- design skills that cooperate instead of clashing
- graphify codebase maps
- Next.js App Router conventions

## Install

Paste this to Claude Code:

> Read https://raw.githubusercontent.com/faizan3165/claude-workflows/main/SETUP.md and set me up.

Claude reads the installer, asks which optional extras you want, runs it, and verifies the result. To do it by hand:

```bash
git clone --depth 1 https://github.com/faizan3165/claude-workflows ~/.cache/claude-workflows/repo
bash ~/.cache/claude-workflows/repo/setup/install.sh            # add --with ponytail,adhd,hallmark,marketing for extras
```

Restart Claude Code afterwards. Re-run the same two commands to update.

## What you get

**This repo's plugin, `workflows`:**

| Skill / agent | What it does |
|---|---|
| `workflows:router` | Maps plain requests (debug, build, review, ship, UI, explain, diagram, plan) to skill chains, so you never type skill names |
| `workflows:pre-pr` | The full gate: scope → hygiene (secrets, debug leftovers, local files) → the repo's own format/lint/typecheck/test/build commands, discovered from its docs, CI, task runner and hooks → test coverage → review agents → security, UI and rules passes → a ready/not-ready report |
| `workflows:design-workflow` | One lead and one critic per design task. impeccable leads product UI, taste-skill leads landing pages, ui-ux-pro-max is the reference library, and the project's tokens and DESIGN.md win |
| `workflows:codebase-map` | How to use graphify on a project: build once, query instead of re-reading, keep it fresh, keep it out of git |
| `workflows:nextjs-stack` | Next.js App Router + React 19 + Tailwind v4 + shadcn/ui + React Hook Form + Zod conventions, with full form and error-handling examples |
| agents `structure-checker`, `code-reviewer`, `simplify-reviewer`, `quality-checker` | The review stage of the gate, for any language |

**Installed from their own repos (not copied here):**

| | Source | License |
|---|---|---|
| superpowers (debugging, plans, TDD, verification) | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official) | see repo |
| mattpocock-skills (code review, PR bodies, grilling) | [mattpocock/skills](https://github.com/mattpocock/skills) | MIT |
| taste-skill (landing pages) | [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill) | MIT |
| diagram-design | [cathrynlavery/diagram-design](https://github.com/cathrynlavery/diagram-design) | MIT |
| impeccable (product UI design) | [pbakaus/impeccable](https://github.com/pbakaus/impeccable) | Apache-2.0 |
| ui-ux-pro-max (UX reference) | [nextlevelbuilder/ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) | MIT |
| security-audit | [cloudflare/security-audit-skill](https://github.com/cloudflare/security-audit-skill) | MIT |
| graphify | [Graphify-Labs/graphify](https://github.com/Graphify-Labs/graphify) (PyPI `graphifyy`) | Apache-2.0 |

**Optional extras** (`--with`):

| | Source |
|---|---|
| `ponytail` | [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail) |
| `adhd` | [ayghri/i-have-adhd](https://github.com/ayghri/i-have-adhd) |
| `hallmark` | [nutlope/hallmark](https://github.com/nutlope/hallmark) |
| `marketing` | [coreyhaines31/marketingskills](https://github.com/coreyhaines31/marketingskills) |

## How it behaves

- **The repo's rules win.** A project's own `CLAUDE.md`, `AGENTS.md`, `.claude/rules/`, `.cursor/rules/` or `CONTRIBUTING.md` overrides these defaults: base branch, gate commands, push policy, conventions.
- **The gate never invents commands.** It runs what the repo already uses, reports missing tools instead of skipping them, and never weakens configs or uses `--no-verify`.
- **Asks before pushing** unless a repo's rules pre-approve it.
- **Lean on purpose.** Process skills (brainstorming, plans, TDD) only run for real feature work, not for questions or small fixes.

## What the installer changes

- Plugins at user scope (`claude plugin marketplace add` / `install`).
- Symlinks in `~/.claude/skills` (or `$CLAUDE_CONFIG_DIR/skills`) pointing to shallow clones in `~/.cache/claude-workflows-skills`.
- One marked block in `CLAUDE.md`, backed up before any change. Re-runs replace only that block.
- The graphify CLI via `uv` or `pipx`.

It doesn't touch permissions or other settings. Uninstall steps are at the end of [SETUP.md](SETUP.md).

## License

MIT for the contents of this repo. Each upstream project keeps its own license.
