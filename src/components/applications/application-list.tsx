import Link from "next/link";
import { ApplicationStatus } from "./application-status";

export function ApplicationList({ rows }: { rows: any[] }) {
  if (!rows.length) return <section className="card empty">No applications yet.</section>;
  return <section className="card">
    <div className="table-wrap">
      <table className="data-table">
        <thead><tr><th>Application</th><th>Organization</th><th>Status</th><th>Fit</th><th>Next action</th><th>Deadline</th></tr></thead>
        <tbody>{rows.map((row) => (
          <tr key={row.application_id}>
            <td><Link className="text-link" href={`/applications/${row.application_id}`}>{row.application_title ?? row.opportunity_title ?? "Application"}</Link></td>
            <td>{row.organization_name ?? "—"}</td>
            <td><ApplicationStatus status={row.application_status} /></td>
            <td>{row.fit_score ?? "—"}</td>
            <td>{formatDate(row.next_action_at)}</td>
            <td>{formatDate(row.application_deadline_at)}</td>
          </tr>
        ))}</tbody>
      </table>
    </div>
  </section>;
}
function formatDate(value?:string|null){if(!value)return "—";const d=new Date(value);return Number.isNaN(d.valueOf())?"—":d.toLocaleDateString();}
