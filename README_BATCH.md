# Career OS — Applications Workspace Batch 7

Apply after Batch 6.

## Important CSS integration

Import this batch's application workspace stylesheet from `src/app/globals.css`:

```css
@import "./application-workspace.css";
```

Place the `@import` at the top of `globals.css`.

## Implemented

- application pipeline board;
- full application list;
- application detail route;
- new application form;
- application lifecycle/status mutation control;
- next interview/assessment and offer summary;
- authenticated server-side reads through `PipelineQueryService`;
- writes through Batch 3 Server Actions.

## Current integration constraint

The create form asks for an Opportunity UUID because the Opportunities workspace has not yet been
implemented. Batch 8 should build the Opportunities vertical slice and replace that UUID field with
an opportunity picker/search flow.

The application components use localized `any` for view rows until generated Supabase view types are
available. Do not spread these casts into service/repository code.

## Next

Batch 8 — Opportunities Workspace:
- ranked opportunity list;
- filters;
- opportunity detail;
- preference-match explanation;
- organization context;
- start-application workflow.
