# Implementation Delta 2026-07-15 — Logbug 14-7-26

| Thuộc tính | Giá trị |
|---|---|
| Module | M02 / `PERSONAL_SCHEDULE_AI` |
| Nguồn | Kế hoạch logbug 14-7-26 do người dùng cung cấp ngày 2026-07-15 |
| Ảnh hưởng | Sinh lịch Guest/Member, quota, idempotency, timeline |

## Quyết định bổ sung

| ID | Quyết định |
|---|---|
| PERSONAL_SCHEDULE_AI-DELTA-BR01 | Horizon lấy ngày cuối lớn nhất từ `meal_plans` và `lifestyle_schedule_items` theo `Asia/Ho_Chi_Minh`; số ngày còn lại tính inclusive. Cho phép khi còn 0/1 ngày, khóa khi còn từ 2 ngày; ngày lỗi/malformed phải fail closed. |
| PERSONAL_SCHEDULE_AI-DELTA-BR02 | Retry của request đã `succeeded` được trả trước gate. Request mới theo thứ tự: auth → horizon → routine → quota check → AI hợp lệ → transaction → quota commit. |
| PERSONAL_SCHEDULE_AI-DELTA-BR03 | Mỗi user chỉ có một generation in-flight. Ngày bắt đầu mới là `max(today, lastScheduledDate + 1)`. |
| PERSONAL_SCHEDULE_AI-DELTA-ADR01 | `ScheduleTimingResolver` sở hữu toàn bộ giờ; AI chỉ sinh nội dung. Ngủ trưa là schedule item thật, nên manifest có 10 hoặc 11 item/ngày. |

## Lỗi typed và evidence

- `PersonalScheduleStillActiveException`, `ScheduleHorizonDataException`, `DailyRoutinePreferencesRequiredException` là lỗi fail-closed tương ứng.
- Runtime: `generated_plan_service.dart`, schedule horizon datasource/entity/repository, timing resolver và timeline builder.
- Test: horizon tháng/năm/leap-day/malformed, single-flight, gate trước quota/AI, idempotent retry và manifest 10/11.
- SQL: migration 16 và `config.sql` chấp nhận 10/11 item/ngày; sandbox apply vẫn là gate riêng.
