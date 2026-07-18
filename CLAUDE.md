# CLAUDE.md

Canonical context file for this repository. `AGENTS.md` is a symlink to this file, so
every agent tool reads one source of truth.

## What this is

A Claude Code **plugin** (`claude-boilerplate`) that sets up Claude Code for a **new or
existing** project. It ships a reusable starting point — setup skills, a planning
workflow, a subagent squad, deterministic hooks, and MCP wiring — installed once and
enabled per scope, rather than vendored into each repo.

This repo is both the plugin source and its self-hosted marketplace. `README.md` is the
user-facing doc; this file is the canonical **developer** doc for working ON the plugin.

**Packaging.** Structure follows the Claude Code plugin layout: `.claude-plugin/plugin.json`
(manifest) + `.claude-plugin/marketplace.json` (self-hosted marketplace, `source: "./"`);
`skills/`, `agents/`, `commands/`, `hooks/hooks.json`, and `.mcp.json` (keyless core MCP
servers, auto-loaded) at the plugin root. Auth-gated MCP servers are opt-in (offered by
`install.sh`).
Install with `install.sh` (or `claude plugin install claude-boilerplate@claude-boilerplate-market
--scope user|local|project`); invoke skills as `/claude-boilerplate:<skill>`. Plugin files are
cached in `~/.claude/plugins/cache/`, never copied into the target project — at any scope only a
settings enable-reference is written. `install.sh` offers three outcomes: **user** (global
`~/.claude`), **project · local-only** (`--scope local` → gitignored `.claude/settings.local.json`,
nothing committed), and **project · shared** (`--scope project` → committed `.claude/settings.json`
so teammates get it on clone + trust). A shared install also commits the marketplace source, so
that source must be a published GitHub `owner/repo` (the installer derives it from `git remote` or
prompts) rather than a local path.

## Current state

- Repository initialized (git); packaged as the `claude-boilerplate` plugin.
- Skills live under `skills/` (router + existing + new + planning workflow + craft).
- Docs: `README.md` (users), this file + `AGENTS.md` symlink (canonical developer doc).
- No application source, config, or dependencies yet — added incrementally.

## Setup skills

The first capability of this boilerplate: run at a project's initial setup phase to
get `CLAUDE.md` / `AGENTS.md` and docs accurate and in sync with the code. Setup
scopes to docs + workflow wiring (hooks / MCP / plugins) — it does **not** create or
sync a project-memory store.

- `setting-up-claude-in-a-project` — router. Detects new vs existing, routes.
- `onboarding-existing-project` — reads docs + code, compares, proposes doc fixes
  (to `.claude/setup-analysis.md`) or creates them if none exist.
- `bootstrapping-new-project` — for a greenfield repo: brainstorms intent, persists it
  to a `docs/project-brief.md` project brief, then builds the initial `CLAUDE.md`/`AGENTS.md`
  from a spec/PRD/plan. **Setup only — it STOPS before any scaffolding or implementation**;
  building is handed off to `planning-work-in-phases`.

Grounded in Anthropic's official large-codebase best practices:
https://claude.com/blog/how-claude-code-works-in-large-codebases-best-practices-and-where-to-start

**Personal (user-global) scope** — separate from the project setup above:

