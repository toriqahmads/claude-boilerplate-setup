---
name: implementing-frontend
description: >
  Use when implementing frontend/UI code from a plan — components, state, data
  fetching, routing, styling — in whatever framework the plan specifies. Also covers
  "build the page/screen/form", "wire up the UI", "add a component", "implement the
  view". Encodes production-grade craft: every async state (loading/error/empty/
  partial/success), accessibility, design-system reuse, controlled state, no console
  errors, and tests, matching the repo's conventions. Delegates user-facing text to
  implementing-i18n and protected UI/routes to implementing-auth-and-authorization.
  Followed by the frontend-executor subagent. Triggers on "implement the component/
  screen", "build the UI for phase N", "wire up the form/page".
---

# Implementing frontend

Execution-time craft for UI code, followed by the `frontend-executor` subagent. Runs on
top of the execution method — **follow `executing-phase-plans` and
`superpowers:test-driven-development`** for the loop. This is the frontend quality bar
layered on top.

## Goal

Turn a plan's frontend steps into **accessible, resilient UI a senior engineer would
approve**: handles every state, reuses the design system, keyboard- and
screen-reader-usable, styled like the rest of the app. Build what the plan specifies;
surface deviations.

## Stack

Plan dictates framework, state library, styling approach. Match the repo's component
patterns/conventions; use context7 for the exact API. Flag any new UI dependency the
plan didn't sanction.

## Enumerate states, reuse shapes, derive only bespoke logic

The frontend analogue of the backend's *Derive before you build*. The most common
shipped UI defect is a **forgotten state** (happy-path-only component), a **hand-rolled
component that already exists**, or a **bespoke interaction race** (stale async
response wins, optimistic update never rolls back). Three cheap steps kill most —
derive only where it pays:

1. **Enumerate the state matrix first — always.** Per view/component, list states it
   must render: **data async** (loading/error/empty/partial/success), **permission**
   (allowed/denied/unauthenticated), **form**
   (pristine/editing/submitting/server-error/success), plus **responsive** breakpoints
   and **i18n/RTL** where relevant. A short list suffices — cheap, catches the #1
   frontend defect: a state nobody built.
2. **Reuse the known shape — canonicity gate.** A **canonical UI pattern** (standard
   form, paginated table/list, modal/dialog, tabs, toast, data-fetch-with-states,
   standard CRUD screen) reuses the **design-system component / shadcn registry
   primitive / framework hook** (ponytail rungs 2–4; `mcp__shadcn__*`) — don't hand-roll
   or re-derive it. Only **bespoke interaction logic** is non-canonical — a custom
   state machine, optimistic-update + rollback reconciliation, a debounced-async
   request race, a drag-reorder/virtualized-selection invariant — **derive its exact
   rule on a concrete event sequence before coding** (which result wins, how a stale
   response is discarded, the invariant). Unsure which it is? Derive. A subtle race is
   easy to get wrong, so **run that derivation on a strong model** (capable tier / a
   strong-model subagent, not the cheap execution tier). **Reusing a canonical
   component doesn't exempt a bespoke sub-decision** (empty-vs-error copy, optimistic
   rollback, focus-return target after close) — enumerate and decide those
   deliberately (benchmark H).
3. **Turn each enumerated state (and derived rule) into a focused failing test first**
   — a tight test per matrix state, not an open-ended sweep. For a **derived
   interaction rule, test both outcomes of the event sequence** — stale response
   *discarded* AND fresh one *wins*; optimistic update *rolls back* on failure AND
   *commits* on success. A one-sided test passes a race that only handles the happy
   ordering.

## Craft checklist (per step)

1. **Test first.** Component/interaction tests before implementation, per TDD; assert
   behavior and error/empty states, not just render.
2. **All async states.** Loading, error, empty, partial, AND success — no
   happy-path-only components; show the user something sensible in each.
3. **Accessibility.** Semantic elements, labels, keyboard navigation, focus management,
   sufficient contrast; ARIA only where semantics fall short.
4. **State discipline.** Controlled inputs; state as local as possible; one source of
   truth; derive don't duplicate; clean up effects/subscriptions.
5. **Data fetching.** Match the **frozen API contract artifact**
   (`docs/plan/contracts/<feature>.*`) — build against its contract-derived mock so the
   UI isn't blocked on the backend (`coordinating-api-contract`); handle failure/retry;
   avoid waterfalls and refetch storms; cache/invalidate per the repo's data layer.
6. **Design-system reuse.** Existing components/tokens/styles; justify any new
   primitive. Responsive per the plan's breakpoints.
7. **Forms & validation.** Client validation mirroring the API contract; clear error
   display; disabled/submitting states; no lost input on error.
8. **No console errors/warnings** — no key warnings, no unhandled promise rejections.
9. **Performance.** Code-split heavy routes; virtualize long lists; memoize where it
   pays; avoid needless re-renders.
10. **Conventions.** Match the repo's file layout, naming, component style.

## Cross-cutting

- **i18n** — all user-facing text follows `implementing-i18n` (no hardcoded strings, no
  concatenation, locale-aware formatting).
- **Auth/RBAC** — protected routes/components and permission-gated UI follow
  `implementing-auth-and-authorization`. UI gating is UX only — the server still
  enforces; never rely on hiding a button for security.
- **Observability** — follows `implementing-observability`: error tracking (boundaries,
  unhandled errors/rejections), real-user monitoring/core web vitals, key user-action
  events, a trace header propagated to the backend. No PII in client telemetry.
- **API contract** — when consuming a backend seam, follows `coordinating-api-contract`:
  build as **consumer** against the frozen contract artifact's mock (never blocked on
  the backend), never assume an undefined field, run the change protocol if a shape
  must move.

## Guardrails

- **Plan is the contract.** Build what it specifies; report blockers, don't improvise.
- **Enumerate the state matrix before building; reuse the canonical shape.** A
  forgotten state and a hand-rolled version of an existing component are the two most
  common UI defects — enumeration + design-system/registry reuse (ponytail rungs 2–4)
  prevent both. Derive only bespoke interaction logic, not a standard form/table/modal.
- **Build to the design system; production-ready UI/UX is the bar.** Implement to the design doc's
  tokens + component system (reuse the repo's library / shadcn registry; establish the tokens if the
  design specifies them), with polished states, clear visual hierarchy, purposeful
  `prefers-reduced-motion`-safe motion, responsive layout, and a11y — professional, not
  functional-but-rough. Per `designing-a-frontend`.
- **States are in scope**, not afterthoughts. Loading/error/empty required.
- **Accessibility is required**, not polish.
- **UI checks aren't security** — gating is UX; the backend authorizes.
- **Tests green + coverage ≥95% before done** — show the run and coverage report; every
  changed file ≥95% (statements/branches/functions/lines), global not regressed; a
  sub-95% file is not done. **Match the repo.**

## When to stop / complete

Complete when the component handles all states, is accessible, tests pass (shown), and
it meets the plan's criteria. Stop and report when tests are green and `progress.md`
updated, OR a step is blocked/ambiguous — report specifics, hand back.

## Output

Per step: components/files changed, tests added + passing result, states handled, a11y
notes, any deviation from the plan and why, anything flagged for review. Keep
`progress.md` current.
