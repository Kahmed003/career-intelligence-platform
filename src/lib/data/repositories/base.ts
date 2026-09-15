import type { SupabaseClient, PostgrestError } from "@supabase/supabase-js";
import type { Database } from "@/lib/supabase/database.types";
import { RepositoryError } from "@/lib/data/errors/repository-error";

export type DbClient = SupabaseClient<Database>;

export abstract class BaseRepository {
  constructor(protected readonly db: DbClient) {}

  protected fail(error: PostgrestError, operation: string): never {
    throw RepositoryError.from(error, operation);
  }
}
