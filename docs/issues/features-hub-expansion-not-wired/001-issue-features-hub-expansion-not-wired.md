Commit đề xuất: docs(issue): ghi nhận lỗi mở rộng features hub chưa được nối route

# Features Hub expansion tạo page mới nhưng chưa hiển thị và chưa có route

## Tóm tắt
- Tài liệu feature expansion ghi `FeaturesHubPage` phải có 14 góc chăm sóc và 6 route mới.
- Code hiện tại của `FeaturesHubPage` chỉ có 8 `_FeatureAction`.
- Router và `RoutePaths` chưa khai báo 6 route mới.

## Mức độ ảnh hưởng
- Severity: high
- Ảnh hưởng user: các module mới đã tạo nhưng không thể mở từ app.
- Ảnh hưởng dev/build/test: tài liệu feature nói đã hoàn tất nhưng code release không khớp.

## Cách tái hiện
1. Mở `FeaturesHubPage`.
2. Đếm card hiển thị: code hiện tại có 8 card.
3. Tìm route `/water-tracking`, `/body-metrics`, `/weekly-summary`, `/gentle-care-mode`, `/quick-care`: không có trong router.

## Đã xác nhận
- `docs/features/features-hub-expansion/001-feature-features-hub-expansion.md` ghi 14 góc chăm sóc và 6 route mới.
- `lib/features/features_hub/presentation/pages/features_hub_page.dart:11-68` chỉ khai báo 8 `_FeatureAction`.
- `lib/core/constants/routes/route_names.dart:1-32` chưa có route mới trừ `goals` sẵn có.
- `lib/core/router/app_router.dart:21-135` chưa import hoặc khai báo 6 page mới.
- Các page mới đang tồn tại trong `lib/features/body_metrics`, `water_tracking`, `weekly_summary`, `personal_goals`, `gentle_care_mode`, `quick_care`.

## Giả thuyết
- Một phần thay đổi feature expansion chưa được áp dụng hoặc bị revert cục bộ.

## Workaround
- Không công bố 6 module mới trong release notes nếu chưa nối route.

## Hướng fix đề xuất
- Đồng bộ `FeaturesHubPage`, `RoutePaths`, `app_router.dart` với docs feature expansion.
- Thêm widget tests kiểm tra đủ 14 card và tap được từng route mới.

## Files/log liên quan
- `docs/features/features-hub-expansion/001-feature-features-hub-expansion.md`
- `lib/features/features_hub/presentation/pages/features_hub_page.dart`
- `lib/core/constants/routes/route_names.dart`
- `lib/core/router/app_router.dart`

## Liên kết
- Worklog: ../../worklog/2026-06-19/007-worklog-release-1-0-bug-audit.md
