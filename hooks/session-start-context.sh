#!/usr/bin/env bash
#
# SessionStart hook — dynamic context loader.
#
# Prints a short, useful context header to stdout, which Claude Code injects into
# the session so every session resumes with the right footing (per Anthropic's
# large-codebase best practices: "load team-specific context dynamically").
#
# Contract: read-only, no runtime deps, ALWAYS exit 0 — a hook must never break a
# session. Every probe is guarded so a missing dir/file/tool is skipped silently.

set -u

# Hook JSON arrives on stdin; we don't need any of it. Drain it so the pipe closes.
cat >/dev/null 2>&1 || true

# Anchor to the project dir when Claude Code provides it; else current dir.
ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$ROOT" 2>/dev/null || exit 0

# Not a git repo → nothing useful to say, but still succeed.
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

echo "## Session context"

branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
[ -n "${branch:-}" ] && echo "- Branch: ${branch}"

dirty="$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
[ "${dirty:-0}" != "0" ] && echo "- Uncommitted changes: ${dirty} file(s)"

# In-progress phase work: any progress.md not yet stamped DONE.
if [ -d docs/plan ]; then
  inprog=""
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    if ! grep -qi 'Status:.*DONE' "$f" 2>/dev/null; then
      inprog="${inprog}  - ${f}\n"
    fi
  done <<EOF
$(find docs/plan -name 'progress.md' 2>/dev/null)
EOF
  if [ -n "$inprog" ]; then
    echo "- In-progress phase plans:"
    printf "%b" "$inprog"
  fi
fi

# API-contract state — so parallel backend/frontend tracks resume across sessions with the
# right footing (see the coordinating-api-contract skill). Each probe is guarded and best-effort.
if [ -d docs/plan/contracts ]; then
  # Frozen contract artifacts + their current version (from the status ledger when present).
  while IFS= read -r s; do
    [ -z "$s" ] && continue
    art="$(grep -m1 -E '^\*\*Artifact:\*\*' "$s" 2>/dev/null | sed 's/^\*\*Artifact:\*\* *//')"
    ver="$(grep -m1 -E '^\*\*Current version:\*\*' "$s" 2>/dev/null | sed -E 's/^\*\*Current version:\*\* *//; s/ .*//')"
    [ -z "$art" ] && art="$s"
    echo "- Contract: ${art}${ver:+ @ ${ver}}"
  done <<EOF
$(find docs/plan/contracts -maxdepth 1 -name '*.status.md' 2>/dev/null)
EOF

  # Stale-track warnings the contract-change protocol wrote into the ledger — surface verbatim.
  while IFS= read -r w; do
    [ -z "$w" ] && continue
    # Trim leading markdown list punctuation for a clean line.
    echo "- $(printf '%s' "$w" | sed -E 's/^[[:space:]]*-[[:space:]]*//')"
  done <<EOF
$(grep -rhE 'NEEDS-RESYNC' docs/plan/contracts/ 2>/dev/null)
EOF
fi

# Multiple worktrees usually means parallel contract tracks are live — list them.
wt="$(git worktree list 2>/dev/null)"
if [ -n "${wt:-}" ] && [ "$(printf '%s\n' "$wt" | wc -l | tr -d ' ')" -gt 1 ]; then
  echo "- Worktrees:"
  printf '%s\n' "$wt" | while IFS= read -r line; do
    [ -z "$line" ] && continue
    echo "  - ${line}"
  done
fi

exit 0
