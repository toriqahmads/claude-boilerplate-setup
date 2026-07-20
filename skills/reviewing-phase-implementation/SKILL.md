---
name: reviewing-phase-implementation
description: >
  Use when running phase 5 of the planning workflow — reviewing the code produced by
  executing-phase-plans against the design doc and phase plan, across seven dimensions
  (correctness, code quality, brainstorm+plan criteria, project conventions,
  architecture, design patterns, security), first by an agent code reviewer then by the
  user, with a fully-autonomous option. Security runs as its own pass (security-review
  skill or a dedicated agent, Critical blocks approval); functional QA runs as its own
  pass too. On approval, marks the plan done and stamps progress.md with a timestamp.
  Uses the official Claude code-review skill or superpowers:requesting-code-review when
  available, else built-in reviewer/security/QA agents. Triggers on "review the
  implementation", "code review after build", "review phase N", "phase 5 review",
  "review this build against the spec", "run the review gate", "security pass",
  "QA the build", "is this ready to merge".
---

# Reviewing Phase Implementation

## Overview

Phase 5 — the review gate. After `executing-phase-plans` builds a phase, verify the code
**against the design doc and that phase's plan** before it's done. Reached from
`executing-phase-plans`.

This closes the implementation back onto **phase 1 (spec)** and **phase 3 (plan)** — what
makes the loop an engineering loop, not a one-shot. Measure the build against the design's
acceptance criteria (GIVEN/WHEN/THEN) + Testing Strategy, and the plan's Global Constraints
+ interfaces. Divergence from the spec is a review failure — fix it, or if the divergence
is right, loop back and update the spec/plan (below). Skipping this gate ships the wrong
thing well-built.

## Scale the gate to the complexity tier

Read the **tier** (design/plan header, `planning-work-in-phases` Step 0.5) and **risk
flag**. The gate always runs; passes scale so a small feature isn't audited like payments:

| Tier | Code review (dims 1–6) | Security pass | Functional QA / E2E |
|---|---|---|---|
| **Small** | always | **only if risk-flagged** (auth/crypto/payments/PII/uploads/external input) | QA once; E2E once, at the end |
| **Standard** | always | if risk-flagged or security-relevant surface | QA per phase; E2E at end |
| **Large / high-risk** | always | **every phase** | QA + E2E per phase |

Two rules hold at **every** tier: the **≥95% coverage gate** (sub-95% changed file or global
regression blocks approval), and **any risk-flagged change gets the security pass**, even at
Small. Scale means skip *redundant* passes on low-risk surfaces — never skip security where
risk is real, never skip the final review, never drop coverage.

**E2E runs once, at the build's end** (unless Large/high-risk) — per-phase Playwright E2E
mostly re-proves the same journeys and is a top time cost.

## Two review passes

1. **Agent code reviewer** (always). 2. **User review** (unless autonomous).

**Ask up front — one question:**
> "Review mode for this phase: **human-in-the-loop** (I run an agent review, fix findings,
> then you approve) or **fully autonomous** (agent review only; auto-approve when clean)?"

