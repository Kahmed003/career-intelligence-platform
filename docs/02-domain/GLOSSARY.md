# Career OS Domain Glossary

**Document ID:** DOM-002
**Version:** 1.0
**Status:** Draft
**Owner:** Ahmed Kazadi Kabuya
**Last Updated:** 2026-07-12

**Related Documents:**

* `docs/00-vision/MANIFESTO.md`
* `docs/01-product/PRD.md`
* `docs/02-domain/DOMAIN_MODEL.md`
* `docs/02-domain/OBJECTS.md`
* `docs/02-domain/RELATIONSHIPS.md`
* `docs/02-domain/LIFECYCLES.md`

---

## Purpose

This glossary defines the canonical vocabulary used throughout Career OS.

Each term should have one consistent meaning across product requirements, domain modeling, system architecture, database design, APIs, user interfaces, analytics, and AI reasoning.

When another document uses a term defined here, it should preserve the meaning established in this glossary.

---

# A

## Action

A specific activity that the user can perform to advance a task, project, opportunity, decision, relationship, or goal.

Examples:

* Submit an application.
* Read a research paper.
* Reply to a recruiter.
* Schedule a meeting.
* Prepare for an interview.

An Action is usually represented operationally as a Task or Calendar Event.

---

## Activity

A recorded event showing that something happened within Career OS or an integrated external system.

Examples:

* A task was completed.
* An application changed stages.
* A document was uploaded.
* A contact replied to an email.
* A recommendation was accepted.

Activities form part of an object's timeline.

---

## Application

A personal record representing the user's pursuit of a specific Opportunity.

An Opportunity exists independently, while an Application represents the user's interaction with it.

An Application may include:

* Current stage.
* Submission date.
* Deadlines.
* Documents used.
* Assessments.
* Interviews.
* Contacts.
* Communications.
* Outcome.

---

## Asset

A long-term capability, resource, reputation, relationship, or body of work that compounds over time and increases the user's career value.

Examples:

* Programming ability.
* Research profile.
* Professional network.
* Portfolio quality.
* Leadership experience.
* Interview readiness.
* Publication record.

Projects, opportunities, deliberate practice, and relationships can build Assets.

---

## Attachment

A file associated with another object or supporting record.

Examples:

* Resume.
* Cover letter.
* Transcript.
* Research paper.
* Presentation.
* Meeting notes.
* Screenshot.

An Attachment is not automatically treated as a first-class Document unless it has independent significance, metadata, versioning, or reuse.

---

# C

## Career Capital

The combined value of the user's accumulated skills, experience, knowledge, reputation, relationships, achievements, and professional options.

Career Capital is not a single score. It is a conceptual summary of multiple Assets.

---

## Career OS

An AI-powered operating system that helps the user organize professional information, execute daily work, identify opportunities, build relationships, and make better long-term career decisions.

Career OS is the product described by the PRD and domain model.

---

## Career Risk

An intelligence-generated warning that identifies a pattern, omission, dependency, deadline, or decision that could reduce the probability of achieving a Goal.

Examples:

* Too few PhD applications.
* An expiring visa deadline.
* Overreliance on one career path.
* A neglected mentor relationship.
* Missing qualifications for a target role.

---

## Career Trajectory

The evolving path formed by the user's education, work, research, skills, relationships, decisions, and goals over time.

Career OS evaluates opportunities and actions partly by how they may affect this trajectory.

---

## Confidence

A system-generated measure of how strongly available evidence supports an Insight, Score, Recommendation, or inferred relationship.

Confidence should not be presented as certainty.

---

## Contact

A Person for whom the user has communication or identification information.

Every Contact is a Person, but not every Person is necessarily a Contact.

A professor the user intends to approach may exist as a Person before becoming a Contact.

---

## Context Panel

A side panel that displays the details of an object without forcing the user to leave the current page or workflow.

The Context Panel supports quick inspection and editing. A user may open the object as a full page when deeper work is required.

---

# D

## Daily Mission

