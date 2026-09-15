import { z } from "zod";
export const uuidSchema=z.string().uuid();
export const titleSchema=z.string().trim().min(1).max(300);
export const dateSchema=z.string().date();
export const dateTimeSchema=z.string().datetime({offset:true});
export const prioritySchema=z.number().int().min(1).max(5);
