# Career OS — Next.js Server Actions Batch 3

Depends on Data Access Batch 1 and Application Services Batch 2.

Merge `package.server-actions.json` into the real `package.json`, install dependencies, then run:

```bash
npm run db:types
npm run typecheck
```

Use Server Actions for client/form mutations. Server Components may call application services directly for trusted server-side reads.

The schemas intentionally validate stable boundary invariants without duplicating every PostgreSQL constraint.
