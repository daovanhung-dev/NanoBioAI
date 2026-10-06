Commit de xuat: fix(m31): huong dan khoi phuc khi chua xac minh lien he

# Worklog — M31 khôi phục hỗ trợ khi thiếu liên hệ xác minh

## Thời gian

- Ngày: 2026-10-06
- Bắt đầu: khoảng 14:08
- Kết thúc: 14:25
- Timezone: Asia/Saigon

## Phạm vi

- Loại task: bugfix
- Module chính: M31 SLEEP_SAFETY_MONITORING
- Yêu cầu: triển khai luồng recovery cho cảnh báo `verified_contact_required`,
  giữ chính sách contact đã xác minh và không đổi cờ Supabase.

## Đã làm

- Đối chiếu ảnh với code: `Thử gửi lại` lặp cloud dispatch, còn nút gọi thủ công
  yêu cầu contact đã xác minh, contact opt-in và `phone_fallback_enabled=true`.
- Giữ lỗi dispatch typed trong controller; lỗi thiếu contact xác minh dẫn tới
  mở danh bạ. Khi contact được tải lại và xác minh, alert còn hoạt động và người
  dùng có thể chủ động retry.
- Thêm cảnh báo không chặn cho phép tiếp tục giám sát cục bộ khi chưa có contact
  xác minh; hiển thị trạng thái gọi trực tiếp tạm dừng khi runtime flag tắt.
- Không ghi staging/production, đổi flag, gửi OTP, mở dialer hay thực hiện cuộc
  gọi. APK mới chỉ được build, chưa cài lên thiết bị.

## File code/docs đã sửa

- `lib/app_versions/v1/features/sleep_tracking/providers/sleep_safety_controller.dart`
  — giữ dispatch failure typed, chặn retry thiếu điều kiện và mở recovery sau refresh.
- `lib/app_versions/v1/features/sleep_tracking/presentation/pages/sleep_tracking_page.dart`
  — nối callback mở danh bạ và chuyển trạng thái flag.
- `lib/app_versions/v1/features/sleep_tracking/presentation/widgets/sleep_safety_alert_overlay.dart`
  — thay retry bằng CTA xác minh khi `verified_contact_required`.
- `lib/app_versions/v1/features/sleep_tracking/presentation/widgets/sleep_safety_status_card.dart`
  — cảnh báo không chặn và CTA quản lý danh bạ.
- `test/app_versions/v1/features/sleep_tracking/providers/sleep_safety_controller_test.dart`
  — kiểm tra recovery sau xác minh và chặn phone fallback khi contact/flag không đạt.
- `test/app_versions/v1/features/sleep_tracking/presentation/sleep_safety_recovery_ui_test.dart`
  — kiểm tra CTA, retry, call-switch message và start-monitoring warning.
- `docs/fixbug/sleep-safety-contact/003-fixbug-m31-support-recovery-without-verified-contact.md`
  — ghi nhận nguyên nhân và sửa.
- Checklist M31 và feature/DD verification được cập nhật theo bằng chứng mới.

## Kiểm chứng

- M31 focused Flutter suite: PASS 40/40 trên 9 test files; migration test dùng
  symlink SQLite tạm qua `LD_LIBRARY_PATH`.
- Targeted `flutter analyze --no-pub` trên 6 file code/test: PASS, 0 issue.
- `dart format` các file Dart thay đổi: PASS.
- `flutter build apk --debug --no-pub`: PASS; artifact `build/app/outputs/flutter-apk/app-debug.apk`.
- `git diff --check`: PASS.
- `validate_codex_integrity.ps1`: FAIL do thiếu
  `docs/audit/source_truth_manifest.json` và stale paths trong history/task-skill;
  đây là blocker tài liệu có trước, ngoài phạm vi fix M31.
- Android UI acceptance: chưa chạy; shell input bị chặn bởi `INJECT_EVENTS`.

## Rủi ro và phần còn lại

- Gọi trực tiếp trên staging vẫn không khả dụng khi runtime flag đang false; flag
  không được đổi theo phạm vi đã chốt.
- Cần operator hỗ trợ verify một contact và bật staging switch theo quy trình
  riêng trước khi nghiệm thu mở `ACTION_DIAL`. Không thực hiện cuộc gọi thật.
- Android APK chưa cài; smoke UI/device còn pending.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: người dùng được đưa tới bước xử lý đúng thay vì retry lỗi
  không thể tự hết; giữ nguyên trust boundary verified-only.
- Mức độ hoàn thành: source/test/build hoàn tất; device và staging call acceptance
  còn mở theo các gate đã giữ nguyên.
- Bằng chứng: 40 focused tests, analyzer sạch, APK build pass.
- Tối ưu phiên sau: kiểm tra UI cùng operator sau khi staging contact được xác
  minh và runtime switch được bật; không chạy integration runner đã từng reset
  session thiết bị.
- Task-skill cần đọc lần sau: `.codex/task-skills/bugfix.md`.
