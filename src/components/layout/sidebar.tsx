import Link from "next/link";

const links = [
  ["/dashboard", "Dashboard"],
  ["/applications", "Applications"],
  ["/opportunities", "Opportunities"],
  ["/network", "Network"],
  ["/projects", "Projects"],
  ["/settings", "Settings"],
] as const;

export function Sidebar() {
  return <aside className="sidebar">
    <div className="brand">Career OS</div>
    <nav className="nav" aria-label="Primary">
      {links.map(([href,label]) => <Link key={href} href={href}>{label}</Link>)}
    </nav>
  </aside>;
}
