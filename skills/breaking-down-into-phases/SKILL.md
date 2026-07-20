---
name: breaking-down-into-phases
description: >
  Use when running phase 2 of the planning workflow — splitting an approved design into
  N contextful, independently buildable phases with clear interfaces, ordering, and
  dependencies, written to a breakdown doc, self-reviewed, then approved by the user.
  Triggers on "break this design into phases", "decompose this before planning", "split
  the design into phases", "phase this out", "how many phases should this be", after a
  design doc is approved.
---

# Breaking Down into Phases

## Overview

Phase 2 of the planning workflow. Split the approved design into **N contextful phases** —
each a coherent chunk with one clear purpose, well-defined interfaces, and an
independently buildable/testable deliverable, small enough to hold in context and plan on
its own. Order them and record dependencies. Reached from `brainstorming-a-goal`.

Why a dedicated phase: a large design planned as one document overflows context and buries
interfaces — splitting first keeps each later plan focused and each phase reviewable alone.

## Workflow

Do these in order. Create a todo per step.

1. **Read the approved design + its complexity tier.** Load `docs/plan/specs/…-design.md` —
   the source of truth for scope; the breakdown must cover it, no more, no less. Read the
   **tier** from the design header (set by `planning-work-in-phases` Step 0.5) — it caps
   the phase count.
2. **Identify the phases — the tier bounds how many.** Decompose by responsibility and
   boundaries, not by technical layer. Each phase = a clear purpose + defined interfaces +
   a self-contained, testable deliverable. Files/concerns that change together stay together.
   - **Small tier → exactly one phase.** Don't split — one phase → one plan → one build →
     one review. Splitting a Small goal is the over-decomposition that makes a quiz feature
     cost hours.
   - **Standard → 2–3 phases. Large → N.** Split only when a boundary is real (independently
     buildable and testable), never to look thorough.

   **Exception — API-contract seam (enables parallel backend + frontend).** A user-facing
   feature with a clean API seam and substantial work on both sides MAY split into a
   **backend (provider) track** and a **frontend (consumer) track** as separate phases —
   *the frozen API contract IS the clean interface that makes them independently
   buildable*, this skill's own bar, not a layer-split anti-pattern. Conditions: the
   contract artifact (`docs/plan/contracts/<feature>.*`) is authored and frozen first
   (the produced/consumed interface between the two tracks), the frontend track builds
   against a contract-derived mock, both carry conformance tests. Record the contract as
   **produced by** the design/contract phase, **consumed by** both tracks; mark both
   parallel-eligible (contract-isolated, separate worktrees) so `executing-phase-plans`
   can run them concurrently. See `coordinating-api-contract`. Thin side → keep the
   vertical slice, don't force the split.
3. **Order them and map dependencies.** What must land before what, and why. Prefer an
   order where each phase produces working, testable software and later ones consume it.
4. **Write the breakdown doc.** Save to `docs/plan/breakdown/YYYY-MM-DD-<topic>-breakdown.md`
   — fill [references/breakdown-template.md](references/breakdown-template.md):
   - **Goal recap** — one paragraph, and a link to the design doc.
   - **Phase list** — for each phase: name + slug, purpose, **scope (in/out)**,
     **interfaces produced** (names/types later phases rely on), **interfaces consumed**
     (from earlier phases), **dependencies**, **order**, **done-criteria**.
   - **Sequencing notes** — the dependency graph / build order in prose.
5. **Self-review.** Fresh eyes, fix inline:
   - **Coverage** — does the union of phases cover the whole design? Gaps or overlaps?
   - **Boundaries** — is each phase isolatable with a clean interface, understandable alone?
   - **Dependencies** — is the order satisfiable (no cycles, nothing consumed before produced)?
   - **Sizing** — is any phase too big to hold in context, or so small it should merge?
   - **Placeholder scan** — no TBD/TODO/vague scope.
6. **User review gate.** Only **after self-review passes**, ask:
   > "Breakdown written to `<path>` — <N> phases. Please review the phases, order, and
   > boundaries before I write plans. Let me know any changes."
   Wait. **Revision** → ask for specifics + any more context needed, revise, re-run the
   self-review. **Rejected** → decomposition missed intent; rethink boundaries from the
   design. Loop until approved.

## Common Mistakes

- Splitting by technical layer (all models, then all controllers) instead of by
  deliverable — **except** the sanctioned contract-seam split above, where a **frozen API
  contract** is the clean interface making both tracks independently buildable.
- Splitting backend/frontend tracks **without** a frozen contract artifact — that's a
  layer-split with hidden coupling, not the sanctioned seam. Freeze the contract first, or
  keep the slice vertical.
- Phases that can't be built or tested independently — hidden cross-coupling.
- Consuming an interface a later phase produces (dependency cycle / wrong order).
- Gaps or overlaps vs. the design — the union must equal the whole.
- Asking the user to review before running the self-review.
- Forcing multiple phases onto a goal that's genuinely one phase.

## Output

Approved breakdown at `docs/plan/breakdown/YYYY-MM-DD-<topic>-breakdown.md`, listing
ordered phases with interfaces and dependencies. Then transition → **REQUIRED SUB-SKILL:**
`planning-each-phase`.
</content>
