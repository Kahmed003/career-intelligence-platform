import {PersonDetail} from "./person-detail";
import {InteractionHistory} from "./interaction-history";
import {CommunicationCaptureForm} from "./communication-capture-form";

export function PersonNetworkWorkspace({person,interactions}:{person:any;interactions:any[]}){
 return <div className="grid grid-2">
  <PersonDetail person={person}/>
  <CommunicationCaptureForm personId={person.id} organizationId={person.organization_id}/>
  <InteractionHistory rows={interactions}/>
 </div>;
}
