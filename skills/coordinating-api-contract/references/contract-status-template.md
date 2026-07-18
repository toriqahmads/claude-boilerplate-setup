# Contract Status Ledger Template

Copy into `docs/plan/contracts/<feature>.status.md` — the **committed, at-a-glance cross-track
ledger** for a backend/frontend seam built in parallel. It is the durable record that lets **any
later session** resume both tracks: which contract version each track built against, where each
worktree is, conformance status, and whether a track has gone **stale** after a contract bump.

Write it **continuously** (like `progress.md`): when the contract is frozen, when either track
syncs/builds, when a gate runs, and — critically — when the **contract-change protocol** bumps the
version (mark every not-yet-resynced track `⚠ NEEDS-RESYNC`). Clear the marker when that track
re-syncs. Get timestamps from `date -u +%Y-%m-%dT%H:%M:%SZ` — never fabricate.

The `⚠ NEEDS-RESYNC` lines are what `session-start-context.sh` greps and surfaces at session start,
so keep them exactly on their own line when a track is behind.

```markdown
# Contract Status — <feature>

**Artifact:** docs/plan/contracts/<feature>.<openapi.yaml|graphql|proto>
**Current version:** <vN>          **Frozen:** yes | no (<date -u> at freeze)
**Updated:** <date -u>

## Changelog
- vN — <what changed> (<date -u>) — breaking | additive
- v1 — initial frozen contract (<date -u>)

## Tracks

### backend — provider
- **Plan / progress:** docs/plan/phases/<N-slug>/plan.md · progress.md
- **Worktree:** <path, e.g. .worktrees/<feature>-backend>   **Branch:** <branch>
- **Synced-version:** <vN>          (the contract version this track last built against)
- **Conformance:** provider <PASS | FAIL | PENDING>   drift <PASS | FAIL | PENDING>
- **State:** in-progress | done
<!-- when Synced-version < Current version, add on its own line: -->
- ⚠ NEEDS-RESYNC: synced <vN-1> < current <vN> — re-sync before continuing

### frontend — consumer
- **Plan / progress:** docs/plan/phases/<M-slug>/plan.md · progress.md
- **Worktree:** <path, e.g. .worktrees/<feature>-frontend>   **Branch:** <branch>
- **Synced-version:** <vN>
- **Mock:** <how the contract-derived mock is stood up — Prism / MSW / generated client>
- **Conformance:** consumer-parity <PASS | FAIL | PENDING>   drift <PASS | FAIL | PENDING>
- **State:** in-progress | done
<!-- ⚠ NEEDS-RESYNC line here too when behind -->

## Integration
- **Gate:** provider-conformance <…> · consumer-parity <…> · drift <…> — all PASS required
- **Integrated:** <date -u | not yet> (mock swapped for real provider)
```

## Resume note

On a fresh session, `coordinating-api-contract`'s **Across sessions / resume** section reads this
ledger + the artifact's current version, discovers the worktrees (`git worktree list`), and
**re-syncs any track whose Synced-version is behind Current version** before continuing. If a
worktree was pruned, recreate it from the track's **Branch** (the commits are durable in git even
when the worktree dir is gone). A `⚠ NEEDS-RESYNC` line here means: do not continue that track
until it is re-synced to the current contract version.
