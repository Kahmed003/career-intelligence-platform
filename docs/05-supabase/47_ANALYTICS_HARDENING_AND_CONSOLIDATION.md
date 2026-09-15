# Career OS — Analytics Hardening and Consolidation

**Status:** Forward-migration hardening
**Scope:** campaign analytics + snapshot execution semantics

## Problems addressed

1. Dashboard code must not silently treat known-imperfect campaign metrics as authoritative.
2. Snapshot runs need durable failure reporting. A function that updates a run to `failed` and then
   re-raises in the same PostgreSQL transaction loses that update when the transaction rolls back.
3. Historical analytics need explicit source-version metadata so future metric-definition changes
   can be distinguished from old snapshots.

## Strategy

This batch does not rewrite applied migrations. It adds:
- an analytics metric-definition registry;
- a snapshot execution-attempt ledger whose rows are independently useful for diagnostics;
- a compatibility view identifying the current metric contract;
- regression assertions for the hardening objects.

The existing campaign metric calculation itself should only be replaced after the exact production
view definition is available in the deployment repository. Do not invent a replacement calculation
from the TypeScript dashboard layer.

## Required follow-up before authoritative campaign reporting

Create a forward migration replacing `campaign_performance_summary` after validating its exact
current SQL against:
- soft-deleted interview/assessment exclusion;
- soft-deleted offer exclusion;
- deadline counts from actual deadline rows rather than distinct source-object collapse.

Then increment the campaign metric definition version in `analytics_metric_definitions`.

## Commit

`chore(analytics): harden metric contracts and snapshot diagnostics`
