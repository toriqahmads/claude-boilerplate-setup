---
name: planning-each-phase
description: >
  Use when running phase 3 of the planning workflow — turning an approved phase breakdown into one detailed implementation plan per phase. Synonyms/triggers: "write the plan(s)", "plan each phase", "create the implementation plan", "generate plan.md", "TDD plan for this phase", "break the phase into tasks/steps" — typically right after a breakdown is approved. Delegates to superpowers:writing-plans when installed; otherwise asks to install it or writes plans inline (TDD, bite-sized steps, no placeholders).
---

# Planning Each Phase

## Overview

Phase 3 of the planning workflow: turn the approved breakdown into **one implementation plan per phase** — self-contained, TDD-structured, buildable by an engineer with zero prior context. Reached from `breaking-down-into-phases`. One plan per phase keeps plans current — later plans reflect what earlier phases actually established.

## Delegation decision

Check whether `superpowers`' writing-plans skill is available:

```bash
ls ~/.claude/plugins/cache/*/superpowers/*/skills/writing-plans/SKILL.md 2>/dev/null \
  && grep -q '"superpowers@claude-plugins-official": true' ~/.claude/settings.json && echo use-superpowers
```

- **Available** → **REQUIRED SUB-SKILL:** use `superpowers:writing-plans` per phase, saving to `docs/plan/phases/<N-slug>/plan.md` (honors user location preference). **Defer bodies:** signatures/skeletons + test cases (behavior + expected I/O) only — same no-full-body rule as the inline fallback. **Small tier:** also tell it to write lightweight (tier rule below) — no full per-task 5-step TDD blocks.
- **Not available** → ask, one message: "The `superpowers` plugin isn't installed — its `writing-plans` skill runs this best. Want to install it first, or should I continue writing plans inline with the same structure?" Install → wait, then delegate. Continue → run the inline fallback below.

## Workflow

Todo per step, in order:

1. **Read the approved breakdown + tier.** Load `docs/plan/breakdown/…-breakdown.md`: ordered phase list, produced/consumed interfaces, and the **complexity tier** (design header, set by `planning-work-in-phases` Step 0.5).
2. **Plan each phase** — delegate or run the inline fallback, saving to `docs/plan/phases/<N-slug>/plan.md`. **Cadence and granularity are tier-driven (canonical rule):**
   - **Small — lightweight plan.** One phase, one plan, single pass, no pause. Only **quality-bearing** content: exact file map, interfaces (consumed/produced), the **edge-case list**, done-criteria (full suite + **≥95% coverage gate** + **E2E**) — **not** full per-task 5-step TDD blocks. A Small phase executes as an inline **derive-then-TDD** pass (`executing-phase-plans`): the *same context* reading the plan writes the test/impl/commit steps, so pre-writing that scaffolding is ritual the executor already runs. **Canonical pattern** (singleflight, LRU/TTL, debounce, CRUD): name the pattern + its edges, don't spell out the algorithm. Cut scaffolding, never paths/interfaces/edges/gates/traceability.
   - **Standard/Large — full per-task blocks** (structure below). Plan **one at a time** in order (later plans reflect earlier reality); single-end-gate/autonomous → plan consecutively, no pause; per-phase gates → offer to pause. A **separate** executor/reviewer subagent consumes each plan across a context boundary, so the detailed blocks earn their cost as the hand-off contract.
3. **Carry cross-phase interfaces.** Each plan references interfaces **produced by earlier phases** (exact names/types from the breakdown) so plans compose. **Backend/frontend contract-seam split** (`breaking-down-into-phases`, `coordinating-api-contract`): both plans list the frozen contract artifact (`docs/plan/contracts/<feature>.*`) under *Consumes from earlier phases*. **Frontend plan** stands up the contract-derived mock (Prism / OpenAPI mock / generated MSW handlers / types) + consumer-parity tests; **backend plan** adds provider-conformance tests (responses validate against the artifact). Neither may introduce a shape absent from the contract — that's a change protocol, not a step.
4. **Execution handoff.** After each plan, offer execution options (below).

## Inline fallback (per phase)

Mirrors `superpowers:writing-plans`. Write for an engineer who knows the toolset poorly and the domain not at all — no unstated context. Fill [references/plan-template.md](references/plan-template.md); for large plans, optionally dispatch [references/plan-reviewer-prompt.md](references/plan-reviewer-prompt.md) after the self-review.

- **Map the file structure** first: files created/modified, one responsibility each.
- **Right-size tasks**: a unit carrying its own test cycle, worth a fresh reviewer's gate, ending in an independently testable deliverable. Prefer coarser tasks for Small/Standard — one deliverable per task, not one micro-action (every task is a model round-trip + test run + commit; over-granular tasks multiply that overhead). Split finer only for Large/high-risk, where per-task review earns it.
- **Focused test commands in the loop; one full-suite+coverage command at the gate.** Each task's test steps run **only that task's test** (single file/case, fail-fast — e.g. `vitest run x.test.ts`, `pytest x::test -x`, `go test ./pkg -run TestX`), **never the whole suite** per step — repeated suite sweeps are the dominant execution-time cost. The **done-criteria** carries the one full command — `<full suite + coverage>` — run once at the gate.
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

