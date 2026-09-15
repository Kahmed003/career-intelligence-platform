import type { CareerDashboardData } from "@/lib/queries";

export function DashboardOverview({ data }: { data: CareerDashboardData }) {
  return <>
    <div className="grid grid-4" style={{marginTop:20}}>
      <section className="card"><div className="muted">Pipeline records</div><div className="metric">{data.pipeline.length}</div></section>
      <section className="card"><div className="muted">Upcoming actions</div><div className="metric">{data.deadlines.length}</div></section>
      <section className="card"><div className="muted">Strong matches</div><div className="metric">{data.matchedOpportunities.length}</div></section>
      <section className="card"><div className="muted">Relationships to review</div><div className="metric">{data.relationshipsNeedingAttention.length}</div></section>
    </div>

    <div className="grid grid-2" style={{marginTop:16}}>
      <section className="card">
        <h2 className="section-title">Next deadlines</h2>
        {data.deadlines.length ? data.deadlines.slice(0,8).map((item:any,i:number) =>
          <div className="row" key={item.id ?? i}>
            <span>{item.title ?? item.item_title ?? item.action_type ?? "Deadline"}</span>
            <span className="badge">{item.urgency ?? "upcoming"}</span>
          </div>
        ) : <div className="empty">No upcoming deadlines.</div>}
      </section>

      <section className="card">
        <h2 className="section-title">Opportunity matches</h2>
        {data.matchedOpportunities.length ? data.matchedOpportunities.slice(0,8).map((item:any,i:number) =>
          <div className="row" key={item.opportunity_id ?? i}>
            <span>{item.opportunity_title ?? item.title ?? "Opportunity"}</span>
            <strong>{item.match_score ?? "—"}</strong>
          </div>
        ) : <div className="empty">No scored opportunities yet.</div>}
      </section>

      <section className="card">
        <h2 className="section-title">Relationships needing attention</h2>
        {data.relationshipsNeedingAttention.length ? data.relationshipsNeedingAttention.slice(0,8).map((item:any,i:number) =>
          <div className="row" key={item.person_id ?? i}>
            <span>{item.person_name ?? item.title ?? "Contact"}</span>
            <span className="badge">{item.relationship_health ?? "review"}</span>
          </div>
        ) : <div className="empty">No relationships currently flagged.</div>}
      </section>

      <section className="card">
        <h2 className="section-title">Campaigns</h2>
        {data.campaigns.length ? data.campaigns.slice(0,8).map((item:any,i:number) =>
          <div className="row" key={item.campaign_id ?? i}>
            <span>{item.campaign_title ?? item.title ?? "Campaign"}</span>
            <span className="badge">{item.status ?? "active"}</span>
          </div>
        ) : <div className="empty">No campaign analytics yet.</div>}
      </section>
    </div>
  </>;
}
