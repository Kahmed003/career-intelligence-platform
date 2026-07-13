# Career OS Lifecycle Specification

**Document ID:** DOM-005
**Version:** 1.0
**Status:** Draft
**Owner:** Ahmed Kazadi Kabuya
**Last Updated:** 2026-07-12

**Related Documents:**

* `docs/00-vision/MANIFESTO.md`
* `docs/01-product/PRD.md`
* `docs/02-domain/DOMAIN_MODEL.md`
* `docs/02-domain/GLOSSARY.md`
* `docs/02-domain/OBJECTS.md`
* `docs/02-domain/RELATIONSHIPS.md`

---

## Purpose

This document defines the valid states, transitions, override rules, and historical requirements for major Career OS objects.

Lifecycle definitions support:

* Consistent workflows.
* Reliable analytics.
* AI reasoning.
* Status automation.
* Auditability.
* Historical reconstruction.
* User control.

---

# 1. Lifecycle Philosophy

Career OS uses a hybrid lifecycle model.

## Standard behavior

Objects should normally move through predefined, validated transitions.

## Override behavior

A user may move an object through a non-standard transition when real-world circumstances require it.

An override must record:

* Previous state.
* New state.
* Reason.
* User who initiated the change.
* Timestamp.
* Related Evidence, when available.

## AI behavior

Career OS may:

* Recommend a transition.
* Detect a likely transition from email or calendar activity.
* Flag an unusual transition.
* Explain why a transition is recommended.
* Ask for confirmation before consequential changes.

Career OS may not silently make consequential lifecycle changes without explicit approval.

---

# 2. Shared Lifecycle Contract

Every lifecycle-enabled object should support:

* `status`
* `previous_status`
* `status_changed_at`
* `status_changed_by`
* `transition_reason`
* `transition_origin`
* `override_used`
* `override_reason`
* `activity_id`
* `evidence_ids`

## Transition origins

* user_manual
* system_rule
* imported
* ai_suggested
* integration_detected
* lifecycle_automation

## General rules

1. Every transition must be recorded.
2. Historical transitions must not be overwritten.
3. Current status is derived from the latest valid transition.
4. Consequential AI-detected transitions require user approval.
5. Backward transitions are allowed when justified.
6. Archived objects retain their full lifecycle history.
7. Deleted objects must not erase audit-critical transition history unless required by user data-deletion rights.

---

# 3. Opportunity Lifecycle

## States

```text
DISCOVERED
RESEARCHING
INTERESTED
QUALIFIED
NOT_QUALIFIED
MONITORING
READY_TO_PURSUE
EXPIRED
WITHDRAWN
ARCHIVED
```

## Standard transitions

```text
DISCOVERED
→ RESEARCHING
→ INTERESTED
→ QUALIFIED
→ READY_TO_PURSUE
```

Alternative transitions:

```text
RESEARCHING → NOT_QUALIFIED
INTERESTED → MONITORING
QUALIFIED → MONITORING
READY_TO_PURSUE → EXPIRED
ANY ACTIVE STATE → WITHDRAWN
ANY TERMINAL STATE → ARCHIVED
```

## State meanings

### DISCOVERED

The Opportunity has been identified but not yet evaluated.

### RESEARCHING

The user or system is gathering information.

### INTERESTED

The Opportunity appears relevant and deserves further consideration.

### QUALIFIED

Available Evidence indicates the user meets core eligibility requirements.

### NOT_QUALIFIED

The user does not currently meet a material requirement.

### MONITORING

The Opportunity is relevant but not ready for immediate pursuit.

### READY_TO_PURSUE

The Opportunity is sufficiently evaluated and ready for an Application or other action.

### EXPIRED

The Opportunity is no longer available.

### WITHDRAWN

The user intentionally stopped considering the Opportunity.

### ARCHIVED

The Opportunity is retained for historical reference.

## AI transition suggestions

Career OS may suggest:

* `DISCOVERED → RESEARCHING` when sufficient source data is available.
* `RESEARCHING → QUALIFIED` when eligibility is supported by Evidence.
* `RESEARCHING → NOT_QUALIFIED` when a material requirement is unmet.
* `INTERESTED → READY_TO_PURSUE` when fit, timing, and Goal Alignment are strong.
* `ACTIVE → EXPIRED` when an authoritative deadline passes.

---

# 4. Application Lifecycle

## States

