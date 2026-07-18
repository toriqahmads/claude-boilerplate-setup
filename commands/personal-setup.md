---
description: Set up your personal, global ~/.claude/CLAUDE.md via an interview. Never overwrites an existing one without confirming.
---

Set up (or update) your **personal global** guide at `~/.claude/CLAUDE.md` — the rules,
preferences, and style Claude Code reads in *every* project on your machine.

**Invoke the `personalizing-claude` skill** and follow it exactly. It interviews you in rounds
(identity, communication, coding conventions, git, security, workflow, Definition of Done,
guardrails, docs) and writes the file from your answers.

This is **user-global** scope — distinct from `/setup` (`setting-up-claude-in-a-project`), which
writes a *project's* `CLAUDE.md`. Two different files: `~/.claude/CLAUDE.md` (personal, all
projects) vs `<project>/CLAUDE.md` (shared, one repo).

**Hard invariant — never overwrite an existing `~/.claude/CLAUDE.md`.** If one already exists,
treat this as an update: propose the diff/merge and confirm before writing; create outright only
when absent.

$ARGUMENTS
