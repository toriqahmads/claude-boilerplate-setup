---
name: finding-security-vulnerabilities
description: Use when auditing code or a feature for security vulnerabilities — a dedicated, comprehensive security assessment (SAST, dependency/SCA, secrets scanning, dynamic checks, config/IaC, authn/authz, taint analysis, OWASP categories) that finds and confirms real vulnerabilities and writes an assessment + remediation-approach doc that feeds the planning workflow (plan → execute → review). Optionally invoked from reviewing-phase-implementation. Delegates to the official Claude security-review skill when available. Triggers on "find vulnerabilities", "security audit", "pentest this code", "is this secure", "vulnerability assessment", "threat model this", "run a security review", "check for OWASP issues", "audit dependencies for CVEs".
---

# Finding Security Vulnerabilities

## Overview

Hunt for **real, confirmed** vulnerabilities, then write an assessment doc (findings +
remediation) that becomes the planning workflow's source of truth — each fix gets designed,
planned, executed, and reviewed like any other work, never patched blind. Same shape as
`debugging-an-issue`: investigate → confirm → document → hand off; produces the artifact fixes
are built from, ships no fixes itself.

**Authorized use only.** Assess only code/systems you're authorized to test — your own project, a
scoped engagement, a CTF, or defensive review. Never target third-party systems without permission.

## The Iron Law

```
NO REPORTED VULNERABILITY WITHOUT CONFIRMING IT IS REAL AND REACHABLE
```

A finding isn't a vulnerability until reachability (attacker-controllable input) and real impact
are proven. Unconfirmed scanner output is a lead, not a finding — confirm before reporting.

## Delegation

Check whether the official Claude `security-review` skill is available (listed in your available
skills when installed); detect `superpowers` as in the other phase skills.

- **Available** → **REQUIRED SUB-SKILL:** use it for the core review pass. This skill wraps it with
  broader tooling (SCA / secrets / dynamic / IaC), exploitability confirmation, the committed
  **assessment doc**, and the **planning handoff**.
- **Not available** → run the inline process below.

## Tools you may need (MCP / skills / plugins)

Reach for whatever fits the stack — search deferred tools with `ToolSearch`:

- **SAST / static analysis** — Semgrep (+ MCP), CodeQL, Bandit (Python), Brakeman (Rails), gosec
  (Go), ESLint security plugins.
- **Dependency / SCA** — `pnpm audit` (preferred for JS — stricter, non-flat `node_modules`) or
  `npm audit`, `pip-audit`, `cargo audit`, `osv-scanner`, Snyk, Trivy, Grype; check lockfiles
  against advisory databases.
- **Secrets scanning** — `gitleaks`, `trufflehog`; scan tree + git history.
- **Config / IaC** — `checkov`, `tfsec`, `kube-score`, `trivy config` for Terraform/K8s/Docker.
- **Dynamic (authorized targets only)** — OWASP ZAP, Burp Suite, `nuclei` against a running instance.
- **context7 MCP** — real semantics of a framework's security controls (auth, escaping, CSRF).
- **WebSearch** — CVEs, advisories, exploit write-ups for the exact libraries/versions in use.
- **git** — history for introduced secrets or a regression that weakened a control.

## The process

Do these in order. Create a todo per step. Confirm before reporting.

### Step 0: Scope & threat model

Define what's assessed and how it's attacked: component/feature, trust boundaries, entry points
(HTTP endpoints, CLI, queues, file uploads, IPC), data handled (PII, secrets, money), actors and
privileges, what "compromise" means. Note stack/versions; write into the assessment-doc scaffold
from the start.

### Step 1: Map the attack surface

Enumerate every place untrusted input enters and every sensitive operation it can reach:
routes/handlers, params/headers/cookies/body, deserialization points, file/path handling, DB
queries, shell/exec calls, template rendering, outbound requests (SSRF), auth/session code,
crypto usage, privileged operations — the target list for the analysis below.

### Step 2: Analyze — multi-channel (don't report yet)

Run each channel; each surfaces different classes:

- **Static analysis (SAST)** — run language scanners over the diff/codebase; collect candidate
  sinks (injection, XSS, path traversal, unsafe deserialization, command exec).
- **Dependency / SCA** — scan lockfiles for known-vulnerable versions, incl. transitive ones.
- **Secrets** — scan tree + git history for keys/tokens/passwords.
- **Config / IaC** — insecure defaults, open ports/buckets, over-broad IAM, missing TLS, debug on.
- **Manual review by category** — walk the attack surface against the checklist below; scanners
  miss logic and authorization flaws.
- **Taint / data-flow tracing** — trace each dangerous sink backward: reachable from an untrusted
  source without sufficient validation/encoding? Reachability turns a candidate into a finding.
- **Dynamic (authorized only)** — fuzz inputs, tamper params/tokens, attempt the attacks the
  static pass suggested.

