Purpose

Applications represent a user's concrete pursuit of an external opportunity.
An opportunity describes what exists externally; an application records the
user's own attempt, materials, recruiting stage, contacts, decisions, and outcome.

Core Table

public.applications

Key fields:

id — shared UUID from public.objects

opportunity_id — opportunity being pursued

organization_id — employer/sponsor, denormalized for pipeline reporting

status — current application stage

application_method — submission channel

submitted_at, withdrawn_at, decision_at

outcome — terminal result when known

requisition_id, portal_url

resume_storage_path, cover_letter_storage_path

additional_materials — JSON metadata for essays/transcripts/portfolios

referral_person_id, recruiter_person_id

priority, fit_score, next_action_at, notes

created_at, updated_at

Lifecycle States

draft, preparing, submitted, assessment, interviewing, offer,
accepted, rejected, withdrawn, closed

Final Outcomes

offer, accepted, rejected, withdrawn, expired, cancelled

Application Methods

company_portal, email, referral, recruiter, campus_portal,
linkedin, handshake, other

Integrity Rules

Canonical object must have object_type = 'application'.

Opportunity must exist, be active, and have the same owner.

Organization, recruiter, and referral person must have the same owner.

Application organization must agree with the opportunity's organization.

Submitted or later-stage applications require submitted_at.

Withdrawn applications require withdrawn_at.

Offer/accepted/rejected/closed decisions require decision_at.

Priority is 1–5; fit score is 0–100.

Outcome and status must be logically consistent.
