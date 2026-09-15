import type { SupabaseClient } from "@supabase/supabase-js";
import type { Database, Json } from "@/lib/supabase/database.types";
import type { WorkflowContext } from "../types/workflow";
import { WorkflowPartialFailureError } from "../errors/workflow-error";

type DbClient = SupabaseClient<Database>;

export interface RecordActivityInput {
  eventTypeCode:
    | "object_created"
    | "object_updated"
    | "object_archived"
    | "object_deleted"
    | "relationship_created"
    | "relationship_deleted"
    | "status_changed"
    | "note_added"
    | "recommendation_generated"
    | "integration_synced";
  objectId?: string | null;
  relatedObjectId?: string | null;
  context?: WorkflowContext;
  payload?: Record<string, unknown>;
}

export class ActivityLedgerService {
  constructor(private readonly db: DbClient) {}

  async record(input: RecordActivityInput) {
    const { data: auth, error: authError } = await this.db.auth.getUser();
    if (authError) throw authError;
    if (!auth.user) throw new Error("Authenticated user required.");

    const context = input.context ?? {};

    const { data, error } = await this.db
      .from("activity_events")
      .insert({
        owner_user_id: auth.user.id,
        event_type_code: input.eventTypeCode,
        actor_type: context.actorType ?? "user",
        source_type: context.sourceType ?? "web",
        object_id: input.objectId ?? null,
        related_object_id: input.relatedObjectId ?? null,
        correlation_id: context.correlationId ?? null,
        causation_id: context.causationId ?? null,
        payload: {
          ...(context.metadata ?? {}),
          ...(input.payload ?? {}),
        } as Json,
      })
      .select("*")
      .single();

    if (error) throw error;
    return data;
  }

  async recordAfterMutation(
    completedOperation: string,
    input: RecordActivityInput,
  ) {
    try {
      return await this.record(input);
    } catch (cause) {
      throw new WorkflowPartialFailureError(
        `${completedOperation} succeeded, but Activity Ledger recording failed.`,
        completedOperation,
        "record activity event",
        { cause },
      );
    }
  }
}
