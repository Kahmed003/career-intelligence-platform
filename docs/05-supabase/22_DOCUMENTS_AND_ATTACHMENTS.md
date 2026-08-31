## 1. Purpose

The Documents and Attachments domain provides a governed metadata layer over
Supabase Storage.

It replaces ad hoc file-path fields with reusable document records that can be
attached to any Career OS object.

Examples include:

- resumes;
- cover letters;
- offer letters;
- transcripts;
- research posters;
- presentations;
- certificates;
- writing samples;
- project deliverables;
- interview preparation files;
- evidence artifacts.

Storage continues to hold file bytes. PostgreSQL stores searchable metadata,
ownership, lifecycle state, integrity constraints, and object relationships.

## 2. Core Tables

### `public.documents`

Each document extends one canonical record in `public.objects`.

| Column | Purpose |
|---|---|
| `id` | Shared UUID from `public.objects` |
| `document_type` | Functional document category |
| `bucket_id` | Supabase Storage bucket |
| `storage_path` | Object path within the bucket |
| `original_filename` | Filename supplied by user/source |
| `display_filename` | Optional cleaned display filename |
| `mime_type` | File MIME type |
| `file_extension` | Normalized extension |
| `file_size_bytes` | Optional size metadata |
| `checksum_sha256` | Optional SHA-256 digest |
| `document_status` | Active/archive/replaced/deleted lifecycle |
| `source_type` | How the document entered Career OS |
| `source_name` | Human-readable provenance |
| `version_number` | Logical document version |
| `supersedes_document_id` | Previous version, when applicable |
| `is_primary` | Marks preferred document among related versions |
| `description` | Optional description |
| `metadata` | Extensible structured metadata |
| `created_at` | Creation timestamp |
| `updated_at` | Update timestamp |

### `public.document_attachments`

Reusable many-to-many links between documents and any canonical object.

| Column | Purpose |
|---|---|
| `document_id` | Document being attached |
| `object_id` | Target canonical object |
| `attachment_role` | Meaning of the attachment |
| `is_primary` | Preferred attachment for that role/object |
| `attached_at` | Link creation timestamp |
| `metadata` | Relationship-specific metadata |

## 3. Document Types

- `resume`
- `cover_letter`
- `offer_letter`
- `transcript`
- `certificate`
- `portfolio`
- `presentation`
- `research_output`
- `writing_sample`
- `project_deliverable`
- `interview_material`
- `application_material`
- `evidence`
- `reference`
- `other`

## 4. Document Statuses

- `active`
- `archived`
- `replaced`
- `deleted`

`deleted` here is a document-domain lifecycle state. Canonical soft deletion
continues to use `public.objects.deleted_at`.

## 5. Source Types

- `upload`
- `generated`
- `imported`
- `email`
- `integration`
- `system`
- `other`

## 6. Attachment Roles

- `resume`
- `cover_letter`
- `offer_letter`
- `supporting_material`
- `evidence`
- `portfolio_item`
- `transcript`
- `certificate`
- `reference`
- `deliverable`
- `preparation`
- `other`

## 7. Storage Design

The Storage Foundation remains authoritative for binary object operations.

Recommended storage path:

```text
<user_uuid>/<domain>/<object_uuid>/<filename>
```

The database must not upload, move, copy, or delete Storage objects directly.
Those operations belong to the Supabase Storage API.

`documents.bucket_id` and `documents.storage_path` identify the corresponding
Storage object.

## 8. Design Decisions

- Documents are first-class canonical objects.
- Attachments are relationship records and therefore do not require their own
  `public.objects` rows.
- A single document may support multiple objects.
- A single object may have multiple documents.
- Document version history is explicit through `supersedes_document_id`.
- `is_primary` supports preferred resumes, offer letters, or evidence artifacts
  without deleting older versions.
- Existing raw storage-path columns in Applications, Offers, and Evidence remain
  temporarily for backward compatibility. A future hardening migration should
  backfill document records and deprecate those columns after application code
  has migrated.

## 9. Integrity Rules

- Canonical document object must have `object_type = 'document'`.
- Storage path must begin with the canonical owner's UUID.
- Bucket must be one of the governed Career OS buckets.
- A document cannot supersede itself.
- A superseded document must share the same owner.
- Version number must be positive.
- File size cannot be negative.
- SHA-256 digests must be 64 hexadecimal characters when supplied.
- Attachment document and target object must share the same owner.
- Attachment target must not be soft-deleted.
- Duplicate `(document_id, object_id, attachment_role)` links are prevented.

## 10. Workflow Support

Indexes support:

- object attachment retrieval;
- document version history;
- resume and application-material lookup;
- active document filtering;
- Storage-path resolution;
- primary-document retrieval;
- checksum lookup.

## 11. Security

RLS is enabled on both tables.

Document access is inherited from canonical object ownership.
Attachment access requires ownership of both the document and target object.

Anonymous access is revoked.

## 12. Migration Strategy for Existing Raw Paths

Do not immediately drop fields such as:

- `applications.resume_storage_path`;
- `applications.cover_letter_storage_path`;
- `offers.offer_letter_storage_path`;
- `evidence_achievements.storage_path`.

Recommended migration sequence:

1. deploy this domain;
2. write new uploads to `documents` + `document_attachments`;
3. backfill existing path values;
4. switch reads to the governed attachment model;
5. verify parity;
6. remove legacy path columns in a later migration.

This avoids destructive coupling between schema rollout and application code.

