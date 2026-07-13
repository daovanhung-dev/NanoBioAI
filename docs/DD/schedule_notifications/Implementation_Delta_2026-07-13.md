# Implementation Delta — M09 mở nhiệm vụ để chụp bằng chứng

| Thuộc tính | Giá trị |
|---|---|
| Module | M09 `SCHEDULE_NOTIFICATIONS` |
| Trạng thái DD gốc | Approved — giữ nguyên |
| Nguồn bổ sung | `BD-BIOAI-WELLNESS-REWARDS-001` |
| Ngày | 2026-07-13 |

## 1. Override hành động notification

Hành động hoàn thành nền trong DD baseline không còn hợp lệ vì không thể đáp ứng
camera proof. Với hành động hoàn thành, notification phải hiển thị `Mở để chụp
ảnh`, xác thực payload/owner/subject rồi điều hướng đúng schedule item. Việc hoàn
thành chỉ xảy ra sau khi use case M03 kiểm tra cửa sổ và camera proof thành công.

Hành động bỏ qua, nếu còn được hiển thị theo cấu hình, vẫn phải đi qua handler
idempotent hiện hành và không được tạo Điểm chăm sóc.

## 2. Contract mới

| ID delta | Contract |
|---|---|
| M09-DELTA-BR01 | Payload chứa source/subject hợp lệ; payload rỗng, sai source hoặc sai owner bị bỏ qua an toàn. |
| M09-DELTA-BR02 | Tap notification/CTA hoàn thành gọi navigation coordinator, không ghi completed trong background isolate. |
| M09-DELTA-BR03 | Deep-link mang schedule item id; trang lịch mở đúng item và áp dụng `[start, start + 30 phút)`. |
| M09-DELTA-BR04 | Resume/startup refresh trạng thái ở mốc mở/khóa; notification không mở khóa nhiệm vụ tương lai hoặc dữ liệu giờ lỗi. |

## 3. Implementation map

- `reminder_notification_scheduler.dart`: action copy `Mở để chụp ảnh`.
- `notification_action_handler.dart`: validation payload/subject, idempotency và
  chuyển hành động hoàn thành sang navigation.
- `notification_navigation_coordinator.dart`: deep-link tới route lịch với item id.
- `notification_bootstrap.dart`: kết nối lifecycle/startup navigation.
- Lifestyle controller/page: nhận pending item, cuộn/mở đúng nhiệm vụ và chạy
  camera proof use case dùng chung.

## 4. Bằng chứng và phần còn thiếu

- Targeted analyze daily/proof sạch.
- Bundle 59 lifestyle/migration/notification/cloud-sync: PASS.
- Bundle 50 dashboard/deep-link liên quan: PASS.

Chưa có bằng chứng real-device cho delivery/action khi app foreground,
background hoặc terminated; chưa có cross-device Supabase smoke. Các trường hợp
đó vẫn thuộc implementation evidence backlog của M09 trước production.