- `personalizing-claude` — interviews the user and writes their **personal** global
  `~/.claude/CLAUDE.md` (identity, communication, coding conventions, git/security rules,
  Definition of Done, guardrails) — the guide Claude reads in *every* project. This is
  **user-global**, not a *project* store, so the "no project-memory store" line above still
  holds: `~/.claude/CLAUDE.md` (personal, all projects) is a different file from
  `<project>/CLAUDE.md` (shared, one repo). Never overwrites an existing personal file without
  confirming. Own slash command: `/personal-setup`. Carries `references/` (interview question
  bank + fill-in template).

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
  conventions, architecture, design patterns, security) — agent code review (`code-reviewer-agent`)
  then user review (or fully autonomous, user's choice). Three passes run in parallel: code review
  (dimensions 1–6), **security** as its own pass (`security-review` skill or `security-reviewer-agent`,
  a pentester/vuln finder — Critical blocks approval), and **functional QA** (`qa-tester`) — black-box
  API/UI/E2E testing of the running build against the spec's success criteria. On approval marks the
  plan `DONE` and stamps `progress.md` with a timestamp. Uses the official Claude `code-review` /
  `security-review` skills or `superpowers:requesting-code-review` when available, else the built-in
  reviewer agents.

On-ramps (investigation → diagnosis/assessment doc → planning workflow):

- `debugging-an-issue` — when the goal is a bug/incident/regression with no known root cause.
  Investigates via logs, traces, metrics, observability, affected code, and reproduction to find
  the **root cause**, then writes a committed diagnosis doc (root cause + resolution approach +
  regression-test plan) that feeds `planning-work-in-phases`. Delegates the root-cause method to
  `superpowers:systematic-debugging` when installed. Dispatchable as the `debugger-agent`.
- `finding-security-vulnerabilities` — when the goal is a security audit, or on request from
  phase 5's security pass (optional, user-approved). Runs SAST, dependency/SCA, secrets, config/IaC,
  manual review, taint analysis, and (authorized) dynamic checks to find and **confirm** real
  vulnerabilities, then writes a committed assessment doc (findings + severity + remediation +
  security-test plan) that feeds `planning-work-in-phases`. Delegates to the official Claude
  `security-review` skill when available.

Artifacts live under `docs/plan/` (`specs/`, `breakdown/`, `phases/<N-slug>/plan.md`, a committed
`phases/<N-slug>/progress.md` execution log written during phase 4, `contracts/<feature>.*` frozen
API-contract artifacts + `contracts/<feature>.status.md` cross-track resume ledgers,
`diagnostics/` diagnosis docs, and `security/` assessment docs) — same layout whether or not
`superpowers` is present.

Each planning/on-ramp skill carries a `references/` folder with fill-in **templates** for its
output doc (design, breakdown, plan, progress, diagnosis, assessment) and **reviewer/agent prompts**
where it dispatches a subagent — e.g. `brainstorming-a-goal/references/visual-companion.md` +
`design-doc-template.md`. The setup skills remain single-file.

## Subagents

Delegatable agents live under `agents/` (one `.md` each: frontmatter +
system prompt). Dispatch them with the Agent tool.

- `research-agent` — research specialist. Browses the web, runs searches, fetches
  and reads external sources, and pulls current library/framework docs via
  context7. Usable in every phase: brainstorming (prior art, options), planning
  (approach validation, version compatibility), debugging (known bugs, error
  strings, upstream issues), executing (exact syntax, migration steps). Read-only;
  returns a synthesized, source-cited answer. Follows the `researching-sources`
  skill for method, source-safety guardrails (prompt-injection defense, harmful/
  malicious source handling, secret protection), and stop/complete criteria.
- `explorer-agent` — read-only codebase explorer. Searches across many files to
  answer where/how/which questions — locate a definition, trace callers, map a
  feature's flow, survey a directory — and returns a compact answer with `file:line`
  references instead of full file dumps. Read-only; editing is the caller's job.
- `debugger-agent` — root-cause investigator. The dispatchable form of the
  `debugging-an-issue` on-ramp: finds the true cause of a bug/incident/test-failure/
  regression/perf issue across logs, traces, metrics, observability, affected code, git
  history, and a reproduction, confirms it with a failing repro, and writes a committed
  diagnosis doc that feeds `planning-work-in-phases`. Enforces the Iron Law (no fix without
  root cause first). Where `explorer-agent` maps **where** code is, `debugger-agent` finds
  **why** it breaks. Follows `debugging-an-issue`; writes only the diagnosis doc + repro
  test — never app source (the fix is planned/executed/reviewed downstream).

Phase-1 design squad (back the brainstorm → spec → plan → review skills):

- `brainstorm-agent` — divergent. Explores intent, generates and weighs 2–4 real
  options, recommends a direction with open questions. Follows `brainstorming-a-goal`.
  Hands the direction + questions back to the main thread, which runs the live
  Socratic dialogue and gets user approval; it does not fake the user's answers.
- `spec-author-agent` — convergent. Turns an approved direction into a rigorous,
  buildable design doc via `brainstorming-a-goal/references/design-doc-template.md`
  (scope, non-goals, measurable success criteria, interfaces, risks), grounded
  against the real repo. Writes `docs/plan/specs/…`; no code.
- `plan-writer-agent` — spec + breakdown → an implementation plan per phase via
  `planning-each-phase/references/plan-template.md` (TDD, bite-sized steps, explicit
  dependencies, no placeholders, per-step verification). Writes
  `docs/plan/phases/<N-slug>/plan.md`; no code.
- `design-reviewer-agent` — read-only phase-1 quality gate. Adversarially reviews a
  spec or plan via the `reviewing-specs-and-plans` skill and returns APPROVE/REVISE
  with ranked findings + spec↔plan traceability. Surfaces gaps; does not rewrite the
  artifact (distinct from `reviewing-phase-implementation`, which reviews built code).

Design specialists (read-only advisors consulted during spec authoring; each returns
a recommendation that `spec-author-agent` / the main thread folds into the design
doc — none write code):

- `architecture-agent` — system structure: component boundaries, data/control flow,
  state and truth, consistency/failure, scalability, tech choices. Follows
  `designing-architecture`.
- `database-designer-agent` — data model: entities, schema, keys/indexes,
  normalization, integrity, storage-engine choice, safe migration path — modeled to
  the access patterns. Follows `designing-a-database`.
- `api-designer-agent` — API contract: paradigm, operations, request/response schemas,
  error/status semantics, auth, versioning — as a reviewable schema sketch. Follows
  `designing-an-api`.
- `frontend-designer-agent` — UI: component tree, state model, data fetching with full
  async states, routing, design-system reuse, accessibility, responsive. Follows
  `designing-a-frontend`. Skip for backend-only work.

Phase-4 executors (write-capable — they produce code, run tests, keep `progress.md`
current. Each executes an approved plan's steps in its domain, test-driven, one step at
a time, following `executing-phase-plans` + `superpowers:test-driven-development` for
the loop and its domain craft skill for the quality bar. Tech stack comes from the
plan; context7 supplies per-stack docs):

- `backend-executor` — server code: services, endpoints, business logic, jobs. Follows
  `implementing-backend` (+ auth/i18n cross-cutting skills).
- `frontend-executor` — UI code: components, state, data fetching, all async states,
  a11y. Follows `implementing-frontend` (+ i18n, auth-gating).
- `database-executor` — migrations, schema, models, backfills, zero-downtime and
  reversible. Follows `implementing-database-changes`.
- `devops-executor` — CI/CD, IaC, containers, k8s, deploy; validate/dry-run before any
  apply. Follows `implementing-devops`.

Cross-cutting execution skills (no dedicated agent — the executor whose step touches the
concern follows them): `implementing-i18n` (externalize strings, ICU plurals,
locale-aware formatting, RTL, fallback); `implementing-auth-and-authorization` (strong
hashing, safe sessions/tokens, server-side deny-by-default enforcement, RBAC /
fine-grained authz, per-resource checks against IDOR, negative authz tests); and
`implementing-observability` (structured logging, distributed tracing, RED/USE metrics,
health checks, monitoring, SLO-based alerting); `implementing-documentation` (API docs
via OpenAPI/Swagger kept in sync with the code, plus README/CHANGELOG/ADR/runbook); and
`coordinating-api-contract` (the backend↔frontend contract discipline that lets the two
executors work in parallel — a standalone, frozen, versioned contract artifact under
`docs/plan/contracts/`, backend building to it as **provider** and frontend against a
contract-derived **mock** as **consumer**, a strict change protocol, and provider/consumer
conformance gates; the two tracks resume **across sessions** via a committed status ledger
(`docs/plan/contracts/<feature>.status.md`) + per-track `progress.md` sync fields, surfaced at
session start by `session-start-context.sh`).
Observability is also a first-class **design** concern (`designing-architecture`) and
**planning** concern (`plan-writer-agent`), and is checked at the spec/plan gate
(`reviewing-specs-and-plans`), so it's built in — not bolted on after an incident.
Documentation is likewise a **planning** concern (`plan-writer-agent`), checked at the
spec/plan gate (`reviewing-specs-and-plans`), continuing the `designing-an-api` contract
artifact into a living, served OpenAPI/Swagger spec at execution.

The **API contract is the spine that runs through every phase** so backend and frontend meet
in the middle without drift: `designing-an-api` authors the standalone artifact
(`docs/plan/contracts/<feature>.*`, from its `references/api-contract-template.md`), frozen at
the design gate; `breaking-down-into-phases` may split a **backend (provider) track** and a
**frontend (consumer) track** around it (the frozen contract is the clean interface that makes
them independently buildable — the one sanctioned layer-split); `planning-each-phase` has both
plans consume it (frontend plans the mock, both plan conformance tests);
`executing-phase-plans` runs the two tracks **concurrently in separate worktrees** (the one
sanctioned exception to one-implementer-at-a-time, which is otherwise per-worktree), with a
contract-change protocol if a shape must move; and `reviewing-phase-implementation` /
`qa-tester` / `testing-apis` gate **provider conformance + consumer parity + drift** on both
sides. `coordinating-api-contract` is the cross-cutting home of this discipline. Because a
parallel build spans **many sessions**, the state that must survive lives on disk, committed: the
**status ledger** (`docs/plan/contracts/<feature>.status.md`) records each track's worktree,
branch, synced contract version, and conformance, and a contract bump writes a `⚠ NEEDS-RESYNC`
marker for any track left behind — surfaced at session start by `session-start-context.sh`, so a
later session detects a stale paused track and re-syncs it before continuing.

Phase-5 review gate — three parallel passes that close the built code back onto phase 1 (spec)
and phase 3 (plan). Code review and security are read-only (return a verdict); QA is
write-capable but scoped to test files only. All follow `reviewing-phase-implementation` as the
orchestrating skill:

- `code-reviewer-agent` — reviews the built code (the phase diff) against the design doc, the
  plan, and project conventions across dimensions 1–6: correctness, code quality/style,
  spec/plan/acceptance-criteria compliance, conventions/standards, architecture/boundaries, and
  design patterns. Grades Critical/Important/Minor, returns APPROVE/REVISE with `file:line`
  fixes + spec↔code traceability. Read-only (may run lint/tests to verify; never edits).
  Follows `reviewing-phase-implementation`. Distinct from `design-reviewer-agent` (specs/plans).
- `security-reviewer-agent` — the dedicated **security pass** (pentester / vulnerability finder):
  diff-scoped OWASP-Top-10 + common-class review — injection, broken access control/IDOR, authn/
  session, secrets, deserialization, path traversal, SSRF, crypto, dependency/config risk. May
  run read-only SAST/SCA/secret scanners to confirm; rates by severity (**Critical blocks
  approval**); escalates to the full `finding-security-vulnerabilities` audit when the change
  warrants it. Read-only, no destructive/dynamic attacks, authorized-use only. Follows
  `finding-security-vulnerabilities`.
- `qa-tester` — the **functional-verification pass**: black-box tests the BUILT, running
  implementation against the spec's success criteria — API/contract testing (status/schema/error/
  auth/IDOR-negative vs the OpenAPI/Swagger doc, via curl or a runner), UI/UX testing, and
  end-to-end journeys (Playwright — all async states, accessibility, responsive/cross-browser).
  The reviewers read the code; `qa-tester` runs it. Writes a persisted, non-flaky regression
  suite + a QA report (pass/fail per criterion, defects with reproduction); reports bugs rather
  than fixing them. Follows `testing-apis` and `testing-ui-and-e2e`.

