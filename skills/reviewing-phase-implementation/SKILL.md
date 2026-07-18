---
name: reviewing-phase-implementation
description: Use when running phase 5 of the planning workflow — reviewing the code produced by executing-phase-plans across seven dimensions (correctness, code quality, brainstorm+plan criteria, project conventions, architecture, design patterns, security) against the design doc and phase plan, first by an agent code reviewer then by the user, with a fully-autonomous option. Security runs as its own pass (security-review skill or a dedicated agent). On approval, marks the plan done and stamps progress.md with a timestamp. Uses the official Claude code-review skill or superpowers:requesting-code-review when available, else a built-in reviewer. Triggers on "review the implementation", "code review after build", "review phase N".
---

# Reviewing Phase Implementation

## Overview

Phase 5 of the planning workflow — the review gate. After `executing-phase-plans` builds a
phase, verify the code **against the design doc and that phase's plan** before it is considered
done. Reached from `executing-phase-plans`.

This gate is what makes the loop an engineering loop, not a one-shot: it closes the implementation
back onto **phase 1 (the spec)** and **phase 3 (the plan)**. Measure the built code against the
design doc's acceptance criteria (GIVEN/WHEN/THEN) and Testing Strategy, and against the plan's
Global Constraints and interfaces. Divergence from the spec is a review failure — fix it, or if
the divergence is right, loop back and update the spec/plan (see below). Skipping review here is
the fast path to shipping the wrong thing well-built.

## Two review passes

1. **Agent code reviewer** (always).
2. **User review** (unless autonomous mode is chosen).

**Ask up front — one question:**
> "Review mode for this phase: **human-in-the-loop** (I run an agent review, fix findings, then
> you approve) or **fully autonomous** (agent review only; auto-approve when the review comes back
> clean)?"

Default **human-in-the-loop** — this is a crucial gate. Autonomous is allowed only when the user
opts in (or has delegated the choice / you are running autonomously by instruction).

## Reviewer selection (fallback order)

Which tool performs the agent review — use the first available:

1. **Official Claude `code-review` skill** — invoke it on the phase diff; add `security-review`
   for security-sensitive changes.
2. **`superpowers:requesting-code-review`** — dispatch a code-reviewer subagent via its
   `code-reviewer.md` template, given the diff + requirements.
3. **Built-in `code-reviewer-agent`** — dispatch this repo's dedicated phase-5 code reviewer
   (Agent tool), scoped to the diff (never your session history). It follows this skill's rubric
   and [references/code-reviewer-prompt.md](references/code-reviewer-prompt.md), owns dimensions
   1–6, and returns APPROVE/REVISE with Critical/Important/Minor findings. (If it's somehow
   unavailable, fall back to a `general-purpose` subagent with the same reference prompt.)

Detect superpowers as in the other phase skills (glob its skills dir + grep `enabledPlugins`).

## What the review checks (rubric)

Review against the design doc (`docs/plan/specs/…`) **and** the phase plan
(`docs/plan/phases/<N-slug>/plan.md`). Cover all seven dimensions:

1. **Code review (correctness)** — logic, edge cases, error handling, and the actual diff behave
   per the contract.
   - **Correctness** — logic, edge cases, error handling per the contract.
   - **Tests** — unit / integration / **E2E** present and passing at the tiers the Testing Strategy names.
   - **Coverage** — the ≥95% gate holds: every changed file ≥95% (statements/branches/functions/
     lines) and the global total not regressed. A **changed file under 95%** or a **global
     regression** is a **blocking** finding — Important, or **Critical** if it drops the global
     bar. Verify from the coverage report, not by eye.
2. **Code quality** — readable, focused units; no dead code, no duplication, no needless complexity.
   - **Quality** — DRY, YAGNI, KISS, SOLID; clean interfaces matching the breakdown.
3. **Criteria from brainstorming + planning** — the built code satisfies what the spec and plan asked for.
   - **Spec compliance** — every requirement in scope met; nothing extra built (no over/under-build).
   - **Acceptance criteria** — the design's GIVEN/WHEN/THEN behaviors hold.
   - **Constraints** — the plan's Global Constraints honored (exact values/formats).
