---
name: implementing-auth-and-authorization
description: >
  Use when implementing authentication or authorization from a plan — login/session/
  token issuance, password handling, MFA, and access control including RBAC and
  fine-grained / ABAC / relationship-based permissions. Encodes security best practice:
  strong password hashing, safe session/token handling, CSRF and secure cookies,
  server-side deny-by-default enforcement, centralized policy, per-resource checks that
  prevent IDOR, and least privilege. Cross-cutting — backend and frontend executors
  follow it whenever a step touches identity or access. Triggers on "add login/auth",
  "implement RBAC", "permission checks", "protect this endpoint/route", "who can access
  this", "session/JWT", "fine-grained authorization".
---

# Implementing auth & authorization

Cross-cutting execution craft for identity and access control — the highest-blast-
radius code in most systems. Followed by whichever executor touches auth
(`backend-executor` for enforcement, `frontend-executor` for UX gating). Runs on top
of the domain skill and the execution method. **Auth bugs are security incidents —
this bar is not optional.**

## Goal

Implement authentication and authorization that is **secure by default and enforced on
the server** — correct identity, and access decided by a centralized, deny-by-default
policy checked on every protected resource. The client never decides access; it only
reflects it.

## Stack

The plan/repo dictates the auth library and model (Passport/Auth.js, Devise, Spring
Security, OAuth/OIDC provider, Casbin/OPA/Oso/Cerbos, etc). Reuse the repo's existing
auth stack and patterns; use context7 for the library's exact API. **Do not hand-roll
crypto, token, or session primitives** when a vetted library exists.

## Authentication checklist

1. **Password storage** — hash with a memory-hard KDF (argon2id, scrypt, or bcrypt);
   never MD5/SHA/plaintext; per-user salt (built into these); tune work factor.
2. **Sessions vs tokens** — prefer server-side sessions or short-lived tokens with
   refresh. For JWT: verify signature and `alg` (reject `none`), check `exp`/`aud`/
   `iss`, don't store secrets in the payload, have a revocation story.
3. **Cookies** — `HttpOnly`, `Secure`, `SameSite` for session cookies; scope and
   expire them.
4. **CSRF** — protect state-changing requests on cookie-based auth (tokens/double-submit).
5. **Transport** — auth only over TLS; no credentials in URLs or logs.
6. **Brute-force defense** — rate-limit and back off login/OTP; lockout/alert on abuse;
   generic error messages (don't reveal which of user/password was wrong).
7. **MFA / account recovery** — implement per the plan; secure, expiring reset tokens;
   no account enumeration.

## Authorization checklist (RBAC / fine-grained)

1. **Enforce on the server, always.** Every protected operation checks authorization
   server-side, at the boundary or in a policy layer. UI/route hiding is UX only.
2. **Deny by default.** No explicit allow → denied. New endpoints are protected unless
   deliberately public.
3. **Model the permissions** — RBAC (roles→permissions), or fine-grained ABAC/ReBAC
   (attributes/ownership/relationship) when the plan needs per-resource rules. Assign
   least privilege.
4. **Per-resource / object-level checks.** Verify the caller may act on THIS record,
   not just the record type — prevents IDOR/BOLA. Never trust an ID from the client as
   authorization.
5. **Centralize policy.** One policy layer/module (or engine: OPA/Casbin/Oso/Cerbos),
   not authorization logic scattered and duplicated across handlers.
6. **Least privilege & separation.** Minimal roles; guard privilege escalation; sensitive
   actions may need re-auth/step-up.
7. **Consistent across surfaces.** API, background jobs, and any admin path enforce the
   same policy — no unprotected side door.

## Verification (required)

- **Authorization test matrix** — for each protected operation, test allowed roles AND
  denied roles, plus cross-tenant/other-user access (expect denied). Negative tests are
  mandatory, not optional.
- Test token/session tampering and expiry rejection.
- Confirm no secret/credential in logs, errors, or responses.

## Guardrails

- **Server enforces; client reflects.** Never rely on hidden UI for security.
- **Deny by default; least privilege.**
- **Object-level checks** on every resource access (no IDOR).
- **No hand-rolled crypto/tokens;** use vetted libraries and strong hashing.
- **No secrets in code/logs/responses;** generic auth errors (no enumeration).
- **Centralized, consistent policy** across every surface.
- **Negative authz tests before done.**

## When to stop / complete

Complete when authentication follows the checklist, every protected resource is
enforced server-side with deny-by-default and object-level checks, policy is
centralized, and the allow/deny test matrix (including cross-user) passes — shown.
Stop and report when verified and `progress.md` updated, OR when an auth decision
carries security risk needing human/security sign-off (flag it and consider the
`security-review` skill), OR when blocked — report specifics, hand back.

## Output

Per step: what auth/authz was implemented, the permission model, where enforcement
lives, the allow/deny (incl. cross-user) test matrix and its passing result, secrets
handling, and anything flagged for security review. Keep `progress.md` current.
