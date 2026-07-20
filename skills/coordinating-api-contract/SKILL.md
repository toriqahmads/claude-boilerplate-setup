---
name: coordinating-api-contract
description: >
  Use when a feature has a backend↔frontend (or service↔service) API seam that may be built by
  different implementers — especially in parallel. Encodes the contract-first discipline that lets
  backend and frontend work concurrently without drift: a single standalone, frozen, versioned
  contract artifact (`docs/plan/contracts/<feature>.<openapi.yaml|graphql|proto>`) authored and
  approved before either side starts, the backend building to it as the provider, the frontend
  building against a contract-derived mock as the consumer, a strict change protocol when the
  contract must move, and conformance gates that verify both sides against it. Cross-cutting — the
  api designer, both executors, the planner, and the review/QA passes all reference it. Triggers on
  "backend and frontend in parallel", "API contract", "mock the API", "contract-first", "keep
  frontend and backend in sync", "consumer-driven contract", "the frontend shouldn't wait for the
  backend", "provider/consumer conformance testing", "OpenAPI contract", "schema drift", "API-first
  development", "split backend and frontend tracks".
---

# Coordinating the API contract

Cross-cutting discipline for the backend↔frontend seam: the API contract is the single source of
truth both sides build against, so they plan, build, and review independently — even in parallel —
and still meet without drift. Referenced by `designing-an-api`, `breaking-down-into-phases`,
`planning-each-phase`, `executing-phase-plans`, `implementing-backend`, `implementing-frontend`,
`testing-apis`, `reviewing-phase-implementation`.

## Goal

Make the contract — not a running server, not the other team's progress — what each side depends
on. Frozen and built-to, backend (provider) and frontend (consumer) proceed **concurrently in
separate worktrees**, never blocking, integrating cleanly because both were verified against the
same artifact.

## When to use

Any feature with an API seam that may be built separately: `frontend-executor` consuming
`backend-executor`'s output, two services, a public API with external clients. Skip only with no
cross-implementer seam (pure-backend, no UI; pure-frontend, no new API). If in doubt, use it.

## The contract artifact

One standalone file, source of truth for the whole lifecycle:

- **Path:** `docs/plan/contracts/<feature>.<openapi.yaml|graphql|proto>` — sibling to
  `docs/plan/specs/` and `docs/plan/breakdown/`. One per feature/seam.
- **Format follows the paradigm** (`designing-an-api`): OpenAPI (YAML/JSON) for REST, GraphQL SDL
  for GraphQL, `.proto` for gRPC. Stack-agnostic — whatever the repo already exposes.
- **The real thing, not a sketch.** Every in-scope operation's request/response schema, the shared
  error envelope, status codes, per-operation auth — complete enough to mock and validate a
  response against. Authored from `designing-an-api/references/api-contract-template.md`.
- **Versioned** — a `version` + changelog header, so a change is detectable and a re-sync explicit.
- **Frozen once approved.** Read-only truth after the design gate; a change runs the protocol below
  — never a silent edit.

## Durable state (survives across sessions)

Parallel tracks span many sessions in two worktrees — context is lost, work pauses, a fresh agent
resumes. State that must survive lives on disk, committed, never only in session memory:

- **Status ledger** — `docs/plan/contracts/<feature>.status.md`, from
  [references/contract-status-template.md](references/contract-status-template.md). Contract's
  current version + frozen state; per track its worktree/branch, last-synced version, conformance
  status, and a `⚠ NEEDS-RESYNC` line when behind. Committed; written continuously.
- **Per-track `progress.md`** — header stamped `Contract: <path> @ <synced-version>` and `Sibling
  track: <other worktree/branch>`, plus conformance in the phase result — so generic
  `executing-phase-plans` resume finds the coupling too.
- **Artifact's version header** = current version; a track's recorded synced-version = what it last
  built against. Behind ⇒ stale ⇒ re-sync.
- **Git durability** — worktrees and branches persist across sessions; artifact + ledgers are
  committed. A pruned worktree is recreatable from its branch; commits survive.

## Contract-first rule

Authored and approved **before either side starts building**. Order: architecture + data model →
API contract (`designing-an-api`) → frontend design consumes it (`designing-a-frontend`) → both
plans written against it. Frozen contract is the precondition for parallel tracks — no freeze, no
parallel.

## Parallel-work protocol

With the contract frozen, the two sides run as independent tracks:

- **Backend = provider.** Implements endpoints to the contract exactly — shapes, status codes,
  error envelope, auth. Keeps served OpenAPI/Swagger (or SDL/proto) in sync with routes
  (`implementing-documentation`). Writes **provider conformance tests**: real responses validate
  against the contract schema.
- **Frontend = consumer.** Never waits on a running backend. Builds against a **contract-derived
  mock** (Prism / an OpenAPI mock server, MSW handlers generated from the schema, generated
  types/client) so every fetch/form/async state matches real shapes. Writes **consumer conformance
  tests**: mock/fixtures validate against the same contract schema.
- **Isolation.** Tracks share only the frozen artifact; disjoint files, separate git worktrees — no
  conflict under concurrent execution. This is what lets `executing-phase-plans` permit parallel
  implementers.