An intelligence-generated, prioritized set of actions recommended for the current day.

A Daily Mission considers:

* Existing calendar commitments.
* Deadlines.
* Goal impact.
* Long-term value.
* Opportunity cost.
* Required preparation.
* Available time.

It should normally emphasize a small number of high-priority actions rather than display every open Task.

---

## Decision

A first-class personal object representing a meaningful choice that requires consideration of alternatives, evidence, tradeoffs, risks, assumptions, and expected outcomes.

Examples:

* Choosing between internship offers.
* Selecting a graduate program.
* Deciding whether to pursue consulting or research.
* Choosing a project to prioritize.

A Decision may contain:

* Decision question.
* Options.
* Evidence.
* Assumptions.
* Evaluation criteria.
* Recommendation.
* Final choice.
* Outcome.
* Reflection.

---

## Decision Engine

The Career OS intelligence capability that evaluates options using Goals, Evidence, Knowledge, Assets, constraints, risks, timing, and expected impact.

The Decision Engine supports judgment. It does not replace the user's final authority.

---

## Deliverable

A concrete output produced by a Project.

Examples:

* Software application.
* Research paper.
* Presentation.
* Data analysis.
* Report.
* Prototype.
* Portfolio case study.

A Project may produce multiple Deliverables.

---

## Document

A first-class object representing a structured artifact with independent value, metadata, reuse, ownership, and potentially multiple versions.

Examples:

* Resume.
* Cover letter.
* Transcript.
* Research statement.
* Technical report.
* Presentation.
* Portfolio document.

A Document is distinct from an Attachment because it is managed as a reusable object rather than merely stored with another record.

---

# E

## Evidence

A source-backed fact, observation, communication, record, or artifact that can support or challenge Knowledge, an Insight, or a Decision.

Examples:

* Official visa guidance.
* A job description.
* A professor's email.
* A research paper.
* A market trade record.
* An interview result.

Evidence should preserve its source and provenance where possible.

---

## Execution

The process of completing actions that advance Tasks, Projects, Applications, Relationships, Decisions, and Goals.

Execution is one of Career OS's three core layers, alongside Organize and Think.

---

## Expected Impact

The estimated contribution that an action, project, relationship, opportunity, or decision may make toward one or more Goals.

Expected Impact may consider:

* Career value.
* Research value.
* Skill growth.
* Network growth.
* Financial value.
* Visa flexibility.
* Time required.
* Probability of success.
* Opportunity cost.

---

# G

## Goal

A first-class personal object representing a desired future outcome.

Examples:

* Secure a strong internship.
* Obtain a full-time role by summer 2028.
* Enter a fully funded PhD program.
* Become a stronger programmer.
* Build a high-quality project portfolio.

A Goal may contain:

* Target date.
* Success criteria.
* Milestones.
* Supporting Assets.
* Supporting Projects.
* Supporting Opportunities.
* Risks.
* Progress indicators.

---

## Goal Alignment

The degree to which an object or proposed action contributes to a Goal.

Goal Alignment is used by the intelligence layer when prioritizing Opportunities, Projects, Tasks, and Recommendations.

---

## Goal Impact Engine

The intelligence capability that estimates how Projects, Opportunities, Actions, Skills, and Relationships contribute to the user's Goals.

Its outputs should be directional and explainable rather than presented as objectively precise predictions.

---

## Growth

The long-term development of the user's Assets, Skills, experience, relationships, knowledge, reputation, and professional options.

Growth differs from task completion. A user may complete many Tasks without meaningfully increasing long-term Growth.

---

## Growth Analytics

Intelligence-generated analysis showing how the user's Assets, Skills, projects, relationships, and career readiness are changing over time.

---

# I

## Insight

An intelligence-generated interpretation derived from Evidence, Knowledge, relationships, patterns, or user activity.

Examples:

* A research lab strongly matches the user's experience.
* The user has neglected an important relationship.
* A particular skill is repeatedly required by target opportunities.
* The current application strategy is insufficiently diversified.

