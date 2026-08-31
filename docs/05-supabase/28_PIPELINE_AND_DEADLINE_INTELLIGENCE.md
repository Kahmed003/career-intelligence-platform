## 1. Purpose

This milestone creates a derived operational intelligence layer across Career OS.

It does **not** introduce another lifecycle source of truth. Instead, it reads the
existing domain tables and produces normalized owner-scoped views for:

- opportunity deadlines;
- application next actions;
- interviews and assessments;
- offer decision deadlines;
- networking follow-ups;
- project/task deadlines;
- overdue items;
- upcoming work;
- recruiting pipeline summaries.

The goal is to answer operational questions such as:

- What requires attention today?
- What is overdue?
- Which applications are active?
- What interview or assessment is next?
- Which offer deadline is approaching?
- Who needs a follow-up?
- Which opportunities close soon?
- What does my recruiting funnel currently look like?

## 2. Architecture

The intelligence layer uses SQL views rather than duplicated tables.

Authoritative lifecycle state remains in:

- `public.opportunities`;
- `public.applications`;
- `public.interviews_assessments`;
- `public.offers`;
- `public.interactions_communications`;
- `public.tasks`.

The derived layer exposes:

1. `public.pipeline_deadline_items`
2. `public.pipeline_application_summary`

## 3. `pipeline_deadline_items`

This view normalizes time-sensitive records into a common shape.

### Output Fields

| Column | Purpose |
|---|---|
| `owner_user_id` | Owner boundary |
| `source_type` | Opportunity, application, interview, offer, interaction, task |
| `source_object_id` | Canonical object UUID |
| `parent_object_id` | Related parent where applicable |
| `title` | Canonical display title |
| `item_status` | Source lifecycle status |
| `action_type` | Human-readable operational action |
| `due_at` | Normalized deadline/next-action timestamp |
| `priority` | Normalized 1–5 priority when available |
| `urgency` | `overdue`, `today`, `next_3_days`, `next_7_days`, `later` |
| `organization_id` | Related organization where available |
| `application_id` | Related application where available |
| `opportunity_id` | Related opportunity where available |
| `person_id` | Related person where available |
| `metadata` | Source-specific context |

## 4. Included Deadline Sources

### Opportunities

Includes active opportunity application deadlines for:

- discovered;
- researching;
- qualified;
- pursuing.

### Applications

Includes `next_action_at` for nonterminal applications.

### Interviews and Assessments

Includes:

- scheduled interviews;
- scheduled assessments;
- assessment deadlines.

### Offers

Includes decision deadlines for offers still requiring a decision.

### Networking

Includes follow-up timestamps where `follow_up_required = true`.

### Tasks

Includes incomplete tasks with due dates.

## 5. Urgency Classification

Urgency is calculated relative to `current_date`:

- `overdue` — before today;
- `today` — due today;
- `next_3_days` — due within 3 days;
- `next_7_days` — due within 7 days;
- `later` — beyond 7 days.

The view intentionally leaves scheduling/reminder execution to the application
or automation layer.

## 6. `pipeline_application_summary`

This view creates one row per application with joined recruiting context.

It includes:

- application status;
- opportunity;
- organization;
- application deadline;
- submission date;
- next action;
- next interview/assessment;
- offer status;
- offer decision deadline;
- interview count;
- completed interview count.

This enables pipeline dashboards without adding denormalized state to the
application table.

## 7. Security Model

Both views are created with `security_invoker = true`.

This means underlying RLS policies remain authoritative. A user can only see
records allowed by the source tables' owner-scoped RLS rules.

No `security definer` view is introduced.

## 8. Design Decisions

- No new canonical object type is required.
- No duplicated status/deadline records are created.
- No trigger automatically synchronizes state between domains.
- Operational intelligence is recomputed from authoritative records at query time.
- The view uses canonical `public.objects.title` for display labels.
- The service/UI layer may apply additional ordering, notification thresholds,
  timezone conversion, or user preferences.
- This milestone does not create reminders itself; reminders should consume the
  normalized queue.

## 9. Recommended Query Patterns

### Highest-priority work queue

```sql
select *
from public.pipeline_deadline_items
order by
    case urgency
        when 'overdue' then 1
        when 'today' then 2
        when 'next_3_days' then 3
        when 'next_7_days' then 4
        else 5
    end,
    priority asc nulls last,
    due_at asc;
```

### Active application funnel

```sql
select *
from public.pipeline_application_summary
where application_status not in ('accepted', 'rejected', 'withdrawn', 'closed')
order by next_action_at nulls last, application_deadline_at nulls last;
