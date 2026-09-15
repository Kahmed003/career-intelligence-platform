import type { SupabaseClient } from "@supabase/supabase-js";
import type { Database } from "@/lib/supabase/database.types";
import { TasksRepository } from "@/lib/data/repositories";
import type { CreateTaskInput } from "@/lib/data/repositories/tasks.repository";
import type { Update } from "@/lib/data/types/database";
import type { WorkflowContext } from "../types/workflow";
import { DomainServiceBase } from "./domain-service.base";

export class TasksService extends DomainServiceBase {
  private readonly repository: TasksRepository;

  constructor(db: SupabaseClient<Database>) {
    super(db);
    this.repository = new TasksRepository(db);
  }

  list(limit?: number) {
    return this.repository.list(limit);
  }

  getById(id: string) {
    return this.repository.getById(id);
  }

  async create(input: CreateTaskInput, context?: WorkflowContext) {
    const record = await this.repository.create(input);
    await this.recordCreated(record.id, "task", context);
    return record;
  }

  async update(
    id: string,
    patch: Update<"tasks">,
    options: { title?: string; context?: WorkflowContext } = {},
  ) {
    const domain = await this.repository.update(id, patch);
    if (options.title !== undefined) {
      await this.objects.update(id, { title: options.title });
    }
    await this.recordUpdated(id, "task", options.context);
    return domain;
  }
}
