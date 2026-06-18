# Playbook — Notification / Reminder

## Mục tiêu

Thông báo theo lịch trình cá nhân, có action Đã làm/Bỏ qua, và action cập nhật DB an toàn.

## Khi sửa Notification

Đọc:

- `lib/services/notifications/`
- `lib/features/daily_health_tracking/`
- DAO/model/table notification/task nếu có.

## Quy tắc

- Timezone phải init trước khi schedule.
- Notification id phải ổn định, tránh trùng ngoài ý muốn.
- Payload phải serialize/parse an toàn, có version/type nếu cần.
- Background action không được phụ thuộc BuildContext.
- Không gọi plugin notification thật trong unit test; test payload/id/mapper/service logic.
- Nếu đổi Android/native config, chạy build APK.

## Test nên có

- Payload round-trip.
- Invalid payload không crash.
- ID generator ổn định.
- Action complete/skip gọi đúng service/DAO abstraction.
