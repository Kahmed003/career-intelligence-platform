#!/usr/bin/env bash
set -euo pipefail

: "${SUPABASE_PROJECT_ID:?SUPABASE_PROJECT_ID must be set}"

mkdir -p src/lib/supabase
supabase gen types typescript --project-id "$SUPABASE_PROJECT_ID" --schema public > src/lib/supabase/database.types.ts
echo "Generated src/lib/supabase/database.types.ts"
