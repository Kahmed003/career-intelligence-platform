import {requireUser} from "@/lib/auth/require-user";
import {RelationshipsQueryService} from "@/lib/queries";
import {RelationshipHealthList} from "@/components/network/relationship-health-list";

export default async function NetworkPage(){
 const {db}=await requireUser();
 const service=new RelationshipsQueryService(db);
 const [attention,health]=await Promise.all([service.needsAttention(50),service.health(100)]);
 return <><h1 className="page-title">Network</h1><p className="muted">Relationship health, follow-ups, and networking activity.</p>
  <div className="grid grid-4 network-metrics">
   <section className="card"><div className="muted">Tracked relationships</div><div className="metric">{health?.length??0}</div></section>
   <section className="card"><div className="muted">Need attention</div><div className="metric">{attention?.length??0}</div></section>
  </div>
  <RelationshipHealthList rows={(attention??[]) as any[]}/>
 </>;
}
