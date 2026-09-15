import type { SupabaseClient } from "@supabase/supabase-js";
import type { Database } from "@/lib/supabase/database.types";
import { OrganizationsRepository } from "@/lib/data/repositories";
import type { CreateOrganizationInput } from "@/lib/data/repositories/organizations.repository";
import type { Update } from "@/lib/data/types/database";
import type { WorkflowContext } from "../types/workflow";
import { DomainServiceBase } from "./domain-service.base";

export class OrganizationsService extends DomainServiceBase {
  private readonly repository: OrganizationsRepository;

  constructor(db: SupabaseClient<Database>) {
    super(db);
    this.repository = new OrganizationsRepository(db);
  }

  list(limit?: number) {
    return this.repository.list(limit);
  }

  getById(id: string) {
    return this.repository.getById(id);
  }

  async create(input: CreateOrganizationInput, context?: WorkflowContext) {
    const record = await this.repository.create(input);
    await this.recordCreated(record.id, "organization", context);
    return record;
  }

  async update(
    id: string,
    patch: Update<"organizations">,
    options: { title?: string; context?: WorkflowContext } = {},
  ) {
    const domain = await this.repository.update(id, patch);
    if (options.title !== undefined) {
      await this.objects.update(id, { title: options.title });
    }
    await this.recordUpdated(id, "organization", options.context);
    return domain;
  }
}
