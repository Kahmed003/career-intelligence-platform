import type {SupabaseClient,PostgrestError} from "@supabase/supabase-js";
import type {Database} from "@/lib/supabase/database.types";
import {QueryError} from "./query-error";
export type DbClient=SupabaseClient<Database>;
export abstract class BaseQueryService {
 constructor(protected readonly db:DbClient){}
 protected fail(error:PostgrestError,operation:string):never{throw QueryError.from(error,operation);}
}
