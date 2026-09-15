"use server";
import { revalidatePath } from "next/cache";
import { TasksService } from "@/lib/application";
import { requireAuthenticatedClient } from "./core/auth";
import { mapActionError } from "./core/error-map";
import { parseActionInput } from "./core/validation";
import type { ActionResult } from "./core/action-result";
import { taskActionSchema } from "./schemas/core-domains";

export async function createTaskAction(input:unknown):Promise<ActionResult<unknown>> {
 const parsed=parseActionInput(taskActionSchema,input); if(!parsed.ok)return parsed;
 const auth=await requireAuthenticatedClient();
 if(!auth.ok)return {ok:false,error:{code:"UNAUTHENTICATED",message:"Sign in to continue."}};
 try {
  const {title,...task}=parsed.data;
  const data=await new TasksService(auth.db).create({title,task} as never,{sourceType:"web"});
  revalidatePath("/tasks"); return {ok:true,data};
 } catch(error) { return mapActionError(error); }
}
