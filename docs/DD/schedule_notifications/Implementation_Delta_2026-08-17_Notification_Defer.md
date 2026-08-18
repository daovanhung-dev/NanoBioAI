# Implementation Delta — Schedule notification defer — 2026-08-17

## Product decision

The schedule-reminder secondary action **“Để sau”** means **Defer/Snooze for 30 minutes**. It is not a task skip.

## Canonical semantics

```text
pending source item
  -> user taps “Để sau”
  -> notification action_status = deferred
  -> notification scheduled_at = response time + 30 minutes
  -> source item remains pending
  -> local OS reminder is scheduled again
```

No schedule completion, meal completion, daily-health-task completion, Health Score, or Wellness Point is created by defer.

## Action identifiers and compatibility

- New canonical action id: `defer`.
- New notifications emit `defer` for the “Để sau” button.
- Legacy delivered notifications may still return `skipped`; the action handler normalizes this input to `defer`.
- `skipped` is not a new canonical source/task status.

## Durable state

No SQLite schema/version increase is required. Existing notification fields are reused:

- `action_status = deferred`;
- `scheduled_at = next delivery time`;
- `responded_at = time of user action`;
- `payload.scheduledAt = next delivery time`.

The deferred row remains the durable reminder record. A later valid delivery may be deferred again for another 30 minutes.

## Idempotency / stale callbacks

A callback from the previous delivery is stale after defer rewrites `scheduled_at` and payload. If its payload timestamp no longer matches the durable row timestamp, it is ignored and must not extend the reminder by another 30 minutes.

## Refresh after source changes

When generated reminders are refreshed:

- a deferred source that still exists and is incomplete keeps its deferred delivery time;
- title/body/payload may be refreshed from current source content (for example after replacing a meal);
- completed, removed, or wrong-subject sources cancel/delete the deferred reminder;
- due/past deferred deliveries are not duplicated by a normal refresh.

## Failure behavior

If native rescheduling fails, notification state becomes `schedule_failed`; the source task still remains pending. The system must not award points or silently mark the task complete.

## M30 boundary

This 30-minute M09 schedule-reminder defer is independent from the M30 Nabi companion occurrence defer. M30 retains its separate 24-hour defer policy.
