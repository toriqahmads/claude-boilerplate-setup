---
name: breaking-down-into-phases
description: Use when running phase 2 of the planning workflow — splitting an approved design into N contextful, independently buildable phases with clear interfaces, ordering, and dependencies, written to a breakdown doc, self-reviewed, then approved by the user. Triggers on "break this design into phases", "decompose this before planning", after a design doc is approved.
---

# Breaking Down into Phases

## Overview

Phase 2 of the planning workflow. Split the approved design into **N contextful phases** —
each a coherent chunk with one clear purpose, well-defined interfaces, and an independently
buildable/testable deliverable, small enough to hold in context and plan on its own. Order
them and record dependencies. Reached from `brainstorming-a-goal`.

Why a dedicated phase: a large design planned as one document overflows context and buries
interfaces. Splitting first keeps each later plan focused and each phase reviewable on its own.

## Workflow

Do these in order. Create a todo per step.

1. **Read the approved design.** Load `docs/plan/specs/…-design.md`. Treat it as the source
   of truth for scope — the breakdown must cover it, no more, no less.
2. **Identify the phases.** Decompose by responsibility and boundaries, not by technical layer.
   Each phase = a clear purpose + defined interfaces + a self-contained, testable deliverable.
   Files/concerns that change together belong in the same phase. A **small goal may be a single
   phase** — don't invent phases to look thorough.
3. **Order them and map dependencies.** What must land before what, and why. Prefer an order
   where each phase produces working, testable software and later phases consume earlier ones.
4. **Write the breakdown doc.** Save to `docs/plan/breakdown/YYYY-MM-DD-<topic>-breakdown.md` —
   fill [references/breakdown-template.md](references/breakdown-template.md):
   - **Goal recap** — one paragraph, and a link to the design doc.
   - **Phase list** — for each phase: name + slug, purpose, **scope (in / out)**, **interfaces
     produced** (names/types later phases rely on), **interfaces consumed** (from earlier
     phases), **dependencies**, **order**, **done-criteria**.
   - **Sequencing notes** — the dependency graph / build order in prose.
5. **Self-review.** Fresh eyes, fix inline:
   - **Coverage** — does the union of phases cover the whole design? Any gaps or overlaps?
   - **Boundaries** — is each phase isolatable with a clean interface, understandable alone?
   - **Dependencies** — is the order satisfiable (no cycles, nothing consumed before produced)?
   - **Sizing** — is any phase too big to hold in context, or so small it should merge?
   - **Placeholder scan** — no TBD/TODO/vague scope.
6. **User review gate.** Only **after self-review passes**, ask the user to review the breakdown:
   > "Breakdown written to `<path>` — <N> phases. Please review the phases, order, and
   > boundaries before I write plans. Let me know any changes."
   Wait. **Revision** → ask for specific feedback + any more context needed, revise, re-run the
   self-review. **Rejected** → the decomposition missed intent; rethink boundaries from the
   design. Loop until approved.

## Common Mistakes

- Splitting by technical layer (all models, then all controllers) instead of by deliverable.
- Phases that can't be built or tested independently — hidden cross-coupling.
- Consuming an interface a later phase produces (dependency cycle / wrong order).
- Gaps or overlaps vs. the design — the union must equal the whole.
- Asking the user to review before running the self-review.
- Forcing multiple phases onto a goal that is genuinely one phase.

## Output

Approved breakdown at `docs/plan/breakdown/YYYY-MM-DD-<topic>-breakdown.md`, listing ordered
phases with interfaces and dependencies. Then transition → **REQUIRED SUB-SKILL:**
`planning-each-phase`.
