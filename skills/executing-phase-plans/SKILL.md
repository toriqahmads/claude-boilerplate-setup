---
name: executing-phase-plans
description: Use when running phase 4 of the planning workflow — executing the per-phase implementation plans from planning-each-phase, one plan at a time in dependency order, or executing/resuming a specific plan on its own after the workflow was paused or exited. Delegates to superpowers:subagent-driven-development or superpowers:executing-plans when installed; otherwise mirrors them inline. Triggers on "execute the plan", "build phase N", "implement the plans", "resume the build", "run this plan".
---

# Executing Phase Plans

## Overview

Phase 4 of the planning workflow. Execute the per-phase implementation plans produced by
`planning-each-phase` — **one plan (one phase) at a time, in dependency order**. Reached
from `planning-each-phase`.

Each phase's plan is already broken down and right-sized by earlier phases, so you execute
**plan-by-plan, never one combined run.** Even when delegating to superpowers, invoke the
execution skill once **per phase plan**, in order — a later phase consumes interfaces an
earlier phase produces, so the earlier plan must be done and integrated first.

**One exception — contract-isolated parallel tracks.** When the breakdown marks two plans
*parallel-eligible* because they share **only** a frozen API contract
(`docs/plan/contracts/<feature>.*`) — a backend (provider) track and a frontend (consumer)
track — they touch disjoint files and may run **concurrently in separate worktrees**. See
[Parallel tracks](#parallel-tracks-contract-isolated) below. This is the only sanctioned
concurrency; every other dependency stays strictly sequential.

## Invocation modes

Reached from `planning-each-phase`, but also runnable standalone — a workflow gets paused or
exited, and the user (or agent) comes back to run one plan. Pick the mode from how it's invoked:

1. **Full run (default)** — execute every phase plan under `docs/plan/phases/` in dependency
   order. Used on hand-off from phase 3.
2. **Specific plan** — the user names a plan (`docs/plan/phases/<N-slug>/plan.md`, a phase
   number/name, or **any plan file path**, even one outside `docs/plan/`). Execute **only that
   plan**. Before starting, check the ledger and the plan's *consumes-from-earlier-phases* block:
   if a dependency isn't marked complete, warn the user and ask whether to proceed anyway, run
   the missing phase first, or stop. Honor an explicit "just this one" without re-running others.
3. **Resume** — a prior run was paused/exited. Read the ledger (below) and `git log`, skip every
   task/phase already marked complete, and continue at the first incomplete task of the first
   incomplete phase. Never re-execute completed work. **For parallel contract tracks:** also read
   the contract status ledger (`docs/plan/contracts/<feature>.status.md`), discover both worktrees
   (`git worktree list`, recreate a pruned one from its branch), and **re-sync any track flagged
   `⚠ NEEDS-RESYNC` / behind the contract's current version before continuing it** — a contract
   bumped while a track was paused leaves that track stale (see `coordinating-api-contract`
   *Across sessions / resume*).

If the invocation is ambiguous (no plan named, no obvious in-progress run), ask: full run,
a specific plan (which?), or resume?

## Delegation decision

Check whether the `superpowers` plugin's execution skills are available:

```bash
ls ~/.claude/plugins/cache/*/superpowers/*/skills/subagent-driven-development/SKILL.md 2>/dev/null \
  && grep -q '"superpowers@claude-plugins-official": true' ~/.claude/settings.json && echo use-superpowers
```

- **Available** → **REQUIRED SUB-SKILL:** for each phase's `plan.md`, use
  `superpowers:subagent-driven-development` (in-session, subagent per task) or
  `superpowers:executing-plans` (parallel session), per the mode chosen below. Run it once
  per phase plan, in order — not on a merged plan.
- **Not available** → ask the user to install it, or continue with the inline mirror below.

## Two choices before executing

Ask the user; if they have delegated the choice or you are running autonomously, decide as
agent using the stated default.

1. **Isolated worktree, or work in place?** Default: **worktree** (protects the current
   branch). superpowers present → **REQUIRED SUB-SKILL:** `superpowers:using-git-worktrees`.
   Absent → inline: detect existing isolation (`git rev-parse --git-dir` vs `--git-common-dir`),
   prefer a native worktree tool, else `git worktree add` under an ignored `.worktrees/`;
   run project setup and verify a clean test baseline before implementing.
2. **Execute in this session, or spawn subagents?** Same trade-off superpowers frames.
   Default: **subagent-driven** when subagents are available (fresh context per task, review
   between, higher quality); otherwise **inline** sequential execution. This picks Step 2's
   sub-mode below.

## Execution order

Follow the breakdown's phase order and dependencies. Finish one phase's plan completely
(all tasks + tests + review + integration) before starting the next. Offer to pause between
phases for the user to review. **Exception:** two *parallel-eligible* contract-isolated plans
may run concurrently — see [Parallel tracks](#parallel-tracks-contract-isolated).

## Parallel tracks (contract-isolated)

When the breakdown marks a **backend (provider)** plan and a **frontend (consumer)** plan
*parallel-eligible* — they share only the frozen contract artifact and touch disjoint files —
run them **concurrently, one worktree per track**, per `coordinating-api-contract`. Conditions,
all required:

1. **Contract frozen first.** `docs/plan/contracts/<feature>.*` exists, is versioned, and is
   approved. No frozen contract → no parallel; run sequentially.
2. **Separate worktrees.** Each track in its own worktree (removes the file-conflict reason the
   one-implementer rule guards against). The "one implementer at a time" rule holds **within** a
   worktree — it is per-worktree, not global.
3. **Build to the contract.** Backend implements to it as provider (provider-conformance tests);
   frontend builds against a contract-derived mock as consumer (consumer-parity tests). Neither
   invents a shape absent from the contract.
4. **Contract-change protocol on divergence.** If either track finds the contract wrong or
   insufficient, **stop that track** — do not work around it. Edit the artifact, bump its version,
   re-approve, and re-sync **both** tracks before continuing (see the stop condition below).
5. **Integration gate.** When both tracks finish, integrate: swap the frontend's mock for the real
   provider and run the **conformance gate** — provider conformance + consumer parity + drift check
   must pass — before the phase is considered built. Then review each track's diff via phase 5.

Each track keeps its own `progress.md` (below). If subagents aren't available for true concurrency,
fall back to sequential execution of the two plans — the frontend still builds against the mock, so
it is never blocked on the backend.

**Durable across sessions.** A parallel build spans sessions, so state lives on disk, committed:
maintain the **contract status ledger** `docs/plan/contracts/<feature>.status.md` (per track:
worktree, branch, synced-version, conformance; `⚠ NEEDS-RESYNC` when behind) alongside each track's
`progress.md`, and stamp both continuously. On resume (Invocation mode 3) they are how a later
session rediscovers both worktrees, sees which contract version each track built against, and knows
which track went stale after a contract bump — re-sync it before continuing. See
`coordinating-api-contract` *Durable state* + *Across sessions / resume*.

## The process (repeat per phase plan)

### Step 1: Load and review plan

1. Read the phase's `docs/plan/phases/<N-slug>/plan.md`.
2. **Pre-flight review** — scan the plan once for conflicts: tasks that contradict each other
   or the Global Constraints, and anything the plan mandates that a review rubric treats as a
   defect (a test that asserts nothing, verbatim duplicated logic). Batch every finding into
   **one** question to the human before starting — not one interrupt per discovery. Clean scan
   → proceed silently.
3. Note context, Global Constraints, and the **interfaces consumed from earlier phases**.
4. Create a todo per task.

### Step 2: Execute tasks

**Sub-mode A — Subagent-driven** (mirrors `superpowers:subagent-driven-development`):
- Dispatch a **fresh implementer subagent per task** — hand it its task brief, consumed
  interfaces, and Global Constraints; never your session history. Answer its questions before
  it proceeds.
- Implementer implements, tests, commits, self-reviews, reports status (DONE /
  DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED).
- After each task, run a **task review** (spec compliance **and** code quality) against the
  diff, and verify the **coverage gate** — every changed file ≥95% (statements/branches/functions/
  lines) and the global total not regressed; show the coverage report. Dispatch a fix subagent for
  Critical/Important findings (a sub-95% changed file is one), then re-review until clean.
- **Model selection** — cheapest tier for mechanical/transcription tasks, standard for
  integration, most capable for design and the final whole-branch review. Specify the model
  explicitly on every dispatch.
- **One implementer at a time _per worktree_** (parallel implementers in the same worktree
  conflict). The only sanctioned concurrency is contract-isolated tracks in **separate**
  worktrees (see [Parallel tracks](#parallel-tracks-contract-isolated)); within any one worktree,
  still one implementer at a time. **Continuous execution** — don't check in between tasks; the
  only stops are an unresolvable BLOCKED, genuine ambiguity, or all tasks done.
- After all tasks, dispatch **one** final whole-branch code review on the most capable model.

**Sub-mode B — Inline** (mirrors `superpowers:executing-plans`):
- For each task: mark in_progress → follow each bite-sized step exactly (the plan carries the
  code and commands) → run the verifications as specified → mark completed.
- Stop and ask the moment a step is unclear or a verification fails.

Both sub-modes: never start implementation on `main`/`master` without explicit user consent.

### Step 3: Review, then complete development

After every task in the phase plan passes and is verified, the phase is **built and committed but
not yet done** — it must pass review first.

**First, sync the layered project-context docs.** If this phase **scaffolded or reshaped the
directory structure** (created a source tree, a new package/app/service, or a meaningful source
directory), give **each meaningful source directory** its own light `CLAUDE.md` (what the subtree
is, its key files/entry points, local conventions and gotchas — pointers, not prose) with an
`AGENTS.md` symlink beside it (`ln -s CLAUDE.md AGENTS.md`), and keep the root `CLAUDE.md` in sync
— in this phase's commits, never later. The root was seeded at bootstrap; the layered subtree docs
are created here, once the directories exist. Follow `implementing-documentation` (Supporting
docs → project context docs). This is the layered form of the keep-docs-synced convention that the
Stop doc-sync hook only reminds about for the root.

Then review. **REQUIRED SUB-SKILL:** use
`reviewing-phase-implementation` (phase 5) to review this phase against its design doc and plan.
**Defer the merge until review approves** — until then the natural finish is keep-as-is (or open a
PR); do not merge to the base branch on unreviewed work.

Once review approves the phase, complete development:
- superpowers present → **REQUIRED SUB-SKILL:** `superpowers:finishing-a-development-branch`.
- Absent → inline: **verify tests pass** (stop if not) → **detect environment**
  (`--git-dir` vs `--git-common-dir`) → present **exactly 4 options** (1. merge to base locally,
  2. push + open PR, 3. keep as-is, 4. discard; **3 options** on detached HEAD, no merge) →
  execute the choice → clean up the worktree **only for options 1 and 4** (and only a worktree
  you created under `.worktrees/`), requiring a typed `discard` confirmation for option 4.

Then move to the **next phase's plan** — return to Step 1 — until all phases are built, reviewed, and done.

## Progress log (durable memory)

**Always write progress and changes to a committed doc as you go** — not only to todos or
git-ignored scratch. It serves three jobs: it survives compaction (a lost controller has
re-run entire completed phases), it is the **resume ledger**, and it is a **shared memory** any
other agent can read to review the implementation without replaying the session.

- **Location:** `docs/plan/phases/<N-slug>/progress.md`, one per phase — beside that phase's
  `plan.md`. Commit it (it is a project record, not throwaway scratch). Fill
  [references/progress-template.md](references/progress-template.md). For a **parallel contract
  track**, stamp its header with `Contract: <path> @ <synced-version>` and `Sibling track: …`, and
  also maintain the shared **contract status ledger** `docs/plan/contracts/<feature>.status.md` —
  the second durable record a later session resumes both tracks from.
- **Write continuously**, in the same message as your other bookkeeping — after each task
  completes and again when the phase finishes. Never batch it to the end.
- **Per task, record:** task name/number and **status** (complete / blocked); a one-line summary
  of what changed; **files touched**; the **commit hashes/range** (`<base7>..<head7>`); the
  **test result** (command + pass count); the **review verdict** (clean / findings + how
  resolved); and any **deviation from the plan or decision made**, with why.
- **Per phase, record:** a done marker, the finish option chosen (merge / PR / keep / discard),
  the branch/PR reference, and any open follow-ups.
- **On resume:** trust this log and `git log` over recollection. Anything marked complete is
  DONE — do not re-execute it; continue at the first incomplete task.
- The commits it names exist in git even when context no longer remembers creating them. If
  `git clean -fdx` or similar destroys uncommitted state, recover from the committed log + `git log`.

## When to stop and ask for help

**STOP immediately when:**
- A blocker appears — missing dependency, failing test, unclear instruction.
- The plan has critical gaps that prevent starting.
- You don't understand an instruction.
- A verification fails repeatedly.
- A subagent reports BLOCKED you cannot resolve, or a finding conflicts with what the plan
  mandates (that is the human's call — present the finding beside the plan text, ask which governs).
- **A parallel track needs the API contract to change** (a shape is wrong, missing, or
  insufficient). Stop that track — do not work around the contract or invent a field. Run the
  **contract-change protocol** (`coordinating-api-contract`): edit `docs/plan/contracts/<feature>.*`,
  bump the version, re-approve, and re-sync both tracks before continuing.

Ask for clarification rather than guessing.

## When to revisit earlier steps

**Return to Step 1 (review) when:**
- The partner updates the plan based on your feedback.
- The fundamental approach needs rethinking.
- An earlier phase changed reality (interface, data shape) in a way that invalidates a later
  phase's plan → send that phase back through `planning-each-phase` to re-plan before executing it.

Don't force through blockers — stop and ask.

## Remember

- Execute **one phase plan at a time, in dependency order** — never a merged plan.
- Standalone runs are fine — a named plan, or resume from the ledger; check dependencies before
  running a single plan out of order, and never re-run completed work.
- Review each plan critically before starting.
- Follow the plan's steps exactly; don't skip verifications.
- **Coverage gate before done** — tests green *and* ≥95% per changed file + global not regressed
  (show the report); a sub-95% file is not done.
- **Layered docs before done** — a phase that scaffolds/reshapes structure gives each meaningful
  source directory its own `CLAUDE.md` + `AGENTS.md` symlink and keeps the root in sync, in the
  same phase (via `implementing-documentation`).
- Subagent mode: one implementer at a time **per worktree** (same-worktree parallel = conflicts);
  task review after each. Contract-isolated tracks in separate worktrees are the one exception.
- Always write progress + changes + commits to the committed `progress.md` per phase — it is
  the resume ledger and a shared memory other agents review the implementation from.
- Reference the skills the plan tells you to.
- Stop when blocked, don't guess.
- Never start implementation on `main`/`master` without explicit user consent.

## Common Mistakes

- Running execution on a combined plan instead of per phase.
- Executing a later phase before the earlier one it depends on.
- Skipping the task review (subagent mode) or the verifications (inline mode).
- Marking a task/phase done with tests green but the **coverage gate unmet** (a changed file under
  95%, or a global regression) — that is not done.
- Dispatching parallel implementer subagents **into the same worktree** — they conflict. (Separate
  worktrees for contract-isolated backend/frontend tracks are fine — that's the sanctioned exception.)
- Running backend and frontend tracks in parallel **without a frozen contract** between them, or
  letting a track change a request/response shape in code instead of running the contract-change protocol.
- Not writing/committing `progress.md`, or only updating it at the end — write it after each task,
  or resume and cross-agent review have nothing to read.
- Scaffolding a new source tree/package but leaving only the root `CLAUDE.md` — each meaningful
  source directory needs its own layered `CLAUDE.md` + `AGENTS.md` symlink, created in the same phase.
- Running a single named plan whose earlier-phase dependencies aren't done, without warning the user.
- Cleaning up a harness-owned worktree, or one for option 2/3.

## Output

Each phase's plan implemented, tested, reviewed, and integrated per the chosen finish option,
plus a committed `docs/plan/phases/<N-slug>/progress.md` per phase recording status, changes,
files, commits, tests, and decisions — durable memory another agent can review from. All phases
complete → the feature is built.