An Insight should include supporting Evidence and a confidence level.

---

## Intelligence Layer

The Career OS layer containing system-generated outputs such as:

* Insights.
* Recommendations.
* Scores.
* Risks.
* Daily Missions.
* Weekly strategies.
* Skill gaps.
* Relationship health.
* Goal progress.

Intelligence objects are derived from Personal and World data.

---

## Interaction

A supporting record representing meaningful engagement between the user and a Person or Organization.

Examples:

* Email exchange.
* Coffee chat.
* Interview.
* Conference conversation.
* Mentoring session.
* Phone call.

Interactions contribute to relationship history.

---

# K

## Knowledge

Reusable understanding created, recorded, or synthesized by the user from experience, Evidence, reflection, and learning.

Examples:

* A research summary.
* A lesson learned from an interview.
* A networking insight.
* A technical explanation.
* A market observation.
* A professor's advice interpreted in context.

Knowledge is personal and may be linked to multiple objects without duplication.

---

## Knowledge Graph

The network of objects and relationships through which Career OS represents the user's professional world.

The Knowledge Graph connects, among other things:

* People.
* Organizations.
* Opportunities.
* Applications.
* Projects.
* Goals.
* Skills.
* Assets.
* Documents.
* Knowledge.
* Evidence.
* Decisions.

---

## Knowledge Item

An atomic or reusable unit of Knowledge with independent meaning.

A Knowledge Item may be linked to multiple People, Projects, Opportunities, Decisions, and Goals.

---

# L

## Lifecycle

The approved set of states through which an object or supporting record may move over time.

Examples:

* Opportunity lifecycle.
* Application lifecycle.
* Project lifecycle.
* Goal lifecycle.
* Relationship lifecycle.

Lifecycles are defined in `LIFECYCLES.md`.

---

## Long-Term Value

The expected contribution of an action or object to the user's future Assets, Goals, options, and Career Capital.

Long-Term Value may conflict with immediate urgency and therefore forms part of balanced prioritization.

---

# M

## Mission Control

The primary Career OS dashboard.

Mission Control answers:

1. What should I do today?
2. What deserves my attention?
3. Which opportunities should I not miss?
4. Which decisions need attention?
5. How am I progressing toward long-term Goals?

Mission Control integrates organization, intelligence, and execution.

---

## Milestone

A measurable intermediate outcome indicating progress toward a Goal or Project.

Examples:

* Complete a project prototype.
* Submit five PhD applications.
* Present research at a conference.
* Reach a defined programming competency.

---

# N

## Note

A user-created written record.

A Note may be temporary, unstructured, or attached to another object. When the information becomes reusable and independently meaningful, it may be converted into a Knowledge Item.

---

## Notification

A supporting system record that communicates an update, deadline, risk, opportunity, recommendation, or required action to the user.

Notifications should be prioritized to prevent excessive interruption.

---

# O

## Object

A meaningful entity represented inside Career OS.

Objects may be:

* First-class objects.
* Supporting records.
* Personal objects.
* World objects.
* Intelligence objects.

Objects are defined in `OBJECTS.md`.

---

## Opportunity

A first-class World object representing an external position, program, event, relationship, resource, or opening capable of advancing one or more Goals.

Examples:

* Internship.
* Full-time role.
* Funded PhD position.
* Fellowship.
* Scholarship.
* Conference.
* Research assistantship.
* Competition.
* Professional introduction.

---

## Opportunity Cost

The value of the best alternative that must be delayed, reduced, or abandoned when one action or opportunity is chosen over another.

---

## Opportunity Radar

The intelligence capability that discovers, monitors, filters, and prioritizes relevant external Opportunities.

It should prioritize fit and Goal Alignment rather than simply maximizing the number of results.

---

## Opportunity Score

An intelligence-generated assessment of an Opportunity's relevance and potential value.

Possible factors include:

* Goal Alignment.
* Eligibility.
* Skill fit.
* Research fit.
* Network proximity.
* Visa compatibility.
* Timing.
* Probability of success.
* Expected long-term value.

