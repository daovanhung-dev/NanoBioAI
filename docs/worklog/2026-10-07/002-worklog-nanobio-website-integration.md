Commit de xuat: docs(worklog): ghi nhan phien nanobio website integration

# Worklog - Tích hợp NanoBio Website vào Admin Web và Supabase

## Thoi gian

- Ngay: 2026-10-07
- Bat dau: 00:00
- Ket thuc: 00:17
- Timezone: Asia/Ho_Chi_Minh

## Pham vi

- Loai task: feature/coding/test/docs
- Module chinh: Admin Web public website, Early Access Supabase contract
- Yeu cau goc: hiện thực plan tích hợp bộ website NanoBio vào Admin Web, public
  route, form phone-only, migration additive và Edge Function an toàn.

## Da lam

- Đọc NanoBio project router, coding workflow/task-skill/domain contract và
  Supabase docs liên quan. Giữ nguyên thay đổi Flutter/design và source pack
  website đang có.
- Thêm public routes `/#/nanobio`, `/#/nanobio/privacy` tách khỏi Admin auth;
  thêm Website NanoBio vào sidebar.
- Đưa nội dung website vào route React với Shadow DOM/CSS riêng, đóng gói local
  các ảnh đã duyệt, giữ feature/FAQ/installation/Free-Plus copy, consent/privacy
  nêu rõ metadata được ghi nhận.
- Thêm client typed cho function, xác thực số điện thoại/consent, hiển thị lỗi
  an toàn, loading/retry, ngăn submit lặp, phản hồi chung cho số trùng và không
  đưa link APK giả khi bucket chưa có file.
- Thêm Edge Function `register-early-access`, exact origin allowlist, HMAC IP,
  giới hạn atomic 10 lần/IP/giờ, metadata server-owned/sanitized, insert-ignore
  để duplicate không reset trạng thái Plus.
- Thêm migration additive, private rate-limit schema/cron, bucket APK private,
  cập nhật canonical local/sandbox rebuild, function config, Supabase README và
  rollback-only smoke fixture. Không sửa seed và không ghi remote.
- Thêm UI tests cho routes signed-out/Admin protection, validation, retry,
  double-submit, no-APK và focus trap/restore.

## File code/docs da sua

- `admin-web/src/App.tsx`, `src/main.tsx`, `src/components/AdminShell.tsx` —
  public routes, phạm vi auth Admin và sidebar.
- `admin-web/src/pages/NanoBioLandingPage.tsx`,
  `src/pages/NanoBioPrivacyPage.tsx`, `src/pages/nanobio/` — trang, nội dung,
  style, asset map, phone/client/controller và tests.
- `admin-web/src/assets/nanobio/` — ảnh website được bundle từ local source.
- `admin-web/src/App.test.tsx`, `.env.example`, `src/vite-env.d.ts` — kiểm thử,
  cấu hình publishable và app version.
- `supabase/functions/register-early-access/`,
  `supabase/functions/.env.example`, `supabase/config.toml` — Edge Function,
  validation/rate-limit tests và cấu hình `verify_jwt`.
- `supabase/migrations/20261007000000_nanobio_early_access.sql` — forward
  migration cho bảng lead, grants, rate-limit RPC/cron và APK bucket.
- `docs/supabase/01_build_system.sql`, `docs/supabase/README.md`,
  `test/docs/fixtures/supabase_early_access_smoke.sql` — canonical local/sandbox
  contract, deploy notes và security smoke fixture.
- `docs/features/nanobio-website/001-feature-admin-web-integration.md` — luồng,
  ranh giới bảo mật và trạng thái xác minh.
- `docs/checklist/checklist_task_coding.md` — addendum source/local evidence và
  các việc còn pending.
- `.codex/history/LEARNED_SKILLS.md`, `OPEN_RISKS.md`, `RISK_HISTORY.md`,
  `WORKLOG_INDEX.md`, `.codex/task-skills/README.md`, `supabase-schema.md`,
  `test.md` — cập nhật tự động bởi worklog history refresh.

## Tai lieu lien quan

- `admin-web/docs/nanobio_website/` — website source pack, giữ nguyên.
- `.codex/AGENTS.md`, `.codex/PROJECT_MAP.md`,
  `.codex/workflows/coding.md`, `.codex/task-skills/coding.md`.
- `.codex/domains/access-membership-referral.md`, `docs/supabase/README.md`.

## Commands

- `npm test`: PASS — 46 tests.
- `npm run typecheck`: PASS.
- `npm run build`: PASS; có cảnh báo chunk JavaScript >500 kB.
- `deno fmt --check supabase/functions/register-early-access`: PASS.
- `deno test supabase/functions/register-early-access`: PASS — 8 tests.
- `deno check supabase/functions/register-early-access/index.ts`: PASS.
- `git diff --check`: PASS.
- `pwsh -ExecutionPolicy Bypass -File .codex/tools/update_worklog_learning.ps1`:
  PASS — refresh 7 file history/task-skill có thay đổi.
- `pwsh -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1`:
  FAIL do repo thiếu `docs/audit/source_truth_manifest.json` và các đường dẫn
  cũ trong history/task-skill (`docs/supabase/seed_data.sql`, `setup.sql`, các
  file Nabi_character); validator không báo lỗi từ file website mới.
- Browser responsive/screen-reader review: SKIPPED — không có browser surface
  khả dụng từ CUA trong phiên.
- Supabase migration/function deploy và luồng live: SKIPPED — chưa xác nhận
  backup/khôi phục; không có remote write.

## Loi/Rui ro

- Da fix: các type lỗi form client/observer; kỳ vọng sanitizer test; retry label;
  phone/consent error associations; button double-submit; focus trap/restore.
- Chua fix: browser visual/responsive/render QA không thực hiện được do browser
  provider không có trong phiên; migration SQL chưa được chạy trên sandbox.
- Can kiem tra tiep: Supabase project ref/migration history/recovery ngay trước
  triển khai, secrets và APK private bucket; test route trên GitHub Pages; review
  screen reader, zoom/reflow và APK thật.

## Ty le hoan thanh

- Hoan thanh: code local, unit tests/build/typecheck, Edge handler tests, docs.
- Dang do: Supabase sandbox/remote apply/deploy, APK availability, visual/device
  acceptance và publication.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot/can cai thien - contract server/client rõ, dữ liệu lead
  tối thiểu; browser/render review còn thiếu.
- Muc do hoan thanh task: implementation local hoàn thành; end-to-end remote
  chưa xác minh.
- Bang chung kiem chung: 46/46 Admin tests, typecheck/build PASS, 8/8 Deno
  tests, Deno check và diff check PASS.
- Diem ton token/chua toi uu: CSS nguồn lớn và chunk JS >500 kB; xem xét tối ưu
  lazy bundle/asset sau khi có kết quả tải thực tế.
- Cach toi uu cho phien sau: dùng browser enabled để xác nhận mobile/tablet/
  desktop và live function trong sandbox disposable; không thay evidence bằng
  source inspection.
- Task-skill can doc lan sau: `.codex/task-skills/coding.md`
