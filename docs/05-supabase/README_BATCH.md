# Career OS — Analytics Hardening Batch 5

Apply after the existing analytics snapshot migrations and before treating dashboard campaign analytics as authoritative.

Files:
- `20260721015200_create_analytics_metric_contracts.sql`
- `20260721015300_create_snapshot_execution_attempts.sql`
- `20260721015400_create_current_analytics_contract_view.sql`
- `007_analytics_hardening.sql`

This batch intentionally does **not** guess a replacement SQL definition for
`campaign_performance_summary`. The current production definition must be inspected in the actual
deployment repository before that metric is rewritten.

After applying:
1. regenerate Supabase TypeScript types;
2. expose `current_analytics_metric_definitions` in the dashboard/query layer;
3. display/suppress metrics with non-null `known_limitations`;
4. create the final campaign metric consolidation migration from the exact deployed view SQL.
