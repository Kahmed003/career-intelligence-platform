import { BaseRepository } from "./base";
import { ObjectsRepository } from "./objects.repository";
import type { Insert, Update } from "@/lib/data/types/database";

export type CreateProjectInput = {
  title: string;
  object?: Partial<Omit<Insert<"objects">, "id" | "owner_user_id" | "object_type" | "title">>;
  project: Omit<Insert<"projects">, "id" | "created_at" | "updated_at">;
};

export class ProjectsRepository extends BaseRepository {
  private objects = new ObjectsRepository(this.db);

  async list(limit = 100) {
    const { data, error } = await this.db
      .from("objects")
      .select("*, projects(*)")
      .eq("object_type", "project")
      .is("deleted_at", null)
      .order("updated_at", { ascending: false })
      .limit(limit);
    if (error) this.fail(error, "list projects");
    return data;
  }

  async getById(id: string) {
    const { data, error } = await this.db
      .from("objects")
      .select("*, projects(*)")
      .eq("id", id)
      .eq("object_type", "project")
      .is("deleted_at", null)
      .maybeSingle();
    if (error) this.fail(error, "get projects");
    return data;
  }

  async create(input: CreateProjectInput) {
    const object = await this.objects.create({
      ...input.object,
      object_type: "project",
      title: input.title,
    } as never);

    const { data, error } = await this.db
      .from("projects")
      .insert({ ...input.project, id: object.id } as Insert<"projects">)
      .select("*").single();

    if (error) {
      await this.objects.cleanupFailedCreate(object.id);
      this.fail(error, "create projects");
    }
    return { ...object, project: data };
  }

  async update(id: string, patch: Update<"projects">) {
    const { data, error } = await this.db
      .from("projects").update(patch).eq("id", id).select("*").single();
    if (error) this.fail(error, "update projects");
    return data;
  }
}
