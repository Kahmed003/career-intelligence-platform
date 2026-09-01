## 1. Purpose

This milestone creates a derived analytics layer for Career Campaigns.

It measures:

- campaign application volume;
- submitted applications;
- assessments and interviews;
- offers and accepted outcomes;
- networking activity;
- saved-search activity;
- task completion;
- deadline pressure;
- target-progress ratios;
- funnel conversion;
- source effectiveness.

No campaign KPI is manually persisted.

## 2. Derived Views

### `public.campaign_performance_summary`

One row per Career Campaign.

Fields include:

- campaign identity and status;
- target counts;
- member counts;
- opportunity count;
- application count;
- submitted application count;
- interview/assessment count;
- completed interview/assessment count;
- offer count;
- accepted offer count;
- networking interaction count;
- completed networking interaction count;
- task count;
- completed task count;
- saved-search count;
- active saved-search count;
- upcoming deadline count;
- overdue deadline count;
- application target progress;
- networking target progress;
- interview target progress;
- application-to-interview conversion;
- interview-to-offer conversion;
- application-to-offer conversion;
- offer acceptance rate;
- campaign health.

### `public.campaign_source_performance`

One row per campaign × discovery source.

It summarizes:

- discovered records;
- promoted opportunities;
- applications;
- submitted applications;
- interviews/assessments;
- offers;
- source-to-opportunity conversion;
- source-to-application conversion;
- application-to-offer conversion.

## 3. Membership Semantics

Campaign analytics use `career_campaign_members` as the explicit campaign scope.

The analytics layer does not infer campaign membership merely because objects are
related elsewhere.

For applications and their downstream interviews/offers, direct campaign
membership of the application is sufficient to include its downstream funnel
events.

For opportunities, direct campaign membership is used unless they are reached
through a campaign application.

## 4. Funnel Definitions

### Application target progress

```text
application_count / target_application_count
```

### Networking target progress

```text
completed_networking_interaction_count / target_networking_count
```

### Interview target progress

```text
completed_interview_assessment_count / target_interview_count
```

Ratios are capped at 1.0 for target-progress reporting.

### Application → Interview

```text
applications with at least one interview/assessment
/
submitted applications
```

### Interview → Offer

```text
applications with at least one offer
/
applications with at least one interview/assessment
```

### Application → Offer

```text
applications with at least one offer
/
submitted applications
```

## 5. Campaign Health

Initial deterministic classification:

- `completed` — campaign status completed;
- `inactive` — paused/cancelled/archived;
- `critical` — overdue deadlines exist and no recent pipeline progress;
- `at_risk` — overdue deadlines or low progress late in campaign window;
- `on_track` — healthy progress and manageable deadlines;
- `early_stage` — insufficient elapsed campaign time or data.

This is an operational signal, not a career-outcome judgment.

## 6. Deadline Pressure

The view reuses `pipeline_deadline_items`.

Campaign deadlines are included when the deadline source object itself is a
campaign member, or when its parent/application/opportunity is a campaign member.

This avoids copying due dates into the campaign tables.

## 7. Source Performance

Source analytics join:

```text
Discovery Source
→ Discovered Opportunity
→ Promoted Opportunity
→ Application
→ Interview / Offer
```

Only objects inside the relevant campaign scope are counted.

## 8. Security

Both views use `security_invoker = true`.

Underlying RLS remains authoritative.

## 9. Design Decisions

- No KPI snapshots are persisted yet.
- Counts and conversions are recomputed from authoritative records.
- Campaign membership is the source of campaign scope.
- Manual campaign targets remain optional.
- A later analytics-history milestone can persist dated snapshots if trend
  analysis becomes necessary.
- The views favor explainability over complex predictive scoring.

