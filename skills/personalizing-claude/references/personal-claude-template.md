# Personal CLAUDE.md — Template

Fill this from the interview answers (`interview-questions.md`) and write it to
`~/.claude/CLAUDE.md`. `<angle-bracket>` = replace with the user's answer; `A | B | C` = pick the
option(s) they chose. **Drop any section the user had no preference on** — keep the guide tight
and scannable, not exhaustive. Never overwrite an existing personal file without confirming (see
`SKILL.md` step 4).

```markdown
# Personal CLAUDE.md — <Name>

Global guide for how I want Claude Code to work with me, across all my projects.
Project-level CLAUDE.md and explicit instructions override anything here.

## Who I am

- **Name:** <Name> — address me as <preferred name>.
- **Role:** <role + specialization; domain focus, e.g. backend / web3>. Assume <expert |
  advanced | intermediate | learning> depth in <domain> — <skip basics | explain advanced |
  teach as we go>.
- **Primary stacks:** <languages / frameworks>.
- **Timezone:** <TZ (region, UTC±N)>. Resolve relative dates against this.
- **Git identity:** <Name> <<email>>.

## Communication

- **Verbosity:** <terse, just do it | balanced — reason then act | explain thoroughly>.
- **Language:** <language(s); when to switch>.
- **Reports:** <e.g. comprehensive but minimal, easy to understand, no walls of text>.
- **Never guess or assume.** If anything is unclear/missing/ambiguous — **ask me**.

## Autonomy & safety

- **Big changes** (architecture / multi-file / destructive): <plan first and wait | high autonomy>.
- **Small, safe changes:** <go ahead and report | check first>.
- **Never take destructive actions** without explicit go-ahead: <the user's hard nos — e.g. DB
  migrations/drops, `git reset --hard`, force-push, direct push to main, deleting files not asked
  for>. Irreversible step → confirm first.
- <optional: **Sandbox-first** — replicate & validate a destructive/irreversible action in a
  local/sandbox environment before touching anything real, then get per-instance go-ahead>.

## Coding conventions

- **Principles:** <SOLID / DRY / KISS / YAGNI, in priority order>.
- **Types:** <strict, no `any` | loose>.
- **Comments:** <minimal / self-documenting> + <doc-comments (JSDoc/TSDoc, docstrings, GoDoc,
  rustdoc) on public APIs so the LSP surfaces them>. Inline comments only for the non-obvious *why*.
- **Magic numbers/strings:** <name as constants/enums | allowed>.
- **API field casing:** <snake_case | camelCase>; follow the project's established style if present.
- **Conventions:** follow language/framework best practice; <mirror repo conventions | improve where
  possible>.
- **Refactors:** <no unrequested refactors / no scope creep | free to refactor>.

## Testing

- **Discipline:** <TDD | tests alongside | tests after on request | flexible per project>.
- **Coverage:** <e.g. enforce ≥95% on touched files | none>.
- **Test layout:** <e.g. mirror the source tree — `src/foo/bar.ts` → `test/foo/bar.test.ts`;
  one test module per source module | co-located | flat `tests/` | follow project convention>.

## Observability
<!-- Drop this whole section if the user doesn't care about observability. -->

- **Logging:** comprehensive **structured** logging with deliberate levels (verbose in dev, `info`+
  JSON in prod, level via config). Tools: <pino | winston | structlog | slog | zerolog | tracing>.
  Never log secrets/PII — redact in logger config.
- **Tracing:** distributed, standards-based via <OpenTelemetry | Jaeger | Tempo | Sentry>; propagate
  context across service/async boundaries; span meaningful units of work.
- **Monitoring:** error tracking + metrics + alerting via <Sentry | Prometheus | OpenTelemetry> —
  RED/USE signals, health/readiness checks, SLO-based alerts. Tooling pluggable, three pillars
  (logs + traces + monitoring) non-negotiable; verify tool setup via context7.

## Git & commits

- **Commits:** <Conventional Commits | plain>; <small, scoped>.
- **Policy:** <commit/push only when asked; never push to main; branch for feature work>.
- **Git habits:** <e.g. `git cherry-pick` for specific commits — confirm hash, flag conflicts>.

## Security

- **Posture:** <paranoid/audit-minded | high-pragmatic | standard | speed-first>.
- **Domain checks:** <e.g. web3: reentrancy, overflow, access control, oracle manipulation>.
- **Secrets:** no secrets in code; use env; never commit `.env`.
- <optional: **`.env` reads** — never read real `.env` files; only `.env.example` allowed; ask if a
  real value / live `.env` is genuinely needed>.
- **Don't guess** library/API behavior — verify via context7 or official docs.

## Workflow for non-trivial features

<e.g. brainstorm + explore → breakdown + plan → build → review>.

## Definition of Done

A task is **not** done until: <criteria — e.g. goal + success criteria met; tests + coverage;
types/lint/build pass; security reviewed; observability in place; verified end-to-end; docs synced;
no scope creep; honest report>.

## Guardrails (non-negotiable)

- <the consolidated hard rules — e.g. ask don't assume; no destructive actions without go-ahead
  (sandbox-first when needed); no secrets in code; never read real `.env` (only `.env.example`);
  no guessing APIs; no unrequested refactors; no false completion claims>.

## Docs & knowledge

- <keep CLAUDE.md synced | OpenAPI/API docs in sync | CHANGELOG | ADRs for decisions>.
```