4. **Code of conduct / project conventions** — matches this project's established style and rules:
   read `CLAUDE.md` / `AGENTS.md`, linters/formatters config, and neighboring code. Naming,
   layout, commit style, and idioms fit the surrounding codebase — not a foreign style.
5. **Architecture** — fits the system's architecture and module boundaries; dependencies point the
   right way; no layering violations; interfaces match the breakdown; changes live where they belong.
6. **Design patterns** — appropriate, consistently applied patterns; no anti-patterns (god objects,
   tight coupling, leaky abstractions); reuses existing patterns rather than inventing parallel ones.
7. **Security vulnerabilities** — run as its own pass (see below).
   - **Security** — input validation, secrets, authz where relevant.

Grade findings **Critical / Important / Minor** across every dimension.

## Security pass (its own skill / agent)

Run security as a **dedicated pass**, not a bullet folded into the general review — it needs a
distinct lens and its own reviewer. Use the first available:

1. **Official Claude `security-review` skill** — invoke it on the phase diff.
2. **Built-in `security-reviewer-agent`** — dispatch this repo's dedicated phase-5 security
   reviewer/pentester (Agent tool), scoped to the diff, tasked only with vulnerability review:
   injection (SQL/command/XSS), authn/authz gaps and IDOR, secrets in code, unsafe
   deserialization, path traversal, SSRF, missing input validation, insecure crypto, dependency/
   config risks, and anything in the project's threat model. It follows
   `finding-security-vulnerabilities`, may run read-only SAST/SCA/secret scanners, and rates
   findings by severity. (If unavailable, fall back to a `general-purpose` security-focused agent.)

Run it in parallel with the general agent review (Step 1); merge its findings into the same
Critical/Important/Minor list. **Critical security findings block approval** — no autonomous
auto-approve past an open Critical.

