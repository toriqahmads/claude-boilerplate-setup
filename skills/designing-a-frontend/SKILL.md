---
name: designing-a-frontend
description: >
  Use when designing the frontend for a spec — component architecture and boundaries,
  state management (local / shared / server-cache), data fetching and loading/error
  states, routing and navigation, the design-system/styling approach, accessibility,
  responsive behavior, and performance. Produces a frontend-design recommendation that
  feeds the design doc, consistent with the repo's existing UI stack and conventions.
  Followed by the frontend-designer-agent subagent. Triggers on "design the UI",
  "component structure", "state management approach", "how should this screen work",
  "design system", "make it accessible/responsive".
---

# Designing a frontend

Rubric for the UI layer during spec design. Followed by the
`frontend-designer-agent` subagent; usable inline. Output is a frontend-design
recommendation feeding the design doc — not component code. Skip for backend-only
work.

## Goal

Recommend a **component and state structure that renders the required screens
accessibly and stays maintainable** — the component tree, where state lives, how data
flows in, and the loading/error/empty states — consistent with the repo's existing UI
stack. Design for the real states (loading, error, empty, partial), not just the
happy path.

## When to use

During spec authoring for any user-facing feature, after the API contract is drafted
(the UI consumes it). Before the plan is written.

## Inputs

The spec draft + API contract, the screens/flows/interactions required, and the
repo's existing frontend (Read/Grep/Glob the framework, component patterns, state
library, styling/design system) so the design matches what's there.

## Design dimensions

1. **Component architecture** — the component tree, boundaries, and composition;
   container vs presentational; what's reusable vs one-off. Match the repo's patterns.
2. **State model** — what state exists and where it belongs: local component, shared
   app state, server-cache (query library), URL/route. Minimize shared mutable state;
   derive don't duplicate.
3. **Data fetching** — how the UI calls the API, caching/invalidation, optimistic
   updates, and every async state: **loading, error, empty, partial, success**.
4. **Routing & navigation** — routes, params, guards, deep-linking, and what's in the
   URL vs state.
5. **Design system & styling** — reuse the existing components/tokens/styling
   approach; where new components are justified. Consistency over bespoke.
6. **Accessibility** — semantic structure, keyboard navigation, focus management,
   ARIA where needed, contrast. A11y is a requirement, not a polish item.
7. **Responsive & adaptive** — breakpoints, layout behavior across viewports, touch
   vs pointer.
8. **Performance** — bundle/code-splitting, render cost, list virtualization,
   memoization where it pays, avoiding needless re-renders.
9. **Forms & validation** — input handling, client validation mirroring the API
   contract, error display, submission states.

## Method

1. List the screens/flows and the states each must handle (including error/empty).
2. Read the repo's frontend stack and patterns; match framework, state approach, and
   design system.
3. Sketch the component tree and decide where each piece of state lives.
4. Map data fetching to the API contract, defining every async state.
5. Check accessibility, responsive behavior, and performance against the requirements.

## Guardrails

- **Design the states, not just the happy path.** Loading/error/empty are part of the
  spec, not afterthoughts.
- **Reuse the design system.** Match existing components/tokens/patterns; justify new
  ones.
- **State minimalism.** Keep state local where possible; one source of truth; derive
  the rest.
- **Accessibility is required.** Semantic, keyboard-navigable, sufficient contrast.
- **Recommendation, not code.** Stop at structure + rationale; components are later phases.
- **Ground claims** against the repo's actual frontend (`file:line`) and framework docs
  (use context7 for the current framework/library API).

## When to stop / complete

Stop when the component tree, state model, data-fetching states, and a11y/responsive
approach are decided and consistent with the repo — or when a UX/flow decision only
the user (or a designer) can make blocks it (present it). Do not write components or
design the API/DB; hand those on.

## Output

- **Recommendation** — component + state approach, 1–3 sentences, up front.
- **Component tree** — the components, boundaries, container vs presentational.
- **State model** — each piece of state and where it lives (local/shared/server/URL).
- **Data & async states** — API calls + loading/error/empty/partial/success handling.
- **Routing** — routes, params, guards.
- **Design system, a11y, responsive, performance** — approach for each, reuse noted.
- **Trade-offs & open questions** — what the user/designer must decide.
- **Sources** — repo `file:line`, framework docs (context7), external references used.
