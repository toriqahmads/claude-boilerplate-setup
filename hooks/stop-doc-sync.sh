#!/usr/bin/env bash
#
# Stop hook — doc-sync reflection.
#
# When a session ends, if it changed the repo's structure (`.claude/**` or the
# top-level source layout) but left `CLAUDE.md` untouched, emit a non-blocking
# reminder to sync the canonical doc while context is still fresh (per Anthropic's
# large-codebase best practices: a Stop hook that proposes CLAUDE.md updates; and
# this repo's own keep-docs-synced convention).
#
# Contract: ADVISORY ONLY — always exit 0, never emit a block decision, never
# loop. Read-only.

set -u

payload="$(cat 2>/dev/null || true)"

# Guard against re-entrancy: if we're already inside a Stop-hook continuation,
# do nothing. Cheap string check keeps us dependency-free.
case "$payload" in
  *'"stop_hook_active": true'*|*'"stop_hook_active":true'*) exit 0 ;;
esac

ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$ROOT" 2>/dev/null || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# Files touched this session — modified, staged, AND untracked (a new agent/skill
# file is a structural change too). Porcelain strips the 2-char status + space
# prefix; for renames ("old -> new") keep the new path.
changed="$(
  git status --porcelain 2>/dev/null \
    | sed 's/^...//; s/^.* -> //' \
    | sort -u
)"
[ -z "$changed" ] && exit 0

# Did structure change? (.claude/** or common top-level source dirs)
structural="$(printf '%s\n' "$changed" | grep -E '^(\.claude/|src/|app/|lib/|packages/|cmd/|internal/)' || true)"
[ -z "$structural" ] && exit 0

# Was CLAUDE.md already updated? If so, nothing to nag about.
if printf '%s\n' "$changed" | grep -qx 'CLAUDE.md'; then
  exit 0
fi

echo "Reminder: this session changed repo structure but not CLAUDE.md."
echo "Per the keep-docs-synced convention, review whether CLAUDE.md (canonical;"
echo "AGENTS.md follows via symlink) needs updating to match —"
echo "do it now while the context is fresh. Changed:"
printf '%s\n' "$structural" | sed 's/^/  - /'

exit 0
