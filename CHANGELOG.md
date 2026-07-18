# Changelog

All notable changes to the `claude-boilerplate` plugin are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html). Cutting a release moves the
`[Unreleased]` entries under a new version heading and bumps `.claude-plugin/plugin.json`.

## [Unreleased]

### Added

- **`personalizing-claude` skill** — interviews the user in rounds and writes their **personal,
  user-global** `~/.claude/CLAUDE.md` (identity, communication, coding conventions, git/security
  rules, Definition of Done, guardrails) — the guide Claude reads in *every* project. User-global
  scope, distinct from the project-scoped setup skills; never overwrites an existing personal file
  without confirming. Ships a `/personal-setup` command and `references/` (interview question bank
  + fill-in template).
- **`coordinating-api-contract` skill** — cross-cutting spine that lets the backend and frontend
  code implementors work **in parallel without drift**. The API contract becomes a standalone,
  frozen, versioned artifact at `docs/plan/contracts/<feature>.<openapi.yaml|graphql|proto>` that
  is the single source of truth across every lifecycle phase. Backend builds to it as **provider**;
  frontend builds against a contract-derived **mock** as **consumer** (never blocked on the
  backend). Includes a strict **contract-change protocol** (edit artifact → bump version →
  re-approve → re-sync both sides) and **conformance gates** (provider conformance + consumer
  parity + drift).
- **API-contract template** — `designing-an-api/references/api-contract-template.md` (OpenAPI /
  GraphQL SDL / proto skeleton with a version + changelog header).
- **Contract status-ledger template** — `coordinating-api-contract/references/contract-status-template.md`
  for `docs/plan/contracts/<feature>.status.md`, the committed cross-track record (per track:
  worktree, branch, synced contract version, conformance) that lets a parallel build **resume
  across sessions**.
- **Parallel backend/frontend execution** — two contract-isolated tracks may run concurrently in
  separate git worktrees, bound only by the frozen contract.
- **Cross-session resume for parallel tracks** — the `SessionStart` hook now surfaces the frozen
  contract + current version, any `⚠ NEEDS-RESYNC` marker a contract bump left for a stale track,
  and the git worktrees when more than one is present.

### Changed

- **`designing-an-api`** / **`api-designer-agent`** — emit the standalone **frozen contract
  artifact** instead of a prose "sketch" buried in the design doc.
- **`breaking-down-into-phases`** — sanctioned exception to the no-layer-split rule: a backend
  (provider) track + frontend (consumer) track sharing a frozen contract is a valid,
  independently-buildable split.
- **`executing-phase-plans`** — added a parallel-tracks mode; the "one implementer at a time" rule
  is now scoped **per worktree** (contract-isolated tracks in separate worktrees are the sanctioned
  exception); added a contract-change stop condition, an integration/conformance gate, and
  parallel-track resume.
- **`planning-each-phase`** / **`plan-writer-agent`** — both sides' plans consume the frozen
  contract; the frontend plan stands up the mock; both include conformance-test steps.
- **`backend-executor`** builds as provider; **`frontend-executor`** builds as consumer against the
  contract mock — both follow the contract-change protocol.
- **`reviewing-phase-implementation`** / **`testing-apis`** / **`qa-tester`** — gate provider
  conformance **and** consumer parity **and** contract drift; a mismatch is a blocking finding.
- **`implementing-backend`** / **`implementing-frontend`** — "match the API contract" now resolves
  to the real frozen artifact + mock.
- **`progress.md` template** — carries the per-track contract path, synced version, sibling track,
  and conformance status.
- **Test-coverage gate (≥95%)** — a coverage bar enforced across every lifecycle phase: the spec's
  Testing Strategy names it, the plan configures the coverage tool's thresholds, execution blocks a
  step until every changed file is ≥95% (statements/branches/functions/lines) with the global total
  not regressed, devops wires the gate into CI, and the phase-5 review makes a sub-95% changed file
  or a global regression a blocking finding. Per-file is a hard floor; the global threshold ratchets
  upward on legacy repos and never regresses. Applies to backend, frontend, and database executors.

## [0.1.0] - 2026-07-18

Initial release — the `claude-boilerplate` plugin: a reusable starting point that sets up Claude
Code for a new or existing project, installed once and enabled per scope.

### Added

- **Setup skills** — `setting-up-claude-in-a-project` router + `onboarding-existing-project` and
  `bootstrapping-new-project`, grounded in Anthropic's large-codebase best practices.
- **Planning workflow** — `planning-work-in-phases` router + the five phase skills (brainstorm →
  breakdown → plan → execute → review), plus the `debugging-an-issue` and
  `finding-security-vulnerabilities` on-ramps.
- **Subagent squad** — research, explorer, and debugger agents; the phase-1 design squad
  (brainstorm / spec-author / plan-writer / design-reviewer) and design specialists (architecture,
  database, API, frontend); the phase-4 executors (backend, frontend, database, devops); and the
  phase-5 review gate (code-reviewer, security-reviewer, qa-tester).
- **Design, implementation-craft, testing, and research skills** — the rubrics and craft skills the
  agents follow, including the cross-cutting concerns (i18n, auth/authorization, observability,
  documentation).
- **Deterministic hooks** — `session-start-context.sh` (SessionStart), `post-tooluse-format.sh`
  (PostToolUse formatting), `stop-doc-sync.sh` (Stop doc-sync reminder).
- **Keyless core MCP servers** — context7, playwright, shadcn (auto-loaded); optional auth-gated
  servers (figma, sentry, github) offered by the installer.
- **Optional companion-tools installer** — superpowers + ponytail plugins and the rtk CLI/hook.
- **Plugin packaging** — `.claude-plugin/plugin.json` manifest + self-hosted marketplace,
  installable via `install.sh` at user / project-local / project-shared scope.

[Unreleased]: https://github.com/toriqahmads/claude-boilerplate-setup/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/toriqahmads/claude-boilerplate-setup/releases/tag/v0.1.0
