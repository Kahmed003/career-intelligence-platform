# Career OS — Applications Workspace UI

**Document ID:** COS-UI-APP-001
**Version:** 1.0.0
**Depends on:** Batches 1–6

## Purpose

Implement the first complete frontend vertical slice over the Career OS application domain.

## Routes

- `/applications` — pipeline/list workspace
- `/applications/new` — create an application
- `/applications/[id]` — application detail and lifecycle controls

## Data flow

Reads:
`Server Component → PipelineQueryService → pipeline_application_summary → PostgreSQL/RLS`

Writes:
`Client/Form → Server Action → ApplicationsService → repository/database → cache revalidation`

## Design constraints

- Server Components own reads.
- Mutations use Batch 3 Server Actions.
- No raw browser-side Supabase persistence.
- Application lifecycle changes are explicit user actions.
- Status controls do not infer outcomes.
- Pipeline UI must tolerate missing optional data.

## Commit

`feat(applications): add application pipeline and lifecycle workspace`
