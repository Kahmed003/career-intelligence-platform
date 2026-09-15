import {DomainServiceBase} from "./domain-service.base";
import {InteractionsRepository} from "@/lib/data/repositories/interactions.repository";
import type {WorkflowContext} from "../types/workflow";

export class InteractionCommunicationService extends DomainServiceBase {
 private repository=new InteractionsRepository(this.db);

 async create(input:{title:string;interaction:Record<string,unknown>},context?:WorkflowContext){
  const created=await this.repository.create(input);
  await this.recordCreated(created.object.id,"interaction",context);
  return created;
 }
}
