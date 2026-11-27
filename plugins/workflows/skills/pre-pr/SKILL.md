---
name: pre-pr
description: Full pre-PR and pre-push quality gate for any language, framework or stack. Checks branch and diff scope, hygiene (secrets, debug leftovers, local-only files), runs the project's own format, lint, typecheck, test and build commands discovered from its docs, CI and task runners, checks test coverage of the change, runs review agents (structure, correctness and security, simplification), a security pass, a UI pass and a rules pass, then reports ready or not ready. Use when someone says pre-pr, review before PR, before I push, is this ready, ship it, or when a feature or fix is finished.
---

# Pre-PR gate

A gate for any repo. Commands are **discovered from the repo, never invented**. Run it on the current branch; it never commits or pushes.

## Levels

- **quick**: steps 0 to 3. For small fixes, docs-only diffs, and the end of debug/build workflows.
- **full**: steps 0 to 8. Default for "pre-pr", "is this ready", "review", and before any push or PR.

## Step 0: Scope

1. Base branch, first match wins: the repo's documented base (rules, CONTRIBUTING), then `git symbolic-ref --short refs/remotes/origin/HEAD` (drop `origin/`), then whichever of `main`, `master`, `develop`, `dev` exists.
2. `git status --short` and `git diff --stat <base>...HEAD`, plus uncommitted changes. Empty diff: stop and say so.
3. On the default branch with changes: say so and suggest a branch, unless the repo commits there directly.
4. Search the diff for conflict markers (`<<<<<<<`, `>>>>>>>`). Any hit is blocking.

## Step 1: Hygiene (added lines only)

- **Secrets (blocking):** if `gitleaks` is installed, scan the branch's commits and staged changes with it (subcommands differ by version: `gitleaks --help`). Otherwise search added lines for private keys (`-----BEGIN .*PRIVATE KEY-----`), cloud keys (`AKIA[0-9A-Z]{16}`, `AIza[0-9A-Za-z_-]{35}`), tokens (`ghp_`, `github_pat_`, `glpat-`, `xox[abp]-`, `sk-`, `sk_live_`), and literal passwords in config. Also any `.env*`, `*.pem`, `*.p12`, `*.keystore`, `credentials*.json` in the diff.
- **Debug leftovers:** `console.log`, `debugger` (JS/TS); `print(`, `breakpoint()`, `pdb` (Python); stray `fmt.Println` (Go); `dbg!` (Rust); `var_dump`, `dd(` (PHP); `binding.pry`, `byebug` (Ruby); `debugPrint` (Dart). Ignore CLIs and real logging.
- **Local-only files:** env files, `*.local.*`, editor folders, OS files, build output, personal config. Lockfile changes with no manifest change: ask.
- **Size:** new binaries or files over 1 MB not covered by Git LFS.
- **Leftovers (warning):** commented-out code blocks, new TODOs without context.

## Step 2: Deterministic gate

Delegate to the `workflows:quality-checker` agent when available; otherwise run it yourself.

**Discover the commands.** First match wins:
1. Repo docs: `CLAUDE.md`, `AGENTS.md`, `CONTRIBUTING.md`, `README` sections on validate, check, lint or test.
2. CI config: `.github/workflows/*.yml`, `.gitlab-ci.yml`, `bitbucket-pipelines.yml`, `azure-pipelines.yml`, `.circleci/config.yml`, `Jenkinsfile`, `.buildkite/`. Use the job that runs on pull requests. Run the same commands locally; skip deploy, publish and release steps and anything that needs CI secrets.
3. Aggregate tasks: `package.json` scripts named `validate`, `check`, `ci` or `verify`; `Makefile`, `justfile` or `Taskfile.yml` targets (`check`, `ci`, `lint`, `test`); composer scripts; mix aliases; tox or nox sessions.
4. Git hooks: `.husky/`, `lefthook.yml`, `.pre-commit-config.yaml` (`pre-commit run --from-ref <base> --to-ref HEAD`).
5. Fallback by manifest: [references/gate-commands.md](references/gate-commands.md). Only tools the repo already configures (config file or dev dependency present).

**Run order:** format check → lint → typecheck → tests → build. In a monorepo, run only the affected packages (turbo, nx, pnpm filters in the reference) or the root task.

**Rules:**
- Use the repo's runner. The lockfile decides: `pnpm-lock.yaml`, `yarn.lock`, `bun.lock`/`bun.lockb`, `package-lock.json`; `uv.lock` → `uv run`, `poetry.lock` → `poetry run`; wrappers `./gradlew`, `./mvnw`.
- A missing tool is reported as "not run: X not installed". Never skip it silently, and never install global tools without asking.
- Fix failures at the root. Never weaken lint, type or test config, add ignores, skip tests, or use `--no-verify` to get green.
- Run tests non-interactively (`CI=true`, no watch mode).
- After fixing, re-run the failing step. Re-run the whole gate once at the end.

## Step 3: Tests cover the change

- Changed behavior has a changed or new test in the same diff.
- A bug fix has a regression test that fails without the fix.
- New endpoints, handlers, actions and jobs have tests at the level the repo already uses.
- If the repo has no tests at all, say so. Don't build a test setup unasked.

## Step 4: Review agents (full)

Run in order as subagents. Give each the base branch, the diff stat and the paths of the repo's rule files. Fix every **Critical** before the next agent.

1. `workflows:structure-checker`: the repo's documented structure and conventions.
2. `workflows:code-reviewer`: correctness, security, error handling, data safety, contracts.
3. `workflows:simplify-reviewer`: duplication, over-engineering, dead code, scope creep.

If the plugin's agents aren't available, use `ponytail:ponytail-review` or `mattpocock-skills:code-review`, or review the diff yourself against the same checklists.

## Step 5: Security pass (full, when relevant)

Run it when the diff touches auth, sessions, permissions, input parsing, file paths, shell or SQL, crypto, payments, uploads, secrets handling, CORS/CSP/headers, deserialization or dependencies.
- Use the `security-audit` skill in focused mode on the touched files if it's installed.
- On dependency changes, run the ecosystem audit if available: `npm audit --omit=dev` / `pnpm audit --prod`, `pip-audit`, `cargo audit`, `govulncheck ./...`, `bundle audit`, `composer audit`, `dotnet list package --vulnerable`. Report high and critical only.

## Step 6: UI pass (full, when the diff touches UI)

- Run the critique step of `workflows:design-workflow`.
- If a dev server and a browser or screenshot tool are available, check mobile and desktop widths.
- Check keyboard access, visible focus, labels and contrast.

## Step 7: Rules pass (full)

Read the diff against the repo's rule files and list each violation with file:line.

## Step 8: Report

| Step | Result |
|---|---|
| Scope | base branch, files changed |
| Hygiene | clean, or each issue |
| Gate | each command: pass / fail / not run (why) |
| Tests | covered, or what's missing |
| Review | Critical found and fixed, open warnings |
| Security | not needed / clean / findings |
| UI | not needed / clean / findings |
| Rules | clean / violations |

Then **Ready: yes/no**. If no, name the one blocking item. Commit and push are separate steps (see `workflows:router`, "ship it").