## Hooks

Event-triggered scripts under `hooks/` that make the setup **deterministic** and
**self-improving** — the three patterns from Anthropic's large-codebase best practices.
They are wired **plugin-natively** in `hooks/hooks.json` (commands referenced via
`${CLAUDE_PLUGIN_ROOT}`), so they activate whenever the plugin is enabled — in all the
user's projects for a `--scope user` install, or only the one project for `--scope local`.
No per-developer copy step.

- `session-start-context.sh` (**SessionStart**) — dynamic context load. Prints the branch,
  uncommitted-change count, any in-progress `docs/plan/**/progress.md`, plus API-contract state
  for parallel tracks — the frozen contract + current version, any `⚠ NEEDS-RESYNC` marker a
  contract bump left for a stale track, and the git worktrees when more than one — so each session
  (even a fresh one) resumes with the right footing. It only surfaces the marker the
  `coordinating-api-contract` change protocol wrote; the version logic stays in the skill.
- `post-tooluse-format.sh` (**PostToolUse** `Write|Edit|MultiEdit`) — deterministic
  formatting. Runs the project's own formatter (prettier / ruff / black / gofmt / rustfmt /
  rubocop / shfmt — detected, never installed) on just the edited file.
- `stop-doc-sync.sh` (**Stop**) — doc-sync reflection. If the session changed repo structure
  but not `CLAUDE.md`, emits a non-blocking reminder to sync the canonical doc while
  context is fresh (the keep-docs-synced convention, enforced).

