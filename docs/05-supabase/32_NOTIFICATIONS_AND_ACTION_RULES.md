## 1. Purpose

This domain provides a governed execution layer for reminders and notifications.

It consumes existing source-of-truth data such as:

- opportunity application deadlines;
- application next actions;
- interview schedules;
- assessment deadlines;
- offer decision deadlines;
- networking follow-ups;
- task due dates.

It does **not** duplicate or own those lifecycle deadlines.

Instead, it stores:

- reusable notification/action rules;
- rule targeting and timing configuration;
- generated notification records;
- delivery state;
- acknowledgment and dismissal state;
- source-object provenance;
- deduplication keys.

## 2. Core Tables

### `public.notification_rules`

First-class user-owned rules.

Examples:

- remind 7 days before an application deadline;
- remind 24 hours before an interview;
- flag networking follow-ups when overdue;
- alert on offer decision deadlines;
- remind on high-priority tasks due today.

Fields include:

- `id`
- `name`
- `status`
- `source_type`
- `action_type`
- `urgency_filter`
- `priority_max`
- `lead_time_minutes`
- `repeat_interval_minutes`
- `channel`
- `is_digest`
- `quiet_hours_behavior`
- `metadata`
- timestamps

### `public.notifications`

Generated notification records.

Fields include:

- `id`
- `notification_rule_id`
- `source_object_id`
- `parent_object_id`
- `source_type`
- `action_type`
- `title`
- `body`
- `scheduled_for`
- `status`
- `channel`
- `dedupe_key`
- `delivered_at`
- `read_at`
- `acknowledged_at`
- `dismissed_at`
- `failed_at`
- `failure_reason`
- `metadata`
- timestamps

## 3. Rule Status

- `draft`
- `active`
- `paused`
- `archived`

Only `active` rules should be evaluated by reminder-generation services.

## 4. Supported Source Types

- `opportunity`
- `application`
- `interview`
- `assessment`
- `offer`
- `interaction`
- `task`
- `other`

These align with the normalized deadline-intelligence layer.

## 5. Supported Action Types

The initial catalog includes:

- `application_deadline`
- `application_next_action`
- `scheduled_interview`
- `scheduled_assessment`
- `assessment_deadline`
- `offer_decision`
- `networking_follow_up`
- `task_due`
- `other`

A rule may leave `action_type` null to apply to all action types for the selected
source.

## 6. Urgency Filters

- `overdue`
- `today`
- `next_3_days`
- `next_7_days`
- `later`
- `any`

## 7. Channels

- `in_app`
- `email`
- `push`
- `sms`
- `webhook`
- `other`

This migration stores notification intent and delivery state. Actual provider
delivery belongs to application/integration services.

## 8. Notification Status

- `pending`
- `scheduled`
- `delivered`
- `read`
- `acknowledged`
- `dismissed`
- `failed`
- `cancelled`

## 9. Timing Model

`lead_time_minutes` defines how long before the source deadline the notification
should be scheduled.

Examples:

- `10080` = 7 days before;
- `1440` = 24 hours before;
- `60` = 1 hour before;
- `0` = at the deadline/action time.

`repeat_interval_minutes` is optional and allows the execution service to create
future repeated reminders. The database does not autonomously schedule jobs.

## 10. Deduplication

Each generated notification should carry a deterministic `dedupe_key`, typically
derived from:

```text
rule_id
+ source_object_id
+ action_type
+ source due timestamp
+ recurrence occurrence
```

The database enforces owner-local uniqueness through the owning rule.

## 11. Integrity Rules

- Notification-rule object must have `object_type = 'notification_rule'`.
- Rule names must be non-empty.
- Lead and repeat intervals cannot be negative.
- Priority filter must remain within 1–5.
- Generated source objects must share the rule owner's boundary.
- A delivered notification requires `delivered_at`.
- A read notification requires `read_at`.
- An acknowledged notification requires `acknowledged_at`.
- A dismissed notification requires `dismissed_at`.
- A failed notification requires `failed_at`.
- Failure reason is only meaningful for failed notifications.
- Delivery/read/acknowledgment/dismissal timestamps cannot precede creation.
- Notification body/title cannot be blank.
- Metadata must be JSON objects.

## 12. Security

`notification_rules` inherits ownership through `public.objects`.

`notifications` inherit ownership through their linked rule.

Cross-owner source-object references are rejected in both trigger validation and
RLS.

Anonymous access is revoked.

## 13. Execution Architecture

Recommended service flow:

```text
pipeline_deadline_items
        ↓
active notification_rules
        ↓
rule evaluation
        ↓
notifications
        ↓
provider delivery
        ↓
delivery/read/acknowledgment state
```

Rules and notifications are auditable even if provider delivery happens outside
PostgreSQL.

## 14. Design Decisions

- Reminder rules are first-class objects; generated notifications are operational
  child records.
- Notifications do not mutate application, opportunity, offer, interaction, or
  task lifecycle state.
- The database stores notification intent and audit state, not external provider
  credentials.
- Quiet hours behavior is stored as policy intent; actual local-time evaluation
  belongs to the execution service.
- No database cron job is created by this migration.
- Future automation services can safely consume the normalized pipeline views.

