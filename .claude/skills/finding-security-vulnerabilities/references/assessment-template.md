# Security Assessment Template

Copy into `docs/plan/security/YYYY-MM-DD-<topic>-security-assessment.md` and commit. One entry per
**confirmed** finding (reachable + real impact). Redact live secrets. Link evidence, don't dump raw
scanner logs. This doc is the source of truth handed to `planning-work-in-phases`.

```markdown
# <Topic> — Security Assessment

**Status:** Findings confirmed
**Assessed:** <scope>   **Date:** <timestamp>
**Counts:** Critical <n> · High <n> · Medium <n> · Low <n>

## Scope & threat model
- Assessed: <components/features>   Not assessed: <out of scope>
- Trust boundaries / entry points: <...>
- Actors & privileges: <...>

## Findings

### F1: <title>
- **Severity:** Critical | High | Medium | Low  (CVSS <score/vector>)
- **Category:** <OWASP category / class>
- **Location:** `file:line` / `<endpoint>`
- **Evidence:** <taint chain / scanner rule / PoC — shortest decisive form, secrets redacted>
- **Reachability:** <how untrusted input reaches the sink>
- **Impact:** <what an attacker gains>
- **Remediation approach:** <root fix — parameterize / encode / enforce authz / upgrade+pin /
  rotate leaked secret; alternatives; blast radius; **security regression test** to add>

### F2: <title>
- ... same fields ...

## Out of scope / accepted risks / follow-ups
- <...>
```

Remediation order in the plan: Critical/High first. Every fix carries a security regression test.
Rotate any exposed secret — deleting it from code is not enough.
```
