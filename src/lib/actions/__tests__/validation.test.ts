import {describe,expect,it} from "vitest";
import {applicationTransitionSchema,taskActionSchema} from "../schemas/core-domains";
describe("action validation",()=>{
 it("rejects unknown application status",()=>expect(applicationTransitionSchema.safeParse({
  id:"550e8400-e29b-41d4-a716-446655440000",status:"made_up"}).success).toBe(false));
 it("rejects task priority outside 1..5",()=>expect(taskActionSchema.safeParse({title:"Prepare",priority:9}).success).toBe(false));
 it("accepts minimal task",()=>expect(taskActionSchema.safeParse({title:"Prepare interview"}).success).toBe(true));
});
