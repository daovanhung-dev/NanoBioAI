Commit đề xuất: feat(features-hub): expand personal care modules

# Mở rộng Góc chăm sóc

## Mục tiêu
- Mở rộng `FeaturesHubPage` thành góc chăm sóc toàn diện hơn.
- Thêm các module chăm sóc nhỏ theo phong cách Nami.
- Đảm bảo các card mới có route/page để người dùng bấm vào không bị gián đoạn.

## Phạm vi
- Bao gồm:
  - Thêm 6 card mới vào `FeaturesHubPage`.
  - Thêm route cho các page mới.
  - Tạo page UI tối thiểu cho từng chức năng.
  - Tạo shared UI widget nhẹ để giữ giao diện đồng bộ.
- Không bao gồm:
  - Chưa tạo persistence/database mới cho các module chưa có luồng dữ liệu.
  - Chưa tạo notification thật cho uống nước hoặc mục tiêu cá nhân.

## Luồng hoạt động
1. Người dùng mở `FeaturesHubPage`.
2. Trang hiển thị đủ 14 góc chăm sóc.
3. Người dùng chọn một card mới.
4. App điều hướng tới page tương ứng.
5. Page hiển thị UI/empty state theo phong cách Nami, không dùng dữ liệu giả như dữ liệu thật.

## Dữ liệu và lưu trữ
- Nguồn đọc: chưa thêm nguồn đọc mới.
- Nơi ghi: chưa thêm nơi ghi mới.
- Table/model/entity: chưa phát sinh.
- Migration/version: chưa phát sinh.
- Ghi chú: `WaterTrackingPage`, `PersonalGoalsPage`, `GentleCareModePage` chỉ dùng local UI state trong phiên hiện tại để tạo tương tác nhẹ.

## UI/UX
- Loading: chưa phát sinh state async.
- Empty: dùng thông điệp dịu nhẹ theo persona Nami.
- Error: chưa phát sinh state async.
- Success: các lựa chọn local có phản hồi visual nhẹ.

## Chức năng thêm mới
- Uống nước hôm nay.
- Cơ thể của bạn.
- Tổng kết tuần.
- Mục tiêu của mình.
- Hôm nay mình mệt.
- Chăm mình 5 phút.

## Route
- `/water-tracking`
- `/body-metrics`
- `/weekly-summary`
- `/goals`
- `/gentle-care-mode`
- `/quick-care`

## Files
- `lib/features/features_hub/presentation/pages/features_hub_page.dart` - thêm 6 card mới và tăng nhẹ chiều cao card.
- `lib/core/constants/routes/route_names.dart` - thêm route path mới.
- `lib/core/router/app_router.dart` - khai báo route/page mới.
- `lib/features/features_hub/presentation/widgets/nami_care_page.dart` - tạo scaffold/card/tile dùng chung cho các page chăm sóc.
- `lib/features/water_tracking/presentation/pages/water_tracking_page.dart` - tạo UI uống nước hôm nay.
- `lib/features/body_metrics/presentation/pages/body_metrics_page.dart` - tạo UI chỉ số cơ thể.
- `lib/features/weekly_summary/presentation/pages/weekly_summary_page.dart` - tạo UI tổng kết tuần.
- `lib/features/personal_goals/presentation/pages/personal_goals_page.dart` - tạo UI mục tiêu cá nhân.
- `lib/features/gentle_care_mode/presentation/pages/gentle_care_mode_page.dart` - tạo UI chế độ chăm sóc nhẹ.
- `lib/features/quick_care/presentation/pages/quick_care_page.dart` - tạo UI chăm mình 5 phút.

## Kiểm chứng
- Command: `dart format .`
- Kết quả: SKIPPED - môi trường hiện tại không có `dart`.
- Command: `flutter analyze`
- Kết quả: SKIPPED - môi trường hiện tại không có `flutter` và workspace được cung cấp chỉ có `.codex` + `lib`, thiếu `pubspec.yaml`.
- Case đã kiểm tra thủ công:
  - `FeaturesHubPage` có đủ 14 `_FeatureAction`.
  - 6 route mới đã được khai báo trong `app_router.dart`.
  - `RoutePaths.goals` được dùng lại cho `Mục tiêu của mình`.

## Liên kết
- Worklog: [001-worklog-features-hub-expansion.md](../../worklog/2026-06-19/001-worklog-features-hub-expansion.md)

## Rủi ro
- Các page mới hiện ưu tiên UI/empty state, chưa lưu dữ liệu lâu dài.
- Cần chạy `flutter analyze` trong project đầy đủ có `pubspec.yaml` để xác nhận toàn bộ app.
