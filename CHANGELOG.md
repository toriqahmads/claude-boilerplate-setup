# Changelog

All notable changes to the `claude-boilerplate` plugin are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html). Cutting a release moves the
`[Unreleased]` entries under a new version heading and bumps `.claude-plugin/plugin.json`.

## [Unreleased]

### Changed

- **All 18 subagents compacted (~1620 → ~1245 lines, ≈23%) — no behavior changed.** Each agent is the
  "short version" of a skill it follows, but the bodies had drifted into restating the skill's full
  method/guardrails/output. Cut that duplication down to a pointer, keeping only agent-unique content:
  identity, the `Follow the <skill>` delegation directive, dispatch context, read-only-vs-write scope,
  model/tier, MCP-tool guidance, and the output shape. `description:` frontmatter enriched with
  trigger-phrase synonyms so the dispatcher picks the right agent on more wordings; `name`/`tools`/
  `model`/`color` left byte-identical. Preserved every distinctive rule — debugger's Iron Law +
  diagnosis-doc-only scope, reviewers' dimensions/severity/verdict + read-only, security's
  Critical-blocks-approval, research's source-safety guardrails, executors' TDD + craft-skill links,
  backend-executor's derive/"signatures-frozen", and `frontend-designer-agent`'s design-system +
  production-ready UI/UX bar. Verified across all 18: valid YAML, frontmatter unchanged, skill
  delegations intact, no tool-syntax artifacts.
- **Planning now designs the whole UI stack for frontend features, not just the API — so a built
  frontend is production-ready with professional UI/UX.** A UI feature is no longer reduced to
  API-design-only. New **domain-in-scope rule** (`brainstorming-a-goal`, mirrored in `CLAUDE.md`):
  a design specialist is relevant when its domain is in the goal, and the tier scales its *depth*,
  not whether it runs — **frontend/UI in scope → `frontend-designer-agent` is required**, a data
  layer → `database-designer-agent`, a backend seam → `api-designer-agent`; a feature shipping UI on
  new data behind a seam designs **all four**. **Design-system + production-ready UI/UX folded into
  `designing-a-frontend`** as first-class mandatory dimensions: design tokens (color/type/spacing/
  radius/elevation/motion), a component system (reuse the repo's library / shadcn registry with
  variants + states, Figma-grounded when connected), UX quality (every state polished — skeleton/
  empty/error/success, purposeful reduced-motion-safe interaction, microcopy), visual hierarchy,
  WCAG-AA a11y, and responsive design of mobile *and* desktop. `frontend-designer-agent` recommends
  the coherent system; `implementing-frontend` gains a guardrail to **build to those tokens +
  component system** so the shipped UI is professional, not functional-but-rough. Backend-only work
  still skips the frontend design.

- **All 29 skills optimized for density + discoverability — no rule dropped.** Two goals: (1) tighten
  bodies so an invoked skill loads fewer tokens into the agent's context, and (2) enrich every
  `description:` frontmatter with **trigger synonyms / alternate phrasings** so a skill activates on
  more user wordings (e.g. `implementing-database-changes` now also matches "alter the table", "add a
  column", "write a Prisma/Alembic/Flyway migration", "zero-downtime schema change"). Every rule,
  guardrail, checklist item, cross-reference, `superpowers:` delegation + inline fallback, worked
  example, and measured benchmark number was **preserved verbatim in meaning** — this was a density
  and trigger-coverage edit, not a scope edit. Real body-word cuts landed **where the bloat actually
  was**: the few long procedural skills (`executing-phase-plans`, `reviewing-phase-implementation`,
  `coordinating-api-contract`, `planning-each-phase`) trimmed ~22–30%; the already-atomic design/craft
  rubrics were near-incompressible without cutting rules, so they trimmed 3–11% and mainly gained
  richer triggers. Verified across all 29: valid YAML frontmatter, every description leads with "Use
  when…", load-bearing rules present (signatures-frozen, two-sided boundary test, canonicity gate,
  tier throttle, ≥95% gate, REQUIRED SUB-SKILL directives, contract-change protocol), `references/`
  untouched.

### Reliability

