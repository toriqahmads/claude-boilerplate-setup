---
name: implementing-backend
description: >
  Use when implementing backend/server-side code from a plan — services, endpoints/
  handlers, business logic, integrations, background jobs — in whatever language and
  framework the plan specifies. Encodes production-grade craft: input validation,
  typed error handling, transactional integrity, idempotency, concurrency,
  observability, and test coverage, matching the repo's conventions. Delegates
  auth/authz to implementing-auth-and-authorization, user-facing text to
  implementing-i18n, and schema changes to implementing-database-changes. Followed by
  the backend-executor subagent. Triggers on "implement the endpoint/service",
  "build the backend for phase N", "write the handler/job".
---

# Implementing backend

Execution-time craft for server-side code. Followed by the `backend-executor`
subagent. Runs ON TOP of the execution method — **follow `executing-phase-plans` and
`superpowers:test-driven-development`** for the loop (one step at a time, test first,
verify, update `progress.md`). This skill is the backend quality bar layered over it.

## Goal

Turn a plan's backend steps into **production-grade code that a senior engineer would
approve** — correct, safe under failure and concurrency, observable, tested, and
indistinguishable in style from the surrounding codebase. Implement exactly what the
plan specifies; surface deviations, don't silently expand.

## Stack

The plan dictates language, framework, and libraries. Read the repo to match its
version and idioms; use context7 for the exact framework/library API. Do not import a
new dependency the plan didn't sanction without flagging it.

## Craft checklist (per step)

1. **Test first.** Write the failing test (unit + integration for I/O boundaries)
   before the implementation, per TDD. Cover the failure paths, not just happy path.
2. **Input validation.** Validate and normalize every external input at the boundary;
   reject invalid early with a clear error. Never trust client data.
3. **Error handling.** Typed/structured errors; map to the right status/response; no
   leaking stack traces or internals to callers; no swallowed exceptions.
4. **Transactions & integrity.** Wrap multi-write operations atomically; define
   behavior on partial failure; keep invariants true.
5. **Idempotency & concurrency.** Make retried operations safe where at-least-once
   delivery is possible; handle races, locks, and ordering the plan requires.
6. **Observability.** Structured logs at the right level (no secrets/PII), metrics/
   traces where the repo does; enough to debug in prod.
7. **Config & secrets.** From config/env, never hardcoded; secrets never logged.
8. **Security.** Authz checks at the boundary (→ `implementing-auth-and-authorization`);
   parameterized queries; output encoding; no injection surface.
9. **Performance.** Avoid N+1 and needless round-trips; paginate large results; only
   optimize what the plan's criteria require.
10. **Conventions.** Match the repo's structure, naming, error style, and patterns.

## Cross-cutting

- **Auth / RBAC** — any step touching authentication or authorization follows
  `implementing-auth-and-authorization` (enforce server-side, deny by default).
- **i18n** — any user-facing message/text follows `implementing-i18n` (externalize,
  no concatenation).
- **Observability** — every step with runtime behavior follows
  `implementing-observability` (structured logs with a request ID, spans that propagate
  context, RED metrics, health checks). Instrument as you build, not after.
- **Schema / migrations** — DB structure changes follow `implementing-database-changes`.
- **API contract** — when exposing a backend seam, follows `coordinating-api-contract`: implement
  as the **provider** to the frozen contract artifact (`docs/plan/contracts/<feature>.*`) — exact
  shapes, statuses, error envelope, auth — write provider-conformance tests, and run the change
  protocol if a shape must move (never diverge in code alone).

## Guardrails

- **Plan is the contract.** Build what it specifies; if a step is wrong or blocked,
  stop and report — don't improvise scope.
- **Tests green + coverage ≥95% before done.** A step isn't complete until its tests pass **and**
  the coverage gate holds — every changed file ≥95% (statements/branches/functions/lines) and the
  global total not regressed. Run with coverage and show the report; a sub-95% file is not done.
- **No secrets, no injection, no swallowed errors.**
- **Match the repo.** New code reads like the existing code.
- **Flag deviations** rather than papering over them.

## When to stop / complete

A step is complete when its behavior is implemented, its tests pass (shown), and it
meets the plan's criteria. Stop and report when: the step's tests are green and
`progress.md` updated; OR a step is blocked, ambiguous, or contradicts the code —
report with specifics and hand back rather than guessing.

## Output

Per step: what changed (files), the tests added and their passing result, any
deviation from the plan and why, and anything flagged for review (security,
performance, a risky call). Keep the plan's `progress.md` current.
