---
name: executing-phase-plans
description: >
  Use when running phase 4 of the planning workflow — executing the per-phase implementation
  plans from planning-each-phase, one plan at a time in dependency order, or executing/resuming a
  specific plan standalone after the workflow was paused or exited. Delegates to
  superpowers:subagent-driven-development or superpowers:executing-plans when installed;
  otherwise mirrors them inline. Triggers on "execute the plan", "build phase N",
  "run/implement the plan(s)", "resume the build", "continue the build", "ship this plan", "start
  coding the phase", "pick up where we left off", "run this plan standalone".
---

# Executing Phase Plans

## Overview

Phase 4 of the planning workflow: execute the per-phase implementation plans from
`planning-each-phase` — **one plan (one phase) at a time, in dependency order**.

Each phase's plan is already right-sized, so execute **plan-by-plan, never a combined run** —
even via superpowers, invoke the execution skill once **per phase plan**, since a later phase
consumes interfaces an earlier one produces.

**Exception — contract-isolated parallel tracks.** Two plans marked *parallel-eligible* because
they share **only** a frozen API contract (`docs/plan/contracts/<feature>.*`) — a backend
(provider) + frontend (consumer) track — touch disjoint files and may run **concurrently in
separate worktrees** ([Parallel tracks](#parallel-tracks-contract-isolated)). Concurrency is
sanctioned in exactly two shapes — this, and **independent disjoint-file tasks within a phase**
([Parallel execution](#parallel-execution-independent-tasks)) — both via separate worktrees; a
genuine dependency always stays sequential.

## Invocation modes

Also runnable standalone — a paused/exited workflow, resumed to run one plan. Pick the mode from
how it's invoked:

1. **Full run (default)** — execute every phase plan under `docs/plan/phases/` in dependency
   order. Used on hand-off from phase 3.
2. **Specific plan** — the user names a plan (`docs/plan/phases/<N-slug>/plan.md`, a phase
   number/name, or any plan file path, even outside `docs/plan/`). Execute **only that plan**.
   First check the ledger and the plan's *consumes-from-earlier-phases* block: an incomplete
   dependency → warn and ask whether to proceed anyway, run it first, or stop. Honor an explicit
   "just this one" without re-running others.
3. **Resume** — read the ledger (below) and `git log`, skip every complete task/phase, continue
   at the first incomplete task — never re-execute completed work. **For parallel contract
   tracks:** also read `docs/plan/contracts/<feature>.status.md`, discover both worktrees (`git
   worktree list`, recreate a pruned one from its branch), and **re-sync any `⚠ NEEDS-RESYNC`
   track** — a contract bumped mid-pause leaves it stale (`coordinating-api-contract` *Across
   sessions / resume*).

Ambiguous invocation → ask: full run, a specific plan (which?), or resume?

## Delegation decision

Check whether the `superpowers` plugin's execution skills are available:

```bash
ls ~/.claude/plugins/cache/*/superpowers/*/skills/subagent-driven-development/SKILL.md 2>/dev/null \
  && grep -q '"superpowers@claude-plugins-official": true' ~/.claude/settings.json && echo use-superpowers
```

- **Available** → **REQUIRED SUB-SKILL:** for each phase's `plan.md`, use
  `superpowers:subagent-driven-development` (in-session, subagent per task) or
  `superpowers:executing-plans` (parallel session), per the mode below — once per phase plan.
- **Not available** → ask the user to install it, or continue with the inline mirror below.

## Two choices before executing

**Read the complexity tier first** (design/plan header, set by `planning-work-in-phases` Step
0.5) — it sets the defaults below; ask only when the tier leaves it open or the user wants to
override. Delegated or autonomous → tier default.

1. **Isolated worktree, or work in place?** Default: **worktree**. superpowers present →
   **REQUIRED SUB-SKILL:** `superpowers:using-git-worktrees`. Absent → inline: detect existing
   isolation (`git rev-parse --git-dir` vs `--git-common-dir`), prefer a native worktree tool,
   else `git worktree add` under an ignored `.worktrees/`; verify a clean test baseline first.
2. **Execute in this session, or spawn subagents? — tier-driven default:**
   - **Small tier → inline** (Sub-mode B). Subagent-per-task fan-out pays a cold-start cost (each
     fresh subagent re-reads plan + interfaces + files) not worth it at this size. Run a
     **single derive-then-TDD pass**: always enumerate edge cases, derive **only non-canonical**
     rules with a **worked numeric example** before coding (per `implementing-backend` → *Derive
     before you build*), not a spec→plan→execute fan-out. Measured: recovers the multi-agent
     chain's defect-catch at **~⅓ the tokens**; a plain edge checklist catches simple forgotten
     edges (overflow) but only the worked-example derivation catches hard boundary/formula/
     concurrency bugs.
   - **Standard → inline or subagent**, by phase weight — inline still uses derive-then-TDD.
   - **Hard-reasoning at Small/Standard size** (bespoke rate limiting, scheduling, money/interval
     math, a hand-rolled concurrency invariant): stay **inline**, make the derivation
     **mandatory**, don't escalate — the derivation, not the choreography, fixes it; escalating
     pays 3× the tokens for the same result. **Two safeguards** (measured: a weak model derives a
     subtle boundary wrong **~1 in 4** — mandatory derivation is necessary, not sufficient): (a)
     **run it on the strong model** (design-grade reasoning, dispatched to the capable tier even
     inside otherwise-cheap execution); (b) **pin the boundary with a two-sided test written
     first** — last value accepted *and* first rejected (`n-1` passes, `n` fails).
   - **Canonical pattern (any tier) → skip the derivation, keep the tests.** A named, standard
     pattern (singleflight, LRU/TTL cache, debounce, CRUD/pagination) — reuse the known shape,
     enumerate + test edges only. Measured (benchmark G): re-deriving a canonical concurrency
     task the model already one-shots cost **1.5× tokens / 3.5× wall-clock** for an identical,
     defect-free result. When unsure which it is, derive.
   - **Large / high-risk / contract-split → subagent-driven** (Sub-mode A): fresh context per
     task, review between — worth the overhead when work is big/risky and the separate artifacts
     serve **coordination** (multi-phase, parallel tracks, cross-session resume, approval gates),
     not just defect-catch.
   - **Then cut wall-clock: fan out independent tasks.** In subagent mode, group tasks into
     dependency levels and dispatch the independent, disjoint-file ones in a level
     **concurrently, one worktree each**, joining before the next
     ([Parallel execution](#parallel-execution-independent-tasks)). Wall-clock per level = the
     slowest task, not the sum. Only for ≥2 non-trivial independent tasks.

## Execution order

Follow the breakdown's phase order and dependencies. Finish one phase's plan completely (tasks +
tests + review + integration) before starting the next; offer to pause between phases for review.
**Exception:** two *parallel-eligible* contract-isolated plans may run concurrently — see
[Parallel tracks](#parallel-tracks-contract-isolated).

## Parallel tracks (contract-isolated)

A **backend (provider)** + **frontend (consumer)** plan marked *parallel-eligible* — sharing only
the frozen contract, disjoint files — run **concurrently, one worktree per track**, per
`coordinating-api-contract`. All conditions required:

1. **Contract frozen first.** `docs/plan/contracts/<feature>.*` exists, versioned, approved. No
   frozen contract → run sequentially.
2. **Separate worktrees** — removes the file-conflict reason the one-implementer rule guards
   against; that rule holds **within** a worktree, not globally.
3. **Build to the contract.** Backend as provider (provider-conformance tests); frontend against
   a contract-derived mock as consumer (consumer-parity tests). Neither invents a shape absent
   from the contract.
4. **Contract-change protocol on divergence.** Wrong/insufficient → **stop that track**, don't
   work around it. Edit the artifact, bump its version, re-approve, re-sync **both** tracks.
5. **Integration gate.** Both finish → swap the mock for the real provider, run the
   **conformance gate** (provider conformance + consumer parity + drift check) before the phase
   counts as built, then review each track's diff via phase 5.

Each track keeps its own `progress.md`. No true concurrency available → sequential fallback; the
frontend still builds against the mock, never blocked on the backend.

**Durable across sessions.** State lives on disk, committed: the **contract status ledger**
`docs/plan/contracts/<feature>.status.md` (per track: worktree, branch, synced-version,
conformance; `⚠ NEEDS-RESYNC` when behind), stamped alongside each track's `progress.md`. On
resume this lets a later session rediscover both worktrees and re-sync the stale one before
continuing (`coordinating-api-contract` *Durable state* + *Across sessions / resume*).

## Parallel execution (independent tasks)

The biggest **wall-clock** saving is not running independent work serially. Beyond the
contract-track case, **any tasks the dependency graph marks mutually independent, touching
disjoint files**, may run **concurrently**:

1. **Group tasks into dependency levels** — a level = tasks whose dependencies are all done,
   independent of each other.
2. **Fan out within a level (subagent mode).** Each independent, disjoint-file task gets its own
   implementer subagent in its **own worktree**; each still self-reviews, tests, and commits.
3. **Join at a barrier, then advance.** Wait for the whole level, integrate, then start the next
   (may consume this level's output). Review over the **combined** diff, not per task.

**Wall-clock per level = the slowest task, not the sum.** Worth it only for **≥2 non-trivial
independent tasks** — a couple of tiny edits are cheaper sequential. Falls back to sequential
when subagents/worktrees are unavailable or tasks share files. **Within any one worktree, still
one implementer at a time; a genuine dependency is never parallelized.** General form of the
contract-track case (the special case where disjointness is contract-guaranteed). superpowers
present → `superpowers:dispatching-parallel-agents`; absent → dispatch inline, join before the
next level.

## The process (repeat per phase plan)

### Step 1: Load and review plan

1. Read the phase's `docs/plan/phases/<N-slug>/plan.md`.
2. **Pre-flight review** — scan once for conflicts: tasks contradicting each other or the Global
   Constraints, anything a review rubric would flag (an assertion-free test, duplicated logic).
   Batch every finding into **one** question before starting, not one interrupt per discovery.
   Clean scan → proceed silently.
3. Note context, Global Constraints, and the **interfaces consumed from earlier phases**.
4. Create a todo per task.

### Step 2: Execute tasks

**Sub-mode A — Subagent-driven** (mirrors `superpowers:subagent-driven-development`):
- Dispatch a **fresh implementer subagent per task** — its task brief, consumed interfaces, and
  Global Constraints; never your session history. Answer its questions before it proceeds.
- Implements, tests, commits, self-reviews, reports status (DONE / DONE_WITH_CONCERNS /
  NEEDS_CONTEXT / BLOCKED).
- **Record every task in `progress.md` the moment it finishes** — the controller appends that
  task's entry (status **COMPLETE**/BLOCKED, one-line summary, files, commit range, test result,
  review verdict, deviations — short but comprehensive) and marks it done, **before dispatching
  the next task**. This is mandatory and per-task, not batched to phase end. "Continuous
  execution" means no *user* check-in between tasks — it does **not** mean skipping the
  progress write.
- **Review cadence is tier-driven** — reviewing after *every* task is the biggest execution
  multiplier:
  - **Large / high-risk** → **per-task**: full review (spec + quality) against the diff, verify
    the coverage gate, dispatch a fix subagent for Critical/Important, re-review until clean.
  - **Small / Standard** → **per-phase**: each implementer self-reviews/tests/commits locally;
    the full spec+quality review runs **once at phase end** over the whole diff (Step 3) — same
    defects, caught a little later, for a large overhead drop.
  - **Coverage gate (≥95% per changed file + global not regressed) verified before done, every
    tier** — per-task tiers each task, per-phase tiers at phase end. Never skipped, only batched.
- **Model selection (enforced)** — mechanical/boilerplate/scaffolding/transcription on the
  **cheapest tier** (e.g. Haiku), standard tier for integration wiring, **most capable** (e.g.
  Opus) only for design-heavy tasks and the final review. **A non-canonical hard-reasoning
  derivation counts as design-heavy — run it on the top model even inside a cheap task**
  (measured: a weak model ships a wrong boundary **~1 in 4**). Every task on the top model costs
  wall-clock/money for no gain on rote work. **Every dispatch names its model.**
- **One implementer at a time _per worktree_** — concurrency is across **separate** worktrees
  only (contract-isolated tracks; independent tasks fanned out by dependency level).
  **Continuous execution** — no check-ins between tasks; stops only for an unresolvable BLOCKED,
  genuine ambiguity, or all tasks done.
- After all tasks, dispatch **one** final whole-branch code review on the most capable model.

**Sub-mode B — Inline** (mirrors `superpowers:executing-plans`):
- Per task: mark in_progress → follow each bite-sized step exactly (plan carries code/commands)
  → run its verifications → **append the task's `progress.md` entry and mark it COMPLETE** →
  mark the todo completed.
- Stop and ask the moment a step is unclear or a verification fails.

Both sub-modes: never start implementation on `main`/`master` without explicit user consent.

**Test-run strategy — focused in the loop, full suite once at the gate.** Re-running the whole
suite every TDD step × task is usually the dominant execution time cost:

- **In the loop, run only the test under work** — fail-fast, single file/case: `vitest run
  path/to/x.test.ts`, `pytest path::test -x`, `go test ./pkg -run TestX`, `cargo test x`.
- **Full suite + coverage exactly once, at the phase gate** (Step 3) — where the ≥95% gate and
  cross-test breakage are caught, not per task.
- **Never compute coverage inside the loop** — a phase-end measurement, not per-step.
- Plan's step commands run the whole suite each step? Treat as a plan defect; run the focused
  equivalent instead (`planning-each-phase`).

Trades a slightly later catch of cross-test breakage for an N× drop in repeated suite runs. The
coverage bar is unchanged — measured once, at the end.

### Step 3: Review, then complete development

Every task passes and is verified → the phase is **built and committed but not yet done** — it
must pass review first.

**Run the full suite + coverage now — once**, the one point they run (the loop ran only focused
tests). Confirm all green and the ≥95% gate holds before review. A failure here is a real
finding — fix, re-run.

**Then sync the layered project-context docs.** Phase scaffolded/reshaped the directory structure
(a source tree, new package/app/service, meaningful directory) → each meaningful source directory
gets its own light `CLAUDE.md` (subtree purpose, key files/entry points, conventions/gotchas —
pointers, not prose) plus an `AGENTS.md` symlink, root kept in sync, same phase's commits.
Follow `implementing-documentation`; the layered form of the keep-docs-synced convention the Stop
doc-sync hook only reminds about for the root.

Then review. **REQUIRED SUB-SKILL:** `reviewing-phase-implementation` (phase 5) against the
design doc and plan. **Defer the merge until review approves** — until then keep-as-is (or open a
PR); never merge unreviewed work to the base branch.

Review approves → complete development:
- superpowers present → **REQUIRED SUB-SKILL:** `superpowers:finishing-a-development-branch`.
- Absent → inline: **verify tests pass** (stop if not) → **detect environment** (`--git-dir` vs
  `--git-common-dir`) → present **exactly 4 options** (1. merge to base locally, 2. push + open
  PR, 3. keep as-is, 4. discard; **3 options** on detached HEAD, no merge) → execute the choice →
  clean up the worktree **only for options 1 and 4** (only one created under `.worktrees/`),
  requiring a typed `discard` confirmation for option 4.

**Mark the phase done.** Once **every task of the phase is COMPLETE** in `progress.md` and review
has approved, stamp the phase: set **Phase result → Status: done** with the reviewed-approved
timestamp (and finish option chosen). The phase is *done* only when all its tasks are done +
reviewed — a phase with any incomplete/blocked task stays *in progress*. `reviewing-phase-implementation`
writes the approval timestamp; this skill flips the phase status to done on that approval.

Then move to the **next phase's plan** — Step 1 — until all phases are built, reviewed, done.

## Progress log (durable memory)

**Always write progress and changes to a committed doc as you go** — not just todos or
git-ignored scratch. It survives compaction (a lost controller has re-run whole completed
phases), is the **resume ledger**, and **shared memory** any other agent can review without
replaying the session.

- **Location:** `docs/plan/phases/<N-slug>/progress.md`, one per phase, beside `plan.md`.
  Committed. Fill [references/progress-template.md](references/progress-template.md). A
  **parallel contract track** also stamps `Contract: <path> @ <synced-version>` +
  `Sibling track: …`, and maintains the shared **contract status ledger**
  `docs/plan/contracts/<feature>.status.md` — the second durable record a later session resumes
  both tracks from.
- **Write continuously** — after each task and again at phase finish. Never batch to the end.
- **Per task:** name/number + **status** (complete/blocked); one-line summary; **files touched**;
  **commit hashes/range** (`<base7>..<head7>`); **test result** (command + pass count); **review
  verdict**; any **deviation/decision**, with why.
- **Per phase:** done marker, finish option (merge/PR/keep/discard), branch/PR reference, open
  follow-ups.
- **On resume:** trust this log and `git log` over recollection — complete means DONE, don't
  re-execute; continue at the first incomplete task.
- Commits it names exist in git even when context forgets creating them; recover from the
  committed log + `git log` if uncommitted state is destroyed.

## When to stop and ask for help

**STOP immediately when:**
- A blocker appears — missing dependency, failing test, unclear instruction.
- The plan has critical gaps preventing a start.
- You don't understand an instruction, or a verification fails repeatedly.
- A subagent reports unresolvable BLOCKED, or a finding conflicts with the plan (the human's
  call — present the finding beside the plan text, ask which governs).
- **A parallel track needs the API contract to change.** Stop that track, don't work around it.
  Run the **contract-change protocol** (`coordinating-api-contract`): edit the contract, bump the
  version, re-approve, re-sync both tracks.

Ask for clarification rather than guessing.

## When to revisit earlier steps

**Return to Step 1 when:** the partner updates the plan based on your feedback; the fundamental
approach needs rethinking; or an earlier phase changed reality (interface, data shape) in a way
that invalidates a later phase's plan → send it back through `planning-each-phase` to re-plan
first.

Don't force through blockers — stop and ask.

## Remember

- Execute **one phase plan at a time, in dependency order** — never merged.
- Standalone runs OK (named plan or resume via ledger); check dependencies first; never re-run
  completed work.
- Review each plan before starting; follow its steps exactly.
- **Coverage gate before done**: tests green *and* ≥95% per changed file + global not regressed —
  show the report.
- **Focused tests in the loop, full suite + coverage once at the gate** — the dominant execution
  time cost otherwise.
- **Model tiering enforced**: cheap tier for rote work, top model for design + final review;
  every dispatch names its model.
- **Layered docs before done**: scaffolded/reshaped structure → per-directory `CLAUDE.md` +
  `AGENTS.md` symlink, root synced, same phase.
- Subagent mode: one implementer per worktree; review cadence per tier (per-task Large/high-risk,
  per-phase Small/Standard); contract-isolated tracks are the one parallel exception.
- **Inline = derive-then-TDD, not spec→plan→execute** — one pass with a worked example catches
  the same defects at **~⅓ the tokens**; reserve the multi-agent chain for coordination needs.
- **Derive only non-canonical rules** — a named textbook pattern (singleflight, LRU/TTL,
  debounce, CRUD) needs no re-derivation. Measured (benchmark G): re-deriving one cost **1.5×
  tokens** for zero defects.
- **Two safeguards on a hard derivation** (a weak model gets it wrong **~1 in 4**, measured): run
  it on the **strong model**, and pin the boundary with a **two-sided test** (`n-1` accepted, `n`
  rejected) — one-sided tests pass a wrong `>=`-vs-`>`.
- **Signature-conformance self-check**: code must compile against the **exact declared
  signature** (names, params, return arity/types) — never change it to fit validation; validate
  within it or flag a contract change. Green self-tests aren't proof — they call the
  implementer's own signature. Measured: a subagent's `NewVault` gained an `error` return, its 15
  self-tests passed, the frozen-contract grader failed it to compile.
- **Fan out independent tasks by dependency level** (subagent mode) — one worktree each, join
  before the next; wall-clock per level = the slowest task, tokens unchanged. Only for ≥2
  non-trivial independent tasks.
- **Write `progress.md` per task, continuously** — append each task's entry (status + short
  comprehensive summary, files, commits, tests, review, deviations) and mark it COMPLETE the moment
  it finishes, never batched; then **mark the phase Status: done once every task is COMPLETE and
  review approved.** It is the resume ledger and shared memory — a task with no entry looks unstarted
  on resume.
- Reference the skills the plan tells you to; stop when blocked; never implement on
  `main`/`master` without consent.

## Common Mistakes

- Running execution on a combined plan instead of per phase.
- Executing a later phase before its dependency.
- Skipping the phase's review, or inline-mode verifications — per-phase review still covers the
  full diff at phase end; only per-task cadence is tier-optional.
- Running the **full suite/coverage every TDD step** instead of the focused test — usually the
  biggest time sink; full suite runs **once**, at the gate.
- Dispatching **every** task on the top model, including rote work — no quality gain, costs
  time/money.
- Marking done with tests green but **coverage gate unmet** (a file under 95%, or a global
  regression).
- Parallel implementer subagents **in the same worktree** — they conflict (separate worktrees
  for contract-isolated tracks are fine).
- Parallel backend/frontend **without a frozen contract**, or changing a shape in code instead of
  the contract-change protocol.
- **Finishing a task without writing its `progress.md` entry** (or batching all entries to phase
  end) — each task must be recorded + marked COMPLETE the moment it finishes; an unrecorded task
  looks unstarted on resume and cross-agent review has nothing to read.
- **Marking a phase done while a task is incomplete/blocked, or leaving it *in progress* after all
  tasks are COMPLETE and reviewed** — the phase Status flips to done exactly when every task is done
  and review approved.
- Scaffolding a new tree but leaving only the root `CLAUDE.md` — each source directory needs its
  own layered docs, same phase.
- Running a named plan whose dependencies aren't done, without warning the user.
- Cleaning up a harness-owned worktree, or one for option 2/3.
- **Escalating Small/Standard work to the full spec→plan→execute→review chain** when one inline
  derive-then-TDD pass catches the same defects — pays **~3× the tokens** for nothing. Escalate
  for *coordination*, not defect-catch.
- **Skipping the derivation** on a non-canonical step and coding from prose — the worked example
  is what catches a `>=`-vs-`>` boundary bug.
- **Deriving on the cheap model, testing one-sided** — wrong **~1 in 4** (measured); a
  happy-path test passes a wrong boundary. Derive on the top model, test both sides.
- **Changing a declared signature to pass your own tests** — self-reports green while the
  contract is broken. Check conformance against the **declared** signature, never the shipped
  one.
- **Over-deriving a canonical pattern** — full derivation on a known algorithm costs
  **1.5×/3.5×** for zero defects caught. Reuse the shape; save derivation for non-canonical
  rules.
- **Serializing independent, disjoint-file tasks** — wastes wall-clock. Fan out by dependency
  level into parallel worktrees; a real dependency still stays sequential.

## Output

Each phase's plan implemented, tested, reviewed, and integrated per the chosen finish option,
plus a committed `docs/plan/phases/<N-slug>/progress.md` per phase recording status, changes,
files, commits, tests, and decisions — durable memory another agent can review from. All phases
complete → the feature is built.
</content>