```text
PLANNED
PREPARING
READY_TO_SUBMIT
SUBMITTED
CONFIRMED
ASSESSMENT
INTERVIEW
FINAL_ROUND
OFFER
ACCEPTED
DECLINED
REJECTED
WITHDRAWN
EXPIRED
COMPLETED
ARCHIVED
```

## Standard path

```text
PLANNED
→ PREPARING
→ READY_TO_SUBMIT
→ SUBMITTED
→ CONFIRMED
→ ASSESSMENT
→ INTERVIEW
→ FINAL_ROUND
→ OFFER
→ ACCEPTED
→ COMPLETED
→ ARCHIVED
```

## Alternative paths

```text
SUBMITTED → REJECTED
CONFIRMED → REJECTED
ASSESSMENT → REJECTED
INTERVIEW → REJECTED
FINAL_ROUND → REJECTED
OFFER → DECLINED
ANY ACTIVE STATE → WITHDRAWN
PLANNED → EXPIRED
PREPARING → EXPIRED
READY_TO_SUBMIT → EXPIRED
```

## State meanings

### PLANNED

The user intends to apply.

### PREPARING

Materials or research are being prepared.

### READY_TO_SUBMIT

Required materials are complete and validated.

### SUBMITTED

The Application has been sent.

### CONFIRMED

Submission has been acknowledged.

### ASSESSMENT

A test, case, HireVue, coding exercise, or other evaluation is active.

### INTERVIEW

At least one formal interview is scheduled or underway.

### FINAL_ROUND

The Application has reached the final evaluation stage.

### OFFER

A formal or verified offer has been received.

### ACCEPTED

The user accepted the offer.

### DECLINED

The user declined the offer.

### REJECTED

The Organization ended the candidacy.

### WITHDRAWN

The user ended the candidacy.

### EXPIRED

The deadline passed before submission or required action.

### COMPLETED

The resulting program, job, internship, or experience has concluded.

### ARCHIVED

The Application remains available for analytics and reference.

## Validation rules

* `SUBMITTED` requires `submitted_at`.
* `CONFIRMED` should reference confirmation Evidence where available.
* `ASSESSMENT` should link to an Assessment, Task, Email, or deadline.
* `INTERVIEW` should link to an Interview or Calendar Event.
* `OFFER` requires verified communication or user confirmation.
* `ACCEPTED` and `DECLINED` require an explicit user action.
* `REJECTED` may be detected by AI but requires confirmation before updating automatically.

## Exceptional transitions

Examples:

* `SUBMITTED → INTERVIEW` when no confirmation stage is recorded.
* `INTERVIEW → OFFER` when no final round exists.
* `REJECTED → INTERVIEW` when an Organization reopens the process.
* `WITHDRAWN → ACTIVE STATE` when the user re-enters the process.

Each requires an override reason.

---

# 5. Project Lifecycle

## States

```text
IDEA
PROPOSED
PLANNED
ACTIVE
PAUSED
BLOCKED
AT_RISK
IN_REVIEW
COMPLETED
CANCELLED
ARCHIVED
```

## Standard path

```text
IDEA
→ PROPOSED
→ PLANNED
→ ACTIVE
→ IN_REVIEW
→ COMPLETED
→ ARCHIVED
```

## Alternative transitions

```text
ACTIVE → PAUSED
ACTIVE → BLOCKED
ACTIVE → AT_RISK
PAUSED → ACTIVE
BLOCKED → ACTIVE
AT_RISK → ACTIVE
IN_REVIEW → ACTIVE
ANY NON-COMPLETED STATE → CANCELLED
```

## State meanings

### IDEA

An undeveloped concept.

### PROPOSED

The Project has a preliminary mission and expected value.

### PLANNED

Scope, outcomes, and initial milestones are defined.

### ACTIVE

Work is currently underway.

### PAUSED

Work is intentionally suspended.

### BLOCKED

Progress cannot continue due to a dependency.

### AT_RISK

Completion or expected value is materially threatened.

### IN_REVIEW

Deliverables or outcomes are being evaluated.

### COMPLETED

Success criteria have been met or formally closed.

### CANCELLED

The Project was intentionally ended before completion.

### ARCHIVED

The Project remains available as historical knowledge and portfolio Evidence.

## Validation rules

* `PLANNED` requires a mission and expected outcomes.
* `ACTIVE` should have at least one milestone, deliverable, or current Task.
* `BLOCKED` requires a blocker.
* `AT_RISK` requires at least one Risk or explanation.
* `COMPLETED` requires a completion date and outcome summary.
* A completed Project may still receive later updates, reflections, or portfolio artifacts.

