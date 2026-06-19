Commit đề xuất: docs(issue): ghi nhận lỗi format dry-run fail ở page mới

# Dart format dry-run fail ở 6 page mới

## Tóm tắt
- `dart format --output=none --set-exit-if-changed .` fail.
- 6 file page mới cần format lại trước release.

## Mức độ ảnh hưởng
- Severity: medium
- Ảnh hưởng user: không trực tiếp.
- Ảnh hưởng dev/build/test: release check/CI fail, khó đóng version 1.0 sạch.

## Cách tái hiện
1. Chạy `dart format --output=none --set-exit-if-changed .`.
2. Command exit code 1.
3. Output báo 6 file `Changed`.

## Đã xác nhận
- Command báo:
  - `lib/features/body_metrics/presentation/pages/body_metrics_page.dart`
  - `lib/features/gentle_care_mode/presentation/pages/gentle_care_mode_page.dart`
  - `lib/features/personal_goals/presentation/pages/personal_goals_page.dart`
  - `lib/features/quick_care/presentation/pages/quick_care_page.dart`
  - `lib/features/water_tracking/presentation/pages/water_tracking_page.dart`
  - `lib/features/weekly_summary/presentation/pages/weekly_summary_page.dart`

## Giả thuyết
- Các file mới được thêm khi môi trường trước đó không có `dart`, nên chưa chạy format thật.

## Workaround
- Không có workaround an toàn nếu CI yêu cầu format.

## Hướng fix đề xuất
- Chạy `dart format` cho 6 file mới.
- Sau đó chạy lại dry-run để xác nhận exit code 0.

## Files/log liên quan
- `lib/features/body_metrics/presentation/pages/body_metrics_page.dart`
- `lib/features/water_tracking/presentation/pages/water_tracking_page.dart`

## Liên kết
- Worklog: ../../worklog/2026-06-19/007-worklog-release-1-0-bug-audit.md
