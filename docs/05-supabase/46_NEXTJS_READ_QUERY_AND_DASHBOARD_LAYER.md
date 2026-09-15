# Career OS — Read / Query Services and Dashboard Data Layer

**Document ID:** COS-APP-QUERY-001
**Version:** 1.0.0
**Status:** Approved for implementation
**Depends on:** Data Access Batch 1; Application Services Batch 2; Server Actions Batch 3

## Purpose
Provide read-optimized, server-only query services over Career OS intelligence views.

## Boundary
Server Component / Route Handler → Query Service → security-invoker view / table → PostgreSQL RLS.

Complex dashboard pages must not reconstruct analytics from raw domain tables.

## Implemented query services
- Pipeline
- Deadlines
- Opportunity matching
- Relationship intelligence
- Campaign analytics
- Historical analytics
- Dashboard aggregation

## Security
Queries use the authenticated request-scoped Supabase client. RLS and security-invoker views remain authoritative.

## Performance
Independent dashboard queries execute concurrently with `Promise.all`. Pages should use the returned DTO instead of issuing duplicate queries.

## Commit
`feat(queries): add Career OS dashboard read layer`
