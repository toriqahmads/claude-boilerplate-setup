# Progress Log Template

Copy into `docs/plan/phases/<N-slug>/progress.md`. **Committed** doc (not scratch). Write
continuously — after each task and again at phase finish, never batched to the end. It is the
resume ledger and a shared memory other agents review the implementation from.

Get timestamps from `date -u +%Y-%m-%dT%H:%M:%SZ` — never fabricate them.

```markdown
# Phase <N>: <Name> — Progress

**Plan:** <link to plan.md>
**Started:** <timestamp>   **Mode:** subagent-driven | inline   **Worktree:** <path or "in place">

## Tasks

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
- Status: <done | in progress>
- Finish: merge | PR #<n> | keep | discard
- Branch/PR: <ref>
- Reviewed & approved: <timestamp> (see phase 5)   — filled by reviewing-phase-implementation
- Follow-ups: <deferred items / accepted Minors>
```
