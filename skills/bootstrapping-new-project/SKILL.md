---
name: bootstrapping-new-project
description: >
  Use when setting up Claude Code for a new/greenfield project that has no source code
  yet — only a spec, PRD, plan, brainstorm, or prompt. Also covers "start a new
  project", "initialize this repo", "set up Claude Code from scratch", "bootstrap this
  idea". Triggers on starting from a PRD/Jira/Linear ticket, a plan doc, or a blank
  repo, to brainstorm intent, write a docs/project-brief.md project brief, and create
  the initial CLAUDE.md/AGENTS.md. Setup only — it never scaffolds or implements source
  code; building happens later via planning-work-in-phases.
---

# Bootstrapping a New Project

## Overview

Stand up the initial `CLAUDE.md`/`AGENTS.md` for a project with no code yet, grounded
in whatever source of truth exists (spec/PRD/plan/brainstorm) — no codebase to analyze,
the intent docs and the user are the truth.

Reached from `setting-up-claude-in-a-project`. Official guidance:
https://claude.com/blog/how-claude-code-works-in-large-codebases-best-practices-and-where-to-start

**REQUIRED SUB-SKILL:** run `superpowers:brainstorming` before authoring docs — nail
intent and requirements first.

## Scope — setup only, STOP before building

**Core rule: setup ends at docs. It NEVER implements or scaffolds source code.** This
skill produces exactly three artifacts — `docs/project-brief.md`, the canonical
`CLAUDE.md`, and the `AGENTS.md` symlink (plus hooks/MCP/companion wiring). That's the
whole job.

Do **not** — even though greenfield makes it tempting to keep going after the
brainstorm — scaffold a source tree, create a manifest (`package.json`,
`pyproject.toml`, `go.mod`, `Cargo.toml`, …), create `src`/`app`/`lib`, install
dependencies, generate boilerplate, or write application code.

`superpowers:brainstorming` precedes *building* elsewhere; here it precedes only the
brief. When the brainstorm concludes, **write the brief, write `CLAUDE.md`, then
STOP.** Building is a **separate, later, user-initiated** step: the
`planning-work-in-phases` workflow (brainstorm → breakdown → plan → execute → review).
Setup seeds that workflow; it does not run it.

## Workflow

Do these in order; a todo per step.

1. **Explore + analyze the source of truth.** Read every intent artifact — brainstorm
   notes, spec, prompt, PRD (doc or Jira/Linear ticket), plan doc. Extract goal, scope,
   intended stack, constraints, milestones.
2. **Pull more context when detail is missing** — `WebSearch` for domain/approach,
   **context7 MCP** (`resolve-library-id` → `query-docs`) for any named
   library/framework/SDK. Don't guess library APIs.
3. **Ask for clarification BEFORE writing.** Unclear/missing context — target stack,
   non-negotiable constraints, what "done" means — ask the user; don't invent
   requirements.
4. **Persist the brainstorm to `docs/project-brief.md`** once
   `superpowers:brainstorming` concludes — the project-initiation doc a later build
   reads: goal, scope + non-goals, stack, constraints, milestones, open questions.
   **Never overwrite an existing** file — propose additions for the user to review
   instead (same discipline as `CLAUDE.md`).
5. **Confirm the brief + invite additions.** Show the draft, confirm accuracy, ask for
   corrections before finishing — it seeds building later, so get it right now.
6. **Create the docs — never overwrite an existing `CLAUDE.md`.** Absent → author it
   as canonical (see Setup quality bar), pointing to `docs/project-brief.md` as the
   source of truth, then symlink `AGENTS.md`: `ln -s CLAUDE.md AGENTS.md`. Exists (even
   in a "new" repo) → don't overwrite — propose additions to
   `.claude/setup-analysis.md`, or write a git-ignored `CLAUDE.local.md`, for review.
   Same for `AGENTS.md`: never clobber an existing file.
7. **Confirm hooks are active.** SessionStart context, PostToolUse format, Stop
   doc-sync activate automatically once `claude-boilerplate` is enabled — no copy step;
   the format hook auto-detects the project's formatter (prettier/ruff/gofmt/…) at
   runtime, so style is enforced from the first commit. See `CLAUDE.md` `## Hooks`.
8. **Confirm MCP servers.** Keyless `context7` + `playwright` + `shadcn` load
   automatically from `.mcp.json`. Offer the **optional** auth servers the project
   needs — `figma`, `sentry` once error tracking exists, `github` for PR/issue flow —
   via `install.sh` or `claude mcp add -s <scope> …`. See `CLAUDE.md`/`README.md`
   `## MCP servers`.
9. **Install the optional companions** — `bash scripts/install-plugins.sh` adds
   `superpowers` + `ponytail` plugins and the `rtk` CLI/hook (needs `jq`). Optional;
   skills work without them. See `CLAUDE.md` `## Plugins & external tooling`.
10. **STOP and hand off — do not build.** Setup is done: tell the user the repo is set
    up (brief + root `CLAUDE.md` + wiring), and that when ready to build they run
    `planning-work-in-phases` (or `superpowers`), reading `docs/project-brief.md` as
    its start. Note the build will **layer a `CLAUDE.md` + `AGENTS.md` symlink into
    each meaningful source directory as it scaffolds** (phase 4,
    `executing-phase-plans`) — the per-subtree docs this setup can't create yet. Don't
    begin implementation/scaffolding now — end here.

## Setup quality bar (from official guidance)

- CLAUDE.md = **pointers and critical gotchas only.** At this stage: the goal,
  intended architecture/stack, key conventions decided so far, and where the source of
  truth (PRD/plan) lives.
- Keep it honest — document decisions made, mark open questions as open. Don't
  document a structure that doesn't exist yet.
- **Reusable expertise → Skills, not CLAUDE.md.**
- **Layered per-subdir CLAUDE.md come later, at scaffold time — not here.** No source
  directories exist yet, so only the **root** `CLAUDE.md` (+ `AGENTS.md` symlink) is
  created now. When the build scaffolds the source tree (phase 4,
  `executing-phase-plans`), **each meaningful source directory** gets its own light
  `CLAUDE.md` + `AGENTS.md` symlink, root kept in sync — via
  `implementing-documentation`. Seed this expectation in the brief/handoff so the build
  honors it.

## Common Mistakes

- **Continuing past setup into scaffolding/implementation** — the single biggest one.
  Setup stops at the brief + `CLAUDE.md`; building is `planning-work-in-phases`, run
  later on the user's explicit say-so.
- Writing CLAUDE.md before intent is clear — brainstorm and ask first.
- Not saving the brainstorm — the brief (`docs/project-brief.md`) is a required
  output, not optional scratch.
- Guessing a library's API instead of using context7.
- Inventing requirements the PRD/user never stated.
- Creating `AGENTS.md` as a separate file instead of a symlink to `CLAUDE.md`.

## Output

Three artifacts, and nothing more:

- `docs/project-brief.md` — the persisted brainstorm/project-initiation doc (goal,
  scope, stack, constraints, milestones, open questions).
- `CLAUDE.md` (canonical) — pointers + gotchas, pointing to the brief as the source of
  truth.
- `AGENTS.md` — a symlink to `CLAUDE.md`.

**No source code, no scaffold, no manifest.** Built from intent — the code doesn't
exist yet, and this skill doesn't create it. Building is handed off to
`planning-work-in-phases`.