- **Integration.** When both finish, swap the mock for the real provider and run the conformance
  gate below. Same artifact ⇒ integration is wiring, not rework.

## Contract-change protocol (the strict part)

Expensive to change mid-flight — always **explicit and synchronized, never a silent local
divergence**:

1. **Stop** the affected track. It surfaces the gap — never works around it or invents fields.
2. **Change the artifact, not the code** — edit `docs/plan/contracts/<feature>.*`, bump the
   version, note it in the changelog header. State compatibility impact (breaking vs additive) per
   `designing-an-api`'s versioning rules.
3. **Record the bump durably.** Update the status ledger: new version + changelog entry, flag every
   track now behind with `⚠ NEEDS-RESYNC` — this is what survives the session (`session-start-
   context.sh` surfaces it at start).
4. **Re-approve** — back through the design gate (user or autonomous reviewer). Breaking change may
   need re-planning the affected phase.
5. **Re-sync both sides.** Regenerate mocks/types (frontend); update handlers + tests (backend).
   Both pick up the new version, clear `⚠ NEEDS-RESYNC`, bump synced-version in ledger +
   `progress.md`.

Never let one side "just add a field" in code — the artifact moves first, the code follows.

## Conformance gates

Both sides verified against the contract, both directions:

- **Provider conformance** — backend responses (status, schema, content-type, required fields,
  enums, error envelope) validate against the artifact. Tooling: `schemathesis` / `dredd`, or
  schema assertions in the repo's runner (`testing-apis`).
- **Consumer parity** — what the frontend consumes (mock handlers, fixtures, generated types)
  validates against the same artifact — no UI built on assumptions the provider never promised.
- **Drift check** — served/generated spec matches the committed artifact (`implementing-
  documentation`). Any mismatch — doc vs code, mock vs provider — **blocks** the review/QA gate
  (`reviewing-phase-implementation`).

## Across the lifecycle

- **Design** (`designing-an-api` / `api-designer-agent`) — authors the artifact; frozen at the gate.
- **Breakdown** (`breaking-down-into-phases`) — may split a provider track and a consumer track
  around it.
- **Plan** (`planning-each-phase` / `plan-writer-agent`) — both plans list it under *Consumes from
  earlier phases*; frontend plan stands up the mock; both include conformance-test steps.
- **Execute** (`executing-phase-plans` + the two executors) — parallel worktrees against the
  frozen contract; change protocol if it must move.
- **Review** (`reviewing-phase-implementation` / `qa-tester` / `testing-apis`) — provider
  conformance and consumer parity gated; drift is blocking.

## Across sessions / resume

Re-entering a paused build — fresh agent, resumed workflow, after compaction — re-establish state
from disk first:

1. **Read durable state.** Contract's current version, the status ledger
   (`docs/plan/contracts/<feature>.status.md`), each track's `progress.md`. Trust these over
   recollection.
2. **Discover worktrees.** `git worktree list`; if one was pruned, recreate from its branch
   (recorded in the ledger) — commits are durable even when the dir is gone.
3. **Detect staleness.** Compare each track's synced-version to the artifact's current version
   (`⚠ NEEDS-RESYNC` flags it; session-start hook surfaces it). Built against an older version while
   paused ⇒ stale.
4. **Re-sync before continuing a stale track.** Regenerate mock/types (frontend) or update handlers
   + provider tests (backend), re-run conformance, clear `⚠ NEEDS-RESYNC`, bump synced-version in
   ledger + `progress.md`. Never resume a stale track as if current.
5. **Resume execution.** Hand back to `executing-phase-plans` resume mode — skip completed tasks
   per `progress.md`, continue the tracks (concurrently or sequential fallback), keep ledger +
   `progress.md` current.

## Guardrails

- **Contract first, frozen, versioned.** No parallel tracks before the artifact is approved and
  frozen.
- **State lives on disk, not in the session.** Status ledger + `progress.md` are the durable memory
  — write continuously; a bump's staleness must never be lost.
- **The artifact moves first.** Any shape change bumps the version before code changes — run the
  change protocol, never a silent divergence.
- **Never invent fields.** Neither side assumes anything absent from the contract; surface gaps,
  don't fill them.
- **Stack-agnostic.** OpenAPI / SDL / proto per the repo's paradigm; use context7 for the exact
  mock/codegen tool API.
- **Degrade gracefully.** No mock-server tool → generated types + a hand-written stub validated
  against the schema. Still contract-bound, just lighter tooling.
- **Both directions verified.** Provider conformance and consumer parity both required — a green
  backend over a frontend built on wrong assumptions (or vice versa) is not done.

## When to stop / complete

Complete when the artifact exists, is versioned and frozen, both tracks built against it (provider
to it, consumer against its mock), provider conformance and consumer parity both pass, and drift is
clean. Stop and run the change protocol if either side needs the contract to move. Hand back if
there's no runnable way to verify conformance and the plan didn't scope creating one.

## Output

The frozen, versioned contract artifact at `docs/plan/contracts/<feature>.*`; both sides built and
verified against it (provider conformance + consumer parity); any contract change recorded as a
version bump with its re-sync; a clean drift check — backend and frontend built in parallel meeting
in the middle without rework.