**Deeper audit (optional — ask the user):** when the phase touches auth, crypto, payments, PII,
file uploads, or external input, or the pass flags something needing investigation, offer a full
audit via **`finding-security-vulnerabilities`**. Ask before running it (it's heavier); on yes, its
assessment doc feeds remediation back through the planning workflow rather than being fixed inline.

## Functional QA pass (its own agent)

Run functional QA as a **dedicated pass too** — the code review reads the code; QA **runs the
built app** and proves it behaves. Dispatch the **`qa-tester`** agent, scoped to the phase's
surface, to black-box test the running implementation against the spec's success criteria and the
plan's Testing Strategy:

- **API** — status/schema/error semantics, auth and cross-user IDOR negatives, validation,
  idempotency, verified against the frozen contract artifact `docs/plan/contracts/<feature>.*`
  (`testing-apis`).
- **Contract conformance (both sides)** — for a backend/frontend seam, gate **provider
  conformance** (backend responses validate against the contract) **and** **consumer parity**
  (the frontend's mock/fixtures/types validate against the same contract), plus a **drift check**
  (served/generated spec == committed artifact). Any mismatch — doc vs code, mock vs provider — is
  a **blocking** finding (`coordinating-api-contract`).
- **UI / E2E** — the critical user journeys, every async state, accessibility, and
  responsive/cross-browser behavior via Playwright (`testing-ui-and-e2e`).

It writes a persisted, non-flaky regression suite (test files only — never app source) and returns
a QA verdict: pass/fail per criterion + defects with reproduction. Run it in parallel with the
general and security passes; merge its defects into the same Critical/Important/Minor list.
**A failing in-scope success criterion blocks approval** — a green code review over a build that
doesn't actually work is not done. Fix via the executor (QA reports bugs, it doesn't fix them),
then re-run QA. Skip only when the phase ships no runnable surface (e.g. pure docs/config) — say so.

## The process

### Step 1: Agent review

1. **Determine the diff range** — read `docs/plan/phases/<N-slug>/progress.md` for the phase's
   commit range, or `git merge-base <base> HEAD`..`HEAD`.
2. **Run the chosen reviewer** on that diff across dimensions 1–6, handing it the design doc +
   this phase's plan + the project's `CLAUDE.md`/conventions as the requirements it verifies
   against. **In parallel, run the security pass** (dimension 7) via its own skill/agent **and the
   functional QA pass** (`qa-tester`) against the running build. Merge all findings, graded
   **Critical / Important / Minor**.
3. **Act on findings with technical rigor** (mirrors `superpowers:receiving-code-review` — use it
   if installed): read fully, verify each finding against the codebase before implementing, push
   back with technical reasoning when a finding is wrong, no performative agreement. Fix
   **Critical + Important** (dispatch a fix, then **re-review** until clean); record **Minor** in
   `progress.md` for triage.
4. Loop until the agent review is clean (or only accepted Minors remain).

### Step 2: User review

Skip entirely in autonomous mode. Otherwise:

- Present a concise summary: what the agent review found, how each Critical/Important was resolved,
  remaining Minors, and where to see the diff. Ask the user to review.
- **Approved** → Step 3. **Changes requested** → ask for specifics, apply with the same rigor,
  re-run Step 1's reviewer, re-present. **Rejected** → treat as a spec/plan problem; loop back
  (below) rather than patching blindly.

### Step 3: On pass + approval — mark done + stamp

Only once the phase is approved (by the user, or by a clean autonomous review):

1. **Mark the plan done.** In `docs/plan/phases/<N-slug>/plan.md`, add a status line under the
   header: `> **Status:** DONE — reviewed & approved <timestamp>`, and ensure every task checkbox
   is checked.
2. **Stamp progress.** Append to `docs/plan/phases/<N-slug>/progress.md` a review record with a
   real timestamp — get it from `date -u +%Y-%m-%dT%H:%M:%SZ` — noting reviewer(s) used, mode
   (autonomous / human-approved), verdict, and any accepted Minors deferred.
3. **Commit** both doc updates.
4. If phases remain unreviewed, continue with the next; when all phases pass, offer a final
   **whole-branch** review, then the finish/merge step of `executing-phase-plans`
   (`superpowers:finishing-a-development-branch` when present).

## When to loop back to earlier phases

Review is where spec/plan defects surface. Don't patch around them:
- **Missing/ambiguous requirement** revealed by the code → back to `brainstorming-a-goal` to update
  the design doc, then re-plan the affected phase.
- **Wrong task decomposition / interface** → back to `planning-each-phase` (or
  `breaking-down-into-phases` if the phase boundaries themselves are wrong).
- Re-run this review after the loop-back lands.

## Remember

- Cover all seven dimensions: correctness, code quality, brainstorm+plan criteria, project
  conventions/code-of-conduct, architecture, design patterns, and security.
- Run **security as its own pass** (official `security-review` skill or a dedicated agent);
  Critical security findings block approval.
- Review against the **design doc and the plan**, not just "does it look fine" — spec compliance is
  the point.
- Agent review first, then user review — unless the user opted into fully autonomous.
- Fix Critical + Important and **re-review**; never proceed with them open.
- Apply feedback with verification and technical reasoning; no performative agreement.
- On approval, **mark the plan DONE and stamp `progress.md` with a real timestamp** (`date -u`), then commit.
- A spec/plan defect loops back to phase 1/3 — don't paper over it in the diff.

## Common Mistakes

- Reviewing code in the abstract instead of against the design doc + plan.
- Folding security into the general review instead of running it as its own pass (skill/agent).
- Checking correctness only — skipping conventions, architecture, or design-pattern dimensions.
- Skipping the agent pass and going straight to the user (or vice-versa when human-in-the-loop was chosen).
- Auto-approving without the user having opted into autonomous mode.
- Marking the plan done but forgetting to stamp `progress.md`, or stamping a fabricated timestamp
  instead of `date -u` output.
- Patching a spec-level gap in the diff instead of updating the spec/plan and re-planning.

## Output

Each phase reviewed (agent + optionally user) against its spec and plan, findings resolved, its
`plan.md` marked `Status: DONE` and its `progress.md` stamped with the approval timestamp and
reviewer(s) — all committed. Approved phases → ready for the finish/merge step.