- **Task structure (Standard/Large)** — each task a full block; *Small skips these blocks* (tier rule above). Bite-sized steps, one action, 2–5 min each: "write the failing test", "run it, see it fail", "minimal implementation to pass", "run, see it pass", "commit". Exact **signatures** + **test cases** (behavior + expected I/O) + **exact commands + expected output** — **not** full function/test bodies; execution writes the bodies (TDD):

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
  // test case: the call under test, exact expected output/error, edge cases —
  // not the full body. Execution writes the assertions.
  ```

  - [ ] **Step 2: Run test to verify it fails**

  Run: `<exact **focused** test command — this file/case only, fail-fast; not the whole suite>`
  Expected: FAIL with "<expected message>"

  - [ ] **Step 3: Write minimal implementation**

  ```language
  // signature + one-line behavior (validate → do → return) — no body.
  // Execution writes the body.
  ```

  - [ ] **Step 4: Run test to verify it passes**

  Run: `<same **focused** test command as Step 2>`
  Expected: PASS

  - [ ] **Step 5: Commit**

  ```bash
  git add <files>
  git commit -m "feat: <what this task delivers>"
  ```
  ````

- **Cover all test tiers** (from the design's Testing Strategy), described by behavior (cases + expected I/O), not full code: **unit** per task (TDD steps above), **integration** where phases/units meet, an **end-to-end** test proving the phase's user-visible behavior through the real flow. Phase isn't done until its E2E test passes.
- **Configure the coverage gate** as a concrete step: set the repo's coverage tool (jest/vitest `coverageThreshold`, `pytest --cov-fail-under=95`, `go test -cover` gate, nyc, JaCoCo, SimpleCov — detected, not imposed) so statements/branches/functions/lines each **fail below 95%**, **per-file for changed files** and **global** (set at current coverage, ratcheted up, never regressing on a legacy repo). Every done-criteria includes "coverage gate green". E2E/black-box is a separate functional gate, not counted toward the %.
- **No vague placeholders.** Plan failures — never write: "TBD" / "TODO" / "implement later"; "add appropriate error handling" / "add validation" / "handle edge cases"; steps that say what to do without naming the signature/case; references to types/functions undefined by any task. (A concrete signature + described test case is **not** a placeholder — it's the required granularity. Full source bodies are the opposite failure: execution's job, not the plan's.)

## Remember

- Exact file paths always. **No full code bodies** — signature + behavior + exact I/O; execution writes the body.
- Exact commands with expected output — **focused test command per step**, the **full suite + coverage command only in the done-criteria** (once, at the gate).
- **DRY** (no repeated logic), **YAGNI** (only what the spec asks), **KISS** (simplest thing that works), **SOLID** (single-responsibility units, clean interfaces), **TDD**, frequent commits.
- **Tier the granularity** — Small = lightweight (file map + interfaces + edges + gates); full per-task 5-step blocks only for Standard/Large. Cut scaffolding, never quality-bearing content.

## Self-review (per plan, fix inline)

After writing, re-read the phase's spec scope fresh and check the plan against it — run yourself, not a subagent dispatch. Fix inline; no re-review needed.

1. **Spec coverage** — every requirement in scope maps to a task; add a task for any gap.
2. **Test coverage** — every requirement has a test at the right tier (unit/integration/E2E); the phase's user-visible behavior is covered end-to-end; the plan sets the **≥95% coverage gate** (per-file changed + global ratchet) with a configure step.
3. **Placeholder scan** — search for the "No vague placeholders" red flags above, and any full function/test bodies (execution's job). Fix both.
4. **Type consistency** — types/signatures/property names used in later tasks match what earlier tasks (and consumed earlier-phase interfaces) defined — e.g. `clearLayers()` in Task 3 vs `clearFullLayers()` in Task 7 is a bug, reconcile.
5. **Principle check** — DRY (no duplication), YAGNI (no unrequested features), KISS (no needless complexity), SOLID (single-responsibility, clean seams).

## Execution handoff

Once plans are written and approved, execution is phase 4 — **REQUIRED SUB-SKILL:** use `executing-phase-plans`. It runs the plans one per phase in dependency order and chooses worktree-or-not / subagent-driven-vs-inline execution (delegating to `superpowers:subagent-driven-development` / `superpowers:executing-plans` when installed, else mirroring them). Don't hand-execute a merged plan here.

## Common Mistakes

- One giant plan covering all phases instead of one plan per phase.
- Vague placeholders instead of concrete signatures/cases/commands.
- Pasting full implementation/test bodies — that's execution, not planning.
- A plan referencing an interface no earlier phase's plan produced.
- Type/name drift — `clearLayers()` in one task, `clearFullLayers()` in another.
- Planning all phases up front instead of one at a time (drifts from reality).
- **Full per-task 5-step TDD blocks on a Small inline task** — boilerplate the derive-then-TDD executor already runs; keep Small to file map + interfaces + edges + gates.

## Output

One `plan.md` per phase under `docs/plan/phases/<N-slug>/`, each independently executable and composing with the others via the breakdown's interfaces.
