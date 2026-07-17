# Diagnosis Doc Template

Copy into `docs/plan/diagnostics/YYYY-MM-DD-<topic>-diagnosis.md` and commit. Link evidence, don't
dump raw logs — quote the shortest decisive lines. This doc is the source of truth handed to
`planning-work-in-phases`.

```markdown
# <Topic> — Diagnosis

**Status:** Root cause confirmed
**Severity:** Critical | High | Medium | Low
**First seen:** <timestamp>   **Environments:** <prod / staging / ...>

## Summary
<One paragraph: symptom, root cause, impact.>

## Symptom & impact
- Observed: <what happens>
- Expected: <what should happen>
- Blast radius: <who/what affected>

## Evidence
- Error/stack: `<shortest decisive line>` at `file:line`
- Logs: <trace/request id>, <key line or link>
- Trace: <trace id / failing span / boundary where data goes bad>
- Metrics: <the shift — error rate / p95 / saturation — and when it broke>
- Observability: <Sentry/APM link>
- Correlating change: <commit / deploy / dependency / config>

## Reproduction
<Exact steps / minimal case, or the failing test.>

## Root cause
<The true cause traced to its source, with the reasoning chain.>
**Contributing factors (not the cause):** <list>

## Resolution approach
- Root fix: <the change at the source — not the symptom>
- Alternatives considered: <...>
- Blast radius / risk / rollback: <...>
- Tests to add: unit / integration / E2E + **regression test for this exact bug**
- Observability to add: <so it's caught earlier next time>

## Out of scope / follow-ups
- <...>
```
