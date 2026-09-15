import type { SupabaseClient } from "@supabase/supabase-js";
import type { Database } from "@/lib/supabase/database.types";
import { PeopleRepository } from "@/lib/data/repositories";
import type { CreatePersonInput } from "@/lib/data/repositories/persons.repository";
import type { Update } from "@/lib/data/types/database";
import type { WorkflowContext } from "../types/workflow";
import { DomainServiceBase } from "./domain-service.base";

export class PeopleService extends DomainServiceBase {
  private readonly repository: PeopleRepository;

  constructor(db: SupabaseClient<Database>) {
    super(db);
    this.repository = new PeopleRepository(db);
  }

  list(limit?: number) {
    return this.repository.list(limit);
  }

  getById(id: string) {
    return this.repository.getById(id);
  }

  async create(input: CreatePersonInput, context?: WorkflowContext) {
    const record = await this.repository.create(input);
    await this.recordCreated(record.id, "person", context);
    return record;
  }

  async update(
    id: string,
    patch: Update<"persons">,
    options: { title?: string; context?: WorkflowContext } = {},
  ) {
    const domain = await this.repository.update(id, patch);
    if (options.title !== undefined) {
      await this.objects.update(id, { title: options.title });
    }
    await this.recordUpdated(id, "person", options.context);
    return domain;
  }
}
