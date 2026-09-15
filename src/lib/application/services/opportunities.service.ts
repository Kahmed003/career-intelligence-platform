import type { SupabaseClient } from "@supabase/supabase-js";
import type { Database } from "@/lib/supabase/database.types";
import { OpportunitiesRepository } from "@/lib/data/repositories";
import type { CreateOpportunityInput } from "@/lib/data/repositories/opportunitys.repository";
import type { Update } from "@/lib/data/types/database";
import type { WorkflowContext } from "../types/workflow";
import { DomainServiceBase } from "./domain-service.base";

export class OpportunitiesService extends DomainServiceBase {
  private readonly repository: OpportunitiesRepository;

  constructor(db: SupabaseClient<Database>) {
    super(db);
    this.repository = new OpportunitiesRepository(db);
  }

  list(limit?: number) {
    return this.repository.list(limit);
  }

  getById(id: string) {
    return this.repository.getById(id);
  }

  async create(input: CreateOpportunityInput, context?: WorkflowContext) {
    const record = await this.repository.create(input);
    await this.recordCreated(record.id, "opportunity", context);
    return record;
  }

  async update(
    id: string,
    patch: Update<"opportunitys">,
    options: { title?: string; context?: WorkflowContext } = {},
  ) {
    const domain = await this.repository.update(id, patch);
    if (options.title !== undefined) {
      await this.objects.update(id, { title: options.title });
    }
    await this.recordUpdated(id, "opportunity", options.context);
    return domain;
  }
}
