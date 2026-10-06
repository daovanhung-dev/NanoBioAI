Commit de xuat: docs(worklog): ghi nhan phien nanobio-early-access-customer-admin

# Worklog - NanoBio Early Access va Admin thong tin su kien

## Thoi gian

- Ngay: 2026-10-07
- Bat dau: khoang 01:20
- Ket thuc: 01:41
- Timezone: Asia/Ho_Chi_Minh

## Pham vi

- Loai task: web, Supabase, Edge Functions, migration, production deploy va smoke test
- Module chinh: Admin Web NanoBio Early Access
- Yeu cau goc: thu thap thong tin khach hang, ghi Supabase, tra APK sau khi ghi nhan va cho phep Admin xem/cap nhat lead.

## Da lam

- Mo rong form public gom so dien thoai, ho ten, tuoi, gioi tinh, dia chi va consent; validation tu choi nguoi duoi 18 tuoi.
- Them Edge Function dang ky voi origin allowlist chinh xac, rate limit 10 request/IP/gio, phone HMAC rieng va URL APK chi duoc tra sau khi RPC ghi nhan thanh cong.
- Them trang Admin "Thong tin su kien" co tim kiem, phan trang va cap nhat trang thai; giao dien, Edge Function va RPC deu gioi han role `super_admin`, `support_admin`, `operations_admin`.
- Them audit cho cap nhat trang thai va cron xoa lead da dong qua 12 thang; lead con mo duoc giu lai. Hash chong cap lai uu dai duoc luu trong schema private.
- Cap nhat migration additive, canonical SQL, seed quyen (khong seed lead), privacy page va tai lieu Supabase.
- Tao prerelease GitHub `nanobio-early-access-v1.0.1-build4`, upload APK Android da ky; APK khong duoc them vao Git/Pages.
- Push commit `73193f51` len `main`; GitHub Pages workflow #10 chay thanh cong. Sau do push `6e49241d` de sua nhan/mau trang thai lead; workflow #11 chay thanh cong va Pages phuc vu bundle co nhan `Mới`, `Đã liên hệ`, `Đã đăng ký`, `Đã chuyển đổi`.
- Deploy hai Edge Function len project `rnwohifdnylqfofkydfl`; secrets moi gom origin chinh xac, hai HMAC key rieng va URL Release.
- Production smoke test khong gui dang ky hop le: website hien form moi va privacy page moi; so dien thoai sai bi chan; function tra `INVALID_PHONE`; Admin endpoint voi anon JWT tra `AUTH_REQUIRED`; CORS preflight cho ca hai function tra origin chinh xac; APK tai duoc tu CDN va checksum khop.

## File code/docs da sua

- `admin-web/src/pages/nanobio/*` - form, validation, submit flow va giao dien Early Access.
- `admin-web/src/pages/EventInfoPage.tsx` va `admin-web/src/lib/admin-api.ts` - trang va API xem/cap nhat lead.
- `admin-web/src/App.tsx`, `admin-web/src/components/AdminShell.tsx`, `admin-web/src/types.ts` - route, sidebar va role guard.
- `supabase/functions/register-early-access/*` - validation, persistence, rate limit va URL download.
- `supabase/functions/admin-early-access-leads/*` - JWT, role allowlist, tim kiem, cap nhat va audit.
- `supabase/migrations/20261007000000_nanobio_early_access.sql` - contract Early Access va rate limit.
- `supabase/migrations/20261007130000_nanobio_early_access_customer_admin.sql` - truong khach hang, admin RPC, suppression hash va retention.
- `docs/supabase/01_build_system.sql`, `docs/supabase/02_seed_data.sql`, `docs/supabase/README.md` - canonical contract va huong dan.
- `supabase/tests/early_access_migration_test.ts` va cac test Admin Web/Deno - bao ve contract va hanh vi.
- `docs/worklog/2026-10-07/004-worklog-nanobio-early-access-customer-admin.md` - ket qua phien.

## Tai lieu lien quan

- `.codex/workflows/coding.md`
- `.codex/workflows/supabase-schema.md`
- `.codex/task-skills/coding.md`
- `.codex/task-skills/supabase-schema.md`
- `.codex/DOCS_WORKFLOW.md`

## Commands