- **Fixed the workflow's one benchmarked edge-case failure: an executor silently broke a frozen
  contract signature to fit validation.** In the ambiguous-variant benchmark
  (docs/workflow-rationale.md §11) one workflow executor changed `NewVault(...) *Vault` into
  `(*Vault, error)` so it could validate a constructor argument; its own 15 tests **adopted the new
  signature and passed**, so it self-reported green while the frozen-contract grader failed it to
  compile — the only defect in any arm, and it came from the *workflow* arm. **Root cause:** wanting
  to validate a constructor input, with no rule forbidding a signature change and a self-authored
  test suite that cannot detect one (the tests call the changed signature). **Fix, in three places:**
  `implementing-backend` gains a **"Signatures are frozen — conform, don't redesign"** guardrail
  (never change declared names/params/return-arity/types for validation or an edge; validate *within*
  the signature — panic on programmer misuse or a documented default — or STOP and flag a contract
  change) plus an input-validation split (untrusted *runtime* input is rejected where the contract
  returns an error; a *constructor precondition* is handled inside the no-error signature);
  `executing-phase-plans` gains a **signature-conformance self-check** before done (compile against
  the *declared* signature, not the shipped one — a green self-test suite is not proof of conformance)
  plus a Common Mistake. **Why it matters:** self-authored tests can't verify contract conformance —
  only an *independent* check (the phase-5 review / provider-conformance gate, or a caller compiled
  against the declared signature) catches this class; it is a concrete argument for the read/write
  separation (§5) and the review gate. This 2-stage benchmark arm had no review stage, which is
  exactly why the defect reached the grader.

- **Closed the one place the benchmark measured the workflow *failing*: a hard-reasoning boundary
  derivation on a weak model.** docs/workflow-rationale.md §11.1 measured that forcing a derivation
  gave **no gain on haiku** for a tricky rate-limiter window boundary — the model derives the exact
  `>=`-vs-`>` boundary wrong **~1 in 4** and ships it, because (a) the derivation ran on the same weak
  model and (b) the arm's own tests were one-sided happy-path, so a wrong boundary passed its own
  suite. Two safeguards now enforced across `implementing-backend`, `implementing-frontend`, and
  `executing-phase-plans`: **(1) derivation-model-escalation** — a non-canonical hard rule (bespoke
  boundary / formula / concurrency invariant / async race) is design-grade reasoning, so *that step*
  runs on the **strong model even inside otherwise-cheap execution** (model-tiering *inverts* for the
  derivation; inline on a weak model, dispatch a strong-model subagent); **(2) two-sided boundary
  test written first** — assert the last-accepted value (`n-1`) passes **and** the first-rejected
  (`n`) fails (frontend: the derived race discards the stale response **and** the fresh one wins), so
  a wrong derivation fails its own test instead of shipping. The two-sided test is exactly what the
  hidden grader used to catch these defects; the arms' one-sided tests did not. The mandatory
  derivation was necessary but not sufficient — escalation lowers the wrong-derivation rate at the
  source, the two-sided test catches what still slips. Quality bar unchanged (≥95% coverage,
  security-on-risk, E2E); this is a correctness-reliability fix, not a new gate.

### Performance

- **Small/Standard single-component execution is now one "derive-then-TDD" pass, not a spec→plan→
  execute→review fan-out — recovers the workflow's defect-catch at ~⅓ the tokens.** A benchmark
  (docs/workflow-rationale.md §11.2) showed the multi-agent chain's defect-catch on a single-component
  task came from **one** mechanism — deriving/enumerating the edge the one-shot missed — yet cost ~3.3×
  the tokens via separate agents each reloading context. Fix: `implementing-backend` gains a **Derive
  before you build** step (enumerate edge cases + derive any non-trivial rule — boundary/formula/
  concurrency invariant — with a **worked numeric example** before coding); `executing-phase-plans`
  makes Small/Standard inline execution a single derive-then-TDD pass and adds a Common Mistake against
  escalating a hard-reasoning small task to the full chain; `planning-work-in-phases` adds a
  **hard-reasoning signal** that makes the derivation mandatory **without** raising the tier. Measured
  (haiku): the derive-then-TDD single pass caught the same defects as the full chain (int64 overflow;
  a sliding-window `>=`-vs-`>` boundary bug) at **1.12× baseline vs 3.3×**. A plain edge *checklist*
  caught the simple edge but not the hard one — the **worked-example derivation** is the load-bearing
  part. Full multi-agent chain reserved for genuine coordination (Large / parallel contract tracks /
  cross-session), not defect-catch.
- **Wall-clock: independent tasks now fan out by dependency level instead of running serially.**
  `executing-phase-plans` gains a **Parallel execution** section — group a phase's tasks into
  dependency levels, dispatch the independent, disjoint-file tasks in a level **concurrently, one
  worktree each**, join before the next level. **Wall-clock per level = the slowest task, not the
  sum** (tokens unchanged — same work in parallel; this is the latency lever, as derive-then-TDD is
  the token lever). Generalizes the previously sole-sanctioned contract-track concurrency to any
  independent disjoint-file tasks; a genuine data/interface dependency still runs sequentially, and
  it's worth the worktree setup only for ≥2 non-trivial independent tasks. Delegates the fan-out to
  `superpowers:dispatching-parallel-agents` when present.
