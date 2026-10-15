# Function List — M22 / Lịch dùng thuốc

| ID | Layer / function | Input → output | Owner / side effects | Error / test trace |
|---|---|---|---|---|
| M22-FN01 | Onboarding controller/entity: validate draft entries | `List<MedicationReminderInput>` → valid list or field errors | M01 controller; no I/O | Empty list valid; invalid row blocks continuation until completed or removed. M22-AC01..04 |
| M22-FN02 | Repository/datasource: save onboarding profile and reminders atomically | Onboarding entity + local owner → committed profile and local reminder rows | SQLite transaction; no outbox write | Roll back together on failure; retry uses stable IDs. M22-AC02, AC10 |
| M22-FN03 | M09 coordinator: reconcile daily reminders | Active local rows + owner → scheduled/cancelled OS IDs | Local notification plugin; no notification-history row/cloud write | Permission denied preserves rows; failures are retryable. M22-AC05..08 |
| M22-FN04 | Settings controller/repository: load and mutate reminders | owner + create/rename/update/pause/delete request → updated rows | SQLite then M09 reconcile | Reject invalid edits; keep prior row on failed mutation. M22-AC06..08, AC11..12 |
| M22-FN05 | M05 local sync projection: preserve schedule on confirmed Guest merge | guest owner + auth owner + `mergeNow` → locally re-keyed rows | One SQLite transaction; no cloud snapshot change | `useExistingCloud` keeps existing guest cleanup behavior. M22-AC09 |

## Contracts

- Domain entity: stable ID, local owner ID, exact user-entered name, sorted
  unique minute-of-day values, enabled flag, created/updated timestamps.
- Settings repository operations: list by owner, create a medicine/schedule,
  rename the medicine, update times, set enabled, and delete. After onboarding,
  these changes are managed in Notification Settings. Onboarding persists the
  initial reminder set in its profile transaction; confirmed Guest merge
  performs the local owner re-key.
- M09 uses a deterministic notification ID per `(owner, minute-of-day)` and a
  daily zoned schedule. Same-owner entries at the same minute are coalesced.
- Notification payload contains only a version/type, owner key, and generic
  navigation intent. It is validated against current owner and active schedule.
- No HTTP/Supabase API is introduced. The medication table is excluded from
  `UserDataSyncTables` and outbox schema.

