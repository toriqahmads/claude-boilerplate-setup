---
name: debugging-an-issue
description: Use when investigating a bug, incident, test failure, regression, performance problem, or unexpected behavior to find the ROOT CAUSE and write a diagnosis + resolution-approach doc that feeds the planning workflow (brainstorm → plan → execute → review). Works from logs, traces, metrics, observability, affected code, and reproduction. Delegates to superpowers:systematic-debugging for the root-cause method when installed. Triggers on "debug this", "find the root cause", "why is X failing", "investigate this incident".
---

# Debugging an Issue

## Overview

Find the **true root cause** of an issue, then write a diagnosis doc (root cause + how to resolve)
that becomes the source of truth for the planning workflow — so the fix is designed, planned,
executed, and reviewed like any other work, not hot-patched. This is an **investigation** skill:
investigate → diagnose → document → hand off. It does not ship a fix; it produces the artifact the
fix is built from.

## The Iron Law

```
NO FIX PROPOSAL WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

Symptom fixes are failure. You cannot propose a resolution until you have traced the cause to its
source and can prove it. This holds even under incident pressure — a mitigation may stop the
bleeding, but it is not the fix (see When to stop).

## Delegation

Check whether the `superpowers` plugin's debugging skill is available:

```bash
ls ~/.claude/plugins/cache/*/superpowers/*/skills/systematic-debugging/SKILL.md 2>/dev/null \
  && grep -q '"superpowers@claude-plugins-official": true' ~/.claude/settings.json && echo use-superpowers
```

- **Available** → **REQUIRED SUB-SKILL:** use `superpowers:systematic-debugging` for the four-phase
  root-cause method. This skill wraps it with broader evidence gathering (traces / metrics /
  observability), the committed **diagnosis doc**, and the **planning handoff**.
- **Not available** → run the inline process below (mirrors it).

## Tools you may need (MCP / skills / plugins)

Reach for whatever the issue's evidence lives in — search deferred tools with `ToolSearch`:

- **Observability / error tracking MCP** — Sentry, Datadog, Grafana, Honeycomb, New Relic,
  CloudWatch, OpenTelemetry. Pull the error, its frequency/first-seen/release, breadcrumbs, traces,
  and metric dashboards. The boilerplate can add an optional `sentry` MCP server
  (`claude mcp add --transport http sentry https://mcp.sentry.dev/mcp`) to pull evidence
  directly; see `CLAUDE.md` / `README.md` `## MCP servers`.
- **Logs** — app/server logs, CI logs, `journalctl`, `docker logs`, `kubectl logs`.
- **Tracing** — distributed traces by trace/request ID; APM spans across service boundaries.
- **context7 MCP** (`resolve-library-id` → `query-docs`) — for the real semantics of a
  library/framework/SDK. Do not guess a dependency's behavior.
- **WebSearch** — exact error strings, known issues, advisories/CVEs.
- **git** — recent changes, `git log`/`diff`, `git bisect` to find the introducing commit.
- **superpowers:test-driven-development** — write the failing reproduction test.
- **superpowers:verification-before-completion** — confirm the root cause with evidence, not assertion.

## The process

Do these in order. Create a todo per step. Do not skip to a fix.

### Step 0: Frame the issue

Capture precisely, into the diagnosis-doc scaffold from the start: observed vs expected behavior;
when it started; blast radius (who/what affected); severity; environment(s). Collect identifiers:
error message + full stack, request/trace IDs, timestamps, affected endpoints/users, build/commit/version.

### Step 1: Gather evidence (multi-channel — do NOT fix yet)

Pull from every available channel; each narrows **where** it breaks:

- **Error messages & stack traces** — read completely, note exact `file:line`, error codes; keep the
  exact strings. The first error usually matters more than the cascading ones.
- **Logs** — around the timestamp; grep the trace/request ID end-to-end; container/orchestrator logs.
- **Traces** — the failing request's distributed trace; which span errors or slows; the cross-service
  boundary where data first goes bad.
- **Metrics** — error rate, latency p50/p95/p99, saturation (CPU/mem/connections), throughput; when
  did the curve break, and does that line up with a deploy/config change?
- **Observability / dashboards** — Sentry issue detail, APM, RUM; releases correlated with first-seen.
- **Affected code** — read the exact lines in the stack, the function, its callers, and its inputs.
- **Recent changes** — `git log`/`diff` since last-known-good; correlate first-seen with a
  commit / deploy / dependency bump / config / infra change; `git bisect` when the window is wide.
- **Environment / config** — differences between envs where it does vs doesn't happen (flags, secrets,
  versions).
- **Multi-component systems** — instrument each component boundary (log what enters and exits), run
  once, and read which layer fails before investigating that layer in depth.

