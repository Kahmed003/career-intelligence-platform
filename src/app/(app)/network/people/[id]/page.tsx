import Link from "next/link";
import {notFound} from "next/navigation";
import {requireUser} from "@/lib/auth/require-user";
import {PeopleRepository} from "@/lib/data/repositories/people.repository";
import {NetworkQueryService} from "@/lib/queries/network.query";
import {PersonDetail} from "@/components/network/person-detail";
import {InteractionHistory} from "@/components/network/interaction-history";
import {CommunicationCaptureNotice} from "@/components/network/communication-capture";

export default async function PersonPage({params}:{params:Promise<{id:string}>}){
 const {id}=await params;const {db}=await requireUser();
 const [record,interactions]=await Promise.all([new PeopleRepository(db).getById(id),new NetworkQueryService(db).interactionsForPerson(id)]);
 if(!record)notFound();
 const person={...((record as any).person??{}),...((record as any).object??{}),id};
 return <><Link className="text-link" href="/network">← Network</Link><div className="page-heading spaced-title"><div><h1 className="page-title">{person.preferred_name??[person.first_name,person.last_name].filter(Boolean).join(" ")??"Contact"}</h1><p className="muted">{person.job_title??person.headline??"Relationship record"}</p></div></div>
  <div className="grid grid-2"><PersonDetail person={person}/><CommunicationCaptureNotice/><InteractionHistory rows={(interactions??[]) as any[]}/></div>
 </>;
}
