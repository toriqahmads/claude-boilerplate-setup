---
name: coordinating-api-contract
description: >
  Use whenever a feature has a backend↔frontend (or service↔service) API seam and the two
  sides may be built by different implementers — especially in parallel. Encodes the
  contract-first discipline that lets backend and frontend work concurrently without drift:
  a single standalone, frozen, versioned contract artifact
  (`docs/plan/contracts/<feature>.<openapi.yaml|graphql|proto>`) authored and approved
  before either side starts, the backend building to it as the provider, the frontend
  building against a contract-derived mock as the consumer, a strict change protocol when
  the contract must move, and conformance gates that verify both sides against it.
  Cross-cutting — the api designer, both executors, the planner, and the review/QA passes
  all reference it. Triggers on "backend and frontend in parallel", "API contract",
  "mock the API", "contract-first", "keep frontend and backend in sync", "consumer-driven
  contract", "the frontend shouldn't wait for the backend".
---

# Coordinating the API contract

Cross-cutting discipline for the **backend↔frontend seam**. The API contract is the single
source of truth both sides build against, so they can be planned, built, and reviewed
**independently — including truly in parallel** — and still meet in the middle without drift.
Referenced by `designing-an-api`, `breaking-down-into-phases`, `planning-each-phase`,
`executing-phase-plans`, `implementing-backend`, `implementing-frontend`,
`testing-apis`, and `reviewing-phase-implementation`.

## Goal

Make the contract — not a running server and not the other team's progress — the thing each
side depends on. When the contract is frozen and both sides build to it, the backend
(provider) and the frontend (consumer) can proceed **concurrently in separate worktrees**,
never blocking each other, and integrate cleanly because both were verified against the same
artifact.

## When to use

Any feature with an API seam where the two sides may be built separately: a `frontend-executor`
consuming what a `backend-executor` produces, two services, or a public API with external
clients. Skip only when there is no cross-implementer seam (a pure-backend job with no UI, a
pure-frontend job with no new API). If in doubt, there is a seam — use it.

## The contract artifact

One standalone file, the source of truth for the whole lifecycle:

- **Path:** `docs/plan/contracts/<feature>.<openapi.yaml|graphql|proto>` — sibling to
  `docs/plan/specs/` and `docs/plan/breakdown/`. One artifact per feature/seam.
- **Format follows the paradigm** (from `designing-an-api`): **OpenAPI** (YAML/JSON) for REST,
  **GraphQL SDL** for GraphQL, **`.proto`** for gRPC. Stack-agnostic — pick what the repo
  already exposes.
- **It is the real thing, not a sketch.** Every in-scope operation with its request/response
  schema, the shared error envelope, status codes, and per-operation auth — complete enough
  to generate a mock and validate a response against. Authored from
  `designing-an-api/references/api-contract-template.md`.
- **Versioned.** A `version` (and a short changelog header) lives in the artifact. This is what
  makes a change detectable and a re-sync explicit.
- **Frozen once approved.** After the design gate, both sides treat it as **read-only truth**.
  Neither an executor nor a reviewer edits it silently — changing it runs the change protocol below.

## Durable state (survives across sessions)

Parallel tracks run in two worktrees over many sessions — context is lost, work pauses, a fresh
agent resumes. The state that must survive is **recorded on disk, committed**, never held only in
session memory:

- **The status ledger** — `docs/plan/contracts/<feature>.status.md`, from
  [references/contract-status-template.md](references/contract-status-template.md). The
  at-a-glance cross-track record: the contract's **current version** + frozen state; per track its
  **worktree path + branch**, the **synced-version** it last built against, conformance status, and
  a `⚠ NEEDS-RESYNC` line when it is behind. Committed; written continuously.
- **Per-track `progress.md`** — each track also stamps its
  `docs/plan/phases/<N-slug>/progress.md` header with `Contract: <path> @ <synced-version>` and
  `Sibling track: <the other worktree/branch>`, and its conformance in the phase result — so the
  generic `executing-phase-plans` resume finds the contract coupling too.
