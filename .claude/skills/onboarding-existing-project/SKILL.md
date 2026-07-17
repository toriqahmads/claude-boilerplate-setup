---
name: onboarding-existing-project
description: Use when setting up Claude Code in an existing project that already has source code, to check whether CLAUDE.md/AGENTS.md, related docs, and project memory match the real codebase and fix drift. Triggers on stale docs, stale memory, missing CLAUDE.md, missing memory, doc/code mismatch, docs lagging recent commits, onboarding an established repo.
---

# Onboarding an Existing Project

## Overview

Make `CLAUDE.md` / `AGENTS.md` (and related docs) **accurate and in sync with the
real code** before Claude Code starts working. Read the docs, read the code, compare,
then either propose fixes (docs exist) or create docs (none exist).

**Core rule: never silently rewrite existing docs.** If docs exist and drift from
code, you *propose* — you do not edit them directly.

Reached from `setting-up-claude-in-a-project`. Official guidance:
https://claude.com/blog/how-claude-code-works-in-large-codebases-best-practices-and-where-to-start

## Workflow

Do these in order. Create a todo per step.

1. **Read existing docs + memory.** Look for and read: `CLAUDE.md`, `AGENTS.md`,
   `context.md`, `architecture.md`, `CONTRIBUTING.md`, `docs/` (often a folder),
   progress/roadmap/CHANGELOG, `README`, and any **memory store** — `memory.md`,
   `MEMORY.md` (index), a `.claude/memory/` directory, or per-file memory notes. Note
   which exist. See "Memory sync" below for how memory is handled specifically.
2. **Analyze the docs.** Extract what they *claim*: architecture, stack, conventions,
   build/test/lint commands, entrypoints, gotchas.
3. **Explore the actual codebase + recent history.** Dispatch Explore subagents;
   traverse the tree, read key files, grep, follow references. Split exploration from
   editing — explore read-only here. Cover: directory layout, manifests/deps,
   entrypoints, build & test config, dominant patterns. Also read the **latest
   commits** — `git log --oneline -30`, `git log -p -10`, and `git diff` for anything
   uncommitted — to catch recent changes docs/memory may predate (renames, new
   modules, dropped flags, changed commands).
4. **Analyze the codebase.** Write down what is *actually* true: real structure,
   stack/versions, how to build/test/run, conventions in force. Treat **HEAD + recent
   commits as the current truth** — where docs/memory describe an older state, the
   commits win.
5. **Compare.** Diff step 1–2 (claimed — docs AND memory) against step 3–4 (actual
   code + latest commits). List every point of drift: wrong/outdated claims, missing
   commands, undocumented modules, dead references, **stale memory** (facts that no
   longer match the code — renamed files, removed flags, changed architecture), and
   anything **recent commits introduced or removed** that docs/memory don't reflect
   yet.
6. **Judge sync.** Decide per doc: in sync, or drifted.
7. **If drifted — ask how to deliver, then never silently rewrite.** When `CLAUDE.md`
   already exists and has drifted, **ask the user one question up front** and pick the
   delivery mode from their answer (see "Delivery mode" below):
   - **(A) Local override** — write the corrected/added context to `CLAUDE.local.md` at
     the repo root, plus one `CLAUDE.local.md` in **each subdirectory** that has its own
     conventions, and add `CLAUDE.local.md` to `.gitignore`. Gives the agent accurate
     context immediately, personal and uncommitted, without touching the shared
     committed `CLAUDE.md`.
   - **(B) Proposal doc** — write a **new** `.claude/setup-analysis.md` containing
     (a) drift findings, (b) proposed concrete changes per doc (show proposed text/diff).
     Edit nothing else; surface it and wait for approval before applying.
   Either way, **never edit the existing committed `CLAUDE.md` / `AGENTS.md` directly.**
8. **If docs are missing — create them.** Author `CLAUDE.md` as the canonical file
   (see Setup quality bar), then make `AGENTS.md` a symlink: `ln -s CLAUDE.md AGENTS.md`.
   Add per-subdirectory `CLAUDE.md` files where a module has its own conventions.
9. **Ask when unclear.** Any missing/ambiguous context (intended architecture, why a
   pattern exists, which command is canonical) → ask the user before guessing.

## Delivery mode (drifted existing docs)

Only when `CLAUDE.md` already exists and drifted (step 7). Ask **before** writing anything:

