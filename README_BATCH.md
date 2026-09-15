# Career OS — Dashboard Data Batch 4

Place these files on top of Batches 1–3.

No new browser database access is introduced. Use `loadCareerDashboard()` from Server Components.

Before typechecking, regenerate the Supabase types against the fully migrated database:

```bash
npm run db:types
npm run typecheck
```

## Important production note

`campaign_performance_summary` still has known historical soft-delete/deadline-count limitations identified during database hardening. This batch preserves the current database contract rather than inventing a replacement in TypeScript. Correct that view with a forward SQL migration before treating campaign analytics as authoritative historical reporting.

The next application milestone should either:
1. perform that analytics consolidation migration first; then
2. build the actual Next.js dashboard/page shell and domain UI.
