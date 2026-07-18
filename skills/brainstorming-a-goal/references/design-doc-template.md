# Design Doc Template

Copy this into `docs/plan/specs/YYYY-MM-DD-<topic>-design.md`. It is a **spec, not an
implementation plan** — behavior and contract level only, no file paths / framework names /
codebase assumptions (those are phase 3). Three layers: what it does → how it's built → how we
prove it. Scale each section to its complexity; delete what a truly simple goal doesn't need, but
keep all three layers.

```markdown
# <Topic> — Design

**Status:** Draft
**Source of truth:** <link to PRD / Jira / Linear / diagnosis / assessment doc, if any>

## Summary
<One paragraph: what we're building and why.>

---

## 1. Functional Specification  — *what should the system do, and for whom?*

### User stories
- As a <role>, I want <capability> so that <outcome>.

### Functional requirements
- FR1: <requirement>
- FR2: <requirement>

### Acceptance criteria (GIVEN / WHEN / THEN)
- GIVEN <state> WHEN <action> THEN <observable result>.

### Out of scope
- <explicitly not doing>

---

## 2. Technical Design  — *what is the system's external contract?*

### Endpoints / interfaces
- `<METHOD> /path` — purpose; request contract; response contract; status/error codes.

### Data model changes
- <entities/fields added or changed, at the contract level — not migrations>

### Flow
- <sequence / flow diagram or prose: how a request moves through the components>

### Error handling
- <failure modes and the contract's response to each>

---

## 3. Testing Strategy  — *what proves the spec is satisfied?*

- **Unit** — <behaviors covered>
- **Integration** — <boundaries covered>
- **E2E** — <user-visible flows proving the acceptance criteria>
- **Coverage bar** — unit + integration coverage **≥95%** (statements/branches/functions/lines),
  **per-file hard** for changed files and **global ratcheted** upward, never regressing; a success
  criterion, not a nicety. E2E is a separate functional gate, not counted toward the %.

---

## Open questions
- <anything unresolved — mark assumptions as assumptions>
```