> "Docs exist and have drifted. Deliver the corrections as **(A)** local overrides —
> `CLAUDE.local.md` at the root and in each subdirectory with its own conventions, added
> to `.gitignore` (applied immediately, personal, uncommitted) — or **(B)** a proposal doc
> at `.claude/setup-analysis.md` for you to review before anything changes?"

- **(A) Local override** — `CLAUDE.local.md` is a Claude-read, git-ignored companion to
  `CLAUDE.md`; it layers on top without altering the committed file. Write root +
  per-subdir files, each holding only that scope's corrections/additions. Append
  `CLAUDE.local.md` to `.gitignore` (add it if missing; don't duplicate the line). Memory
  corrections ride along here too — put them in the relevant `CLAUDE.local.md` rather than
  editing committed memory files.
- **(B) Proposal doc** — the `.claude/setup-analysis.md` report; touch nothing else until
  approved.

Honor a standing user preference without re-asking. Missing docs (step 8) don't use this
gate — there's nothing committed to protect, so create directly.

## Memory sync

Project **memory** = durable facts about the project that are NOT derivable from the
code itself: decisions and their rationale, goals, constraints, non-obvious gotchas,
external references. Common forms: `memory.md`, a `MEMORY.md` index + `.claude/memory/`
files, or notes embedded in docs.

Handle memory as part of the workflow above, with the same propose-don't-overwrite rule:

- **Memory exists:** read it (step 1), compare each fact against the real codebase
  (step 5). For every fact:
  - Matches code → keep.
  - Contradicts code (renamed symbol, dropped flag, changed structure) → flag as
    **stale**; propose a corrected fact in `.claude/setup-analysis.md`.
  - Still true but no longer indexed / orphaned → propose a fix.
  Do NOT edit committed memory files directly — deliver per the chosen mode: mode A →
  into the relevant `CLAUDE.local.md`; mode B → into `.claude/setup-analysis.md`, applied
  on approval.
- **Memory missing:** learn the codebase (steps 3–4) and **create** the memory store.
  Capture only what the code can't tell you on its own (why-decisions, constraints,
  gotchas) — not restated code structure. Use a `MEMORY.md` index + one fact per file
  under `.claude/memory/`, or a single `memory.md` for a small project.

**Do not** put in memory: things the repo already records (code structure, git
history, what CLAUDE.md already states). Memory holds the non-obvious.

## Setup quality bar (from official guidance)

- CLAUDE.md = **pointers and critical gotchas only** — "everything else drifts into
  noise." High-level architecture, VCS details, key tooling at root.
- **Layer hierarchically:** root CLAUDE.md for the overview; per-subdir CLAUDE.md for
  local conventions, build/test/lint commands, and deps of that module.
- **Reusable expertise → Skills, not CLAUDE.md.**
- Add `.claudeignore` for generated/build/vendored files; version-control exclusions
  in `.claude/settings.json`.
- Per-subdir test/lint commands to avoid timeouts; add a lightweight codebase map if
  the tree doesn't communicate its own structure.

## Common Mistakes

- Editing an existing committed `CLAUDE.md` or memory file directly instead of a `CLAUDE.local.md` override (mode A) or `.claude/setup-analysis.md` proposal (mode B).
- Skipping the delivery-mode question and picking A or B yourself when docs drifted.
- Mode A but forgetting to add `CLAUDE.local.md` to `.gitignore` (leaks personal context into commits).
- Trusting the docs/memory over the code — code is the source of truth for drift.
- Syncing to an old snapshot — ignoring the latest commits / uncommitted diff.
- Dumping everything into CLAUDE.md instead of pointers + subdir layering.
- Putting code-derivable facts into memory — memory is for the non-obvious only.
- Skipping clarification and guessing intent.

## Output

- Docs/memory existed & drifted → **user-chosen delivery**: mode A → `CLAUDE.local.md` at
  root + per-subdir (added to `.gitignore`) carrying doc AND memory corrections; or mode B
  → `.claude/setup-analysis.md` proposal covering doc AND memory fixes. Committed docs
  untouched either way.
- Docs missing → new `CLAUDE.md` + `AGENTS.md` symlink (+ optional subdir CLAUDE.md).
- Memory missing → new memory store (`MEMORY.md` + `.claude/memory/`, or `memory.md`).
