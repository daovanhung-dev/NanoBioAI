# Nabi Invalid Constant Hotfix

## Mục tiêu
Sửa lỗi Dart `Invalid constant value` tại
`lib/features/Nabi/application/Nabi_expression_resolver.dart:116`.

## Nguyên nhân
`fallbackContext` là tham số runtime, nhưng được truyền vào một lời gọi
`const NabiResolvedPresentation(...)`. Giá trị runtime không thể nằm trong
một hằng số Dart.

## Thay đổi
- Bỏ `const` duy nhất ở nhánh `NabiEvent.formNeedsAttention`.
- Giữ nguyên `fallbackContext` để Nabi vẫn biết đang ở ngữ cảnh nào.
- Thêm unit test bảo vệ trường hợp fallback context là `NabiContext.onboarding`.

## Cách áp dụng
Giải nén tại thư mục gốc `nano_app`, cho phép ghi đè file nếu được hỏi.

## Kiểm tra trên Windows
```powershell
flutter test test/features/Nabi/application/Nabi_expression_resolver_test.dart
flutter analyze lib/features/Nabi/application/Nabi_expression_resolver.dart
```
