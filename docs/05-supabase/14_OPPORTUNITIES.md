Career OS — Opportunities Domain

Document ID: COS-DOM-OPP-001Version: 1.0.0Status: Approved for implementationCanonical path: docs/05-supabase/14_OPPORTUNITIES.mdRelated migration: supabase/migrations/20260721010500_create_opportunities.sql

1. Purpose

The Opportunities domain represents external career, academic, and professionalopportunities that a user may evaluate, pursue, track, or archive.

Examples include:

internships;

full-time and part-time jobs;

fellowships;

scholarships;

research programs;

competitions;

conferences;

accelerators;

grants;

networking programs.

Each opportunity extends one canonical record in public.objects.

2. Table

public.opportunities

Column

Purpose

id

Shared UUID from public.objects

organization_id

Optional sponsoring or hiring organization

opportunity_type

Stable machine-readable opportunity category

status

Current evaluation and pursuit state

external_id

Employer or platform requisition identifier

source_name

Discovery source, such as Handshake or LinkedIn

source_url

Canonical posting or program URL

description

Opportunity description or user summary

location_text

Human-readable location

country_code

Optional two-letter country code

work_mode

On-site, hybrid, remote, or unspecified

employment_type

Internship, full-time, part-time, contract, etc.

application_open_at

Application opening timestamp

application_deadline_at

Application deadline

start_date

Expected program or job start

end_date

Expected program or job end

compensation_min

Lower compensation bound

compensation_max

Upper compensation bound

compensation_currency

Three-letter currency code

compensation_period

Hourly, monthly, annual, stipend, or total

visa_sponsorship

Known sponsorship position

requires_work_authorization

Whether work authorization is required

priority

User-defined pursuit priority from 1 to 5

fit_score

Optional user or model score from 0 to 100

notes

User-maintained evaluation notes

created_at

Domain-row creation timestamp

updated_at

Domain-row update timestamp

3. Opportunity Types

internship

job

fellowship

scholarship

research_program

competition

conference

accelerator

grant

networking_program

other

4. Opportunity Statuses

discovered

researching

qualified

pursuing

not_pursuing

closed

archived

Application-specific statuses belong in the Applications domain rather than thistable.

5. Design Decisions

The display title remains in public.objects.title.

Organization affiliation is optional because some opportunities are discoveredbefore the sponsor is fully identified.

Compensation uses numeric bounds and explicit currency and period fields.

fit_score is informational and does not replace human judgment.

Application workflow is intentionally separated into a future Applicationsdomain so one opportunity may support multiple attempts or application records.

Source metadata supports deduplication and provenance.

6. Integrity Rules

The canonical object must have object_type = 'opportunity'.

A linked organization must have the same owner as the opportunity.

Deadline cannot precede the application opening timestamp.

End date cannot precede start date.

Compensation maximum cannot be below minimum.

Currency codes must contain three uppercase letters.

Country codes must contain two uppercase letters.

Priority must be between 1 and 5.

Fit score must be between 0 and 100.

URLs must begin with http:// or https://.

7. Search and Workflow Support

Indexes support:

organization lookups;

opportunity type and status filtering;

deadline queues;

start-date planning;

source and external-ID deduplication;

high-priority and high-fit opportunity views;

trigram search over descriptions and locations.

8. Security

RLS is enabled immediately. Authenticated users may access an opportunity onlywhen they own the corresponding canonical object.

9. Recommended Commit Message

feat(opportunities): create opportunities domain

10. Root README Addition

- [Opportunities](docs/05-supabase/14_OPPORTUNITIES.md) — internships, jobs, fellowships, research programs, scholarships, competitions, and other career opportunities.