### Step 2: Reproduce

Build a reliable reproduction: exact steps/inputs, minimal case; every time or intermittent? If it
is **not reproducible**, gather more data (add logging/tracing) — do not guess. Note the conditions
(timing, concurrency, data-dependent, load). Capture the repro as a **failing test** where possible
(test-driven-development skill) — it is both proof and the regression guard.

### Step 3: Trace to the root cause

- **Backward data-flow tracing** — where does the bad value/state originate? What called it with bad
  input? Keep tracing up to the source. Fix at the source, not the symptom.
- **Pattern analysis** — find a working example in the codebase; diff working vs broken; list every
  difference, however small; understand the dependencies, config, and assumptions.
- **One hypothesis at a time** — state it: "X is the root cause because Y." Test minimally, one
  variable. Confirmed → Step 4. Not confirmed → form a NEW hypothesis; don't stack fixes. **If 3+
  hypotheses/fixes fail → stop and question the architecture** (this is a wrong-design signal, not a
  failed guess) and escalate.

### Step 4: Confirm the root cause

Prove it before writing it up: the failing repro test, the evidence chain that points to one origin,
and a minimal experimental change that flips the behavior (a spike, not the shipped fix). Separate
the **root cause** from contributing factors and downstream symptoms.

### Step 5: Write the diagnosis doc

Save to `docs/plan/diagnostics/YYYY-MM-DD-<topic>-diagnosis.md` and commit it — fill
[references/diagnosis-template.md](references/diagnosis-template.md). Structure:

- **Summary** — one paragraph: symptom, root cause, impact.
- **Symptom & impact** — observed vs expected, severity, blast radius, environments, first-seen.
- **Evidence** — the channels that mattered: the shortest decisive log lines, trace IDs, the metric
  shift, the Sentry/APM link, the affected `file:line`, the correlating commit/deploy. **Link, don't
  dump** raw logs.
- **Reproduction** — exact steps / the failing test.
- **Root cause** — the true cause traced to its source, with the reasoning chain; contributing
  factors kept separate from the cause.
- **Resolution approach** — how to fix at the **root** (not the symptom): the change and alternatives
  considered; the fix's blast radius, risks, and rollback; tests to add (unit / integration / E2E
  **plus a regression test for this exact bug**); and the observability/alerting to add so it's
  caught earlier next time.
- **Out of scope / follow-ups.**

### Step 6: Hand off to the planning workflow

The diagnosis doc is the **source of truth**. **REQUIRED SUB-SKILL:** hand to `planning-work-in-phases`
— brainstorming fast-paths (the diagnosis already defines goal + approach), then breakdown → plan →
execute → review, with the **regression test as a first-class plan requirement**. Scale to size: a
tiny one-line fix still gets a diagnosis, a regression test, and a review — just lighter phases.

## When to stop and ask for help

- **Not reproducible** after evidence gathering → present findings, ask for more access/data.
- **3+ hypotheses/fixes failed** → architectural problem; escalate, don't attempt fix #4.
- **Root cause spans systems you don't own** → involve the owners.
- **Live incident** → a mitigation (rollback / feature flag / scale-up) may be applied first to stop
  the bleeding, but the root-cause investigation and diagnosis doc STILL follow. Mitigation is not the fix.

## When to revisit earlier steps

- New evidence contradicts the current hypothesis → back to Step 1/3.
- The fix experiment reveals deeper coupling → back to Step 3 and question the architecture.

## Remember

- Root cause before fixes — always. Symptom fixes are failure.
- Gather evidence from every channel (logs, traces, metrics, observability, affected code, recent
  changes) before theorizing.
- Reproduce reliably; capture the repro as a failing test.
- One hypothesis, one variable, minimal test; 3+ failures = question the architecture.
- The diagnosis is a **committed doc** that feeds plan → execute → review; always add a regression
  test and observability so the bug can't return silently.
- Mitigation ≠ fix — still find the root cause.
- Don't guess a library's behavior — use context7.

## Common Mistakes

- Proposing a fix before establishing root cause.
- Reading only the last error instead of the first error and the full trace.
- Fixing the symptom line instead of the origin of the bad value.
- Skipping reproduction, or shipping without a regression test.
- Not writing the diagnosis doc — the knowledge is lost and the fix can't be planned or reviewed.
- Dumping raw logs into the doc instead of the decisive lines plus links.

## Output

A committed diagnosis doc at `docs/plan/diagnostics/YYYY-MM-DD-<topic>-diagnosis.md` — root cause,
evidence, reproduction, and a root-level resolution approach with a regression-test plan — handed to
`planning-work-in-phases` for design → plan → execute → review.
