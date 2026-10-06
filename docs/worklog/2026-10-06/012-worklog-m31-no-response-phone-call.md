Commit de xuat: fix(m31): goi lien he tai may sau 15 giay khong phan hoi

# Worklog — M31 gọi liên hệ tại máy sau 15 giây

## Thời gian

- Ngày: 2026-10-06
- Bắt đầu / kết thúc: Không ghi nhận chính xác / 22:00 Asia/Ho_Chi_Minh
- Múi giờ: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: bugfix / M31 `SLEEP_SAFETY_MONITORING`.
- Yêu cầu: thay timeout no-response 15 giây từ voice/SMS backend dispatch sang
  gọi cục bộ liên hệ ưu tiên; giữ cảnh báo nếu không thể bàn giao.

## Đã làm

- Dùng chung một controller handler cho native `escalationRequired` và snapshot
  `escalating`; Android gọi trực tiếp khi có quyền, fallback sang dialer; iOS
  mở `tel:` qua gateway.
- Chọn liên hệ ưu tiên đang hoạt động đã đồng ý nhận cuộc gọi; Android/iOS vẫn
  tuân thủ quyền và bước xác nhận của hệ điều hành.
- Lưu trạng thái timeout/handoff cục bộ, khử trùng lặp theo event ID, không xác
  nhận cuộc gọi đã kết nối. Retry cũ no-response được dừng tại máy; timeout mới
  không gọi dispatcher và không tạo outbox retry.
- Thêm thao tác lưu event cục bộ cho khôi phục snapshot thiếu event; không đổi
  API, schema hoặc giá trị `escalation_status`.
- Sau khi xem ảnh kiểm thử, xác định runtime flag `phone_fallback_enabled=false`
  là nguyên nhân chặn đường gọi. Bỏ việc đọc flag khỏi query config và bỏ mọi
  gate UI/controller; flag cũ không còn điều khiển cuộc gọi local.
- Cập nhật BD M31 v1.3, DD hiện hành, changelog và fixbug; bổ sung controller,
  UI và kiểm tra gateway/native contract.

## File code/docs đã sửa

- `lib/app_versions/v1/features/sleep_tracking/providers/sleep_safety_controller.dart` — gọi timeout cục bộ, recovery/dedupe và dừng retry cũ.
- `lib/app_versions/v1/features/sleep_tracking/domain/repositories/sleep_safety_repository.dart` — khai báo lưu event local-only.
- `lib/app_versions/v1/features/sleep_tracking/data/repositories/sleep_safety_repository_impl.dart` — hiện thực lưu event không đồng bộ cloud.
- `lib/app_versions/v1/features/sleep_tracking/presentation/pages/sleep_tracking_page.dart` — nối trạng thái timeout/retry vào cảnh báo.
- `lib/app_versions/v1/features/sleep_tracking/presentation/widgets/sleep_safety_status_card.dart` — bỏ cảnh báo sai rằng auto-call bị tạm dừng theo cờ hệ thống.
- `lib/app_versions/v1/features/sleep_tracking/data/datasources/sleep_safety_cloud_datasource.dart` — không đọc cờ phone fallback trong runtime-config query.
- `lib/app_versions/v1/features/sleep_tracking/presentation/widgets/sleep_safety_alert_overlay.dart` — copy, retry và phản hồi khi handoff lỗi.
- `test/app_versions/v1/features/sleep_tracking/providers/sleep_safety_controller_test.dart` — ưu tiên, dedupe, retry chủ động, flag, quyền, thiếu contact, iOS, OK/help.
- `test/app_versions/v1/features/sleep_tracking/presentation/sleep_safety_recovery_ui_test.dart` — trạng thái lỗi và hành động thủ công.
- `docs/BD/sleep_safety/BD_NanoBio_Sleep_Safety_M31_v1.3.md`, `docs/DD/sleep_safety_monitoring/` — hợp đồng timeout local phone, giữ API/schema cũ.
- `docs/fixbug/m31-alert-call-handoff/001-fixbug-m31-alert-call-handoff-15s.md` — bổ sung hành vi thay thế và giới hạn nghiệm thu.

## Tài liệu liên quan

