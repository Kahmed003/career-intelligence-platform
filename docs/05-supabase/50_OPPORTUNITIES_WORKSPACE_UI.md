# Career OS — Opportunities Workspace UI

**Document ID:** COS-UI-OPP-001
**Version:** 1.0.0
**Depends on:** Batches 1–7

## Purpose
Create the opportunity evaluation workspace connecting discovered opportunities, preference matching,
organization context, and the application pipeline.

## Routes
- `/opportunities`
- `/opportunities/[id]`

## Read model
The workspace uses `OpportunityMatchingQueryService` for ranked matches and preference evaluations.
Opportunity domain details are retrieved server-side through the existing repository layer.

## Workflow
Opportunity → evaluate preference fit → inspect organization/context → start application.

## Security
All reads use the authenticated request-scoped Supabase client. Application creation continues through
the existing Server Action / Application Service boundary.

## Commit
`feat(opportunities): add matching and opportunity evaluation workspace`
