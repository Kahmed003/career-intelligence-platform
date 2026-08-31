
## 1. Purpose

The Interactions and Communications domain records the relationship history
behind networking, recruiting, mentorship, and professional outreach.

Examples include:

- LinkedIn outreach;
- email exchanges;
- recruiter calls;
- coffee chats;
- mentor meetings;
- informational interviews;
- conference conversations;
- follow-up messages;
- referral conversations;
- application-related communications.

Each interaction extends one canonical record in `public.objects`.

## 2. Core Table

`public.interactions_communications`

| Column | Purpose |
|---|---|
| `id` | Shared UUID from `public.objects` |
| `interaction_type` | Meeting, email, LinkedIn, call, etc. |
| `direction` | Inbound, outbound, or mutual |
| `status` | Planned, sent, completed, cancelled, etc. |
| `person_id` | Primary person involved |
| `organization_id` | Optional organization context |
| `application_id` | Optional related application |
| `opportunity_id` | Optional related opportunity |
| `occurred_at` | Actual interaction timestamp |
| `scheduled_for` | Planned interaction timestamp |
| `duration_minutes` | Optional duration |
| `subject` | Short topic or message subject |
| `summary` | Concise interaction summary |
| `channel_detail` | Platform, phone, office, venue, etc. |
| `outcome` | Relationship/recruiting result |
| `follow_up_required` | Explicit follow-up flag |
| `follow_up_at` | Planned follow-up timestamp |
| `response_received_at` | Response timestamp where relevant |
| `external_message_id` | Provider/message identifier |
| `source_system` | Gmail, LinkedIn, manual, etc. |
| `metadata` | Extensible integration/context data |
| `created_at` | Creation timestamp |
| `updated_at` | Update timestamp |

## 3. Interaction Types

- `email`
- `linkedin_message`
- `phone_call`
- `video_call`
- `coffee_chat`
- `in_person_meeting`
- `informational_interview`
- `recruiter_conversation`
- `mentor_meeting`
- `conference_conversation`
- `career_fair`
- `follow_up`
- `other`

## 4. Direction

- `outbound`
- `inbound`
- `mutual`

## 5. Statuses

- `planned`
- `sent`
- `delivered`
- `completed`
- `cancelled`
- `no_response`
- `rescheduled`

## 6. Outcomes

- `none`
- `awaiting_response`
- `responded`
- `connected`
- `meeting_scheduled`
- `referral_offered`
- `referral_received`
- `application_guidance`
- `relationship_advanced`
- `no_response`
- `closed`
- `other`

## 7. Design Decisions

- Canonical display title remains in `public.objects.title`.
- A primary person is optional because some interactions may initially be tied
  only to an organization or opportunity.
- Organization may be inferred from the linked person in the application layer,
  but the direct field preserves historical organizational context.
- Communications are first-class objects so they can participate in activity
  history, notes, attachments, search, and future integrations.
- Full message bodies should not be duplicated unnecessarily when Gmail or
  another provider remains the source of truth. This table stores operational
  metadata, summary, outcome, and provider identifiers.
- Detailed meeting notes should use the Notes and Knowledge domain and link back
  through the Relationship Graph.
- Parent application status should not be mutated automatically by communication
  triggers. Workflow orchestration belongs in the service layer.

## 8. Integrity Rules

- Canonical object must have `object_type = 'interaction'`.
- Linked person, organization, application, and opportunity must share the same owner.
- If both application and opportunity are present, the application's opportunity
  must match.
- If application has an organization, interaction organization must match it
  when explicitly supplied.
- Duration cannot be negative.
- Follow-up timestamp requires `follow_up_required = true`.
- Completed interactions require `occurred_at`.
- Response timestamp cannot precede the interaction timestamp when both exist.
- Blank subjects, summaries, external IDs, source systems, and channel details
  are rejected.

## 9. Workflow Support

Indexes support:

- interaction timeline by person;
- organization relationship history;
- application/recruiting communication history;
- upcoming meetings;
- follow-up queues;
- unanswered outreach;
- source-system/message reconciliation;
- recent completed interactions.

## 10. Security

RLS is enabled immediately.

All linked entities must share the canonical interaction owner's user boundary.
Anonymous access is revoked.

