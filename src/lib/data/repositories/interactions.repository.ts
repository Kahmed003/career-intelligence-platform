import {BaseRepository} from "./base";
import {ObjectsRepository} from "./objects.repository";

export class InteractionsRepository extends BaseRepository {
 private objects=new ObjectsRepository(this.db);

 async create(input:{title:string;interaction:Record<string,unknown>}){
  const object=await this.objects.create({object_type:"interaction",title:input.title} as never);
  try{
   const {data,error}=await this.db.from("interactions_communications")
    .insert({id:object.id,...input.interaction} as never).select("*").single();
   if(error)this.fail(error,"create interaction");
   return {object,interaction:data};
  }catch(error){
   await this.objects.cleanupFailedCreate(object.id);
   throw error;
  }
 }

 async getById(id:string){
  const {data,error}=await this.db.from("interactions_communications")
   .select("*, objects!inner(*)").eq("id",id).is("objects.deleted_at",null).maybeSingle();
  if(error)this.fail(error,"get interaction");
  return data;
 }
}