- `node node_modules/vitest/vitest.mjs run`: PASS - 61 test Admin Web.
- `node node_modules/typescript/bin/tsc -b && node node_modules/vite/bin/vite.js build`: PASS - build production; chi co canh bao bundle JS lon hon 500 kB.
- `deno test --allow-read supabase/tests/early_access_migration_test.ts`: PASS - 2 migration contract tests.
- `deno test supabase/functions/register-early-access supabase/functions/admin-early-access-leads`: PASS - 13 Edge Function tests.
- `deno check supabase/functions/register-early-access/index.ts supabase/functions/admin-early-access-leads/index.ts`: PASS.
- `apksigner verify --verbose --print-certs` va `aapt dump badging`: PASS - APK co chu ky v2, package `com.nanobioai.app`, version 1.0.1, build 4, minSdk 24.
- GitHub Release HEAD + tai stream checksum: PASS - 155252368 bytes, SHA-256 `bb397535b2b2115cd410415d4438e12807e5d1f6c5bbe2ea74d5e0883f0d0484` khop file local.
- `supabase db push --linked --dry-run --skip-vault`: PASS - chi hai migration moi, khong seed.
- `supabase db push --linked --skip-vault --yes`: PASS - ap dung hai migration additive va cap nhat migration history.
- `supabase functions deploy ... --use-api`: PASS - public function `verify_jwt=false`, Admin function `verify_jwt=true`.
- Remote SQL security checks: PASS - RLS bat; anon/authenticated khong co quyen truc tiep; RPC save chi service role; cron retention hang ngay active; rate-limit cleanup moi 5 phut active; bucket APK khong duoc tao; lead_count=0.
- Production OPTIONS/POST smoke: PASS - CORS exact origin; dang ky so sai tra 400 `INVALID_PHONE`; Admin request bang anon key tra 401 `AUTH_REQUIRED`.
- GitHub Actions workflow #10: PASS - deploy Pages tu commit `73193f51`.
- GitHub Actions workflow #11: PASS - deploy Pages tu commit `6e49241dacfcb9b0f9857a0e61ccc7fcbd396580`; tai HTML va bundle tren Pages xac nhan cac nhan trang thai moi.
- `validate_codex_integrity.ps1`: FAIL - repository validator bao thieu `docs/audit/source_truth_manifest.json` va cac stale path trong worklog meal nutrition cu cung task-skill Nabi; cac file nay khong thuoc thay doi phien.
- `supabase db dump --linked`: khong tao duoc schema snapshot vi Supabase CLI can Docker tai may nay. Trước khi push da xac nhan bang `early_access_leads` chua ton tai va khong co du lieu lead; cac migration la additive va co transaction.

## Loi/Rui ro

- Da fix: route Admin moi bi thieu label trong mot so map TypeScript; test form cap nhat them cac truong bat buoc.
- Follow-up sau review: bo sung map nhan va tone badge cho cac trang thai lead, them assertion UI cho nhan/mau.
- Chua fix: khong tao lead dang ky hop le tren production theo gioi han cua smoke test; do do khong xac nhan live insert, danh sach Admin voi lead that, hoac tai APK thong qua response cua mot lead that.
- Can kiem tra tiep: sau khi co dang ky hop le duoc phep, doi chieu mot lead trong Admin va xac nhan qua trinh cap Plus rieng. URL GitHub Release la cong khai va co the duoc chia se truc tiep theo thiet ke.

## Ty le hoan thanh

- Hoan thanh: code, test local, migrations, secrets, Edge Functions, APK Release, GitHub Pages va production smoke khong tao lead.
- Dang do: chua co ban ghi production hop le de kiem tra luong ghi va xem lead that end-to-end.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - validation, phan quyen, retention va duong tai APK co test rieng; production duoc smoke test khong dung PII khach hang.
- Muc do hoan thanh task: production deploy hoan tat; live successful registration chua duoc tao theo dung gioi han test.
- Bang chung kiem chung: 61 Admin Web tests, 15 Deno tests, build, migration/security SQL queries, workflow #10/#11, browser render, invalid submit, auth rejection va APK checksum tren CDN.
- Diem ton token/chua toi uu: browser upload chooser khong mo file chooser; da dung Release API voi cached Git credential ma khong in token. Migration dump can Docker nen khong co snapshot schema.
- Cach toi uu cho phien sau: kiem tra kha nang upload file cua Chrome extension som; neu can schema snapshot, chuan bi pg_dump native/connection an toan truoc gio deploy.
- Task-skill can doc lan sau: `.codex/task-skills/coding.md` va `.codex/task-skills/supabase-schema.md`
