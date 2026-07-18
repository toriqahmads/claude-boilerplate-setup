# Personal CLAUDE.md — Interview Question Bank

Run these as `AskUserQuestion` rounds, batched by theme (max 4 questions per call). Each round
maps to a section of `personal-claude-template.md`. Offer real options; the user picks one/many or
hits **Other** for free text. Free-text-only items (marked ✎) — ask explicitly in the message,
since options can't enumerate them. **Never invent an answer.** Skip any topic the user says they
don't care about; add topics they raise.

---

## Round 1 — Identity  → template "Who I am"

- ✎ **Name** — how to address them; and git author name + email for commits.
- ✎ **Timezone** — for dates/scheduling (offer common zones as options, Other for the rest).
- **Role / specialization** — what they mainly build (full-stack / backend-infra / frontend-UI /
  lead-architect), plus any domain focus (e.g. blockchain/web3, data, mobile). Free-text welcome.
- **Primary stacks / languages** (multi-select) — the languages and frameworks they work in most.
- **Domain depth** — for a specialization, how much to assume they know so Claude doesn't
  over-explain (expert / advanced / intermediate / learning).

## Round 2 — Communication  → template "Communication"

- **Verbosity** — terse just-do-it / balanced (reason then act) / explain thoroughly / compressed.
- **Language(s)** — what language Claude replies in; when to switch (e.g. English for code,
  another language for discussion).
- **Reporting style** — how they want results reported (e.g. comprehensive-but-minimal vs detailed
  walkthrough).

## Round 3 — Autonomy & safety  → template "Autonomy & safety"

- **Autonomy level** — ask-before-big-changes / high-autonomy / low-autonomy / plan-first-always.
- **Destructive-action policy** — what Claude must never do without explicit go-ahead (DB
  migrations, hard reset, force-push, direct push to main, deletes). Free-text for their hard nos.

## Round 4 — Coding conventions  → template "Coding conventions"

- **Design principles** — SOLID / DRY / KISS / YAGNI and their priority order.
- **Type strictness** — strict types / no `any` / loose.
- **Comment & doc style** — minimal vs doc-comments (JSDoc/TSDoc, docstrings, GoDoc, rustdoc) for
  public APIs so the LSP surfaces them.
- **Magic numbers/strings** — allowed or must be named constants.
- **API field casing** — snake_case / camelCase / follow existing project style.
- **Convention-following** — mirror repo conventions, follow language/framework best practice, or
  improve existing where possible.
- **Refactor policy** — no unrequested refactors / free to refactor.

## Round 5 — Testing  → template "Testing"

- **Discipline** — TDD / tests-alongside / tests-after-on-request / flexible-per-project.
- **Coverage gate** — enforced threshold (e.g. ≥95% on touched files) or none.

## Round 6 — Git & commits  → template "Git & commits"

- **Commit style** — Conventional Commits / plain / other; small-scoped or not.
- **Push/commit policy** — commit only when asked, never push to main, always branch, etc.
- **Cherry-pick / rebase habits** — any specific git workflows they use (e.g. `git cherry-pick`).

## Round 7 — Security  → template "Security"

- **Posture** — paranoid/audit-minded / high-pragmatic / standard / speed-first.
- **Domain specifics** — e.g. web3: reentrancy, overflow, access control, oracle manipulation.
- **Secrets** — no secrets in code, never commit `.env`, etc.

## Round 8 — Workflow  → template "Workflow"

- **Feature workflow** — brainstorm/explore → plan → build → review, or lighter. When to plan vs
  just build.

## Round 9 — Definition of Done  → template "Definition of Done"

- **Completion criteria** — what must hold before a task is "done" (tests + coverage, types/lint/
  build pass, security reviewed, verified end-to-end, docs synced, no scope creep, honest report).

## Round 10 — Guardrails  → template "Guardrails"

- **Non-negotiables** — the consolidated hard rules Claude must never break (ask-don't-assume, no
  destructive actions, no secrets, no API guessing, no unrequested refactors, no false completion).

## Round 11 — Docs & knowledge  → template "Docs & knowledge"

- **Doc habits** (multi-select) — keep CLAUDE.md synced, OpenAPI/API docs in sync, CHANGELOG,
  ADRs for decisions.

---

**After the interview:** fill `personal-claude-template.md`, drop any section the user had no
preference on, and write `~/.claude/CLAUDE.md` (never overwrite an existing one without
confirming — see SKILL.md step 4).
