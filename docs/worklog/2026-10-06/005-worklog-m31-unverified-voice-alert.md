Commit de xuat: docs(worklog): ghi nhan M31 voice alert cho lien he pending

# Worklog — M31 gọi cảnh báo cho liên hệ chưa xác minh

## Thời gian

- Ngày: 2026-10-06
- Bắt đầu: khoảng 14:35
- Kết thúc: 14:59
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: coding / Supabase contract / DD cập nhật.
- Module chính: M31 `SLEEP_SAFETY_MONITORING`.
- Yêu cầu gốc: cho phép số pending nhận voice khi chủ tài khoản bật consent
  riêng; SMS/Zalo tiếp tục yêu cầu xác minh; manual dialer vẫn cần thao tác
  người dùng và `phone_fallback_enabled`.

## Đã làm

- Thêm `allow_unverified_voice_alert`, mặc định tắt, vào contact domain/cache,
  form, repository/RPC mapping, SQLite v27 và Supabase canonical source.
- Giữ RPC legacy 5/7 tham số; app dùng overload 8 tham số; thêm migration tiến
  tới mới nhưng không apply lên Supabase.
- Dispatch tức thời và provider callback cho phép voice-only với contact pending
  có consent. Khi voice lỗi/no-answer thì bỏ qua SMS và chuyển sang contact đủ
  điều kiện kế tiếp theo priority.
- Cho phép mở `ACTION_DIAL`/`tel:` chủ động với contact pending khi cài đặt
  contact và cờ hệ thống cho phép; test dùng fake gateway, không mở dialer thật.
- Cập nhật cảnh báo/danh bạ, BD/DD, checklist, feature note và `.codex` SQLite
  version thành v27.
- Giữ các chỉnh sửa worktree chưa commit; không đổi staging/production flags,
  không chạy migration/deploy, không tạo contact hoặc gửi OTP/call.

## File code/docs đã sửa

- `lib/app_versions/v1/features/sleep_tracking/` — consent model/controller/UI,
  RPC serialization và điều kiện manual dial.
- `lib/core/storage/localdb/` — SQLite v27, schema/cache cho consent mới.
- `supabase/functions/sleep-safety-dispatch/` và
  `supabase/functions/sleep-safety-provider-webhook/` — contact eligibility,
  voice-only và cascade sau thất bại.
- `docs/supabase/01_build_system.sql` và
  `supabase/migrations/20261006110000_m31_unverified_voice_alert.sql` — nguồn
  canonical + migration tiến tới; migration chưa áp dụng.
- `test/app_versions/v1/features/sleep_tracking/`,
  `test/core/storage/localdb/migrations/`, `test/docs/` và Edge tests —
  regression tests cho consent/cache/RPC/UI/dialer/cascade.
- `docs/BD/sleep_safety/`, `docs/DD/sleep_safety_monitoring/`,
  `docs/checklist/`, `docs/features/m31-unverified-voice-alert/` và
  `.codex/AGENTS.md`, `.codex/domains/sqlite.md` — đồng bộ policy/progress.

## Tài liệu liên quan

- `docs/features/m31-unverified-voice-alert/001-feature-m31-unverified-voice-alert.md`
- `docs/DD/sleep_safety_monitoring/README.md`
- `docs/checklist/checklist_complete_DD.md`
- `docs/checklist/checklist_task_coding.md`

## Commands

- Flutter focused M31 suite (controller, repository, model, recovery UI,
  manual-call contract, SQLite v26/v27 and Supabase contract), with
  `LD_LIBRARY_PATH=/tmp/nanobio-m31-sqlite:/usr/lib/x86_64-linux-gnu`:
  **PASS 33/33**. The first run found one stale widget assertion; updated it to
  match the revised Vietnamese warning, then reran the full suite successfully.
- `flutter analyze` on M31 feature, SQLite v26/v27 and targeted tests:
  **PASS, no issues** (10 analysis targets).
- `dart format --set-exit-if-changed` on touched M31 Dart sources/tests:
  **PASS, 32 files, 0 changed** on final check.
- `deno test supabase/functions/sleep-safety-dispatch/handler_test.ts supabase/functions/sleep-safety-provider-webhook/cascade_test.ts`:
  **PASS 8/8**.
- `deno fmt --check` on six dispatch/webhook source and test files:
  **PASS**.
- `git diff --check`: **PASS**.
- `pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1`:
  **FAIL on existing repository issues** — missing
  `docs/audit/source_truth_manifest.json` and stale paths in the historical
  `.codex/history/WORKLOG_2026-08-16_meal_nutrition_estimation.md` and
  `.codex/task-skills/nabi-character/SKILL.md`; no M31 worklog path was reported.
- Supabase staging/production migration, Edge deploy, Android build, device
  dialer and real provider call: **SKIPPED**; no live acceptance was requested
  or performed for this source change.

## Lỗi/Rủi ro

- Đã xử lý: pending contact không nhận được SMS/Zalo; asynchronous callback
  cũng không rẽ sang SMS; khi voice thất bại hệ thống tiếp tục tìm contact kế
  tiếp. Manual call không còn phụ thuộc OTP.
- Chưa fix: không có lỗi source còn mở được phát hiện trong kiểm tra mục tiêu.
- Cần kiểm tra tiếp: staging migration/Edge acceptance, Android/iOS dialer
  acceptance với profile test có consent, và provider voice evidence. Các
  staging migrations v1.2 là bằng chứng lịch sử trong checklist/worklog trước;
  phiên này không xác minh lại chúng.

## Tỷ lệ hoàn thành

- Hoàn thành: source, local persistence/API contract, Edge cascade, regression
  tests và tài liệu M31.
- Đang dở: live Supabase migration/deploy và thiết bị/provider acceptance.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt — voice consent tách biệt, default-off, và quy tắc
  voice-only được áp dụng cho cả immediate dispatch lẫn callback bất đồng bộ.
- Mức độ hoàn thành task: source và focused verification hoàn tất; staging,
  provider và thiết bị thật còn pending theo phạm vi đã chọn.
- Bằng chứng kiểm chứng: Flutter 33/33, analyzer sạch, format sạch, Deno 8/8;
  không có xác minh mạng/thiết bị.
- Điểm tốn token/chưa tối ưu: lần test đầu phát hiện matcher cũ; lần đọc focused
  test/UI giúp sửa đúng assertion, không đổi behavior ngoài scope.
- Cách tối ưu cho phiên sau: dùng test danh bạ/RPC có fake controller nếu cần
  mở rộng UI regression; tiếp tục tách local source proof khỏi staging/device.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`.
