# Career OS — Interaction / Communication Mutation Slice

**Document ID:** COS-APP-COMMS-001
**Version:** 1.0.0
**Depends on:** Batches 1–9

## Purpose
Complete the write path for networking interactions without allowing React components to bypass
application services.

## Flow
Capture form → Server Action → Zod → InteractionCommunicationService → repository → Object Registry
+ interaction domain row → Activity Ledger.

## Supported interaction types
email, linkedin_message, phone_call, video_call, coffee_chat, in_person_meeting,
informational_interview, recruiter_conversation, mentor_meeting, conference_conversation,
career_fair, follow_up, other.

## Important
Creation remains subject to the same cross-table atomicity limitation documented in earlier batches.
A future RPC hardening batch should make Object Registry + domain insert + ledger write one database
transaction.

## Commit
`feat(network): add validated communication mutation workflow`
