# M08 Implementation Delta — Manual task score isolation — 2026-08-16

## Decision

Daily Health Hub introduces user-authored `manual_health_task` schedule rows. These rows are intentionally excluded from the official schedule-derived Health Score so a user cannot improve the score by creating arbitrarily easy personal tasks.

## Formula contract

- Previous runtime formula: `daily_schedule_equal_v1_2026_07`.
- New runtime formula: `daily_schedule_equal_v2_2026_08`.
- Scoring remains equal-weight completion across due **system/generated** schedule items.
- `manual_health_task` rows remain visible in schedule progress and can use the separately governed wellness-reward rules, but do not enter `dueItems` or `completedDueItems` for M08.
- A new formula version is required because the eligibility set changed.

## Evidence

- `DailyScheduleScoreService` filters `manual_health_task` before due-item evaluation.
- Focused unit test verifies two completed manual tasks do not change a generated-task score of 50%.
