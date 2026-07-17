---
name: finding-security-vulnerabilities
description: Use when auditing code or a feature for security vulnerabilities — a dedicated, comprehensive security assessment (SAST, dependency/SCA, secrets, dynamic checks, config/IaC, authn/authz, taint analysis, OWASP categories) that finds and confirms real vulnerabilities and writes an assessment + remediation-approach doc that feeds the planning workflow (plan → execute → review). Optionally invoked from reviewing-phase-implementation. Delegates to the official Claude security-review skill when available. Triggers on "find vulnerabilities", "security audit", "pentest this code", "is this secure".
---

# Finding Security Vulnerabilities

## Overview

Hunt for **real, confirmed** security vulnerabilities in the code or feature, then write an
assessment doc (findings + how to remediate) that becomes the source of truth for the planning
workflow — so each fix is designed, planned, executed, and reviewed like any other work, not
patched blind. Same shape as `debugging-an-issue`: investigate → confirm → document → hand off.
It does not ship fixes; it produces the artifact the fixes are built from.

**Authorized use only.** Run this against code and systems you are authorized to assess — your own
project, a security engagement with scope, a CTF, or defensive review. Do not target third-party
systems you don't own or have permission to test.

## The Iron Law

```
NO REPORTED VULNERABILITY WITHOUT CONFIRMING IT IS REAL AND REACHABLE
```

A finding is not a vulnerability until you've established the vulnerable code is **reachable** with
attacker-controllable input and the impact is real. Unconfirmed scanner output is a lead, not a
finding — theoretical noise wastes the remediation effort. Confirm before you report.

## Delegation

Check whether the official Claude `security-review` skill is available (it is listed in your
available skills when installed). Also detect `superpowers` as in the other phase skills.

- **`security-review` skill available** → **REQUIRED SUB-SKILL:** use it for the core review pass.
  This skill wraps it with broader tooling (SCA / secrets / dynamic / IaC), confirmation of
  exploitability, the committed **assessment doc**, and the **planning handoff**.
- **Not available** → run the inline process below.

## Tools you may need (MCP / skills / plugins)

Reach for whatever fits the stack — search deferred tools with `ToolSearch`:

- **SAST / static analysis** — Semgrep (and its MCP), CodeQL, Bandit (Python), Brakeman (Rails),
  gosec (Go), ESLint security plugins.
- **Dependency / SCA** — `pnpm audit` (preferred for JS — stricter, non-flat `node_modules`) or
  `npm audit`, `pip-audit`, `cargo audit`, `osv-scanner`, Snyk, Trivy, Grype;
  check lockfiles against advisory databases.
- **Secrets scanning** — `gitleaks`, `trufflehog`; scan the tree and git history.
- **Config / IaC** — `checkov`, `tfsec`, `kube-score`, `trivy config` for Terraform/K8s/Docker.
- **Dynamic (authorized targets only)** — OWASP ZAP, Burp Suite, `nuclei` against a running instance.
- **context7 MCP** — real semantics of a framework's security controls (auth, escaping, CSRF).
- **WebSearch** — CVEs, advisories, exploit write-ups for the exact libraries/versions in use.
- **git** — history for introduced secrets or a regression that weakened a control.

## The process

Do these in order. Create a todo per step. Confirm before reporting.

### Step 0: Scope & threat model

Define what you are assessing and how it's attacked: the component/feature, its trust boundaries,
the entry points (HTTP endpoints, CLI, queues, file uploads, IPC), the data it handles (PII,
secrets, money), the actors and their privileges, and what "compromise" means here. Note the
stack and versions. Write this into the assessment-doc scaffold from the start.

### Step 1: Map the attack surface

Enumerate every place untrusted input enters and every sensitive operation it can reach: routes and
handlers, params/headers/cookies/body, deserialization points, file/path handling, DB queries,
shell/exec calls, template rendering, outbound requests (SSRF), auth/session code, crypto usage,
and privileged operations. This is the target list for the analysis below.

### Step 2: Analyze — multi-channel (don't report yet)

Run each channel; each surfaces different classes:

- **Static analysis (SAST)** — run the language's scanners over the diff/codebase; collect candidate
  sinks (injection, XSS, path traversal, unsafe deserialization, command exec).
- **Dependency / SCA** — scan lockfiles for known-vulnerable versions; note transitive ones.
- **Secrets** — scan tree and git history for keys/tokens/passwords.
- **Config / IaC** — insecure defaults, open ports/buckets, over-broad IAM, missing TLS, debug on.
- **Manual code review by category** — walk the attack surface against the checklist below; scanners
  miss logic and authorization flaws.
- **Taint / data-flow tracing** — for each dangerous sink, trace backward: is it reachable from an
  untrusted source without sufficient validation/encoding in between? Reachability is what turns a
  candidate into a finding.
- **Dynamic (authorized only)** — exercise the running app: fuzz inputs, tamper params/tokens,
  attempt the attacks the static pass suggested.

### Step 3: Category checklist (OWASP Top 10 + common classes)

