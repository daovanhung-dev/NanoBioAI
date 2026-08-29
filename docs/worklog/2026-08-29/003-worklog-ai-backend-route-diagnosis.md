Commit de xuat: docs(worklog): ghi nhan chan doan AI backend route

# Worklog - Chan doan ket noi AI backend

## Thoi gian

- Ngay: 2026-08-29
- Bat dau: 2026-08-29
- Ket thuc: 2026-08-29
- Timezone: Asia/Ho_Chi_Minh

## Pham vi

- Loai task: bugfix
- Module chinh: M05 AI / runtime configuration / Supabase Edge Function
- Yeu cau goc: nap context, tim va fix nguyen nhan ung dung khong ket noi duoc AI key.

## Da lam

- Nap workflow `bugfix`, task-skill `bugfix`, domain AI va domain access sau
  khi xac nhan AI production phu thuoc Supabase.
- Xac nhan Flutter production dung `NabiAiBackendClient`, khong gui Gemini key
  trong app, va Edge Function la noi duy nhat doc `GEMINI_API_KEY`.
- Kiem tra endpoint bang request an toan khong lo credential: ca public config
  local va bundled deu tra HTTP 404 tai `nabi-ai-generate`.
- Cap nhat README/runbook de loai huong dan direct-key da loi thoi.

## File code/docs da sua

- `README.md` - sua - dong bo mo ta AI transport voi source hien tai.
- `docs/AI_CHAT_API_FIX.md` - sua - thay huong dan direct key bang backend-only runbook.
- `docs/fixbug/gemini-ai-connection/008-fixbug-ai-backend-route-unavailable.md` - tao - ghi bang chung va handoff deployment.
- `docs/worklog/2026-08-29/003-worklog-ai-backend-route-diagnosis.md` - tao - ghi nhan phien.

## Tai lieu lien quan

- `lib/app_versions/v1/services/ai/README_FIX.md`
- `docs/supabase/README.md`
- `supabase/functions/nabi-ai-generate/index.ts`

## Commands

- `GET /functions/v1/nabi-ai-generate` voi public config: PASS - endpoint phan hoi HTTP 404, khong goi provider.
- Request AI toi thieu qua Edge endpoint: PASS - nhan HTTP 404 truoc khi provider duoc goi.
- `pwsh -NoProfile -ExecutionPolicy Bypass -File tools/test_gemini_connection.ps1`: SKIPPED - `pwsh` khong co trong workspace.
- `powershell -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1`: SKIPPED - `powershell` khong co trong workspace.
- `powershell -ExecutionPolicy Bypass -File .codex/tools/update_worklog_learning.ps1`: SKIPPED - `powershell` khong co trong workspace; khong sua thu cong cac file generated history/task-skill.
- `git diff --check`: PASS.
- Flutter/Dart/Supabase CLI targeted validation: SKIPPED - executable khong co trong PATH.

## Loi/Rui ro

- Da fix: tai lieu current source khong con huong dan dong goi Gemini key vao app.
- Chua fix: Edge Function chua co tai Supabase project dang duoc app cau hinh, hoac project target chua dung.
- Can kiem tra tiep: dat Edge secret, deploy function vao dung project, roi chay live check va test Flutter.

## Ty le hoan thanh

- Hoan thanh: root-cause diagnosis, source-document correction va deployment handoff.
- Dang do: external Supabase deployment can credential/quyen cua chu project.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - phan biet duoc loi client key voi Edge deployment bang HTTP evidence.
- Muc do hoan thanh task: partial - khong the tu deploy khi thieu quyen backend.
- Bang chung kiem chung: context source, contract tests da doc, va route probe HTTP 404 cho ca hai public config.
- Diem ton token/chua toi uu: co tai lieu lich su direct-key mau thuan voi source hien tai; lan sau uu tien reachable transport va release docs.
- Cach toi uu cho phien sau: lay Supabase project ref/access token truoc khi kiem tra live deployment.
- Task-skill can doc lan sau: `.codex/task-skills/bugfix.md`
