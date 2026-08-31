## 1. Purpose

The Education and Academic Records domain stores structured academic history for
resume generation, application forms, academic planning, and career narratives.

Examples include:

- universities;
- secondary schools;
- degree programs;
- majors and minors;
- GPA;
- expected graduation;
- honors;
- scholarships;
- relevant coursework;
- study-abroad or exchange programs.

Each education record extends one canonical record in `public.objects`.

## 2. Core Table

`public.education_academic_records`

| Column | Purpose |
|---|---|
| `id` | Shared UUID from `public.objects` |
| `institution_id` | Linked educational organization |
| `education_level` | Secondary school, bachelor's, master's, etc. |
| `degree_name` | Formal degree/program name |
| `field_of_study` | Primary field or major |
| `secondary_field` | Minor, concentration, or second major |
| `start_date` | Program start |
| `end_date` | Actual or expected end |
| `is_current` | Whether enrollment is ongoing |
| `graduation_status` | Expected, graduated, withdrawn, etc. |
| `gpa` | Optional GPA |
| `gpa_scale` | GPA scale |
| `class_rank` | Optional rank |
| `class_size` | Optional cohort size |
| `honors` | Structured honors/awards |
| `relevant_coursework` | Structured coursework list |
| `activities` | Structured extracurricular/academic activities |
| `thesis_title` | Optional thesis/capstone title |
| `description` | Additional academic detail |
| `is_resume_ready` | Ready for resume generation |
| `created_at` | Creation timestamp |
| `updated_at` | Update timestamp |

## 3. Education Levels

- `secondary`
- `certificate`
- `associate`
- `bachelor`
- `master`
- `doctorate`
- `professional`
- `exchange`
- `other`

## 4. Graduation Status

- `enrolled`
- `expected`
- `graduated`
- `withdrawn`
- `deferred`
- `incomplete`

## 5. Design Decisions

- Institutions reuse the Organizations domain rather than introducing a separate
  school table.
- Canonical display title remains in `public.objects.title`.
- GPA is optional and stored with its scale to avoid assuming a universal 4.0 scale.
- Coursework, honors, and activities are structured JSON arrays for flexible
  downstream rendering.
- Scholarships and awards may also exist as Evidence/Achievement records; this
  table keeps a concise academic summary while evidence preserves proof.
- Detailed course-level transcripts belong in future coursework/transcript
  extensions rather than this core education record.

## 6. Integrity Rules

- Canonical object must have `object_type = 'education'`.
- Institution must exist, be active, and share the same owner.
- End date cannot precede start date.
- Current records must have graduation status `enrolled` or `expected`.
- GPA and GPA scale must be positive when present.
- GPA cannot exceed its scale.
- Class rank must be positive.
- Class size must be positive.
- Rank cannot exceed class size.
- Honors, coursework, and activities must be JSON arrays.

## 7. Workflow Support

Indexes support:

- education timeline retrieval;
- current enrollment;
- institution history;
- degree/education-level filtering;
- expected graduation lookup;
- resume-ready records.

## 8. Security

RLS is enabled immediately. Institution relationships must stay within the same
owner boundary.
