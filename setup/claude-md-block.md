<!-- claude-workflows:start (managed by github.com/faizan3165/claude-workflows; re-running setup replaces this block, so put your own rules outside it) -->
## Workflows

- Plain-language requests go through the `workflows:router` skill. Pick the workflow from intent, name it in one line, and run it. Don't ask which skill to use.
- The repo's own rules (`CLAUDE.md`, `AGENTS.md`, `.claude/rules/`, `.cursor/rules/`, `CONTRIBUTING.md`) beat these defaults.
- Before calling work done, run `workflows:pre-pr`: quick for small changes, full before any PR or push.
- UI work uses `workflows:design-workflow`. Next.js App Router repos use `workflows:nextjs-stack`. Codebase questions in large repos use `workflows:codebase-map` (graphify).
- Process skills (brainstorming, plans, TDD) are for non-trivial features and multi-step changes only.
- Never push, force-push or open a PR without asking, unless the repo's rules pre-approve it. Never use `--no-verify`.
- Comments only for the non-obvious why.
<!-- claude-workflows:end -->
