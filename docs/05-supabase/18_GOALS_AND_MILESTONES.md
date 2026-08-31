
# Career OS — Goals and Milestones Domain

**Document ID:** COS-DOM-GOAL-001  
**Version:** 1.0.0  
**Status:** Approved for implementation  
**Canonical path:** `docs/05-supabase/18_GOALS_AND_MILESTONES.md`  
**Related migration:** `supabase/migrations/20260721010900_create_goals_and_milestones.sql`

## 1. Purpose

The Goals and Milestones domain provides the strategic planning layer above
Projects and Tasks.

It supports:

- long-term career goals;
- annual or semester objectives;
- recruiting targets;
- skill-development goals;
- academic goals;
- networking goals;
- project milestones;
- measurable progress tracking.

Each goal or milestone extends one canonical record in `public.objects`.

## 2. Core Table

`public.goals_milestones`

| Column | Purpose |
|---|---|
| `id` | Shared UUID from `public.objects` |
| `item_kind` | `goal` or `milestone` |
| `parent_goal_id` | Optional parent goal |
| `project_id` | Optional linked project |
| `status` | Current planning state |
| `priority` | Priority from 1–5 |
| `target_date` | Intended completion date |
| `completed_at` | Actual completion timestamp |
| `progress_percent` | Manual or computed progress, 0–100 |
| `metric_name` | Optional measurable KPI |
| `metric_target` | Optional target value |
| `metric_current` | Optional current value |
| `metric_unit` | Optional metric unit |
| `description` | Goal/milestone detail |
| `notes` | Planning notes |
| `created_at` | Creation timestamp |
| `updated_at` | Update timestamp |

## 3. Item Kinds

- `goal`
- `milestone`

## 4. Statuses

- `planned`
- `active`
- `at_risk`
- `blocked`
- `completed`
- `cancelled`
- `archived`

## 5. Design Decisions

- Goals may contain milestones through `parent_goal_id`.
- Milestones may optionally link to a project.
- Project execution remains in Projects and Tasks; this table expresses strategic
  intent and measurable outcomes.
- Progress can be manually maintained initially.
- Metrics are optional because not every career goal is naturally numeric.
- Canonical display titles remain in `public.objects.title`.

## 6. Integrity Rules

- Canonical object type must be `goal_milestone`.
- Parent goals must exist, have `item_kind = 'goal'`, and share the same owner.
- Project links must share the same owner.
- An item cannot parent itself.
- Progress must be between 0 and 100.
- Completed status requires `completed_at`.
- Non-completed items cannot report 100% progress unless explicitly marked completed.
- `metric_current` and `metric_target` require `metric_name`.
- Target metric values must not be negative when present.

## 7. Workflow Support

Indexes support:

- active goals by priority;
- milestone lookup by parent goal;
- project-linked milestones;
- upcoming target dates;
- at-risk and blocked planning views;
- progress reporting.

## 8. Security

RLS is enabled immediately. All linked entities must remain inside the same
owner boundary.

## 9. Recommended Commit Message

```text
feat(goals): create goals and milestones domain
```
