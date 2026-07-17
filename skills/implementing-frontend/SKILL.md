---
name: implementing-frontend
description: >
  Use when implementing frontend/UI code from a plan — components, state, data
  fetching, routing, styling — in whatever framework the plan specifies. Encodes
  production-grade craft: every async state (loading/error/empty/partial/success),
  accessibility, design-system reuse, controlled state, no console errors, and tests,
  matching the repo's conventions. Delegates user-facing text to implementing-i18n and
  protected UI/routes to implementing-auth-and-authorization. Followed by the
  frontend-executor subagent. Triggers on "implement the component/screen", "build the
  UI for phase N", "wire up the form/page".
---

# Implementing frontend

Execution-time craft for UI code. Followed by the `frontend-executor` subagent. Runs
ON TOP of the execution method — **follow `executing-phase-plans` and
`superpowers:test-driven-development`** for the loop. This skill is the frontend
quality bar layered over it.

## Goal

Turn a plan's frontend steps into **accessible, resilient UI a senior engineer would
approve** — handles every state, reuses the design system, is keyboard- and
screen-reader-usable, and looks like the rest of the app. Build what the plan
specifies; surface deviations.

## Stack

The plan dictates framework, state library, and styling approach. Read the repo to
match its component patterns and conventions; use context7 for the exact framework/
library API. No new UI dependency the plan didn't sanction without flagging it.

## Craft checklist (per step)

1. **Test first.** Component/interaction tests before implementation, per TDD; assert
   behavior and the error/empty states, not just render.
2. **All async states.** Handle loading, error, empty, partial, AND success — no
   happy-path-only components. Show the user something sensible in each.
3. **Accessibility.** Semantic elements, labels, keyboard navigation, focus
   management, sufficient contrast; ARIA only where semantics fall short.
4. **State discipline.** Controlled inputs; state as local as possible; one source of
   truth; derive don't duplicate; clean up effects/subscriptions.
5. **Data fetching.** Match the API contract; handle failure and retry; avoid waterfalls
   and refetch storms; cache/invalidate per the repo's data layer.
6. **Design-system reuse.** Use existing components/tokens/styles; justify any new
   primitive. Responsive per the plan's breakpoints.
7. **Forms & validation.** Client validation mirroring the API contract; clear error
   display; disabled/submitting states; no lost input on error.
8. **No console errors/warnings;** no key warnings, no unhandled promise rejections.
9. **Performance.** Code-split heavy routes; virtualize long lists; memoize where it
   pays; avoid needless re-renders.
10. **Conventions.** Match the repo's file layout, naming, and component style.

## Cross-cutting

- **i18n** — all user-facing text follows `implementing-i18n` (no hardcoded strings,
  no string concatenation, locale-aware formatting).
- **Auth / RBAC** — protected routes/components and permission-gated UI follow
  `implementing-auth-and-authorization`. UI gating is UX only; the server still
  enforces — never rely on hiding a button for security.
- **Observability** — follows `implementing-observability`: error tracking (error
  boundaries, unhandled errors/rejections), real-user monitoring / core web vitals, key
  user-action events, and a trace header propagated to the backend. No PII in client
  telemetry.

## Guardrails

- **Plan is the contract.** Build what it specifies; report blockers, don't improvise.
- **States are in scope**, not afterthoughts. Loading/error/empty required.
- **Accessibility is required**, not polish.
- **UI checks aren't security** — gating is UX; the backend authorizes.
- **Tests green before done;** show the run. **Match the repo.**

## When to stop / complete

A step is complete when the component handles all states, is accessible, tests pass
(shown), and it meets the plan's criteria. Stop and report when tests are green and
`progress.md` updated, OR when a step is blocked/ambiguous — report specifics, hand back.

## Output

Per step: components/files changed, tests added + passing result, states handled,
a11y notes, any deviation from the plan and why, and anything flagged for review. Keep
`progress.md` current.
