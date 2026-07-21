# Progress Log Template

Copy into `docs/plan/phases/<N-slug>/progress.md`. **Committed** doc (not scratch). Write
continuously — after each task and again at phase finish, never batched to the end. It is the
resume ledger and a shared memory other agents review the implementation from.

Get timestamps from `date -u +%Y-%m-%dT%H:%M:%SZ` — never fabricate them.

```markdown
# Phase <N>: <Name> — Progress

**Plan:** <link to plan.md>
**Started:** <timestamp>   **Mode:** subagent-driven | inline   **Worktree:** <path or "in place">
<!-- Parallel contract track only (omit otherwise) — see coordinating-api-contract: -->
**Contract:** <docs/plan/contracts/<feature>.* @ <synced-version> | n/a>
**Sibling track:** <the other track's worktree/branch | none>

## Tasks
<!-- One block per task, appended the moment the task finishes (never batched). Status is
     COMPLETE | BLOCKED | IN PROGRESS. Keep each entry short but comprehensive. -->

### Task 1: <name> — COMPLETE
- Changed: <one-line summary>
- Files: <paths>
- Commits: `<base7>..<head7>`
- Tests: `<command>` → <N passed>
- Review: clean | <findings + how resolved>
- Deviations/decisions: <plan deviation + why, or "none">

### Task 2: <name> — BLOCKED
- Blocker: <what and why>
- Needs: <decision/context to unblock>

## Phase result
- Status: <done | in progress>   <!-- "done" ONLY when every task above is COMPLETE and phase 5 approved -->

- Finish: merge | PR #<n> | keep | discard
- Branch/PR: <ref>
- Conformance (contract track only): provider <PASS|FAIL|PENDING> · consumer-parity <…> · drift <…>
- Reviewed & approved: <timestamp> (see phase 5)   — filled by reviewing-phase-implementation
- Follow-ups: <deferred items / accepted Minors>
```