---

# 6. Goal Lifecycle

## States

```text
DRAFT
ACTIVE
ON_TRACK
AT_RISK
BLOCKED
DEFERRED
ACHIEVED
PARTIALLY_ACHIEVED
ABANDONED
ARCHIVED
```

## Standard path

```text
DRAFT
→ ACTIVE
→ ON_TRACK
→ ACHIEVED
→ ARCHIVED
```

## Alternative transitions

```text
ACTIVE → AT_RISK
ACTIVE → BLOCKED
ACTIVE → DEFERRED
AT_RISK → ON_TRACK
BLOCKED → ACTIVE
DEFERRED → ACTIVE
ANY ACTIVE STATE → PARTIALLY_ACHIEVED
ANY NON-TERMINAL STATE → ABANDONED
```

## State meanings

### DRAFT

The Goal is not yet fully defined.

### ACTIVE

The Goal is accepted and being pursued.

### ON_TRACK

Current progress supports the target outcome and timing.

### AT_RISK

The Goal may not be achieved without corrective action.

### BLOCKED

A material dependency prevents progress.

### DEFERRED

The Goal remains valid but is intentionally postponed.

### ACHIEVED

The success criteria have been met.

### PARTIALLY_ACHIEVED

Some but not all success criteria were met.

### ABANDONED

The user intentionally stopped pursuing the Goal.

### ARCHIVED

The Goal remains available for history and reflection.

## Validation rules

* `ACTIVE` requires success criteria.
* `ON_TRACK` and `AT_RISK` may be AI-inferred but must be explainable.
* `ACHIEVED` requires verified success criteria or explicit user confirmation.
* `ABANDONED` should preserve the reason.
* Goal status must not be inferred solely from Task completion.

---

# 7. Decision Lifecycle

## States

```text
IDENTIFIED
FRAMING
GATHERING_EVIDENCE
EVALUATING_OPTIONS
READY_TO_DECIDE
DECIDED
IMPLEMENTING
OUTCOME_PENDING
REVIEWED
REOPENED
ABANDONED
ARCHIVED
```

## Standard path

```text
IDENTIFIED
→ FRAMING
→ GATHERING_EVIDENCE
→ EVALUATING_OPTIONS
→ READY_TO_DECIDE
→ DECIDED
→ IMPLEMENTING
→ OUTCOME_PENDING
→ REVIEWED
→ ARCHIVED
```

## Alternative transitions

```text
DECIDED → REOPENED
OUTCOME_PENDING → REOPENED
ANY PRE-DECISION STATE → ABANDONED
REOPENED → GATHERING_EVIDENCE
REOPENED → EVALUATING_OPTIONS
```

## Validation rules

* `FRAMING` requires a clear Decision question.
* `EVALUATING_OPTIONS` requires at least two options unless the Decision is act-versus-do-not-act.
* `READY_TO_DECIDE` should identify missing Evidence and assumptions.
* `DECIDED` requires a final choice or explicit decision not to act.
* `REVIEWED` requires an outcome or reflection.
* AI Recommendations remain separate from the user's Decision.

---

# 8. Relationship Lifecycle

## States

```text
IDENTIFIED
PROSPECTIVE
CONTACTED
ESTABLISHED
ACTIVE
DEVELOPING
STRONG
DORMANT
NEEDS_ATTENTION
ENDED
ARCHIVED
```

## Standard path

```text
IDENTIFIED
→ PROSPECTIVE
→ CONTACTED
→ ESTABLISHED
→ ACTIVE
→ DEVELOPING
→ STRONG
```

## Alternative transitions

```text
ACTIVE → DORMANT
DEVELOPING → DORMANT
STRONG → DORMANT
DORMANT → ACTIVE
ANY ACTIVE STATE → NEEDS_ATTENTION
NEEDS_ATTENTION → ACTIVE
ANY STATE → ENDED
ENDED → ARCHIVED
```

## State meanings

### IDENTIFIED

A relevant Person has been added to the graph.

### PROSPECTIVE

The user may want to establish contact.

### CONTACTED

Initial outreach has occurred.

### ESTABLISHED

A verified two-way professional interaction exists.

### ACTIVE

The relationship currently has meaningful engagement.

### DEVELOPING

