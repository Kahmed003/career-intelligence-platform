"use server";
import { revalidatePath } from "next/cache";
import { OpportunitiesService } from "@/lib/application";
import { requireAuthenticatedClient } from "./core/auth";
import { mapActionError } from "./core/error-map";
import { parseActionInput } from "./core/validation";
import type { ActionResult } from "./core/action-result";
import { opportunityActionSchema } from "./schemas/core-domains";

export async function createOpportunityAction(input:unknown):Promise<ActionResult<unknown>> {
 const parsed=parseActionInput(opportunityActionSchema,input); if(!parsed.ok)return parsed;
 const auth=await requireAuthenticatedClient();
 if(!auth.ok)return {ok:false,error:{code:"UNAUTHENTICATED",message:"Sign in to continue."}};
 try {
  const {title,...opportunity}=parsed.data;
  const data=await new OpportunitiesService(auth.db).create({title,opportunity} as never,{sourceType:"web"});
  revalidatePath("/opportunities"); return {ok:true,data};
 } catch(error) { return mapActionError(error); }
}
