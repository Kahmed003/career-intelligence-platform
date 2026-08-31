## 1. Purpose

The Notes and Knowledge domain stores reusable context across Career OS.

Examples include:

- company research;
- networking notes;
- interview preparation;
- recruiting-process observations;
- market and industry research;
- meeting notes;
- reflections;
- technical research notes;
- application-specific context;
- career strategy notes.

Each note extends one canonical record in `public.objects`.

## 2. Core Table

`public.notes_knowledge`

| Column | Purpose |
|---|---|
| `id` | Shared UUID from `public.objects` |
| `note_type` | Functional category |
| `content` | Main note body |
| `summary` | Optional concise summary |
| `source_type` | Origin of the information |
| `source_name` | Human-readable source |
| `source_url` | Optional external reference |
| `source_occurred_at` | When source event/content occurred |
| `captured_at` | When note was captured |
| `confidence_score` | Confidence in extracted/recalled information |
| `is_pinned` | Pin important notes |
| `is_archived` | Archive without deleting |
| `metadata` | Extensible structured metadata |
| `created_at` | Creation timestamp |
| `updated_at` | Update timestamp |

## 3. Note Types

- `general`
- `company_research`
- `person_research`
- `networking`
- `meeting`
- `interview_prep`
- `application`
- `market_research`
- `technical`
- `academic`
- `reflection`
- `strategy`
- `idea`
- `other`

## 4. Source Types

- `user`
- `conversation`
- `meeting`
- `email`
- `website`
- `document`
- `article`
- `research`
- `system`
- `other`

## 5. Object Linking

A note may be related to any object through the existing Relationship Graph.

Recommended examples:

- organization `associated_with` note;
- person `associated_with` note;
- application `associated_with` note;
- interview/assessment `associated_with` note;
- project `associated_with` note;
- skill `supported_by` note;
- evidence `derived_from` note.

This avoids adding nullable foreign keys for every possible domain.

## 6. Design Decisions

- Canonical note title remains in `public.objects.title`.
- Notes are first-class objects so they can participate in relationships,
  activity history, search, and future AI workflows.
- `content` is plain text/Markdown-compatible content at the database layer.
- Provenance is explicit because future generated summaries and recommendations
  must be traceable to their source material.
- Confidence is optional and primarily intended for imported, extracted, or
  machine-generated knowledge.
- Archive state is separate from canonical soft deletion.

## 7. Integrity Rules

- Canonical object must have `object_type = 'note'`.
- Note content must be non-empty.
- Source URL must use HTTP or HTTPS.
- Confidence score must be between 0 and 1.
- Metadata must be a JSON object.
- Blank source names and summaries are rejected.

## 8. Search

The migration enables PostgreSQL full-text search using an expression GIN index
over the canonical object title, summary, source name, and note content.

Trigram indexing is also added for source-name lookup.

## 9. Workflow Support

Indexes support:

- pinned-note views;
- note category filtering;
- source/provenance retrieval;
- chronological research timelines;
- archived vs active note views;
- full-text knowledge search.

## 10. Security

RLS is enabled immediately. Users may access only notes whose canonical objects
they own.

