Commit de xuat: feat(app): chuyen cac luong NanoBio sang backend tu host

# Worklog - Self-hosted backend cutover

## Thoi gian

- Ngay: 2026-10-30
- Bat dau: khoang 17:00 (Asia/Ho_Chi_Minh)
- Ket thuc: 21:25 (Asia/Ho_Chi_Minh; tiep tuc tu ban ghi 18:28)
- Timezone: Asia/Ho_Chi_Minh

## Pham vi

- Loai task: coding, data migration rehearsal, server inspection va validation.
- Module chinh: Flutter Mobile, Admin Web, FastAPI backend, snapshot Supabase va PostgreSQL server.
- Yeu cau: thuc thi runbook `docs/features/self-hosted-backend/002-feature-client-migration-cutover.md` theo thu tu; khong cutover khi con direct Supabase, chua co HTTPS, chua doi soat/import va chua co admin credential rieng.

## Da lam

- Chuyen mot phan luong Flutter auth/session/password, cloud snapshot sync, membership/quota, payment/Google Play, FamilyPlus, food evidence, AI report va account security sang API FastAPI co version. Them HTTPS-enforcing backend client va luong AI authenticated qua server cho generate/stream/Food Scan; guest/local AI va voice/XiaoZhi tiep tuc local.
- Chuyen Sleep Safety datasource khoi Supabase sang API co auth cho runtime config, contact CRUD/verification, preferences, session/event sync va dispatch. Them model, owner guard, migration `0004_sleep_safety_sync` va composite FK rang buoc event/session cung user.
- Chuyen Admin Web khoi Supabase client/dependency sang BackendClient cho cac luong da co API; bo credential Supabase khoi workflow deploy Admin Web.
- Bo sung backend auth must-change state, migration admin phone/quota va AI text streaming/JSON/vision routes trong checkout. Cai model `qwen3-vl:4b` tren may chu; chua deploy code hoac bat endpoint vision tren service live.
- Tao snapshot Supabase rieng, loai cac truong password hash/session/token khoi cac hang Auth duoc xuat. Sua 50 lenh `auth.identities` de khong ghi cot `email` GENERATED ALWAYS, giu nguyen UUID va identity fields.
- Restore thu thanh cong snapshot trong PostgreSQL 17 co lap: 118 bang, khong loi, khong FK mo coi, khong constraint chua validate. Doi chieu 3 Storage objects: duong dan, kich thuoc va SHA-256 khop 100%.
- Doi chieu 50 users nguon voi DB dich: khong trung UUID/phone/email; 50 health_subjects nguon khong trung UUID voi 1 health_subject dich. Ghi so lieu va blocker vao `docs/audit/SELF_HOSTED_CUTOVER_CONFLICT_REPORT_2026-10-30.md`.
- Tao backup truoc cutover cho DB `nanobio`; giu nguyen `nanobio_legacy`. Khong freeze Supabase, khong chay migration/import vao production va khong deploy client/server.
- Kiem tra service live: health HTTP 200 qua cong 8080; cong 80/443 khong truy cap duoc. DB server van o Alembic `0001_initial`, trong khi checkout co migration moi; khong co HTTPS tin cay de cutover.

## File code/docs da sua

- Flutter: `lib/core/network/`, auth/session, cloud sync, membership/quota, payments, FamilyPlus, settings, AI provider/client va Food Scan.
- Backend: auth/security, cloud sync, membership, payment, AI/Ollama, request limit, model va Alembic migrations `0002`/`0003`/`0004`.
- Admin Web: backend client/auth/config/API, early access page/tests, package dependency va deployment workflow.
- Test: contract/API tests cho auth, account lock, cloud sync, payments va AI backend client.
- Docs: `docs/features/self-hosted-backend/002-feature-client-migration-cutover.md`, `docs/audit/SELF_HOSTED_CUTOVER_CONFLICT_REPORT_2026-10-30.md` va worklog nay.

## Commands va bang chung

