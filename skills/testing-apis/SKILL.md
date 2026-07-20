---
name: testing-apis
description: >
  Use when black-box testing a built API (REST/GraphQL/RPC) against its contract — hitting
  the running service and asserting behavior, not reading the code. Encodes best practice:
  test every operation's status codes, response schema, error/status semantics, auth and
  per-resource authorization (including negative and cross-user IDOR cases), input
  validation, idempotency, pagination, and rate limits; verify the live service against its
  OpenAPI/Swagger contract so docs and reality agree. Tool-neutral — curl/httpie for quick
  probes, a runner (supertest, pytest+requests, RestAssured, Postman/newman) for a persisted
  suite. Followed by the `qa-tester` agent. Triggers on "test the API", "API testing",
  "contract test", "check the endpoints", "verify the API against the spec".
---

# Testing APIs

Craft for **black-box functional testing of a running API** — prove the built service does
what the spec and its OpenAPI/Swagger contract promise, by calling it and asserting the
response. Distinct from the executor's unit/integration tests (white-box, written during
TDD): this exercises the deployed surface as a client sees it.

## Goal

For every operation in scope, prove the live service returns the **right status, the right
shape, and the right errors**, enforces **auth/authz** correctly, and matches its published
contract. A defect is any deviation from the spec's success criteria or the OpenAPI/Swagger
doc — surface it with the exact request and response that shows it.

## Stack

The repo/plan dictates the tooling. Quick probes: `curl` / `httpie`. Persisted suite: the
repo's runner (supertest, pytest+requests/httpx, RestAssured, Jest, Postman/newman,
`schemathesis`/`dredd` for contract fuzzing). Match the repo's existing test layout and
naming; use context7 for the tool's exact API. The **contract source of truth** is the frozen
artifact `docs/plan/contracts/<feature>.*` (kept in sync with the served spec under
`implementing-documentation`) — validate against it (`coordinating-api-contract`).

## What to test

1. **Happy path** — each operation with valid input returns the documented success status
   and a body matching the documented schema.
2. **Contract conformance** — response (and request) validate against the frozen contract
   artifact schema; content-type, field types, required fields, enums. Doc vs reality must agree —
   a mismatch is a doc bug or a code bug, either way a defect. **Both sides of a seam:** the
   backend (**provider**) responses validate against the artifact, and the frontend's mock/
   fixtures/types (**consumer parity**) validate against the same artifact — plus a **drift check**
   that the served/generated spec equals the committed artifact.
3. **Error & status semantics** — bad input, missing fields, wrong types, not-found,
   conflict — each returns the documented status and error shape, not a 500.
4. **Auth & authorization** — unauthenticated is rejected; a valid but unauthorized caller
   is denied; **cross-user object access is blocked (IDOR)** — request another tenant's/
   user's resource and assert deny. Negative authz cases are mandatory, not optional.
5. **Validation & boundaries** — limits, empty, oversized, injection-shaped input,
   Unicode/i18n input; assert graceful handling, never a crash.
6. **Idempotency & side effects** — safe methods don't mutate; retried idempotent writes
   don't double-apply; check the persisted state, not just the response.
7. **Pagination, filtering, ordering, rate limits** where the contract defines them.

## Method

1. Read the spec's success criteria and the OpenAPI/Swagger contract; list operations in scope.
2. Prepare isolated test data and credentials for each role (admin/user/other-tenant).
3. Probe interactively (`curl`) to confirm behavior, then encode the assertions in the
   repo's runner as a repeatable suite. Assert status + schema + body + side effects.
4. Cover happy, error, auth-negative, and boundary cases per operation.
5. Run the suite; capture failures with the exact request/response.

## Guardrails

- **Never test destructively against production;** use a test/staging environment or an
  ephemeral instance with seeded data. Real prod data and real user PII stay out.
- **No real secrets/tokens in committed tests** — use env vars / fixtures / a vault.
- **Deterministic and isolated** — each test sets up and tears down its own data; no
  order-dependence, no shared mutable state, no reliance on records that may vanish.
- **Assert the contract, not a snapshot of noise** — pin the meaningful fields, tolerate
  volatile ones (timestamps, generated IDs).
- **Negative authz is required** — a suite with only happy-path auth is incomplete.
- **Re-test targeted, not the whole suite, after a fix.** When a defect is fixed, re-run **only
  the failed test(s) and any that hit the changed operation** to confirm it — most runners scope
  by file/name (`jest path`, `pytest -k`, `vitest run path`, `go test -run`). Run the **full
  suite once at the end** to catch cross-operation regression. Full-suite sweep per small fix is
  the waste, not the coverage.

## When to stop / complete

Complete when every in-scope operation has happy + error + auth-negative + boundary
coverage, responses validate against the contract, side effects are asserted, the suite runs
green (or the failures are reported as defects with repro), and the persisted tests live in
the repo's test tree. Stop and hand back if the service can't be run/reached or the contract
is missing and the plan didn't scope creating it.

## Output

The persisted API tests (paths), the run result, each defect as an exact request→response
with the expected vs actual, contract mismatches (doc vs code) called out, coverage summary
(operations × case types), and anything left for follow-up.
