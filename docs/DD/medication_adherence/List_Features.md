# List Features — M22 / Lịch dùng thuốc

## 0. Thông tin

| Trường | Giá trị |
|---|---|
| Module | M22 `MEDICATION_ADHERENCE` |
| Overall | [Overall.md](Overall.md) |
| Version / updated | v1.0.1 / 2026-10-15 |

## 1. Feature inventory

| ID | Feature | Actor / trigger | Priority | Functions | Views | Decision / implementation |
|---|---|---|---|---|---|---|
| M22-F01 | Nhập tên và giờ nhắc trong onboarding | Guest; mở mục thuốc và thêm lịch | P0 | M22-FN01, FN02 | M22-V01 | Approved slice; source implemented; persistence/device verification pending |
| M22-F02 | Thêm và quản lý thuốc/lịch nhắc | Guest / same-device account; mở Cài đặt thông báo | P0 | M22-FN03, FN04, FN05 | M22-V02 | Approved slice; source implemented; SQLite/device verification pending |

## 2. M22-F01 — Nhập lịch nhắc

**Source:** Advanced Health BD §M22, M22-BR01..03, 2026-10-15 addendum; explicit user instruction.

1. User may add zero or more reminder entries inside the existing onboarding
   medication accordion.
2. Each entry has exact medicine name and one or more time-of-day values;
   times repeat daily until disabled or deleted.
3. User may add/remove entries and times; review step summarizes names/times.
4. Empty schedule is valid. An incomplete entry is not saved and is explained
   inline; onboarding can continue after removing or completing it.
5. Existing medicine categories and free-text treatment note keep their
   current meaning.

**Acceptance:**

- M22-AC01: Empty reminder list completes onboarding.
- M22-AC02: Multiple medicines and multiple times per medicine persist and
  appear in review with correct local time.
- M22-AC03: Blank name, no time, or invalid time cannot create a partial row.
- M22-AC04: Existing category selection and treatment note behavior is intact.
- M22-AC05: Permission denial does not discard saved schedules or block
  onboarding.

## 3. M22-F02 — Quản lý lịch nhắc

**Source:** Advanced Health BD §M22 M09 dependency, M22-BR01..03, 2026-10-15 addendum.

User can add a medicine with one or more times, rename it, edit reminder times,
pause/resume an entry, or delete its schedule. After onboarding these changes
are managed in Notification Settings. The shared M09 coordinator reconciles OS
schedules after each mutation and app startup. Notification Settings global
master switch controls delivery without erasing per-entry state.

**Acceptance:**

- M22-AC06: Pause/delete cancels matching OS IDs; resume/edit schedules the
  desired daily set and leaves no obsolete IDs.
- M22-AC07: Identical active times are coalesced into one generic alert.
- M22-AC08: Notification content and payload do not disclose medicine names;
  a valid tap opens the management view.
- M22-AC09: Guest merge re-keys local rows only for explicit merge; rows are
  excluded from cloud snapshot. Existing-cloud selection does not import them.
- M22-AC10: Local data remains available after app restart and remains absent
  from SyncOutbox/Supabase snapshots.
- M22-AC11: After onboarding, the user can add a medicine and its schedule in
  Settings; the new entry is shown with its saved name and times.
- M22-AC12: Renaming or deleting a medicine schedule in Settings updates or
  removes the in-app entry while notification content remains generic.

## 4. Out of scope

Dose/form, date range or weekday recurrence, taken/skipped/snoozed history,
adherence scoring, medical advice, AI, FamilyPlus, cross-device sync, and
cloud schema are not part of these features.

