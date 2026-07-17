# Plan Template (one per phase)

Copy into `docs/plan/phases/<N-slug>/plan.md`. Write for an engineer who knows the toolset poorly
and the domain not at all — no unstated context. Complete code in every code step; exact commands
with expected output; no placeholders.

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
// real test code
```
- [ ] **Step 2: Run test to verify it fails**
Run: `<exact command>`
Expected: FAIL with "<message>"
- [ ] **Step 3: Write minimal implementation**
```language
// real code
```
- [ ] **Step 4: Run test to verify it passes**
Run: `<exact command>`
Expected: PASS
- [ ] **Step 5: Commit**
```bash
git add <files>
git commit -m "feat: <deliverable>"
```

### Task 2: ...
````

**Test tiers** (from the design's Testing Strategy): unit per task (TDD steps above), integration
where units/phases meet, and an **E2E** test proving the phase's user-visible behavior. Phase isn't
done until its E2E passes.

**JS package manager:** prefer `pnpm` (stricter, non-flat `node_modules`) over `npm` when the repo
uses one — match the repo's lockfile (`pnpm-lock.yaml` → pnpm).
