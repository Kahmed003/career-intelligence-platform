import { requireUser } from "@/lib/auth/require-user";
import { Sidebar } from "@/components/layout/sidebar";
import { AppHeader } from "@/components/layout/app-header";

export default async function ProtectedLayout({ children }: { children: React.ReactNode }) {
  const { user } = await requireUser();
  return <div className="shell">
    <Sidebar />
    <main className="main">
      <AppHeader email={user.email} />
      <div className="content">{children}</div>
    </main>
  </div>;
}
