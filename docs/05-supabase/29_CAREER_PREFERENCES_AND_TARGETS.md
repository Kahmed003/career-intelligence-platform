## 1. Purpose

This domain stores user-specific career preferences and search criteria without
embedding them into opportunities or applications.

It supports:

- target functions;
- target industries;
- preferred locations;
- work-mode preferences;
- employment types;
- opportunity types;
- compensation expectations;
- visa/work-authorization constraints;
- company-size preferences;
- weighted must-have and nice-to-have criteria.

These records can later drive opportunity scoring, ranking, recommendation, and
search-filter generation.

## 2. Core Tables

### `public.career_preference_profiles`

A first-class preference profile.

Fields include:

- `id`
- `profile_name`
- `status`
- `is_default`
- `target_start_date`
- `target_end_date`
- `minimum_compensation`
- `preferred_compensation`
- `compensation_currency`
- `compensation_period`
- `requires_sponsorship`
- `work_authorization_notes`
- `minimum_fit_score`
- `notes`
- timestamps

### `public.career_preference_criteria`

Weighted criteria attached to a preference profile.

Fields include:

- `preference_profile_id`
- `criterion_type`
- `criterion_value`
- `preference_level`
- `weight`
- `is_exclusion`
- `notes`
- timestamps

## 3. Profile Status

- `draft`
- `active`
- `archived`

Only active profiles should be used by recommendation workflows.

## 4. Criterion Types

Initial supported criteria:

- `function`
- `role_family`
- `industry`
- `location`
- `country`
- `work_mode`
- `employment_type`
- `opportunity_type`
- `company_size`
- `organization`
- `skill`
- `compensation`
- `sponsorship`
- `other`

## 5. Preference Levels

- `must_have`
- `strong_preference`
- `preference`
- `neutral`
- `avoid`

`is_exclusion = true` provides an explicit hard exclusion separate from soft
preference levels.

## 6. Weighting

Each criterion has a numeric weight from 0 to 100.

Recommended interpretation:

- `100` — decisive;
- `70–99` — very important;
- `40–69` — meaningful;
- `1–39` — minor preference;
- `0` — informational only.

Scoring logic should be implemented in a later recommendation/intelligence
milestone rather than inside this storage migration.

## 7. Design Decisions

- Preference profiles are first-class canonical objects.
- Criteria are child records and do not require canonical object IDs.
- Multiple profiles allow different strategies, such as:
  - general Summer 2027 search;
  - quant-focused search;
  - energy/consulting search;
  - geography-specific search.
- Opportunity records remain factual. User preference does not mutate opportunity data.
- Compensation expectations belong to the profile; actual compensation remains
  on the Opportunity or Offer domains.
- Visa/work-authorization preferences remain user-specific and separate from an
  opportunity's stated sponsorship policy.
- Organization- and skill-specific preferences are stored as criterion values
  now; future hardening can add typed object references where useful.

## 8. Integrity Rules

- Canonical preference profile object must have
  `object_type = 'career_preference_profile'`.
- Profile name must be non-empty.
- Target end date cannot precede target start date.
- Compensation values cannot be negative.
- Preferred compensation cannot be below minimum compensation when both exist.
- Compensation currency is required when compensation values are present.
- Minimum fit score must be between 0 and 100.
- Criterion values must be non-empty.
- Criterion weights must be between 0 and 100.
- Duplicate criterion type/value combinations within one profile are prevented.
- Profile and criteria owner boundaries are enforced through the parent profile.

## 9. Recommendation Usage

Future scoring can evaluate:

```text
opportunity facts
+ user preference profile
+ criterion weights
+ exclusions
+ skills / evidence
+ application history
= computed opportunity score
```

No score is persisted by this milestone.

## 10. Workflow Support

Indexes support:

- default active-profile lookup;
- profile status filtering;
- criterion-type filtering;
- exclusion filtering;
- weighted criteria retrieval;
- target-date search windows.

## 11. Security

RLS is enabled on both tables.

Preference profiles inherit ownership from `public.objects`. Criteria are
accessible only when their parent preference profile belongs to the current user.

Anonymous access is revoked.

