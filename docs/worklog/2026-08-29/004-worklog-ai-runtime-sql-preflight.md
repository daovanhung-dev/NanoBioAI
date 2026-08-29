Commit de xuat: docs(supabase): them preflight AI runtime

# Worklog - AI runtime SQL preflight

## Thoi gian

- Ngay: 2026-08-29
- Bat dau: 2026-08-29
- Ket thuc: 2026-08-29
- Timezone: Asia/Ho_Chi_Minh

## Pham vi

- Loai task: supabase-schema
- Module chinh: M05 AI / quota / Supabase runtime contract
- Yeu cau goc: tao file SQL kich hoat cac chuc nang AI can dung trong docs/supabase.

## Da lam

- Them 03_ai_runtime_enablement.sql la preflight read-only chay sau 01 va 02.
- Preflight kiem tra bang, RPC, RLS, policy, client grant, entitlement va quota
  cho AI chat, tao lich ca nhan va bao cao noi dung AI.
- Hardening 01_build_system.sql: revoke default PUBLIC/anon execute cua bon quota
  RPC, sau do chi grant authenticated.
- Cap nhat README va contract test de giu rebuild canonical la 01 -> 02; 03 la
  optional preflight, khong phai rebuild hay migration.

## File code/docs da sua

- docs/supabase/01_build_system.sql - sua - hardening quota RPC va fail-fast AI
  database contract.
- docs/supabase/03_ai_runtime_enablement.sql - tao - preflight AI read-only.
- docs/supabase/README.md - sua - huong dan thu tu chay va Edge secret/deploy.
- test/docs/supabase_two_script_rebuild_contract_test.dart - sua - bao ve
  canonical rebuild va preflight khong thay doi state.
- docs/worklog/2026-08-29/004-worklog-ai-runtime-sql-preflight.md - tao - ghi
  nhan phien.

## Tai lieu lien quan

- supabase/functions/nabi-ai-generate/index.ts
- supabase/functions/report-ai-content/index.ts
- docs/supabase/README.md

## Commands

- Static inspection of 03 SQL mutation patterns and provider-key marker: PASS.
- SQL dollar-quote marker balance for 03: PASS.
- git diff --check: PASS.
- powershell -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1:
  SKIPPED - powershell khong co trong PATH.
- powershell -ExecutionPolicy Bypass -File .codex/tools/update_worklog_learning.ps1:
  SKIPPED - powershell khong co trong PATH; khong sua thu cong generated history.
- dart test test/docs/supabase_two_script_rebuild_contract_test.dart: SKIPPED -
  dart khong co trong PATH.
- Supabase SQL execution va Edge deployment: NOT RUN - khong co CLI/credential
  sandbox; 01 va 02 la destructive local/sandbox scripts.

## Loi/Rui ro

- Da lam: database contract AI co preflight ro rang va quota RPC khong con
  default public execute.
- Khong the lam bang SQL: deploy nabi-ai-generate, dat provider secret, hoac
  sua HTTP 404 cua Edge route.
- Con rui ro: nabi-ai-generate hien gio khong tu goi quota RPC; direct Edge
  request van chi dung rate limit trong bo nho cua isolate.

## Ty le hoan thanh

- Hoan thanh: SQL/database contract, static guard, docs handoff.
- Dang do: live SQL preflight va Edge deployment can Supabase project access.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - khong tao migration gia hoac mo rong RLS de danh
  dau AI da san sang khi Edge route chua deploy.
- Muc do hoan thanh task: partial ve van hanh - file SQL da tao, nhung provider
  runtime can deploy ngoai PostgreSQL.
- Bang chung kiem chung: static source audit, SQL read-only pattern check va
  git diff --check.
- Diem ton token/chua toi uu: contract AI phan tach giua Flutter, PostgreSQL va
  Edge Function nen can doi chieu nhieu source.
- Cach toi uu cho phien sau: cap project ref va CLI token de chay preflight,
  deploy Edge Function, sau do luu HTTP evidence.
- Task-skill can doc lan sau: .codex/task-skills/supabase-schema.md
