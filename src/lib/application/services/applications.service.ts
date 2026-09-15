import type { SupabaseClient } from "@supabase/supabase-js";
import type { Database } from "@/lib/supabase/database.types";
import { ApplicationsRepository } from "@/lib/data/repositories";
import type { CreateApplicationInput } from "@/lib/data/repositories/applications.repository";
import type { Update } from "@/lib/data/types/database";
import type { WorkflowContext } from "../types/workflow";
import { DomainServiceBase } from "./domain-service.base";

export type ApplicationStatus =
  | "draft"
  | "preparing"
  | "submitted"
  | "assessment"
  | "interviewing"
  | "offer"
  | "accepted"
  | "rejected"
  | "withdrawn"
  | "closed";

export class ApplicationsService extends DomainServiceBase {
  private readonly repository: ApplicationsRepository;

  constructor(db: SupabaseClient<Database>) {
    super(db);
    this.repository = new ApplicationsRepository(db);
  }

  list(limit?: number) {
    return this.repository.list(limit);
  }

  getById(id: string) {
    return this.repository.getById(id);
  }

  async create(input: CreateApplicationInput, context?: WorkflowContext) {
    const record = await this.repository.create(input);
    await this.recordCreated(record.id, "application", context);
    return record;
  }

  async update(
    id: string,
    patch: Update<"applications">,
    options: { title?: string; context?: WorkflowContext } = {},
  ) {
    const domain = await this.repository.update(id, patch);

    if (options.title !== undefined) {
      await this.objects.update(id, { title: options.title });
    }

    await this.recordUpdated(id, "application", options.context);
    return domain;
  }

  async transitionStatus(
    id: string,
    status: ApplicationStatus,
    options: {
      outcome?: Update<"applications">["outcome"];
      context?: WorkflowContext;
    } = {},
  ) {
    const current = await this.repository.getById(id);
    if (!current?.applications) throw new Error(`Application ${id} not found.`);

    const now = new Date().toISOString();
    const patch: Update<"applications"> = { status };

    if (status === "submitted" && !current.applications.submitted_at) {
      patch.submitted_at = now;
    }

    if (status === "withdrawn") {
      patch.withdrawn_at = now;
      patch.decision_at = current.applications.decision_at ?? now;
      patch.outcome = options.outcome ?? "withdrawn";
    }

    if (["offer", "accepted", "rejected", "closed"].includes(status)) {
      patch.decision_at = current.applications.decision_at ?? now;
      if (options.outcome !== undefined) patch.outcome = options.outcome;
    }

    const updated = await this.repository.update(id, patch);

    await this.activity.recordAfterMutation("transition application status", {
      eventTypeCode: "status_changed",
      objectId: id,
      context: options.context,
      payload: {
        objectType: "application",
        fromStatus: current.applications.status,
        toStatus: status,
        outcome: updated.outcome,
      },
    });

    return updated;
  }
}
