# Career OS — Next.js App Shell and Dashboard UI

**Document ID:** COS-UI-001  
**Version:** 1.0.0  
**Depends on:** Batches 1–5

## Purpose

Create the first navigable Career OS App Router surface over the existing backend.

## Routes

- `/login`
- `/dashboard`
- `/applications`
- `/opportunities`
- `/network`
- `/projects`
- `/settings`

## Architecture

```text
Root Layout
├── Auth routes
└── Protected App Layout
    ├── Sidebar
    ├── Header
    └── Route content
```

The protected layout checks the authenticated Supabase user on the server. Dashboard data is loaded
through the Batch 4 query layer; React components do not issue raw Supabase queries.

## UI principles

- Server Components by default.
- Client Components only when browser state/interactivity requires them.
- Semantic HTML and keyboard-accessible navigation.
- Responsive shell.
- Reusable primitive components instead of page-local styling duplication.
- No business workflow orchestration in React.

## Commit

`feat(ui): add authenticated Career OS app shell and dashboard`
