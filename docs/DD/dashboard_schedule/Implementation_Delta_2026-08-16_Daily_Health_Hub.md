# M03 Implementation Delta — Daily Health Hub — 2026-08-16

## Status

Approved by user instruction in the 2026-08-16 implementation session.

## Scope

Upgrade the existing daily lifestyle schedule into a single “Ngày của tôi” health-care surface while preserving M03 completion-window, M08 score, M09 notification, cloud-sync and wellness-reward trust boundaries.

## Product decisions

1. Keep meal and exercise completion on the existing camera-proof flow.
2. Add lightweight health actions for non-photo schedule items:
   - quick completion;
   - hydration amount;
   - mood + stress check-in;
   - sleep-hours check-in;
   - weight check-in.
3. Allow users to create manual health tasks with title, description, time, bounded seven-day recurrence and reminder preference.
4. Manual tasks are stored as `source_type = manual_health_task`, `ai_generated = false`; action/reminder/repeat metadata is encoded in `source_id` without adding a new SQLite column.
5. Manual tasks may participate in the Daily Health Hub progress UI but are excluded from the official M08 Health Score formula to prevent self-authored task gaming.
6. Health metrics are local-first in `health_tracking_logs` and continue through the existing sync outbox.
7. Non-photo reward check-ins use a dedicated Supabase RPC; the client never increments the wellness wallet.
8. Manual-task rewards are limited server-side to four rewarded manual completions per user/day. Existing meal/exercise photo reward policy is unchanged.
9. Standalone quick health logs (outside a scheduled task) update health tracking only and do not award points.
10. M20–M29 advanced clinical modules remain outside scope and are not implemented by this delta.

## Runtime flow

```text
Ngày của tôi
  -> DailyHealthHubPanel
      -> health_tracking_logs snapshot
      -> quick standalone check-in (no reward)
      -> create/edit/delete manual schedule task
  -> ScheduleTimeline
      -> meal/exercise -> existing camera proof controller
      -> non-photo -> DailyHealthHubController
          -> DailyHealthHubRepository
          -> DailyHealthHubLocalDatasource
          -> SQLite transaction
              -> health_tracking_logs when applicable
              -> lifestyle_schedule_items completion
              -> linked daily_health_task when applicable
              -> official daily score (manual items excluded)
          -> local sync outbox
          -> Supabase health-check-in reward RPC when authenticated
```

## Persistence

The core schedule and health-log schemas do not need new columns. A SQLite v19 migration adds one **local-only durable reward retry outbox** so an authenticated health check-in cannot lose its server reward attempt when connectivity fails:

- `lifestyle_schedule_items`: category/source/target/current/completion/manual flag fields;
- `health_tracking_logs`: water/sleep/stress/mood/weight/daily score;
- `health_score_ledgers`: versioned score projection;
- `schedule_health_checkin_outbox` (v19): pending/confirmed/not-eligible/undo-pending/reversed reward retry state. It is not part of the mobile health snapshot payload.

## Supabase delta

`docs/supabase/20260816_daily_health_hub_rewards.sql` adds:

- `schedule_health_checkins` server-owned evidence rows;
- server-owned weighted reward-point mapping;
- `finalize_my_schedule_health_checkin`;
- `undo_my_schedule_health_checkin`;
- RLS/read-only mobile table policy;
- manual reward anti-farming limit;
- a compatibility wrapper around `sync_my_mobile_snapshot` that reapplies the latest server-owned structured check-in state after the existing snapshot logic, without relaxing the JPEG camera-proof contract.

Generated structured check-ins reuse existing generated eligibility but do **not** create fake photo-proof rows. Manual tasks keep `eligibility_id = NULL`, so they cannot be misclassified as generated/photo tasks. The RPC stores validated self-report evidence but does not directly write `health_tracking_logs`; the existing local-first sync path remains the only health-log synchronization path, preventing double application.

## Acceptance criteria

- Meal/exercise still open the camera-proof detail flow.
- Water task can record 250/500 ml and complete within the existing window.
- Mood/stress task records mood + stress level.
- Sleep and weight tasks validate bounded numeric input.
- Quick tasks complete without camera.
- Manual task recurrence creates at most seven days of rows per edit/create operation.
- Reminder-disabled manual tasks are not scheduled by M09.
- Manual tasks never change official Health Score.
- No client code directly writes positive wellness points.
- M20–M29 health-module persistence/API/device flows remain untouched.
