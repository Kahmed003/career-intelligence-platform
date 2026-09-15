# Career OS — Communications Mutation Batch 10

Apply after Batch 9.

## Replace the Batch 9 disabled capture component

In the person detail route, replace the detail grid with:

```tsx
<PersonNetworkWorkspace person={person} interactions={(interactions ?? []) as any[]} />
```

Import:
```ts
import { PersonNetworkWorkspace } from "@/components/network/person-network-workspace";
```

In the organization detail route, replace the detail grid with:

```tsx
<OrganizationNetworkWorkspace
  organization={organization}
  people={(people ?? []) as any[]}
  interactions={(interactions ?? []) as any[]}
/>
```

Import:
```ts
import { OrganizationNetworkWorkspace } from "@/components/network/organization-network-workspace";
```

## Barrel exports

Add:
```ts
export * from "./interactions.repository";
```
to `src/lib/data/repositories/index.ts`.

Add:
```ts
export * from "./interactions.service";
```
to `src/lib/application/services/index.ts`.

Add:
```ts
export * from "./interactions.actions";
```
to `src/lib/actions/index.ts`.

## CSS

Add to the top of `src/app/globals.css`:
```css
@import "./communication-workspace.css";
```

## Architecture

The browser does not write directly to Supabase. Communication capture now follows:

form → Server Action → Zod → service → repository → PostgreSQL/RLS → activity ledger.

## Known production hardening

This still inherits the earlier multi-step atomicity gap. A future database RPC batch should make
object creation, interaction insertion, and activity event creation atomic.

## Next

Batch 11 — Projects + Tasks workspace, including project overview, task board, evidence linkage, and
career-outcome tracking.
