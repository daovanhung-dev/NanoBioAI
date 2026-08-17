# M09 Implementation Delta — Manual health reminders — 2026-08-16

## Decision

Manual health tasks reuse the existing lifestyle schedule reminder scheduler. No second notification subsystem is introduced.

## Contract

- A manual task stores its reminder preference inside the versioned `source_id` metadata contract.
- `reminderEnabled = false` causes `ReminderScheduleService` to exclude that item from candidates.
- `reminderEnabled = true` uses the existing deterministic notification ID/payload and subject isolation.
- Existing generated items keep their current behavior and fallback copy.
- Manual-task fallback copy is generic and does not incorrectly instruct users to take a photo.
- Saving/deleting/editing manual tasks triggers a reminder reschedule after the schedule write succeeds.
