Commit de xuat: fix(m31): tat chuong sau khi ban giao goi va cho 15 giay

# Worklog — M31 bàn giao gọi và hạn chờ 15 giây

## Thời gian

- Ngày: 2026-10-06
- Bắt đầu / kết thúc: Không ghi nhận chính xác
- Múi giờ: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: bugfix / M31 `SLEEP_SAFETY_MONITORING`.
- Yêu cầu: dừng tone và notification khi hệ điều hành nhận yêu cầu gọi; giữ
  cảnh báo nếu handoff thất bại; chuyển escalation không phản hồi sang 15 giây.

## Đã làm

- Đồng bộ timer state machine, countdown Flutter, Android foreground service và
  iOS runtime về 15 giây; bỏ reminder 30 giây.
- Bổ sung xử lý handoff theo kết quả mở `ACTION_CALL`, `ACTION_DIAL` và `tel:`;
  chỉ nhánh thành công mới tắt tone/xóa notification. Giữ nguyên session,
  không gọi dispatch cho lượt **Tôi cần hỗ trợ**.
- Bổ sung state-machine/widget/native source-contract coverage.
- Cập nhật BD M31 v1.3, DD M31 hiện hành, changelog, checklist, fixbug và
  worklog.

## Lệnh và kết quả

- `dart format` trên các file Dart đã sửa: PASS.
- `flutter test --no-pub test/app_versions/v1/features/sleep_tracking/presentation test/app_versions/v1/features/sleep_tracking/providers/sleep_safety_controller_test.dart test/app_versions/v1/features/sleep_tracking/sleep_safety_state_machine_calibration_alert_test.dart test/app_versions/v1/features/sleep_tracking/sleep_safety_phone_fallback_contract_test.dart`: **47/47 PASS**.
- `flutter analyze --no-pub` trên 10 file Dart liên quan: PASS, 0 issue.
- `flutter build apk --debug --no-pub`: PASS. Gradle 8.14.0, AGP 8.11.1 và
  Kotlin 2.2.20 phát cảnh báo tương thích tương lai từ Flutter.
- `adb install -r build/app/outputs/flutter-apk/app-debug.apk`: PASS trên
  Xiaomi `220333QPG`, Android 11; package được giữ dữ liệu.
- `git diff --check`: PASS.
- `pwsh -NoProfile -File .codex/tools/update_worklog_learning.ps1`: PASS; cập
  nhật 19 history/task-skill files và worklog index.
- `pwsh -NoProfile -File .codex/tools/validate_codex_integrity.ps1`: FAIL do
  thiếu `docs/audit/source_truth_manifest.json` và các stale path có sẵn trong
  `.codex/history/WORKLOG_2026-08-16_meal_nutrition_estimation.md` cùng
  `.codex/task-skills/nabi-character/SKILL.md`; không liên quan đến M31.
- Khởi chạy activity và chụp màn hình mới: app vẫn hiển thị nền đen. Logcat đã
  lọc không có `FATAL EXCEPTION`, `E/flutter`, `FlutterError` hoặc
  `PlatformException`; màn M31 và trình gọi chưa được thao tác xác nhận.
- Không khởi tạo cuộc gọi thật, không bấm Call, không sửa contact hay cờ QA.
- iOS source/contract đã rà; không có Xcode/iPhone để build/device test.

## Lỗi / rủi ro còn lại

- Nghiệm thu bằng tay trên Xiaomi cho thao tác **Tôi cần hỗ trợ** còn pending vì
  activity hiển thị nền đen, chưa đến được màn hình M31.
- Việc OS chấp nhận `ACTION_CALL`/`ACTION_DIAL`/`tel:` chỉ xác nhận handoff;
  không chứng minh cuộc gọi đã kết nối hoặc được trả lời.

## Hoàn thành

- Source, test, analyzer, APK build và cài giữ dữ liệu đã hoàn tất.
- Device call-handoff acceptance và iOS build/device acceptance chưa hoàn tất.
