# Career OS — Next.js Application Services Batch 2

This batch depends on Data Access Layer Batch 1.

Copy the files into the same Next.js Career OS repository, then:

1. Ensure Batch 1 repositories are present.
2. Regenerate `src/lib/supabase/database.types.ts` from the migrated Supabase project.
3. Run the TypeScript compiler.
4. Run repository/service tests.
5. Use services—not repositories directly—from Server Actions and Route Handlers.

Important: if your generated Activity Ledger field names differ from the service assumptions,
TypeScript will surface the mismatch. Align the service to the generated schema; do not alter
the database merely to satisfy guessed application code.
