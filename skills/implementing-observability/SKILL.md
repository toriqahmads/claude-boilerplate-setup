---
name: implementing-observability
description: >
  Use when implementing anything with runtime behavior that needs to be operable in
  production — logging, distributed tracing, metrics, health checks, monitoring
  dashboards, and alerting. Encodes best practice: structured leveled logs with
  correlation IDs and no secrets/PII, spans that propagate context across services,
  RED/USE metrics, actionable SLO-based alerts, and health/readiness endpoints.
  Cross-cutting — backend, frontend, database, and devops executors follow it whenever
  a step ships behavior that must be observed. It is also a first-class design and
  planning concern. Triggers on "add logging/tracing/metrics", "instrument this",
  "make it observable", "add monitoring/alerting", "health check", "SLO/dashboard".
---

# Implementing observability

Cross-cutting craft for the three pillars — **logs, traces, metrics** — plus health,
monitoring, and alerting. Followed by whichever executor ships runtime behavior. Runs
on top of the domain skill and the execution method. Observability is not an
afterthought bolted on after an incident — it is designed in, planned as steps, and
built alongside the feature.

## Goal

Make every feature **operable in production** — you can see that it works, know when it
doesn't, and debug why without adding code after the fact. If a change has runtime
behavior, it emits the signals needed to answer: is it working, how well, and where did
a request fail.

## Stack

The plan/repo dictates the stack (OpenTelemetry, Prometheus/Grafana, Datadog, ELK,
Sentry, CloudWatch, structured-logging libs, etc). Match the repo's existing telemetry
setup, log format, and naming; use context7 for the library's exact API. Prefer
OpenTelemetry-style vendor-neutral instrumentation where the repo hasn't committed
otherwise. Don't roll your own if one exists.

## The three pillars + operational signals

1. **Structured logging.** Machine-parseable (JSON) key-value logs, not string
   interpolation. Correct levels (error/warn/info/debug); errors logged once with
   context at the boundary, not re-logged at every layer. **Never log secrets, tokens,
   passwords, or PII** — redact. Include a correlation/request ID on every line.
2. **Distributed tracing.** Instrument request entry points and cross-service/DB/queue
   calls with spans; **propagate trace context** (headers) across boundaries so one
   request is one trace. Record key attributes and error status on spans. Sample
   sensibly (head/tail) for cost.
3. **Metrics.** Emit the ones that answer operational questions: **RED** for
   request-driven services (Rate, Errors, Duration) and **USE** for resources
   (Utilization, Saturation, Errors). Business/domain metrics where the spec cares.
   Correct types (counter/gauge/histogram); bounded label cardinality (no user IDs as
   labels).
4. **Correlation.** A single request ID / trace ID flows through logs, traces, and (where
   possible) metrics exemplars, so you can pivot between them for one request.
5. **Health & readiness.** Liveness and readiness endpoints/probes that reflect real
   dependency health, for orchestrators and load balancers.
6. **Monitoring & dashboards.** The signals land somewhere queryable; a dashboard covers
   the feature's golden signals (latency, traffic, errors, saturation).
7. **Alerting.** Alerts on **symptoms/SLOs** (user-facing pain), not every raw metric —
   actionable, low-false-positive, with a clear owner. Tie to error budgets where the
   repo uses SLOs.

## By domain

- **Backend** — instrument entry points, downstream calls, and jobs; RED metrics;
  spans with propagation; structured logs with request ID; health endpoints.
- **Frontend** — error tracking (unhandled errors/rejections, error boundaries), core
  web vitals / real-user monitoring, key user-action events; propagate a trace header
  to the backend; no PII in client telemetry.
- **Database** — slow-query logging, query/connection-pool metrics; ensure app spans
  wrap DB calls; watch migration/backfill duration and lock time.
- **DevOps** — wire log/metric/trace shipping, resource metrics, health probes,
  dashboards, and alert rules as code; ensure telemetry config and sampling are
  deployed with the service.

## Guardrails

- **Designed in, not bolted on.** Instrument as part of the step, not after an incident.
- **Never log secrets or PII;** redact. Bounded metric label cardinality.
- **Log an error once**, at the boundary, with context — no re-logging at every layer.
- **Propagate context** across service/DB/queue boundaries — a broken trace is a defect.
- **Alert on symptoms/SLOs**, not noise. Every alert is actionable and owned.
- **Reuse the repo's telemetry stack and conventions;** vendor-neutral (OTel) when open.

## When to stop / complete

Complete when the step emits structured logs (with correlation ID, no secrets), the
relevant traces propagate, the RED/USE (and any business) metrics are exported, health
checks reflect real state, and any dashboards/alerts the plan calls for exist —
verified by observing the signals locally (log output, a trace, a scraped metric). Stop
and report the instrumentation added, or hand back if the telemetry setup itself is
missing and the plan didn't scope creating it.

## Output

Signals added (logs/traces/metrics/health), correlation approach, redaction notes,
dashboards/alerts touched, how you verified the signals appear, and anything left for
follow-up (e.g. an alert threshold needing a human decision).
