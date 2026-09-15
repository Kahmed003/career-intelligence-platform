export function AppHeader({ email }: { email?: string | null }) {
  return <header className="topbar">
    <strong>Career command center</strong>
    <span className="muted">{email ?? "Authenticated user"}</span>
  </header>;
}
