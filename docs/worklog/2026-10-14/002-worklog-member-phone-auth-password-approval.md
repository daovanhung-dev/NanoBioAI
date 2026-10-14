Commit de xuat: feat(auth): dung phone login va Admin duyet doi mat khau

# Worklog - Member Phone Auth And Password Approval

## Thoi gian

- Ngay: 2026-10-14
- Bat dau: trong phien hien tai; moc gio bat dau khong duoc ghi nhan chinh xac
- Ket thuc: 16:35
- Timezone: Asia/Ho_Chi_Minh

## Pham vi

- Loai task: Coding, migration source, targeted tests, project docs.
- Module chinh: M05 `AUTH_PROFILE_SYNC`, Supabase auth/admin provisioning.
- Yeu cau goc: member dang nhap/dang ky bang SĐT; moi doi/reset mat khau can Admin duyet; chi thay doi source va migration trong repo, khong thao tac Supabase live.

## Da lam

- Doi member signup/login sang phone/password chuan hoa Vietnam `+84`; bo email khoi form member. Admin staff van dung email, email cu duoc giu lam du lieu lien he.
- Chuyen tao tai khoan don/lo sang bat buoc SĐT, email lien he tuy chon va kiem tra trung theo phone.
- Settings va Quen mat khau chi gui yeu cau duyet; Edge Function tu xac minh session, tra phan hoi chung cho so khong ton tai, chong spam/trung yeu cau va khong nhan password hay `user_id` tuy y tu client.
- Them Admin Web queue, ly do bat buoc, xac nhan da doi chieu SĐT dang ky, idempotency, audit; mat khau tam ngau nhien rieng cho moi lan duyet chi hien mot lan, bat buoc doi truoc khi mo app.
- Them additive migration va dong bo dung khoi nay vao canonical rebuild. Private tables/RPC khong mo quyen truc tiep cho client; trigger chan doi password ngoai permit duyet va chi danh dau hoan tat sau khi Auth password thuc su doi.
- Them cong cu chuyen tai khoan cu mac dinh dry-run; chi nhung tai khoan member co SĐT hop le, duy nhat moi duoc chuyen. Apply yeu cau xac nhan sandbox/ref nhieu lop, giu Auth ID/password/email/role/du lieu khac; dong Auth phone co the duoc Auth trigger dong bo sang profile. Tai khoan loi/trung/Admin/dual/orphan duoc de manual review.
- Khoa SĐT dang nhap theo Supabase Auth: bo phone khoi Admin va profile edit, loai khoi cloud snapshot allowlist, them privilege boundary trong SQL va wrapper RPC trong migration de strip phone truoc logic snapshot hien co. Them contract tests cho cac duong ghi nay.
- Cap nhat fixture, Supabase config source, DD M05, checklist, OPEN_RISKS va worklog/history.

## File code/docs da sua

- `lib/app_versions/v2/features/auth/`, `lib/app_versions/v2/router/`, `lib/core/constants/routes/auth_route_paths.dart` - member auth phone, password gate va route constants.
- `lib/app_versions/v1/features/settings/`, `lib/app_versions/v1/router/v1_route_guards.dart`, `lib/services/supabase/auth/` - password request tu Settings, auth error va account-security boundary.
- `admin-web/src/` - API/types/UI queue duyet password; provisioning don/lo theo SĐT.
- `supabase/functions/` - member password request, Admin approval va provisioning; tests tuong ung.
- `supabase/scripts/member-phone-migration*.ts` - phan loai va migrate co guard sandbox; khong chay len Supabase trong phien.
- `supabase/migrations/20261014090000_member_phone_password_approval.sql`, `docs/supabase/01_build_system.sql`, `docs/supabase/02_seed_data.sql`, `supabase/config.toml` - migration, canonical contract, seed/Auth config source.
- `docs/DD/auth_profile_sync/`, `docs/checklist/`, `.codex/history/OPEN_RISKS.md`, `docs/supabase/README.md` - cap nhat source/evidence backlog.

## Tai lieu lien quan

