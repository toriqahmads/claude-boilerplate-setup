#!/usr/bin/env bash
#
# install-plugins.sh — set up the boilerplate's Claude Code plugins + rtk tooling.
#
#   • superpowers (obra)        — TDD / brainstorming / planning methodology skills
#   • ponytail    (DietrichGebert) — "laziness ladder" YAGNI ruleset + review commands
#   • rtk         (rtk-ai)      — Rust token-optimizer CLI + Bash-rewrite hook
#
# These are OPTIONAL companions to the claude-boilerplate plugin — the boilerplate's
# own skills work without them (they fall back to inline behavior). This script installs
# the two plugins into your chosen Claude Code scope and additionally sets up rtk (a CLI).
#
# Contract: idempotent, safe to re-run, never hard-fails a missing prerequisite —
# it reports and moves on. Nothing is installed silently that you didn't ask for by
# running this script. Always exits 0.

set -u

# Freshly-installed CLIs (rtk) land in ~/.local/bin — make sure it's visible now.
export PATH="$HOME/.local/bin:$PATH"

info() { printf '  %s\n'   "$*"; }
warn() { printf '  ! %s\n' "$*" >&2; }
sect() { printf '\n== %s ==\n' "$*"; }

# ---------------------------------------------------------------------------
# 1. Claude Code plugins: superpowers + ponytail
# ---------------------------------------------------------------------------
sect "Claude Code plugins (superpowers, ponytail)"

if command -v claude >/dev/null 2>&1; then
  # Register marketplaces (no-op if already known), then install. Both are
  # idempotent; a re-run just reports "already installed".
  claude plugin marketplace add obra/superpowers-marketplace >/dev/null 2>&1 || true
  claude plugin marketplace add DietrichGebert/ponytail      >/dev/null 2>&1 || true

  if claude plugin install superpowers@superpowers-marketplace >/dev/null 2>&1; then
    info "superpowers installed"
  else
    warn "superpowers not installed via CLI (already present, or the CLI declined)"
  fi

  if claude plugin install ponytail@ponytail >/dev/null 2>&1; then
    info "ponytail installed"
  else
    warn "ponytail not installed via CLI (already present, or the CLI declined)"
  fi
else
  warn "'claude' CLI not found — install them by hand in a Claude Code session:"
  info "    /plugin marketplace add obra/superpowers-marketplace"
  info "    /plugin install superpowers@superpowers-marketplace"
  info "    /plugin marketplace add DietrichGebert/ponytail"
  info "    /plugin install ponytail@ponytail   (send as two separate prompts)"
fi

# ---------------------------------------------------------------------------
# 2. rtk — Rust token-optimizer CLI (installs binary, then wires the hook)
# ---------------------------------------------------------------------------
sect "rtk (token optimizer)"

if ! command -v rtk >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    info "installing rtk via Homebrew..."
    brew install rtk || warn "brew install rtk failed — install manually: https://github.com/rtk-ai/rtk"
  elif command -v curl >/dev/null 2>&1; then
    info "installing rtk via the official install script..."
    curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/master/install.sh | sh \
      || warn "rtk install script failed — install manually: https://github.com/rtk-ai/rtk"
  else
    warn "neither brew nor curl found — install rtk manually: https://github.com/rtk-ai/rtk"
  fi
fi

if command -v rtk >/dev/null 2>&1; then
  # The Bash-rewrite hook shells out to jq to read the tool call; without it the
  # hook silently no-ops. Warn, don't install (no silent system changes).
  command -v jq >/dev/null 2>&1 \
    || warn "'jq' not found — the rtk hook needs it on PATH or it will no-op. Install jq, then re-run 'rtk init'."

  # Project-scoped hook (per the setup choice). --auto-patch wires it without prompts.
  if rtk init --auto-patch >/dev/null 2>&1; then
    info "rtk hook wired into this project."
    info "Note: rtk patches your Claude settings. If it lands in a committed"
    info ".claude/settings.json, move the rtk hook block into .claude/settings.local.json"
    info "(gitignored) before committing — the hook is machine-local (needs rtk installed)."
  else
    warn "'rtk init' did not complete — run it yourself: rtk init --auto-patch (add -g for all repos)."
  fi
else
  warn "rtk not installed — skipping hook setup."
fi

sect "Done"
info "Restart Claude Code so the plugin and hook changes take effect."
exit 0
