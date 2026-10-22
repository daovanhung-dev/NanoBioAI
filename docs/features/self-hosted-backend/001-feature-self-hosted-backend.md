Commit de xuat: feat(backend): them backend NanoBioAI tu host

# NanoBioAI self hosted backend

## Muc tieu

Tao backend FastAPI modular monolith de NanoBioAI co the chay tren Ubuntu va PostgreSQL do du an quan ly. Backend la dau moi cho cac luong Supabase da duoc port trong phase nay. Phase nay chi tao backend va context; app Flutter, Admin Web va website chua duoc chuyen sang goi API moi.

## Kien truc

- Composition root FastAPI tai `backend/src/nanobio_backend/main.py`; API v1 duoc lap tu router modules.
- Core gom typed environment settings, SQLAlchemy sync session, transaction helper, trace middleware, response envelope, error mapping va JWT security.
- Modules tach `router.py`, `models.py`, `validate.py`, `query.py`, `view.py` theo trach nhiem; migration Alembic tao schema PostgreSQL moi.
- PostgreSQL native tren Ubuntu la runtime database mac dinh. Secret di qua environment/secret store; upload ghi vao local root da cau hinh.
- `backend/.agents/` la context chinh cho BE. `.codex/AGENTS.md`, `PROJECT_MAP.md` va domain backend tro agent vao context nay. Worklog van dung `docs/worklog/` cua NanoBio.

## API da co

- Chuyen 19 Edge Function da duoc cau hinh thanh route BE; hai endpoint AI legacy duoc khai bao nhung tra `503 FEATURE_NOT_ENABLED` vi AI inference van chay tren thiet bi.
- Co first party phone/password Auth voi Argon2id, access JWT va refresh token rotation.
- Co API profile, membership, manual membership payment, Google Play verification, cloud snapshot, account deletion, Admin account/membership, early access, AI content report, food evidence, sleep safety va storage `sale-payout-proofs`.
- Port RPC FamilyPlus cho context, group va member; signup tao self health subject. Cac thao tac kiem tra paid plan, owner subject va gioi han member.
- Payment manual lay gia va tai khoan ngan hang tu environment. Duyet chuyen khoan can reviewer co role, ly do, idempotency key va xac nhan doi soat; cap entitlement trong transaction.
- File upload co owner check, MIME/signature validation va local storage.

## Contract va gioi han

`backend/contracts/supabase-function-mapping.md` ghi du 19 function da cau hinh va sau thu muc empty `NOT_FOUND`. `backend/contracts/supabase-rpc-mapping.md` doi chieu 38 app RPC cung RPC Admin Web dong; cac muc `PARTIAL` va `NOT_YET_PORTED` o do la trang thai that cua implementation, khong phai API da hoat dong.

Cloud snapshot hien la allowlisted per-user JSON snapshot, chua thay the cac side effect quan he/subject/reward cua RPC Supabase. Sale, wellness/reward va nhieu thao tac Admin Web con duoc danh dau chua port. Khong tao route placeholder cho cac contract nay.

Hai thu muc Edge Function khong duoc bat; khong goi Gemini tu server. Sau thu muc function empty khong co source nen khong tao API tu suy doan. Tai khoan/dataset Supabase hien tai khong duoc import.

## Van hanh Ubuntu

`backend/README.md` huong dan cai Python/uv va PostgreSQL native, tao database/user, cau hinh environment, migrate, chay bang systemd, health check va backup. `backend/systemd/nanobio-backend.service` la unit tham khao. Chua deploy len Ubuntu server.

## Kiem chung

- Unit/API suite mac dinh: SQLite tam thoi; PostgreSQL suite bat qua `NANOBIO_TEST_DATABASE_URL` chi khi URL tro toi loopback database disposable co ten chua `test`.
- Migration duoc chay tren PostgreSQL 17 tam thoi rong; `alembic check` khong phat hien thay doi schema chua co migration.
- Khong chay test voi production database; khong import user/payment/health data that.

## Nguon tham chieu

- `docs/context/Backend_Agent_Context_Reusable/README.md`
- `docs/supabase/README.md`
- `docs/supabase/01_build_system.sql`
- `Study2Work/apps/study-server/` chi la tham chieu phan tang; khong copy domain, schema hay secret.
