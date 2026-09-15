"use server";
import { revalidatePath } from "next/cache";
import { OrganizationsService } from "@/lib/application";
import { requireAuthenticatedClient } from "./core/auth";
import { mapActionError } from "./core/error-map";
import { parseActionInput } from "./core/validation";
import type { ActionResult } from "./core/action-result";
import { organizationActionSchema } from "./schemas/core-domains";

export async function createOrganizationAction(input:unknown):Promise<ActionResult<unknown>> {
 const parsed=parseActionInput(organizationActionSchema,input); if(!parsed.ok)return parsed;
 const auth=await requireAuthenticatedClient();
 if(!auth.ok)return {ok:false,error:{code:"UNAUTHENTICATED",message:"Sign in to continue."}};
 try {
  const {title,...organization}=parsed.data;
  const data=await new OrganizationsService(auth.db).create({title,organization} as never,{sourceType:"web"});
  revalidatePath("/organizations"); return {ok:true,data};
 } catch(error) { return mapActionError(error); }
}
