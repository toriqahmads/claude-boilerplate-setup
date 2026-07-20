---
name: designing-a-frontend
description: >
  Use when designing the frontend for a spec — component architecture and boundaries, state management (local / shared / server-cache), data fetching and loading/error states, routing and navigation, the design-system/styling approach, accessibility, responsive behavior, and performance. Also fires for: "design the UI", "component structure", "state management approach", "how should this screen work", "design system", "make it accessible/responsive", "frontend architecture", "component tree", "UI/UX design for this feature". Produces a frontend-design recommendation that feeds the design doc, consistent with the repo's existing UI stack and conventions. Followed by the frontend-designer-agent subagent.
---

# Designing a frontend

Rubric for the UI layer during spec design. Followed by the `frontend-designer-agent` subagent; usable inline. Output is a frontend-design recommendation feeding the design doc — not component code. Skip for backend-only work.

## Goal

Recommend a **component and state structure that renders the required screens accessibly and stays maintainable** — the component tree, where state lives, how data flows in, and the loading/error/empty states — consistent with the repo's existing UI stack. Design for the real states (loading, error, empty, partial), not just the happy path. **When a feature ships UI, the bar is production-ready, professional UI/UX** — a coherent design system and polished interaction, not a functional-but-rough screen.

## When to use

During spec authoring for any user-facing feature, after the API contract is drafted (the UI consumes it). Before the plan is written.

## Inputs

The spec draft + API contract, the screens/flows/interactions required, and the repo's existing frontend (Read/Grep/Glob the framework, component patterns, state library, styling/design system) so the design matches what's there.

## Design dimensions

1. **Component architecture** — the component tree, boundaries, and composition; container vs presentational; what's reusable vs one-off. Match the repo's patterns.
2. **State model** — what state exists and where it belongs: local component, shared app state, server-cache (query library), URL/route. Minimize shared mutable state; derive don't duplicate.
3. **Data fetching** — how the UI calls the API, caching/invalidation, optimistic updates, and every async state: **loading, error, empty, partial, success**.
4. **Routing & navigation** — routes, params, guards, deep-linking, and what's in the URL vs state.
5. **Design system & visual language (mandatory for UI work)** — establish or reuse a **coherent design system**: **design tokens** (color palette + semantic roles, typographic scale, spacing/sizing scale, radius, elevation/shadow, motion durations/easing), a **component system** (reuse the repo's library / shadcn registry primitives with defined variants + sizes + states — `mcp__shadcn__*`; ground tokens in Figma when connected), and a consistent visual hierarchy. Reuse an existing system; if none exists, propose the token set + base components. On-brand and consistent — never bespoke per screen.
6. **UX quality & interaction (production-ready polish)** — what separates a professional UI from a functional one: every state *designed* (skeleton/loading, empty, error, success, partial), clear affordances and immediate feedback, sensible defaults and safe destructive-action confirms, purposeful **micro-interactions/motion** (subtle, `prefers-reduced-motion`-safe), keyboard/input ergonomics, and clear microcopy/tone. Design the empty and error states as first-class screens.
7. **Accessibility** — semantic structure, keyboard navigation, focus management, ARIA where needed, contrast (WCAG AA). A11y is a requirement, not a polish item.
8. **Responsive & adaptive** — breakpoints, layout behavior across viewports, touch vs pointer, content reflow. Design mobile and desktop, not one scaled.
9. **Performance** — bundle/code-splitting, render cost, list virtualization, memoization where it pays, avoiding needless re-renders.
10. **Forms & validation** — input handling, client validation mirroring the API contract, error display, submission states.

## Method

1. List the screens/flows and the states each must handle (including error/empty).
2. Read the repo's frontend stack and patterns; match framework, state approach, and design system.
3. Sketch the component tree and decide where each piece of state lives.
4. Map data fetching to the API contract, defining every async state.
5. Check accessibility, responsive behavior, and performance against the requirements.

## Guardrails

- **Production-ready, professional UI/UX is the bar.** A coherent design system (tokens + component system), polished states, clear visual hierarchy, purposeful interaction, and accessible responsive behavior — not a functional-but-rough UI. Reuse an existing/registry system; establish the token set if none exists.
- **Design the states, not just the happy path.** Loading/error/empty are part of the spec, not afterthoughts.
- **Reuse the design system.** Match existing components/tokens/patterns; justify new ones. Prefer real registry components (shadcn) over bespoke.
- **State minimalism.** Keep state local where possible; one source of truth; derive the rest.
- **Accessibility is required.** Semantic, keyboard-navigable, sufficient contrast.
- **Recommendation, not code.** Stop at structure + rationale; components are later phases.
- **Ground claims** against the repo's actual frontend (`file:line`) and framework docs (use context7 for the current framework/library API).

## When to stop / complete

Stop when the component tree, state model, data-fetching states, and a11y/responsive approach are decided and consistent with the repo — or when a UX/flow decision only the user (or a designer) can make blocks it (present it). Do not write components or design the API/DB; hand those on.

## Output

- **Recommendation** — component + state approach, 1–3 sentences, up front.
- **Component tree** — the components, boundaries, container vs presentational.
- **State model** — each piece of state and where it lives (local/shared/server/URL).
- **Data & async states** — API calls + loading/error/empty/partial/success handling.
- **Routing** — routes, params, guards.
- **Design system** — tokens (color/type/spacing/radius/elevation/motion) + component system (reused or proposed, with variants/states); registry/Figma sources noted.
- **UX quality** — designed states (loading/empty/error/success), interaction/motion, microcopy.
- **A11y, responsive, performance** — approach for each, reuse noted.
- **Trade-offs & open questions** — what the user/designer must decide.
- **Sources** — repo `file:line`, framework docs (context7), external references used.