- **Tokens/wall-clock: the worked-example derivation is now gated on *non-canonicity*.** Benchmark G
  (concurrent singleflight coalescer, ambiguous prompt, haiku both arms) measured the derive-then-TDD
  arm at **1.5× tokens / 3.5× wall-clock for zero extra defects** — because singleflight is a
  *canonical* pattern the model one-shots correctly (both arms passed a hidden `-race` grader incl. an
  expiry stampede). `implementing-backend`, `executing-phase-plans`, and `planning-work-in-phases` now
  **always enumerate edge cases** (cheap; catches forgotten-edge bugs) but **spend the worked-example
  derivation only on non-canonical rules** — a named textbook pattern (singleflight, LRU/TTL, debounce,
  standard CRUD/pagination) reuses the known shape + edge tests, no re-derivation; a bespoke formula/
  boundary/concurrency-invariant still gets derived. Default when unsure: derive. Removes the canonical-
  case waste while preserving the non-canonical rescue (experiment F); coverage/security/E2E gates
  unchanged. **A canonical *shape* does not exempt a bespoke *sub-decision*** (error / expiry / eviction
  / tie-break semantics) — those are enumerated and decided deliberately even inside a canonical pattern
  (benchmark H surfaced a gated arm skipping the error-caching choice under a too-coarse "canonical"
  label). Direct A/B (benchmark H) also measured the gate capping an over-derivation tail — an
  unconditional arm spent **1.86× the tokens** re-deriving a textbook pattern the gated arm reused.
- **`implementing-frontend` gets the same enumerate → reuse → derive discipline, in UI terms.** New
  *Enumerate states, reuse shapes, derive only bespoke logic* section: always enumerate the state matrix
  (data async / permission / form / responsive / i18n-RTL) — cheap, catches the forgotten-state defect;
  reuse the canonical shape (design-system / shadcn registry / framework hook, ponytail rungs 2–4) for
  standard form/table/modal/data-fetch instead of hand-rolling; derive **only** bespoke interaction
  logic (optimistic-rollback, debounced-async race, custom state machine) on a concrete event sequence;
  and a canonical component doesn't exempt a bespoke sub-decision (empty-vs-error copy, focus-return).
  *Benchmark I (search controller — stale-response race + async states, haiku & sonnet) validated the
  **canonical** side: all arms one-shot the race + every state (it's a canonical last-write-wins
  pattern), and forcing the derivation cost 1.28× for zero defect gain — the frontend twin of G,
  exactly the over-derivation the canonicity rule prevents. The **rescue** side (a genuinely
  non-canonical frontend interaction, the analogue of F) remains unbenchmarked.*
- **Tokens: `planning-each-phase` now tiers the plan's granularity.** A **Small** phase executes as an
  inline derive-then-TDD pass, so the same context reads and executes the plan — pre-writing full
  per-task 5-step TDD blocks is boilerplate that executor already runs. Small plans are now
  **lightweight** (file map + interfaces + edge list + done-criteria: full suite + ≥95% coverage gate
  + E2E), with the full per-task blocks reserved for **Standard/Large**, where a *separate* executor/
  reviewer subagent consumes the plan across a context boundary and the detail earns its cost. Cuts
  plan-authoring tokens on the common single-phase case; no quality-bearing content
  (paths/interfaces/edges/gates/traceability) dropped.
- **Tier throttle now reaches the whole planning phase 1 — planning no longer pays large-feature
  cost on small work.** The complexity tier previously only gated 2 of 5 planning skills, so spec
  authoring dispatched up to **4 design specialists serially** (`architecture-agent` →
  `database-designer-agent` → `api-designer-agent` → `frontend-designer-agent`), each doing
  context7 + web lookups — ~15-20 min even for a Small feature. Now: **design specialists are
  tier-gated** (Trivial/Small → none, inline reasoning; Standard → only-relevant, in parallel;
  Large → architecture-first then db+api+frontend **in parallel**, not a serial chain —
  `brainstorming-a-goal`); and **`brainstorming-a-goal` and `reviewing-specs-and-plans` read the
  tier** (Small → ~1-3 questions / core review dimensions only). The speedup comes from **cutting
  and parallelizing dispatch**, not from downgrading models — planning/design agents stay on
  **`opus`** for quality; executors run on **`sonnet`**. Quality bar unchanged — ≥95% coverage,
  security on risk-flagged, E2E before done, spec↔code traceability hold at every tier.
- **Phase-5 review/QA loop no longer thrashes.** `reviewing-phase-implementation` now **re-reviews
  only the fix delta** (the first pass audits the full phase diff; later passes verify just the
  changed lines + no regression in touched files — not a full re-audit of already-passing code),
  **caps at 2 re-review rounds** then escalates a still-recurring review to the user instead of
  ping-ponging fixes, and **re-runs only the affected QA criteria** after a fix rather than the whole
  suite. Same rigor on what changed; stops re-proving what didn't. (Complements the existing
  execution-side throttle: focused tests in the loop, full suite + coverage once at the gate.)
