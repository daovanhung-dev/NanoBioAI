Commit de xuat: docs(worklog): ghi nhan deploy Admin Web self-hosted

# Worklog - Deploy Admin Web qua NanoBio backend

## Thoi gian

- Ngay: 2026-10-31
- Bat dau: Khoang 12:15 (Asia/Ho_Chi_Minh)
- Ket thuc: 12:33
- Timezone: Asia/Ho_Chi_Minh

## Pham vi

- Loai task: Chuyen va deploy Admin Web sang backend self-hosted.
- Module chinh: `backend/`, `admin-web/`, GitHub Pages environment.
- Yeu cau goc: Deploy branch `codex/self-hosted-cutover` truc tiep, khong merge `main`, khong dung Supabase.

## Da lam

- Tao ban sao PostgreSQL `nanobio` truoc migration tai `/var/backups/nanobio/nanobio-before-admin-20261031.dump` (73,384 bytes, mode 600); giu nguyen `nanobio_legacy`.
- Chay Alembic rehearsal tren PostgreSQL tam; restore ban sao production vao DB rehearsal va xac nhan migration tu `0001_initial` len `0006_referral_comm` khong mat user row.
- Rehearsal phat hien revision ID cu dai hon gioi han 32 ky tu; rut gon thanh `0006_referral_comm`, chay lai rehearsal thanh cong truoc khi ap dung production.
- Deploy backend va migrations len `/opt/nanobio/backend`; production Alembic revision hien tai la `0006_referral_comm`.
- Gan role `super_admin` cho tai khoan duy nhat hien co trong `nanobio`, theo lua chon cua nguoi dung. Khong thay doi password.
- Them `https://daovanhung-dev.github.io` vao `CORS_ALLOWED_ORIGINS`; preflight tu origin nay tra 200 va `Access-Control-Allow-Origin` khop chinh xac.
- Health/readiness tu Internet tra `{"status":"ready","database":"ready"}`. OpenAPI co cac route dashboard, business, file storage va Early Access.
- Tao release commit backend `4ec77e24`, giu commit Admin Web `88474f11`, va push branch `codex/self-hosted-cutover`.
- Them GitHub Repository Variable `NANOBIO_API_BASE_URL=https://42.118.174.147`.
- GitHub Pages environment ban dau chi cho `main`; sau khi nguoi dung cho phep, them duy nhat branch `codex/self-hosted-cutover`, giu rule `main`.
- Workflow #17 bi chan truoc build do branch protection; sau khi cap nhat allowlist, rerun thanh cong.
- Kiem tra bundle Pages co URL backend, khong co `supabase.co` hay `@supabase/supabase-js`.
- Tai giao dien live, phat hien tai khoan admin duoc chon khong co email. Sua form dang nhap nhan email hoac so dien thoai; backend-client gui `email` hoac `phone` dung contract. Them test cho phone-only login.
- Tao commit `1a6e171d` va push branch. Workflow #18 typecheck, test, build va deploy Pages deu PASS.
- Tai lai tab Admin Web live, form dang nhap hien “Email hoac so dien thoai”. Bundle `/NanoBioAI/assets/index-BFBryrHW.js` chua URL backend va khong chua `supabase.co` hay `@supabase/supabase-js`.

## File code/docs da sua

- `backend/alembic/versions/0002_nullable_admin_phone.py` den `0006_referral_commission_contract.py` - them schema va contracts cho auth, business, quota, sleep safety, payments/referral, Admin.
- `backend/src/nanobio_backend/` - them route dashboard/business, quan tri, storage, auth va cac module phu thuoc; cap nhat API contracts lien quan.
- `backend/tests/test_api_core.py`, `backend/tests/test_ai_ollama.py` - kiem tra backend contracts.
- `admin-web/src/lib/backend-client.ts`, `admin-web/src/lib/admin-api.ts`, `admin-web/src/auth/AuthProvider.tsx`, `admin-web/src/pages/LoginPage.tsx` - ho tro dang nhap Admin bang email hoac so dien thoai qua backend.
- `admin-web/src/lib/admin-api.test.ts` - them test phone-only login.
- `docs/worklog/2026-10-31/001-worklog-admin-web-self-hosted-deploy.md` - ghi lai ket qua migration rehearsal, deploy va gioi han nghiem thu.
- `.codex/history/` va `.codex/task-skills/` - cap nhat bang script refresh worklog theo project workflow.

## Tai lieu lien quan

- `.codex/DOCS_WORKFLOW.md`
- `backend/AGENTS.md`
- `backend/.agents/context-map.md`
- `docs/worklog/2026-10-30/005-worklog-https-connection-recovery.md`

## Commands

- Backend `ruff check`, `ruff format --check`, `mypy`, `pytest`: PASS.
- Restore ban sao production vao PostgreSQL tam va apply Alembic toi head: PASS; so user truoc/sau la 1.
- Production `/health/ready` va route inventory: PASS.
- HTTPS CORS preflight tu GitHub Pages: PASS, HTTP 200.
- GitHub Actions workflow #17: PASS sau khi them branch vao environment allowlist.
- GitHub Actions workflow #18: PASS; typecheck, test, config validation, build va Pages deployment deu thanh cong.
- Bundle Pages live: PASS; URL backend co mat, Supabase domain/SDK khong co.
- `.codex/tools/validate_codex_integrity.ps1`: FAIL do thieu `docs/audit/source_truth_manifest.json` va cac stale path trong history/task-skill hien co; cac file loi khong thuoc pham vi sua cua task.
- `git diff --check`: PASS.
- Live Admin login/dashboard va thao tac co quyen: CHUA KIEM CHUNG; can dang nhap bang tai khoan hien co de xac nhan giao dich end-to-end.

## Loi/Rui ro

- Da fix: Alembic revision vuot 32 ky tu; branch deploy bi environment protection chan; form Admin Web chi nhan email trong khi user duoc chon chi co phone.
- Chua fix: Chua co thong tin mat khau tai khoan de dang nhap va kiem tra dashboard/thao tac Admin end-to-end. Password khong duoc thay doi hay ghi vao worklog.
- Can kiem tra tiep: Nguoi dung dang nhap bang phone/mat khau hien tai de xac nhan dashboard va mot thao tac doc/ghi phu hop.

## Ty le hoan thanh

- Hoan thanh: Backend API/migrations/CORS va role; code Admin Web; branch/commit; workflow #17/#18; bundle Pages live dung backend.
- Dang do: Dang nhap/dashboard va thao tac Admin end-to-end do chua co thong tin password de agent dang nhap.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - migration duoc restore rehearsal tu backup production truoc khi ap dung.
- Muc do hoan thanh task: Code va deploy da xong; nghiem thu dashboard E2E can nguoi dung dang nhap bang credential rieng.
- Bang chung kiem chung: Health public, OpenAPI routes, CORS 200, restored DB migration, workflow summaries va asset URL da fetch.
- Diem ton token/chua toi uu: GitHub environment protection can them mot vong UI sau khi run dau bi chan.
- Cach toi uu cho phien sau: Kiem tra environment deployment branch allowlist truoc workflow_dispatch.
- Task-skill can doc lan sau: `.codex/task-skills/coding.md`
