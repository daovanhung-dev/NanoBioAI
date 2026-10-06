$ErrorActionPreference = "Stop"
$ProjectRef = if ($env:SUPABASE_PROJECT_REF) { $env:SUPABASE_PROJECT_REF } else { "rnwohifdnylqfofkydfl" }
if (-not (Get-Command supabase -ErrorAction SilentlyContinue)) { throw "Cần cài Supabase CLI trước." }
Write-Host "==> Link Supabase project: $ProjectRef"
supabase link --project-ref $ProjectRef
Write-Host "==> Push migration"
supabase db push
Write-Host "==> Deploy function"
supabase functions deploy register-early-access --no-verify-jwt
Write-Host "Hoàn tất backend. Tiếp theo upload APK vào bucket early-access-apk với tên nanobio-early-access.apk."
