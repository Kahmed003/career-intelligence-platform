import { BaseRepository } from "./base";
import { ObjectsRepository } from "./objects.repository";
import type { Insert, Update } from "@/lib/data/types/database";

export type CreateTaskInput = {
  title: string;
  object?: Partial<Omit<Insert<"objects">, "id" | "owner_user_id" | "object_type" | "title">>;
  task: Omit<Insert<"tasks">, "id" | "created_at" | "updated_at">;
};

export class TasksRepository extends BaseRepository {
  private objects = new ObjectsRepository(this.db);

  async list(limit = 100) {
    const { data, error } = await this.db
      .from("objects")
      .select("*, tasks(*)")
      .eq("object_type", "task")
      .is("deleted_at", null)
      .order("updated_at", { ascending: false })
      .limit(limit);
    if (error) this.fail(error, "list tasks");
    return data;
  }

  async getById(id: string) {
    const { data, error } = await this.db
      .from("objects")
      .select("*, tasks(*)")
      .eq("id", id)
      .eq("object_type", "task")
      .is("deleted_at", null)
      .maybeSingle();
    if (error) this.fail(error, "get tasks");
    return data;
  }

  async create(input: CreateTaskInput) {
    const object = await this.objects.create({
      ...input.object,
      object_type: "task",
      title: input.title,
    } as never);

    const { data, error } = await this.db
      .from("tasks")
      .insert({ ...input.task, id: object.id } as Insert<"tasks">)
      .select("*").single();

    if (error) {
      await this.objects.cleanupFailedCreate(object.id);
      this.fail(error, "create tasks");
    }
    return { ...object, task: data };
  }

  async update(id: string, patch: Update<"tasks">) {
    const { data, error } = await this.db
      .from("tasks").update(patch).eq("id", id).select("*").single();
    if (error) this.fail(error, "update tasks");
    return data;
  }
}
