import "server-only";
import {createClient} from "@/lib/supabase/server";
import {CareerDashboardQuery} from "./dashboard/dashboard.query";

export async function loadCareerDashboard(){
 const db=await createClient();
 const {data,error}=await db.auth.getUser();
 if(error||!data.user)throw new Error("Authenticated user required.");
 return new CareerDashboardQuery(db).load();
}
