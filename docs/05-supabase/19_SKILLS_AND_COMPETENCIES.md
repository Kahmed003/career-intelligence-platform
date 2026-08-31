## 1. Purpose

The Skills and Competencies domain maintains a structured inventory of a user's
technical, analytical, business, communication, and domain-specific capabilities.

Examples include:

- Python;
- MATLAB;
- SQL;
- Excel;
- power markets;
- financial modeling;
- quantitative research;
- data analysis;
- public speaking;
- case interviewing;
- project management.

Each skill extends one canonical record in `public.objects`.

## 2. Core Table

`public.skills_competencies`

| Column | Purpose |
|---|---|
| `id` | Shared UUID from `public.objects` |
| `skill_category` | Broad skill grouping |
| `proficiency_level` | Current proficiency |
| `target_proficiency_level` | Optional desired level |
| `development_status` | Current development state |
| `years_experience` | Approximate years of experience |
| `last_used_at` | Most recent known use |
| `evidence_status` | Whether the skill has supporting evidence |
| `evidence_summary` | Short evidence description |
| `certification_name` | Optional certification |
| `certification_expires_at` | Optional certification expiry |
| `notes` | User-maintained notes |
| `created_at` | Creation timestamp |
| `updated_at` | Update timestamp |

## 3. Skill Categories

- `programming`
- `data`
- `quantitative`
- `engineering`
- `energy`
- `finance`
- `consulting`
- `research`
- `communication`
- `leadership`
- `project_management`
- `language`
- `other`

## 4. Proficiency Levels

- `awareness`
- `beginner`
- `intermediate`
- `advanced`
- `expert`

## 5. Development Statuses

- `active`
- `maintaining`
- `learning`
- `planned`
- `paused`
- `retired`

## 6. Evidence Statuses

- `none`
- `self_reported`
- `project_evidence`
- `work_evidence`
- `academic_evidence`
- `certified`

## 7. Design Decisions

- Canonical skill name remains in `public.objects.title`.
- Current and target proficiency are stored explicitly for gap analysis.
- Evidence is summarized here, while detailed proof should be linked through the
  Relationship Graph or future Evidence domain.
- Skill-to-project, skill-to-goal, and skill-to-application mappings should use
  relationship records rather than hard-coded foreign-key columns.
- Years of experience is approximate and optional.

## 8. Integrity Rules

- Canonical object must have `object_type = 'skill'`.
- Years of experience cannot be negative.
- Certification expiry requires a certification name.
- Blank evidence summaries and certification names are rejected.
- Enum-like text values must belong to the governed sets above.

## 9. Workflow Support

Indexes support:

- skill inventory by category;
- proficiency and target-gap analysis;
- active learning queues;
- evidence readiness;
- certification-expiry monitoring;
- recently used skills.

## 10. Security

RLS is enabled immediately. Users may access only skill records whose canonical
objects they own.

## 11. Recommended Commit Message

