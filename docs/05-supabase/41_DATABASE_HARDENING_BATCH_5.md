
# Career OS — Database Hardening Batch 5

**Document ID:** COS-SUP-HARD-005  
**Version:** 1.0.0  
**Status:** Approved for implementation  
**Canonical path:** `docs/05-supabase/41_DATABASE_HARDENING_BATCH_5.md`

## Purpose

This batch closes the remaining high-value schema-integrity gaps before moving into
historical analytics.

It covers:

- Relationship Graph vocabulary expansion;
- Resume Content lineage and master-version integrity;
- Application Material role compatibility;
- Campaign Source Performance lifecycle filtering;
- Security/RLS regression coverage.

## Migration Order

1. `20260721014300_expand_relationship_types.sql`
2. `20260721014400_harden_resume_content_lineage.sql`
3. `20260721014500_harden_application_material_roles.sql`
4. `20260721014600_harden_campaign_source_performance.sql`
5. `supabase/tests/database/005_hardening_batch_5.sql`

## Relationship Graph

Adds governed relationship types needed by later domains:

- `supported_by`
- `produced`
- `verified_by`
- `issued_by`
- `attached_to`
- `variant_of`
- `scheduled_for`
- `member_of`

## Resume Content Lineage

Adds `parent_resume_content_id`.

Rules:

- same owner;
- same `content_type`;
- no self-reference;
- no recursive cycles;
- a master version cannot itself be a child variant;
- at most one active master per owner + content type + source object.

## Application Materials

Material items already restrict object type to `document` or `resume_content`.
This batch additionally validates semantic role compatibility.

Examples:

- resume → Resume Document or resume-ready content;
- cover letter → Cover Letter Document or cover-letter-ready content;
- transcript/certificate/portfolio/reference/writing sample → matching Document;
- application response → matching Resume Content or governed Document.

## Campaign Source Performance

Adds `public.campaign_source_performance_active`, which wraps the original analytics
view but requires both the Campaign and Discovery Source canonical objects to remain
active and same-owner.

## Security

Regression tests verify RLS remains enabled on key user-facing tables and SECURITY
DEFINER functions have hardened `search_path` handling.

## Exit Criteria

After this batch, the next database milestone is:

**Analytics Snapshots and Historical Trends**

## Commit

```text
fix(database): complete core schema hardening and integrity coverage
```
