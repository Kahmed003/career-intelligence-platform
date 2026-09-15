import {BaseQueryService} from "./core/base-query.service";
export class RelationshipsQueryService extends BaseQueryService {
 async health(limit=100){
  const {data,error}=await this.db.from("person_relationship_health").select("*").order("relationship_score",{ascending:false}).limit(limit);
  if(error)this.fail(error,"query relationship health");return data;
 }
 async needsAttention(limit=25){
  const {data,error}=await this.db.from("person_relationship_health").select("*")
   .in("relationship_health",["stale","needs_attention","unengaged"])
   .neq("relationship_stage","do_not_contact").order("relationship_score",{ascending:true}).limit(limit);
  if(error)this.fail(error,"query relationships needing attention");return data;
 }
}
