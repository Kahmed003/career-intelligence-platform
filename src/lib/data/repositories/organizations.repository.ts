import { BaseRepository } from "./base";
import { ObjectsRepository } from "./objects.repository";
import type { Insert, Update } from "@/lib/data/types/database";

export type CreateOrganizationInput = {
  title: string;
  object?: Partial<Omit<Insert<"objects">, "id" | "owner_user_id" | "object_type" | "title">>;
  organization: Omit<Insert<"organizations">, "id" | "created_at" | "updated_at">;
};

export class OrganizationsRepository extends BaseRepository {
  private objects = new ObjectsRepository(this.db);

  async list(limit = 100) {
    const { data, error } = await this.db
      .from("objects")
      .select("*, organizations(*)")
      .eq("object_type", "organization")
      .is("deleted_at", null)
      .order("updated_at", { ascending: false })
      .limit(limit);
    if (error) this.fail(error, "list organizations");
    return data;
  }

  async getById(id: string) {
    const { data, error } = await this.db
      .from("objects")
      .select("*, organizations(*)")
      .eq("id", id)
      .eq("object_type", "organization")
      .is("deleted_at", null)
      .maybeSingle();
    if (error) this.fail(error, "get organizations");
    return data;
  }

  async create(input: CreateOrganizationInput) {
    const object = await this.objects.create({
      ...input.object,
      object_type: "organization",
      title: input.title,
    } as never);

    const { data, error } = await this.db
      .from("organizations")
      .insert({ ...input.organization, id: object.id } as Insert<"organizations">)
      .select("*").single();

    if (error) {
      await this.objects.cleanupFailedCreate(object.id);
      this.fail(error, "create organizations");
    }
    return { ...object, organization: data };
  }

  async update(id: string, patch: Update<"organizations">) {
    const { data, error } = await this.db
      .from("organizations").update(patch).eq("id", id).select("*").single();
    if (error) this.fail(error, "update organizations");
    return data;
  }
}
