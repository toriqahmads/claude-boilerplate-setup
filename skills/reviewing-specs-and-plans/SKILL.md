---
name: reviewing-specs-and-plans
description: >
  Use when reviewing a design doc / spec or an implementation plan BEFORE any code
  is written — the phase-1 quality gate. Checks a spec for problem clarity, scope /
  non-goals, measurable success criteria, constraints, interfaces, risks, and
  considered alternatives; checks a plan for completeness against the spec, step
  granularity, test/TDD coverage, sequencing and dependencies, absence of
  placeholders, and feasibility. Adversarial by design — hunts for gaps, ambiguity,
  and untestable claims, then returns approve-or-revise with specific fixes. Distinct
  from reviewing-phase-implementation, which reviews built CODE. Triggers on "review
  this spec", "review the design doc", "review the plan", "is this plan ready to
  build", "check the breakdown".
---

# Reviewing specs and plans

The phase-1 quality gate: catch design and planning defects before they become
code. Followed by the `design-reviewer-agent` subagent, usable inline by the main
thread. Distinct from `reviewing-phase-implementation` (that reviews built code).

## Goal

Decide whether a spec or plan is **ready to advance** — and if not, return the
**specific, actionable gaps** that block it. Be adversarial: assume something is
missing and go find it. A rubber-stamp review is a failed review. Output is a
verdict plus a ranked list of concrete fixes, not prose praise.

## When to use

- After `brainstorming-a-goal` / spec authoring produces a design doc — before breakdown.
- After `breaking-down-into-phases` produces a breakdown — before planning.
- After `planning-each-phase` produces a plan — before execution.

## Inputs

Read the artifact under review AND its upstream source of truth: a plan is judged
against its spec + breakdown; a spec is judged against the original goal / ticket /
PRD. Ground against the real repo (Read/Grep/Glob) to check that referenced files,
APIs, and versions actually exist.

## Scale the review to the tier

**Read the complexity tier** from the design-doc header and scale the dimension walk to it
— depth, not the quality bar:

- **Small** — core dimensions only. Spec: {problem clarity, success criteria, interfaces,
  consistency}. Plan: {completeness vs spec, test/TDD coverage, verification}. Skip the rest.
- **Standard** — all dimensions, single pass.
- **Large** — all dimensions, full adversarial depth (the default behavior below).
- **Security is never dropped on a risk-flagged change**, any tier — always walk the
  security-relevant dimensions (interfaces/contracts, constraints, reversibility) for it.

## Spec review dimensions

1. **Problem clarity** — is the problem stated crisply, with who it's for and why now? No solution smuggled in as the problem.
2. **Scope & non-goals** — is what's in and explicitly out both stated? Vague scope = scope creep later.
3. **Success criteria** — measurable and testable? "Fast" / "robust" / "clean" are not criteria. Each should map to something verifiable.
4. **Constraints & assumptions** — tech, time, compatibility, data. Are assumptions stated and safe? Which are load-bearing?
5. **Interfaces & contracts** — inputs, outputs, APIs, data shapes, error behavior at the boundaries.
6. **Alternatives considered** — were real options weighed, or just the first idea? Is the chosen direction justified over them?
7. **Risks & unknowns** — what could sink this? What's unproven and needs a spike?
8. **Observability** — does the spec state what must be observable in production (key logs, traces, golden-signal metrics, health checks, alerts)? Operability is a requirement, not an afterthought.
9. **Consistency** — internally coherent, and consistent with existing system architecture and conventions.

## Plan review dimensions

1. **Completeness vs spec** — does the plan deliver every success criterion? Anything in the spec with no plan step? Anything in the plan not traceable to the spec (gold-plating)?
2. **Step granularity** — bite-sized, independently verifiable steps? No giant "implement the feature" step.
3. **Test / TDD coverage** — does each behavior change come with a test? Tests before implementation where the workflow calls for it? Edge cases and failure paths covered?
4. **Sequencing & dependencies** — correct order? Dependencies explicit? No step needing an artifact a later step produces?
5. **No placeholders** — no "TODO", "figure out later", "handle somehow". Concrete files, functions, commands.
6. **Feasibility** — do referenced files/APIs/versions exist? Will the approach actually work against this repo? Any step that's hand-waving over the hard part?
7. **Reversibility & risk** — migrations, destructive ops, rollout/rollback. Is the risky step isolated and recoverable?
8. **Observability steps** — for behavior-bearing steps, does the plan include concrete instrumentation (logging, tracing, metrics, health checks, and any required dashboards/alerts) with verification, or is observability left implicit?
9. **Documentation steps** — for steps that add/change an API or public interface, does the plan include producing/updating the API doc (OpenAPI/Swagger/SDL) and supporting docs (README/CHANGELOG/runbook), with verification, or are docs left implicit?
10. **Verification** — is "done" defined per step and for the whole plan, with the command/observation that proves it?

## Method

1. Read the artifact and its upstream source fully.
2. Walk each applicable dimension; for each, either confirm it holds with a
   reference or record a specific gap (quote the line, name the missing thing).
3. Cross-check spec↔plan traceability both directions (criterion→step, step→criterion).
4. Rank findings by severity: **blocker** (must fix before advancing) > **should-fix**
   (fix now or log as known risk) > **nit** (optional polish).
5. Give a verdict.

## Verdict

One of:

- **APPROVE** — ready to advance. Note any nits as optional.
- **REVISE** — list the blockers and should-fixes as concrete, actionable edits
  ("add a measurable criterion for latency", "step 4 depends on step 7's output —
  reorder", "spec claims file `x.ts` — it doesn't exist"). Each finding: what's
  wrong, where, and the fix.

Never approve to be agreeable. If nothing is wrong, say so plainly with the
evidence you checked — but you usually find something.

## When to stop / complete

Stop when you've walked every applicable dimension and produced a verdict with
ranked findings. Do not redesign the spec or rewrite the plan yourself — surface
the gaps and hand back. Do not expand scope beyond reviewing the artifact.

## Output

- **Verdict** — APPROVE / REVISE, one line, up front.
- **Blockers** — must-fix before advancing, each with location + fix.
- **Should-fix** — fix-now-or-log, each with location + fix.
- **Nits** — optional.
- **Traceability** — spec criteria ↔ plan steps map (for plan reviews), gaps flagged.
- **What I checked** — dimensions covered and what grounded them, so the caller
  knows the coverage.
