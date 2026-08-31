## 1. Purpose

This milestone creates an explainable opportunity-matching layer that compares
Career OS opportunities against user-defined career preference profiles.

It produces:

- criterion-level match evaluations;
- weighted match scores;
- hard-exclusion decisions;
- must-have failures;
- compensation compatibility;
- sponsorship compatibility;
- human-readable match explanations.

The layer is derived. It does not overwrite factual opportunity data or the
manually assigned `opportunities.fit_score`.

## 2. Derived Views

### `public.opportunity_preference_evaluations`

One row per:

`preference profile × opportunity × criterion`

Fields include:

- preference profile;
- opportunity;
- organization;
- criterion type/value;
- preference level;
- weight;
- exclusion flag;
- match state;
- matched boolean;
- weighted contribution;
- explanation.

### `public.opportunity_match_scores`

One row per:

`preference profile × opportunity`

Fields include:

- weighted score from 0–100;
- evaluable criteria count;
- matched criteria count;
- must-have failure count;
- exclusion count;
- compensation compatibility;
- sponsorship compatibility;
- recommendation status;
- explanation JSON.

## 3. Supported Criterion Evaluation

The first version evaluates criteria that map cleanly to structured opportunity
fields:

- `industry`
- `location`
- `country`
- `work_mode`
- `employment_type`
- `opportunity_type`
- `organization`
- `sponsorship`

The following criteria are retained in preference profiles but are marked
`not_evaluable` until structured opportunity-side data exists:

- `function`
- `role_family`
- `company_size`
- `skill`
- `compensation`
- `other`

This avoids pretending that keyword inference is equivalent to structured data.

## 4. Match Semantics

### Positive preferences

For:

- `must_have`
- `strong_preference`
- `preference`

a match contributes its weight.

A non-match contributes zero.

### Neutral

`neutral` criteria are informational and do not affect the score.

### Avoid

A matched `avoid` criterion contributes a negative weight.

### Hard exclusions

If `is_exclusion = true` and the criterion matches the opportunity, the
opportunity is excluded regardless of its weighted score.

### Must-have failure

If a `must_have` criterion is evaluable and does not match, the opportunity is
classified as `disqualified`.

## 5. Weighted Score

The score considers only evaluable, non-neutral criteria.

Conceptually:

```text
positive matched weight
- matched avoid weight
-------------------------------- × 100
total evaluable weighted preference
```

The score is clamped to `0–100`.

A profile with no evaluable weighted criteria receives no weighted score rather
than an artificial zero.

## 6. Compensation Compatibility

Profile-level compensation preferences are compared with structured opportunity
compensation.

The first version classifies compensation as:

- `compatible`
- `below_minimum`
- `unknown`
- `not_requested`

Comparison is only performed when:

- profile minimum compensation exists;
- opportunity compensation is populated;
- currency matches;
- compensation period is compatible.

Unknown or incompatible units do not create a false failure.

## 7. Sponsorship Compatibility

If the preference profile states `requires_sponsorship = true`:

- opportunity sponsorship `yes` => `compatible`;
- `no` => `incompatible`;
- `case_by_case` => `case_by_case`;
- `unknown` => `unknown`.

If sponsorship is not required, the result is `not_required`.

## 8. Recommendation Status

Possible values:

- `excluded` — a hard exclusion matched;
- `disqualified` — one or more evaluable must-have criteria failed;
- `sponsorship_conflict` — sponsorship is explicitly incompatible;
- `compensation_conflict` — known compensation is below the profile minimum;
- `strong_match` — score >= 75;
- `possible_match` — score >= 50;
- `weak_match` — score < 50;
- `insufficient_data` — no evaluable weighted criteria.

The recommendation status is deterministic and inspectable.

## 9. Explainability

The aggregate view exposes JSON fields containing:

- matched criteria;
- failed must-haves;
- matched exclusions;
- unevaluable criteria;
- compensation status;
- sponsorship status.

This makes it possible for the UI to show:

> 82% match — strong industry, work-mode, and opportunity-type fit; location did
> not match; sponsorship is case-by-case.

without relying on a hidden model judgment.

## 10. Security

Both views use `security_invoker = true`.

Underlying RLS policies on preference profiles, criteria, opportunities,
organizations, and objects remain authoritative.

## 11. Design Decisions

- No recommendation row is persisted in this milestone.
- No opportunity fact is mutated.
- No unsupported criterion is guessed using free-text heuristics.
- Manual `opportunities.fit_score` remains separate from computed profile match.
- Future versions may add structured role-function, skill requirements, company
  size, and normalized compensation taxonomies.
- Persisted recommendation snapshots, if needed later, should include algorithm
  version and input provenance.
