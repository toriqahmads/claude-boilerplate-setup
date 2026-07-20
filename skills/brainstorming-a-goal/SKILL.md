---
name: brainstorming-a-goal
description: >
  Use when running phase 1 of the planning workflow — turning a goal (prompt, docs,
  Jira/Linear ticket, PRD, GitHub issue, or link) into an approved design doc via
  Socratic dialogue. Also covers "brainstorm this", "let's design this before
  building", "spec this out", "what's the design for X", after gathering a goal to
  plan. Delegates to superpowers:brainstorming when installed; otherwise asks to
  install it or runs an inline brainstorm.
---

# Brainstorming a Goal

## Overview

Phase 1 of the planning workflow: turn the goal into an **approved design doc** via
collaborative, one-question-at-a-time dialogue — nail purpose, constraints, and success
criteria before any breakdown or code. Reached from `planning-work-in-phases`.

Terminal state: approved design doc → hand off to phase 2. Do NOT scaffold, write code,
or invoke any implementation skill here.

## Scale to the tier

**Read the complexity tier** the router set in Step 0.5 (carried in the design-doc
header) and scale this phase to it — the tier is the throttle, not advisory:

- **Trivial** — the router skips the workflow; you won't reach this skill.
- **Small** — short design doc, **~1-3 targeted questions** (not the full 8-step loop),
  **no design specialists**, single approval. This is the "Too simple / already
  brainstormed" fast path below — bound to the tier, not judged ad hoc.
- **Standard** — normal flow; consult **only the relevant** specialists, in parallel
  (below).
- **Large** — full 8-step brainstorm + the full specialist set.

## Design specialists — when to consult

The four design specialists (`architecture-agent`, `database-designer-agent`,
`api-designer-agent`, `frontend-designer-agent`) are **optional read-only advisors**:
default is inline reasoning; dispatch one only when the tier below calls for it **and**
its domain is in scope.

| Tier | Specialists | How |
|---|---|---|
| **Trivial / Small** | **none** | reason inline in the design doc — no specialist dispatch, no web/context7 chain |
| **Standard** | **only the relevant** one(s) — skip DB if no schema change, skip frontend for backend-only | dispatch **in parallel** (one message, multiple Agent calls) |
| **Large** | full set | `architecture-agent` first (others reference its structure), then **db + api + frontend in parallel** — never a 4-deep serial chain |

Never dispatch a specialist for a domain the goal doesn't touch, at any tier.

**Domain-in-scope rule — what counts as "relevant."** A specialist is relevant when its domain is in the goal, and the tier scales its *depth*, not whether it runs:
- **Frontend/UI in scope → `frontend-designer-agent` is required** (never treat a UI feature as API-design-only). It carries the **design system + production-ready UI/UX** bar — tokens, a component system, every state, a11y, responsive, and UX polish (`designing-a-frontend`) — which is what makes the built UI professional, not just functional.
- **A data layer / persistence in scope → `database-designer-agent`.**
- **A backend or service seam in scope → `api-designer-agent`** (produces the frozen contract).

So a feature that ships a UI on top of new data behind a backend seam designs **all four** (db + api + frontend/design-system), consulted per the tier's parallelism. A UI-only or design-system change still runs the frontend specialist. Only genuinely backend-only work skips the frontend/design-system design.

## Delegation decision

Check whether the `superpowers` plugin's brainstorming skill is available:

```bash
ls ~/.claude/plugins/cache/*/superpowers/*/skills/brainstorming/SKILL.md 2>/dev/null \
  && grep -q '"superpowers@claude-plugins-official": true' ~/.claude/settings.json && echo use-superpowers
```

- **Available** → **REQUIRED SUB-SKILL:** use `superpowers:brainstorming`. Instruct it
  to save the spec under `docs/plan/specs/` (honors user location preference, keeps all
  workflow artifacts in one home) structured in the three layers below. When done,
  transition to phase 2.
- **Not available** → ask the user, in one message:
  > "The `superpowers` plugin isn't installed — its `brainstorming` skill runs this
  > best. Want to install it first, or should I continue with the same brainstorming
  > process inline?"
  Install chosen → wait, then delegate as above. Continue chosen → run the inline
  fallback below.

## Inline fallback