**Contract (every hook):** no runtime dependencies, read-only except formatting the edited
file, and **always exit 0** — a hook must never break a session, and silently no-ops when a
project has no formatter configured. Setup skills tailor the format hook to the detected stack.

## MCP servers

The keyless **core** servers ship in the committed root **`.mcp.json`** and load automatically
whenever the plugin is enabled (at whatever scope). The **auth-gated** servers are **opt-in** —
`install.sh` offers to `claude mcp add … -s <scope>` them, or add them by hand; the full
catalogue with commands lives in `README.md` `## MCP servers`. Agents reference servers as
`mcp__<server>__<tool>` in their `tools:` lists and degrade gracefully when one isn't enabled.

**Core — bundled, zero-auth, keyless via `npx`** (in `.mcp.json`):

- **context7** — live library/framework/SDK docs. Used by every executor, designer,
  reviewer, researcher, and the debugger (`mcp__context7__resolve-library-id` /
  `mcp__context7__query-docs`). The rule "don't guess a dependency's behavior" runs on it.
- **playwright** — drives a real browser for `qa-tester` + `testing-ui-and-e2e` (user
  journeys, all async states, accessibility, cross-browser).
- **shadcn** — shadcn/ui component registry (search / view / add). `frontend-designer-agent`
  recommends real registry components; `frontend-executor` adds them (`mcp__shadcn__*`).