The relationship is strengthening through repeated engagement or collaboration.

### STRONG

The relationship has substantial history, trust, relevance, or reciprocity.

### DORMANT

No meaningful engagement has occurred within the expected cadence.

### NEEDS_ATTENTION

The system or user identifies a reason to re-engage.

### ENDED

The relationship is no longer active or appropriate to pursue.

### ARCHIVED

The relationship remains available for history.

## Validation rules

* Relationship strength should not be inferred solely from message frequency.
* `STRONG` should not be assigned automatically without sufficient Evidence.
* `DORMANT` depends on expected cadence and context.
* A user may override all AI-generated relationship states.

---

# 9. Knowledge Item Lifecycle

## States

```text
CAPTURED
DRAFT
STRUCTURED
VERIFIED
ACTIVE
NEEDS_REVIEW
CONTRADICTED
OUTDATED
SUPERSEDED
ARCHIVED
```

## Standard path

```text
CAPTURED
→ DRAFT
→ STRUCTURED
→ VERIFIED
→ ACTIVE
```

## Alternative transitions

```text
ACTIVE → NEEDS_REVIEW
ACTIVE → CONTRADICTED
ACTIVE → OUTDATED
ACTIVE → SUPERSEDED
ANY TERMINAL STATE → ARCHIVED
```

## State meanings

### CAPTURED

Raw information has been recorded.

### DRAFT

The content is incomplete or unrefined.

### STRUCTURED

The content has independent meaning and relationships.

### VERIFIED

Relevant claims have adequate Evidence.

### ACTIVE

The Knowledge Item is available for retrieval and reasoning.

### NEEDS_REVIEW

The item requires user or source verification.

### CONTRADICTED

Available Evidence materially conflicts with the item.

### OUTDATED

The item may no longer be current.

### SUPERSEDED

A newer Knowledge Item replaces it.

### ARCHIVED

The item is retained for historical context.

## Validation rules

* AI-generated Knowledge must be labeled.
* `VERIFIED` requires Evidence or explicit user confirmation.
* `CONTRADICTED` must preserve conflicting Evidence.
* `SUPERSEDED` must link to the replacement item.
* Outdated information should not silently remain active in consequential recommendations.

---

# 10. Document Lifecycle

## States

```text
DRAFT
IN_REVIEW
APPROVED
CURRENT
SUPERSEDED
RETIRED
ARCHIVED
```

## Standard path

```text
DRAFT
→ IN_REVIEW
→ APPROVED
→ CURRENT
→ SUPERSEDED
→ ARCHIVED
```

## Alternative transitions

```text
IN_REVIEW → DRAFT
APPROVED → DRAFT
CURRENT → RETIRED
RETIRED → CURRENT
```

## Validation rules

* Every Document Version has its own lifecycle.
* Only one version should normally be `CURRENT`.
* `SUPERSEDED` must reference the replacement version.
* AI-generated edits create a new Version.
* Sensitive Documents default to private.

---

# 11. Task Lifecycle

## States

```text
CAPTURED
PLANNED
READY
IN_PROGRESS
BLOCKED
WAITING
COMPLETED
CANCELLED
DEFERRED
ARCHIVED
```

## Standard path

```text
CAPTURED
→ PLANNED
→ READY
→ IN_PROGRESS
→ COMPLETED
→ ARCHIVED
```

## Alternative transitions

```text
READY → BLOCKED
IN_PROGRESS → BLOCKED
IN_PROGRESS → WAITING
BLOCKED → READY
WAITING → READY
ANY ACTIVE STATE → DEFERRED
DEFERRED → PLANNED
ANY NON-COMPLETED STATE → CANCELLED
```

## Validation rules

* `READY` means the Task can be executed without an unresolved dependency.
* `BLOCKED` requires a blocker.
* `WAITING` requires an external dependency.
* `COMPLETED` requires `completed_at`.
* Recurring Tasks create new instances rather than reopening completed history where practical.

---

# 12. Time Block Lifecycle

## States

```text
PROPOSED
SCHEDULED
CONFIRMED
IN_PROGRESS
COMPLETED
MISSED
CANCELLED
RESCHEDULED
```

## Validation rules

* AI-created Time Blocks begin as `PROPOSED`.
* External Calendar changes require approval.
* `RESCHEDULED` should link to the replacement Time Block.
* `MISSED` should not automatically imply Task failure.

---

# 13. Evidence Lifecycle

## States

