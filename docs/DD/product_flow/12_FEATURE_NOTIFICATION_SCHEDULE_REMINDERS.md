# DD-PRODUCT-FLOW-FR-009 - Notification theo Lịch Trình Cá Nhân

**BD nguồn:** UC-04, Section 9.3, BR-02, BR-03  
**Status:** Draft  
**Dependencies:** 04, 09, 13, 14, 15, `.codex/playbooks/notification.md`  

## 1. Mục tiêu và outcome

App lập thông báo theo từng ngày/mốc thời gian trong lịch trình cá nhân, cho Guest và member, đồng thời action hoàn thành/bỏ qua cập nhật đúng dữ liệu lịch trình.

## 2. Trigger / Preconditions

- Lịch trình cá nhân đã được tạo/lưu.
- Schedule item có ngày/giờ/source/status rõ ràng.
- Notification service đã init timezone.

## 3. Input contract

| Field | Required | Type | Validation | Sensitive? |
|---|---:|---|---|---|
| scheduleItemId/sourceId | Yes | string/int | stable mapping | Yes |
| scheduleDate/startTime | Yes | date/time | timezone-aware | No |
| title/body | Yes | text | Vietnamese, no internal terms | No |
| payload | Yes | structured | type/id/version/status action | Yes |

## 4. Output / Postconditions

- Local notification scheduled với stable id.
- Payload action complete/skip có thể parse an toàn.
- Complete/skip update SQLite/Supabase theo ownership của schedule item.
- FamilyPlus notification theo member/subject chỉ Ready khi family permission policy chốt.

## 5. Happy path

```text
1. Schedule items được lưu.
2. Reminder scheduler tạo notification id ổn định.
3. Notification được schedule theo local timezone.
4. User bấm hoàn thành/bỏ qua.
5. Background handler parse payload và cập nhật status qua service/DAO abstraction.
6. Dashboard/timeline refresh từ data source.
```

## 6. Alternative and error flows

| Case | Detection | UI behavior | Technical behavior | Retry |
|---|---|---|---|---|
| Invalid payload | parser failure | Không crash | Ignore/log safe summary | No |
| Timezone init fail | bootstrap error | Báo chưa thể nhắc lịch | Do not schedule invalid reminders | Retry init |
| Duplicate schedule | stable id/source conflict | Không nhân đôi notification | Replace/cancel existing by stable id | Yes |
| Family subject unauthorized | permission deny | Không schedule/cập nhật | Fail closed | No |

## 7. Persistence and ownership

| Action | Target | Actor allowed | RLS/constraint |
|---|---|---|---|
| Schedule local notification | device notification plugin | app local | no secret |
| Store notification record | notifications table/local DB | owner/subject allowed | source_id stable |
| Complete/skip item | schedule/task table | owner/family edit allowed | no BuildContext dependency |

## 8. Layer responsibilities / affected files

| Layer | Responsibility | Proposed file |
|---|---|---|
| Notification bootstrap | timezone/plugin init | `notification_bootstrap.dart` |
| Scheduler | id/payload/schedule logic | `reminder_notification_scheduler.dart`, `reminder_schedule_service.dart` |
| Action handler | complete/skip without UI context | `notification_action_handler.dart` |
| Lifestyle data | update schedule item status | lifestyle schedule repository/DAO |

## 9. Security / privacy

- Payload không chứa hồ sơ sức khỏe chi tiết.
- Background action không phụ thuộc `BuildContext`.
- Không hiển thị thuật ngữ technical trong notification/error.

## 10. Acceptance tests

- TC-PF-29: Schedule item tạo notification id ổn định.
- TC-PF-30: Payload valid round-trip parse được.
- TC-PF-31: Invalid payload không crash.
- TC-PF-32: Complete/skip cập nhật đúng source item.

## 11. Non-goals

- Không định nghĩa notification chéo family nếu Q-07 chưa chốt.
- Không đổi native Android/iOS config nếu không cần.

## 12. Open decisions

| ID | Question | Owner | Impact |
|---|---|---|---|
| Q-07 | FamilyPlus gửi/nhận thông báo chéo theo member như thế nào? | Product Owner / Privacy | Subject-aware notification routing |

