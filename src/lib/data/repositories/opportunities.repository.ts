import { BaseRepository } from "./base";
import { ObjectsRepository } from "./objects.repository";
import type { Insert, Update } from "@/lib/data/types/database";

export type CreateOpportunityInput = {
  title: string;
  object?: Partial<Omit<Insert<"objects">, "id" | "owner_user_id" | "object_type" | "title">>;
  opportunity: Omit<Insert<"opportunities">, "id" | "created_at" | "updated_at">;
};

export class OpportunitysRepository extends BaseRepository {
  private objects = new ObjectsRepository(this.db);

  async list(limit = 100) {
    const { data, error } = await this.db
      .from("objects")
      .select("*, opportunities(*)")
      .eq("object_type", "opportunity")
      .is("deleted_at", null)
      .order("updated_at", { ascending: false })
      .limit(limit);
    if (error) this.fail(error, "list opportunities");
    return data;
  }

  async getById(id: string) {
    const { data, error } = await this.db
      .from("objects")
      .select("*, opportunities(*)")
      .eq("id", id)
      .eq("object_type", "opportunity")
      .is("deleted_at", null)
      .maybeSingle();
    if (error) this.fail(error, "get opportunities");
    return data;
  }

  async create(input: CreateOpportunityInput) {
    const object = await this.objects.create({
      ...input.object,
      object_type: "opportunity",
      title: input.title,
    } as never);

    const { data, error } = await this.db
      .from("opportunities")
      .insert({ ...input.opportunity, id: object.id } as Insert<"opportunities">)
      .select("*").single();

    if (error) {
      await this.objects.cleanupFailedCreate(object.id);
      this.fail(error, "create opportunities");
    }
    return { ...object, opportunity: data };
  }

  async update(id: string, patch: Update<"opportunities">) {
    const { data, error } = await this.db
      .from("opportunities").update(patch).eq("id", id).select("*").single();
    if (error) this.fail(error, "update opportunities");
    return data;
  }
}
