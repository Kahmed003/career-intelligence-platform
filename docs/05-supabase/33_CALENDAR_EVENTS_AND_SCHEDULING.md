## 1. Purpose

This domain provides a normalized scheduling layer for Career OS.

It supports:

- interview and assessment events;
- networking meetings;
- application deadlines;
- offer decision deadlines;
- task and project blocks;
- study / preparation sessions;
- recurring career-planning blocks;
- external Google / Outlook calendar synchronization.

The scheduling layer does **not** become the lifecycle source of truth for
applications, interviews, offers, tasks, or interactions. It represents the
calendar manifestation of those records.

## 2. Core Tables

### `public.calendar_events`

A first-class user-owned calendar event.

Key fields:

- `id`
- `event_type`
- `status`
- `source_object_id`
- `parent_object_id`
- `title`
- `description`
- `starts_at`
- `ends_at`
- `all_day`
- `timezone`
- `location_text`
- `meeting_url`
- `preparation_minutes`
- `follow_up_minutes`
- `is_recurring`
- `recurrence_rule`
- `metadata`
- timestamps

### `public.calendar_event_participants`

Participants linked to a calendar event.

Key fields:

- `calendar_event_id`
- `person_id`
- `participant_role`
- `response_status`
- `is_required`
- timestamps

### `public.external_calendar_links`

Synchronization state between Career OS calendar events and external providers.

Key fields:

- `id`
- `calendar_event_id`
- `provider`
- `external_calendar_id`
- `external_event_id`
- `sync_direction`
- `sync_status`
- `external_updated_at`
- `last_synced_at`
- `etag`
- `sync_error`
- `metadata`
- timestamps

## 3. Event Types

- `interview`
- `assessment`
- `networking`
- `application_deadline`
- `offer_deadline`
- `task`
- `project`
- `preparation`
- `study`
- `career_planning`
- `conference`
- `other`

## 4. Event Status

- `tentative`
- `confirmed`
- `completed`
- `cancelled`
- `rescheduled`

## 5. Participant Roles

- `interviewer`
- `recruiter`
- `mentor`
- `contact`
- `attendee`
- `organizer`
- `other`

## 6. Participant Response Status

- `needs_action`
- `accepted`
- `declined`
- `tentative`
- `unknown`

## 7. External Calendar Providers

Initial provider values:

- `google`
- `outlook`
- `apple`
- `other`

Provider credentials and OAuth tokens are **not** stored in these tables.

## 8. Sync Direction

- `push`
- `pull`
- `bidirectional`

## 9. Sync Status

- `pending`
- `synced`
- `conflict`
- `failed`
- `detached`

## 10. Design Decisions

- Calendar events are first-class objects because they need ownership, activity
  history, notes, relationships, and potential standalone scheduling blocks.
- Source career objects remain authoritative for business lifecycle state.
- `source_object_id` allows the same scheduling model to represent interviews,
  tasks, offers, networking meetings, or deadlines.
- `parent_object_id` supports broader grouping such as an Application or Project.
- Participant records reference canonical People rather than duplicating contact
  information.
- External provider identifiers are isolated in a separate sync table.
- Recurrence is stored as an iCalendar-style rule string; execution belongs to
  the scheduling service.
- Timezone is explicit to preserve wall-clock intent across DST and provider sync.

## 11. Integrity Rules

- Calendar event object must have `object_type = 'calendar_event'`.
- Source and parent objects must share the event owner.
- End time cannot precede start time.
- Non-all-day events require a timezone.
- Preparation/follow-up minutes cannot be negative.
- Recurring events require a recurrence rule.
- Non-recurring events cannot carry a recurrence rule.
- Meeting URLs must be HTTP(S).
- Participants must be same-owner Person objects.
- One person can appear only once per participant role on an event.
- External event identifiers are unique per provider/calendar.
- External sync links must reference same-owner calendar events.
- Failed sync state requires an error message.
- Non-failed sync state cannot retain a sync error.

## 12. Security

RLS is enabled across all three tables.

Ownership is inherited from the canonical Calendar Event object. Participant and
external-sync records are authorized through the owning event.

Anonymous access is revoked.

## 13. Recommended Workflow

```text
Career Object
(interview / task / interaction / offer / deadline)
        ↓
Calendar Event
        ↓
Participants
        ↓
External Calendar Link
        ↓
Google / Outlook / other provider
```

Provider callbacks update sync state but should not directly mutate career
lifecycle records without application-layer reconciliation.
