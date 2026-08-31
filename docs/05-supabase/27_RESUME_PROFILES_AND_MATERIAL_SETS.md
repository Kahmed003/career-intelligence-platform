## 1. Purpose

This domain assembles approved Career OS content into reusable resume profiles
and application material packages.

It supports configurations such as:

- Quant resume;
- Energy / Consulting resume;
- Technical / Data resume;
- Investment Banking resume;
- research-focused CV;
- application-specific material packages.

The underlying experiences, education, skills, projects, documents, and content
remain canonical and reusable. Profiles select and order them.

## 2. Core Tables

### `public.resume_profiles`

Defines a reusable resume or CV configuration.

Key fields:

- `id`
- `profile_type`
- `status`
- `target_function`
- `target_role_family`
- `target_industry`
- `target_location`
- `max_pages`
- `is_default`
- `summary_content_id`
- `resume_document_id`
- `notes`
- timestamps

### `public.resume_profile_items`

Ordered items included in a profile.

Key fields:

- `resume_profile_id`
- `object_id`
- `section_type`
- `position`
- `is_visible`
- `custom_label`
- `metadata`

The object may be an experience, education record, project, skill, resume
content record, evidence record, or another supported canonical object.

### `public.application_material_sets`

Defines a package of materials prepared for an application or opportunity.

Key fields:

- `id`
- `application_id`
- `opportunity_id`
- `resume_profile_id`
- `status`
- `label`
- `notes`
- timestamps

### `public.application_material_items`

Individual governed documents/content included in the package.

Key fields:

- `material_set_id`
- `object_id`
- `material_role`
- `position`
- `is_required`
- `is_submitted`
- `submitted_at`
- `metadata`

## 3. Resume Profile Types

- `resume`
- `cv`
- `one_page_resume`
- `two_page_resume`
- `academic_cv`
- `other`

## 4. Profile Status

- `draft`
- `active`
- `archived`

## 5. Resume Section Types

- `summary`
- `education`
- `experience`
- `projects`
- `research`
- `leadership`
- `skills`
- `awards`
- `publications`
- `other`

## 6. Material Set Status

- `draft`
- `ready`
- `submitted`
- `archived`

## 7. Material Roles

- `resume`
- `cover_letter`
- `transcript`
- `writing_sample`
- `portfolio`
- `certificate`
- `reference`
- `application_response`
- `supporting_document`
- `other`

## 8. Design Decisions

- Profiles are first-class objects because they need lifecycle state,
  application links, activity history, and future AI generation support.
- Profile items are ordered join records rather than first-class objects.
- Material sets are first-class objects because they represent a concrete,
  reusable application package.
- Material items can point to either document objects or approved content
  objects, depending on the role.
- A profile can point to one generated resume document while still retaining
  the structured selection used to create it.
- Application material sets can inherit application/opportunity context but do
  not mutate application lifecycle state automatically.

## 9. Integrity Rules

- Resume profile canonical object must have `object_type = 'resume_profile'`.
- Material set canonical object must have `object_type = 'material_set'`.
- All linked objects must share the same owner.
- Summary content must have `object_type = 'resume_content'`.
- Resume document must have `object_type = 'document'`.
- Application and opportunity must match when both are present.
- Profile items must reference supported canonical object types.
- Duplicate object/section entries in a profile are prevented.
- Item positions must be nonnegative.
- Material submission timestamp requires `is_submitted = true`.
- `submitted` material sets require an application.

## 10. Workflow Support

Indexes support:

- active/default profile lookup;
- profile rendering order;
- target-function retrieval;
- application package retrieval;
- submission readiness;
- missing required-material queries;
- submitted material history.

## 11. Security

RLS is enabled on all four tables.

All linked objects must remain within the same owner boundary.

