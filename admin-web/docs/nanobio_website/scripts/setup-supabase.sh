#!/usr/bin/env bash
set -euo pipefail
PROJECT_REF="${SUPABASE_PROJECT_REF:-rnwohifdnylqfofkydfl}"
command -v supabase >/dev/null || { echo "Cần cài Supabase CLI trước."; exit 1; }
echo "==> Link Supabase project: $PROJECT_REF"
supabase link --project-ref "$PROJECT_REF"
echo "==> Push migration"
supabase db push
echo "==> Deploy function"
supabase functions deploy register-early-access --no-verify-jwt
echo "Hoàn tất backend. Tiếp theo upload APK vào bucket early-access-apk với tên nanobio-early-access.apk."
