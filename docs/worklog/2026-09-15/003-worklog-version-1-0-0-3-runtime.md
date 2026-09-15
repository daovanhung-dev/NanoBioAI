Commit de xuat: chore(android): build lai ung dung version 1.0.0+3

# Worklog - Chạy lại ứng dụng version 1.0.0+3

## Thời gian

- Ngày: 2026-09-15
- Kết thúc ghi nhận: 11:22
- Timezone: Asia/Ho_Chi_Minh (UTC+07:00)

## Phạm vi

- Loại task: test / Android runtime build.
- Yêu cầu: đồng bộ version `1.0.0+3`, build lại ứng dụng và chạy trên thiết bị Android nếu ADB khả dụng.

## Đã làm

- Cập nhật `pubspec.yaml` từ `1.0.0+2` lên `1.0.0+3`; thay đổi này được thực hiện vì version `+3` mới chỉ có trong file paste/IDE, chưa có trong file workspace.
- Chạy `flutter pub get`; Flutter đồng bộ `android/local.properties` về versionCode `3`.
- Build APK debug mới từ `lib/main.dart` với runtime defines hiện có.
- Không thay đổi business logic, RPC, schema, notification hoặc cấu hình secret.

## Artifact

- File: `build/app/outputs/flutter-apk/app-debug.apk`
- Package: `com.nanobioai.app`
- VersionName: `1.0.0`
- VersionCode: `3`
- Kích thước: `230,679,784` bytes
- SHA-256: `828da3a163e2041ebf7ca7f8cc7b8a1df2fdf7824bef77b8fb865c0510619631`

## Commands và bằng chứng

- `flutter pub get`: PASS.
- `flutter build apk --debug -t lib/main.dart --dart-define-from-file=.dart_tool/nanobio_defines.json`: PASS.
- `aapt2 dump badging build/app/outputs/flutter-apk/app-debug.apk`: PASS; xác nhận package/versionCode/versionName/SDK.
- `git diff --check`: PASS.
- `flutter devices`: chỉ nhận Linux và Chrome; Android serial `12b304f9` không xuất hiện.
- `adb devices -l`: không có thiết bị; chưa thể `adb install` hoặc launch APK trên điện thoại thật trong phiên này.

## Trạng thái

- Build artifact version `1.0.0+3`: PASS.
- Chạy trên Android thật: `UNVERIFIED/BLOCKED` do thiết bị không kết nối ADB.
- Khi kết nối lại thiết bị, chạy:
  `adb -s 12b304f9 install -r --no-streaming build/app/outputs/flutter-apk/app-debug.apk`
  rồi mở `com.nanobioai.app` để nghiệm thu runtime.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - artifact đã được build đúng versionCode `3` và metadata được kiểm chứng bằng `aapt2`.
- Mức độ hoàn thành task: build hoàn tất; chạy trực tiếp trên Android thật chưa hoàn tất do ADB offline.
- Bằng chứng kiểm chứng: `pubspec.yaml`/`local.properties` version `1.0.0+3`, APK build PASS, package/version metadata PASS; chưa có log runtime từ thiết bị.
- Điểm tốn token/chưa tối ưu: phải xác minh lại thay đổi IDE chưa lưu và chờ Gradle build; lần sau nên lưu pubspec trước khi gọi build.
- Cách tối ưu cho phiên sau: kết nối điện thoại trước, kiểm tra `adb devices -l`, sau đó build/install/launch trong cùng một vòng xác minh.
- Task-skill cần đọc lần sau: `.codex/task-skills/test.md`
