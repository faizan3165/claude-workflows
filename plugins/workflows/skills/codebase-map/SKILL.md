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

If the CLI is missing: `uv tool install graphifyy` (or `pipx install graphifyy`), then `graphify install --platform claude` once to add the `/graphify` skill. Commands below are for graphify 0.9+. On older versions, upgrade first (`uv tool upgrade graphifyy` or `pipx upgrade graphifyy`). `graphify --help` lists what the installed version supports.

## 2. First build (once per repo)

1. Add the output folder to the local exclude file, so it never gets committed (unless the team decides to commit the graph):
   ```bash
   grep -qxF 'graphify-out/' .git/info/exclude || echo 'graphify-out/' >> .git/info/exclude
   ```
2. Tell the user the first build reads the whole folder. Code is cheap (AST); large docs folders cost tokens.
3. Build:
   - Whole repo: `/graphify .`
   - Large monorepo: graph the part you need, e.g. `/graphify ./services/api`
   - No HTML needed: `/graphify . --no-viz`
   - Code only, no model calls at all: `graphify update .` (builds the AST graph and report; add docs later with `/graphify . --update`)

## 3. Use the graph (before reading files)

1. Read `graphify-out/GRAPH_REPORT.md` first: central modules, communities, surprising connections. `graphify god-nodes` lists the architectural hubs.
2. Ask the graph (all CLI, no model calls):
   - `graphify query "how does a request reach the database"`: breadth-first, broad context. Add `--dfs` to trace one path, `--budget 1500` to cap tokens, `--seed <node or file>` to start from a known place.
   - `graphify path "AuthModule" "Database"`: the shortest path between two concepts.
   - `graphify explain "PaymentService"`: one node and its neighbours in plain language.
   - `graphify affected "createInvoice"`: what is impacted if this changes. Use it before refactors and in reviews.
   - An exit code of 3 means the name is ambiguous (candidates are listed); 4 means no match.
3. Edges are tagged EXTRACTED, INFERRED or AMBIGUOUS. Treat INFERRED and AMBIGUOUS as leads. Open the files the graph points to and confirm before you edit or state anything as fact.

## 4. Keep it fresh

- After code changes: `graphify update .` (code only, no model calls), or `/graphify . --update` when docs changed too.
- During long agent sessions: `graphify watch .` in a background terminal rebuilds code changes automatically.
- Before relying on an old graph after a big refactor, update it first.

These change repo state, so they are opt-in per project. Ask first:
- `graphify hook install` adds git hooks (post-commit, post-checkout, post-merge, post-rewrite) that rebuild code nodes.
- `graphify claude install` writes a graphify section into the project's `CLAUDE.md` (or the `AGENTS.md` Claude Code reads) and a PreToolUse hook. Both are usually tracked files, so it's a team decision.
- For Cursor: `graphify cursor install` writes `.cursor/rules/graphify.mdc` into the current folder, as an always-on rule.

## Known traps

- Use `graphify --help` for help. Older versions ran a real install on `graphify install --help`.
- `graphify uninstall --purge` also deletes `graphify-out/`.
- Run `graphify cursor install` and `graphify install --platform cursor` only inside a project. From the home folder they write `~/.cursor/rules/graphify.mdc`: a global always-on rule that forces graphify before every read or search, even in repos with no graph.
- Never run the HTML view on a graph over 5,000 nodes without warning the user (`--no-viz` skips it).
