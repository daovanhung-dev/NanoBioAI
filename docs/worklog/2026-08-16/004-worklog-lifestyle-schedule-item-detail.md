# Worklog — Lifestyle Schedule item detail

## Metadata

- Date: 2026-08-16
- Workflow: coding
- Task skill: coding
- Domain: lifestyle-schedule
- Module: M03 `DASHBOARD_SCHEDULE`
- DD status before work: Approved / 100%
- Coding progress before work: 100%
- Scope: progressive disclosure for each timeline item; no new business rule, persistence, quota, reward, or access contract.

## User requirement

- Tap the whole timeline card to open a dedicated detail screen.
- Keep the circular completion action independent.
- Detail shows full task information, status, description, target/progress, Nabi guidance, completion window, proof image, completion time, and wellness reward status.
- When the item is inside the approved 30-minute completion window, the detail screen may invoke the existing camera completion flow.

## Implementation

### Timeline interaction

- `ScheduleTimeline` now treats the item card as the detail navigation target.
- The completion circle remains the inner gesture target; tapping it does not open detail.
- Updated the timeline helper copy so users can discover the detail interaction.

### Detail screen

Added `LifestyleScheduleItemDetailPage` and pure `LifestyleScheduleItemDetailContent`.

The screen renders:

- full title and status;
- date and start/end time;
- category;
- full description without timeline truncation;
- quantitative target/progress when applicable;
- Nabi encouragement when present;
- completion-window explanation;
- completion timestamp;
- active proof image through the existing `ScheduleProofPreviewSection`;
- reward projection based only on `ScheduleCompletionProofEntity.rewardStatus`;
- completion CTA only when `item.canCompleteAt(now)` is true.

### State and completion reuse

No new DAO/repository path was added. The detail screen watches the existing `lifestyleScheduleControllerProvider` and resolves the same item by ID from its authoritative projection, falling back to the tapped item only while the provider is transitioning. This avoids a second read model and preserves the existing:

`Presentation -> Controller -> Repository -> Datasource -> DAO/API`

Completion from detail calls the existing `LifestyleScheduleController.toggleItem()`; therefore camera permission handling, local proof persistence, app-resume race guard, idempotent `alreadyCompleted` handling, Supabase upload/finalize, and reward reconciliation remain shared.

## Reward trust boundary

- The UI never increments points.
- `+10 Điểm chăm sóc` is shown only for `rewardStatus == confirmed`.
- `pending`, `not_eligible`, `reversed`, and legacy non-redeemable states use distinct copy.

## Tests added/updated

- Timeline card detail action callback.
- Completion-circle gesture does not bubble to the surrounding detail tap target.
- Open detail shows full description/status/time and invokes completion CTA.
- Waiting detail disables CTA.
- Confirmed reward displays +10.
- Pending reward does not look confirmed.

## Validation in this environment

- Static delimiter balance: PASS for touched Dart files.
- Client-side point increment scan: PASS.
- No DAO/Database access introduced in the detail presentation files: PASS.
- Flutter/Dart executable: unavailable in this environment, so `dart format`, `flutter analyze`, and `flutter test` could not be executed here.

## Self-review

- Business completion window remains unchanged.
- Detail CTA reuses the camera/reward controller instead of duplicating completion logic.
- Proof display reuses the existing private-local/cloud-restorable proof presentation.
- The implementation intentionally avoids new schema/API/repository surface because the controller already owns the authoritative schedule + proof projection needed by this screen.
- M03 remains 100%; this is presentation depth on an approved/runtime-complete module, not a new completion claim.
