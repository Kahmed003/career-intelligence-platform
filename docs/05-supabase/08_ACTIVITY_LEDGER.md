Document ID: COS-SUP-ACT-001Version: 1.0.0Status: Approved for implementationCanonical path: docs/05-supabase/08_ACTIVITY_LEDGER.mdRelated migration: supabase/migrations/20260721000600_create_activity_ledger.sql

1. Purpose

The Activity Ledger records meaningful events across Career OS.

It supports:

user-facing timelines;

auditability;

historical reconstruction;

AI context assembly;

analytics;

notification generation;

integration provenance.

2. Architecture

Career OS uses a Hybrid Activity Ledger.

The shared ledger stores cross-domain event facts, while specialized domain tablesremain responsible for current state. The ledger is append-oriented and shouldnot be treated as the sole source of operational state.

3. Tables

public.activity_event_types

Defines governed event codes.

public.activity_events

Stores immutable activity records linked to users and objects.

4. Core Fields

id

owner_user_id

event_type_code

actor_type

actor_user_id

primary_object_id

secondary_object_id

occurred_at

recorded_at

source_system

correlation_id

causation_id

payload

metadata

5. Initial Event Types

object_created

object_updated

object_archived

object_deleted

relationship_created

relationship_deleted

status_changed

note_added

recommendation_generated

integration_synced

6. Integrity Rules

Event type must exist and be active.

Owner must own linked objects under the initial authorization model.

User actors require actor_user_id.

Non-user actors may omit actor_user_id.

Payload and metadata must be JSON objects.

occurred_at cannot be unreasonably later than recorded_at.

Activity rows are immutable after insertion.

Physical deletion is prohibited for authenticated users.

7. Security

Authenticated users may read and insert only activity events they own.

Authenticated users cannot update or delete activity events.

Privileged system processes may insert events through the service role.

8. Recommended Commit Message

feat(database): create append-only activity ledger

9. Root README Addition

- [Activity Ledger](docs/05-supabase/08_ACTIVITY_LEDGER.md) — append-oriented event history for timelines, auditability, analytics, and AI context.
