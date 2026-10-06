Commit de xuat: fix(android): ask runtime permissions at app entry

# Worklog — M31 yêu cầu quyền runtime khi mở Nabi

## Thời gian

- Ngày: 2026-10-06
- Bắt đầu: 17:54
- Kết thúc: 18:08
- Múi giờ: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: bugfix.
- Module chính: M31 `SLEEP_SAFETY_MONITORING`, app lifecycle Android.
- Yêu cầu gốc: kiểm tra và xin các quyền runtime còn thiếu khi mở app hoặc quay
  lại foreground, để quyền gọi điện sẵn sàng trước luồng cần trợ giúp.

## Đã làm

- Thêm `AndroidRuntimePermissionCoordinator` dùng gateway có thể thay thế khi
  test. Android kiểm tra/yêu cầu quyền theo thứ tự gọi điện, micro, thông báo,
  máy ảnh; nền tảng khác không phát sinh yêu cầu.
- Chuyển `BioAIApp` thành stateful lifecycle observer, chạy kiểm tra sau frame
  đầu và mỗi lần app resume. Các lượt đồng thời dùng chung một Future.
- Thêm hướng dẫn mở Cài đặt dạng không chặn khi Android báo quyền bị từ chối
  vĩnh viễn; người dùng có thể đóng hướng dẫn và tiếp tục dùng app.
- Giữ nguyên `ACTION_CALL` và phương án mở trình gọi điền số sẵn của luồng M31.
- Cài APK debug lên Xiaomi 220333QPG bằng `adb install -r`, giữ dữ liệu ứng
  dụng. Quan sát trực tiếp hộp thoại Android xin quyền cuộc gọi khi app mở;
  sau đó package manager báo `CALL_PHONE`, `CAMERA`, `RECORD_AUDIO` đều đã cấp
  và `MainActivity` đang chạy ở foreground.

## File code/docs đã sửa

- `lib/app/android_runtime_permission_coordinator.dart` — thêm kiểm tra, xin
  quyền runtime Android và điều phối lượt kiểm tra đồng thời.
- `lib/app/bio_ai_app.dart` — chạy kiểm tra ở app start/resume và hiện hướng dẫn
  mở Cài đặt khi cần.
- `test/app/android_runtime_permission_coordinator_test.dart` — thêm test cho
  thứ tự, trạng thái quyền, từ chối và kiểm tra đồng thời.
- `test/app/bio_ai_app_test.dart` — kiểm tra resume, hướng dẫn Cài đặt và việc
  app tiếp tục dùng được sau khi đóng hướng dẫn.
- `docs/fixbug/m31-android-runtime-permissions-at-entry/001-fixbug-m31-android-runtime-permissions-at-entry.md`
  — ghi nhận nguyên nhân và cách sửa.

## Tài liệu liên quan

- `.codex/workflows/bugfix.md`
- `.codex/task-skills/bugfix.md`
- `.codex/DOCS_WORKFLOW.md`

## Commands

- `dart format <4 file Dart đã sửa>`: PASS.
- Flutter tests app permissions + app root: **10/10 PASS**.
- Flutter tests M31 controller + phone fallback: **21/21 PASS**.
- `flutter analyze --no-pub <4 file Dart đã sửa>`: PASS, 0 issues.
- `flutter build apk --debug --no-pub`: PASS.
- `adb install -r build/app/outputs/flutter-apk/app-debug.apk`: PASS.
- Android UI evidence: system `GrantPermissionsActivity` showed the `CALL_PHONE`
  request at startup on Xiaomi Android 11.
- Device permission state after the prompt: `CALL_PHONE`, `CAMERA`, and
  `RECORD_AUDIO` all show `granted=true`.
- `git diff --check`: PASS before adding this worklog; rerun after docs update.

## Lỗi/Rủi ro

- Đã sửa lỗi thiếu kiểm tra quyền tập trung khi mở/resume app.
- Flutter 3.35.2 đi kèm Dart 3.9.0 không đạt constraint `^3.9.2`; dùng Flutter
  3.47.1 / Dart 3.13.1 cùng `--no-pub` để format, test, analyze và build.
- Không lặp lại cuộc gọi trợ giúp trên thiết bị trong phiên này vì contact QA
  tạm đã được dọn ở lượt M31 trước; call gateway/controller vẫn qua focused tests.
- Không đổi backend, schema, iOS hoặc dữ liệu ứng dụng.

## Tỷ lệ hoàn thành

- Hoàn thành: implementation, unit/widget tests, analyzer, APK build/install và
  xác nhận Android hiện prompt quyền gọi khi mở app; quyền gọi, máy ảnh và micro
  hiện đều được cấp trên thiết bị.
- Đang dở: nghiệm thu lại cuộc gọi trợ giúp trên thiết bị trong lượt này.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt — quyền được kiểm tra ở lifecycle gốc, có test cho từ
  chối và vòng đời resume, app không bị khóa khi từ chối.
- Mức độ hoàn thành task: phần code và prompt quyền trên thiết bị đã xác nhận;
  cuộc gọi trợ giúp không được lặp lại trong lượt này.
- Bằng chứng kiểm chứng: 31 focused tests, 0 lỗi analyzer, APK cài giữ dữ liệu;
  ảnh màn hình Android cho thấy hộp thoại `CALL_PHONE` đã xuất hiện khi mở app.
- Điểm tốn token/chưa tối ưu: SDK Flutter mặc định đầu tiên không khớp constraint;
  phát hiện package cache của repo và chuyển sang SDK đúng sau một lần thử.
- Cách tối ưu cho phiên sau: kiểm tra Flutter SDK đang trỏ tới trước khi chạy
  Flutter test/build.
- Task-skill cần đọc lần sau: `.codex/task-skills/bugfix.md`.
