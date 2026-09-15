import { ApplicationStatus } from "./application-status";
import { StatusTransitionForm } from "./status-transition-form";

export function ApplicationDetail({ row }: { row:any }) {
 return <div className="grid grid-2">
  <section className="card">
   <h2 className="section-title">Application</h2>
   <dl className="detail-list">
    <div><dt>Status</dt><dd><ApplicationStatus status={row.application_status}/></dd></div>
    <div><dt>Organization</dt><dd>{row.organization_name ?? "—"}</dd></div>
    <div><dt>Opportunity</dt><dd>{row.opportunity_title ?? "—"}</dd></div>
    <div><dt>Type</dt><dd>{row.opportunity_type ?? "—"}</dd></div>
    <div><dt>Priority</dt><dd>{row.priority ?? "—"}</dd></div>
    <div><dt>Fit score</dt><dd>{row.fit_score ?? "—"}</dd></div>
    <div><dt>Submitted</dt><dd>{date(row.submitted_at)}</dd></div>
    <div><dt>Application deadline</dt><dd>{date(row.application_deadline_at)}</dd></div>
   </dl>
  </section>
  <section className="card">
   <h2 className="section-title">Lifecycle</h2>
   <StatusTransitionForm id={row.application_id} currentStatus={row.application_status}/>
  </section>
  <section className="card">
   <h2 className="section-title">Next event</h2>
   <dl className="detail-list">
    <div><dt>Kind</dt><dd>{row.next_event_kind ?? "—"}</dd></div>
    <div><dt>Scheduled</dt><dd>{date(row.next_event_at)}</dd></div>
    <div><dt>Deadline</dt><dd>{date(row.next_event_deadline_at)}</dd></div>
   </dl>
  </section>
  <section className="card">
   <h2 className="section-title">Offer</h2>
   <dl className="detail-list">
    <div><dt>Status</dt><dd>{row.offer_status ?? "—"}</dd></div>
    <div><dt>Decision deadline</dt><dd>{date(row.offer_decision_deadline_at)}</dd></div>
    <div><dt>Comparison score</dt><dd>{row.offer_comparison_score ?? "—"}</dd></div>
   </dl>
  </section>
 </div>;
}
function date(v?:string|null){if(!v)return "—";const d=new Date(v);return Number.isNaN(d.valueOf())?"—":d.toLocaleString();}
