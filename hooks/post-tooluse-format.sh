#!/usr/bin/env bash
#
# PostToolUse hook (matcher: Write|Edit|MultiEdit) — deterministic formatting.
#
# After Claude edits a file, run the project's configured formatter on JUST that
# file, so style is enforced deterministically instead of relying on Claude to
# remember (per Anthropic's large-codebase best practices).
#
# Contract: format the edited file only, NEVER install anything, NEVER hit the
# network, and ALWAYS exit 0 — a formatter that is absent or fails must not break
# the tool call. Silent no-op when the project has no formatter configured (the
# correct behavior for a fresh/empty repo).

set -u

payload="$(cat 2>/dev/null || true)"

ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$ROOT" 2>/dev/null || exit 0

# --- Extract tool_input.file_path, best-effort, no hard dependency ------------
file=""
if command -v jq >/dev/null 2>&1; then
  file="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"
fi
if [ -z "$file" ] && command -v python3 >/dev/null 2>&1; then
  file="$(printf '%s' "$payload" | python3 -c \
    'import json,sys
try:
    print(json.load(sys.stdin).get("tool_input",{}).get("file_path","") or "")
except Exception:
    print("")' 2>/dev/null)"
fi
if [ -z "$file" ]; then
  # Last resort: grep the first file_path string out of the JSON.
  file="$(printf '%s' "$payload" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' \
    | head -n1 | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"//; s/"$//')"
fi

[ -z "$file" ] && exit 0
[ -f "$file" ] || exit 0

# Run a formatter only if its binary is actually available. Never `npx`-install.
run() { command -v "$1" >/dev/null 2>&1 && "$@" >/dev/null 2>&1; return 0; }

npx_local() {
  # Use a locally-installed CLI only (no download). $1 = bin name, rest = args.
  local bin="$1"; shift
  if [ -x "node_modules/.bin/${bin}" ]; then
    "node_modules/.bin/${bin}" "$@" >/dev/null 2>&1 || true
  elif command -v npx >/dev/null 2>&1; then
    npx --no-install "$bin" "$@" >/dev/null 2>&1 || true
  fi
  return 0
}

case "$file" in
  *.js|*.jsx|*.ts|*.tsx|*.mjs|*.cjs|*.json|*.jsonc|*.css|*.scss|*.less|*.html|*.vue|*.svelte|*.md|*.mdx|*.yaml|*.yml)
    npx_local prettier --write "$file"
    ;;
  *.py)
    if command -v ruff >/dev/null 2>&1; then
      ruff format "$file" >/dev/null 2>&1 || true
    else
      run black "$file"
    fi
    ;;
  *.go)   run gofmt -w "$file" ;;
  *.rs)   run rustfmt "$file" ;;
  *.rb)   run rubocop -a "$file" ;;
  *.sh)   run shfmt -w "$file" ;;
  *)      : ;;  # unknown type → no-op
esac

exit 0
