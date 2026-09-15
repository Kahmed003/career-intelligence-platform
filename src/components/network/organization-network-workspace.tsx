import {OrganizationDetail} from "./organization-detail";
import {OrganizationPeople} from "./organization-people";
import {InteractionHistory} from "./interaction-history";
import {CommunicationCaptureForm} from "./communication-capture-form";

export function OrganizationNetworkWorkspace({organization,people,interactions}:{organization:any;people:any[];interactions:any[]}){
 return <div className="grid grid-2">
  <OrganizationDetail organization={organization}/>
  <CommunicationCaptureForm organizationId={organization.id}/>
  <OrganizationPeople rows={people}/>
  <InteractionHistory rows={interactions}/>
 </div>;
}
