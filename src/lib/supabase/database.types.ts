/**
 * GENERATED FILE PLACEHOLDER.
 *
 * Replace this file by running:
 *   npm run db:types
 *
 * Do not hand-maintain production database types.
 */
export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[];

export type Database = {
  public: {
    Tables: Record<string, never>;
    Views: Record<string, never>;
    Functions: Record<string, never>;
    Enums: Record<string, never>;
    CompositeTypes: Record<string, never>;
  };
};