Default **human-in-the-loop**. Autonomous only when the user opts in (or has delegated the
choice / you're running autonomously by instruction).

## Reviewer selection (fallback order)

1. **Official Claude `code-review` skill** — on the phase diff; add `security-review` for
   security-sensitive changes.
2. **`superpowers:requesting-code-review`** — dispatch a code-reviewer subagent via its
   `code-reviewer.md` template, given the diff + requirements.
3. **Built-in `code-reviewer-agent`** — dispatch (Agent tool), scoped to the diff only
   (never session history). Follows this skill's rubric +
   [references/code-reviewer-prompt.md](references/code-reviewer-prompt.md), owns
   dimensions 1–6, returns APPROVE/REVISE with Critical/Important/Minor findings. (If
   unavailable, fall back to `general-purpose` with the same reference prompt.)

Detect superpowers as in the other phase skills (glob its skills dir + grep `enabledPlugins`).

## What the review checks (rubric)

Review against the design doc (`docs/plan/specs/…`) **and** the phase plan
(`docs/plan/phases/<N-slug>/plan.md`) — all seven dimensions:

1. **Correctness** — logic, edge cases, error handling per the contract.
   - **Tests** — unit/integration/**E2E** present and passing at the Testing Strategy's tiers.
   - **Coverage** — ≥95% gate: every changed file ≥95% (statements/branches/functions/lines),
     global total not regressed. A **changed file under 95%** or **global regression** is
     **blocking** — Important, or **Critical** if it drops the global bar. Verify from the
     coverage report, not by eye.
2. **Code quality** — readable, focused units; no dead code/duplication/needless complexity;
   DRY, YAGNI, KISS, SOLID; clean interfaces matching the breakdown.
3. **Brainstorm/plan criteria** — **spec compliance** (every in-scope requirement met,
   nothing extra built), **acceptance criteria** (GIVEN/WHEN/THEN hold), **constraints**
   (plan's Global Constraints honored, exact values/formats).
4. **Conventions** — matches `CLAUDE.md`/`AGENTS.md`, linters/formatters config, neighboring
   code: naming, layout, commit style, idioms fit the codebase, not a foreign style.
5. **Architecture** — fits system structure/module boundaries; dependencies point the right
   way; no layering violations; interfaces match the breakdown; changes live where they belong.
6. **Design patterns** — appropriate, consistent; no anti-patterns (god objects, tight
   coupling, leaky abstractions); reuses existing patterns over inventing parallel ones.
7. **Security** — its own pass (below).

Grade findings **Critical / Important / Minor** across every dimension.

## Security pass (its own skill / agent)

**When:** every phase for Large/high-risk; for Small/Standard, when the change is
**risk-flagged** (auth, crypto, payments, PII, file uploads, untrusted external input) or
touches a security-relevant surface. A low-risk Small feature (e.g. quiz list/browse CRUD)
skips it — but Small + **grading/submission/scoring** is risk-flagged and gets it. When in
doubt, run it.

Run as a **dedicated pass**, not a bullet in the general review — distinct lens, own
reviewer. First available:

1. **Official Claude `security-review` skill** — on the phase diff.
2. **Built-in `security-reviewer-agent`** — dispatch (Agent tool), scoped to the diff,
   vulnerability review only: injection (SQL/command/XSS), authn/authz gaps and IDOR,
   secrets in code, unsafe deserialization, path traversal, SSRF, missing input validation,
   insecure crypto, dependency/config risks, project threat model. Follows
   `finding-security-vulnerabilities`, may run read-only SAST/SCA/secret scanners, rates by
   severity. (If unavailable, fall back to a `general-purpose` security-focused agent.)

Run in parallel with the general review; merge findings into the same list. **Critical
security findings block approval** — no autonomous auto-approve past an open Critical.

**Deeper audit (optional, ask first):** touches auth/crypto/payments/PII/uploads/external
input, or the pass flags something needing investigation → offer a full
**`finding-security-vulnerabilities`** audit. Ask before running (heavier); its assessment
doc feeds remediation back through the planning workflow rather than being fixed inline.

## Functional QA pass (its own agent)

Dedicated pass too — code review reads the code; QA **runs the app**. Dispatch
**`qa-tester`**, scoped to the phase's surface, black-box against the spec's success
criteria and the plan's Testing Strategy:

- **API** — status/schema/error semantics, auth + cross-user IDOR negatives, validation,
  idempotency, vs the frozen contract `docs/plan/contracts/<feature>.*` (`testing-apis`).
- **Contract conformance (both sides)** — for a backend/frontend seam: **provider
  conformance** (backend responses validate against the contract), **consumer parity**
  (frontend mock/fixtures/types validate against it), **drift check** (served/generated spec
  == committed artifact). Any mismatch is **blocking** (`coordinating-api-contract`).
- **UI / E2E** — critical journeys, every async state, accessibility, responsive/
  cross-browser via Playwright (`testing-ui-and-e2e`). **Once at the build's end for
  Small/Standard** (per phase only for Large/high-risk); API/contract checks still run per
  phase, browser E2E batches to the end.

Writes a persisted, non-flaky regression suite (test files only, never app source); returns
pass/fail per criterion + defects with reproduction. Runs in parallel with the other passes;
merge defects into the same list. **A failing in-scope criterion blocks approval** — green
code review over a build that doesn't work isn't done. Fix via the executor (QA reports,
doesn't fix), then **re-run only the affected criteria** — not the whole suite. Skip QA
entirely when the phase ships no runnable surface (pure docs/config) — say so.

## The process

### Step 1: Agent review

1. **Determine the diff range** — `docs/plan/phases/<N-slug>/progress.md`'s commit range, or
   `git merge-base <base> HEAD`..`HEAD`.
2. **Run the chosen reviewer** on dimensions 1–6, given the design doc + phase plan +
   `CLAUDE.md`/conventions as requirements. **In parallel:** security pass (dimension 7) and
   `qa-tester` against the running build — **each gated by the tier table** (security only
   if risk-flagged at Small/Standard; E2E once at the end for Small/Standard). Merge all
   findings, graded **Critical/Important/Minor**.
3. **Act with technical rigor** (mirrors `superpowers:receiving-code-review` if installed):
   read fully, verify each finding against the codebase, push back with reasoning when wrong
   — no performative agreement. Fix **Critical + Important** (dispatch a fix, **re-review**);
   record **Minor** in `progress.md` for triage.
4. **Re-review only the fix delta.** First pass audits the full diff; later passes verify
   just the **changed lines** landed and introduced no regression — never re-audit unchanged
   code that already passed. Loop until clean (or only accepted Minors remain), **cap at 2
   re-review rounds** — recurring findings past that means the review is thrashing (spec/plan
   defect or disputed finding): stop, **escalate to the user**.

### Step 2: User review

Skip in autonomous mode. Otherwise: present what the agent review found, how each
Critical/Important was resolved, remaining Minors, and where to see the diff.
**Approved** → Step 3. **Changes requested** → apply with the same rigor, re-run Step 1,
re-present. **Rejected** → spec/plan problem, loop back (below), don't patch blindly.

### Step 3: On pass + approval — mark done + stamp

1. **Mark the plan done** — in `plan.md`, add `> **Status:** DONE — reviewed & approved
   <timestamp>` under the header, check every task box.
2. **Stamp progress** — append a review record to `progress.md` with a real timestamp
   (`date -u +%Y-%m-%dT%H:%M:%SZ`): reviewer(s), mode (autonomous/human-approved), verdict,
   accepted Minors deferred.
3. **Commit** both doc updates.
4. Continue to the next unreviewed phase; once all pass, offer a final **whole-branch**
   review, then the finish/merge step of `executing-phase-plans`
   (`superpowers:finishing-a-development-branch` when present).

## When to loop back to earlier phases

- **Missing/ambiguous requirement** revealed by the code → `brainstorming-a-goal` to update
  the design doc, then re-plan the affected phase.
- **Wrong task decomposition/interface** → `planning-each-phase` (or
  `breaking-down-into-phases` if phase boundaries are wrong).
- Re-run this review after the loop-back lands.

## Remember

- All seven dimensions; security as its **own pass**, Critical blocks approval.
- Review against the **design doc and plan**, not "does it look fine."
- Agent review first, then user review, unless autonomous was chosen.
- Fix Critical + Important, **re-review the fix delta only**, **cap at 2 rounds**, escalate
  thrashing reviews. Re-run only **affected** QA criteria.
- Apply feedback with verification and reasoning — no performative agreement.
- On approval: mark **DONE**, stamp `progress.md` with real `date -u`, commit.
- A spec/plan defect loops back to phase 1/3 — don't paper over it in the diff.

## Common Mistakes

- Reviewing code in the abstract instead of against the design doc + plan.
- Folding security into the general review instead of its own pass.
- Correctness only — skipping conventions, architecture, design-pattern dimensions.
- Skipping the agent pass, or auto-approving without the user opting into autonomous mode.
- Marking done but forgetting to stamp `progress.md`, or faking the timestamp.
- Patching a spec-level gap in the diff instead of updating the spec/plan.
- **Re-auditing the whole diff on every re-review**, or looping fixes with no cap — recurring
  past 2 rounds is thrashing, escalate. Re-running the **whole** QA suite after a one-line fix.

## Output

Each phase reviewed (agent + optionally user) against spec and plan, findings resolved,
`plan.md` marked `Status: DONE`, `progress.md` stamped with timestamp + reviewer(s) — all
committed. Approved phases → ready for the finish/merge step.
</content>
