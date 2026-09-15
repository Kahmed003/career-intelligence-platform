import type { ZodType } from "zod";
import type { ActionResult } from "./action-result";

export function parseActionInput<T>(schema: ZodType<T>, input: unknown):
  {ok:true;data:T} | ActionResult<never> {
  const parsed=schema.safeParse(input);
  if (!parsed.success) {
    const raw=parsed.error.flatten().fieldErrors;
    const fieldErrors=Object.fromEntries(Object.entries(raw).filter(([,v])=>v?.length)) as Record<string,string[]>;
    return {ok:false,error:{code:"VALIDATION_ERROR",message:"Check the submitted fields and try again.",fieldErrors}};
  }
  return {ok:true,data:parsed.data};
}
