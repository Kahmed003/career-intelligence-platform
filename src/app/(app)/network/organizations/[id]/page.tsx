import Link from "next/link";
import {notFound} from "next/navigation";
import {requireUser} from "@/lib/auth/require-user";
import {OrganizationsRepository} from "@/lib/data/repositories/organizations.repository";
import {NetworkQueryService} from "@/lib/queries/network.query";
import {OrganizationDetail} from "@/components/network/organization-detail";
import {OrganizationPeople} from "@/components/network/organization-people";
import {InteractionHistory} from "@/components/network/interaction-history";

export default async function OrganizationPage({params}:{params:Promise<{id:string}>}){
 const {id}=await params;const {db}=await requireUser();const query=new NetworkQueryService(db);
 const [record,people,interactions]=await Promise.all([new OrganizationsRepository(db).getById(id),query.peopleAtOrganization(id),query.interactionsForOrganization(id)]);
 if(!record)notFound();
 const organization={...((record as any).organization??{}),...((record as any).object??{}),id};
 return <><Link className="text-link" href="/network">← Network</Link><div className="page-heading spaced-title"><div><h1 className="page-title">{organization.legal_name??organization.title??"Organization"}</h1><p className="muted">{organization.industry??"Organization record"}</p></div></div>
  <div className="grid grid-2"><OrganizationDetail organization={organization}/><OrganizationPeople rows={(people??[]) as any[]}/><InteractionHistory rows={(interactions??[]) as any[]}/></div>
 </>;
}
