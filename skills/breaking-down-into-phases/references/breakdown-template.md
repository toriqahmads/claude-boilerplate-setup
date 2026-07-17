# Breakdown Template

Copy into `docs/plan/breakdown/YYYY-MM-DD-<topic>-breakdown.md`. Each phase must be independently
buildable/testable, sized to hold in context, with clear interfaces. A small goal may be a single
phase — don't invent phases.

```markdown
# <Topic> — Phase Breakdown

**Design:** <link to docs/plan/specs/YYYY-MM-DD-<topic>-design.md>

## Goal recap
<One paragraph.>

## Phases

### Phase 1: <name>  (slug: `1-<slug>`)
- **Purpose:** <one clear responsibility>
- **Scope — in:** <what this phase delivers>
- **Scope — out:** <explicitly deferred to another phase>
- **Interfaces produced:** <names/types later phases rely on>
- **Interfaces consumed:** <from earlier phases — none if first>
- **Dependencies:** <phases that must land first>
- **Done-criteria:** <what "this phase is complete" means, incl. tests>

### Phase 2: <name>  (slug: `2-<slug>`)
- ... same fields ...

## Sequencing
<Build order + dependency graph in prose. No cycles; nothing consumed before it's produced.>

## Coverage check
<One line confirming the union of phases covers the whole design — no gaps, no overlaps.>
```
