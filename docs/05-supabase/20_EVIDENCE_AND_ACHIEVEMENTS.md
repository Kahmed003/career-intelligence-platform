## 1. Purpose

The Evidence and Achievements domain stores structured proof behind skills,
resume claims, applications, projects, goals, and professional narratives.

Examples include:

- quantified project outcomes;
- research posters and presentations;
- awards and scholarships;
- certifications;
- publications;
- leadership impact;
- internship deliverables;
- competition results;
- academic achievements;
- testimonials or formal recognition.

Each evidence item extends one canonical record in `public.objects`.

## 2. Core Table

`public.evidence_achievements`

| Column | Purpose |
|---|---|
| `id` | Shared UUID from `public.objects` |
| `evidence_type` | Kind of evidence or achievement |
| `verification_status` | Strength of verification |
| `issued_by_organization_id` | Optional issuer or granting organization |
| `related_person_id` | Optional verifier, recommender, or witness |
| `occurred_on` | Date achievement occurred |
| `valid_from` | Optional validity start |
| `valid_until` | Optional expiry |
| `quantified_value` | Numeric impact or result |
| `quantified_unit` | Unit for quantified value |
| `summary` | Concise evidence statement |
| `details` | Longer description |
| `source_url` | Public or internal reference URL |
| `storage_path` | Supabase Storage path |
| `credential_id` | Certificate or credential identifier |
| `is_resume_ready` | Whether evidence is ready for resume use |
| `is_portfolio_ready` | Whether evidence is ready for portfolio use |
| `created_at` | Creation timestamp |
| `updated_at` | Update timestamp |

## 3. Evidence Types

- `project_outcome`
- `work_achievement`
- `research_output`
- `publication`
- `presentation`
- `award`
- `scholarship`
- `certification`
- `competition_result`
- `academic_achievement`
- `leadership_impact`
- `testimonial`
- `credential`
- `other`

## 4. Verification Status

- `unverified`
- `self_verified`
- `documented`
- `third_party_verified`
- `official`

## 5. Design Decisions

- Canonical title remains in `public.objects.title`.
- Detailed relationships to skills, projects, applications, goals, and people
  should use the Relationship Graph rather than many nullable foreign keys.
- Issuer organization and verifier person are direct fields because they are
  common, operationally important attributes.
- Quantified value is optional and generic so the same model supports values such
  as percentages, dollars, people reached, megawatts, hours saved, or rankings.
- Storage contains the underlying proof; this table stores only the storage path.
- Resume and portfolio readiness are explicit workflow fields.

## 6. Integrity Rules

- Canonical object must have `object_type = 'evidence_achievement'`.
- Issuer organization and related person must share the same owner.
- `valid_until` cannot precede `valid_from`.
- Source URLs must use HTTP or HTTPS.
- Quantified unit is required when quantified value is present.
- Blank summaries, units, storage paths, and credential IDs are rejected.

## 7. Relationship Graph Usage

Recommended relationship types:

- skill `supported_by` evidence;
- project `produced` evidence;
- application `supported_by` evidence;
- goal `supported_by` evidence;
- person `verified` evidence;
- organization `issued` evidence.

Where catalog relationship types do not yet exist, add them through a governed
relationship-type migration rather than hard-coding ad hoc values.

## 8. Workflow Support

Indexes support:

- evidence type filtering;
- verification-strength reporting;
- resume-ready views;
- portfolio-ready views;
- credential expiry;
- issuer lookup;
- quantified-impact retrieval.

## 9. Security

RLS is enabled immediately. All linked entities must remain inside the same
owner boundary.


