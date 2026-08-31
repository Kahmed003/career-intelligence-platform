1. Purpose

The Offers domain represents formal or informal offers that result from an
application process.

It separates offer economics and decision-making from the broader application
lifecycle.

Examples include:

internship offers;

full-time offers;

fellowship awards;

scholarship awards;

research-program offers;

return offers.

Each offer extends one canonical record in public.objects.

2. Core Table

public.offers

Column

Purpose

id

Shared UUID from public.objects

application_id

Parent application

organization_id

Offering organization

status

Current offer state

offer_received_at

Date/time offer was received

decision_deadline_at

Employer/program decision deadline

decision_at

User decision timestamp

decision

Accepted, declined, expired, etc.

start_date

Expected start date

end_date

Expected end date

base_compensation

Base pay or stipend amount

compensation_currency

ISO-style currency code

compensation_period

Hour, month, year, stipend, total

signing_bonus

Signing or one-time bonus

performance_bonus_target

Target bonus

equity_value

Estimated equity value

relocation_amount

Relocation support

housing_amount

Housing support

other_compensation

Structured JSON for additional economics

work_mode

Onsite, hybrid, remote, unspecified

location_text

Primary work/program location

negotiation_status

Negotiation lifecycle

negotiated_at

Last negotiation timestamp

offer_letter_storage_path

Storage path for offer letter

comparison_score

Optional user/model comparison score

notes

Offer and decision notes

created_at

Creation timestamp

updated_at

Update timestamp

3. Offer Statuses

received

reviewing

negotiating

accepted

declined

expired

rescinded

4. Decisions

accepted

declined

expired

rescinded

5. Negotiation Status

not_started

considering

requested

in_progress

completed

not_applicable

6. Design Decisions

An application may theoretically generate more than one offer version over
time, so the table does not impose a strict one-offer-per-application limit.

Economics are normalized into major compensation components while preserving
other_compensation JSON for less common terms.

Decision state is separate from offer status to preserve history and reporting.

A dedicated offer comparison layer can later aggregate multiple offers.

Offer letters remain in Storage; this table stores only the path until a
generalized attachment model is introduced.

7. Integrity Rules

Canonical object must have object_type = 'offer'.

Parent application must exist and have the same owner.

Organization must match the application organization when both are present.

Currency code must contain three uppercase letters.

Compensation amounts cannot be negative.

End date cannot precede start date.

Accepted/declined/expired/rescinded statuses require a matching decision.

A non-null decision requires decision_at.

Decision deadline cannot precede receipt time.

Comparison score must be between 0 and 100.

8. Workflow Support

Indexes support:

open-offer dashboards;

decision-deadline queues;

employer offer history;

accepted-offer reporting;

negotiation-state filtering;

compensation comparison.

9. Security

RLS is enabled immediately. All linked entities must share the same owner.

