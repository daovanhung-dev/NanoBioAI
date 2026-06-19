Commit đề xuất: docs(issue): ghi nhận lỗi page chăm sóc mới chỉ lưu state trong phiên

# Các page chăm sóc mới hiển thị tương tác nhưng không lưu dữ liệu thật

## Tóm tắt
- Một số page mới có tương tác nhìn như ghi nhận hành vi, nhưng chỉ lưu trong `State` cục bộ.
- Rời trang hoặc rebuild là mất dữ liệu, dashboard/lifestyle schedule không đọc được.

## Mức độ ảnh hưởng
- Severity: medium
- Ảnh hưởng user: người dùng tưởng đã ghi uống nước, mục tiêu hoặc chế độ chăm sóc nhẹ nhưng dữ liệu không tồn tại lâu dài.
- Ảnh hưởng dev/build/test: dễ tạo lệch kỳ vọng giữa UI và data layer.

## Cách tái hiện
1. Vào `WaterTrackingPage`.
2. Bấm `+250 ml`.
3. Rời trang rồi quay lại.
4. `_currentMl` trở về 0 vì không lưu DB/provider.

## Đã xác nhận
- `lib/features/water_tracking/presentation/pages/water_tracking_page.dart:12-18` chỉ dùng `_currentMl` trong `State`.
- `lib/features/personal_goals/presentation/pages/personal_goals_page.dart:11-12` chỉ dùng `_selectedIndex` cục bộ.
- `lib/features/gentle_care_mode/presentation/pages/gentle_care_mode_page.dart:11-12` chỉ dùng `_selectedIndex` cục bộ.
- Docs feature expansion cũng ghi các page mới chưa có persistence/database.

## Giả thuyết
- Các page được tạo như UI/empty state nhẹ nhưng copy và interaction dễ làm user hiểu là đã ghi nhận thật.

## Workaround
- Chỉ dùng như prototype hoặc đổi copy để nói rõ dữ liệu chưa được lưu.

## Hướng fix đề xuất
- Nối Water Tracking vào daily health tracking datasource/log hiện có.
- Nối Personal Goals/Gentle Care vào provider hoặc lưu local preference nếu cần trong v1.
- Nếu chưa làm persistence, bỏ tương tác ghi nhận hoặc đổi thành navigation tới feature thật.

## Files/log liên quan
- `lib/features/water_tracking/presentation/pages/water_tracking_page.dart`
- `lib/features/personal_goals/presentation/pages/personal_goals_page.dart`
- `lib/features/gentle_care_mode/presentation/pages/gentle_care_mode_page.dart`

## Liên kết
- Worklog: ../../worklog/2026-06-19/007-worklog-release-1-0-bug-audit.md
