Commit de xuat: feat(dashboard): chuyển Blue Wellness và tối giản trang chủ

# Feature — Dashboard Blue Wellness

## 1. Mục tiêu

- Chuyển màu thương hiệu chính từ xanh lá sang xanh dương bằng semantic theme token.
- Tối giản Dashboard M03, ưu tiên thông tin và hành động quan trọng nhất trong ngày.
- Giảm chiều dài cuộn, tải nhận thức và số lượng card toàn chiều ngang.
- Giữ nguyên toàn bộ business logic, persistence, provider refresh, quota, access và navigation.

## 2. Phạm vi source

### Theme

- `lib/core/theme/app_colors.dart`
- `lib/core/theme/app_gradients.dart`
- `lib/core/theme/app_shadows.dart`
- `lib/core/theme/app_theme.dart`
- `lib/core/theme/foundation/colors.dart`
- `lib/core/theme/foundation/shadows.dart`
- `lib/core/theme/tokens/color_tokens.dart`
- Các comment/demo label liên quan trong `lib/core/theme/`

### Dashboard

- `lib/app_versions/v1/features/dashboard/presentation/pages/dashboard_page.dart`
- `lib/app_versions/v1/features/dashboard/presentation/widgets/dashboard_content.dart`
- `lib/app_versions/v1/features/dashboard/presentation/widgets/overview/dashboard_overview_widgets.dart`
- `lib/app_versions/v1/features/dashboard/presentation/widgets/sections/dashboard_sections.dart`
- `lib/app_versions/v1/features/dashboard/presentation/widgets/states/dashboard_state_widgets.dart`

### Test

- `test/core/theme/blue_wellness_contract_test.dart`
- `test/app_versions/v1/features/dashboard/dashboard_blue_ui_test.dart`

## 3. Thiết kế đã triển khai

1. Header thấp hơn, copy ngắn, không pulse animation vô hạn.
2. Health Score và việc tiếp theo được gộp trong một snapshot card.
3. Cảm xúc, nước và cân nặng trở thành ba quick action; trên màn hẹp/text scale lớn tự xuống hai hàng.
4. Tổng quan hôm nay chỉ còn bốn chỉ số chính theo lưới 2×2.
5. Timeline hiển thị tối đa ba mục và ưu tiên mục chưa hoàn thành.
6. Trạng thái kế hoạch và self-care streak được gộp; CTA tạo lịch chỉ hiện khi chưa có lịch hoặc còn tối đa một ngày.
7. Insight chỉ ưu tiên một nội dung chính và một recommendation ngắn.
8. Goal/lifestyle/conditions/habits/BMI/height được đưa vào progressive disclosure.
9. Loading state dùng skeleton theo cấu trúc mới; partial error/sync state giữ dạng banner nội tuyến.

## 4. Invariants được giữ

- `dashboardProvider`, `dashboardDynamicProvider`, `dashboardControllerProvider` và `userDataSyncControllerProvider` vẫn là nguồn state hiện tại.
- Pull-to-refresh vẫn invalidate và await cả dashboard static/dynamic provider.
- Tạo lịch vẫn qua `DashboardController.generateAdditionalPlan()` và giữ auth/quota/horizon error mapping.
- Check-in, nước và cân nặng vẫn gọi controller hiện tại.
- Timeline action vẫn deep-link đến đúng `lifestyleSchedule` item và invalidate dynamic provider khi quay lại.
- Presentation không import DAO, datasource hoặc SQLite.
- Không tạo production mock/fake/sample data.

## 5. Palette chính

| Token | Giá trị |
|---|---|
| Primary | `#2F6FED` |
| Primary dark | `#1746A2` |
| Primary light | `#6EA8FE` |
| Primary soft | `#E8F1FF` |
| Background | `#F7FAFF` |
| Text primary | `#15253D` |
| Text secondary | `#5B6B82` |
| Border | `#DCE6F4` |
| Focus ring | `#7DB2FF` |

Success vẫn dùng xanh lá `#14885F`; warning/error không bị đổi thành xanh dương.

## 6. Validation

Đã chạy trong môi trường bàn giao:

- `python3 tools/validate_nabi_green_wellness.py`: PASS — 740 Dart files, 0 blocking findings.
- Import path check cho toàn bộ file mới: PASS.
- Semantic token reference check (`AppColors`, `AppSpacing`, `AppRadius`, `AppDuration`, `AppGradients`, `AppShadows`): PASS, không có member không tồn tại.
- Lexical delimiter balance cho source mới/theme files: PASS.
- Presentation boundary scan: không có DAO/datasource/localdb import.
- Old brand-hex scan trong `lib`, `test`, `tools`: không còn mã màu brand xanh lá cũ.

Chưa thể chạy vì container không có Flutter/Dart executable:

```powershell
dart format lib/core/theme lib/app_versions/v1/features/dashboard test/app_versions/v1/features/dashboard test/core/theme
flutter analyze lib/core/theme lib/app_versions/v1/features/dashboard test/app_versions/v1/features/dashboard test/core/theme
flutter test test/app_versions/v1/features/dashboard/dashboard_blue_ui_test.dart
flutter test test/core/theme/blue_wellness_contract_test.dart
flutter test test/features/dashboard
flutter test test/architecture_version_boundary_test.dart
flutter test test/architecture_preservation_property_test.dart
flutter build apk --debug
```

## 7. Acceptance còn cần trên máy phát triển

- Không overflow tại 320×568, 360×800, 375×812, 412×915 và tablet.
- Text scale 90%, 100%, 115%, 130% không cắt CTA hoặc nội dung quan trọng.
- Nabi overlay không che action cuối trang.
- Pull-to-refresh, check-in, water, weight, timeline deep-link và create-plan hoạt động trên thiết bị thật.
