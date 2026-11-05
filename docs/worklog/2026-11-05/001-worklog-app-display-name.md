Commit de xuat: feat(app): doi ten hien thi Nabi

# Worklog - Đổi tên hiển thị ứng dụng Nabi

## Thời gian

- Ngày: 2026-11-05
- Bắt đầu: 12:52:50
- Kết thúc: 13:04:33
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: coding
- Module chính: Android/iOS app display name
- Yêu cầu gốc: đổi tên dưới biểu tượng ứng dụng thành “Nabi - Trợ lý sức khỏe AI”.

## Đã làm

- Đổi Android `android:label` và iOS `CFBundleDisplayName` sang đúng chuỗi được yêu cầu.
- Giữ nguyên Android package ID, iOS bundle ID, tên package Dart và dữ liệu ứng dụng.
- Build APK debug, xác nhận package `com.nanobioai.app`, version `1.0.2` / code `8`, và nhãn đóng gói chính xác.
- So sánh chứng thư ký của APK mới với APK đang cài trên Android 220333QPG; chứng thư khớp.
- Cập nhật ứng dụng bằng `adb install -r`; cài đặt thành công. `ceDataInode` trước và sau vẫn là `114073`.
- Trích APK đã cài để xác nhận nhãn và SHA-256 trùng với APK vừa build; xóa bản APK tạm sau khi kiểm tra.
- Không thể build/cài iOS trên host Linux vì không có `xcodebuild`; plist được parse bằng Python và giá trị display name đã xác nhận.

## File code/docs đã sửa

- `android/app/src/main/AndroidManifest.xml` - đổi nhãn ứng dụng Android.
- `ios/Runner/Info.plist` - đổi tên hiển thị ứng dụng iOS.
- `docs/worklog/2026-11-05/001-worklog-app-display-name.md` - ghi lại phạm vi và bằng chứng.

## Tài liệu liên quan

- `.codex/workflows/coding.md`
- `.codex/domains/ui-nami.md`

## Commands

- `flutter build apk --debug`: PASS - hoàn tất sau 231.6 giây; có cảnh báo nâng cấp Gradle/AGP/Kotlin và SDK XML v4.
- Python XML parse Android manifest: PASS - nhãn đúng nguyên văn.
- Python `plistlib` parse iOS plist: PASS - `CFBundleDisplayName` đúng nguyên văn.
- `aapt dump badging`: PASS - label `Nabi - Trợ lý sức khỏe AI`, package `com.nanobioai.app`, version `1.0.2` / code `8`.
- `apksigner verify --print-certs`: PASS - chứng thư APK mới khớp APK đang cài.
- `adb install -r build/app/outputs/flutter-apk/app-debug.apk`: PASS - `Success`.
- Kiểm tra package và APK đã cài: PASS - package vẫn cài, version không đổi, label chính xác, SHA-256 APK đã cài khớp APK build.
- `git diff --check`: PASS.
- `pwsh -NoProfile -File .codex/tools/validate_codex_integrity.ps1`: FAIL - thiếu `docs/audit/source_truth_manifest.json` và báo stale path trong history/task-skill hiện có; không liên quan hai metadata tên app.
- iOS native build/install: SKIPPED - host Linux không có `xcodebuild`.

## Lỗi/Rủi ro

- Đã fix: nhãn ứng dụng Android/iOS cũ là “Nabi”.
- Chưa fix: không có.
- Cần kiểm tra tiếp: build/cài iOS trên macOS nếu cần nghiệm thu binary iOS.
- Kiểm tra integrity hiện có lỗi ngoài phạm vi: thiếu source-truth manifest và stale path trong tài liệu lịch sử/task-skill; giữ nguyên, không sửa trong task đổi tên.
- Build có cảnh báo tương thích tương lai của Gradle 8.14, AGP 8.11.1, Kotlin 2.2.20 và SDK XML v4; không ảnh hưởng build lần này.

## Tỷ lệ hoàn thành

- Hoàn thành: Android/iOS display metadata, Android APK build và cập nhật thiết bị.
- Đang dở: không có trong phạm vi; iOS native build không khả dụng trên host Linux.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - tên hiển thị được xác nhận từ APK build và APK đã cài.
- Mức độ hoàn thành task: hoàn thành phạm vi được môi trường hỗ trợ; iOS native build chưa xác minh.
- Bằng chứng kiểm chứng: XML/plist parse, APK badging, package manager, cài đặt thành công, signer và SHA-256 khớp.
- Điểm tốn token/chưa tối ưu: Android debug APK lớn nên build/cài mất vài phút; giữ phạm vi build nhỏ ở các lần đổi metadata tương tự.
- Cách tối ưu cho phiên sau: dùng cùng Android device/debug signer hiện hành và kiểm tra label trong artifact trước khi cài.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`