---

## Organization

A first-class World object representing an institution, company, university, laboratory, government agency, nonprofit organization, investment firm, or professional group.

---

## Organize

The Career OS capability responsible for storing, structuring, connecting, retrieving, and presenting information.

Organize is one of the product's three core layers, alongside Think and Execute.

---

# P

## Personal Layer

The object layer containing information unique to the user.

Examples:

* Goals.
* Decisions.
* Applications.
* Projects.
* Knowledge.
* Tasks.
* Documents.
* Time Blocks.
* Journal records.

---

## Person

A first-class World object representing an individual who could influence, or be influenced by, the user's professional journey.

The user does not need to have interacted with the Person for the object to exist.

---

## Priority

The relative importance assigned to a Task, Opportunity, Decision, Project, or Goal.

Priority may be user-defined, intelligence-generated, or a combination of both.

---

## Project

A first-class personal object representing a deliberate investment of time, knowledge, and effort intended to create long-term career value while producing one or more measurable Deliverables.

A Project should normally support one or more Goals and build one or more Assets or Skills.

---

## Provenance

Information identifying where Evidence, Knowledge, data, or an inference originated.

Examples:

* Email thread.
* Official website.
* Research paper.
* Calendar event.
* Manual entry.
* AI inference.

---

# R

## Recommendation

An intelligence-generated proposal for an action, prioritization, decision, or strategy.

A Recommendation should include:

* Recommended action.
* Reasoning.
* Supporting Evidence.
* Assumptions.
* Confidence.
* Expected impact.
* Tradeoffs.
* Relevant Goals.

---

## Relationship

A structured supporting object representing the professional connection between the user and a Person, or between relevant People where appropriate.

A Relationship may contain:

* Relationship type.
* Interaction history.
* Shared interests.
* Introductions.
* Last contact.
* Suggested follow-up.
* Relationship health.

Relationships do not normally appear as separate top-level pages.

---

## Relationship Health

An intelligence-generated assessment of the strength, recency, reciprocity, relevance, and development of a Relationship.

It should not be treated as a definitive measure of human trust or personal value.

---

## Reminder

A supporting record that prompts the user to take an action at or before a specified time.

---

## Research Profile

The combined evidence of the user's research experience, interests, methods, publications, presentations, collaborators, technical skills, and scholarly trajectory.

Research Profile is an Asset.

---

# S

## Score

A structured intelligence output that summarizes an evaluation.

Examples:

* Opportunity Score.
* Relationship Health.
* Goal readiness.
* Skill fit.

Every Score should be explainable and should expose the major factors influencing it.

---

## Skill

A first-class object representing a capability that can be learned, practiced, demonstrated, assessed, required, or improved.

Examples:

* Python.
* MATLAB.
* Financial modeling.
* Optical spectroscopy.
* Public speaking.
* Interviewing.

---

## Skill Gap

An intelligence-generated difference between the user's current demonstrated Skills and the Skills required for a Goal, Project, Opportunity, or desired role.

---

## Status

The current state of an object within its approved Lifecycle.

---

## Strategic Partner

The intended role of embedded Career OS AI.

The Strategic Partner:

* Identifies opportunities and risks.
* Connects context.
* Recommends priorities.
* Supports decisions.
* Explains reasoning.
* Preserves user agency.
* Requires approval before changing external systems or communicating externally.

---

## Supporting Record

A lower-level record used to support first-class objects and daily execution.

Examples:

* Task.
* Email.
* Calendar Event.
* Interaction.
* Reminder.
* Notification.
* Attachment.
* Activity.

Supporting records may still contain history, relationships, and intelligence, but they do not receive the full top-level object experience.

---

# T

## Tag

A user-defined or system-generated label used to categorize objects and improve filtering, search, and discovery.

Tags should not replace formal object types or relationships.

---

## Task

A supporting personal record representing a specific unit of work that can be completed.

A Task may connect to:

