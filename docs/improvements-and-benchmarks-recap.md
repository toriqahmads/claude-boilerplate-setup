# Session Recap — Workflow Improvements & Benchmarks

**Date:** 2026-07-20 · **Scope:** benchmark-driven improvements to the `claude-boilerplate`
plugin (skills, agents, planning/design phase), plus three empirical benchmark rounds.
Full rationale + numbers live in [`workflow-rationale.md`](workflow-rationale.md) §11;
per-change detail in [`../CHANGELOG.md`](../CHANGELOG.md).

---

## 1. What we measured

An A/B benchmark, model held constant per arm, scored by a **hidden Go `-race` grader the
arms never saw** (re-run by the main thread — never self-reported). Task: an ambiguous,
multi-concern **per-user rate-limited document vault** (Go) bundling **IDOR access control**,
**input validation**, a **sliding-window rate-limit boundary** (left unspecified → each arm
must *derive* it), and **concurrency**. Graded on **12 edge-case properties**. Three rounds:

| Round | Arms | Headline result |
|---|---|---|
| 1 (clear spec) | opus one-shot · haiku one-shot · haiku workflow | All correct — task too clearly specified to discriminate. |
| 2 (ambiguous spec) | same | Tie on the grader **but** the workflow arm shipped **1 contract break** (`NewVault` signature changed to validate a constructor arg; its own tests adopted the change and passed). Drove a fix. |
| 3 (ambiguous, post-fix) | opus one-shot · haiku one-shot · **haiku workflow via subagents** | **Three-way tie, 60/60 each. No contract break** — the fix held. Workflow generated the most tests. |

### Final numbers (round 3, N=5/arm)

| Arm | model · dispatch | grader (60 checks) | tests generated | tests passed / failed |
|---|---|---|---|---|
| opus one-shot | opus · 1 agent | **60/60** | 75 | 75 / 0 |
| haiku one-shot | haiku · 1 agent | **60/60** | 111 | 111 / 0 |
| **haiku workflow** | haiku · 2 subagents (derive→execute) | **60/60** | **135** | 135 / 0 |
| **Total** | — | **180/180** | **321** | **321 / 0** |

**Reading:** a cheap model running the workflow through subagents **matched a strong model
one-shot** on correctness, and shipped **~1.8× the regression tests** (135 vs 75) — at ~2.5×
the tokens on a far cheaper model. On a small, clearly-contracted task the workflow adds no
*correctness* over a plain cheap one-shot; its durable payoff is the **test suite + edge/
security analysis** and **process consistency**. This validates the complexity-tier throttle:
reserve subagent ceremony for where coordination/scale actually pays.

**Two honest findings that shaped the improvements:**
1. **Self-reported "all green" is untrustworthy.** Round 2's contract break and a round-3
   sample that flaked under load *both* self-reported success; only the independent grader
   caught them. → argues for read/write separation and an independent review/conformance gate.
2. **A weak model derives a subtle boundary wrong ~1-in-4** and ships it, because its own
   tests are one-sided. → mandatory derivation is necessary but not sufficient.

---

## 2. What we improved (all preserved in the skills/agents)

| Area | Change | Files |
|---|---|---|
| **Derivation reliability** | For a non-canonical hard rule (boundary/formula/concurrency invariant): (a) **run the derivation on the strong model** even inside cheap execution (model-tiering *inverts* for it); (b) **two-sided boundary test written first** (`n-1` accepted *and* `n` rejected) so a wrong `<`-vs-`≥` fails its own test. | `implementing-backend`, `implementing-frontend`, `executing-phase-plans`, `planning-work-in-phases` |
| **Contract conformance** | **"Signatures are frozen — conform, don't redesign"** guardrail (validate a constructor precondition *within* the no-error signature — panic or documented default — never add a return; else stop-and-flag) + a **signature-conformance self-check** (compile against the *declared* signature, not the shipped one; a green self-test suite is not proof). Closed the round-2 contract break; re-verified 5/5. | `implementing-backend`, `executing-phase-plans` |
| **Design phase = whole UI stack** | A UI feature now designs **database + API + design-system + frontend**, not just the API. **Domain-in-scope rule:** frontend/UI in scope → frontend design **required**; data layer → DB design; backend seam → API design; tier scales *depth*, not presence. **Design-system + production-ready UI/UX** folded into `designing-a-frontend` (tokens, component system/shadcn, polished states, motion, a11y, responsive) so an implemented frontend is professional, not functional-but-rough. | `designing-a-frontend`, `frontend-designer-agent`, `brainstorming-a-goal`, `implementing-frontend`, `CLAUDE.md` |
| **Skills optimized (29)** | Tighter bodies (real cuts concentrated on the long procedural skills, ~22–30%) + every `description:` enriched with **trigger synonyms** so skills activate on more phrasings. No rule/cross-ref/benchmark number dropped. | all `skills/*/SKILL.md` |
| **Agents compacted (18, ~1620→1245 lines)** | Cut each agent's restatement of the skill it follows down to a pointer; kept identity + delegation + unique constraints + output shape; enriched descriptions with trigger synonyms. Frontmatter (`name`/`tools`/`model`/`color`) unchanged. | all `agents/*.md` |

Quality bar unchanged throughout: **≥95% coverage**, **security on risk**, **E2E before done**,
**spec↔code traceability**. These are density/reliability/coverage improvements, not a scope cut.

---

## 3. Where to look

- **Benchmark method + full result:** `workflow-rationale.md` §11.
- **Per-change detail:** `CHANGELOG.md` (`[Unreleased]` → Changed / Reliability / Performance).
- **The improvements themselves:** the skill and agent files listed above.
