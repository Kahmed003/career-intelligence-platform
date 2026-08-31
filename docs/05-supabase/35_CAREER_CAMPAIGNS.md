## 1. Purpose

This domain groups related Career OS activity into coherent recruiting campaigns.

Examples:

- Summer 2027 internship search;
- energy consulting recruiting;
- quantitative trading applications;
- Europe-focused opportunities;
- graduate fellowship cycle;
- targeted company campaign.

A campaign is a strategic container, not another lifecycle state machine.

It can group:

- preference profiles;
- saved searches;
- opportunities;
- applications;
- people;
- organizations;
- tasks;
- projects;
- interactions;
- material sets;
- calendar events;
- notes.

## 2. Core Tables

### `public.career_campaigns`

A first-class campaign object.

Fields include:

- `id`
- `campaign_type`
- `status`
- `start_date`
- `end_date`
- `target_application_count`
- `target_networking_count`
- `target_interview_count`
- `preference_profile_id`
- `description`
- `notes`
- timestamps

### `public.career_campaign_members`

Generic membership table linking canonical Career OS objects to a campaign.

Fields include:

- `campaign_id`
- `object_id`
- `member_role`
- `priority`
- `status`
- `added_at`
- `metadata`

This avoids hard-coding a large number of nullable foreign keys into the
campaign table.

## 3. Campaign Types

- `internship_search`
- `full_time_search`
- `fellowship_search`
- `graduate_school`
- `networking`
- `industry_strategy`
- `geography_strategy`
- `company_targeting`
- `general`
- `other`

## 4. Campaign Status

- `planned`
- `active`
- `paused`
- `completed`
- `cancelled`
- `archived`

## 5. Member Roles

- `target`
- `supporting`
- `networking`
- `application`
- `search`
- `task`
- `research`
- `material`
- `calendar`
- `other`

Member role is contextual and does not replace the canonical object's own type.

## 6. Member Status

- `active`
- `completed`
- `dropped`
- `archived`

This is campaign membership state only. It does not alter the object's own
domain status.

## 7. Design Decisions

- Campaigns are first-class objects.
- Membership is generic and uses canonical object IDs.
- Underlying Opportunities, Applications, Tasks, People, etc. remain authoritative.
- One object may belong to multiple campaigns.
- Campaigns may optionally reference one preference profile as their primary
  search intent.
- Detailed campaign analytics should be derived in later views rather than stored
  manually.
- Campaign membership should not duplicate Relationship Graph semantics. The
  campaign membership table is specifically operational grouping.

## 8. Integrity Rules

- Campaign object must have `object_type = 'career_campaign'`.
- Linked preference profile must share owner and be active/not deleted.
- Campaign end date cannot precede start date.
- Target counts cannot be negative.
- Campaign member must share the campaign owner.
- Duplicate `(campaign_id, object_id, member_role)` membership is prevented.
- Membership priority must be 1–5.
- Metadata must be a JSON object.

## 9. Suggested Workflows

### Recruiting cycle

```text
Career Campaign
    ├── Preference Profile
    ├── Saved Searches
    ├── Target Organizations
    ├── Opportunities
    ├── Applications
    ├── Networking Contacts
    ├── Tasks
    ├── Resume / Material Sets
    └── Calendar Events
```

### Example

```text
Summer 2027 Quant Campaign
    preference profile → Quant Trading
    saved searches → IMC / Jane Street / AQR / general quant
    targets → selected firms
    opportunities → open internships
    applications → submitted processes
    networking → traders / recruiters
    tasks → assessments / follow-ups
```

## 10. Security

RLS is enabled on both tables.

Campaign ownership is inherited from `public.objects`.

Membership rows are visible and mutable only when both the campaign and member
object belong to the current user.

Anonymous access is revoked.

