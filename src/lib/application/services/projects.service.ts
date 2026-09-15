import type { SupabaseClient } from "@supabase/supabase-js";
import type { Database } from "@/lib/supabase/database.types";
import { ProjectsRepository } from "@/lib/data/repositories";
import type { CreateProjectInput } from "@/lib/data/repositories/projects.repository";
import type { Update } from "@/lib/data/types/database";
import type { WorkflowContext } from "../types/workflow";
import { DomainServiceBase } from "./domain-service.base";

export class ProjectsService extends DomainServiceBase {
  private readonly repository: ProjectsRepository;

  constructor(db: SupabaseClient<Database>) {
    super(db);
    this.repository = new ProjectsRepository(db);
  }

  list(limit?: number) {
    return this.repository.list(limit);
  }

  getById(id: string) {
    return this.repository.getById(id);
  }

  async create(input: CreateProjectInput, context?: WorkflowContext) {
    const record = await this.repository.create(input);
    await this.recordCreated(record.id, "project", context);
    return record;
  }

  async update(
    id: string,
    patch: Update<"projects">,
    options: { title?: string; context?: WorkflowContext } = {},
  ) {
    const domain = await this.repository.update(id, patch);
    if (options.title !== undefined) {
      await this.objects.update(id, { title: options.title });
    }
    await this.recordUpdated(id, "project", options.context);
    return domain;
  }
}