```text
CAPTURED
UNVERIFIED
VERIFIED
DISPUTED
STALE
RETRACTED
ARCHIVED
```

## Validation rules

* `VERIFIED` requires provenance and a verification method.
* Time-sensitive Evidence may become `STALE`.
* `DISPUTED` preserves competing Evidence.
* `RETRACTED` must remain visible for auditability.
* Official sources may still become stale.

---

# 14. Insight Lifecycle

## States

```text
GENERATED
ACTIVE
ACKNOWLEDGED
ACTED_ON
DISMISSED
OUTDATED
CONTRADICTED
SUPERSEDED
EXPIRED
ARCHIVED
```

## Validation rules

* Every Insight must identify supporting inputs.
* An Insight must expire or be recalculated when material inputs change.
* User dismissal should be recorded.
* Contradicted Insights should not remain active.

---

# 15. Recommendation Lifecycle

## States

```text
GENERATED
PRESENTED
ACCEPTED
REJECTED
DEFERRED
IN_PROGRESS
COMPLETED
INEFFECTIVE
EXPIRED
SUPERSEDED
ARCHIVED
```

## Validation rules

* `ACCEPTED` does not authorize external action by itself.
* Rejected Recommendations should not recur without new Evidence.
* Completed Recommendations should track outcomes where possible.
* Expired Recommendations should be removed from active views.

---

# 16. Career Risk Lifecycle

## States

```text
DETECTED
ACTIVE
ACKNOWLEDGED
MITIGATION_PLANNED
MITIGATING
RESOLVED
ACCEPTED
DISMISSED
EXPIRED
ARCHIVED
```

## Validation rules

* Risks require Evidence and assumptions.
* Severe Risks must be actionable.
* `ACCEPTED` means the user knowingly accepts the Risk.
* `RESOLVED` requires a mitigation result or changed conditions.

---

# 17. Daily Mission Lifecycle

## States

```text
GENERATED
REVIEWED
CONFIRMED
ACTIVE
PARTIALLY_COMPLETED
COMPLETED
MISSED
REPLACED
ARCHIVED
```

## Validation rules

* The user may edit the Mission before confirmation.
* A Mission should normally be generated once per day unless manually refreshed.
* Regeneration must preserve the prior version.
* Task completion and Mission completion are related but not identical.

---

# 18. Lifecycle Override Policy

An override is permitted when:

* A real-world process skips stages.
* Imported data arrives out of sequence.
* Historical records are incomplete.
* An Organization reopens a closed process.
* A user corrects an inaccurate system inference.
* A lifecycle definition does not cover a legitimate edge case.

## Required override data

```text
previous_state
new_state
override_reason
initiated_by
initiated_at
evidence_ids
```

## AI treatment

AI may:

* Flag the override.
* Explain why it is unusual.
* Recommend a standard alternative.
* Learn from confirmed recurring exceptions.

AI may not reverse a user override automatically.

---

# 19. Transition Audit Requirements

Each transition event should preserve:

* Object ID.
* Object type.
* Previous state.
* New state.
* Initiator.
* Origin.
* Timestamp.
* Reason.
* Evidence.
* Override indicator.
* Relevant integration source.
* AI model version, when AI-generated.

Transition history should be append-only where practical.

---

# 20. Lifecycle Analytics

Lifecycle histories should support analysis such as:

* Average Application time by stage.
* Interview conversion rate.
* Opportunity-to-Application conversion.
* Project completion and cancellation rates.
* Goal stagnation duration.
* Relationship dormancy patterns.
* Recommendation acceptance and success rates.
* Risk-detection lead time.
* Task completion by planned state.
* Document-version effectiveness.

Analytics must distinguish correlation from causation.

---

# 21. Open Questions

1. Which transitions can integrations perform automatically?
2. Which status changes require explicit confirmation?
3. How long should dormant or stale thresholds be?
4. Should lifecycle rules be user-configurable?
5. How are recurring Tasks and Programs modeled?
6. How should historical imported records with missing states be represented?
7. Which lifecycle changes trigger Notifications?
8. How should bulk transitions work?
9. Which transitions require Evidence?
10. How are ontology and lifecycle migrations versioned?

---

# Next Documents

* `docs/03-architecture/ARCHITECTURE.md`
* `docs/03-architecture/SECURITY.md`
* `docs/04-database/ERD.md`
* `docs/06-ai/AI_ARCHITECTURE.md`
