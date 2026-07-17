---
name: bootstrapping-new-project
description: Use when setting up Claude Code for a new/greenfield project that has no source code yet — only a spec, PRD, plan, brainstorm, or prompt. Triggers on starting from a PRD/Jira/Linear ticket, a plan doc, or a blank repo, to create the initial CLAUDE.md/AGENTS.md and seed project memory.
---

# Bootstrapping a New Project

## Overview

Stand up the initial `CLAUDE.md` / `AGENTS.md` for a project that has no code yet,
grounded in whatever source of truth exists (spec / PRD / plan / brainstorm). There
is no codebase to analyze — the intent documents and the user are the truth.

Reached from `setting-up-claude-in-a-project`. Official guidance:
https://claude.com/blog/how-claude-code-works-in-large-codebases-best-practices-and-where-to-start

**REQUIRED SUB-SKILL:** run `superpowers:brainstorming` before authoring docs — nail
intent and requirements first.

## Workflow

Do these in order. Create a todo per step.

1. **Explore + analyze the source of truth.** Read every intent artifact available:
   brainstorm notes, spec, prompt, PRD (a document, or a Jira / Linear ticket), plan
   doc. Extract: goal, scope, intended stack, constraints, milestones.
2. **Pull more context when detail is missing.** Use available MCP/skills/plugins —
   `WebSearch` for domain/approach, **context7 MCP** (`resolve-library-id` then
   `query-docs`) for any named library/framework/SDK. Do not guess library APIs.
3. **Ask for clarification BEFORE writing.** Any unclear or missing context — target
   stack, non-negotiable constraints, what "done" means — ask the user. Do not invent
   requirements.
4. **Create the docs.** Author `CLAUDE.md` as the canonical file (see Setup quality
   bar), then make `AGENTS.md` a symlink: `ln -s CLAUDE.md AGENTS.md`.
5. **Seed the memory store.** There is no codebase yet, so memory comes from the
   intent artifacts and the brainstorm — capture durable, non-obvious facts: key
   decisions + rationale, hard constraints, goals/milestones, where the source of
   truth (PRD/plan) lives, open questions. Use a `MEMORY.md` index + one fact per
   file under `.claude/memory/`, or a single `memory.md` for a small project. Mark
   assumptions as assumptions. Do not record anything as settled that the user hasn't
   confirmed — this follows the initiation (brainstorm + ask first), same as the docs.

## Setup quality bar (from official guidance)

- CLAUDE.md = **pointers and critical gotchas only.** At this stage: the goal, the
  intended architecture/stack, key conventions decided so far, and where the source
  of truth (PRD/plan) lives.
- Keep it honest — document decisions made, mark open questions as open. Don't
  document a structure that doesn't exist yet.
- **Reusable expertise → Skills, not CLAUDE.md.**
- Plan to layer per-subdir CLAUDE.md files as the codebase grows.

## Common Mistakes

- Writing CLAUDE.md before intent is clear — brainstorm and ask first.
- Guessing a library's API instead of using context7.
- Inventing requirements the PRD/user never stated.
- Creating `AGENTS.md` as a separate file instead of a symlink to `CLAUDE.md`.

## Output

New `CLAUDE.md` (canonical) + `AGENTS.md` symlink pointing to it, plus a seeded
memory store (`MEMORY.md` + `.claude/memory/`, or `memory.md`) built from intent — not
code, which doesn't exist yet.
