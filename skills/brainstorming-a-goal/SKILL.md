---
name: brainstorming-a-goal
description: Use when running phase 1 of the planning workflow — turning a goal (prompt, docs, Jira/Linear ticket, PRD, or link) into an approved design doc via Socratic dialogue. Delegates to superpowers:brainstorming when installed; otherwise asks to install it or runs an inline brainstorm. Triggers on "brainstorm this", "let's design this before building", after gathering a goal to plan.
---

# Brainstorming a Goal

## Overview

Phase 1 of the planning workflow. Turn the goal into an **approved design doc** through
collaborative, one-question-at-a-time dialogue — nail purpose, constraints, and success
criteria before any breakdown or code. Reached from `planning-work-in-phases`.

The terminal state is an approved design doc and a hand-off to phase 2. Do NOT scaffold,
write code, or invoke any implementation skill here.

## Scale to the tier

**Read the complexity tier** the router set in Step 0.5 (carried in the design-doc header)
and scale this phase to it — the tier is the throttle, not advisory:

- **Trivial** — the router skips the workflow; you won't reach this skill.
- **Small** — short design doc, **~1-3 targeted questions** (not the full 8-step loop),
  **no design specialists**, single approval. This is the "Too simple / already
  brainstormed" fast path below — bound to the tier, not judged ad hoc.
- **Standard** — normal flow; consult **only the relevant** specialists, in parallel (see
  below).
- **Large** — full 8-step brainstorm + the full specialist set.

## Design specialists — when to consult

The four design specialists (`architecture-agent`, `database-designer-agent`,
`api-designer-agent`, `frontend-designer-agent`) are **optional read-only advisors**. The
default is the main thread reasoning inline in the design doc — dispatch a specialist only
when the tier row below calls for it **and** its domain is actually in scope.

| Tier | Specialists | How |
|---|---|---|
| **Trivial / Small** | **none** | reason inline in the design doc — no specialist dispatch, no web/context7 chain |
| **Standard** | **only the relevant** one(s) — skip DB if no schema change, skip frontend for backend-only | dispatch **in parallel** (one message, multiple Agent calls) |
| **Large** | full set | `architecture-agent` first (the others reference its structure), then dispatch **db + api + frontend in parallel** — never a 4-deep serial chain |

Do not dispatch a specialist for a domain the goal doesn't touch, at any tier.

## Delegation decision

Check whether the `superpowers` plugin's brainstorming skill is available:

```bash
ls ~/.claude/plugins/cache/*/superpowers/*/skills/brainstorming/SKILL.md 2>/dev/null \
  && grep -q '"superpowers@claude-plugins-official": true' ~/.claude/settings.json && echo use-superpowers
```

- **Available** → **REQUIRED SUB-SKILL:** use `superpowers:brainstorming`. Instruct it to
  save the spec under `docs/plan/specs/` (its skill honors user location preference), so all
  workflow artifacts share one home, and to structure the design doc in the three layers below.
  When it finishes, come back and transition to phase 2.
- **Not available** → ask the user, in one message:
  > "The `superpowers` plugin isn't installed — its `brainstorming` skill runs this best. Want
  > to install it first, or should I continue with the same brainstorming process inline?"
  Install chosen → wait, then delegate as above. Continue chosen → run the inline fallback below.

## Inline fallback

Mirrors `superpowers:brainstorming`. Do these in order. Create a todo per step.

1. **Explore context.** Read the gathered source of truth and any existing project files,
   docs, recent commits. Know what already exists before asking.
