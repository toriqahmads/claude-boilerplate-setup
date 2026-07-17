#!/usr/bin/env bash
#
# install.sh — install the `claude-boilerplate` plugin at your chosen scope.
#
# Three outcomes:
#   user             — enable globally in ~/.claude/settings.json (every project, this user).
#   project · local  — enable for the CURRENT project only, in that project's
#                      .claude/settings.local.json, which is gitignored. Nothing is committed
#                      or pushed.
#   project · shared — enable for the CURRENT project and COMMIT it: written to
#                      .claude/settings.json so teammates get the plugin on clone + trust.
#                      The committed file records the marketplace source, so a shared install
#                      needs a resolvable GitHub repo (owner/repo), not a local path.
#
# In every case the plugin's own files live in Claude Code's central cache
# (~/.claude/plugins/cache/), never inside your repo. This never creates or overwrites
# CLAUDE.md. To scaffold docs afterwards, run:  /claude-boilerplate:setup
#
# MCP servers: the keyless CORE servers (context7, playwright, shadcn) ship in the plugin's
# .mcp.json and load automatically when the plugin is enabled — nothing to do. The installer
# only asks about the OPTIONAL auth-gated servers (figma, sentry), which are off by default.
#
# Usage:
#   bash install.sh                      # interactive (scope, then private/shared, then optional-MCP y/N)
#   bash install.sh --user               # global
#   bash install.sh --local              # current project, local-only (gitignored)
#   bash install.sh --shared             # current project, committed/shared
#   bash install.sh --scope user|local|project
#   bash install.sh --shared --repo owner/repo   # supply the shareable source non-interactively
#   bash install.sh --local --mcp        # also add the optional auth MCP servers (or --no-mcp to skip)
#
# Contract: prereq-checked, idempotent, safe to re-run, always exits 0.

set -u

MARKETPLACE_NAME="claude-boilerplate-market"
PLUGIN="claude-boilerplate"

# Absolute path to this clone (the marketplace source), independent of the caller's CWD.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

info() { printf '  %s\n'   "$*"; }
warn() { printf '  ! %s\n' "$*" >&2; }
sect() { printf '\n== %s ==\n' "$*"; }

# --- parse flags -----------------------------------------------------------
SCOPE=""          # user | local | project
REPO_SRC=""       # explicit marketplace source for a shared install
MCP_CHOICE=""     # yes | no (empty → ask when interactive)
while [ $# -gt 0 ]; do
  case "$1" in
    --user)                SCOPE="user" ;;
    --local)               SCOPE="local" ;;
    --shared|--project)    SCOPE="project" ;;
    --scope)               shift; SCOPE="${1:-}" ;;
    --scope=*)             SCOPE="${1#*=}" ;;
    --repo|--marketplace)  shift; REPO_SRC="${1:-}" ;;
    --repo=*|--marketplace=*) REPO_SRC="${1#*=}" ;;
    --mcp)                 MCP_CHOICE="yes" ;;
    --no-mcp)              MCP_CHOICE="no" ;;
    -h|--help)
      grep -E '^#( |$)' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) warn "ignoring unknown argument: $1" ;;
  esac
  shift || true
done

# --- prerequisite: the claude CLI ------------------------------------------
sect "claude-boilerplate plugin install"

if ! command -v claude >/dev/null 2>&1; then
  warn "'claude' CLI not found — cannot install automatically."
  info "Install Claude Code, then run these in a Claude Code session:"
  info "  Global (user):   /plugin marketplace add ${SCRIPT_DIR}"
  info "                   /plugin install ${PLUGIN}@${MARKETPLACE_NAME}"
  info "  Shared (commit): /plugin marketplace add <owner/repo>"
  info "                   /plugin install ${PLUGIN}@${MARKETPLACE_NAME}   (then commit .claude/settings.json)"
  exit 0
fi

# --- choose scope (prompt only when interactive) ---------------------------
if [ -z "$SCOPE" ]; then
  if [ -t 0 ] && [ -t 1 ]; then
    echo "Choose install scope:"
    echo "  1) user     — global, all your projects (~/.claude/settings.json)"
    echo "  2) project  — just this project"
    printf "Enter 1 or 2: "
    read -r choice
    case "$choice" in
      1) SCOPE="user" ;;
      2)
        echo
        echo "Project install — keep it private or share with the team?"
        echo "  a) local-only — .claude/settings.local.json (gitignored, NOT committed)"
        echo "  b) shared     — .claude/settings.json (committed; teammates get it on clone + trust)"
        printf "Enter a or b: "
        read -r sub
        case "$sub" in
          a) SCOPE="local" ;;
          b) SCOPE="project" ;;
          *) warn "invalid choice; aborting without changes."; exit 0 ;;
        esac ;;
      *) warn "invalid choice; aborting without changes."; exit 0 ;;
    esac
  else
    warn "no scope given and not an interactive terminal."
    info "Re-run with a scope flag:  --user  |  --local  |  --shared [--repo owner/repo]"
    exit 0
  fi
fi

case "$SCOPE" in
  user|local|project) ;;
  *) warn "invalid scope '${SCOPE}' (expected user, local, or project); aborting."; exit 0 ;;
esac

# --- resolve the marketplace source ----------------------------------------
# user/local: the local clone path is fine (personal, machine-local enable-reference).
# project (shared): the source is committed, so it must resolve for teammates — a GitHub
# owner/repo (or git URL), NOT a local path.
SRC="$SCRIPT_DIR"

