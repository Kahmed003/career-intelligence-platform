Career OS — People and Contacts Domain

Document ID: COS-DOM-PEOPLE-001Version: 1.0.0Status: Approved for implementationCanonical path: docs/05-supabase/13_PEOPLE.mdRelated migration: supabase/migrations/20260721010400_create_people.sql

1. Purpose

The People domain represents individuals who appear in a user's career ecosystem,including:

recruiters;

hiring managers;

mentors;

professors;

alumni;

investors;

founders;

colleagues;

professional contacts;

referral sources.

Each person extends one canonical record in public.objects.

2. Table

public.people

Column

Purpose

id

Shared UUID from public.objects

organization_id

Optional current organization

first_name

Person's given name

middle_name

Optional middle name

last_name

Person's family name

preferred_name

Optional preferred display name

headline

Professional headline or summary

job_title

Current role

department

Current department or function

email

Primary email address

phone

Primary phone number

linkedin_url

LinkedIn profile

website_url

Personal or professional website

city

Current city

region

State, province, or region

country_code

Two-letter country code

relationship_stage

Current relationship state

last_contacted_at

Most recent known interaction

next_follow_up_at

Planned follow-up timestamp

notes

User-maintained relationship context

created_at

Domain-row creation timestamp

updated_at

Domain-row update timestamp

3. Relationship Stages

uncontacted

outreach_sent

connected

active_relationship

dormant

do_not_contact

4. Design Decisions

The canonical display name remains in public.objects.title.

Structured name fields support sorting, search, and personalization.

One current organization may be stored directly for efficient access.

Historical roles should later be represented through a dedicated employmenthistory table or relationship records.

Contact fields are optional because many contacts begin with incomplete data.

Relationship stage is user-specific and operational rather than a universalproperty of the person.

5. Integrity Rules

The canonical object must have object_type = 'person'.

The linked organization, when present, must be owned by the same user.

Email addresses are normalized to lowercase.

Country codes are normalized to uppercase.

URLs must begin with http:// or https://.

Follow-up timestamps may exist independently of prior contact timestamps.

Blank structured name values are rejected.

6. Search and Workflow Support

Indexes support:

organization lookups;

email matching;

relationship-stage filtering;

follow-up queues;

recent-contact sorting;

trigram search across structured names, titles, and headlines.

7. Security

RLS is enabled immediately. Authenticated users may access a person only whenthey own the corresponding canonical object.

8. Recommended Commit Message

feat(people): create people and contacts domain

9. Root README Addition

- [People and Contacts](docs/05-supabase/13_PEOPLE.md) — professional contacts, affiliations, outreach status, and relationship follow-up data.
