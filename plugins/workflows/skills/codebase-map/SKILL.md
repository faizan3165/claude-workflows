---
name: codebase-map
description: Uses graphify correctly on a project - builds a knowledge graph of the repo once, queries it instead of re-reading files, keeps it fresh after changes, and keeps its output out of git. Use when someone asks to explain or onboard onto a codebase, map the architecture, find how modules connect, or answer cross-cutting "where does X happen / how does X reach Y" questions in a large repo.
---

# Codebase map (graphify)

graphify turns a folder into a knowledge graph (`graphify-out/graph.json`), a plain-language report (`graphify-out/GRAPH_REPORT.md`) and an HTML view. Code is parsed with tree-sitter ASTs (cheap and deterministic). Docs, papers and images go through the model (costs tokens). The graph persists across sessions.

The CLI is `graphify`; the PyPI package is `graphifyy` (two y's). The `/graphify` skill runs the full build.

## When to use it

- **Use:** onboarding onto an unfamiliar or large repo (roughly 50+ files), architecture questions, "what depends on X", tracing a flow across modules, finding connections between docs and code.
- **Skip:** small repos, single-file questions, or anything a quick grep answers.

## 1. Check what exists

```bash
command -v graphify          # CLI installed?
ls graphify-out/graph.json   # graph already built for this repo?
```

If the CLI is missing: `uv tool install graphifyy` (or `pipx install graphifyy`), then `graphify install` once to add the `/graphify` skill.

## 2. First build (once per repo)

1. Add the output folder to the local exclude file, so it never gets committed (unless the team decides to commit the graph):
   ```bash
   grep -qxF 'graphify-out/' .git/info/exclude || echo 'graphify-out/' >> .git/info/exclude
   ```
2. Tell the user the first build reads the whole folder. Code is cheap; large docs folders cost tokens.
3. Build:
   - Whole repo: `/graphify .`
   - Large monorepo: graph the part you need, e.g. `/graphify ./services/api`
   - No HTML needed: `/graphify . --no-viz`

## 3. Use the graph (before reading files)

1. Read `graphify-out/GRAPH_REPORT.md` first: central modules, communities, surprising connections.
2. Ask the graph:
   - `graphify query "how does a request reach the database"` (breadth-first, broad context)
   - `graphify query "<question>" --dfs` to trace one specific path
   - `graphify query "<question>" --budget 1500` to cap the output tokens
   - `/graphify path "AuthModule" "Database"` for the shortest path between two concepts
   - `/graphify explain "PaymentService"` for one node in plain language
3. Edges are tagged EXTRACTED, INFERRED or AMBIGUOUS. Treat INFERRED and AMBIGUOUS as leads. Open the files the graph points to and confirm before you edit or state anything as fact.

## 4. Keep it fresh

- After code changes: `/graphify . --update` (re-extracts only new and changed files).
- During long agent sessions: `/graphify . --watch` in a background terminal rebuilds code changes automatically, with no model calls.
- Before relying on an old graph after a big refactor, run `--update` first.

These change repo state, so they are opt-in per project. Ask first:
- `graphify hook install` adds a git post-commit hook that rebuilds code nodes after each commit.
- `graphify claude install` writes a `## graphify` section into the project's `CLAUDE.md` and a PreToolUse hook into `.claude/settings.json`. Both are usually tracked files, so it's a team decision.
- For Cursor: `graphify cursor install` writes `.cursor/rules/graphify.mdc`.

## Known traps

- `graphify install --help` does not print help; it runs the install. Use `graphify --help` only.
- `graphify install --platform cursor` has crashed on some versions. Use `graphify cursor install` per project instead.
- `graphify install` always writes to `~/.claude`, even when `CLAUDE_CONFIG_DIR` points somewhere else. Link `~/.claude/skills/graphify` into the active config's `skills/` folder.
- Never run the HTML view on a graph over 5,000 nodes without warning the user.
