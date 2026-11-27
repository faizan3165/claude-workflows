#!/usr/bin/env bash
# Installs the claude-workflows setup for Claude Code. Safe to re-run (it updates in place).
# Usage: setup/install.sh [--with ponytail,adhd,hallmark,marketing|all] [--no-graphify] [--dry-run]
#
# What it touches:
#   - Claude Code plugins (user scope) via `claude plugin marketplace add` / `claude plugin install`
#   - Skill links in $CLAUDE_CONFIG_DIR/skills (default ~/.claude/skills), cloned into ~/.cache/claude-workflows
#   - One marked block in $CLAUDE_CONFIG_DIR/CLAUDE.md (backed up before any change)
#   - graphify CLI via uv or pipx; `graphify install` adds its skill and a short section to ~/.claude/CLAUDE.md (skip with --no-graphify)
# It never changes permissions, hooks or other settings.
set -euo pipefail

CONFIG_DIR=${CLAUDE_CONFIG_DIR:-$HOME/.claude}
CACHE_DIR=${XDG_CACHE_HOME:-$HOME/.cache}/claude-workflows
SOURCE=${CLAUDE_WORKFLOWS_SOURCE:-faizan3165/claude-workflows}
BLOCK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/claude-md-block.md"
WITH="" GRAPHIFY=1 DRY_RUN=0
export PATH="$HOME/.local/bin:$PATH"

while [ $# -gt 0 ]; do
  case $1 in
    --with) WITH=${2:-}; shift 2 ;;
    --with=*) WITH=${1#*=}; shift ;;
    --no-graphify) GRAPHIFY=0; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) sed -n '2,3p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

run() { echo "+ $*"; [ "$DRY_RUN" = 1 ] || "$@"; }
has() { command -v "$1" >/dev/null 2>&1; }
wants() { case ",$WITH," in *",$1,"*|*",all,"*) return 0 ;; *) return 1 ;; esac; }

for tool in claude git; do has "$tool" || { echo "missing required tool: $tool" >&2; exit 1; }; done

marketplace() { # <name> <source>
  if claude plugin marketplace list --json 2>/dev/null | grep -qF "\"name\": \"$1\""; then
    echo "= marketplace $1"
    run claude plugin marketplace update "$1" >/dev/null
  else
    run claude plugin marketplace add "$2"
  fi
}

plugin() { # <plugin@marketplace>
  if claude plugin list --json 2>/dev/null | grep -qF "\"id\": \"$1\""; then
    echo "= plugin $1"
    run claude plugin update "$1" --scope user >/dev/null
  else
    run claude plugin install "$1" --scope user
  fi
}

skill_link() { # <skill-name> <github owner/repo> <path to skill folder in repo>
  local src="$CACHE_DIR/src/${2//\//__}" dest="$CONFIG_DIR/skills/$1"
  if [ -d "$src/.git" ]; then run git -C "$src" pull --ff-only --quiet || echo "! could not update $2; keeping the current copy"
  else run git clone --depth 1 --quiet "https://github.com/$2.git" "$src"; fi
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    echo "! $dest already exists and is not a link; left untouched"
    return
  fi
  run mkdir -p "$CONFIG_DIR/skills"
  run ln -sfn "$src/$3" "$dest"
}

echo "== Plugins"
marketplace claude-plugins-official anthropics/claude-plugins-official
marketplace mattpocock mattpocock/skills
marketplace taste-skill Leonxlnx/taste-skill
marketplace diagram-design cathrynlavery/diagram-design
marketplace claude-workflows "$SOURCE"
plugin superpowers@claude-plugins-official
plugin mattpocock-skills@mattpocock
plugin taste-skill@taste-skill
plugin diagram-design@diagram-design
plugin workflows@claude-workflows

if wants ponytail; then marketplace ponytail DietrichGebert/ponytail; plugin ponytail@ponytail; fi
if wants adhd; then marketplace i-have-adhd ayghri/i-have-adhd; plugin i-have-adhd@i-have-adhd; fi
if wants hallmark; then marketplace hallmark nutlope/hallmark; plugin hallmark@hallmark; fi
if wants marketing; then marketplace marketingskills coreyhaines31/marketingskills; plugin marketing-skills@marketingskills; fi

echo "== Skills (linked from upstream clones, no hooks)"
skill_link impeccable pbakaus/impeccable plugin/skills/impeccable
skill_link ui-ux-pro-max nextlevelbuilder/ui-ux-pro-max-skill .claude/skills/ui-ux-pro-max
skill_link security-audit cloudflare/security-audit-skill skills/security-audit

if [ "$GRAPHIFY" = 1 ]; then
  echo "== graphify"
  if has uv && uv tool list 2>/dev/null | grep -q '^graphifyy '; then run uv tool upgrade graphifyy
  elif has pipx && pipx list --short 2>/dev/null | grep -q '^graphifyy '; then run pipx upgrade graphifyy
  elif has graphify; then echo "= graphify found (not managed by uv or pipx); left as is"
  elif has uv; then run uv tool install graphifyy
  elif has pipx; then run pipx install graphifyy
  else echo "! graphify skipped: install uv (https://docs.astral.sh/uv/) or pipx, then re-run"; fi
  if has graphify; then
    run graphify install --platform claude
    if [ "$CONFIG_DIR" != "$HOME/.claude" ] && [ ! -e "$CONFIG_DIR/skills/graphify" ]; then
      run ln -sfn "$HOME/.claude/skills/graphify" "$CONFIG_DIR/skills/graphify"
    fi
  fi
fi

echo "== CLAUDE.md block"
claude_md="$CONFIG_DIR/CLAUDE.md"
if [ "$DRY_RUN" = 1 ]; then
  echo "+ write the claude-workflows block into $claude_md"
else
  mkdir -p "$CONFIG_DIR"
  touch "$claude_md"
  tmp=$(mktemp)
  awk -v block="$BLOCK" '
    function emit(  line) { while ((getline line < block) > 0) print line; close(block) }
    /<!-- claude-workflows:start/ { emit(); skip = 1; found = 1; next }
    /<!-- claude-workflows:end -->/ { skip = 0; next }
    !skip { print }
    END { if (!found) { if (NR > 0) print ""; emit() } }
  ' "$claude_md" > "$tmp"
  if cmp -s "$tmp" "$claude_md"; then
    echo "= block up to date"
  else
    [ -s "$claude_md" ] && cp "$claude_md" "$claude_md.bak.$(date +%Y%m%d%H%M%S)"
    cat "$tmp" > "$claude_md"
    echo "+ block written to $claude_md"
  fi
  rm -f "$tmp"
fi

echo "== Done. Restart Claude Code, then just ask in plain words (\"fix …\", \"is this ready for a PR?\", \"polish this screen\")."
