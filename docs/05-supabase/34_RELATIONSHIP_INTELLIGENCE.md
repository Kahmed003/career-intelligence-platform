## 1. Purpose

This milestone creates a derived relationship-intelligence layer across Career OS.

It combines:

- People;
- Organizations;
- Interactions and Communications;
- Relationship Graph edges;
- application and opportunity context.

It produces:

- relationship recency;
- interaction volume;
- response rate;
- follow-up health;
- stale-contact signals;
- active-networking signals;
- relationship-health classifications;
- warm-introduction candidates.

No new manual relationship-health state is introduced.

## 2. Derived Views

### `public.person_relationship_health`

One row per Person.

Fields include:

- `owner_user_id`
- `person_id`
- `person_name`
- `organization_id`
- `organization_name`
- `relationship_stage`
- `last_contacted_at`
- `next_follow_up_at`
- `interaction_count`
- `outbound_count`
- `inbound_count`
- `meeting_count`
- `response_count`
- `response_rate`
- `days_since_last_interaction`
- `overdue_follow_up_count`
- `open_follow_up_count`
- `relationship_score`
- `relationship_health`
- `relationship_flags`
- `latest_interaction_summary`

### `public.relationship_warm_intro_candidates`

Finds possible warm-introduction paths where a known Person is connected by
Relationship Graph edges to another Person or Organization.

The view is intentionally conservative and only uses explicit graph edges. It
does not infer social relationships from employer overlap alone.

## 3. Relationship Health Categories

- `strong`
- `healthy`
- `needs_attention`
- `stale`
- `unengaged`

These are derived classifications, not persisted lifecycle states.

## 4. Relationship Score

The first version computes an explainable 0–100 score from:

- recency of the latest interaction;
- total interaction volume;
- inbound engagement;
- completed meetings;
- overdue follow-up penalties;
- relationship stage.

The score is intentionally simple and deterministic.

It is not intended to measure personal closeness. It is an operational signal
for professional relationship management.

## 5. Recency Logic

Suggested recency contribution:

- interaction in last 14 days — highest;
- last 30 days — strong;
- last 60 days — moderate;
- last 120 days — weak;
- older / none — minimal.

## 6. Engagement Logic

Positive signals include:

- inbound replies;
- mutual conversations;
- meetings;
- recruiter/mentor conversations;
- referral outcomes;
- repeated interaction history.

Negative signals include:

- overdue follow-ups;
- repeated no-response outcomes;
- long inactivity.

## 7. Relationship Flags

The view emits JSON flags such as:

- `follow_up_overdue`
- `follow_up_due_soon`
- `stale_contact`
- `no_interaction_history`
- `active_relationship`
- `recruiter_contact`
- `referral_signal`
- `recent_response`

These can support dashboard badges or action queues.

## 8. Warm Introduction Candidates

The warm-intro view uses explicit Relationship Graph paths.

Examples:

```text
You know Person A
Person A works_at Organization X
```

or:

```text
Person A introduced_by Person B
```

The view surfaces possible paths but does not claim that an introduction is
available or appropriate.

## 9. Security

All derived views use `security_invoker = true`.

Underlying RLS remains authoritative.

## 10. Design Decisions

- No new first-class object type is required.
- Relationship health is recomputed rather than persisted.
- Relationship stage on `people` remains user-managed operational state.
- This milestone does not automatically change `people.relationship_stage`.
- Warm-introduction candidates rely only on explicit graph evidence.
- No sensitive inference such as personal friendship strength is attempted.
- Score weights can be versioned later if a recommendation service begins to
  persist snapshots.

