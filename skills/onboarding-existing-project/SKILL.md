---
name: onboarding-existing-project
description: Use when setting up Claude Code in an existing project that already has source code, to check whether CLAUDE.md/AGENTS.md and related docs match the real codebase and fix drift. Triggers on stale docs, missing CLAUDE.md, doc/code mismatch, docs lagging recent commits, onboarding an established repo.
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

1. **Read existing docs.** Look for and read: `CLAUDE.md`, `AGENTS.md`,
   `context.md`, `architecture.md`, `CONTRIBUTING.md`, `docs/` (often a folder),
   progress/roadmap/CHANGELOG, `README`. Note which exist. (Setup does not create or
   sync a project-memory store — it scopes to docs.)
2. **Analyze the docs.** Extract what they *claim*: architecture, stack, conventions,
   build/test/lint commands, entrypoints, gotchas.
3. **Explore the actual codebase + recent history.** Dispatch Explore subagents;
   traverse the tree, read key files, grep, follow references. Split exploration from
   editing — explore read-only here. Cover: directory layout, manifests/deps,
   entrypoints, build & test config, dominant patterns. Also read the **latest
   commits** — `git log --oneline -30`, `git log -p -10`, and `git diff` for anything
   uncommitted — to catch recent changes the docs may predate (renames, new
   modules, dropped flags, changed commands).
4. **Analyze the codebase.** Write down what is *actually* true: real structure,
   stack/versions, how to build/test/run, conventions in force. Treat **HEAD + recent
   commits as the current truth** — where docs describe an older state, the
   commits win.
5. **Compare.** Diff step 1–2 (claimed by docs) against step 3–4 (actual
   code + latest commits). List every point of drift: wrong/outdated claims, missing
   commands, undocumented modules, dead references, and anything **recent commits
   introduced or removed** that the docs don't reflect yet.
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
10. **Confirm hooks are active.** The plugin's hooks (SessionStart context, PostToolUse
    format, Stop doc-sync) activate automatically once `claude-boilerplate` is enabled —
    no copy step. The format hook auto-detects the project's own formatter (prettier /
    ruff / black / gofmt / …) at runtime, so nothing to tailor. See `CLAUDE.md` `## Hooks`.
11. **Confirm MCP servers.** The keyless `context7` + `playwright` + `shadcn` load automatically
    from the plugin's `.mcp.json`. Offer to add the **optional** auth servers this repo would
    benefit from — `sentry` (its error tracker), `github`, `figma` — via `install.sh` or
    `claude mcp add -s <scope> …`. See `CLAUDE.md` / `README.md` `## MCP servers`.
12. **Offer to install the optional companions.** Run `bash scripts/install-plugins.sh` to add
    the `superpowers` + `ponytail` plugins and the `rtk` token-optimizer CLI/hook (needs `jq`).
    They are optional — the skills work without them. See `CLAUDE.md` `## Plugins & external tooling`.

## Delivery mode (drifted existing docs)

Only when `CLAUDE.md` already exists and drifted (step 7). Ask **before** writing anything:

> "Docs exist and have drifted. Deliver the corrections as **(A)** local overrides —
> `CLAUDE.local.md` at the root and in each subdirectory with its own conventions, added
> to `.gitignore` (applied immediately, personal, uncommitted) — or **(B)** a proposal doc
> at `.claude/setup-analysis.md` for you to review before anything changes?"

- **(A) Local override** — `CLAUDE.local.md` is a Claude-read, git-ignored companion to
  `CLAUDE.md`; it layers on top without altering the committed file. Write root +
  per-subdir files, each holding only that scope's corrections/additions. Append
  `CLAUDE.local.md` to `.gitignore` (add it if missing; don't duplicate the line).
- **(B) Proposal doc** — the `.claude/setup-analysis.md` report; touch nothing else until
  approved.

Honor a standing user preference without re-asking. Missing docs (step 8) don't use this
gate — there's nothing committed to protect, so create directly.

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

- Editing an existing committed `CLAUDE.md` directly instead of a `CLAUDE.local.md` override (mode A) or `.claude/setup-analysis.md` proposal (mode B).
- Skipping the delivery-mode question and picking A or B yourself when docs drifted.
- Mode A but forgetting to add `CLAUDE.local.md` to `.gitignore` (leaks personal context into commits).
- Trusting the docs over the code — code is the source of truth for drift.
- Syncing to an old snapshot — ignoring the latest commits / uncommitted diff.
- Dumping everything into CLAUDE.md instead of pointers + subdir layering.
- Skipping clarification and guessing intent.

## Output

- Docs existed & drifted → **user-chosen delivery**: mode A → `CLAUDE.local.md` at
  root + per-subdir (added to `.gitignore`) carrying doc corrections; or mode B
  → `.claude/setup-analysis.md` proposal covering doc fixes. Committed docs
  untouched either way.
- Docs missing → new `CLAUDE.md` + `AGENTS.md` symlink (+ optional subdir CLAUDE.md).
