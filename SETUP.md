# Setup instructions for Claude Code

You are setting up **claude-workflows** for the person you're working with. Follow these steps in order. Don't change permissions, hooks or settings beyond what the installer does. If a step fails, stop, show the error, and don't work around it with `sudo` or by editing settings by hand.

## 1. Check prerequisites

```bash
claude --version && git --version
command -v uv || command -v pipx || echo "no uv/pipx: graphify will be skipped"
```

## 2. Get the repo (or update it)

```bash
dir=${XDG_CACHE_HOME:-$HOME/.cache}/claude-workflows/repo
if [ -d "$dir/.git" ]; then git -C "$dir" pull --ff-only; else git clone --depth 1 https://github.com/faizan3165/claude-workflows "$dir"; fi
```

## 3. Read the installer before running it

Read `setup/install.sh` in that folder. Tell the person in 3 short lines what it will install and change:
- Plugins at user scope.
- Skill links in the Claude config's `skills/` folder.
- One marked block in their `CLAUDE.md` (backed up first).
- The graphify CLI, whose own installer adds a short `# graphify` section to `~/.claude/CLAUDE.md`.

## 4. Ask one question

Ask which optional extras they want (multi-select, default none):

| Extra | What it does |
|---|---|
| `ponytail` | Always-on "lazy senior dev" mode: smallest complete change, ends replies with what was skipped and the risks |
| `adhd` | Always-on reply shape for ADHD readers: next action first, numbered steps, one next step at the end |
| `hallmark` | An alternate design lead for brand-new landing pages |
| `marketing` | 50+ marketing skills (copy, SEO, launch, pricing). Adds a lot to the skill list. |

Also ask whether to skip graphify (default: install it).

## 5. Run the installer

```bash
bash "${XDG_CACHE_HOME:-$HOME/.cache}/claude-workflows/repo/setup/install.sh" --with <comma-separated extras>
```

- Leave out `--with` for none.
- Add `--no-graphify` to skip graphify.
- `--dry-run` prints the steps without changing anything.
- It respects `CLAUDE_CONFIG_DIR` if they use a non-default Claude profile.

## 6. Verify

- `claude plugin list` shows `workflows@claude-workflows`, `superpowers@claude-plugins-official`, `mattpocock-skills@mattpocock`, `taste-skill@taste-skill`, `diagram-design@diagram-design`, plus the chosen extras.
- The config's `skills/` folder has `impeccable`, `ui-ux-pro-max`, `security-audit` and (unless skipped) `graphify`.
- `CLAUDE.md` contains the `claude-workflows:start` block exactly once.

## 7. Tell them how to use it

Restart Claude Code, then talk in plain words. For example:
- "why is the login test failing?" → debug workflow
- "add CSV export to the reports page" → build workflow
- "is this ready for a PR?" → full pre-PR gate
- "polish the settings screen" → design workflow
- "explain how this repo is put together" → codebase map with graphify

## Updating later

Re-run steps 2 and 5. The installer updates the plugins and skills in place and rewrites only its own `CLAUDE.md` block.

## Uninstalling

1. `claude plugin uninstall workflows@claude-workflows --scope user`. Do the same for any other plugins they no longer want.
2. Remove the `impeccable`, `ui-ux-pro-max`, `security-audit` and `graphify` links from the config's `skills/` folder.
3. Delete the lines between `<!-- claude-workflows:start` and `<!-- claude-workflows:end -->` in `CLAUDE.md`, plus the `# graphify` section if graphify was installed. A `CLAUDE.md.bak.*` backup sits next to it.
