import {BaseQueryService} from "./core/base-query.service";

export class NetworkQueryService extends BaseQueryService {
 async interactionsForPerson(personId:string,limit=100){
  const {data,error}=await this.db.from("interactions_communications").select("*")
   .eq("person_id",personId).order("occurred_at",{ascending:false,nullsFirst:false}).limit(limit);
  if(error)this.fail(error,"query person interactions");return data;
 }
 async interactionsForOrganization(organizationId:string,limit=100){
  const {data,error}=await this.db.from("interactions_communications").select("*")
   .eq("organization_id",organizationId).order("occurred_at",{ascending:false,nullsFirst:false}).limit(limit);
  if(error)this.fail(error,"query organization interactions");return data;
 }
 async peopleAtOrganization(organizationId:string,limit=100){
  const {data,error}=await this.db.from("people").select("*, objects!inner(title,deleted_at)")
   .eq("organization_id",organizationId).is("objects.deleted_at",null).limit(limit);
  if(error)this.fail(error,"query organization people");return data;
 }
}
