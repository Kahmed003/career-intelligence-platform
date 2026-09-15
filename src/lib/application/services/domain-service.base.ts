import type { SupabaseClient } from "@supabase/supabase-js";
import type { Database } from "@/lib/supabase/database.types";
import { ObjectsRepository } from "@/lib/data/repositories";
import { ActivityLedgerService } from "./activity-ledger.service";
import type { WorkflowContext } from "../types/workflow";

export abstract class DomainServiceBase {
  protected readonly objects: ObjectsRepository;
  protected readonly activity: ActivityLedgerService;

  constructor(protected readonly db: SupabaseClient<Database>) {
    this.objects = new ObjectsRepository(db);
    this.activity = new ActivityLedgerService(db);
  }

  protected async recordCreated(objectId: string, objectType: string, context?: WorkflowContext) {
    await this.activity.recordAfterMutation(`create ${objectType}`, {
      eventTypeCode: "object_created",
      objectId,
      context,
      payload: { objectType },
    });
  }

  protected async recordUpdated(objectId: string, objectType: string, context?: WorkflowContext) {
    await this.activity.recordAfterMutation(`update ${objectType}`, {
      eventTypeCode: "object_updated",
      objectId,
      context,
      payload: { objectType },
    });
  }
}
