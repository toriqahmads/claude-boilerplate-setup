---
name: implementing-database-changes
description: >
  Use when implementing database changes from a plan — migrations, schema/DDL, ORM
  models, indexes, and data backfills — in whatever database and migration tool the
  plan specifies. Encodes migration-safety craft: expand/contract for zero-downtime,
  backward compatibility, safe backfills, non-blocking index creation, guaranteed
  rollback, and no data loss. Followed by the database-executor subagent. Triggers on
  "write the migration", "change the schema", "add the index", "backfill the data",
  "update the model".
---

# Implementing database changes

Execution-time craft for the data layer. Followed by the `database-executor`
subagent. Runs ON TOP of the execution method — **follow `executing-phase-plans` and
`superpowers:test-driven-development`**. This skill is the migration-safety bar
layered over it, because DB changes are the least reversible thing you ship.

## Goal

Apply the plan's data-layer changes **without downtime and without data loss**, with a
proven rollback at every step. A schema change that can't be safely rolled back or
that breaks live readers/writers is a defect, however correct the end state.

## Stack

The plan dictates the database and migration tool (Rails/Prisma/Alembic/Flyway/raw
SQL, etc). Match the repo's existing migrations and model conventions; use context7
for the tool's exact API. Never edit an already-applied migration — add a new one.

## Craft checklist (per migration)

1. **Expand/contract for zero-downtime.** Split risky changes into phases: add new
   (expand) → backfill → switch reads/writes → remove old (contract). Never rename/drop
   in one shot on a live table.
2. **Backward compatibility.** The migration must be safe with the OLD code still
   running (rolling deploys). Additive first; make columns nullable or defaulted before
   the app requires them.
3. **Safe backfills.** Batch large backfills to avoid long locks/replication lag;
   make them resumable and idempotent; keep them out of the schema migration when the
   dataset is big.
4. **Non-blocking DDL.** Create indexes concurrently / add constraints as NOT VALID
   then validate, where the engine supports it, to avoid table locks.
5. **Rollback.** Every migration has a real, tested `down` / reverse path. If a step is
   irreversible (a drop), call it out explicitly and require an approved backup first.
6. **No data loss.** Destructive steps (drop column/table, type narrowing) come only
   after the data is confirmed unused and backed up. Contract phase is last and gated.
7. **Integrity.** Constraints, FKs, uniqueness, checks enforced in the DB; verify they
   hold against existing data before adding (NOT VALID → validate).
8. **Test & verify.** Run the migration up AND down on a realistic copy; assert the
   resulting schema and that existing data survives; test the models against it.
9. **Conventions.** Match the repo's migration naming, structure, and model style.
10. **Observability.** Follow `implementing-observability`: watch migration/backfill
    duration and lock time; ensure slow-query logging and query/connection-pool metrics
    cover the new schema, and that app spans wrap the new queries.

## Guardrails

- **Reversible or gated.** Every step rolls back, or is explicitly flagged as
  irreversible and gated on a confirmed backup.
- **Safe with old code running.** Assume a rolling deploy; no big-bang breaking change.
- **Never mutate applied migrations** — always add a new one.
- **Destructive ops are last, flagged, and backup-gated.** Surface them for human
  confirmation; do not quietly drop data.
- **Plan is the contract;** report blockers, don't improvise schema.
- **Tests/verification green before done;** show the up+down run. Where a step ships model/logic
  code with a coverage harness, the **≥95% coverage gate** applies to it (per changed file + global
  not regressed) on top of the up/down migration verification.

## When to stop / complete

A migration is complete when it applies and reverts cleanly on a realistic copy,
existing data survives, models pass against it, and it's safe under rolling deploy.
Stop and report when verified and `progress.md` updated, OR when a step is irreversible/
risky and needs human sign-off, OR when blocked — report specifics, hand back.

## Output

Per migration: files added, the expand/contract phase this is, up+down verification
result, data-safety notes, any irreversible/destructive step flagged for confirmation,
and rollback instructions. Keep `progress.md` current.
