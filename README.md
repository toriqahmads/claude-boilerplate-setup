# claude-boilerplate

A Claude Code **plugin** that turns a fresh checkout of Claude Code into a disciplined,
end-to-end engineering workflow. It ships setup skills, a phase-based planning pipeline
(brainstorm → breakdown → plan → execute → review), a squad of specialist subagents,
debugging and security on-ramps, deterministic hooks, and MCP server wiring — all
installable in one step and enable-able at the scope you choose.

Install it once and Claude Code gains the skills and agents automatically; they are
invoked by task context, or on demand via the namespaced slash commands
(`/claude-boilerplate:…`).

---

## What you get

- **27 skills** — setup, planning-workflow, design rubrics, implementation craft, testing.
- **18 subagents** — research, exploration, debugging, a phase-1 design squad, phase-4
  executors, and a phase-5 review gate.
- **3 hooks** — session-context load, edited-file formatting, and a doc-sync reminder.
- **MCP servers** — the keyless `context7`, `playwright`, and `shadcn` ship in `.mcp.json`
  and load automatically with the plugin; the auth-gated `figma` / `sentry` / `github` are
  opt-in (the installer asks, or add them manually).
- **Optional companions** — a helper script to add the `superpowers` + `ponytail` plugins
  and the `rtk` token-optimizer CLI.

### Capability map

| Area | What it does |
|------|--------------|
| **Setup** | `setting-up-claude-in-a-project` (router) → `onboarding-existing-project` / `bootstrapping-new-project`. Gets `CLAUDE.md` / `AGENTS.md` and docs accurate and in sync. **Never overwrites an existing `CLAUDE.md`.** |
| **Planning workflow** | `planning-work-in-phases` (router) drives `brainstorming-a-goal` → `breaking-down-into-phases` → `planning-each-phase` → `executing-phase-plans` → `reviewing-phase-implementation`, with an approval gate between. |
| **On-ramps** | `debugging-an-issue` (bug → root-cause diagnosis doc) and `finding-security-vulnerabilities` (audit → assessment doc) both feed the planning workflow. |
| **Design squad** | `architecture-agent`, `database-designer-agent`, `api-designer-agent`, `frontend-designer-agent` advise the spec; `spec-author-agent` + `plan-writer-agent` write the artifacts; `design-reviewer-agent` gates them. |
| **Executors** | `backend-executor`, `frontend-executor`, `database-executor`, `devops-executor` build plan steps test-first. |
| **Review gate** | `code-reviewer-agent`, `security-reviewer-agent`, and `qa-tester` run in parallel against the spec + plan. |
| **Hooks** | `SessionStart` context load, `PostToolUse` format-on-edit, `Stop` doc-sync reminder. |

---

## Requirements

- **Claude Code** with the plugin system (`/plugin`, `claude plugin …`). Update with
  `npm install -g @anthropic-ai/claude-code@latest` if `/plugin` is unknown.
- **git** — plugins are installed from git sources.
- **jq** — used by the format hook and the optional `rtk` tool (they no-op without it).
- **npx** (optional) — the default MCP servers launch via `npx`; only needed if you use them.

---

## Install — step by step

### Option A — one command from a clone (recommended)

```bash
git clone https://github.com/toriqahmads/claude-boilerplate-setup.git
cd claude-boilerplate-setup
bash install.sh
```

`install.sh` registers the bundled marketplace and asks which **scope** to install at:

```
Choose install scope:
  1) user     — global, all your projects (~/.claude/settings.json)
  2) project  — just this project
       a) local-only — .claude/settings.local.json (gitignored, NOT committed)
       b) shared     — .claude/settings.json (committed; teammates get it on clone + trust)
```

Non-interactive equivalents:

```bash
bash install.sh --user                      # global
bash install.sh --local                     # this project only, kept out of git
bash install.sh --shared                    # this project, committed/shared (prompts for owner/repo)
bash install.sh --shared --repo owner/repo  # shared, marketplace source given up front
```