**Optional — opt-in, need auth** (added via `install.sh` or manually, not in `.mcp.json`):

- **figma** — remote HTTP, Figma OAuth + Dev seat. Design context for the frontend agents.
- **sentry** — remote HTTP, OAuth. Errors/traces/metrics for `debugging-an-issue` + `debugger-agent`.
- **github** — remote HTTP, PAT (`GITHUB_MCP_TOKEN`). PRs/issues/CI for planning + review.

Never commit real tokens — pass them via `claude mcp add --header`/`-e` or a gitignored `.env`.

## Plugins & external tooling

Two Claude Code **plugins** and one **CLI tool** the workflow can build on — all
**optional**. `claude-boilerplate`'s own skills work without them (they fall back to inline
behavior). `scripts/install-plugins.sh` installs the two plugins into your chosen Claude Code
scope and additionally sets up `rtk` (a CLI). The script is idempotent, prereq-checked, never
hard-fails a missing tool, and always exits 0.

- **superpowers** (`obra/superpowers-marketplace`) — the TDD / brainstorming / planning
  methodology the planning-workflow skills delegate to when installed: `superpowers:brainstorming`,
  `writing-plans`, `executing-plans`, `subagent-driven-development`, `test-driven-development`,
  `systematic-debugging`, `requesting-code-review`, `using-git-worktrees`. Installing it makes
  the "delegates to `superpowers:…` when installed" branches throughout the skills live.
- **ponytail** (`DietrichGebert/ponytail`) — a "laziness ladder" YAGNI ruleset injected each
  turn (don't build it → reuse → stdlib → native platform → existing dependency → one-liner →
  minimal code, while keeping validation/error-handling/security/a11y) plus review commands
  (`/ponytail`, `/ponytail-review`, `/ponytail-audit`, `/ponytail-debt`, `/ponytail-gain`).
- **rtk** (`rtk-ai/rtk`, "Rust Token Killer") — a local CLI that filters/compresses the output
  of 100+ dev commands before it hits the context window. Integrates as a **PreToolUse** hook
  that rewrites Bash commands (`git status` → `rtk git status`); the hook needs `jq` on `PATH`
  or it no-ops. Installed via `brew install rtk` or the official install script; the script
  wires the project hook with `rtk init --auto-patch` (add `-g` yourself for all repos). No
  auth; telemetry off by default. `rtk init` patches your Claude settings — if it lands in the
  committed `.claude/settings.json`, move the rtk hook block into `.claude/settings.local.json`
  (gitignored, machine-local) before committing.

Enable everything: `bash scripts/install-plugins.sh`, then restart Claude Code. Setup skills
wire this into both onboarding paths.

## Conventions

- **CLAUDE.md is canonical; AGENTS.md is a symlink to it** (`ln -s CLAUDE.md AGENTS.md`).
- Start minimal. Add files only when a concrete need appears.
- **Keep docs synced.** Any change to repo structure updates this file in the same
  change (AGENTS.md follows via the symlink).
- **Document reality**, not plans. Describe what exists.
- Reusable expertise → Skills, not CLAUDE.md.
- **Changelog.** Record notable changes in `CHANGELOG.md` (Keep a Changelog + SemVer) under
  `[Unreleased]`; cutting a release moves those entries to a version heading and bumps
  `.claude-plugin/plugin.json`.
