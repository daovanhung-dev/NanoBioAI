Commit de xuat: feat(home): them loi vao doi qua trong tien ich

# Worklog - Thêm lối vào Đổi quà trong Tiện ích

## Thời gian

- Ngày: 2026-10-14
- Bắt đầu: Phiên tiếp nối; thời điểm bắt đầu chính xác không được ghi lại.
- Kết thúc: 23:35
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: Bổ sung lối điều hướng UI vào chức năng hiện có.
- Module chính: V1 Features Hub / Tiện ích; V2 Wellness Rewards route.
- Yêu cầu gốc: Thêm nút Đổi quà trong mục Tiện ích để mở chức năng Đổi quà đã
  được triển khai.

## Đã làm

- Thêm ô **Đổi quà** sau **Nhiệm vụ hôm nay** trong lưới tiện ích, dùng icon
  quà và màu theo token đang có.
- Thêm route path dùng chung trong `core`; V1 hub dùng hằng số này mà không
  phụ thuộc trực tiếp vào router V2. `V2RoutePaths.wellnessRewards` dùng lại
  cùng hằng số nên route đăng ký và lối vào không lệch nhau.
- Giữ nguyên auth guard hiện có của route Đổi quà.
- Cập nhật số tiện ích trong screen spec và test danh sách active; thêm test
  xác nhận tap ô Đổi quà mở đúng route.
- Hot reload app đang chạy. Widget inspector xác nhận tile mới hiện trong
  `FeaturesHubPage` trên app đang kết nối.

## File code/docs đã sửa

- `lib/app_versions/v1/features/features_hub/presentation/pages/features_hub_page.dart`
  - thêm tile Đổi quà sau Nhiệm vụ hôm nay.
- `lib/core/constants/routes/wellness_rewards_route_paths.dart`
  - tạo hằng số route dùng chung.
- `lib/app_versions/v2/router/v2_route_paths.dart`
  - trỏ hằng số V2 hiện có về route path dùng chung.
- `test/features/features_hub/features_hub_page_test.dart`
  - kiểm tra đầy đủ 19 nhãn tiện ích và kiểm tra tap điều hướng tới route rewards.
- `.codex/design/screens/v1-x01-features-hub.md`
  - cập nhật số lối tắt active và ghi nhận route Đổi quà được bảo vệ bởi guard.

## Commands

- `dart format` trên 4 file Dart/test: PASS; lần cuối không thay đổi file.
- `flutter analyze --no-pub` trên 4 file Dart/test: PASS, không có issue.
- 4 suite focused (Features Hub, Fitness entry, Food Scan entry, V2 composed
  route guard): PASS, 20 test.
- Flutter hot reload: PASS.
- Widget inspector app đang chạy: PASS - tìm thấy tile
  `feature-tile-wellness-rewards` dưới `FeaturesHubPage`.
- Flutter Driver tap trên app đang chạy: UNAVAILABLE - app không bật driver
  extension; hành động tap và route được xác minh bằng widget test GoRouter.
- `architecture_version_boundary_test.dart`: FAIL trên 8 file v1 có sẵn vi
  phạm ranh giới phiên bản; `features_hub_page.dart` mới không import V2 và
  không nằm trong danh sách vi phạm.
- `git diff --check`: PASS sau cập nhật docs/history.

## Lỗi/Rủi ro

- Đã làm: lối vào Đổi quà xuất hiện ngay trong mục Tiện ích và dùng đúng route
  hiện có; quyền truy cập tiếp tục do router quyết định.
- Chưa làm: không có thay đổi backend, dữ liệu rewards, hoặc giao dịch đổi quà;
  đây là task điều hướng.
- Cần kiểm tra tiếp: architecture test toàn repo cần xử lý 8 vi phạm V1 đang có
  ở các module khác; không sửa ngoài phạm vi lối vào Đổi quà.

## Tỷ lệ hoàn thành

- Hoàn thành: tile hiển thị trong source và app đang chạy; widget test xác nhận
  mở route rewards; analyzer/tests focused đạt.
- Đang dở: không còn phần bắt buộc của yêu cầu này.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - dùng route constant chung nên bảo toàn ranh giới
  version và không tạo URL trùng lặp.
- Mức độ hoàn thành task: hoàn thành; lối vào được đặt đúng trong tab Tiện ích.
- Bằng chứng kiểm chứng: 20 tests, analyzer, hot reload và DTD widget tree của
  app đang chạy.
- Điểm tốn token/chưa tối ưu: architecture suite báo lỗi nền ngoài file task;
  một lần chạy đầu còn phát hiện test lazy viewport chưa cuộn tới nhóm cuối.
- Cách tối ưu cho phiên sau: giữ widget tests cuộn tới các section lazy trước
  khi assert và chạy architecture baseline theo trạng thái repo hiện tại.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`
