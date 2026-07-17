---
description: Set up Claude Code in this project (docs + hooks + MCP + plugins). Never overwrites an existing CLAUDE.md.
---

Set up Claude Code for the current project.

**Invoke the `setting-up-claude-in-a-project` skill** and follow it exactly. It detects
whether this is a **new** (greenfield, no source yet) or **existing** (has real source
code) project and routes to the matching workflow:

- **Existing** → `onboarding-existing-project`: read the docs + code, compare, and propose
  fixes (or create docs if none exist).
- **New** → `bootstrapping-new-project`: author the initial docs from the spec/PRD/plan.

Both paths also offer to enable the plugin's hooks, confirm MCP servers, and install the
optional companion plugins.

**Hard invariant — never overwrite an existing `CLAUDE.md`.** If `CLAUDE.md` already
exists, do **not** rewrite it: create only when absent, otherwise propose the changes to
`.claude/setup-analysis.md` or a git-ignored `CLAUDE.local.md` for the user to review.

$ARGUMENTS