- **Test coverage ≥95%.** Configure the target project's coverage tool (jest/vitest
  `coverageThreshold`, `pytest --cov-fail-under=95`, `go test -cover` gate, nyc, JaCoCo, SimpleCov —
  detected, not imposed) so **statements, branches, functions, and lines each fail below 95%**.
  **Per-file: hard ≥95%** for every file a change creates/touches. **Global: ratchet** — set at
  current coverage, only ever raised toward 95, never regressed; pre-existing legacy gaps are
  backlog with user sign-off (per "document reality"). Unit + integration coverage; E2E/black-box
  is a separate functional gate, not counted. Enforced across the lifecycle — spec Testing Strategy,
  plan step, execution done-gate, CI (devops), and the phase-5 review (a sub-95% changed file or a
  global regression blocks approval). This governs projects the workflow builds; the plugin repo
  itself ships docs/skills, no app code to cover.

## Working agreement (for any agent)

- Explore before editing; for existing projects, treat code as the source of truth.
- Propose doc changes for review rather than silently rewriting existing docs.
- Ask for clarification on unclear or missing context.

## Commands

None yet — no build/test/lint tooling is set up (this plugin ships docs/skills, no app code).
This section grows as tooling is added, layered per-subdirectory to avoid timeouts. Projects the
workflow builds expose a **coverage command** whose gate fails below 95% (see the coverage
convention above) — e.g. `npm test -- --coverage`, `pytest --cov --cov-fail-under=95`.

## Structure

