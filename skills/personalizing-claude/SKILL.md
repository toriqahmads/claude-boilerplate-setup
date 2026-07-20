---
name: personalizing-claude
description: >
  Use when setting up or updating the user's PERSONAL, global guide at ~/.claude/CLAUDE.md —
  their cross-project identity, communication style, coding conventions, git/security rules, and
  guardrails, applied in every repo on their machine. Triggers on "set up my personal CLAUDE.md",
  "personal rules/guide", "global Claude config", "how I want Claude to work with me",
  "personalize claude", "configure my preferences", "my coding style across projects",
  "/personal-setup", or a direct mention of ~/.claude/CLAUDE.md. Not for a project's
  CLAUDE.md/AGENTS.md (use setting-up-claude-in-a-project).
---

# Personalizing Claude

## Overview

One job: interview the user, then write their personal global `~/.claude/CLAUDE.md` — the guide
Claude Code reads in every project (identity, communication style, coding conventions,
git/security rules, Definition of Done, guardrails). Build it from their answers only, never
assumptions.

**User-global scope**, distinct from `setting-up-claude-in-a-project` (repo-scoped).
`~/.claude/CLAUDE.md` (all projects) vs `<project>/CLAUDE.md` (one repo) — this skill touches
only the personal one, never a project-memory store.

## When to Use

"Set up my personal CLAUDE.md" / "my personal rules" / "global Claude config"; applying
preferences across all projects; updating an existing personal file. Not a project's
`CLAUDE.md`/`AGENTS.md` (use `setting-up-claude-in-a-project`).

## Workflow

Todo per step, in order.

1. **Check for an existing file.** Read `~/.claude/CLAUDE.md` — present → this is an *update*:
   preserve what's there, add only what the interview surfaces.
2. **Interview in rounds.** `AskUserQuestion`, batched by theme, per
   `references/interview-questions.md`. Real options plus "Other"; ask free-text items (name,
   timezone, git identity) explicitly. **Never invent an answer.**
3. **Confirm ambiguities before writing.** Unclear/missing → ask; never guess or default.
4. **Write from the template — never overwrite blindly.** Fill
   `references/personal-claude-template.md`, write `~/.claude/CLAUDE.md`.
   - Absent → create directly.
   - Exists → show the diff/merge and confirm, don't clobber.
   Keep it comprehensive but minimal.
5. **Offer the `AGENTS.md` symlink** (optional): `ln -s CLAUDE.md ~/.claude/AGENTS.md`.
6. **Verify.** `cat ~/.claude/CLAUDE.md`; note it loads every session; suggest a fresh-session
   check: "what are my personal rules?".

## Common Mistakes

- Inventing answers instead of asking.
- Overwriting instead of merging + confirming.
- Project-specific rules in the global file (belongs in a project `CLAUDE.md`).
- A wall of text — keep it scannable.
- Confusing this with project setup or a project-memory store.

## Output

A personal `~/.claude/CLAUDE.md` from the user's answers (+ optional `AGENTS.md` symlink).
</content>
