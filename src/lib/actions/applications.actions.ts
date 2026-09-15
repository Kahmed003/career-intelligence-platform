"use server";
import {revalidatePath} from "next/cache";
import {ApplicationsService} from "@/lib/application";
import {requireAuthenticatedClient} from "./core/auth";
import {mapActionError} from "./core/error-map";
import {parseActionInput} from "./core/validation";
import type {ActionResult} from "./core/action-result";
import {applicationActionSchema,applicationTransitionSchema} from "./schemas/core-domains";

export async function createApplicationAction(input:unknown):Promise<ActionResult<unknown>>{
 const parsed=parseActionInput(applicationActionSchema,input);if(!parsed.ok)return parsed;
 const auth=await requireAuthenticatedClient();
 if(!auth.ok)return {ok:false,error:{code:"UNAUTHENTICATED",message:"Sign in to continue."}};
 try{
  const {title,...application}=parsed.data;
  const data=await new ApplicationsService(auth.db).create({title,application} as never,{sourceType:"web"});
  revalidatePath("/applications");revalidatePath("/pipeline");return {ok:true,data};
 }catch(error){return mapActionError(error);}
}

export async function transitionApplicationStatusAction(input:unknown):Promise<ActionResult<unknown>>{
 const parsed=parseActionInput(applicationTransitionSchema,input);if(!parsed.ok)return parsed;
 const auth=await requireAuthenticatedClient();
 if(!auth.ok)return {ok:false,error:{code:"UNAUTHENTICATED",message:"Sign in to continue."}};
 try{
  const data=await new ApplicationsService(auth.db).transitionStatus(
   parsed.data.id,parsed.data.status,
   {outcome:parsed.data.outcome as never,context:{sourceType:"web"}}
  );
  revalidatePath("/applications");revalidatePath(`/applications/${parsed.data.id}`);revalidatePath("/pipeline");
  return {ok:true,data};
 }catch(error){return mapActionError(error);}
}