```
.                                              # plugin root
├── .claude-plugin/
│   ├── plugin.json                           # plugin manifest (name: claude-boilerplate)
│   └── marketplace.json                      # self-hosted marketplace (claude-boilerplate-market, source "./")
├── README.md                                 # user-facing doc: install / setup / use / function reference
├── CHANGELOG.md                              # release history (Keep a Changelog + SemVer)
├── LICENSE                                   # MIT
├── CLAUDE.md                                 # canonical developer doc (this file)
├── AGENTS.md                                 # symlink → CLAUDE.md
├── .gitignore                                # ignores .claude/settings.local.json + .env* (secrets)
├── install.sh                                # installer: scope choice (user / project-local / shared) + optional-MCP prompt
├── .mcp.json                                 # keyless core MCP servers (auto-loaded): context7 + playwright + shadcn
├── scripts/
│   └── install-plugins.sh                    # optional companions: superpowers + ponytail plugins + rtk CLI/hook
├── commands/
│   ├── setup.md                              # /claude-boilerplate:setup → runs the setup router skill
│   └── personal-setup.md                     # /claude-boilerplate:personal-setup → runs personalizing-claude (user-global ~/.claude/CLAUDE.md)
├── hooks/                                    # plugin-native hooks (wired in hooks.json, active when enabled)
│   ├── hooks.json                            # hook wiring via ${CLAUDE_PLUGIN_ROOT}
│   ├── session-start-context.sh              # SessionStart: load branch/in-progress-plan + API-contract state (version, ⚠ NEEDS-RESYNC, worktrees)
│   ├── post-tooluse-format.sh                # PostToolUse: format the edited file with the project's formatter
│   └── stop-doc-sync.sh                      # Stop: remind to sync CLAUDE.md if structure changed
├── agents/                                   # subagents (one .md each, frontmatter + prompt)
│   ├── research-agent.md                     # web/docs research: browse, search, cite (any phase)
│   ├── explorer-agent.md                     # read-only codebase explorer: locate/trace/map, file:line refs
│   ├── debugger-agent.md                     # root-cause investigator: logs/traces/metrics/git/repro → diagnosis doc (writes doc+repro test only)
│   ├── brainstorm-agent.md                   # phase-1 divergent: options, trade-offs, recommended direction
│   ├── spec-author-agent.md                  # phase-1 convergent: direction → design doc (design-doc-template)
│   ├── plan-writer-agent.md                  # phase-1: spec+breakdown → implementation plan (plan-template)
│   ├── design-reviewer-agent.md              # phase-1 gate: adversarial spec/plan review → APPROVE/REVISE (read-only)
│   ├── architecture-agent.md                 # spec design specialist: system structure, boundaries, tech choices
│   ├── database-designer-agent.md            # spec design specialist: data model, schema, keys/indexes, migration
│   ├── api-designer-agent.md                 # spec design specialist: API contract, errors, auth, versioning
│   ├── frontend-designer-agent.md            # spec design specialist: component tree, state, async states, a11y
│   ├── backend-executor.md                   # phase-4 executor: server code (write-capable, TDD, per plan)
│   ├── frontend-executor.md                  # phase-4 executor: UI code (write-capable, TDD, per plan)
│   ├── database-executor.md                  # phase-4 executor: migrations/schema (write-capable, safe, per plan)
│   ├── devops-executor.md                    # phase-4 executor: infra/CI/CD (write-capable, validate-first, per plan)
│   ├── qa-tester.md                          # phase-5 QA: black-box test built app — API/UI/E2E (write test files only)
│   ├── code-reviewer-agent.md                # phase-5 gate: review built code vs design+plan (quality/arch/patterns/conventions) → APPROVE/REVISE (read-only)
│   └── security-reviewer-agent.md            # phase-5 gate: security/pentest review of built code (OWASP, scanners) → severity-rated findings (read-only)
└── skills/                                   # each skill = SKILL.md (+ references/ for planning skills)
    ├── setting-up-claude-in-a-project/       # setup router: new vs existing
    ├── onboarding-existing-project/      # existing-project workflow
    ├── bootstrapping-new-project/        # new-project workflow
    ├── personalizing-claude/             # personal (user-global) ~/.claude/CLAUDE.md via interview (references/: interview-questions, personal-claude-template)
    ├── planning-work-in-phases/          # planning router: brainstorm→breakdown→plan→execute→review
    ├── brainstorming-a-goal/             # planning phase 1: goal → design doc (references/: visual-companion, templates)
    ├── breaking-down-into-phases/        # planning phase 2: design → phases (references/: breakdown-template)
    ├── planning-each-phase/              # planning phase 3: one plan per phase (references/: plan-template, reviewer)
    ├── executing-phase-plans/            # planning phase 4: execute plans per phase (references/: progress-template)
    ├── reviewing-phase-implementation/   # planning phase 5: review build vs spec+plan (references/: code-reviewer)
    ├── debugging-an-issue/               # on-ramp: bug → root-cause diagnosis doc → planning (references/: diagnosis-template)
    ├── finding-security-vulnerabilities/ # on-ramp: audit → security assessment doc → planning (references/: assessment-template)
    ├── researching-sources/              # utility: web/docs research protocol + source-safety guardrails (research-agent follows it)
    ├── reviewing-specs-and-plans/        # phase-1 gate: adversarial spec/plan review rubric (design-reviewer-agent follows it)
    ├── designing-architecture/           # spec design rubric: system structure (architecture-agent follows it)
    ├── designing-a-database/             # spec design rubric: data model/schema (database-designer-agent follows it)
    ├── designing-an-api/                 # spec design rubric: API contract → standalone artifact (references/: api-contract-template; api-designer-agent follows it)
    ├── designing-a-frontend/             # spec design rubric: UI/component/state (frontend-designer-agent follows it)
    ├── implementing-backend/             # exec craft: server-side code (backend-executor follows it)
    ├── implementing-frontend/            # exec craft: UI code + async states + a11y (frontend-executor follows it)
    ├── implementing-database-changes/    # exec craft: migration safety, zero-downtime (database-executor follows it)
    ├── implementing-devops/              # exec craft: infra/CI/CD safety, validate-first (devops-executor follows it)
    ├── implementing-i18n/                # exec craft (cross-cutting): internationalization best practice
    ├── implementing-auth-and-authorization/ # exec craft (cross-cutting): authn + RBAC/fine-grained authz + secure coding
    ├── implementing-observability/      # exec craft (cross-cutting): logging, tracing, metrics, monitoring, alerting
    ├── implementing-documentation/      # exec craft (cross-cutting): API docs (OpenAPI/Swagger) + README/CHANGELOG/ADR/runbook
    ├── coordinating-api-contract/       # exec craft (cross-cutting): frozen contract spine → parallel backend(provider)+frontend(consumer/mock), change protocol, conformance gates, cross-session resume (references/: contract-status-template)
    ├── testing-apis/                     # phase-5 QA craft: black-box API/contract testing (qa-tester follows it)
    └── testing-ui-and-e2e/               # phase-5 QA craft: browser UI + E2E via Playwright (qa-tester follows it)
```
