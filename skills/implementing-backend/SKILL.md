---
name: implementing-backend
description: >
  Use when implementing backend/server-side code from a plan — services, endpoints/
  handlers, controllers, business logic, integrations, background jobs/workers — in
  whatever language and framework the plan specifies. Also covers "add an endpoint",
  "write a service/handler/job", "build the API", "server-side logic". Encodes
  production-grade craft: input validation, typed error handling, transactional
  integrity, idempotency, concurrency, observability, and test coverage, matching the
  repo's conventions. Delegates auth/authz to implementing-auth-and-authorization,
  user-facing text to implementing-i18n, and schema changes to
  implementing-database-changes. Followed by the backend-executor subagent. Triggers on
  "implement the endpoint/service", "build the backend for phase N", "write the
  handler/job".
---

# Implementing backend

Execution-time craft for server-side code, followed by the `backend-executor` subagent.
Runs on top of the execution method — **follow `executing-phase-plans` and
`superpowers:test-driven-development`** for the loop (test first, one step at a time,
verify, update `progress.md`); this is the backend quality bar on top of it.

## Goal

Turn a plan's backend steps into **production-grade code a senior engineer would
approve**: correct under failure/concurrency, observable, tested, styled like the
surrounding codebase. Build exactly what the plan specifies — surface deviations, don't
expand scope.

## Stack

Plan dictates language/framework/libraries. Match the repo's version and idioms; use
context7 for the exact API. Flag any dependency the plan didn't sanction — don't import
it silently.

## Derive before you build

The most common shipped defect is a **hard rule reasoned wrong** (a boundary comparison,
a formula, a concurrency invariant) or a **forgotten edge case**. Two cheap steps catch
most — spend the second only where it pays: on a canonical pattern it's wasted
(benchmark G, measured: **1.5× tokens for zero defects caught** on a canonical
concurrency task). Do this inline before coding any non-trivial step, no separate design
doc:

1. **Enumerate edge cases — always.** Overflow/past-limit values, empty/nil/zero,
   boundary conditions (off-by-one, `>=` vs `>`, window/interval edges), invalid/
   malformed input, concurrency/data races. A short comment block suffices — cheap,
   catches *forgotten-edge* defects every time.
2. **Derive the hard rule on a worked numeric example — only when non-canonical.**
   - **Canonical pattern** — a named, standard algorithm with a well-known shape
     (singleflight, LRU/TTL cache, debounce, standard REST CRUD, pagination): reuse it
     (ponytail rung 2/3), don't re-derive — enumerate + test its edges; deriving a
     textbook pattern buys nothing. **But a canonical shape can hide a bespoke
     sub-decision** the pattern doesn't fix — error/expiry/eviction semantics, what to
     cache, tie-breaking. Treat those as non-canonical: enumerate and **decide
     deliberately** whenever the choice has a correctness consequence — singleflight's
     structure doesn't say whether to cache a *failed* call, that's yours to decide.
     Measured (benchmark H): skipping this sub-decision is exactly where a "canonical"
     call shipped a debatable error-caching choice.
   - **Non-canonical / hard-reasoning rule** — a bespoke boundary, a derived formula
     (rate/backoff/pricing/rounding), or an unnamed concurrency invariant: write the
     exact rule and **prove it on concrete numbers before coding** — e.g. "an entry at
     `t` drops when `now - t >= window`; a burst at t=0.9s (window 1s) frees at t=1.9s."
     Catches *hard-reasoning* defects enumeration misses. **Unsure which it is? Derive**
     — skipping a needed derivation ships a bug. **Necessary but not sufficient: a weak
     model derives a subtle boundary wrong ~1 in 4 (measured).** Run it on a **strong
     reasoning model** — design-grade work, dispatched to the capable tier even mid
     cheap execution (a strong-model subagent, not reasoned inline on a weak one).
     Model-tiering **inverts here**: rote code stays cheap, the hard derivation goes to
     the top model.
3. **Turn each enumerated edge (and derived rule) into a focused failing test first**,
   and **test a derived boundary from both sides** — last-accepted and first-rejected
   values (`n-1` passes, `n` fails), plus the just-past-edge case. A one-sided
   happy-path test passes a wrong `>=`-vs-`>` derivation; the two-sided test catches it
   (measured — the hidden grader caught boundary defects the arms' one-sided tests
   missed). Target tests at the edge list, not an open-ended sweep.

