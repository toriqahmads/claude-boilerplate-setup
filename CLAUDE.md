# CLAUDE.md

Canonical context file for this repository. `AGENTS.md` is a symlink to this file, so
every agent tool reads one source of truth.

## What this is

Boilerplate to set up Claude Code for a **new or existing** project. It ships a
reusable starting point — setup skills, agent instructions, and conventions — that
you drop into a target repo to get Claude Code productive fast.

This repo is the source template, not an application. There is no runtime to build
or serve yet.

## Current state

- Repository initialized (git).
- Setup skills live under `.claude/skills/` (router + existing + new).
- Docs: this file (canonical) and `AGENTS.md` (symlink to it).
- No application source, config, or dependencies yet — added incrementally.

## Setup skills

The first capability of this boilerplate: run at a project's initial setup phase to
get `CLAUDE.md` / `AGENTS.md`, docs, and **project memory** accurate and in sync with
the code.

- `setting-up-claude-in-a-project` — router. Detects new vs existing, routes.
- `onboarding-existing-project` — reads docs + memory + code, compares, proposes doc
  and memory fixes (to `.claude/setup-analysis.md`) or creates them if none exist.
- `bootstrapping-new-project` — builds initial docs + seeds memory from a spec/PRD/plan
  for a greenfield repo.

Grounded in Anthropic's official large-codebase best practices:
https://claude.com/blog/how-claude-code-works-in-large-codebases-best-practices-and-where-to-start

## Planning workflow skills

Second capability: turn a goal (a prompt, docs, a Jira/Linear ticket, a PRD, or a bare
link) into an approved design, a phase breakdown, one implementation plan per phase, the
executed build, and a reviewed result. Router + five delegatable phase skills.

- `planning-work-in-phases` — router. Gathers the source of truth, checks for the
  `superpowers` plugin, routes brainstorm → breakdown → plan → execute → review with an
  approval gate between.
- `brainstorming-a-goal` — phase 1. Socratic dialogue → approved design doc (spec, not a
  plan). Delegates to `superpowers:brainstorming` if installed, else asks to install or
  brainstorms inline.
- `breaking-down-into-phases` — phase 2. Splits the design into N contextful phases →
  breakdown doc → self-review → user review.
- `planning-each-phase` — phase 3. One plan per phase. Delegates to `superpowers:writing-plans`
  if installed, else asks to install or writes plans inline.
- `executing-phase-plans` — phase 4. Executes the plans one per phase in dependency order;
  chooses worktree-or-not and subagent-driven-vs-inline; can run/resume a specific plan
  standalone; writes a committed `progress.md`. Delegates to
  `superpowers:subagent-driven-development` / `superpowers:executing-plans` if installed, else
  mirrors them inline.
- `reviewing-phase-implementation` — phase 5. Reviews each built phase against the spec + plan
  across seven dimensions (correctness, code quality, brainstorm+plan criteria, project
  conventions, architecture, design patterns, security) — agent code reviewer then user review
  (or fully autonomous, user's choice). Security runs as its own pass (`security-review` skill or
  a dedicated agent). On approval marks the plan `DONE` and stamps `progress.md` with a timestamp.
  Uses the official Claude `code-review` skill or `superpowers:requesting-code-review` when
  available, else a built-in reviewer.

On-ramps (investigation → diagnosis/assessment doc → planning workflow):

- `debugging-an-issue` — when the goal is a bug/incident/regression with no known root cause.
  Investigates via logs, traces, metrics, observability, affected code, and reproduction to find
  the **root cause**, then writes a committed diagnosis doc (root cause + resolution approach +
  regression-test plan) that feeds `planning-work-in-phases`. Delegates the root-cause method to
  `superpowers:systematic-debugging` when installed.
- `finding-security-vulnerabilities` — when the goal is a security audit, or on request from
  phase 5's security pass (optional, user-approved). Runs SAST, dependency/SCA, secrets, config/IaC,
  manual review, taint analysis, and (authorized) dynamic checks to find and **confirm** real
  vulnerabilities, then writes a committed assessment doc (findings + severity + remediation +
  security-test plan) that feeds `planning-work-in-phases`. Delegates to the official Claude
  `security-review` skill when available.

Artifacts live under `docs/plan/` (`specs/`, `breakdown/`, `phases/<N-slug>/plan.md`, a committed
`phases/<N-slug>/progress.md` execution log written during phase 4, `diagnostics/` diagnosis docs,
and `security/` assessment docs) — same layout whether or not `superpowers` is present.

Each planning/on-ramp skill carries a `references/` folder with fill-in **templates** for its
output doc (design, breakdown, plan, progress, diagnosis, assessment) and **reviewer/agent prompts**
where it dispatches a subagent — e.g. `brainstorming-a-goal/references/visual-companion.md` +
`design-doc-template.md`. The setup skills remain single-file.

## Conventions

- **CLAUDE.md is canonical; AGENTS.md is a symlink to it** (`ln -s CLAUDE.md AGENTS.md`).
- Start minimal. Add files only when a concrete need appears.
- **Keep docs synced.** Any change to repo structure updates this file in the same
  change (AGENTS.md follows via the symlink).
- **Document reality**, not plans. Describe what exists.
- Reusable expertise → Skills, not CLAUDE.md.

## Working agreement (for any agent)

- Explore before editing; for existing projects, treat code as the source of truth.
- Propose doc changes for review rather than silently rewriting existing docs.
- Ask for clarification on unclear or missing context.

## Commands

None yet — no build/test/lint tooling is set up. This section grows as tooling is
added, layered per-subdirectory to avoid timeouts.

## Structure

```
.
├── CLAUDE.md                 # canonical context (this file)
├── AGENTS.md                 # symlink → CLAUDE.md
└── .claude/
    └── skills/                               # each skill = SKILL.md (+ references/ for planning skills)
        ├── setting-up-claude-in-a-project/   # setup router: new vs existing
        ├── onboarding-existing-project/      # existing-project workflow
        ├── bootstrapping-new-project/        # new-project workflow
        ├── planning-work-in-phases/          # planning router: brainstorm→breakdown→plan→execute→review
        ├── brainstorming-a-goal/             # planning phase 1: goal → design doc (references/: visual-companion, templates)
        ├── breaking-down-into-phases/        # planning phase 2: design → phases (references/: breakdown-template)
        ├── planning-each-phase/              # planning phase 3: one plan per phase (references/: plan-template, reviewer)
        ├── executing-phase-plans/            # planning phase 4: execute plans per phase (references/: progress-template)
        ├── reviewing-phase-implementation/   # planning phase 5: review build vs spec+plan (references/: code-reviewer)
        ├── debugging-an-issue/               # on-ramp: bug → root-cause diagnosis doc → planning (references/: diagnosis-template)
        └── finding-security-vulnerabilities/ # on-ramp: audit → security assessment doc → planning (references/: assessment-template)
```