- `flutter test` tren auth, cloud sync, payments, FamilyPlus, config, account lock va backend AI: PASS, 114 tests.
- `flutter test test/app_versions/v1/features/ai_chat/ai_chat_thinking_phrase_test.dart`: PASS, 5 tests.
- Sleep Safety backend ownership API va Flutter backend datasource tests: PASS; bo test domain co 67 pass va 1 contract fail cu do con mong SQLite version 24 trong khi current version la 36.
- `dart analyze` tren toan bo Dart source/test da sua: PASS, khong loi.
- `backend/.venv/bin/ruff check src tests`: PASS.
- `backend/.venv/bin/pytest -o addopts='' -q`: PASS, 61 passed, 2 PostgreSQL-only skipped; co mot deprecation warning tu Starlette/httpx.
- Alembic `0004_sleep_safety_sync` upgrade va `alembic check`: PASS tren PostgreSQL 17 fresh schema va schema cu `0003` mo phong.
- Admin Web trong cung task: 62 tests, TypeScript build va Vite build PASS.
- PostgreSQL restore rehearsal: PASS; 118 bang, 0 FK orphan, 0 constraint chua validate.
- Storage doi chieu: PASS, 3/3 path/size/SHA-256 khop; tong 1,593,111 bytes.
- `git diff --check`: PASS.
- Full `flutter analyze`: chi con warning `use_build_context_synchronously` tai dashboard page khong thuoc file sua; duplicate import trong Food Scan prompt da duoc bo. `dart analyze` tren tat ca file Dart da sua PASS.
- `validate_codex_integrity.ps1`: FAIL vi thieu `docs/audit/source_truth_manifest.json` va con 9 stale path trong hai tai lieu cu khong thuoc pham vi; ba path auth/sync bi stale do thay datasource trong `.codex/Design_NaBi_Green_Wellness.md` da duoc cap nhat.
- Live network probe: port 8080 open va health 200; ports 80 va 443 closed.

## Trang thai ghi nhan tai 18:28 (lich su; duoc cap nhat o phan tiep theo)

- Flutter van con direct Supabase o Admin Mobile, wellness rewards/rank, sale/referral va payout/storage review. Sleep Safety datasource da chuyen sang backend trong checkout. Admin Web con cac thao tac sales/reconciliation/reward/dashboard chua du backend API.
- Snapshot API va Alembic schema chua thay the day du RPC/relational semantics cho wellness/reward, sale/referral va Admin. Sleep Safety co owner-scoped write sync nhung chua co history read/import route. Chua co importer du lieu san sang cho toan bo 50 user/role va cac bang lien quan.
- Chua nhap production data vi bao cao va migrations chua duoc duyet; chua tao credential rieng cho admin va chua write-freeze Supabase.
- HTTPS IP certificate chua the cap/kiem chung do cong 80/443 khong truy cap duoc tu Internet. Can mo forwarding/firewall o lop mang phia truoc may chu truoc khi cau hinh Certbot/Nginx.
- Snapshot `.sql.gpg` chua duoc tao: lenh GPG da dung sau khi user hoi co the bo passphrase khong; may khong co GPG recipient key san. Khong ghi passphrase vao worklog, khong tao khoa mac dinh yeu. Plain SQL va Storage export van nam trong staging rieng voi quyen han che; khong xoa cho den khi artifact ma hoa co the khoi phuc hoan tat.
- Khong deploy backend code hoac migrations len server; code live va checkout chua dong bo.

## Ty le ghi nhan tai 18:28 (lich su)

- Hoan thanh: cac luong client/backend da port trong pham vi da liet ke; test local; restore rehearsal; Storage checksum; conflict report.
- Dang do: port tiep RPC/admin/wellness/sale; encrypted SQL artifact; schema/import approval; credential admin; mo HTTPS; deploy, smoke test thuc va cutover. Sleep Safety sync da co trong checkout nhung chua deploy.

## Tu danh gia ghi nhan tai 18:28 (lich su)

- Chat luong dau ra: tot o cac luong da port; chua dat acceptance cua runbook vi con direct Supabase va blocker HTTPS/data import.
- Muc do hoan thanh task: chua hoan tat cutover. Khong co production import, write-freeze, deploy hay client release.
- Bang chung kiem chung: 114 Flutter tests, 5 AI phrase tests, targeted Dart analysis, backend Ruff/pytest, Admin Web test/build, restore/FK/Storage checks va live health/port probe.
- Diem ton token/chua toi uu: full Flutter analyze chay lau va phat hien mot issue dashboard cu ngoai pham vi; lan dau goi sai duong dan AI phrase test va da chay lai dung duong dan.
- Cach toi uu cho phien sau: hoan thien mapping/API cho domain con thieu; lap lai restore va conflict report sau khi code/migration duoc duyet; chi cutover sau khi HTTPS/trusted certificate va admin credential da san sang.
- Task-skill can doc lan sau: `.codex/task-skills/coding.md`

## Tiep tuc thuc hien 21:00, 2026-10-30

### Da lam them

