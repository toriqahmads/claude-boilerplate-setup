---
name: testing-ui-and-e2e
description: >
  Use when testing a built UI or a full user journey by driving a real browser — verifying
  the running app, not reading the code. Encodes best practice: test complete user flows
  end to end, assert every async state (loading/error/empty/partial/success), check
  accessibility (roles, keyboard, contrast via axe), responsive/cross-browser behavior, and
  guard against flakiness with role-based selectors and auto-waiting instead of arbitrary
  sleeps. Playwright by default (Cypress/others per the repo). Followed by the `qa-tester`
  agent. Triggers on "test the UI", "UI/UX testing", "E2E test", "end-to-end", "test the
  user flow", "Playwright test", "browser test".
---

# Testing UI and E2E

Craft for **driving the running app in a real browser** to prove a user can complete the
flows the spec promises — clicking, typing, navigating, and asserting what renders. Covers
component/UI behavior through full end-to-end journeys across the stack.

## Goal

Prove the user-facing behavior works as specified: each critical journey completes, every
state renders correctly, the UI is accessible and responsive, and regressions are caught by
a stable, non-flaky suite. A defect is any journey that fails, any state that breaks, or any
accessibility violation — reported with a reproduction (and a trace/screenshot).

## Stack

**Playwright** by default (`@playwright/test`) — cross-browser, auto-waiting, trace/video
on failure. Use Cypress, Selenium, or the repo's existing E2E tool if it already commits to
one. Component testing via the framework's tool (Playwright CT, Testing Library, Storybook
interaction tests). `axe-core` for accessibility. Match the repo's test layout; use context7
for the tool's exact API.

## What to test

1. **Critical user journeys** — the end-to-end flows from the spec's success criteria: sign
   in, the core task, edge paths. Test through the UI as a user, across page/route
   boundaries and real (or realistically stubbed) backends.
2. **Every async state** — loading, error, empty, partial, and success all render
   correctly (mirrors `implementing-frontend`). Force error/empty by controlling the
   backend or network, not just the happy path.
3. **Accessibility** — run `axe` on key screens; assert semantic roles, keyboard navigation
   (tab order, focus, escape), visible focus, and contrast. A11y failures are defects.
4. **Responsive & cross-browser** — key breakpoints (mobile/tablet/desktop) and the
   browsers the spec targets; assert layout doesn't break.
5. **Forms & validation** — client validation, error messaging, submission, i18n text
   rendering (including a longer-locale / RTL smoke check where the app is localized).
6. **Visual regression** (where the repo uses it) — snapshot key screens; review diffs.

## Method

1. Read the spec's success criteria + acceptance flows; list journeys and states in scope.
2. Stand up the app (dev server or built artifact) and seed test data / auth state.
3. Write each journey as a test using **role/label/text selectors** (`getByRole`,
   `getByLabel`) — never brittle CSS/XPath tied to structure.
4. Rely on the tool's **auto-waiting / web-first assertions**; never `sleep(n)` to "fix"
   timing. Isolate state between tests (fresh context/storage per test).
5. Run headless in CI + headed locally when debugging; capture trace/screenshot on failure.

## Guardrails

- **No arbitrary sleeps** — use auto-waiting and web-first assertions; a flaky test is a
  broken test. Retries mask flake, they don't fix it.
- **Stable selectors** — role/label/text or explicit `data-testid`, not
  structure-dependent CSS/XPath.
- **Isolated & deterministic** — each test owns its data and auth; fresh browser context;
  no order-dependence; control network/time where results would otherwise vary.
- **Test against non-prod** — a dev/staging/ephemeral environment with seeded data; no real
  user PII; no real secrets in committed tests.
- **Assert user-visible outcomes**, not implementation details — what the user sees and can
  do, not internal DOM plumbing.

## When to stop / complete

Complete when each in-scope journey has an E2E test that passes, all async states are
asserted, key screens pass `axe` and keyboard checks, responsive/cross-browser checks pass
at the targeted breakpoints/browsers, the suite runs stably (no flake) in CI, and the
persisted specs live in the repo's test tree. Report failures as defects with a trace/
screenshot repro. Stop and hand back if the app can't be run or a testing toolchain the plan
didn't scope is missing.

## Output

The persisted E2E/UI specs (paths), the run result (with traces/screenshots for failures),
each defect as a reproducible journey with expected vs actual, a11y findings, coverage
summary (journeys × states/breakpoints), and anything left for follow-up (e.g. a flaky area
needing a stable hook from the frontend executor).
