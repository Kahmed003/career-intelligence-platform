# Career OS — Analytics Snapshots and Historical Trends

**Document ID:** COS-SUP-ANL-001
**Version:** 1.0.0
**Status:** Approved for implementation
**Canonical path:** `docs/05-supabase/42_ANALYTICS_SNAPSHOTS_AND_HISTORICAL_TRENDS.md`

## Purpose

The current intelligence layer describes present state. This milestone adds append-only historical observations so Career OS can measure campaign, recruiting-pipeline, and relationship-health trends over time.

## Design

- Current domain tables remain authoritative.
- Snapshot rows are immutable historical observations.
- Capture is explicit; scheduling stays in the application/worker layer.
- Important metrics use typed columns.
- The complete source-view row is retained as JSONB for reproducibility.
- RLS is owner-scoped.
- Authenticated clients receive read-only access to snapshot tables.

## Migration Order

1. `20260721014700_create_analytics_snapshot_runs.sql`
2. `20260721014800_create_campaign_performance_snapshots.sql`
3. `20260721014900_create_relationship_health_snapshots.sql`
4. `20260721015000_create_pipeline_health_snapshots.sql`
5. `20260721015100_create_snapshot_capture_functions.sql`
6. `supabase/tests/database/006_analytics_snapshots.sql`

## Snapshot Runs

`analytics_snapshot_runs` is the provenance anchor for a capture operation. It records owner, logical snapshot date, kind, execution status, timestamps, row counts, errors, and metadata.

## Campaign Snapshots

One row per Campaign per run, preserving funnel counts, target progress, conversions, deadline pressure, campaign health, and the full source payload.

## Relationship Snapshots

One row per Person per run, preserving interaction counts, response rate, follow-up pressure, relationship score/health, flags, and full source payload.

## Pipeline Snapshots

One aggregate row per owner per run, preserving application volume, submitted applications, interview/offer penetration, upcoming events/deadlines, average fit score, and status distribution.

## Capture

The application or trusted scheduled worker calls:

`private.capture_daily_analytics_snapshot(snapshot_date)`

Recommended cadence: once daily after the user's logical day closes.

## Idempotency

Only one running/completed daily snapshot of a given kind is allowed per owner and date. A failed run can be retried.

## Next Milestone

**TypeScript Data Access Layer — repositories for Object Registry, Projects, Tasks, Opportunities, and Applications.**

## Commit

`feat(analytics): add historical snapshots and trend capture`