- **The artifact's own version header** is the source of truth for *current* version; a track's
  recorded synced-version is what it *last built against*. Behind ⇒ stale ⇒ re-sync.
- **Git durability** — worktrees and each track's branch persist on disk across sessions; the
  contract artifact and both ledgers are committed. Even if a worktree dir is pruned, the track's
  commits survive on its branch and the worktree is recreatable.

## Contract-first rule

The contract is **authored and approved before either side starts building.** Order within
the design phase: architecture and data model drafted → API contract authored (`designing-an-api`)
→ **frontend design consumes the contract** (`designing-a-frontend`) → both sides' plans written
against it. A frozen contract is the precondition for splitting into parallel tracks — no freeze,
no parallel.

## Parallel-work protocol

With the contract frozen, the two sides run as independent tracks:

- **Backend = provider.** Implements the endpoints to satisfy the contract exactly — the
  documented shapes, status codes, error envelope, and auth. Keeps the served OpenAPI/Swagger (or
  SDL/proto) in sync with the routes (`implementing-documentation`) so the served spec and the
  contract artifact agree. Writes **provider conformance tests**: real responses validate against
  the contract schema.
- **Frontend = consumer.** Never waits on a running backend. Builds against a
  **contract-derived mock** stood up from the artifact — e.g. Prism / an OpenAPI mock server, MSW
  handlers generated from the schema, or generated types/client — so every data-fetch, form, and
  async state is wired to the contract's real shapes. Writes **consumer conformance tests**: the
  mock/fixtures the UI assumes validate against the same contract schema.
- **Isolation.** The tracks share **only** the frozen contract artifact; they touch disjoint
  files and run in **separate git worktrees**, so concurrent execution does not conflict. This is
  the condition under which `executing-phase-plans` permits parallel implementers.
- **Integration.** When both tracks finish, swap the frontend's mock for the real provider and run
  the conformance gate (below). Because both were built to the same artifact, integration is
  wiring, not rework.

## Contract-change protocol (the strict part)

The contract is expensive to change once both sides depend on it — so a mid-flight change is
**explicit and synchronized, never a silent local divergence:**

1. **Stop** the affected track. A track that finds the contract wrong or insufficient does **not**
   work around it or invent fields — it surfaces the gap.
2. **Change the artifact**, not the code — edit `docs/plan/contracts/<feature>.*`, **bump the
   version**, and note the change in the changelog header. State the compatibility impact
   (breaking vs additive) per `designing-an-api`'s versioning rules.
3. **Record the bump durably.** Update the status ledger: new current version + changelog entry,
   and mark **every track whose synced-version is now behind** with a `⚠ NEEDS-RESYNC` line. This
   is what makes the staleness survive the session — a paused track's next session sees it (the
   `session-start-context.sh` hook surfaces the marker at start).
4. **Re-approve** — the change goes back through the design gate (the user, or the autonomous
   reviewer). A breaking change may require re-planning the affected phase.
5. **Re-sync both sides.** Regenerate mocks/types on the frontend; update provider handlers and
   provider tests on the backend. Both tracks pick up the new version, **clear their
   `⚠ NEEDS-RESYNC` marker and bump their synced-version in the ledger + `progress.md`**, before
   continuing.

Never let one side "just add a field" in code. The artifact moves first; the code follows.

## Conformance gates

Both sides are verified **against the contract**, both directions checked:

- **Provider conformance** — backend responses (status, schema, content-type, required fields,
  enums, error envelope) validate against the artifact. Tooling: `schemathesis` / `dredd` for
  contract fuzzing, or schema assertions in the repo's runner (`testing-apis`).
- **Consumer parity** — the shapes the frontend consumes (mock handlers, fixtures, generated
  types) validate against the same artifact, so the UI isn't built on assumptions the provider
  never promised.
- **Drift check** — the served/generated spec matches the committed artifact (a CI-style drift
  check, per `implementing-documentation`). Any mismatch — doc vs code, mock vs provider — is a
  **blocking defect** at the review/QA gate (`reviewing-phase-implementation`).

