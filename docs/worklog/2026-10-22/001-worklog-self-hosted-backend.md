Commit de xuat: docs(worklog): ghi nhan phien self-hosted-backend

# Worklog - NanoBioAI self-hosted backend

## Thoi gian

- Ngay: 2026-10-22
- Bat dau: Khong ghi nhan rieng
- Ket thuc: 14:53
- Timezone: Asia/Ho_Chi_Minh

## Pham vi

- Loai task: Xay backend va agent context cho BE.
- Module chinh: `backend/`, `.codex/`, tai lieu backend va worklog NanoBio.
- Yeu cau goc: Dung context tai `docs/context/Backend_Agent_Context_Reusable/`, tham khao cach phan tang cua Study Server, thay Supabase Edge Function bang API FastAPI, dung PostgreSQL local cho Ubuntu; chua sua app/web, chua deploy va khong dung du lieu production.

## Da lam

- Tao FastAPI modular monolith voi typed settings, SQLAlchemy, Alembic, request session, transaction helper, trace ID, response envelope, error handler, health/live va health/ready co probe database.
- Tao 19 API mapping cho Edge Function dang cau hinh; hai endpoint AI legacy tra `503 FEATURE_NOT_ENABLED`. Sau thu muc function empty/unconfigured duoc ghi `NOT_FOUND`, khong tao route tu suy doan.
- Them phone/password Auth noi bo voi Argon2id, access JWT, refresh rotation, rate limit va revocation.
- Them cac module API source-backed cho account, profile, membership, FamilyPlus, Admin account/membership, manual payment, Google Play provider, cloud snapshot, early access, AI content report, food evidence, sleep safety va local storage.
- Tao self health subject cung transaction khi signup hoac Admin provision account; FamilyPlus co 4 API cho context/group/member/remove, owner checks va gioi han 5 thanh vien.
- Duyet thanh toan manual co RBAC, self-review block, doi soat bat buoc, audit event, idempotency va cap/renew entitlement trong transaction.
- Them migration schema, sample environment, systemd unit, backup script va huong dan PostgreSQL native tren Ubuntu.
- Tao agent context rieng `backend/.agents/` dua tren reusable context, them router/domain entry vao `.codex/`, giu `docs/worklog/` la worklog chinh.
- Lap inventory 38 app RPC va RPC dong cua Admin Web. Cac muc con `PARTIAL`/`NOT_YET_PORTED` duoc danh dau ro; khong cong bo route placeholder cho nghiep vu chua co.
- Tao feature doc va test setup PostgreSQL chi chap nhan database loopback tam thoi co ten chua `test`; chay migration tren PostgreSQL 17 rong va chay toan bo test tren PG tam.

## File code/docs da sua

- `backend/src/nanobio_backend/` - tao core, routers va modules cho BE self-hosted; mo rong schema subject/FamilyPlus.
- `backend/alembic/`, `backend/tests/`, `backend/pyproject.toml`, `backend/uv.lock` - migration, dependency va test.
- `backend/.agents/`, `backend/AGENTS.md` - context/router rieng cho BE.
- `backend/contracts/` - inventory Edge Function, RPC, PostgREST va Storage.
- `backend/README.md`, `backend/.env.example`, `backend/systemd/`, `backend/scripts/` - van hanh Ubuntu, cau hinh va backup.
- `.codex/AGENTS.md`, `.codex/PROJECT_MAP.md`, `.codex/domains/backend.md` - noi context BE vao router NanoBio.
- `.codex/history/` va `.codex/task-skills/` - cap nhat tu dong tu worklog NanoBio.
- `docs/features/self-hosted-backend/001-feature-self-hosted-backend.md` - mo ta feature va gioi han contract.
- `docs/worklog/2026-10-22/001-worklog-self-hosted-backend.md` - worklog va ket qua kiem chung.

## Tai lieu lien quan

- `docs/context/Backend_Agent_Context_Reusable/README.md` (nguon reusable context da doc, khong sua).
- `backend/contracts/supabase-function-mapping.md`
- `backend/contracts/supabase-rpc-mapping.md`
- `docs/supabase/README.md` va `docs/supabase/01_build_system.sql`
- `Study2Work/apps/study-server/` chi duoc tham khao ve phan tang va cach trinh bay.

## Commands

- `uv sync --locked`: PASS.
- `uv run ruff format .`, `uv run ruff check .`, `uv run ruff format --check .`: PASS.
- `uv run mypy src/nanobio_backend`, `uv run mypy tests/test_postgres_concurrency.py`: PASS.
- `uv run pytest -q` voi SQLite tam: PASS - 15 passed, 1 skipped (PostgreSQL concurrency test khong co URL).
- PostgreSQL 17 disposable loopback: `alembic upgrade head`, `alembic current`, `alembic check`, `pytest -q`: PASS - migration `0001_initial (head)`, khong con schema diff, 16 passed.
- `python3 backend/scripts/validate_agent_context.py`: PASS - 21 context files va local links.
- `bash -n backend/scripts/backup_postgres.sh`: PASS.
- `pwsh -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1`: FAIL - validator gap stale paths trong history/task-skill NanoBio cu (`docs/supabase/seed_data.sql`, `docs/supabase/setup.sql`, migration SQL va tai lieu Nabi character).
- `python3 tools/validate_docs_source_truth.py`: FAIL - project thieu `docs/audit/source_truth_manifest.json`.
- `git diff --check`: PASS (se chay lai sau khi cap nhat worklog/context history).

## Loi/Rui ro

- Da fix: chuoi timestamp idempotent khac nhau tren PostgreSQL do timezone; test fixture concurrency khong tu tao schema; ownership test sleep safety duoc doi sang kiem tra no-op dung source RPC.
- Chua fix: nhieu RPC app/Admin Web van `PARTIAL` hoac `NOT_YET_PORTED`; xem `backend/contracts/supabase-rpc-mapping.md`. Cloud snapshot chua thay the relational side effects, subject/reward logic.
- Can kiem tra tiep: port cac contract Sale, wellness/reward va cac RPC Admin con lai; cap nhat app/Admin Web/website o phase rieng; danh gia security va deployment tai Ubuntu environment thuc.
- Root context validator va source-truth validator chua xanh vi cac loi tham chieu/manifest ngoai pham vi backend; khong tu y sua cac tai lieu cu khong lien quan.

## Ty le hoan thanh

- Hoan thanh: core backend self-hosted, migration, cac Edge Function route da cau hinh, 4 RPC FamilyPlus va nhung RPC/module khac da danh dau trong inventory.
- Dang do: chua thay the toan bo 38 app RPC va toan bo Admin Web RPC; app/web chua doi endpoint; chua deploy va chua import tai khoan/data Supabase.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot cho nen tang BE va cac contract da port; con gioi han ro rang o nhom RPC chua port.
- Muc do hoan thanh task: chua full theo muc tieu thay the moi luong Supabase; da hoan thanh core, 19 Edge Function API va mot phan RPC (bao gom FamilyPlus).
- Bang chung kiem chung: 15 API tests tren SQLite; 16 tests tren PostgreSQL 17; Alembic head/check, Ruff, mypy va backend context validator PASS.
- Diem ton token/chua toi uu: can map tung RPC va PostgREST call vao source tables/functions de chia phase Sale, wellness/reward va Admin.
- Cach toi uu cho phien sau: port theo domain, lay SQL source va app callsite lam contract, them migration/test isolation truoc khi cong bo API.
- Task-skill can doc lan sau: `.codex/task-skills/coding.md`
