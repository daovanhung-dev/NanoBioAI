# Overall — M22 / Lịch dùng thuốc

## 0. Thông tin tài liệu

| Trường | Giá trị |
|---|---|
| Mã module | M22 `MEDICATION_ADHERENCE` |
| Phiên bản | v1.0.1 |
| Lifecycle | Current |
| DD decision | Approved for M22-F01/F02 only |
| Implementation | Partial — approved F01/F02 source implemented on top of baseline `598daf04` |
| Verification | Affected Dart analysis and coordinator tests passed; SQLite FFI/device evidence remains pending |
| BD nguồn | Advanced Health BD §M22 and approved addendum 2026-10-15 |
| Owner nghiệp vụ | User / Product Owner instruction |
| Ngày tạo / cập nhật | 2026-10-15 / 2026-10-15 |

`Approved` applies only to the local medication-reminder slice. It does not
approve the full adherence product or imply runtime completion.

## 1. Mục đích và ranh giới

Guest may enter an exact medicine name with one or more daily reminder times
during onboarding. Reminders repeat every day while enabled. After onboarding,
the user can add a medicine and schedule, rename the medicine, edit reminder
times, pause/resume, and delete schedules in Notification Settings.

| Nhóm | Trong phạm vi | Ngoài phạm vi |
|---|---|---|
| Nghiệp vụ | Lưu tên do người dùng nhập; giờ nhắc mỗi ngày; thêm/đổi tên/sửa giờ/tạm dừng/bật lại/xóa trong Settings | Liều/dạng thuốc, lịch theo ngày trong tuần, ngày bắt đầu/kết thúc, taken/skipped history |
| Dữ liệu | SQLite trên thiết bị; owner là local subject hiện hành | Supabase, SyncOutbox, cross-device restore, FamilyPlus sharing |
| Thông báo | Lặp hằng ngày qua M09; copy chung; mở trang quản lý khi chạm | Notification chứa tên thuốc, action taken/skipped, AI/điều trị |
| UX | Optional onboarding section and Settings management | Blocking onboarding because permission is denied |

The existing onboarding medication-category selector and treatment note remain
profile metadata and are not converted to schedule entries.

## 2. Actor và quyền

| Actor | Quyền | Giới hạn |
|---|---|---|
| Guest on current device | Create/read/update/pause/delete own local schedules | No cloud transfer except local re-key when the user confirms `mergeNow` |
| Authenticated user on same device | Manage schedules locally re-keyed during confirmed Guest merge | No account snapshot or cross-device sync |
| Notification service (M09) | Schedule/cancel local OS alerts for active local records | Does not decide medicine, dose, or adherence |

Changing to an existing cloud profile follows the current Guest-data cleanup
behavior: Guest-only medicine schedules are not imported. A confirmed merge to
a new account re-keys the local owner inside the same SQLite transaction but
excludes these rows from cloud snapshots.

## 3. Feature map

| ID | Feature | Actor | View |
|---|---|---|---|
| M22-F01 | Nhập lịch nhắc trong onboarding | Guest | M22-V01 |
| M22-F02 | Quản lý lịch trong Cài đặt thông báo | Guest / same-device account | M22-V02 |

## 4. Dữ liệu và luồng

`MedicationReminder` contains a stable local ID, local `user_id`, user-entered
medicine name, a sorted/deduplicated list of minutes after midnight, enabled
state, and timestamps. SQLite persists one row per medicine in
`medication_reminders`; times are serialized as a local list. The table has a
foreign key to `users` and is intentionally absent from sync snapshot tables,
outbox triggers, and Supabase schema.

Onboarding saves the reminder list in the same local transaction as the
profile. Empty list is valid. Every submitted row needs a nonblank name and at
least one valid time (0–1439 minutes). Duplicate times within a row are
deduplicated. No dosage or clinical fields are collected.

M09 derives one generic daily OS reminder per distinct active minute across
the owner's medication rows, so two medicines at the same time do not produce
duplicate alerts. Stable IDs are derived from local owner and minute. The
payload contains only type, owner, and a safe route hint; it never contains a
medicine name. The initialized M09 timezone is used (device timezone with the
existing `Asia/Ho_Chi_Minh` fallback).

## 5. Business rules

| ID | Rule |
|---|---|
| M22-BR01 | Onboarding medicine reminders are optional; zero entries never block completion. |
| M22-BR02 | Each saved entry has a trimmed name and at least one valid daily time; invalid partial entries are rejected without a partial row. |
| M22-BR03 | Schedules repeat daily until paused or deleted; edits reconcile old OS IDs and desired IDs without duplicate delivery. After onboarding, add/rename/time/pause/delete actions are managed in Settings. |
| M22-BR04 | Store schedule definitions locally only. Do not include them in `SyncOutbox`, cloud snapshot, notification history sync, or Supabase. |
| M22-BR05 | On an explicit Guest `mergeNow`, re-key rows locally to the authenticated owner in the same local transaction; on `useExistingCloud`, do not import them. |
| M22-BR06 | Notification title/body are generic; payload/logs contain no medicine name. Tap opens Notification Settings. |
| M22-BR07 | Notification permission denial preserves the schedule and never blocks onboarding; Settings offers the existing permission path. |
| M22-BR08 | The existing global notification master switch disables/re-enables medication reminders; per-entry pause state remains saved. |
| M22-BR09 | App/device does not prescribe, change dosage, or record taken/skipped events in this slice. |
| M22-BR10 | Adding, renaming, changing, pausing, resuming, or deleting a medicine reminder after onboarding is done in Notification Settings. |

## 6. Failure and privacy handling

- SQLite save failure fails the profile transaction and preserves retryable UI
  input; no reminder is scheduled before the transaction commits.
- OS permission denial or scheduling exception leaves the local schedule
  intact, avoids logging medicine values, and can be retried from Settings.
- On startup and after account identity change, refresh active-owner reminders;
  stale owner notifications are cancelled before any new owner schedule is
  applied.
- Deleted/paused rows cancel matching OS reminders; stale payloads only open
  Settings after the current owner and enabled row are validated.

## 7. Dependencies and implementation order

1. Create the local entity/repository/table and migration v34; keep the new
   table outside generic user-data sync.
2. Add onboarding list capture/review and transaction persistence.
3. Add M09 recurring schedule/cancel/reconcile and safe tap navigation.
4. Add Notification Settings list/editor and master-switch refresh.
5. Add local owner re-key to the confirmed Guest merge path.
6. Update this DD and checklists with source/test evidence.

Dependencies: M01 onboarding, M05 guest merge consent, M09 notifications, M19
local privacy boundary. No API or Supabase schema changes.

## 8. Approval record

| Role | Record | State | Date |
|---|---|---|---|
| Product Owner | Explicit user-approved implementation scope, including post-onboarding medicine and schedule management in Settings | Approved for this slice | 2026-10-15 |
| Tech Lead | No separate reviewer identity supplied; design follows current repository architecture | Not separately recorded |
| QA | Acceptance cases defined in `List_Features.md`; execution evidence tracked by worklog | Not separately recorded |