The keyless core MCP servers load automatically with the plugin. After the scope choice, the
installer also asks **whether to add the optional auth MCP servers** (off unless you say yes —
pass `--mcp` / `--no-mcp` to skip the prompt). See [MCP servers](#mcp-servers) below.

Restart Claude Code afterwards so the plugin loads.

### Option B — manual CLI

```bash
# Global (user) or project-local — the local clone path is fine as the marketplace source:
claude plugin marketplace add ./claude-boilerplate-setup
claude plugin install claude-boilerplate@claude-boilerplate-market --scope user    # global
claude plugin install claude-boilerplate@claude-boilerplate-market --scope local   # project, gitignored

# Shared (committed) — the source must be a PUBLISHED repo so teammates can resolve it:
claude plugin marketplace add owner/claude-boilerplate-setup
claude plugin install claude-boilerplate@claude-boilerplate-market --scope project
git add .claude/settings.json && git commit -m "Enable claude-boilerplate plugin"
```

### Scopes explained

| Choice | Enable-reference written to | Committed? | Who gets it | Marketplace source |
|--------|------------------------------|------------|-------------|--------------------|
| **user** | `~/.claude/settings.json` | No (your machine) | You, in every project | local path OK |
| **project · local-only** | `<project>/.claude/settings.local.json` | **No — gitignored** | You, in that project | local path OK |
| **project · shared** | `<project>/.claude/settings.json` | **Yes — commit to share** | Your team, on clone + trust | **published GitHub repo** |

A **shared** install commits the marketplace source along with the enable-reference, so that
source must be a repo teammates can resolve — a GitHub `owner/repo`, not a local path. The
installer reads it from your `git remote` if present, otherwise it asks (or takes `--repo`).
It only *instructs* you to commit `.claude/settings.json`; it never runs git for you.

**The plugin's files are never copied into your repository** — any scope. Claude Code caches
them in `~/.claude/plugins/cache/`. A **local** install adds one line to the gitignored
`settings.local.json` (and `install.sh` makes sure that path is in your `.gitignore`); a
**shared** install commits only the enable-reference + marketplace entry in
`.claude/settings.json`. Your repo never gains the plugin's skills, agents, or hooks as
committed files.

---

## Set up a project — step by step

After installing, scaffold docs for the project you're working in:

```
/claude-boilerplate:setup
```

(or simply ask Claude Code: *"set up Claude in this project"*.)

This runs the `setting-up-claude-in-a-project` router, which:

1. Detects **new** (only a spec/PRD/plan, no source yet) vs **existing** (has real source).
2. **Existing** → reads your docs + code, compares, and **proposes** fixes (to
   `.claude/setup-analysis.md`) or creates docs only if none exist.
3. **New** → authors an initial `CLAUDE.md` from the intent artifacts.
4. Offers to enable the hooks, confirm MCP servers, and install the optional companions.

> **Guarantee:** setup **never overwrites an existing `CLAUDE.md`**. If one exists, it
> creates nothing on top of it — it proposes changes to `.claude/setup-analysis.md` or a
> git-ignored `CLAUDE.local.md` for you to review.

---

## How to use it

Once installed, the skills and agents are **invoked automatically** by task context — you
don't have to name them. Some common entry points:

- **Build a feature** — start with *"let's build X"*; the planning router runs brainstorm →
  breakdown → plan → execute → review, pausing for your approval at each gate. Artifacts land
  under `docs/plan/` (`specs/`, `breakdown/`, `phases/<N-slug>/plan.md`, a committed
  `progress.md`).
- **Fix a bug with an unknown cause** — *"debug this / find the root cause"* runs
  `debugging-an-issue`: it investigates logs/traces/metrics/code, confirms a reproduction,
  and writes a committed diagnosis doc that feeds the planning workflow. No fix is proposed
  before the root cause is established.
- **Security audit** — *"audit this for vulnerabilities"* runs
  `finding-security-vulnerabilities` and writes an assessment doc.
- **Slash commands** — every skill is namespaced: `/claude-boilerplate:<skill-name>`.

Subagents (dispatched with the Agent tool) do the heavy, parallelizable work: read-only
`explorer-agent` and `research-agent`, the design specialists, the write-capable executors,
and the review gate.

---

## MCP servers

**Core (keyless) — automatic.** `context7`, `playwright`, and `shadcn` ship in the plugin's
`.mcp.json` and load whenever the plugin is enabled, at whatever scope you installed it. No
setup, no auth. (context7 = live library/API docs; playwright = browser E2E for `qa-tester`;
shadcn = shadcn/ui component registry.)

**Optional (auth) — opt-in.** These need OAuth or a token, so they're off by default. The
installer asks whether to add them; you can also add them yourself at the scope that matches
your install (`-s user` / `-s local` / `-s project`):

```bash
# Figma design context (needs a Figma Dev seat; OAuth on first use):
claude mcp add -s user -t http figma https://mcp.figma.com/mcp
# Sentry errors/traces for debugging (OAuth on first use):
claude mcp add -s user -t http sentry https://mcp.sentry.dev/mcp
# GitHub PRs/issues/CI (needs a PAT — never commit the token):
claude mcp add -s user -t http github https://api.githubcopilot.com/mcp/ \
  --header "Authorization: Bearer $GITHUB_MCP_TOKEN"
```

Agents reference these as `mcp__<server>__<tool>` in their tool lists; without a server
enabled, an agent simply degrades (e.g. skips a context7 lookup) rather than failing.

---

## Optional companions

The workflow is designed to lean on three external tools when present, and to work fine
without them. Install them any time:

```bash
bash scripts/install-plugins.sh
```

- **superpowers** (`obra/superpowers-marketplace`) — the TDD / brainstorming / planning
  methodology the planning skills delegate to when it's installed.
- **ponytail** (`DietrichGebert/ponytail`) — a "laziness ladder" YAGNI ruleset + review
  commands.
- **rtk** (`rtk-ai/rtk`, "Rust Token Killer") — a CLI that compresses command output before
  it hits the context window, wired as a `PreToolUse` Bash-rewrite hook (needs `jq`).

The boilerplate's own skills fall back to inline behavior when these aren't installed.

---

## Update / uninstall / disable

```bash
claude plugin update claude-boilerplate
claude plugin disable claude-boilerplate            # keep installed, turn off
claude plugin uninstall claude-boilerplate          # remove (add --scope user|local)
```

---

## Function reference

### Skills (28)

| Skill | Purpose |
|-------|---------|
| `setting-up-claude-in-a-project` | Router: new vs existing → the right setup workflow. |
| `onboarding-existing-project` | Sync `CLAUDE.md`/docs with real code; propose, don't overwrite. |
| `bootstrapping-new-project` | Author initial docs from a spec/PRD/plan (greenfield). |
| `planning-work-in-phases` | Router for brainstorm → breakdown → plan → execute → review. |
| `brainstorming-a-goal` | Phase 1: goal → approved design doc (spec). |
| `breaking-down-into-phases` | Phase 2: design → N contextful phases. |
| `planning-each-phase` | Phase 3: one implementation plan per phase (TDD, bite-sized). |
| `executing-phase-plans` | Phase 4: execute plans in dependency order; committed `progress.md`. |
| `reviewing-phase-implementation` | Phase 5: code review + security + QA against spec + plan. |
| `debugging-an-issue` | On-ramp: bug → root-cause diagnosis doc → planning. |
| `finding-security-vulnerabilities` | On-ramp: audit → security assessment doc → planning. |
| `researching-sources` | Web/docs research protocol + source-safety guardrails. |
| `reviewing-specs-and-plans` | Phase-1 gate: adversarial spec/plan review rubric. |
| `designing-architecture` | Design rubric: system structure, boundaries, tech choices. |
| `designing-a-database` | Design rubric: data model, schema, keys/indexes, migration. |
| `designing-an-api` | Design rubric: API contract, errors, auth, versioning. |
| `designing-a-frontend` | Design rubric: component tree, state, async states, a11y. |
| `implementing-backend` | Exec craft: server-side code. |
| `implementing-frontend` | Exec craft: UI code + async states + a11y. |
| `implementing-database-changes` | Exec craft: migration safety, zero-downtime. |
| `implementing-devops` | Exec craft: infra/CI/CD safety, validate-first. |
| `implementing-i18n` | Cross-cutting: internationalization. |
| `implementing-auth-and-authorization` | Cross-cutting: authn + RBAC/authz + secure coding. |
| `implementing-observability` | Cross-cutting: logging, tracing, metrics, alerting. |
| `implementing-documentation` | Cross-cutting: API docs (OpenAPI) + README/CHANGELOG/ADR. |
| `coordinating-api-contract` | Cross-cutting: frozen API-contract spine → parallel backend (provider) + frontend (consumer/mock), change protocol, conformance gates; resumes across sessions via a committed status ledger + the session-start hook. |
| `testing-apis` | QA craft: black-box API/contract testing. |
| `testing-ui-and-e2e` | QA craft: browser UI + E2E via Playwright. |

### Agents (18)

| Agent | Role |
|-------|------|
| `research-agent` | Web/docs research; cited answers (read-only). |
| `explorer-agent` | Read-only codebase explorer; `file:line` answers. |
| `debugger-agent` | Root-cause investigator → diagnosis doc (writes doc + repro test only). |
| `brainstorm-agent` | Phase-1 divergent: options + recommended direction. |
| `spec-author-agent` | Phase-1 convergent: direction → design doc. |
| `plan-writer-agent` | Spec + breakdown → implementation plan. |
| `design-reviewer-agent` | Phase-1 gate: adversarial spec/plan review (read-only). |
| `architecture-agent` | Design specialist: system structure. |
| `database-designer-agent` | Design specialist: data model. |
| `api-designer-agent` | Design specialist: API contract. |
| `frontend-designer-agent` | Design specialist: component tree, state, a11y. |
| `backend-executor` | Phase-4: server code (write-capable, TDD). |
| `frontend-executor` | Phase-4: UI code (write-capable, TDD). |
| `database-executor` | Phase-4: migrations/schema (write-capable, safe). |
| `devops-executor` | Phase-4: infra/CI/CD (write-capable, validate-first). |
| `qa-tester` | Phase-5: black-box test the built app (test files only). |
| `code-reviewer-agent` | Phase-5: review built code vs design + plan (read-only). |
| `security-reviewer-agent` | Phase-5: security/pentest review (read-only). |

### Hooks (3)

| Hook | Event | What it does |
|------|-------|--------------|
| `session-start-context.sh` | `SessionStart` | Prints branch, uncommitted count, in-progress phase plans, and API-contract state (version, `⚠ NEEDS-RESYNC`, worktrees) for parallel tracks. |
| `post-tooluse-format.sh` | `PostToolUse` (`Write\|Edit\|MultiEdit`) | Formats just the edited file with the project's own formatter. |
| `stop-doc-sync.sh` | `Stop` | Reminds you to sync `CLAUDE.md` if structure changed but the doc didn't. |

Every hook is read-only (except formatting the edited file), needs no runtime deps, and
always exits 0 — it can never break a session and silently no-ops when a project has no
formatter.

---

## Changelog

Release history in [CHANGELOG.md](CHANGELOG.md) — [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format, [SemVer](https://semver.org/).

---

## License

MIT — see [LICENSE](LICENSE).
