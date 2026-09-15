import { loadCareerDashboard } from "@/lib/queries/server";
import { DashboardOverview } from "@/components/dashboard/dashboard-overview";

export default async function DashboardPage() {
  const data = await loadCareerDashboard();
  return <>
    <h1 className="page-title">Dashboard</h1>
    <p className="muted">Applications, deadlines, opportunities, relationships, and campaign activity.</p>
    <DashboardOverview data={data} />
  </>;
}
