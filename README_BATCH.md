# Career OS — Network & Relationship Workspace Batch 9

Apply after Batch 8.

## CSS
Add at the top of `src/app/globals.css`:

```css
@import "./application-workspace.css";
@import "./opportunity-workspace.css";
@import "./network-workspace.css";
```

## Query export
Add this export to `src/lib/queries/index.ts`:

```ts
export * from "./network.query";
```

## Implemented
- relationship health overview;
- follow-up queue;
- person detail pages;
- organization detail pages;
- organization contact lists;
- person/organization interaction history.

## Deliberate boundary
Interaction creation is **not** implemented by inserting directly into `interactions_communications`.
The existing application-service batches did not create a validated interaction mutation service.
The UI therefore displays a clear disabled capture state instead of bypassing the architecture.

## Next
Batch 10 should add the Interaction/Communication mutation vertical slice:
repository + application service + Zod schema + Server Action + capture form, then connect it here.
