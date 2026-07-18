---
name: planning-each-phase
description: Use when running phase 3 of the planning workflow — turning an approved phase breakdown into one detailed implementation plan per phase. Delegates to superpowers:writing-plans when installed; otherwise asks to install it or writes plans inline (TDD, bite-sized steps, no placeholders). Triggers on "write the plans", "plan each phase", after a breakdown is approved.
---

# Planning Each Phase

## Overview

Phase 3 of the planning workflow. Turn the approved breakdown into **one implementation plan
per phase** — each plan self-contained, TDD-structured, and buildable by an engineer with zero
prior context. Reached from `breaking-down-into-phases`.

One plan per phase keeps each plan focused and current: plan a phase, and later phases' plans
reflect the reality earlier phases established.

## Delegation decision

Check whether the `superpowers` plugin's writing-plans skill is available:

```bash
ls ~/.claude/plugins/cache/*/superpowers/*/skills/writing-plans/SKILL.md 2>/dev/null \
  && grep -q '"superpowers@claude-plugins-official": true' ~/.claude/settings.json && echo use-superpowers
```

- **Available** → **REQUIRED SUB-SKILL:** use `superpowers:writing-plans` for each phase. Save
  each plan to `docs/plan/phases/<N-slug>/plan.md` (its skill honors user location preference).
- **Not available** → ask the user, in one message:
  > "The `superpowers` plugin isn't installed — its `writing-plans` skill runs this best. Want
  > to install it first, or should I continue writing plans inline with the same structure?"
  Install chosen → wait, then delegate. Continue chosen → run the inline fallback below.

## Workflow

Do these in order. Create a todo per step.

1. **Read the approved breakdown.** Load `docs/plan/breakdown/…-breakdown.md`; take the ordered
   phase list and the produced/consumed interfaces.
