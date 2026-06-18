# Playbook — Dashboard / Health Score

## Mục tiêu

Dashboard phải hiển thị dữ liệu động từ SQLite/data layer thật, không dùng mock/fake production.

## Luồng đúng

```text
Onboarding -> lưu hồ sơ -> tạo lịch trình cá nhân -> lưu task/plan -> dashboard tính điểm từ DB -> user action cập nhật DB -> dashboard refresh
```

## Khi sửa Dashboard

Đọc vùng liên quan:

- `lib/features/dashboard/`
- `lib/features/daily_health_tracking/`
- `lib/features/lifestyle_schedule/`
- DAO/model/table liên quan health tracking, daily tasks, schedule items, meal plans.

Kiểm tra bằng `rg`:

```bash
rg "mock|fake|sample|dummy|TODO" lib/features/dashboard lib/features/daily_health_tracking
rg "score|point|progress|completion|task" lib/features/dashboard lib/features/daily_health_tracking
```

## Quy tắc

- Controller không tự bịa dữ liệu nếu DB rỗng, trừ empty state rõ ràng.
- Score calculator nên tách logic để unit test được.
- Dashboard state phải biểu diễn loading/error/empty/data rõ ràng.
- Không query DB trực tiếp trong Widget.