### Step 3: Category checklist (OWASP Top 10 + common classes)

- **Injection** — SQL/NoSQL, command, LDAP, template (SSTI), header, log.
- **Broken access control** — missing authz checks, IDOR, path/function-level bypass, privilege escalation.
- **Cryptographic failures** — weak/home-rolled crypto, plaintext secrets, weak hashing, bad randomness, missing TLS.
- **Insecure design** — missing rate limits, no lockout, trust of client-side checks, unsafe workflows.
- **Security misconfiguration** — verbose errors, default creds, permissive CORS, missing security headers.
- **Vulnerable / outdated components** — known-CVE dependencies (from Step 2).
- **Identification & auth failures** — weak session mgmt, JWT flaws, credential stuffing exposure, missing MFA where required.
- **Software & data integrity failures** — unsigned updates, insecure deserialization, CI/supply-chain risks.
- **Security logging & monitoring failures** — no audit trail for security events, secrets in logs.
- **SSRF** — user-controlled outbound URLs without allow-listing.
- Also: XSS (stored/reflected/DOM), CSRF, open redirect, mass assignment, race conditions/TOCTOU, file-upload handling.

### Step 4: Confirm & rate

For each candidate: **prove reachability and impact** — a minimal PoC or the exact input +
data-flow chain reaching the sink (PoC on an authorized target, or a failing security test).
Discard false positives; rate severity (CVSS or Critical/High/Medium/Low) by impact × likelihood;
note chained findings combining into a higher-severity path.

### Step 5: Write the assessment doc

Save to `docs/plan/security/YYYY-MM-DD-<topic>-security-assessment.md` and commit it — fill
[references/assessment-template.md](references/assessment-template.md). Structure:

- **Summary** — scope assessed, count by severity, top risks in one paragraph.
- **Scope & threat model** — what was and wasn't assessed, trust boundaries, actors.
- **Findings** — one entry per confirmed vuln: title; **severity** (+ CVSS); category (OWASP);
  affected `file:line` / endpoint; **evidence** (the taint chain, scanner rule, or PoC — shortest
  decisive form, redact live secrets); **reachability** (how untrusted input gets there);
  **impact**; and **remediation approach** (the root fix — parameterize, encode, enforce authz,
  upgrade/pin, rotate the leaked secret — with alternatives, blast radius, and a
  **regression/security test** to add).
- **Out of scope / accepted risks / follow-ups.**

### Step 6: Hand off to the planning workflow

The assessment doc is the **source of truth**. **REQUIRED SUB-SKILL:** hand to
`planning-work-in-phases` — brainstorming fast-paths (findings define goal + approach), then
breakdown → plan → execute → review, with each fix's **security regression test** a first-class
plan requirement. Order remediation by severity, Critical/High first; even a single finding gets
an assessment entry, a security test, and a review.

## Invoked from the review phase (optional)

`reviewing-phase-implementation` runs a **security pass** on every phase — that's the baseline.
This skill is the **deeper, dedicated audit**: invoke from the review phase only when warranted
and the user opts in (ask) — auth/crypto/payments/PII/file-uploads/external-input touched; a
scanner flagged something needing investigation; or a full audit is requested. Its assessment doc
feeds remediation back through the planning workflow.

## When to stop and ask for help

**Can't confirm reachability** → report as a lead needing more access/data, not a finding.
**Dynamic testing would hit out-of-scope / unowned systems** → stop, get authorization first.
**Live-exploitable Critical found in production** → surface immediately for mitigation
(patch/flag/block) alongside the write-up — mitigation ≠ the planned fix. **Root cause spans
systems you don't own** → involve the owners.

## When to revisit earlier steps

A confirmed finding reveals a new entry point → back to Step 1 (attack surface), re-scan. A
chained exploit path emerges → re-rate severity (Step 4) for the combined path.

## Remember

Confirm reachability + impact before reporting — scanner output is a lead, not a finding. Cover
every channel (SAST, SCA, secrets, config/IaC, manual, taint, dynamic) — no single tool finds all
classes. Authorized targets only; dynamic testing needs explicit scope. The assessment is a
**committed doc** feeding plan → execute → review; every fix gets a security regression test.
Rate by impact × likelihood; watch for low findings chaining into a Critical path. Rotate any
exposed secret immediately — deleting it from code isn't enough. Don't guess a framework's
security control — verify with context7.

## Common Mistakes

Raw unconfirmed scanner output reported as a finding; SAST-only coverage (misses authz/logic
flaws); leaked secret deleted but never rotated; no regression test (hole reopens silently); no
assessment doc written (findings lost); full scanner logs dumped instead of decisive evidence +
links; dynamic tests run outside authorized scope.

## Output

The committed assessment doc (Step 5) — scope, confirmed findings with severity/evidence/
reachability/impact, root-level remediation with security-test plans — handed to
`planning-work-in-phases` (Step 6).
