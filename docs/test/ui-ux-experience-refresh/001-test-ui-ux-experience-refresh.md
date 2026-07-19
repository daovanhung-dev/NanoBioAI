Commit de xuat: test(ui): ghi nhan static validation cho UI UX experience refresh

# Test - UI/UX Experience Refresh

## Phạm vi kiểm chứng

- Theme/motion primitive mới.
- View-level back-navigation.
- Onboarding copy và step Back behavior.
- Ranh giới thay đổi chỉ ở presentation/theme.
- Import nội bộ và cân bằng delimiter của toàn bộ Dart file đã chạm.
- An toàn đóng gói secret/cache.

## Kết quả

| Kiểm tra | Trạng thái | Bằng chứng |
|---|---|---|
| Danh mục file Dart thay đổi | PASS | 34 file; tất cả thuộc `core/theme`, `*/presentation` hoặc `sale_referral/presentation` |
| Delimiter lexical check | PASS | Không có ngoặc, bracket, brace, string hoặc block comment chưa đóng trong file đã chạm |
| `package:nano_app` import resolution | PASS | Mọi import/export package nội bộ trỏ tới file tồn tại |
| Relative import resolution | PASS | Mọi import/export tương đối trong file đã chạm tồn tại |
| Scope guard | PASS | Không có controller/provider/repository/datasource/model/SQLite/Supabase bị sửa |
| Hardware Back source audit | PASS tĩnh | Detail navigation dùng `push`; onboarding dùng `PopScope`; root/redirect giữ `go` có chủ đích |
| Onboarding required copy contract | PASS tĩnh | Giữ CTA `Tạo lộ trình của tôi` theo test hiện hữu; giữ nguyên consent/medical boundary content bắt buộc |
| Onboarding literal reduction | PASS | 2.218 → 1.717 từ, giảm 501 từ (22,6%) trong presentation scope |
| Secret mutation | PASS | Không chỉnh `.env` hoặc `assets/config/auth.env`; các file này bị loại khỏi ZIP |
| `dart format` | SKIPPED | Runtime hiện tại không có Dart executable |
| `flutter analyze` | SKIPPED | Runtime hiện tại không có Flutter executable |
| Targeted `flutter test` | SKIPPED | Runtime hiện tại không có Flutter executable |
| Debug APK/build | SKIPPED | Runtime hiện tại không có Flutter/Android toolchain |
| Real-device visual/back smoke | NOT RUN | Không có thiết bị và Flutter runtime trong môi trường bàn giao |

Kết quả máy đọc được lưu tại `static-validation-output.txt`.

## Static commands đã chạy

```text
Python changed-file hash/diff inventory
Python Dart delimiter scanner trên 34 file thay đổi
Python package/relative import resolution
Python scope guard cho presentation/theme
rg context.go/context.push/PopScope navigation audit
rg contract strings trong onboarding tests/source
```

## Rủi ro còn lại

- Static validation không thay thế Dart analyzer; API compatibility của Flutter/GoRouter cần được xác nhận bằng SDK của dự án.
- Chưa có screenshot matrix ở 360/600/1024 px và chưa chạy trên điện thoại thật.
- Global theme có phạm vi rộng; cần smoke các dialog, bottom sheet, keyboard, text scale và route transition trên APK cuối.

## Validation đề xuất trên máy dự án

```powershell
dart format lib/core/theme lib/app_versions/v1/features/onboarding/presentation `
  lib/app_versions/v1/features/settings/presentation/pages/settings_page.dart `
  lib/app_versions/v2/features lib/app_versions/v3/features `
  lib/app_versions/admin/features/admin_panel/presentation `
  lib/features/nabi/presentation lib/sale_referral/presentation

flutter analyze lib/core/theme lib/app_versions/v1/features/onboarding/presentation `
  lib/app_versions/v1/features/settings/presentation/pages/settings_page.dart `
  lib/app_versions/v2/features lib/app_versions/v3/features `
  lib/app_versions/admin/features/admin_panel/presentation `
  lib/features/nabi/presentation lib/sale_referral/presentation

flutter test test/core/theme/medical_design_system_contract_test.dart
flutter test test/app_versions/v1/features/onboarding
flutter test test/app_versions/v2/features/auth/auth_pages_smoke_test.dart
flutter build apk --debug
```
