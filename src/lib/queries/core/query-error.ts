import type { PostgrestError } from "@supabase/supabase-js";
export class QueryError extends Error {
 constructor(message:string,public readonly code?:string,options?:ErrorOptions){super(message,options);this.name="QueryError";}
 static from(error:PostgrestError,operation:string){return new QueryError(`${operation}: ${error.message}`,error.code,{cause:error});}
}
