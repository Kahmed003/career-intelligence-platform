"use server";
import { revalidatePath } from "next/cache";
import { ProjectsService } from "@/lib/application";
import { requireAuthenticatedClient } from "./core/auth";
import { mapActionError } from "./core/error-map";
import { parseActionInput } from "./core/validation";
import type { ActionResult } from "./core/action-result";
import { projectActionSchema } from "./schemas/core-domains";

export async function createProjectAction(input:unknown):Promise<ActionResult<unknown>> {
 const parsed=parseActionInput(projectActionSchema,input); if(!parsed.ok)return parsed;
 const auth=await requireAuthenticatedClient();
 if(!auth.ok)return {ok:false,error:{code:"UNAUTHENTICATED",message:"Sign in to continue."}};
 try {
  const {title,...project}=parsed.data;
  const data=await new ProjectsService(auth.db).create({title,project} as never,{sourceType:"web"});
  revalidatePath("/projects"); return {ok:true,data};
 } catch(error) { return mapActionError(error); }
}