2. **Scope check.** If the goal describes multiple independent subsystems (e.g. "chat +
   billing + analytics"), flag it now — that is a decomposition, not a single design. Note
   it; phase 2 will split it, but the design must acknowledge the pieces.
3. **Ask clarifying questions — one at a time.** Socratic, multiple-choice where possible.
   Cover: **purpose** (what problem, for whom), **target users**, **success metrics**, hard
   **constraints** (stack, deadlines, non-negotiables), and **verification / definition of
   done**. One question per message; don't overwhelm.
4. **Propose 2–3 approaches.** With trade-offs; lead with your recommendation and why.
5. **Present the design in sections.** Scale each section to its complexity; ask after each
   whether it looks right. Cover architecture, components, data flow, error handling, testing.
   Design for isolation — units with one clear purpose and well-defined interfaces.
   Need a visual (layout, wireframe, diagram, side-by-side)? See
   [references/visual-companion.md](references/visual-companion.md) — offered just-in-time.
6. **Write the design doc.** Save to `docs/plan/specs/YYYY-MM-DD-<topic>-design.md`, in the
   three-layer structure below. Fill [references/design-doc-template.md](references/design-doc-template.md).
7. **Spec self-review.** Fresh eyes: placeholder scan (TBD/TODO/vague), internal consistency,
   scope (focused enough — or does it need decomposition?), ambiguity (any requirement readable
   two ways → pick one, make it explicit). Fix inline. For large specs, optionally dispatch
   [references/spec-reviewer-prompt.md](references/spec-reviewer-prompt.md).
8. **User review gate.** Ask the user to review the written spec before advancing (see below).

## Design doc structure

The output is a **spec, not an implementation plan** — it stays entirely at the **behavior
and contract level**: no file paths, no framework names, no codebase assumptions. Those
belong to phase 3 (`planning-each-phase`).

**The doc always follows the `superpowers:brainstorming` design-doc format** — same section
style, same `YYYY-MM-DD-<topic>-design.md` save convention, same spec self-review — **even
when the plugin is not installed.** The inline fallback is not a different format; it produces
a doc that reads exactly like a superpowers spec. The three layers below are how that spec's
content is organized, not a replacement for it — map each layer onto the superpowers spec
sections (architecture, components, data flow, error handling, testing).

A living document in three layers — moving from *what the system does*, to *how it's built*,
to *how we prove it works*:

| Layer | Content | Question answered | Maps onto superpowers sections |
|-------|---------|-------------------|--------------------------------|
| **Functional Specification** | User stories, functional requirements, GIVEN/WHEN/THEN acceptance criteria, out-of-scope | *What should the system do, and for whom?* | purpose, components (behavior) |
| **Technical Design** | Endpoints, request/response contracts, flow diagrams, data model changes, error handling | *What is the system's external contract?* | architecture, data flow, error handling |
| **Testing Strategy** | Unit, integration, and E2E tiers described by behavior, plus the **≥95% coverage bar** (per-file hard, global ratcheted) as a success criterion | *What proves the spec is satisfied?* | testing |

## "Too simple / already brainstormed"

Every goal gets a design doc and an approval — but the effort scales:

- The design can be **short** (a few sentences) for a truly simple goal. "Too simple to need
  a design" is a trap that hides unexamined assumptions — still write it, still get approval.
- If the **source already contains a thorough design** (a detailed PRD/spec), don't re-brainstorm
  settled decisions: summarize the design from the source, fill only the real gaps with a few
  targeted questions, write/adopt the design doc, get approval. Fast path, same gate.

## Revision / rejection

- **Revision requested** → ask for the **specific feedback** and any **more context detail** you
  need, revise the doc, re-run the spec self-review, re-present. Loop until approved.
- **Rejected** → go back to clarifying questions / approaches; the design missed intent, so
  re-understand before rewriting.

## Common Mistakes

- Writing an implementation plan instead of a spec — file paths, framework names, and code
  belong in phase 3, not the design doc. Keep it at behavior + contract level.
- Skipping the design because the goal "seems obvious" — write a short one and get approval.
- Asking many questions at once instead of one at a time.
- Re-litigating decisions a detailed PRD already settled.
- Inventing requirements the user never stated.
- Advancing to breakdown before the user approves the design.

## Output

Approved design doc at `docs/plan/specs/YYYY-MM-DD-<topic>-design.md`. Then transition →
**REQUIRED SUB-SKILL:** `breaking-down-into-phases`.