- **Targeted re-test in the QA/testing layer.** `qa-tester`, `testing-apis`, and
  `testing-ui-and-e2e` now state the same rule the TDD loop already used: after a defect fix,
  re-run **only the failed test(s) + those hitting the changed surface** (scoped by the runner —
  `pytest -k`, `vitest run <path>`, `playwright test <file>/-g`), and run the **full suite exactly
  once at the end** for cross-test regression. E2E is called out as the most expensive to re-run and
  batches to the build's end for Small/Standard. Fixes the "re-tests the whole part after a little
  change" behavior — no coverage lost.

### Fixed

- **Duplicate hook registration on plugin install.** `plugin.json` declared
  `"hooks": "./hooks/hooks.json"` while Claude Code also auto-discovers that same file at the
  conventional `hooks/hooks.json` path — registering each hook twice. Removed the redundant manifest
  key; the hooks still load via the default-location convention.

### Added

- **Complexity tiers — the planning workflow's throttle.** `planning-work-in-phases` now
  classifies every goal into a tier (**Trivial / Small / Standard / Large**) with a **risk flag**
  (auth/crypto/payments/PII/uploads/external-input) at a new **Step 0.5**, recorded in the
  design-doc header and read by every phase to scale ceremony to the actual work — cutting a small
  feature (e.g. a quiz) from hours of large-feature overhead. The quality bar is untouched (≥95%
  coverage, security on risk-flagged changes, E2E before done, spec↔code traceability all hold at
  every tier). Interview/template gain a **Complexity tier + Risk-flagged + Approval mode** header.

### Changed

- **Ceremony now scales to the complexity tier** across the planning skills:
  - `breaking-down-into-phases` — **Small tier = exactly one phase** (no over-decomposition);
    Standard 2–3, Large N, split only on real boundaries.
  - `planning-each-phase` — Small plans in a single pass; Standard/Large plan one-at-a-time but
    without inter-phase approval pauses under a single-end-gate / autonomous run.
  - `executing-phase-plans` — execution mode is tier-driven (**Small = inline**, avoiding
    subagent-per-task cold-start; Large = subagent-driven), and **review cadence is per-phase for
    Small/Standard** (self-review + commit per task, full review once at phase end) vs per-task
    only for Large/high-risk. The coverage gate is verified before done at every tier.
  - `reviewing-phase-implementation` — the phase-5 gate scales: the **security pass runs only when
    risk-flagged** at Small/Standard (every phase for Large), and **E2E runs once at the build's
    end** for Small/Standard rather than per phase. Coverage gate + final review never skipped.
  - Approval gates are tier-gated: **single end gate** for Small/autonomous, milestone for
    Standard, per-phase for Large.

- **Execution speed — cut the dominant per-loop costs** in `executing-phase-plans`,
  `planning-each-phase`, and the plan template (execution was the 1–2h bottleneck):
  - **Focused tests in the TDD loop, full suite + coverage once at the phase gate.** Loop steps run
    only the test file/case under work (fail-fast); the whole suite and coverage run a single time
    at the gate. Plans/template now write focused step commands + one full-suite+coverage
    done-criteria block. Removes the repeated whole-suite sweep that dominated execution time.
  - **Model tiering enforced** — mechanical/boilerplate/test-scaffolding on the cheapest tier, top
    model only for design + final review; every dispatch names its model.
  - **Coarser task granularity for Small/Standard** — one meaningful testable deliverable per task,
    not one micro-action, cutting round-trip/test/commit overhead. Finer only for Large/high-risk.

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

- **Planning stops writing full code** — `planning-each-phase`, its `plan-template` /
  `plan-reviewer-prompt`, and `plan-writer-agent` now require each plan step to carry **exact
  signatures + test cases (behavior + expected I/O) + exact commands/output**, not full function or
  test **bodies**. Bodies are written at execution (phase 4), TDD. The "no placeholders" rule is
  reconciled: a concrete signature + case is required, not a placeholder; a pasted full body is the
  opposite failure. The `superpowers:writing-plans` delegation is instructed to defer bodies too.
- **Layered per-subtree `CLAUDE.md` at scaffold time** — `executing-phase-plans` now creates a
  light `CLAUDE.md` + `AGENTS.md` symlink in **each meaningful source directory** as a phase
  scaffolds/reshapes structure (root kept in sync), gated before the phase is done;
  `implementing-documentation` defines the doc-craft; `bootstrapping-new-project` (which stops
  before scaffolding, so only the root exists) seeds the expectation in its handoff.
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