2. **Plan each phase** (in order; **one at a time** recommended so later plans reflect earlier
   phases' reality — offer to pause between them). For each phase, delegate or run the inline
   fallback, saving to `docs/plan/phases/<N-slug>/plan.md`.
3. **Carry cross-phase interfaces.** Each phase's plan must reference the interfaces **produced
   by earlier phases** (from the breakdown), with exact names/types, so the plans compose.
   **For a backend/frontend contract-seam split** (see `breaking-down-into-phases` and
   `coordinating-api-contract`): both plans list the frozen contract artifact
   (`docs/plan/contracts/<feature>.*`) in their *Consumes from earlier phases* block. The
   **frontend plan** includes a task to stand up the contract-derived mock (Prism / OpenAPI mock /
   generated MSW handlers / types) and consumer-parity tests; the **backend plan** includes
   provider-conformance tests (responses validate against the artifact). Neither plan may introduce
   a request/response shape absent from the contract — that's a change protocol, not a plan step.
4. **Execution handoff.** After each plan, offer execution options (see below).

## Inline fallback (per phase)

Mirrors `superpowers:writing-plans`. Write for an engineer who knows the toolset poorly and the
domain not at all — no unstated context. Fill [references/plan-template.md](references/plan-template.md);
for large plans, optionally dispatch [references/plan-reviewer-prompt.md](references/plan-reviewer-prompt.md)
after the self-review.

- **Map the file structure** first: which files are created/modified, one responsibility each.
- **Right-size tasks**: a task is the smallest unit carrying its own test cycle and worth a
  fresh reviewer's gate; each ends in an independently testable deliverable.
- **Plan header:**

  ```markdown
  # [Phase N: Name] Implementation Plan

  **Goal:** [one sentence]
  **Architecture:** [2-3 sentences]
  **Tech Stack:** [key tech]

  ## Consumes from earlier phases
  [exact interface names/types this phase depends on — from the breakdown]

  ## Global Constraints
  [project-wide requirements, exact values from the design — one line each]
  ```

- **Task structure** — each task is a full block. Bite-sized steps are one action, 2–5 min each:
  "write the failing test", "run it, see it fail", "minimal implementation to pass", "run, see it
  pass", "commit". Show **real code** in code steps and **exact commands + expected output**:

  ````markdown
  ### Task N: [Component Name]

  **Files:**
  - Create: `exact/path/to/file.ext`
  - Modify: `exact/path/to/existing.ext:123-145`
  - Test: `tests/exact/path/to/test.ext`

  **Interfaces:**
  - Consumes: [what this task uses from earlier tasks/phases — exact signatures]
  - Produces: [what later tasks/phases rely on — exact function names, parameter and return types]

  - [ ] **Step 1: Write the failing test**

  ```language
  // real test code — the actual assertion, not a description
  ```

  - [ ] **Step 2: Run test to verify it fails**

  Run: `<exact test command>`
  Expected: FAIL with "<expected message>"

  - [ ] **Step 3: Write minimal implementation**

  ```language
  // real implementation code
  ```

  - [ ] **Step 4: Run test to verify it passes**

  Run: `<exact test command>`
  Expected: PASS

  - [ ] **Step 5: Commit**

  ```bash
  git add <files>
  git commit -m "feat: <what this task delivers>"
  ```
  ````

- **Cover all test tiers** (from the design's Testing Strategy), described by behavior with real
  code: **unit tests** per task (the TDD steps above), **integration tests** where phases/units
  meet, and an **end-to-end test** proving the phase's user-visible behavior works through the
  real flow. The phase is not done until its E2E test passes.
- **Configure the coverage gate** as a concrete step: set the repo's coverage tool
  (jest/vitest `coverageThreshold`, `pytest --cov-fail-under=95`, `go test -cover` gate, nyc,
  JaCoCo, SimpleCov — detected, not imposed) so statements/branches/functions/lines each **fail
  below 95%**, **per-file for changed files** and **global** (global set at current coverage and
  ratcheted up, never regressing on a legacy repo). Every phase's done-criteria includes "coverage
  gate green". E2E/black-box is a separate functional gate, not counted toward the %.
- **No placeholders.** These are plan failures — never write them: "TBD" / "TODO" / "implement
  later"; "add appropriate error handling" / "add validation" / "handle edge cases"; "write tests
  for the above" (without the test code); "similar to Task N" (repeat the code — tasks may be read
  out of order); steps that say what to do without showing how; references to types/functions not
  defined in any task.

## Remember

- Exact file paths always.
- Complete code in every step — if a step changes code, show the code.
- Exact commands with expected output.
- **DRY** (no repeated logic), **YAGNI** (only what the spec asks), **KISS** (simplest thing that
  works), **SOLID** (single-responsibility units, clean interfaces), **TDD**, frequent commits.

## Self-review (per plan, fix inline)

After writing the plan, look at the phase's spec scope with fresh eyes and check the plan against
it. This is a checklist you run yourself — not a subagent dispatch. Fix issues inline; no need to
re-review.

1. **Spec coverage** — skim every requirement in this phase's scope (from the breakdown/design).
   Can you point to a task that implements it? List and close any gaps — add the missing task.
2. **Test coverage** — does every requirement have a test at the right tier (unit / integration /
   E2E)? Is the phase's user-visible behavior covered end-to-end? Does the plan set the **≥95%
   coverage gate** (per-file for changed files + global ratchet) and include a step to configure it?
3. **Placeholder scan** — search for the "No placeholders" red flags above. Fix them.
4. **Type consistency** — do types, method signatures, and property names used in later tasks
   match what earlier tasks (and consumed earlier-phase interfaces) defined? A `clearLayers()` in
   Task 3 but `clearFullLayers()` in Task 7 is a bug — reconcile.
5. **Principle check** — no duplicated logic (DRY), no unrequested features (YAGNI), no needless
   complexity (KISS), units single-responsibility with clean seams (SOLID).

## Execution handoff

Once the plans are written and approved, execution is phase 4 — **REQUIRED SUB-SKILL:** use
`executing-phase-plans`. It runs the plans one per phase in dependency order, and chooses
worktree-or-not and subagent-driven-vs-inline execution (delegating to
`superpowers:subagent-driven-development` / `superpowers:executing-plans` when installed, else
mirroring them). Don't hand-execute a merged plan here.

## Common Mistakes

- One giant plan covering all phases instead of one plan per phase.
- Placeholders instead of real code and exact commands.
- A plan that references an interface no earlier phase's plan produced.
- Type/name drift — `clearLayers()` in one task, `clearFullLayers()` in another.
- Planning all phases up front when planning one at a time would keep later plans accurate.

## Output

One `plan.md` per phase under `docs/plan/phases/<N-slug>/`, each independently executable and
composing with the others via the breakdown's interfaces.
