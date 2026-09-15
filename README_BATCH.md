# Career OS — Next.js App Shell Batch 6

Apply on top of Batches 1–5.

## Includes
- App Router root layout
- authenticated `(app)` route group
- login route
- server-side auth guard
- sidebar and top header
- live dashboard page using Batch 4 `loadCareerDashboard()`
- placeholder domain workspaces for applications, opportunities, network, projects, and settings
- responsive baseline CSS

## Integration
Regenerate Supabase types and typecheck the complete project:

```bash
npm run db:types
npm run typecheck
```

The dashboard component currently uses localized `any` access for read-view rows because Batch 4's
DTO deliberately used `unknown[]`. Replace those with generated view-derived DTOs in the next
frontend hardening pass.

## Next
Build the Applications vertical slice:
- pipeline board/list
- application detail page
- status transition controls
- deadline/next-action UI
- application creation form using Batch 3 Server Actions
