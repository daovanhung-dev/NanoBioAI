Commit de xuat: feat(ui): them nut quay ve va quan ly thong bao

# Worklog - Nút quay về và quản lý thông báo

## Thời gian

- Ngày: 2026-09-15
- Kết thúc ghi nhận: 10:56
- Timezone: Asia/Ho_Chi_Minh (UTC+07:00)

## Phạm vi

- Loại task: coding
- Module chính: UI Cài đặt, quản lý notification và điều hướng V1.
- Yêu cầu: thêm nút `Quay về` trên trang `Quản lý thông báo`, thêm nút `Quản lý` riêng trong Cài đặt và fallback deep-link về đúng tab `Của bạn`.

## Đã làm

- Thêm `notification_settings_back_button` trên AppBar của `NotificationSettingsPage`.
- Nút quay về dùng stack hiện tại nếu có; deep-link trực tiếp fallback tới `/menu?tab=settings`.
- Thêm `settings_manage_notifications` riêng trong `SettingsView`, giữ nguyên công tắc bật/tắt notification.
- Thêm key riêng `settings_notifications_switch` để giữ contract kiểm thử/accessibility rõ ràng.
- `MainNavigationPage` nhận `initialIndex`; route `/menu?tab=settings` khởi tạo index `3`, đúng tab `Của bạn`.
- Không đổi RPC, schema, database, notification payload, permission flow hoặc business logic.

## File code/docs đã sửa

- `lib/app_versions/v1/features/settings/presentation/pages/notification_settings_page.dart`
- `lib/app_versions/v1/features/settings/presentation/pages/settings_page.dart`
- `lib/app_versions/v1/features/dashboard/presentation/pages/menu_page.dart`
- `lib/app_versions/v1/router/v1_router.dart`
- `test/app_versions/v1/features/settings/notification_navigation_test.dart`
- `docs/worklog/2026-09-15/001-worklog-notification-navigation-actions.md`

## Commands và bằng chứng

- `dart format` trên 5 file chạm: PASS.
- Flutter targeted tests gồm settings navigation, settings auth reactivity, notification coordinator và route guards: PASS 13/13.
- `flutter analyze`: PASS, `No issues found!`.
- `flutter build apk --debug -t lib/main.dart --dart-define-from-file=.dart_tool/nanobio_defines.json`: PASS; APK được tạo tại `build/app/outputs/flutter-apk/app-debug.apk`.
- `git diff --check`: PASS.
- Android device acceptance: `BLOCKED` sau khi build vì `adb install` báo thiết bị `12b304f9` không còn kết nối; `adb devices -l` vẫn không có thiết bị sau khi restart ADB. APK mới chưa được cài và test UI trên máy thật trong phiên này.

## Lỗi/Rủi ro

- Đã xử lý: không có entry point rõ ràng từ Cài đặt vào trang quản lý notification; trang notification thiếu nút quay về khi mở từ deep-link; fallback trước đây không có cách chọn tab Cài đặt.
- Chưa thể nghiệm thu vật lý trên Android với APK mới do thiết bị USB/ADB ngắt kết nối.
- Cần chạy lại smoke test trên serial `12b304f9` khi thiết bị kết nối: Cài đặt -> Quản lý -> Quay về và mở trực tiếp `/notification-settings`.

## Tỷ lệ hoàn thành

- Hoàn thành: implementation, widget/route tests, format, analyze và Android APK build.
- `UNVERIFIED/BLOCKED`: cài đặt và nghiệm thu UI APK mới trên Android thật do thiết bị không còn online.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - thay đổi đúng phạm vi, giữ công tắc và notification behavior, có semantics/key và test cho cả stack navigation lẫn deep-link fallback.
- Mức độ hoàn thành task: implementation hoàn tất; nghiệm thu máy thật còn blocked do ADB disconnect.
- Bằng chứng kiểm chứng: 13/13 Flutter tests PASS, analyze PASS, APK build PASS, git diff check PASS; device acceptance chưa chạy được với APK mới.
- Điểm tốn token/chưa tối ưu: cần đọc lại nhiều lớp router/tab vì SettingsView nằm trong PageView thay vì route độc lập; thiết bị bị ngắt sau build làm mất vòng kiểm tra cuối.
- Cách tối ưu cho phiên sau: kết nối và khóa serial thiết bị trước khi build cuối; chạy install/launch ngay sau build rồi mới ghi nhận acceptance evidence.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`
