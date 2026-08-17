# Worklog — Daily Health Hub / Ngày của tôi

## Metadata

- Date: 2026-08-16
- Workflow: `coding`
- Task skill: `coding`
- Primary domain: `lifestyle-schedule`
- Dependent modules: M03 `DASHBOARD_SCHEDULE`, M08 `HEALTH_SCORE_HABITS`, M09 `SCHEDULE_NOTIFICATIONS`
- Source branch: `main`
- M03/M08/M09 DD status before work: Approved / 100%
- Scope guard: no business implementation for M20–M29 advanced clinical modules.

## User requirement

Upgrade the daily schedule into a broader daily health experience:

- add more wellness actions;
- allow users to create their own health tasks;
- support completion actions appropriate to each task instead of forcing camera proof for every task;
- keep local-first health data and reminders;
- keep wellness points server-authoritative and synchronized through Supabase;
- improve the schedule UI into a single “Ngày của tôi” hub.

## Product decisions applied

- Meals and exercise keep the existing camera-proof completion flow.
- Structured health actions use typed check-ins:
  - hydration;
  - mood/stress;
  - sleep;
  - weight;
  - quick wellness completion.
- Manual health tasks support once/daily/weekdays/weekends recurrence over the current 7-day schedule horizon and optional reminders.
- Manual tasks are excluded from the official Daily Schedule / M08 score denominator to prevent user-created task farming from distorting Health Score.
- Standalone quick health logs do not award wellness points.
- Scheduled structured check-ins may receive weighted wellness points only after trusted backend confirmation.
- Manual rewarded completions are capped server-side; the client never writes the wellness ledger.

## Runtime implementation

### Daily Health Hub

Added a local-first Daily Health Hub repository/controller inside Lifestyle Schedule. It provides:

- daily snapshot from `health_tracking_logs`;
- water quick actions;
- mood/stress check-in;
- sleep-hours check-in;
- weight check-in;
- manual task create/edit/delete;
- typed schedule completion and undo;
- durable reward reconciliation.

The UI now presents a “Ngày của tôi” panel above the timeline with current health snapshot, quick actions, manual task entry, and a short Nabi insight.

### Shared completion action policy

Added `ScheduleHealthActionPolicy` so all schedule surfaces resolve one completion mode:

- `photo_proof`;
- `quick_complete`;
- `hydration`;
- `mood_stress`;
- `sleep_checkin`;
- `weight_checkin`.

`LifestyleSchedulePage`, `ScheduleTimeline`, and `TodayTaskCard` use the same policy. This removes the prior inconsistency where “Nhiệm vụ hôm nay” could still open the camera for a water or check-in task.

### Manual tasks

Manual schedule items reuse the existing `lifestyle_schedule_items` schema with:

- `source_type = manual_health_task`;
- metadata encoded in `source_id` for series/action/reminder/repeat;
- `ai_generated = false`;
- standard schedule date/time and completion-window behavior.

No new schedule-item table was added.

### SQLite v19

Database version was bumped from 18 to 19 for one local-only durable table:

- `schedule_health_checkin_outbox`.

The table stores structured reward retry evidence and undo state. It is intentionally not part of the mobile health snapshot. `DatabaseService` includes v19 onCreate, upgrade, and defensive onOpen parity.

### Health Score protection

`DailyScheduleScoreService` moved to `daily_schedule_equal_v2_2026_08` and excludes `manual_health_task` from the score denominator. Generated/approved schedule tasks continue to drive the official daily score.

### Notifications

Manual tasks reuse the existing reminder scheduler. The scheduler now:

- respects the manual task reminder flag;
- avoids camera-specific reminder text for non-photo health actions;
- keeps existing photo-proof wording for tasks that actually require proof.

## Supabase / wellness reward contract

Added `docs/supabase/20260816_daily_health_hub_rewards.sql` and its validation SQL.

The migration adds server-authoritative `schedule_health_checkins` evidence plus:

