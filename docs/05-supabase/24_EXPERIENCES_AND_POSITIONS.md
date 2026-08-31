## 1. Purpose

The Experiences and Positions domain stores structured career-history records
that can feed resumes, profiles, applications, skill evidence, and professional
narratives.

Examples include:

- internships;
- full-time and part-time jobs;
- research assistantships;
- teaching assistant roles;
- leadership positions;
- volunteer positions;
- fellowships;
- campus roles;
- consulting projects;
- independent professional engagements.

Each experience extends one canonical record in `public.objects`.

## 2. Core Table

`public.experiences_positions`

| Column | Purpose |
|---|---|
| `id` | Shared UUID from `public.objects` |
| `organization_id` | Optional employer/institution |
| `experience_type` | Internship, research, teaching, etc. |
| `employment_type` | Full-time, part-time, contract, etc. |
| `title` | Role title |
| `department` | Optional team/function |
| `location_text` | Human-readable location |
| `country_code` | Optional two-letter country code |
| `work_mode` | Onsite, hybrid, remote, unspecified |
| `start_date` | Experience start |
| `end_date` | Experience end |
| `is_current` | Whether role is ongoing |
| `hours_per_week` | Approximate workload |
| `summary` | Concise role summary |
| `responsibilities` | Longer responsibility description |
| `achievements` | Structured JSON array/object for notable outcomes |
| `is_resume_ready` | Whether record is ready for resume generation |
| `is_profile_ready` | Whether record is ready for public/profile use |
| `created_at` | Creation timestamp |
| `updated_at` | Update timestamp |

## 3. Experience Types

- `internship`
- `employment`
- `research`
- `teaching`
- `leadership`
- `volunteer`
- `fellowship`
- `campus_role`
- `consulting_project`
- `independent_project`
- `other`

## 4. Employment Types

- `full_time`
- `part_time`
- `contract`
- `temporary`
- `seasonal`
- `volunteer`
- `fellowship`
- `academic`
- `project_based`
- `other`

## 5. Work Modes

- `onsite`
- `hybrid`
- `remote`
- `unspecified`

## 6. Design Decisions

- Canonical display title remains in `public.objects.title`; the `title` field in
  this table is the formal role title.
- Organization is optional to support independent projects and community work.
- Detailed proof and quantified results should be linked through the Evidence and
  Achievements domain.
- Skill mappings should use the Relationship Graph instead of repeating skill IDs.
- Resume/profile readiness is explicit so downstream generators can filter cleanly.

## 7. Integrity Rules

- Canonical object must have `object_type = 'experience'`.
- Linked organization must exist, be active, and share the same owner.
- `end_date` cannot precede `start_date`.
- Current experiences cannot have an `end_date`.
- Non-current experiences must have an `end_date`.
- Hours per week must be between 0 and 168.
- Country code must be two uppercase letters when present.
- Title and summary cannot be blank when supplied.
- Achievements must be a JSON object or array.

## 8. Workflow Support

Indexes support:

- chronological experience timelines;
- current-role retrieval;
- organization history;
- experience-type filtering;
- resume-ready/profile-ready views;
- country and work-mode filtering.

## 9. Security

RLS is enabled immediately. All linked organizations must share the canonical
experience owner's user boundary.


