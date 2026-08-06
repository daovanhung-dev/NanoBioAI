Commit de xuat: fix(ui): dọn lỗi analyzer sau Nabi Kinetic Aura

# Fixbug — Analyzer regressions sau Nabi Kinetic Aura

## Phạm vi

Sửa đúng các diagnostics người dùng cung cấp sau đợt refactor motion/feedback. Không thay đổi business logic, persistence, route/access, Supabase hoặc SQLite.

## Nguyên nhân

1. `theme.dart` đã export feedback, experience preferences, colors và durations nhưng một số file vẫn import trực tiếp barrel/file con, tạo `unnecessary_import`.
2. `AppPressScale` dùng tên tham số `pressedScale`, trong khi Voice AI truyền `scale`.
3. `MotionFoundation` có `emphasized` nhưng facade `AppDuration` chưa expose alias tương ứng.
4. `ref.refresh(...)` trả về `FamilyPlusViewModel` có `@useResult`, nhưng kết quả bị bỏ qua.
5. Một primitive còn import token không sử dụng.
6. Hai test SQLite import đồng thời `sqflite` và `sqflite_common_ffi`, trong khi FFI barrel đã cung cấp `Database`.
7. Flutter đã deprecate `SemanticsNode.hasFlag`; contract test cần dùng `flagsCollection`.
8. Một interpolation có braces không cần thiết.
9. `AdminLogger` còn marker `TODO` trong API export placeholder.

## Bản vá

### Motion và component API

- Thay `scale: .965` bằng `pressedScale: .965` trong Voice AI.
- Bổ sung `AppDuration.emphasized = MotionFoundation.emphasized` để giữ compatibility cho onboarding và lifestyle schedule.

### Riverpod

- FamilyPlus sử dụng `FamilyPlusViewModel` trả về từ `ref.refresh(...)`.
- Chỉ phát success feedback khi model không ở trạng thái `failure`.

### Import/lint cleanup

- Loại bỏ các import trực tiếp đã được `theme.dart` export.
- Loại bỏ import `component_tokens.dart` không dùng.
- Loại bỏ import `sqflite.dart` trùng trong hai test FFI.
- Rút gọn `'$waterMl ml'`.

### Flutter semantics API

- Thay `semantics.hasFlag(SemanticsFlag.isSelected)` bằng:

```dart
semantics.flagsCollection.isSelected.toBoolOrNull()
```

### Admin logger

- Loại bỏ marker `TODO` gây analyzer warning.
- Giữ logger không phụ thuộc file system và trả về export marker an toàn; file sharing vẫn thuộc platform layer.

## File đã sửa

- `lib/app/bio_ai_app.dart`
- `lib/app_versions/admin/app/bio_ai_admin_app.dart`
- `lib/app_versions/admin/core/admin_logger.dart`
- `lib/app_versions/v1/features/ai_chat/presentation/pages/ai_chat_screen.dart`
- `lib/app_versions/v1/features/ai_voice/presentation/pages/ai_voice_page.dart`
- `lib/app_versions/v1/features/dashboard/presentation/pages/menu_page.dart`
- `lib/app_versions/v1/features/dashboard/presentation/widgets/overview/dashboard_overview_widgets.dart`
- `lib/app_versions/v1/features/nabi/presentation/widgets/nabi_floating_overlay.dart`
- `lib/app_versions/v1/features/onboarding/presentation/widgets/consent_step.dart`
- `lib/app_versions/v1/features/onboarding/presentation/widgets/nabi_onboarding_experience.dart`
- `lib/app_versions/v1/features/onboarding/presentation/widgets/onboarding_compact_ui.dart`
- `lib/app_versions/v1/shared/widgets/ai_chat_fab.dart`
- `lib/app_versions/v3/features/familyplus/presentation/pages/familyplus_page.dart`
- `lib/core/theme/app_duration.dart`
- `lib/core/theme/primitives/section_header.dart`
- `lib/features/nabi/presentation/widgets/nabi_character.dart`
- `lib/features/nabi/presentation/widgets/nabi_floating_mascot.dart`
- `test/app_versions/v1/features/meal_plan/meal_plan_replacement_transaction_test.dart`
- `test/app_versions/v1/features/nutrition/nutrition_profile_local_datasource_test.dart`
- `test/core/theme/blue_wellness_contract_test.dart`
- `test/core/theme/green_wellness_contract_test.dart`

## Validation

- Targeted Python static validator: PASS trên 21 file Dart.
- Package/relative import resolution: PASS.
- Delimiter/string/comment structural check: PASS.
- Trailing whitespace: PASS.
- Các pattern diagnostics đã cung cấp: không còn.
- `dart format`, `flutter analyze`, `flutter test`: chưa chạy được vì môi trường bàn giao không có Dart/Flutter SDK.

## Rủi ro còn lại

- Cần chạy targeted analyzer trên máy phát triển để xác nhận chính thức toàn bộ diagnostics đã sạch.
- Thay đổi `flagsCollection` yêu cầu Flutter phiên bản có `SemanticsFlags`/`Tristate`, phù hợp với SDK hiện tại của dự án.
