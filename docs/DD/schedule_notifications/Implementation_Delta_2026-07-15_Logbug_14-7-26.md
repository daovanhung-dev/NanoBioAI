# Implementation Delta 2026-07-15 — Logbug 14-7-26

| Thuộc tính | Giá trị |
|---|---|
| Module | M09 / `SCHEDULE_NOTIFICATIONS` |
| Nguồn | Kế hoạch logbug 14-7-26 do người dùng cung cấp ngày 2026-07-15 |
| Ảnh hưởng | Thời điểm reminder và deep-link completion |

## Quyết định bổ sung

| ID | Quyết định |
|---|---|
| SCHEDULE_NOTIFICATIONS-DELTA-BR01 | Reminder dùng thời gian đã được `ScheduleTimingResolver` ghi vào schedule item; notification không tự suy diễn giờ từ nội dung AI. |
| SCHEDULE_NOTIFICATIONS-DELTA-BR02 | Deep-link mở đúng item và áp dụng cửa sổ inclusive `[start, start + 30 phút]`; camera proof/controller vẫn thuộc M03. |
| SCHEDULE_NOTIFICATIONS-DELTA-ADR01 | Không đổi cơ chế notification, payload hay idempotency trong logbug này; chỉ đổi nguồn giờ thành schedule item đã resolve. |

## Evidence

- Runtime source: timing resolver/timeline builder và notification scheduling hiện có.
- Regression: test timeline/count và notification contract hiện có; real-device delivery/action smoke vẫn là gate trước production.
