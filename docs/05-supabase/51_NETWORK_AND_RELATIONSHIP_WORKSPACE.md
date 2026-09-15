# Career OS — Network & Relationship Workspace

**Document ID:** COS-UI-NET-001
**Version:** 1.0.0
**Depends on:** Batches 1–8

## Purpose
Turn people, organizations, relationship intelligence, and communications into an actionable
networking workspace.

## Routes
- `/network`
- `/network/people/[id]`
- `/network/organizations/[id]`

## Read model
The workspace combines:
- `person_relationship_health`;
- People repository records;
- Organization repository records;
- `interactions_communications`.

## Workflow
Relationship health → follow-up queue → contact detail → interaction history → capture communication.

## Commit
`feat(network): add relationship and communications workspace`