- BD: `docs/BD/sleep_safety/BD_NanoBio_Sleep_Safety_M31_v1.3.md`
- DD: `docs/DD/sleep_safety_monitoring/README.md`, `Overall.md`, `List_Features.md`, `Function_List.md`, `Views.md`, `Import_File.md`, `diagrams/README.md`, `history/CHANGELOG.md`
- Fixbug: `docs/fixbug/m31-alert-call-handoff/001-fixbug-m31-alert-call-handoff-15s.md`

## Commands

- `dart format` trên 7 file Dart liên quan: PASS.
- `flutter test` controller: PASS, 23/23.
- `flutter test` UI recovery, alert overlay, native phone contract và state-machine timer: PASS, 16/16.
- Flutter 3.35.2 / Dart 3.9.0 test attempt: FAIL trước khi nạp test vì package cache yêu cầu Dart 3.10/3.11; chạy lại với Flutter 3.47.1 / Dart 3.13.1: PASS.
- `flutter analyze --no-pub` trên 7 file Dart: PASS, không còn issue.
- `git diff --check`: PASS.
- `pwsh -NoProfile -File .codex/tools/validate_codex_integrity.ps1`: FAIL do thiếu `docs/audit/source_truth_manifest.json` và stale paths có sẵn trong `.codex/history/WORKLOG_2026-08-16_meal_nutrition_estimation.md` cùng `.codex/task-skills/nabi-character/SKILL.md`; không liên quan đến M31.
- `pwsh -NoProfile -File .codex/tools/update_worklog_learning.ps1`: PASS; refresh 19 deterministic history/task-skill files, bao gồm worklog index.

## Bổ sung sau ảnh kiểm thử — 2026-10-06

- `dart format` 6 file Dart liên quan: PASS.
- Controller regression suite: PASS, 23/23; runtime flag giả lập `false` vẫn
  bàn giao cuộc gọi local một lần tới liên hệ ưu tiên và không tạo dispatch/
  retry backend.
- UI recovery, alert overlay, native phone contract và state-machine timer:
  PASS, 16/16; timer vẫn hết hạn ở 15 giây và không có nhắc ở giây 30.
- `flutter analyze --no-pub` trên 6 file Dart liên quan: PASS, 0 issue.
- `flutter build apk --debug --no-pub`: PASS; chỉ có cảnh báo tương lai về
  phiên bản Gradle, Android Gradle Plugin và Kotlin hiện dùng.
- `.codex/tools/validate_codex_integrity.ps1`: FAIL do thiếu manifest nguồn và
  một số đường dẫn cũ trong history/task-skill ngoài phạm vi; validator không
  báo lỗi đường dẫn M31 mới.
- Không thực hiện cuộc gọi thật hoặc cài bản mới lên thiết bị; chỉ build APK để
  tránh tác động phiên giám sát và không kích hoạt cuộc gọi tự động ngoài ý muốn.

## Lỗi / rủi ro

- Đã fix: timeout gửi backend và retry có thể tạo cuộc gọi voice/SMS thay vì
  mở ứng dụng Điện thoại; snapshot lặp có thể phát lại hành động.
- Chưa fix: không có xác nhận iOS physical-device; Android permission/dialer và
  cuộc gọi thật không được thao tác trong lượt này.
- Cần kiểm tra tiếp: nghiệm thu trên thiết bị xác nhận OS handoff tắt chuông,
  giữ monitoring; iOS có thể yêu cầu người dùng xác nhận `tel:`.

## Tỷ lệ hoàn thành

- Hoàn thành: code, regression tests, analyzer và tài liệu.
- Đang dở: validator còn lỗi inventory/path cũ ngoài phạm vi; xác minh thiết bị chưa thực hiện.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt — timeout và restore dùng cùng route, có dedupe lưu cục bộ và giữ alert khi lỗi.
- Mức độ hoàn thành task: code/tests/docs hoàn thành; nghiệm thu thiết bị chưa thực hiện.
- Bằng chứng kiểm chứng: 41 test liên quan PASS; analyzer 6 file sạch, APK
  debug build PASS, diff check PASS; không có cuộc gọi thật.
- Điểm tốn token/chưa tối ưu: lần chạy Flutter đầu ghép SDK Dart 3.9 với package cache mới hơn.
- Cách tối ưu cho phiên sau: dùng trực tiếp `/home/daovanhung/development/Flutter/flutter/bin/flutter` của workspace.
- Task-skill cần đọc lần sau: `.codex/task-skills/bugfix.md`
