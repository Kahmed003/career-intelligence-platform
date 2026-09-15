import { createClient } from "@/lib/supabase/server";

export async function requireAuthenticatedClient() {
  const db = await createClient();
  const { data, error } = await db.auth.getUser();
  if (error || !data.user) return { ok: false as const, db, user: null };
  return { ok: true as const, db, user: data.user };
}
