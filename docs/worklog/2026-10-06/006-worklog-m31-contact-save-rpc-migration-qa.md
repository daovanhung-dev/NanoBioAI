Commit de xuat: fix(m31): apply contact RPC migration to QA

# Worklog — M31 thiếu migration RPC lưu liên hệ

## Phạm vi

- Loại task: bugfix / Supabase schema / Android QA.
- Module chính: M31 `SLEEP_SAFETY_MONITORING`.
- Yêu cầu: xác định vì sao app không lưu được contact và áp dụng migration QA
  đã được người dùng cho phép.

## Đã làm

- Xác nhận app datasource gọi `upsert_sleep_safety_contact` bằng overload 8
  tham số. Trước thao tác, linked remote history có hai migration M31 và thiếu
  `20261006110000_m31_unverified_voice_alert.sql`.
- Người dùng xác nhận project ref `rnwohifdnylqfofkydfl` là QA/staging. Supabase
  project listing, local `.env` và APK ban đầu nhất quán với ref đó.
- Kiểm tra đường khôi phục: staging không có PITR/physical backup; migration
  dùng transaction, chỉ thêm cột/RPC và không cập nhật contact rows. Recovery
  là forward-fix.
- Áp dụng duy nhất migration 11:00 bằng workflow có version. Không dùng
  canonical rebuild/seed script, không đổi flags, không deploy Edge Function,
  không sửa production.
- Truy vấn chỉ đọc xác nhận `allow_unverified_voice_alert` là boolean,
  `NOT NULL`, default `false`; overload RPC 8 tham số có mặt; execute được cấp
  cho `authenticated` và `service_role`, bị từ chối với `anon`.
- Trên Android, danh sách contact ban đầu hiển thị `0/3`; APK `1.0.1+4` trùng
  byte-for-byte với build debug hiện có.

## Kiểm chứng

- Flutter focused M31 suite (controller, repository, model, recovery UI, phone
  contract, SQLite v26/v27 và Supabase SQL contract): **33/33 PASS**, Flutter
  3.47.1 / Dart 3.13.1, `--no-pub`.
- Targeted `flutter analyze --no-pub`: **10 mục, 0 issue**.
- Supabase migration list sau apply: ba migration M31 có remote version tương
  ứng; migration 11:00 không còn pending.
- Remote schema/RPC/grants query: PASS, chỉ đọc.
- `git diff --check`: PASS after documentation updates.

## Phần chưa nghiệm thu và sự cố trong quá trình kiểm tra

- ADB `input tap` và Android UIAutomator đều bị từ chối với
  `INJECT_EVENTS`. Không lưu contact thử vì không thể bảo đảm dọn chính xác qua
  UI; chưa có xác nhận contact xuất hiện sau lưu/tải lại.
- Integration test tạm khởi động Gradle build nhưng lỗi trong bootstrap/
  teardown. Runner đã gỡ package app; đã cài lại APK ban đầu đã capture và xác
  nhận hash khớp. Dữ liệu app cục bộ/session có thể đã bị xóa; màn hình sau khi
  mở lại còn ở trạng thái “đang chuẩn bị tài khoản”.
- Khi thử scrcpy, UI hiển thị độ nhạy đổi từ “Cân bằng” thành “Thấp”. Không thể
  khôi phục bằng thao tác UI do hạn chế input; không xác minh preference cloud.
  Cần người vận hành đăng nhập QA, kiểm tra lại độ nhạy, rồi thực hiện save,
  reload và delete contact giả qua UI.
- Không contact, OTP, cuộc gọi, Edge dispatch, production write hay flag change
  nào được thực hiện.

## File ghi nhận

- `docs/fixbug/sleep-safety-contact/004-fixbug-m31-contact-save-rpc-migration-qa.md`
- `docs/features/m31-unverified-voice-alert/001-feature-m31-unverified-voice-alert.md`
- `docs/DD/sleep_safety_monitoring/README.md`
- `docs/checklist/checklist_complete_DD.md`
- `docs/checklist/checklist_task_coding.md`

## Tự đánh giá

- Root deployment gap đã được sửa và quyền RPC được xác minh.
- End-to-end contact acceptance còn mở do Android chặn input; không suy diễn từ
  schema hoặc unit tests sang lưu contact thật.
- Cần cải thiện trước lần sau: xác nhận đường UI input hoạt động trước khi thử
  thay đổi bất kỳ setting nào; không chạy integration runner trên profile thiết
  bị có session người dùng nếu chưa có cơ chế bảo toàn dữ liệu.
