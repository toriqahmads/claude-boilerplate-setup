---
name: designing-an-api
description: >
  Use when designing an API for a spec — the paradigm (REST / GraphQL / gRPC / RPC),
  resource and operation modeling, request/response contracts and schemas, status and
  error semantics, auth and authorization, versioning, pagination/filtering,
  idempotency, and rate limits. Produces an API-contract recommendation that feeds the
  design doc, consistent with the repo's existing API conventions. Followed by the
  api-designer-agent subagent. Triggers on "design the API", "REST vs GraphQL",
  "what endpoints", "design the request/response", "how should errors look", "API
  versioning".
---

# Designing an API

Rubric for the API surface during spec design. Followed by the `api-designer-agent`
subagent; usable inline. Output is a contract recommendation feeding the design doc —
not handler code.

## Goal

Recommend an **API contract that is predictable, consistent, and hard to misuse** —
the operations, their request/response shapes, error semantics, and auth — modeled on
the domain and consistent with the repo's existing API. Design the contract clients
depend on; it's expensive to change later.

## When to use

During spec authoring, after architecture and data model are drafted (the API
exposes them). Before the plan is written.

## Inputs

The spec draft + architecture + data model, the consumers (who calls this and how),
and the repo's existing API (Read/Grep/Glob the current routes, schemas, error
format, auth) so the new surface matches established conventions.

## Design dimensions

1. **Paradigm** — REST / GraphQL / gRPC / plain RPC, driven by consumers, coupling,
   and repo precedent. Default to what the repo already exposes; justify a departure.
2. **Resource / operation modeling** — resources and their operations (REST) or
   queries/mutations/procedures (GraphQL/RPC). Model the domain, not the DB tables.
3. **Request/response contracts** — exact shapes, field names, types, required vs
   optional, defaults. Stable, consistent naming and casing.
4. **Status & error semantics** — success codes, a consistent error envelope (code +
   message + details), validation errors, which failures map to which status. No 200-with-error-body.
5. **Auth & authorization** — authentication scheme (token/session/mTLS) and
   per-operation authorization (who can do what). State it per endpoint, not globally hand-waved.
6. **Versioning & compatibility** — versioning strategy (URI/header/none), what counts
   as a breaking change, deprecation path.
7. **Pagination, filtering, sorting** — for collections: cursor vs offset, filter/sort
   params, limits, consistent across endpoints.
8. **Idempotency & safety** — safe vs unsafe methods; idempotency keys for
   at-least-once clients; retry behavior.
9. **Rate limiting & abuse** — limits, quotas, and the response when exceeded, if the
   spec requires them.
10. **Contract artifact** — express it as OpenAPI/GraphQL SDL/proto sketch so it's
    unambiguous and reviewable.

## Method

1. Identify the consumers and their real calls (the operations they need).
2. Read the repo's existing API — routes, schema style, error envelope, auth — and
   match it; consistency across the surface beats local cleverness.
3. Model resources/operations from the domain; define request/response shapes.
4. Nail error semantics and auth per operation.
5. Decide versioning, pagination, idempotency to the spec's needs.
6. Express the contract in a schema sketch; ground types against the data model.

## Guardrails

- **Consistency over novelty.** Match the repo's existing conventions; a uniform API
  beats a locally elegant but divergent one.
- **Model the domain, not the tables.** The API is a contract, not a DB dump.
- **Explicit errors & auth.** Every operation states its failure modes and who may call it.
- **Don't break clients silently.** Any change to an existing endpoint states
  compatibility impact and a versioning/deprecation path.
- **Recommendation, not code.** Stop at the contract + rationale; handlers are later phases.
- **Ground claims** against the repo's existing API (`file:line`) and external specs.

## When to stop / complete

Stop when the contract is defined (operations, shapes, errors, auth) as a reviewable
schema sketch consistent with the repo — or when a consumer need or auth policy only
the user has blocks it (present it). Do not implement handlers or design the DB/UI;
hand those on.

## Output

- **Recommendation** — paradigm + surface shape, 1–3 sentences, up front.
- **Operations** — resources/endpoints or queries/mutations, each with method + purpose.
- **Contracts** — request/response schema per operation (field, type, required, default).
- **Errors** — the error envelope + status mapping + validation errors.
- **Auth** — scheme + per-operation authorization.
- **Versioning, pagination, idempotency, limits** — as the spec requires.
- **Contract sketch** — OpenAPI / GraphQL SDL / proto excerpt.
- **Trade-offs & open questions** — what the user must confirm; compatibility impacts.
- **Sources** — repo `file:line` and external references used.
