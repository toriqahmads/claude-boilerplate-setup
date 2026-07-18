---
name: personalizing-claude
description: Use when setting up or updating the user's PERSONAL, global guide at ~/.claude/CLAUDE.md — their cross-project rules, preferences, and style. Triggers on "set up my personal CLAUDE.md", "personal rules/guide", "global Claude config", "how I want Claude to work with me", or ~/.claude/CLAUDE.md. Not for project docs.
---

# Personalizing Claude

## Overview

One job: **interview the user, then write their personal global `~/.claude/CLAUDE.md`** — the
standing guide Claude Code reads in *every* project on their machine (their identity, how they
communicate, coding conventions, git/security rules, Definition of Done, guardrails). Build it
from their answers, not assumptions.

This is **user-global** scope. It is distinct from `setting-up-claude-in-a-project`, which is
**repo-scoped** and writes a project's `CLAUDE.md`. Two different files, two different scopes —
`~/.claude/CLAUDE.md` (personal, all projects) vs `<project>/CLAUDE.md` (shared, one repo). This
skill only touches the personal one. It does **not** create a project-memory store.

## When to Use

- "Set up my personal CLAUDE.md" / "my personal rules" / "global Claude config".
- The user wants their preferences, conventions, or guardrails applied across all projects.
- Updating an existing `~/.claude/CLAUDE.md` with new rules.

Not for: a project's `CLAUDE.md`/`AGENTS.md` (use `setting-up-claude-in-a-project`).

## Workflow

Do these in order. Create a todo per step.

1. **Check for an existing personal file.** Read `~/.claude/CLAUDE.md` if present. If it exists,
   this is an *update* — preserve what's there and only add/change what the interview surfaces.
2. **Interview in rounds.** Use `AskUserQuestion`, batched by theme, following
   `references/interview-questions.md`. Give real options plus "Other" for free text. Ask the
   free-text items (name, timezone, git identity) explicitly. **Never invent an answer** — every
   line in the output must trace to something the user said.
3. **Confirm ambiguities before writing.** Anything unclear, missing, or ambiguous — ask. Do not
   guess intent or fill gaps with defaults the user didn't choose.
4. **Write the file from the template — never overwrite blindly.** Fill
   `references/personal-claude-template.md` with the answers and write `~/.claude/CLAUDE.md`.
   - **Absent** → create it directly.
   - **Exists** → do **not** clobber it. Show the proposed diff/merge and confirm before writing.
   Keep it a *tight guide* — comprehensive but minimal, not a wall of text.
5. **Offer the `AGENTS.md` symlink** (optional, ask first) so Codex/Gemini/other agent CLIs read
   the same guide: `ln -s CLAUDE.md ~/.claude/AGENTS.md`.
6. **Verify.** `cat ~/.claude/CLAUDE.md` to confirm content. Tell the user it loads into every
   session automatically; suggest a sanity check — start a fresh session and ask "what are my
   personal rules?".

## Common Mistakes

- Inventing answers instead of asking — every rule must come from the user.
- Overwriting an existing `~/.claude/CLAUDE.md` instead of merging + confirming.
- Putting **project-specific** rules in the global file (those belong in a project `CLAUDE.md`).
- Dumping a long wall of text — the personal guide is a scannable set of rules, kept minimal.
- Confusing this with project setup or a project-memory store.

## Output

A personal `~/.claude/CLAUDE.md` built from the user's answers (+ an optional `AGENTS.md` symlink
pointing to it).
