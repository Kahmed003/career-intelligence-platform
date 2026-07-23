Career OS — Organizations Domain

Document ID: COS-DOM-ORG-001Version: 1.0.0Status: Approved for implementationCanonical path: docs/05-supabase/12_ORGANIZATIONS.mdRelated migration: supabase/migrations/20260721010300_create_organizations.sql

1. Purpose

Organizations represent institutions that appear throughout a user's career system,including:

companies;

universities;

investment firms;

research laboratories;

nonprofit organizations;

government agencies;

professional associations;

recruiting firms.

Each organization extends one canonical record in public.objects.

2. Table

public.organizations

Column

Purpose

id

Shared UUID from public.objects

legal_name

Optional formal registered name

organization_type

Stable machine-readable category

website_url

Canonical website

primary_domain

Normalized email or web domain

industry

Free-text initial industry classification

description

User-maintained organization profile

city

Primary city

region

State, province, or region

country_code

ISO-style two-letter country code

linkedin_url

Optional LinkedIn organization page

founded_year

Optional founding year

employee_count

Optional estimated headcount

created_at

Domain-row creation timestamp

updated_at

Domain-row update timestamp

3. Design Decisions

Canonical display name remains in public.objects.title.

legal_name is used only when different from the common display name.

organization_type remains constrained text because categories may expand.

primary_domain is normalized to lowercase and cannot include URL paths.

Industry is initially free text; a governed taxonomy can be introduced later.

Locations remain lightweight until multi-office support is required.

4. Initial Organization Types

company

university

investment_firm

research_institution

nonprofit

government

professional_association

recruiting_firm

other

5. Integrity Rules

The canonical object must have object_type = 'organization'.

Country codes must contain two uppercase letters.

Founded year must be plausible.

Employee count cannot be negative.

Website and LinkedIn values must begin with http:// or https://.

Primary domain must be lowercase and path-free.

The organization must remain owned by the same user as its canonical object.

6. Search and Lookup

Indexes support:

owner-mediated organization access through the object registry;

primary-domain matching;

organization-type filtering;

country filtering;

trigram search over legal names;

case-insensitive industry lookup.

7. Security

RLS is enabled immediately. Authenticated users may access organization rows onlywhen they own the corresponding canonical object.

8. Recommended Commit Message

feat(organizations): create organizations domain

9. Root README Addition

- [Organizations](docs/05-supabase/12_ORGANIZATIONS.md) — institutional profiles for employers, universities, investors, research institutions, and partner organizations.
