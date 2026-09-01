## Purpose

This batch fixes three confirmed issues in the implemented schema:

1. Opportunity matching reads industry from the wrong table.
2. Shared SECURITY DEFINER helpers require stronger privilege/search-path controls.
3. Resume profiles and career preference profiles permit multiple active defaults per owner.

All corrections are forward migrations. Existing migration history remains immutable.

## Migration Order

1. `20260721013100_fix_opportunity_matching_industry.sql`
2. `20260721013200_harden_shared_database_functions.sql`
3. `20260721013300_enforce_single_default_profiles.sql`
4. `supabase/tests/database/002_hardening_batch_2.sql`

## Opportunity Matching

`public.opportunities` does not own the normalized industry field. Industry belongs to the linked Organization. The evaluation view is recreated so `industry` criteria evaluate `organizations.industry`.

The score view is recreated afterward because it depends on the criterion-level evaluation view.

## Shared Function Security

Authorization helpers are recreated with:

```text
search_path = pg_catalog, public
```

Mutation helpers explicitly assert ownership before writes.

PUBLIC and anonymous execution is revoked. Authenticated users receive only the helper execution required by RLS/application behavior.

## Default Profiles

Career OS permits at most one active default Resume Profile and one active default Career Preference Profile per owner.

Because owner identity remains canonical in `public.objects`, enforcement uses validation triggers rather than duplicating owner columns.

## Testing

Regression tests verify:

- opportunity matching no longer references `op.industry`;
- the matching view references Organization industry;
- SECURITY DEFINER helper search paths are hardened;
- public execution is not available;
- single-default validation triggers exist.
