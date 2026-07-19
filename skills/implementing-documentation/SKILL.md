---
name: implementing-documentation
description: >
  Use when implementing anything that adds or changes an API or public interface and
  needs to stay documented — API reference (OpenAPI 3.x / Swagger, GraphQL SDL, proto),
  plus README/usage, CHANGELOG, ADRs, runbooks, and layered per-subtree CLAUDE.md/AGENTS.md
  project-context docs. Encodes best practice: docs live in
  the repo next to the code, generated-from-code or contract-first with a CI drift check,
  served via Swagger UI / Redoc, every operation documenting params, schemas, error/status
  semantics, auth, and examples — updated in the SAME change as the behavior, never later.
  Cross-cutting — backend, frontend, database, and devops executors follow it whenever a
  step ships a documentable surface. It is also a planning and review-gate concern, and
  continues the `designing-an-api` contract sketch into a living published spec. Triggers
  on "document this endpoint/API", "add OpenAPI/Swagger", "update the docs", "API
  reference", "keep docs in sync", "write the README/CHANGELOG/runbook".
---

# Implementing documentation

Cross-cutting craft for keeping the **published contract in sync with the code** —
API reference first (OpenAPI/Swagger), plus the supporting docs a change touches. Followed
by whichever executor ships a documentable surface. Runs on top of the domain skill and the
execution method. Documentation is not a follow-up chore — it is designed as a contract,
planned as steps, and updated alongside the feature in the same change.

## Goal

Make every public surface **discoverable and accurate without reading the source**. If a
change adds or alters an API/interface, its published doc reflects the real behavior — a
caller can find the operation, its inputs/outputs, its errors, and its auth requirements,
and the doc does not disagree with the running code.

## Stack

The plan/repo dictates the tooling (springdoc, drf-spectacular, FastAPI's built-in schema,
swagger-jsdoc, NestJS Swagger, tsp/redocly, GraphQL codegen, protobuf, Storybook, etc).
Match the repo's existing docs setup, location, and format; use context7 for the library's
exact API. Prefer **generate-from-code** (annotations/decorators reflect the real handler)
or **contract-first with a drift check** where the repo already commits to a hand-written
spec. Don't hand-maintain a parallel doc that can silently rot.

## API documentation (primary)

1. **A single source of truth.** The OpenAPI/Swagger (or SDL/proto) document is generated
   from or checked against the code — not a separate artifact that drifts. A doc that
   disagrees with the handler is a defect.
2. **Every operation, fully.** Path/params, request and response **schemas**, **error and
   status semantics** (which codes, which error shape), **auth requirements** per operation,
   and at least one realistic example. Model these, don't hand-wave them.
3. **Served and discoverable.** Expose the spec (Swagger UI / Redoc / GraphQL playground)
   where the repo serves docs, and keep the raw spec file in the repo.
4. **Versioned with the API.** The doc's version tracks the API version; breaking changes
   are visible in the doc and the CHANGELOG.
5. **Drift-checked.** Where feasible, a CI step regenerates or validates the spec against
   the code so an undocumented or mismatched change fails the build.

**Continues `designing-an-api`.** The design phase produced a reviewed contract sketch
(OpenAPI/SDL/proto). Execution turns that sketch into the living, served, drift-checked
spec — same contract, now real and enforced.

## Supporting docs (light)

- **README / usage** — kept current with behavior a user or operator relies on (setup,
  run, key flags/env). Update it when behavior changes, not months later.
- **CHANGELOG** — an entry for every user-visible change; call out breaking changes.
- **ADR** — a short architecture-decision record for a significant or irreversible choice,
  so the *why* survives.
- **Runbook** — operational steps (deploy/rollback, on-call actions) for new operational
  surface.
- **Docstrings / interface comments** — on public functions, types, and modules — the
  *why*, not a restatement of the code.
- **Project context docs (`CLAUDE.md` / `AGENTS.md`), layered per subtree** — when a change
  creates or reshapes a **meaningful source directory**, give that directory its own light
  `CLAUDE.md` (what this subtree is, its key files/entry points, local conventions and gotchas —
  **pointers, not prose**) plus an `AGENTS.md` symlink beside it (`ln -s CLAUDE.md AGENTS.md`),
  and keep the parent/root `CLAUDE.md` in sync. Same change as the structure, never later — this
  is the layered form of the keep-docs-synced convention (the Stop doc-sync hook only nags about
  the root). Keep each layer light so it stays maintainable; don't restate the code.

## By domain

- **Backend** — OpenAPI/Swagger for every endpoint, generated from routes/annotations and
  kept in sync; document the error catalogue and auth per operation; docstrings on public
  services.
- **Frontend** — component and prop documentation with usage examples (Storybook or the
  repo's equivalent); document shared components/hooks so they're reused, not re-invented.
- **Database** — schema and relationship documentation; capture each migration's intent in
  the migration itself; note new tables/columns and their meaning.
- **DevOps** — runbook and deploy/rollback steps; a config/environment-variable reference;
  wire the docs/spec generation and drift check into CI as code.

## Guardrails

- **Same change, not later.** Update the doc in the commit that changes the behavior — a
  "document later" TODO is undocumented.
- **Doc reflects real code.** No fabricated endpoints, fields, or params; generated or
  drift-checked beats hand-maintained.
- **No secrets in examples.** No real tokens, keys, passwords, or PII in samples or fixtures.
- **In the repo, next to the code.** Docs are versioned with the source, not in a detached
  wiki that rots.
- **Reuse the repo's docs stack and conventions;** don't introduce a second doc system.

## When to stop / complete

Complete when the touched API surface has an accurate published spec (OpenAPI/Swagger/SDL)
that matches the code and is served, every operation documents its schemas/errors/auth/
examples, any drift check passes, and the supporting docs the change touches
(README/CHANGELOG/ADR/runbook/docstrings, plus a layered `CLAUDE.md`+`AGENTS.md` symlink for
each meaningful source directory the change created/reshaped, root kept in sync) are updated —
verified by opening the served doc or running the drift/validation check. Stop and report the docs added/updated, or hand back
if a docs toolchain the plan didn't scope is missing.

## Output

Docs added/updated (spec file + served UI, README/CHANGELOG/ADR/runbook), how the spec is
kept in sync (generated vs contract-first + drift check), how you verified it (opened the
UI, ran the validator), and anything left for follow-up (e.g. a versioning/breaking-change
decision needing a human).
