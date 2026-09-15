# Career OS — Opportunities Workspace Batch 8

Apply after Batch 7.

## CSS integration

At the top of `src/app/globals.css`, after the existing application-workspace import, add:

```css
@import "./opportunity-workspace.css";
```

## Implemented
- ranked opportunity workspace;
- client-side role/company/location search;
- opportunity-type filtering;
- opportunity detail route;
- preference criterion evaluation;
- organization context from matching read model;
- direct Start Application workflow using the existing application Server Action.

This removes the normal need to manually copy an Opportunity UUID into the Applications workspace.

## Integration note
The repository return shape is normalized in the opportunity detail page using the Batch 1
`OpportunitiesRepository` contract. After replacing the placeholder Supabase database types with
generated types, remove localized `any` casts and derive explicit DTOs from the generated view/table
types.

## Next
Batch 9 — Network / Relationship Workspace:
people, organizations, relationship health, follow-up queue, interaction history, and communication capture.
