import { BaseRepository } from "./base";
import { ObjectsRepository } from "./objects.repository";
import type { Insert, Update } from "@/lib/data/types/database";

export type CreatePersonInput = {
  title: string;
  object?: Partial<Omit<Insert<"objects">, "id" | "owner_user_id" | "object_type" | "title">>;
  person: Omit<Insert<"people">, "id" | "created_at" | "updated_at">;
};

export class PersonsRepository extends BaseRepository {
  private objects = new ObjectsRepository(this.db);

  async list(limit = 100) {
    const { data, error } = await this.db
      .from("objects")
      .select("*, people(*)")
      .eq("object_type", "person")
      .is("deleted_at", null)
      .order("updated_at", { ascending: false })
      .limit(limit);
    if (error) this.fail(error, "list people");
    return data;
  }

  async getById(id: string) {
    const { data, error } = await this.db
      .from("objects")
      .select("*, people(*)")
      .eq("id", id)
      .eq("object_type", "person")
      .is("deleted_at", null)
      .maybeSingle();
    if (error) this.fail(error, "get people");
    return data;
  }

  async create(input: CreatePersonInput) {
    const object = await this.objects.create({
      ...input.object,
      object_type: "person",
      title: input.title,
    } as never);

    const { data, error } = await this.db
      .from("people")
      .insert({ ...input.person, id: object.id } as Insert<"people">)
      .select("*").single();

    if (error) {
      await this.objects.cleanupFailedCreate(object.id);
      this.fail(error, "create people");
    }
    return { ...object, person: data };
  }

  async update(id: string, patch: Update<"people">) {
    const { data, error } = await this.db
      .from("people").update(patch).eq("id", id).select("*").single();
    if (error) this.fail(error, "update people");
    return data;
  }
}
