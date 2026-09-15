import Link from "next/link";
import { ApplicationStatus } from "./application-status";

const columns=["preparing","submitted","assessment","interviewing","offer"] as const;

export function ApplicationPipeline({ rows }: { rows:any[] }) {
  return <div className="pipeline-grid">{columns.map(status => {
    const items=rows.filter(row=>row.application_status===status);
    return <section className="pipeline-column" key={status}>
      <div className="pipeline-heading"><strong>{status}</strong><span className="badge">{items.length}</span></div>
      <div className="stack">{items.map(row=><Link href={`/applications/${row.application_id}`} className="pipeline-card" key={row.application_id}>
        <strong>{row.application_title ?? row.opportunity_title ?? "Application"}</strong>
        <span className="muted">{row.organization_name ?? "Unknown organization"}</span>
        <div><ApplicationStatus status={row.application_status}/></div>
      </Link>)}
      {!items.length?<div className="empty">None</div>:null}</div>
    </section>;
  })}</div>;
}