Mirrors `superpowers:brainstorming`. Do these in order; a todo per step.

1. **Explore context.** Read the source of truth, project docs, recent commits — know
   what exists before asking.
2. **Scope check.** Multiple independent subsystems (e.g. "chat + billing +
   analytics") = decomposition, not one design — flag now; phase 2 splits it, but the
   design must acknowledge the pieces.
3. **Ask clarifying questions — one at a time.** Socratic, multiple-choice where
   possible. Cover **purpose** (problem, for whom), **target users**, **success
   metrics**, **constraints** (stack, deadlines, non-negotiables), and
   **verification/definition of done**. One question per message.
4. **Propose 2–3 approaches.** With trade-offs; lead with your recommendation and why.
5. **Present the design in sections**, scaled to complexity — confirm each before
   moving on. Cover architecture, components, data flow, error handling, testing;
   design for isolation (one purpose, clean interfaces per unit). Need a visual
   (layout, wireframe, diagram, side-by-side)? See
   [references/visual-companion.md](references/visual-companion.md), offered
   just-in-time.
6. **Write the design doc.** Save to `docs/plan/specs/YYYY-MM-DD-<topic>-design.md`, in
   the three-layer structure below. Fill
   [references/design-doc-template.md](references/design-doc-template.md).
7. **Spec self-review**, fresh eyes: placeholder scan (TBD/TODO/vague), consistency,
   scope (focused, or needs decomposition?), ambiguity (two readings → pick one, make
   it explicit). Fix inline; for large specs, optionally dispatch
   [references/spec-reviewer-prompt.md](references/spec-reviewer-prompt.md).
8. **User review gate.** Ask the user to review the written spec before advancing
   (below).

## Design doc structure

The output is a **spec, not an implementation plan** — strictly **behavior and
contract level**: no file paths, framework names, or codebase assumptions (those are
phase 3, `planning-each-phase`).

**The doc always follows the `superpowers:brainstorming` design-doc format** — same
section style, save convention, self-review — **even without the plugin installed**;
the inline fallback reads like a superpowers spec. The three layers below organize that
content, mapped onto its sections (architecture, components, data flow, error handling,
testing).

A living document in three layers — moving from *what the system does*, to *how it's
built*, to *how we prove it works*:

| Layer | Content | Question answered | Maps onto superpowers sections |
|-------|---------|-------------------|--------------------------------|
| **Functional Specification** | User stories, functional requirements, GIVEN/WHEN/THEN acceptance criteria, out-of-scope | *What should the system do, and for whom?* | purpose, components (behavior) |
| **Technical Design** | Endpoints, request/response contracts, flow diagrams, data model changes, error handling | *What is the system's external contract?* | architecture, data flow, error handling |
| **Testing Strategy** | Unit, integration, and E2E tiers described by behavior, plus the **≥95% coverage bar** (per-file hard, global ratcheted) as a success criterion | *What proves the spec is satisfied?* | testing |

## "Too simple / already brainstormed"

Every goal gets a design doc and an approval — only the effort scales:

- **Truly simple goal** → a short design (a few sentences). "Too simple to need one" is
  a trap hiding unexamined assumptions — still write it, still get approval.
- **Source already has a thorough design** (a detailed PRD/spec) → don't re-brainstorm
  settled decisions: summarize it, fill only real gaps with a few targeted questions,
  adopt/write the doc, get approval. Fast path, same gate.

## Revision / rejection

- **Revision requested** → get the specific feedback plus any missing context, revise,
  re-run the self-review, re-present. Loop until approved.
- **Rejected** → the design missed intent — return to clarifying questions/approaches
  and re-understand before rewriting.

## Common Mistakes

- Writing an implementation plan instead of a spec — file paths, framework names, and
  code belong in phase 3, not the design doc. Keep it at behavior + contract level.
- Skipping the design because the goal "seems obvious" — write a short one and get
  approval.
- Asking many questions at once instead of one at a time.
- Re-litigating decisions a detailed PRD already settled.
- Inventing requirements the user never stated.
- Advancing to breakdown before the user approves the design.

## Output

Approved design doc at `docs/plan/specs/YYYY-MM-DD-<topic>-design.md`. Then transition →
**REQUIRED SUB-SKILL:** `breaking-down-into-phases`.