- **Injection** — SQL/NoSQL, command, LDAP, template (SSTI), header, log.
- **Broken access control** — missing authz checks, IDOR, path/function-level bypass, privilege escalation.
- **Cryptographic failures** — weak//home-rolled crypto, plaintext secrets, weak hashing, bad randomness, missing TLS.
- **Insecure design** — missing rate limits, no lockout, trust of client-side checks, unsafe workflows.
- **Security misconfiguration** — verbose errors, default creds, permissive CORS, missing security headers.
- **Vulnerable / outdated components** — known-CVE dependencies (from Step 2).
- **Identification & auth failures** — weak session mgmt, JWT flaws, credential stuffing exposure, missing MFA where required.
- **Software & data integrity failures** — unsigned updates, insecure deserialization, CI/supply-chain risks.
- **Security logging & monitoring failures** — no audit trail for security events, secrets in logs.
- **SSRF** — user-controlled outbound URLs without allow-listing.
- Also: XSS (stored/reflected/DOM), CSRF, open redirect, mass assignment, race conditions/TOCTOU, file-upload handling.

### Step 4: Confirm & rate

For each candidate: **prove reachability and impact** — a minimal proof-of-concept or the exact
input + data-flow chain that reaches the sink (a PoC on an authorized target, or a failing security
test). Discard false positives. Then rate severity (CVSS or Critical/High/Medium/Low) using
impact × likelihood, and note any chained findings that combine into a higher-severity path.

### Step 5: Write the assessment doc

Save to `docs/plan/security/YYYY-MM-DD-<topic>-security-assessment.md` and commit it — fill
[references/assessment-template.md](references/assessment-template.md). Structure:

- **Summary** — scope assessed, count by severity, top risks in one paragraph.
- **Scope & threat model** — what was and wasn't assessed, trust boundaries, actors.
- **Findings** — one entry per confirmed vuln: title; **severity** (+ CVSS); category (OWASP);
  affected `file:line` / endpoint; **evidence** (the taint chain, scanner rule, or PoC — shortest
  decisive form, redact live secrets); **reachability** (how untrusted input gets there);
  **impact**; and **remediation approach** (the root fix — parameterize, encode, enforce authz,
  upgrade/pin, rotate the leaked secret — with alternatives, blast radius, and a **regression/security
  test** to add).
- **Out of scope / accepted risks / follow-ups.**

### Step 6: Hand off to the planning workflow

The assessment doc is the **source of truth**. **REQUIRED SUB-SKILL:** hand to
`planning-work-in-phases` — brainstorming fast-paths (findings define the goal + approach), then
breakdown → plan → execute → review, with each fix's **security regression test** a first-class plan
requirement. Order remediation by severity; Critical/High first. Scale to size: a single finding
still gets an assessment entry, a security test, and a review.

## Invoked from the review phase (optional)

`reviewing-phase-implementation` runs a **security pass** on every phase. That pass is the baseline.
This skill is the **deeper, dedicated audit** — invoke it from the review phase only when it's
warranted and the user opts in (ask): the change touches auth, crypto, payments, PII, file uploads,
or external input; a scanner flagged something needing investigation; or the user requests a full
audit. Its assessment doc then feeds remediation back through the planning workflow.

## When to stop and ask for help

- **Can't confirm reachability** → report it as a lead needing more access/data, not a finding.
- **Dynamic testing would hit systems out of scope / not owned** → stop; get authorization first.
- **A live-exploitable Critical is found in production** → surface immediately for mitigation
  (patch/flag/block) in parallel with writing it up; note that mitigation ≠ the planned fix.
- **Root cause spans systems you don't own** → involve the owners.

## When to revisit earlier steps

- A confirmed finding reveals a new entry point → back to Step 1 (attack surface) and re-scan.
- A chained exploit path emerges → re-rate severity (Step 4) for the combined path.

## Remember

- Confirm reachability + impact before reporting — scanner output is a lead, not a finding.
- Cover every channel (SAST, SCA, secrets, config/IaC, manual, taint, dynamic) — no single tool finds all classes.
- Authorized targets only; dynamic testing needs explicit scope.
- The assessment is a **committed doc** that feeds plan → execute → review; every fix gets a security regression test.
- Rate by impact × likelihood; watch for low findings that chain into a Critical path.
- Rotate any exposed secret immediately — removing it from code is not enough.
- Don't guess a framework's security control — verify with context7.

## Common Mistakes

- Reporting raw scanner output without confirming exploitability (false-positive noise).
- Relying on SAST alone — it misses authorization and business-logic flaws.
- Finding a leaked secret and only deleting it, without rotating it.
- No security regression test, so the hole silently reopens.
- Not writing the assessment doc — findings are lost and can't be planned or reviewed.
- Dumping full scanner logs into the doc instead of the decisive evidence + links.
- Running dynamic tests against systems outside the authorized scope.

## Output

A committed assessment doc at `docs/plan/security/YYYY-MM-DD-<topic>-security-assessment.md` — scope,
confirmed findings with severity, evidence, reachability, impact, and root-level remediation with
security-test plans — handed to `planning-work-in-phases` for design → plan → execute → review.
