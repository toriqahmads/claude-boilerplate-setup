---
name: implementing-devops
description: >
  Use when implementing DevOps/infra from a plan — CI/CD pipelines, IaC (Terraform/
  Pulumi/CloudFormation), containerization (Dockerfiles/compose), Kubernetes manifests,
  and deploy/config scripts — in whatever tooling the plan specifies. Encodes craft:
  idempotency, least privilege, secrets via a manager (never plaintext), pinned
  versions, safe rollout/rollback, and dry-run/validate before apply. Followed by the
  devops-executor subagent. Triggers on "write the pipeline", "add the Terraform",
  "containerize this", "set up the deploy", "write the k8s manifest".
---

# Implementing devops

Execution-time craft for infrastructure and delivery. Followed by the
`devops-executor` subagent. Runs ON TOP of the execution method — **follow
`executing-phase-plans`** and validate/dry-run in place of unit TDD where a test
harness doesn't fit. This skill is the safety bar for changes that can take down an
environment.

## Goal

Apply the plan's infra/CI/CD changes **safely and reproducibly** — idempotent,
least-privilege, secret-safe, and rollback-able — validated before they touch a real
environment. Infra changes have blast radius; treat every apply as production until
proven otherwise.

## Stack

The plan dictates the tooling (GitHub Actions/GitLab CI, Terraform/Pulumi, Docker, k8s,
etc). Match the repo's existing pipelines/modules/manifests and conventions; use
context7 for the tool's exact syntax. No new provider/tool the plan didn't sanction
without flagging it.

## Craft checklist (per change)

1. **Validate before apply.** `terraform plan` / `kubectl --dry-run` / `docker build` /
   CI lint locally; review the diff/plan before anything mutates real state. Never
   blind-apply.
2. **Idempotency.** Re-running produces the same state, no duplicates or drift. Declare
   desired state (IaC) rather than imperative one-shots where possible.
3. **Least privilege.** Scope IAM/roles/service accounts to exactly what's needed;
   no wildcard admin. Default-deny network/security groups.
4. **Secrets.** From a secret manager / CI secret store, never in code, image layers,
   logs, or state files. Reference, don't embed. Rotate-friendly.
5. **Pinned versions.** Pin base images, providers, actions, and chart versions
   (digests where feasible) for reproducibility; no floating `latest`.
6. **Safe rollout/rollback.** Staged rollout (canary/blue-green/rolling) per the plan;
   health checks and a defined rollback/rollforward. Migrations gated and ordered vs
   deploy.
7. **Observability & limits.** Health/readiness probes, resource requests/limits,
   log/metric wiring; alarms where the repo does.
8. **Least surprise.** Small, reviewable changes; document required manual steps and
   env vars.
9. **Conventions.** Match the repo's module/pipeline/manifest structure and naming.

## Cross-cutting

- **Auth / secrets handling** in deployed services coordinates with
  `implementing-auth-and-authorization` (secret storage, service identity, least
  privilege).
- **Observability** — follow `implementing-observability`: wire log/metric/trace
  shipping, resource metrics, health probes, dashboards, and alert rules **as code**,
  and ensure telemetry config + sampling deploy with the service. A service you can't
  observe in the target environment isn't done.

## Guardrails

- **Dry-run/validate first — always.** No apply to real state without a reviewed plan.
- **No plaintext secrets** anywhere — code, images, logs, state.
- **Least privilege, default-deny.** No wildcard IAM or open security groups.
- **Rollback defined** before rollout. Destructive infra ops (delete/replace of stateful
  resources) flagged and gated on confirmation.
- **Pin versions.** Reproducible or it's a defect.
- **Wire the coverage gate into CI.** The pipeline runs tests with coverage and **fails below 95%**
  (per-file for changed files + global, no regression) — as code, so it can't be skipped. The gate
  applies to code with a coverage harness; infra code itself uses validate/dry-run, not a % target.
- **Plan is the contract;** report blockers, don't improvise infra.

## When to stop / complete

A change is complete when it validates/plans cleanly, is idempotent, secret-safe,
least-privilege, and has a rollback — and the reviewed plan/diff is shown. Stop and
report when validated and `progress.md` updated, OR when an apply would destroy/replace
stateful resources and needs sign-off, OR when blocked — report specifics, hand back.

## Output

Per change: files added, the validate/plan/dry-run output (the reviewed diff), secret
and IAM handling notes, rollout/rollback plan, any destructive op flagged for
confirmation, and required manual steps. Keep `progress.md` current.