- `finalize_my_schedule_health_checkin`;
- `undo_my_schedule_health_checkin`;
- weighted action points;
- own-row SELECT RLS only;
- no authenticated direct writes;
- manual task daily reward cap;
- generated-task eligibility enforcement;
- meal/exercise rejection from structured check-in RPCs (`photo_proof_required`).

The existing JPEG `schedule_completion_proofs` contract is not altered and no fake/synthetic proof is created.

Because the current `setup.sql` mobile snapshot function treats generated schedule reward eligibility + active JPEG proof as authoritative, the migration wraps `sync_my_mobile_snapshot(jsonb)` and overlays structured `schedule_health_checkins` after the canonical base sync. This preserves generated typed completions and completed manual tasks without weakening the photo-proof contract.

A transient `eligibility_not_found` from a newly generated task is treated as retryable by the client so reward reconciliation can succeed after eligibility/snapshot synchronization rather than permanently dropping the reward attempt.

## Tests and static validation added

Added focused source tests for:

- action policy mapping;
- manual task exclusion from Daily Schedule score;
- manual recurrence/local persistence;
- health-log merging;
- future standalone check-in rejection;
- durable reward attempt queue;
- reward attempt model;
- SQLite v19 migration;
- manual reminder opt-out and non-camera reminder copy;
- Supabase reward/RLS/snapshot-wrapper static contract.

Validation available in this execution environment:

- Dart lexical delimiter/string/comment balance: PASS for all scoped Dart files.
- Presentation architecture boundary scan: PASS.
- Direct client wellness-ledger mutation scan: PASS.
- SQLite v19 onCreate/upgrade/onOpen parity scan: PASS.
- Supabase migration static contract: PASS for RPCs, RLS, write revocation, manual eligibility policy, snapshot wrapper, and unchanged JPEG proof contract.
- Scope/security package scan: PASS; no `.env`, patch/diff artifact, or M20–M29 implementation added.

Not executed in this environment:

- `dart format`;
- `flutter analyze`;
- `flutter test`;
- Flutter device smoke;
- Supabase sandbox migration/RLS/concurrency smoke.

Reason: Flutter/Dart/PostgreSQL executables are unavailable in this runtime. No PASS claim is made for those gates.

## Remaining production acceptance

1. Apply `docs/supabase/setup.sql` to a disposable clean sandbox and then apply `20260816_daily_health_hub_rewards.sql`.
2. Run `validate_daily_health_hub_rewards.sql` with two authenticated users.
3. Run targeted Flutter format/analyze/tests on the touched paths.
4. Run Android/iOS device smoke for:
   - camera photo task;
   - water/mood/sleep/weight structured task;
   - manual reminder on/off;
   - offline completion then reward retry;
   - undo;
   - cloud sync from a second session/device.
5. Update project-wide coding/DD checklists after those acceptance gates are recorded.

## Self-review

### Output quality

The change keeps one completion policy across schedule surfaces, preserves the existing photo-proof trust boundary, and avoids building parallel notification or schedule persistence systems.

### Completion

The requested source implementation is complete in the scoped change package. Production acceptance remains blocked by unavailable Flutter and Supabase sandbox tooling, not by intentionally omitted source behavior.

### Verification strength

Static verification covers architecture boundaries, SQLite migration parity, reward trust boundaries, SQL/RLS structure, and package scope. Runtime compilation, tests, native behavior, and live RLS still require the canonical toolchain.

### Token/context efficiency

The task stayed on the `coding` workflow with Lifestyle Schedule as the primary domain. Source reads were targeted to the schedule controller/repository/datasource, health logs, notifications, reward gateway, mobile sync function, and directly affected “Nhiệm vụ hôm nay” surface rather than loading the full repository.

### Next-session optimization

Start with targeted Flutter tests and sandbox SQL acceptance from this exact file set. Do not reopen broad project context unless a failing test demonstrates a cross-domain dependency.