- Approved implementation plan: member phone/password Auth; Admin email boundary; no-OTP signup; Admin-reviewed password changes; random one-time temporary password; sandbox-only migration verification.
- `.codex/workflows/coding.md`, `.codex/task-skills/coding.md`, `.codex/domains/access-membership-referral.md`, `.codex/history/LEARNED_SKILLS.md`, `docs/supabase/README.md`.

## Commands

- `dart format --set-exit-if-changed <changed Dart files>`: PASS - 39 files, 0 changed.
- `flutter analyze <4 affected source/test paths>`: PASS - no issues.
- Focused `flutter test` run across auth, authenticated cloud sync, cloud sync contract, composed route guard, Supabase auth, and member-phone SQL contract: PASS - 62 tests.
- `PATH=<Node 24> npm run typecheck && npm test` in `admin-web`: PASS - typecheck and 67 tests.
- `deno test --allow-env --allow-net <4 Edge handler suites + migration script tests>`: PASS - 31 tests.
- `deno check <4 Edge entrypoints + migration script/core>`: PASS.
- `deno fmt --check <15 changed TypeScript files>`: PASS.
- Canonical member-phone SQL/migration parity check and `git diff --check`: PASS.
- `pwsh -NoProfile -ExecutionPolicy Bypass -File .codex/tools/update_worklog_learning.ps1`: PASS - refreshed 19 deterministic history/task-skill files.
- `pwsh -NoProfile -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1`: FAIL - pre-existing missing `docs/audit/source_truth_manifest.json` and stale paths in historical `.codex/history`/Nabi task-skill files; no new stale path from this worklog was reported.
- Dart MCP DTD discovery: PASS; no Flutter app was connected, and an explicit hot-reload attempt confirmed that no app connection exists. Desktop/web targets are available, but no app was launched; device/runtime smoke remains unavailable. Dart MCP `analyze_files` returned `No roots set`; the equivalent targeted Flutter analyzer passed.
- Supabase sandbox/live SQL, Auth Dashboard settings, Edge deployment/secrets, Android/iOS device acceptance: NOT RUN; no live DB operations were made.

## Loi/Rui ro

- Da fix: loi cu phap tren Settings sheet; route confirm email con sot trong V1 guard; test/auth fixture cu con ky vong email; canh bao Material cua terms checkbox; SQL canonical mismatch va privilege revoke qua rong da duoc thu hep ve ba bang password approval.
- Chua fix: khong co blocker source/test con lai trong pham vi. Supabase SQL/RLS/trigger, phone Auth config, HMAC secret, session revoke, Admin approval va forced-change can duoc smoke tren sandbox. Context-integrity validator van bao missing source-truth manifest va stale historical links ngoai pham vi.
- Can kiem tra tiep: verify hosted `enable_confirmations=false`, dat `PASSWORD_REQUEST_RATE_LIMIT_HMAC_KEY` (toi thieu 32 ky tu), chay dry-run va migration guarded tren sandbox, kiem tra RLS/idempotency/replay/session revocation va hoan tat password change tren Android.

## Ty le hoan thanh

- Hoan thanh: 100% source/migration/docs va targeted local test trong pham vi duoc phe duyet.
- Dang do: hosted config/deploy, database sandbox acceptance va device/runtime smoke.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - source flow, Admin/API contracts, additive migration va local evidence duoc dong bo; khong claim live/sandbox/device acceptance.
- Muc do hoan thanh task: hoan tat phan repo; external acceptance con mo theo ke hoach.
- Bang chung kiem chung: 62 focused Flutter tests; 67 Admin Web tests; 31 Deno tests; targeted Flutter analyzer, Deno formatting/type checks, va canonical SQL parity deu pass.
- Diem ton token/chua toi uu: mot lan formatter/test ban dau phat hien contract tests cu va route helper dang de trong; da cap nhat tests/guard truoc khi chay lai.
- Cach toi uu cho phien sau: dung migration dry-run truoc, chot sandbox ref va hosted config rieng, roi ghi evidence cho tung buoc SQL/RLS/Edge/device.
- Task-skill can doc lan sau: `.codex/task-skills/coding.md`.
