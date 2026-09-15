import { BaseRepository } from "./base";
import { ObjectsRepository } from "./objects.repository";
import type { Insert, Update } from "@/lib/data/types/database";

export type CreateApplicationInput = {
  title: string;
  object?: Partial<Omit<Insert<"objects">, "id" | "owner_user_id" | "object_type" | "title">>;
  application: Omit<Insert<"applications">, "id" | "created_at" | "updated_at">;
};

export class ApplicationsRepository extends BaseRepository {
  private objects = new ObjectsRepository(this.db);

  async list(limit = 100) {
    const { data, error } = await this.db
      .from("objects")
      .select("*, applications(*)")
      .eq("object_type", "application")
      .is("deleted_at", null)
      .order("updated_at", { ascending: false })
      .limit(limit);
    if (error) this.fail(error, "list applications");
    return data;
  }

  async getById(id: string) {
    const { data, error } = await this.db
      .from("objects")
      .select("*, applications(*)")
      .eq("id", id)
      .eq("object_type", "application")
      .is("deleted_at", null)
      .maybeSingle();
    if (error) this.fail(error, "get applications");
    return data;
  }

  async create(input: CreateApplicationInput) {
    const object = await this.objects.create({
      ...input.object,
      object_type: "application",
      title: input.title,
    } as never);

    const { data, error } = await this.db
      .from("applications")
      .insert({ ...input.application, id: object.id } as Insert<"applications">)
      .select("*").single();

    if (error) {
      await this.objects.cleanupFailedCreate(object.id);
      this.fail(error, "create applications");
    }
    return { ...object, application: data };
  }

  async update(id: string, patch: Update<"applications">) {
    const { data, error } = await this.db
      .from("applications").update(patch).eq("id", id).select("*").single();
    if (error) this.fail(error, "update applications");
    return data;
  }
}