This inline pass is what a full spec/plan phase produces, compressed for a
single-component step — escalate to separate design agents only per
`executing-phase-plans`'s criteria for the full multi-agent chain.

## Craft checklist (per step)

1. **Test first.** Failing test (unit + integration for I/O) before implementation, per
   TDD — cover failure paths, not just happy path.
2. **Input validation — within the given signature.** Validate/normalize every external
   input at the boundary; reject invalid early with a clear error; never trust client
   data. **Validation never justifies changing a declared signature.** Two cases:
   *untrusted runtime input* (a request field, a `Get` arg) is rejected **where the
   contract already returns an error**; a *programmer-error precondition* (nil
   dependency, negative config into a constructor the contract declares error-free) is
   handled idiomatically **inside** that signature — panic on misuse, or a documented
   safe default — **never** by adding an `error`/second return the contract lacks.
   Validating a constructor arg is the most common way implementers silently break
   contracts; don't.
3. **Error handling.** Typed/structured errors; map to the right status/response; no
   leaking stack traces/internals; no swallowed exceptions.
4. **Transactions & integrity.** Wrap multi-write ops atomically; define behavior on
   partial failure; keep invariants true.
5. **Idempotency & concurrency.** Retried operations safe under at-least-once delivery;
   handle races, locks, and ordering the plan requires.
6. **Observability.** Structured logs at the right level (no secrets/PII), metrics/
   traces where the repo does — enough to debug in prod.
7. **Config & secrets.** From config/env, never hardcoded; secrets never logged.
8. **Security.** Authz checks at the boundary (→ `implementing-auth-and-authorization`);
   parameterized queries; output encoding; no injection surface.
9. **Performance.** Avoid N+1 and needless round-trips; paginate large results; optimize
   only what the plan requires.
10. **Conventions.** Match the repo's structure, naming, error style, patterns.

## Cross-cutting

- **Auth/RBAC** → `implementing-auth-and-authorization` (server-side, deny by default)
  for any step touching authentication/authorization.
- **i18n** → `implementing-i18n` (externalize, no concatenation) for user-facing text.
- **Observability** → `implementing-observability` (structured logs with a request ID,
  context-propagating spans, RED metrics, health checks) for every step with runtime
  behavior. Instrument as you build, not after.
- **Schema/migrations** → `implementing-database-changes` for DB structure changes.
- **API contract** → `coordinating-api-contract` when exposing a backend seam: implement
  as **provider** to the frozen contract artifact (`docs/plan/contracts/<feature>.*`) —
  exact shapes, statuses, error envelope, auth — with provider-conformance tests, and run
  the change protocol if a shape must move (never diverge in code alone).

## Guardrails

- **Plan is the contract.** Build what it specifies; if a step is wrong or blocked, stop
  and report — don't improvise scope.
- **Signatures are frozen — conform, don't redesign.** The plan/contract's exact
  signatures (names, params, **return arity and types**) are what other code and the
  grader/reviewer compile against. Never change one for validation, an edge case, or
  convenience — not the return type, not an added `error`, not an extra parameter. An
  edge that can't fit the declared signature is a **contract change**: STOP and flag it
  (per `coordinating-api-contract` for an API seam) — don't alter the signature silently.
  **Self-authored tests can't catch this** — they call your *changed* signature and pass,
  hiding the break; conformance must check the **declared** signature, not the shipped
  one (see `executing-phase-plans` → conformance self-check). Measured: a benchmark
  executor turned `NewVault(...) *Vault` into `(*Vault, error)` to validate a constructor
  arg; its own 15 tests passed, the frozen-contract grader failed it to compile.
- **Tests green + coverage ≥95% before done.** Every changed file ≥95%
  (statements/branches/functions/lines), global not regressed — run with coverage, show
  the report; a sub-95% file is not done.
- **No secrets, no injection, no swallowed errors.**
- **Match the repo.** New code reads like the existing code.
- **Flag deviations** rather than papering over them.

## When to stop / complete

Complete when behavior is implemented, tests pass (shown), and it meets the plan's
criteria. Stop and report when tests are green and `progress.md` updated, OR a step is
blocked, ambiguous, or contradicts the code — report specifics, hand back rather than
guessing.

## Output

Per step: files changed, tests added + passing result, any deviation from the plan and
why, anything flagged for review (security, performance, a risky call). Keep
`progress.md` current.