## Across the lifecycle

The same artifact, referenced at every phase:

- **Design** (`designing-an-api` / `api-designer-agent`) — authors the artifact; frozen at the gate.
- **Breakdown** (`breaking-down-into-phases`) — may split a backend (provider) track and a
  frontend (consumer) track, with the contract as the produced/consumed interface between them.
- **Plan** (`planning-each-phase` / `plan-writer-agent`) — both plans list the artifact in their
  *Consumes from earlier phases* block; the frontend plan includes standing up the mock; both
  include conformance-test steps.
- **Execute** (`executing-phase-plans` + the two executors) — parallel tracks in separate
  worktrees against the frozen contract; change protocol if it must move.
- **Review** (`reviewing-phase-implementation` / `qa-tester` / `testing-apis`) — provider
  conformance **and** consumer parity gated; drift is blocking.

## Across sessions / resume

A parallel build spans many sessions. When you (re)enter one — a fresh agent, a resumed
workflow, after compaction — **re-establish state from disk before touching either track:**

1. **Read the durable state.** Load the contract artifact's current version, the status ledger
   (`docs/plan/contracts/<feature>.status.md`), and each track's `progress.md`. Trust these over
   recollection.
2. **Discover the worktrees.** `git worktree list` — locate each track's worktree. If one was
   pruned, **recreate it from the track's branch** (recorded in the ledger); its commits are
   durable in git even when the dir is gone.
3. **Detect staleness.** For each track compare its **synced-version** against the artifact's
   **current version** (a `⚠ NEEDS-RESYNC` line in the ledger flags this — the session-start hook
   surfaces it). A track built against an older version — because the contract was bumped while it
   was paused — is **stale**.
4. **Re-sync before continuing a stale track.** Regenerate its mock/types (frontend) or update
   handlers + provider tests (backend) to the current version, re-run its conformance, then clear
   the `⚠ NEEDS-RESYNC` marker and bump its synced-version in the ledger + `progress.md`. Never
   resume building a stale track as if it were current.
5. **Resume execution.** Hand back to `executing-phase-plans` resume mode — skip completed tasks
   per each track's `progress.md`, continue the tracks (concurrently, or the sequential fallback),
   and keep the ledger + `progress.md` current as state changes.

## Guardrails

- **Contract first, frozen, versioned.** No parallel tracks before the artifact is approved and frozen.
- **State lives on disk, not in the session.** The status ledger + each `progress.md` are the
  durable memory — write them continuously so any later session resumes without replaying, and a
  contract bump's staleness is never lost.
- **The artifact moves first.** Any shape change edits `docs/plan/contracts/<feature>.*` and bumps
  the version before any code changes — run the change protocol, never a silent divergence.
- **Never invent fields.** Neither side assumes anything absent from the contract; a gap is surfaced, not filled.
- **Stack-agnostic.** OpenAPI / SDL / proto per the repo's paradigm; use context7 for the exact
  mock/codegen tool API.
- **Degrade gracefully.** No mock-server tool available → fall back to generated types + a
  hand-written stub validated against the schema. Still contract-bound, just lighter tooling.
- **Both directions verified.** Provider conformance and consumer parity — a green backend over a
  frontend built on wrong assumptions (or vice versa) is not done.

## When to stop / complete

Complete when the contract artifact exists, is versioned and frozen, both tracks built against
it (provider to it, consumer against its mock), provider conformance and consumer parity both
pass, and the drift check is clean. Stop and run the change protocol if either side needs the
contract to move. Hand back if there is no runnable way to verify conformance and the plan didn't
scope creating one.

## Output

The frozen, versioned contract artifact at `docs/plan/contracts/<feature>.*`; both sides built
and verified against it (provider conformance + consumer parity); any contract change recorded as
a version bump with its re-sync; and a clean drift check — a backend and frontend that were built
in parallel and meet in the middle without rework.
