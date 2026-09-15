"use server";
import {revalidatePath} from "next/cache";
import {createClient} from "@/lib/supabase/server";
import {InteractionCommunicationService} from "@/lib/application/services/interactions.service";
import {createInteractionSchema} from "./schemas/interactions";
import {mapActionError} from "./core/error-map";

export async function createInteractionAction(input:unknown){
 try{
  const parsed=createInteractionSchema.parse(input);
  const db=await createClient();
  const {data:{user}}=await db.auth.getUser();
  if(!user)return {ok:false,error:{code:"UNAUTHENTICATED",message:"Authentication required."}} as const;

  const {title,...interaction}=parsed;
  const result=await new InteractionCommunicationService(db).create(
   {title,interaction},
   {actorType:"user",sourceType:"web"}
  );
  revalidatePath("/network");
  if(parsed.person_id)revalidatePath(`/network/people/${parsed.person_id}`);
  if(parsed.organization_id)revalidatePath(`/network/organizations/${parsed.organization_id}`);
  return {ok:true,data:result} as const;
 }catch(error){
  return {ok:false,error:mapActionError(error)} as const;
 }
}
