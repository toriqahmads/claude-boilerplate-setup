# Plan Template (one per phase)

Copy into `docs/plan/phases/<N-slug>/plan.md`. Write for an engineer who knows the toolset poorly
and the domain not at all — no unstated context. Signatures + test cases (behavior + expected I/O)
in every code step; exact commands with expected output; **no full bodies, no vague placeholders**
(execution writes the bodies).

**Test-command discipline (execution speed):** each task's Step 2/4 commands are **focused** — the
single test file/case, fail-fast — **never the whole suite**. The full suite + coverage runs **once**
at the phase gate (the *Phase done-criteria* block below). **Task sizing:** for Small/Standard tiers
keep tasks coarse (one meaningful testable deliverable each, not one micro-action) — every task is a
round-trip + test run + commit.

````markdown
# Phase <N>: <Name> — Implementation Plan

**Goal:** <one sentence>
**Architecture:** <2-3 sentences>
**Tech Stack:** <key tech>

## Consumes from earlier phases
<exact interface names/types this phase depends on — from the breakdown>

## Global Constraints
<project-wide requirements, exact values from the design — one line each>

---

### Task 1: <Component>

**Files:**
- Create: `exact/path/to/file.ext`
- Modify: `exact/path/to/existing.ext:123-145`
- Test: `tests/exact/path/to/test.ext`

**Interfaces:**
- Consumes: <exact signatures used from earlier tasks/phases>
- Produces: <exact names, params, return types later tasks/phases rely on>

- [ ] **Step 1: Write the failing test**
```language
// test case: call, expected output/error, edge cases — not the full body
```
- [ ] **Step 2: Run test to verify it fails**
Run: `<focused command — this test file/case only, fail-fast; NOT the whole suite>`
Expected: FAIL with "<message>"
- [ ] **Step 3: Write minimal implementation**
```language
// signature + one-line behavior — body written at execution
```
- [ ] **Step 4: Run test to verify it passes**
Run: `<same focused command as Step 2>`
Expected: PASS
- [ ] **Step 5: Commit**
```bash
git add <files>
git commit -m "feat: <deliverable>"
```

### Task 2: ...

---

## Phase done-criteria (run ONCE, at the phase gate — not per task)

- [ ] **Full suite + coverage** — `<full test command with coverage, e.g. pnpm test --coverage /
  pytest --cov --cov-fail-under=95 / go test ./... -cover>` → all green, **≥95%** per changed file
  + global not regressed.
- [ ] **E2E** — `<e2e command>` proving the phase's user-visible behavior (once, here — not per task).
- [ ] Lint / format / build clean.
````

**Test tiers** (from the design's Testing Strategy): unit per task (TDD steps above), integration
where units/phases meet, and an **E2E** test proving the phase's user-visible behavior. Phase isn't
done until its E2E passes.

**JS package manager:** prefer `pnpm` (stricter, non-flat `node_modules`) over `npm` when the repo
uses one — match the repo's lockfile (`pnpm-lock.yaml` → pnpm).
