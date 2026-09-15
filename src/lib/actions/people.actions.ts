"use server";
import { revalidatePath } from "next/cache";
import { PeopleService } from "@/lib/application";
import { requireAuthenticatedClient } from "./core/auth";
import { mapActionError } from "./core/error-map";
import { parseActionInput } from "./core/validation";
import type { ActionResult } from "./core/action-result";
import { personActionSchema } from "./schemas/core-domains";

export async function createPersonAction(input:unknown):Promise<ActionResult<unknown>> {
 const parsed=parseActionInput(personActionSchema,input); if(!parsed.ok)return parsed;
 const auth=await requireAuthenticatedClient();
 if(!auth.ok)return {ok:false,error:{code:"UNAUTHENTICATED",message:"Sign in to continue."}};
 try {
  const {title,...person}=parsed.data;
  const data=await new PeopleService(auth.db).create({title,person} as never,{sourceType:"web"});
  revalidatePath("/people"); return {ok:true,data};
 } catch(error) { return mapActionError(error); }
}
