## 1. Purpose

This domain models how external opportunities enter Career OS.

It supports:

- recurring job and internship searches;
- company career pages;
- job boards;
- university portals;
- newsletters;
- recruiter feeds;
- conference and fellowship sources;
- manual discovery;
- ingestion-run provenance;
- external identifiers;
- deduplication keys;
- discovery-to-opportunity conversion.

The discovery layer is intentionally separate from `public.opportunities`.
Discovery records describe how something was found; Opportunity records remain
the canonical qualified representation used by the application pipeline.

## 2. Core Tables

### `public.discovery_sources`

A governed source such as a company career page, job board, newsletter, portal,
search engine, recruiter feed, or manual source.

Fields include:

- `id`
- `source_type`
- `name`
- `base_url`
- `organization_id`
- `is_active`
- `trust_level`
- `notes`
- timestamps

### `public.saved_searches`

A reusable search definition.

Fields include:

- `id`
- `discovery_source_id`
- `preference_profile_id`
- `name`
- `query_text`
- `filters`
- `schedule_hint`
- `is_active`
- `last_run_at`
- `next_run_at`
- timestamps

### `public.discovery_runs`

One execution of a saved search or source scan.

Fields include:

- `id`
- `saved_search_id`
- `discovery_source_id`
- `started_at`
- `completed_at`
- `status`
- `records_seen`
- `records_created`
- `records_updated`
- `records_skipped`
- `error_message`
- `metadata`

### `public.discovered_opportunities`

Raw-but-structured discovered records before or during promotion to a canonical
Opportunity.

Fields include:

- `id`
- `discovery_source_id`
- `discovery_run_id`
- `saved_search_id`
- `external_id`
- `external_url`
- `dedupe_key`
- `raw_title`
- `raw_organization_name`
- `raw_location`
- `raw_description`
- `raw_payload`
- `published_at`
- `discovered_at`
- `ingestion_status`
- `promoted_opportunity_id`
- timestamps

## 3. Discovery Source Types

- `company_careers`
- `job_board`
- `university_portal`
- `professional_network`
- `newsletter`
- `recruiter`
- `conference`
- `fellowship_portal`
- `search_engine`
- `api`
- `manual`
- `other`

## 4. Trust Levels

- `high`
- `medium`
- `low`
- `unknown`

Trust is informational and should not imply factual verification by itself.

## 5. Discovery Run Status

- `queued`
- `running`
- `completed`
- `partial`
- `failed`
- `cancelled`

## 6. Ingestion Status

- `new`
- `reviewing`
- `promoted`
- `duplicate`
- `ignored`
- `invalid`

## 7. Design Decisions

- Discovery sources are first-class objects because they have lifecycle,
  provenance, notes, organization links, and future integration metadata.
- Saved searches are first-class objects because they are reusable user assets.
- Discovery runs are operational records and do not need canonical object IDs.
- Discovered opportunities are staging records, not canonical Opportunity objects.
- Promotion creates or links a record in `public.opportunities`.
- Raw payload is preserved as JSON for provenance while selected fields are
  normalized for inspection and deduplication.
- Deduplication should happen before promotion whenever possible.
- External source content must not silently overwrite user-edited canonical
  Opportunity fields without an explicit reconciliation workflow.

## 8. Deduplication

A discovered record may be identified by:

1. `(source, external_id)` when a stable external identifier exists;
2. `(source, dedupe_key)` when an ingestion pipeline computes a stable key;
3. application-layer fuzzy matching for records without either.

The database enforces uniqueness only for reliable structured identifiers.

## 9. Integrity Rules

- `discovery_source` objects require `object_type = 'discovery_source'`.
- `saved_search` objects require `object_type = 'saved_search'`.
- Linked organizations and preference profiles must share the same owner.
- Discovery run completion cannot precede start.
- Completed/partial/failed/cancelled runs require `completed_at`.
- Ingestion status `promoted` requires `promoted_opportunity_id`.
- Promoted Opportunity must share the source owner's boundary.
- Source URLs must be HTTP(S) when present.
- Counts cannot be negative.
- Raw payload and search filters must be JSON objects.

## 10. Workflow

Typical flow:

```text
Discovery Source
      ↓
Saved Search
      ↓
Discovery Run
      ↓
Discovered Opportunity
      ↓ review / dedupe / normalize
Canonical Opportunity
      ↓
Matching Intelligence
      ↓
Application Pipeline
```

## 11. Security

RLS is enabled on all tables.

First-class source/search records inherit ownership from `public.objects`.
Operational child records are authorized through their owning source/search.

Anonymous access is revoked.

