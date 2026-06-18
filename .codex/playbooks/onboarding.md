# Playbook — Onboarding

## Mục tiêu

Onboarding thu thập hồ sơ sức khỏe, lưu DB, rồi kích hoạt tạo lịch trình cá nhân.

## Khi sửa Onboarding

Đọc:

- `lib/features/onboarding/`
- DAOs/models: user, health_profile, health_goal, lifestyle_habit, conditions, allergies.
- Service tạo meal/schedule/task nếu task liên quan sau onboarding.

## Quy tắc

- Giữ provider/controller/route/callback public nếu chưa kiểm tra usage bằng `rg`.
- Giảm nhập tay, ưu tiên select/choice có kiểm soát.
- Validate dữ liệu trước khi lưu.
- Text tiếng Việt có dấu, giọng Nami nhẹ nhàng, không phán xét.
- Sau submit thành công, không chỉ navigate; phải đảm bảo dữ liệu cần cho dashboard đã có hoặc có flow tạo tiếp rõ ràng.

## Test nên có

- Validate required fields.
- Save profile/goals/habits đúng mapping.
- Submit success kích hoạt flow kế tiếp.
- Error state không mất dữ liệu người dùng.
