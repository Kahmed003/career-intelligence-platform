import { signIn } from "./actions";
export default function LoginPage() {
  return <main className="login-wrap"><section className="login-card">
    <h1>Career OS</h1><p className="muted">Sign in to your career command center.</p>
    <form action={signIn}>
      <label className="field"><span>Email</span><input name="email" type="email" autoComplete="email" required /></label>
      <label className="field"><span>Password</span><input name="password" type="password" autoComplete="current-password" required /></label>
      <button className="primary" type="submit">Sign in</button>
    </form>
  </section></main>;
}