* Goal.
* Project.
* Opportunity.
* Application.
* Person.
* Decision.
* Document.
* Calendar Event.

---

## Think

The Career OS capability responsible for analysis, prioritization, recommendations, decision support, and strategic reasoning.

Think is one of the product's three core layers, alongside Organize and Execute.

---

## Time Block

A scheduled period reserved for a specific Task, Project, Goal, preparation activity, or category of work.

Time Blocks connect intended work to the calendar.

---

## Timeline

A chronological record of meaningful Activities, changes, Interactions, decisions, and events connected to an object.

---

## Tradeoff

A situation in which improving one outcome requires sacrificing or delaying another.

Career OS should surface tradeoffs explicitly instead of hiding them inside a Recommendation or Score.

---

# U

## User Agency

The principle that the user retains authority over decisions and external actions.

Career OS may analyze, draft, schedule, or recommend, but it should not send communications, submit applications, execute trades, or make consequential external changes without explicit authorization.

---

# V

## Version

A recorded iteration of a Document, Knowledge Item, decision analysis, or other version-controlled object.

---

## Visa Pathway

A World object representing an immigration or work-authorization route relevant to study, employment, or long-term residence.

Examples:

* F-1 OPT.
* STEM OPT.
* H-1B.
* EU Blue Card.
* Post-study work permit.

Visa Pathways require authoritative Evidence and regular verification.

---

# W

## Weekly Strategy

An intelligence-generated plan that identifies the user's highest-value priorities, risks, deadlines, and growth investments for the coming week.

---

## World Layer

The object layer containing entities that exist independently of the user.

Examples:

* People.
* Organizations.
* Opportunities.
* Research papers.
* Conferences.
* Universities.
* Countries.
* Visa Pathways.

---

# Canonical Distinctions

## Opportunity vs. Application

An Opportunity is the external opening.

An Application is the user's pursuit of that opening.

---

## Person vs. Contact

A Person may exist in the graph without communication details or prior interaction.

A Contact is a Person with known communication information or an active communication context.

---

## Note vs. Knowledge

A Note is a written record.

Knowledge is reusable understanding with independent meaning and relationships.

---

## Evidence vs. Knowledge

Evidence is source-backed information.

Knowledge is the user's understanding derived from Evidence, experience, or reflection.

---

## Knowledge vs. Insight

Knowledge belongs to the user.

An Insight is generated by Career OS through analysis of Knowledge, Evidence, and relationships.

---

## Skill vs. Asset

A Skill is a specific capability.

An Asset is a broader form of career capital that may contain or depend on multiple Skills.

For example, Programming Ability is an Asset supported by Skills such as Python, TypeScript, SQL, testing, and system design.

---

## Project vs. Task

A Project is a strategic investment that creates long-term value and Deliverables.

A Task is one unit of work that helps advance a Project or another object.

---

## Goal vs. Project

A Goal describes a desired future outcome.

A Project is one structured vehicle for progressing toward that outcome.

---

## Document vs. Attachment

A Document is independently managed, reusable, and potentially versioned.

An Attachment is a file associated with another object and may not need independent management.

---

## Insight vs. Recommendation

An Insight explains what the system has inferred.

A Recommendation proposes what the user should consider doing.

---

## Reminder vs. Notification

A Reminder is scheduled around a specific time or action.

A Notification communicates a broader change, event, risk, or update.

---

# Glossary Governance

1. Each canonical term should have one primary definition.
2. New terms should be added only when they represent a distinct concept.
3. Synonyms should point to the canonical term rather than receive duplicate definitions.
4. Product, engineering, database, API, and AI documents should use the terminology in this glossary.
5. Changes that alter the meaning of a core term require review of dependent documents.
6. Significant changes should be recorded in `DOMAIN_DECISIONS.md` or an Architecture Decision Record.

---

# Next Documents

* `docs/02-domain/OBJECTS.md`
* `docs/02-domain/RELATIONSHIPS.md`
* `docs/02-domain/LIFECYCLES.md`