- Chuyen cac luong con lai trong Flutter/Admin Mobile va Admin Web/Early Access sang `BackendApiClient`/`BackendClient`; giu SQLite offline, guest/local AI va voice/XiaoZhi local.
- Chuyen Edge Function, migration va SQL Supabase cu sang `docs/archive/legacy-supabase/`; runtime/build audit khong con SDK, URL/key hay call site Supabase trong 987 file nguon/build. SQL va function lich su van chi doc.
- Bo sung API va migration cho Sale/referral, wellness/rank/reward, Admin business, reconciliation/config/report, sleep-safety sync, quota va storage; them job membership/early-access theo systemd timer.
- Hoan thien luong payment ledger: duyet manual payment tao/cap nhat `payment_events`; referral/Sale active tao commission idempotent theo direct rate va delay 24 gio; refund/cancel tao adjustment am rieng, khong sua commission goc. Sale dashboard dem payment events da thanh cong.
- Them Admin download cho payout proof: chi Finance/Super Admin va chi khi file duoc gan vao Sale conversion. Cap nhat route download tren Admin Web.
- Them `GET /api/v1/sleep-safety/history` voi pagination va owner scoping cho session/event lich su; cap nhat RPC contract map.
- Cap nhat contract map RPC/Admin/storage theo route hien tai va ghi ro cac phan con partial; mapping nay khong thay cho deployment/cutover.
- Them workaround release compile cho plugin `integration_test` dev-only neu generated Android registrant con chua plugin nay; giu generated source sau build.

### Kiem chung tiep tuc

- Backend: Ruff check/format, mypy va toan bo pytest PASS; focused payment + referral commission/reversal va storage/Admin download tests PASS. 2 test PostgreSQL-only duoc skip trong pytest SQLite.
- Sau khi them Sleep Safety history, Ruff, mypy va focused owner-scope API test PASS.
- Admin Web: TypeScript typecheck, 63 Vitest tests va Vite production build PASS.
- `tools/audit_self_hosted_runtime.py`: PASS, 987 runtime/build source files.
- Flutter focused tests da PASS trong phan truoc cua cung task; full Flutter suite da fail voi hon 250 test failures nen khong the xem la full regression PASS.
- Live API `http://42.118.174.147:8080/health/ready`: HTTP 200, DB ready. HTTPS 443: ket noi bi tu choi; khong the xac nhan certificate/reverse proxy.
- `flutter build apk --release --dart-define=API_BASE_URL=https://42.118.174.147`: PASS; APK co chu ky hop le, chua phat hanh. SHA-256 `7f861763c9b779d932b611a5bd620ab2309af9d0b2b1b7df340168b1e9ccf412`.
- APK universal co kich thuoc 641 MiB; gom 3 ABI, 264.6 MiB anh mon an va 302.2 MiB native libraries. Chua toi uu/dong goi split ABI.
- `backend/scripts/validate_agent_context.py`: PASS. `tools/validate_docs_source_truth.py`: FAIL vi thieu `docs/audit/source_truth_manifest.json`.
- Cap nhat cac duong dan Supabase runtime cu trong `.codex/Design_NaBi_Green_Wellness.md`, `.codex/PROJECT_MAP.md`, domain map va access domain sang backend tu host. `validate_codex_integrity.ps1` van FAIL do thieu source-truth manifest va 9 path cu trong worklog lich su/Nabi skill khong thuoc pham vi.
- `apksigner verify`: PASS; khong co entry file ten Supabase; `libapp.so` chua URL `https://42.118.174.147`.

### Trang thai hien tai va gioi han

- Checkout code, API va ban build la pham vi da lam; server production chua deploy code/migration, Supabase chua freeze, snapshot cuoi chua import va APK chua phan phoi.
- Khong xoa staging export truoc cutover/import cuoi. `nanobio_legacy` van duoc giu nguyen.
- Password recovery la Admin reset + buoc doi mat khau; chua co email/SMS recovery provider. Google Play refund khong goi provider refund. Report export moi tao request, chua co worker tao file. Sleep Safety history da co API doc owner-scoped; import du lieu cu van cho final cutover.
- Migration 0006 chua duoc ap dung tren PostgreSQL disposable trong phan tiep tuc nay; pytest SQLite khong thay the bang chung migration PostgreSQL.

### Tu danh gia tiep tuc

- Chat luong dau ra: tot cho luong client/backend da port; van co gioi han parity va operational gate duoc ghi ro trong contract map.
- Muc do hoan thanh: chua hoan tat deployment/cutover. Khong thuc hien production data write, freeze, deploy hay distribution.
- Bang chung: backend lint/typing/pytest, Admin Web typecheck/63 tests/build, runtime audit, focused API tests, APK signature/URL checks va live health/HTTPS probe.
- Diem ton token/chua toi uu: can them mot lan full Flutter regression sau khi tach nhom failure baseline; build Android release lau do compile native.
- Cach toi uu cho phien sau: mo network 443, deploy backend/migrations theo cua so rieng, chay migration tren PostgreSQL disposable truoc; cutover chi sau khi doi soat/import va smoke test.
- Task-skill can doc lan sau: `.codex/task-skills/coding.md`
