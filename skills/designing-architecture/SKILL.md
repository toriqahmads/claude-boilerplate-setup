---
name: designing-architecture
description: >
  Use when designing the system architecture for a spec — component boundaries, how
  data and control flow, where state lives, sync vs async, scalability and failure
  behavior, and the technology/pattern choices that hold it together. Produces an
  architecture recommendation that feeds the design doc, grounded against the real
  repo and the spec's constraints. Followed by the architecture-agent subagent.
  Triggers on "design the architecture", "how should this be structured", "component
  design", "should this be a service / a queue / a monolith".
---

# Designing architecture

Rubric for shaping a system's high-level structure during spec design. Followed by
the `architecture-agent` subagent; usable inline. Output is a recommendation that
feeds the design doc — not code, not a full implementation plan.

## Goal

Recommend the **simplest structure that meets the spec's requirements and
constraints** — the components, their boundaries, how they communicate, where state
and truth live — with the trade-offs made explicit and the choice justified over
real alternatives. Bias to boring, proven structure; add complexity only where a
requirement forces it.

## When to use

During spec authoring, when a feature/system needs a structural shape decided before
interfaces and data are pinned down. After a direction is chosen (brainstorm), before
the spec's interfaces/DB/API sections are finalized.

## Inputs

The spec draft / approved direction and its constraints (scale, latency, consistency,
team, timeline). The real repo — Read/Grep/Glob to see the existing architecture,
so the recommendation fits what's already there rather than a greenfield ideal.

## Design dimensions

1. **Components & boundaries** — what are the pieces, what each owns, what it hides.
   High cohesion, low coupling. Justify every boundary (a boundary has a cost).
2. **Data & control flow** — how a request moves through the pieces; where
   transformations happen; sync call vs async message vs event.
3. **State & source of truth** — where state lives, who owns it, how it's kept
   consistent. Avoid two components claiming the same truth.
4. **Consistency & failure** — consistency model (strong/eventual), what happens on
   partial failure, retries, idempotency, timeouts, back-pressure.
5. **Scalability** — the expected load and the axis it grows on; what scales
   horizontally vs is a bottleneck. Don't design for scale the spec doesn't require.
6. **Cross-cutting concerns** — auth, config, caching, and **observability**
   (structured logging, distributed tracing, metrics, health checks, monitoring,
   alerting) — where each lives so they aren't bolted on later. Observability is
   first-class: name how a request is traced across components, the golden-signal
   metrics, and where health/telemetry is emitted. Capture these as spec requirements
   so planning and execution build them in (see `implementing-observability`).
7. **Technology & patterns** — frameworks, runtime, messaging, storage class. Prefer
   what the repo/team already uses; justify any new dependency.
8. **Fit with existing system** — how it plugs into current architecture; what it
   reuses; what it must not break.

## Method

1. Restate the requirements and the load-bearing constraints (the ones that actually
   shape structure — scale, consistency, latency, team).
2. Read the existing architecture in the repo so the design fits reality.
3. Sketch 2–3 candidate structures when the choice is non-obvious; compare on the
   dimensions that matter for THIS spec.
4. Recommend one; state what it costs and what would change the call.
5. Ground it — confirm the components/tech you name exist or are addable here.

## Guardrails

- **Simplest thing that works.** Complexity is a cost paid forever; justify each piece.
- **No speculative generality.** Don't design for requirements the spec doesn't state.
- **Fit the repo.** Reuse existing structure/tech; flag and justify anything new.
- **Recommendation, not code.** Stop at structure + rationale; interfaces/DB/API are
  the sibling specialist skills; implementation is later phases.
- **Ground claims.** Cite the repo (`file:line`) and external sources for pattern/tech claims.

## When to stop / complete

Stop when the structure is decided with rationale and grounded against the repo, OR
when the choice hinges on a requirement only the user can pin down (present the
options + the decisive question). Do not expand into DB schema, API contracts, or
implementation steps — hand those to the sibling specialists / planning.

## Output

- **Recommendation** — the structure, 1–3 sentences, up front.
- **Components & boundaries** — each piece, what it owns, why the boundary.
- **Flow** — how data/control moves (entry → output), sync/async noted.
- **State, consistency, failure** — where truth lives, consistency model, failure behavior.
- **Scale & cross-cutting** — the growth axis; where auth/logging/observability live.
- **Tech & patterns** — choices, with justification vs alternatives and repo fit.
- **Trade-offs & open questions** — what this costs; what the user must decide.
- **Sources** — repo `file:line` and external references used.
