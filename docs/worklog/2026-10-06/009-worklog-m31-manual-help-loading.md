# Worklog — M31 sửa loading của yêu cầu gọi hỗ trợ

## Thời gian

- Ngày: 2026-10-06
- Múi giờ: Asia/Ho_Chi_Minh
- Ghi nhận kiểm chứng cuối: 18:29

## Phạm vi

- Loại task: bugfix.
- Module: M31 `SLEEP_SAFETY_MONITORING`.
- Yêu cầu: nút “Tôi cần hỗ trợ” gọi trực tiếp hoặc mở trình gọi, không kẹt
  loading khi cờ gọi tự động tắt hoặc khi hệ điều hành không mở được cuộc gọi.

## Đã làm

- Tách pha `manualHelp` khỏi server dispatch `escalating`; pha thủ công không
  bị countdown tự chuyển sang dispatch.
- Gỡ chặn `phone_fallback_enabled` khỏi yêu cầu chủ động; lựa chọn này không
  đổi luồng tự động khi không phản hồi.
- Hiện trạng thái loading chỉ trong lúc chuẩn bị cuộc gọi. Sau khi Android nhận
  yêu cầu gọi hoặc trình gọi mở, cảnh báo loading đóng; nếu thất bại, cảnh báo
  giữ lại kèm hành động thử lại/mở danh bạ.
- Phục hồi event gọi bị ngắt khi app chạy lại để tránh hiển thị spinner cũ.
- Giới hạn thời gian chờ cho native acknowledgement, lưu event best-effort và
  lệnh mở cuộc gọi để không treo vô thời hạn.
- Cập nhật copy trạng thái hệ thống và tài liệu fixbug/worklog.
- Không đổi schema/API bên ngoài, Edge Function, cấu hình QA/production hoặc
  dữ liệu liên hệ.

## File liên quan

- `lib/app_versions/v1/features/sleep_tracking/domain/services/sleep_safety_state_machine.dart`
- `lib/app_versions/v1/features/sleep_tracking/providers/sleep_safety_controller.dart`
- `lib/app_versions/v1/features/sleep_tracking/presentation/pages/sleep_tracking_page.dart`
- `lib/app_versions/v1/features/sleep_tracking/presentation/widgets/sleep_safety_alert_overlay.dart`
- `lib/app_versions/v1/features/sleep_tracking/presentation/widgets/sleep_safety_status_card.dart`
- `test/app_versions/v1/features/sleep_tracking/providers/sleep_safety_controller_test.dart`
- `test/app_versions/v1/features/sleep_tracking/presentation/sleep_safety_recovery_ui_test.dart`
- `test/app_versions/v1/features/sleep_tracking/sleep_safety_state_machine_calibration_alert_test.dart`
- `docs/fixbug/sleep-safety-contact-dispatch/002-fixbug-m31-manual-help-loading.md`

## Lệnh và kết quả

- `dart format` trên các file Dart liên quan: **PASS**.
- Flutter controller/UI/state-machine tests: **27/27 PASS**.
- Deno `handler_test.ts` và `cascade_test.ts`: **7/7 PASS**.
- Flutter analyze trên 8 file liên quan: **PASS**, 0 issues.
- `flutter build apk --debug --no-pub`: **PASS**.
- `adb install -r build/app/outputs/flutter-apk/app-debug.apk`: **PASS**;
  model `220333QPG`, Android 11, dữ liệu được giữ lại.
- Sau khi mở app, `MainActivity` chạy foreground và logcat không có
  `FATAL EXCEPTION`/`E/flutter`; ảnh fresh từ thiết bị là màn hình đen. Chưa
  thể thao tác UI để xác nhận cuộc gọi thật nên nghiệm thu máy thật chưa đạt.
- `git diff --check`: **PASS**.

## Mức độ hoàn thành

- Hoàn thành: sửa controller/state machine/UI, kiểm thử tự động, phân tích,
  build APK và cài giữ dữ liệu lên máy.
- Chưa xác minh: bấm nút trợ giúp và xác nhận cuộc gọi thật trên Xiaomi; app
  sau khi mở bản debug chỉ hiển thị nền đen trong ảnh chụp.

## Rủi ro còn lại

- Kết quả `startCall` xác nhận Android nhận lệnh khởi tạo, không xác nhận cuộc
  gọi đã kết nối hoặc được bắt máy.
- Cảnh báo Gradle/AGP/Kotlin của Flutter về hỗ trợ sắp tới vẫn hiện khi build;
  build hiện tại thành công.
