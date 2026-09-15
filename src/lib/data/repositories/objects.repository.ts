import { BaseRepository } from "./base";
import type { Insert, ObjectRow, Update } from "@/lib/data/types/database";

export type CreateObjectInput = Omit<
  Insert<"objects">,
  "id" | "owner_user_id" | "created_at" | "updated_at" | "archived_at" | "deleted_at"
> & { id?: string };

export class ObjectsRepository extends BaseRepository {
  async list(params: { objectType?: string; lifecycleStatus?: string; limit?: number } = {}) {
    let query = this.db
      .from("objects")
      .select("*")
      .is("deleted_at", null)
      .order("updated_at", { ascending: false })
      .limit(params.limit ?? 100);

    if (params.objectType) query = query.eq("object_type", params.objectType);
    if (params.lifecycleStatus) query = query.eq("lifecycle_status", params.lifecycleStatus);

    const { data, error } = await query;
    if (error) this.fail(error, "list objects");
    return data;
  }

  async getById(id: string): Promise<ObjectRow | null> {
    const { data, error } = await this.db
      .from("objects").select("*").eq("id", id).is("deleted_at", null).maybeSingle();
    if (error) this.fail(error, "get object");
    return data;
  }

  async create(input: CreateObjectInput): Promise<ObjectRow> {
    const { data: auth, error: authError } = await this.db.auth.getUser();
    if (authError) throw authError;
    if (!auth.user) throw new Error("Authenticated user required.");

    const { data, error } = await this.db
      .from("objects")
      .insert({ ...input, owner_user_id: auth.user.id })
      .select("*").single();
    if (error) this.fail(error, "create object");
    return data;
  }

  async update(id: string, patch: Update<"objects">): Promise<ObjectRow> {
    const { data, error } = await this.db
      .from("objects").update(patch).eq("id", id).is("deleted_at", null).select("*").single();
    if (error) this.fail(error, "update object");
    return data;
  }

  async softDelete(id: string) {
    const { data, error } = await this.db
      .from("objects")
      .update({ deleted_at: new Date().toISOString() })
      .eq("id", id).is("deleted_at", null).select("*").single();
    if (error) this.fail(error, "soft-delete object");
    return data;
  }

  async cleanupFailedCreate(id: string) {
    const { error } = await this.db.from("objects").delete().eq("id", id);
    if (error) this.fail(error, "cleanup failed domain create");
  }
}
