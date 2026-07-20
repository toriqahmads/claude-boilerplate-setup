---
name: designing-a-database
description: >
  Use when designing the data layer for a spec — the entities and relationships, the
  schema, normalization vs deliberate denormalization, keys and indexes, constraints
  and integrity, access/query patterns, migration and versioning, and the storage
  engine choice (relational / document / KV / other). Produces a data-model
  recommendation that feeds the design doc, grounded against the real repo's existing
  schema and access patterns. Followed by the database-designer-agent subagent.
  Triggers on "design the schema", "data model", "what tables", "SQL vs NoSQL",
  "how should we index this", "design the migration", "entity relationship design",
  "database schema design", "normalize this table", "sharding or partitioning
  strategy", "primary vs foreign keys", "which database should we use".
---

# Designing a database

Rubric for the data layer during spec design. Followed by `database-designer-agent`;
usable inline. Output is a data-model recommendation feeding the design doc — not
migration code.

## Goal

Recommend a **data model that serves the actual access patterns with integrity and
room to grow** — entities, relationships, schema, keys, indexes, constraints — fit to
how the data is written and read, not an abstract ideal. Model to the queries, not
just the nouns.

## When to use

During spec authoring, once architecture names the components that own data. Before
API contracts finalize (shape depends on what's queryable).

## Inputs

The spec draft + architecture recommendation, and the **access patterns** (what's
read/written, how often, by what key, at what latency). The real repo — existing
schema, ORM/models, migrations — so the design extends it consistently.

## Design dimensions

1. **Entities & relationships** — nouns, cardinality (1:1 / 1:N / M:N), ownership,
   lifecycle. An ER sketch.
2. **Storage engine fit** — relational vs document vs KV vs graph vs time-series,
   driven by access patterns and consistency needs. Default to the repo's; justify a
   new store.
3. **Schema & types** — tables/collections, columns/fields, types, nullability,
   defaults. Precise types (money isn't a float; time is tz-aware).
4. **Keys & identity** — primary keys (natural vs surrogate), foreign keys, unique
   constraints. UUID vs sequential trade-off where relevant.
5. **Normalization vs denormalization** — normalize for integrity by default;
   denormalize only for a proven read pattern, stating the cost (write amplification,
   consistency).
6. **Indexes** — index real query/filter/sort/join columns; composite/partial where
   it pays. Note write cost. No indexes for queries that don't exist.
7. **Integrity & constraints** — FKs, checks, uniqueness, enums; DB-enforced vs
   app-enforced. Prefer the DB for invariants.
8. **Access patterns & hot paths** — top reads/writes and how schema+indexes serve
   them; N+1 and full-scan risks.
9. **Migration & evolution** — how it's created/changed safely (expand/contract,
   backfill, zero-downtime), and rollback.
10. **Scale & retention** — expected volume, growth, partitioning/sharding if
    required, archival/retention.

## Method

1. List access patterns first — reads/writes, keys, frequency. The model serves these.
2. Read existing schema/models/migrations for consistency.
3. Model entities → relationships → schema → keys → indexes, checking each against
   the access patterns.
4. Choose the storage engine deliberately (or confirm the existing one fits).
5. Sanity-check integrity, hot paths, and a safe migration path.

## Guardrails

- **Model to the queries.** A schema that can't serve the read patterns efficiently
  is wrong however clean it looks.
- **Integrity first.** Normalize by default; every denormalization states its cost.
- **Index the real queries only.** No speculative indexes; note write cost.
- **Fit the repo's store & conventions.** Justify any new engine or naming departure.
- **Safe evolution.** Any change to existing data has a migration + rollback story;
  flag destructive steps explicitly.
- **Recommendation, not migration code.** Stop at the model + rationale.
- **Ground claims** against the repo's actual schema (`file:line`).

## When to stop / complete

Stop when the model serves the access patterns with integrity, keys/indexes are
justified, and a safe migration path exists — or when an access pattern or volume
figure only the user has blocks the choice (present it). Don't write migration code
or design the API surface; hand those on.

## Output

- **Recommendation** — engine + model shape, 1–3 sentences, up front.
- **Entities & relationships** — ER sketch with cardinality and ownership.
- **Schema** — tables/collections with columns/fields, types, nullability, keys.
- **Indexes** — each with the query it serves and its write cost.
- **Integrity** — constraints enforced by the DB vs app.
- **Access patterns** — top reads/writes mapped to schema + indexes; hot-path notes.
- **Migration & scale** — how to create/evolve safely + rollback; volume/partitioning.
- **Trade-offs & open questions** — denormalizations and their cost; what the user must confirm.
- **Sources** — repo `file:line` and external references used.
