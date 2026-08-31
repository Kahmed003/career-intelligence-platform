## 1. Purpose

The Resume Content and Career Narratives domain stores reusable, structured
professional writing that can be assembled into resumes, applications, profiles,
cover letters, networking materials, and interview narratives.

Examples include:

- resume bullets;
- achievement statements;
- professional summaries;
- project descriptions;
- leadership narratives;
- technical summaries;
- application-tailored bullets;
- short bios;
- interview story prompts;
- cover-letter source paragraphs.

Each content item extends one canonical record in `public.objects`.

## 2. Core Table

`public.resume_content`

| Column | Purpose |
|---|---|
| `id` | Shared UUID from `public.objects` |
| `content_type` | Bullet, summary, narrative, bio, etc. |
| `content_text` | Reusable professional text |
| `content_status` | Draft, approved, archived, etc. |
| `tone` | Neutral, technical, executive, concise, etc. |
| `target_function` | Quant, consulting, energy, finance, engineering, etc. |
| `target_role_family` | Optional role-family label |
| `target_industry` | Optional industry label |
| `source_object_id` | Primary object from which content was derived |
| `evidence_object_id` | Optional supporting evidence record |
| `word_count` | Stored for filtering and generation |
| `character_count` | Stored for constrained application fields |
| `impact_score` | Optional ranking score |
| `is_master_version` | Marks canonical reusable version |
| `is_resume_ready` | Approved for resume use |
| `is_cover_letter_ready` | Approved for cover-letter use |
| `is_interview_ready` | Approved for interview-story use |
| `metadata` | Structured generation/tailoring metadata |
| `created_at` | Creation timestamp |
| `updated_at` | Update timestamp |

## 3. Content Types

- `resume_bullet`
- `achievement_statement`
- `professional_summary`
- `project_summary`
- `experience_summary`
- `leadership_story`
- `technical_narrative`
- `career_narrative`
- `short_bio`
- `interview_story`
- `cover_letter_paragraph`
- `application_response`
- `other`

## 4. Content Status

- `draft`
- `review`
- `approved`
- `superseded`
- `archived`

## 5. Tone

- `neutral`
- `concise`
- `technical`
- `quantitative`
- `executive`
- `consulting`
- `academic`
- `conversational`
- `other`

## 6. Target Functions

The schema intentionally uses text rather than a hard enum for target functions,
because Career OS may expand to new role families. Typical values include:

- quant;
- trading;
- data;
- software;
- energy;
- consulting;
- finance;
- investment_banking;
- research;
- engineering;
- product;
- general.

## 7. Design Decisions

- Canonical display title remains in `public.objects.title`.
- Content is first-class so it can be versioned, searched, attached, scored,
  related to applications, and surfaced by AI workflows.
- `source_object_id` provides one primary provenance pointer for common use cases.
  Additional supporting objects should use the Relationship Graph.
- `evidence_object_id` provides a direct, high-value link to the strongest proof
  behind a statement when available.
- Master content is separated from tailored variants through `is_master_version`
  and Relationship Graph links such as `derived_from`.
- Content length is stored explicitly for fast filtering against application
  character/word limits.
- Generated text should not silently overwrite approved master content.
  New variants should be separate rows.

## 8. Integrity Rules

- Canonical object must have `object_type = 'resume_content'`.
- Content text must be non-empty.
- Source object must exist, not be deleted, and share the same owner.
- Evidence object must be an `evidence_achievement` and share the same owner.
- Impact score must be between 0 and 100.
- Word and character counts must be nonnegative.
- Approved resume/cover-letter/interview-ready content must have
  `content_status = 'approved'`.
- Blank targeting labels are rejected.
- Stored length fields are automatically recalculated by trigger.

## 9. Relationship Graph Usage

Recommended relationships include:

- resume content `derived_from` experience;
- resume content `derived_from` project;
- resume content `derived_from` education;
- resume content `supports` application;
- evidence `supports` resume content;
- skill `associated_with` resume content;
- tailored content `derived_from` master content.

## 10. Workflow Support

Indexes support:

- approved resume bullets;
- master content retrieval;
- target-function filtering;
- source-object content retrieval;
- evidence-backed statements;
- impact-score ranking;
- content-type/status filtering.

## 11. Security

RLS is enabled immediately.

The content object, source object, and evidence object must remain within the
same owner boundary.
