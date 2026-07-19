# Plan Reviewer Prompt

Optional: after the plan self-review, dispatch a fresh subagent to review the plan against the
spec/breakdown before execution. Fill and dispatch a `general-purpose` agent.

```
You are a plan document reviewer. Verify this plan is complete and ready for implementation.

Plan to review: <docs/plan/phases/<N-slug>/plan.md>
For reference: <docs/plan/specs/...-design.md> and <docs/plan/breakdown/...-breakdown.md>

Check:
- Completeness — no TODO / vague placeholder / missing step. A step at signature + test-case
  granularity is complete, NOT "incomplete"; flag the opposite too — full function/test bodies
  belong in execution, not the plan.
- Spec alignment — plan covers this phase's scope; no scope creep.
- Task decomposition — clear boundaries; steps actionable; each task independently testable.
- Buildability — could an engineer follow this without getting stuck?
- Interfaces — every consumed interface is produced by an earlier task/phase; names/types consistent.
- Tests — unit/integration/E2E present per the Testing Strategy; a regression test where relevant.

Only flag issues that would cause real problems during implementation (wrong build, stuck engineer,
vague placeholder content, full code bodies that belong in execution, contradictory steps). Minor
wording is not an issue.

Output:
## Plan Review
**Status:** Approved | Issues Found
**Issues (if any):**
- [Task X, Step Y]: [issue] — [why it matters]
**Recommendations (advisory, non-blocking):**
- [suggestion]
```