derive_owner_repo() {
  # Echo "owner/repo" parsed from a GitHub remote URL, or nothing.
  local url slug
  url="$(git -C "$PWD" remote get-url origin 2>/dev/null)" || return 0
  case "$url" in
    git@github.com:*)        slug="${url#git@github.com:}" ;;
    https://github.com/*)    slug="${url#https://github.com/}" ;;
    ssh://git@github.com/*)  slug="${url#ssh://git@github.com/}" ;;
    *) return 0 ;;
  esac
  printf '%s' "${slug%.git}"
}

if [ "$SCOPE" = "project" ]; then
  if [ -n "$REPO_SRC" ]; then
    SRC="$REPO_SRC"
  else
    derived="$(derive_owner_repo)"
    if [ -n "$derived" ]; then
      SRC="$derived"
      info "using marketplace source from git remote: ${SRC}"
    elif [ -t 0 ] && [ -t 1 ]; then
      echo
      echo "A shared install commits the marketplace source so teammates can resolve it."
      printf "GitHub owner/repo for the marketplace (e.g. acme/claude-boilerplate-setup): "
      read -r SRC
      [ -n "$SRC" ] || { warn "no source given; aborting shared install."; exit 0; }
    else
      warn "shared install needs a resolvable source, but none was found."
      info "Re-run with:  --shared --repo owner/repo   (a published GitHub repo)."
      warn "aborting so an unresolvable local path is never committed."
      exit 0
    fi
  fi
fi

# --- register the marketplace (idempotent) ---------------------------------
sect "Registering marketplace"
if claude plugin marketplace add "$SRC" >/dev/null 2>&1; then
  info "marketplace '${MARKETPLACE_NAME}' registered from ${SRC}"
else
  info "marketplace already registered (or add declined) — continuing"
fi

# --- install at the chosen scope -------------------------------------------
sect "Installing plugin (scope: ${SCOPE})"
if claude plugin install "${PLUGIN}@${MARKETPLACE_NAME}" --scope "$SCOPE" >/dev/null 2>&1; then
  info "${PLUGIN} enabled at ${SCOPE} scope"
else
  warn "plugin install did not complete (may already be installed). Try manually:"
  info "    claude plugin install ${PLUGIN}@${MARKETPLACE_NAME} --scope ${SCOPE}"
fi

# --- per-scope follow-up ---------------------------------------------------
case "$SCOPE" in
  local)
    # Keep the enable-reference out of git.
    target_gitignore="${PWD}/.gitignore"
    line=".claude/settings.local.json"
    if [ -f "$target_gitignore" ] && grep -qxF "$line" "$target_gitignore" 2>/dev/null; then
      info ".gitignore already ignores ${line}"
    else
      printf '%s\n' "$line" >> "$target_gitignore" 2>/dev/null \
        && info "added '${line}' to ${target_gitignore} (kept out of git)" \
        || warn "could not update ${target_gitignore} — add '${line}' yourself so the install stays local."
    fi
    ;;
  project)
    # Committed/shared: leave settings.json tracked; instruct (never run git).
    info "Enabled in .claude/settings.json (marketplace: ${SRC})."
    info "Commit it to share with your team:"
    info "    git add .claude/settings.json && git commit -m 'Enable claude-boilerplate plugin'"
    info "(Teammates are offered the plugin on clone + trust. Plugin files stay in the cache — not vendored.)"
    ;;
esac

# --- optional: auth-gated MCP servers --------------------------------------
# Core servers (context7, playwright, shadcn) ship in the plugin's .mcp.json and load
# automatically — nothing to add here. Only the OPTIONAL auth servers are opt-in, added at
# the same scope as the plugin (user / local / project).
sect "Optional MCP servers (auth)"
info "Core servers (context7, playwright, shadcn) load automatically with the plugin."

if [ -z "$MCP_CHOICE" ]; then
  if [ -t 0 ] && [ -t 1 ]; then
    printf "Also add the optional auth servers (figma, sentry — OAuth on first use)? [y/N]: "
    read -r ans
    case "$ans" in [Yy]*) MCP_CHOICE="yes" ;; *) MCP_CHOICE="no" ;; esac
  else
    MCP_CHOICE="no"   # default off when non-interactive and no flag
  fi
fi

if [ "$MCP_CHOICE" = "yes" ]; then
  add_http_mcp() {  # name, url
    if claude mcp add -s "$SCOPE" -t http "$1" "$2" >/dev/null 2>&1; then
      info "added MCP server '${1}' (scope: ${SCOPE}; authenticates on first use)"
    else
      info "MCP server '${1}' already present or add declined — skipping"
    fi
  }
  add_http_mcp figma  https://mcp.figma.com/mcp
  add_http_mcp sentry https://mcp.sentry.dev/mcp
  info "github needs a PAT — add it yourself (never commit the token):"
  info "  claude mcp add -s ${SCOPE} -t http github https://api.githubcopilot.com/mcp/ \\"
  info "    --header \"Authorization: Bearer \$GITHUB_MCP_TOKEN\""
else
  info "skipped. Add optional servers later — see README '## MCP servers'."
fi

# --- done ------------------------------------------------------------------
sect "Done"
info "Restart Claude Code so the plugin loads."
info "Then scaffold project docs with:  /claude-boilerplate:setup"
info "(This installer never touches CLAUDE.md.)"
info "Optional companions (superpowers / ponytail / rtk):  bash \"${SCRIPT_DIR}/scripts/install-plugins.sh\""
exit 0
