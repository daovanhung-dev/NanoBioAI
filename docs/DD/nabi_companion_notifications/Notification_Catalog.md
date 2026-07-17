# Notification Catalog — M30

All content traces to `BD-NABI-NOTIFICATION-001` §§9-15. `I` is in-app and `O`
is local OS notification. Copy, benefits and dynamic values are versioned config;
missing values disable the occurrence.

| ID | Audience/trigger | Destination key | Channel | Dependency |
|---|---|---|---|---|
| `NBI-FREE-001` | Free asks beyond 3 plan days or quota; Guest reaches 7-day horizon | `membership_compare`, return intent | I | M02/M06 |
| `NBI-FREE-002` | Free successful chat #2; denied attempt #4 | `membership_compare`, focus chat | I | M06/M07 |
| `NBI-FREE-003` | Free first 7-day required-task streak | `membership_compare` / `achievement` | I+O | M03/M08 |
| `NBI-FREE-004` | Free opens locked expert action | `expert_benefit` | I | Expert read model |
| `NBI-FREE-005` | Free taps locked Map 365 milestone | `membership_compare`, focus roadmap | I | Map 365 read model |
| `NBI-FREE-006` | Free opens full weekly report | `membership_compare` / `weekly_report_summary` | I | Reporting |
| `NBI-FREE-007` | Trusted classifier returns `expert_recommended` | `expert_benefit`, preserve draft | I | M07/expert |
| `NBI-ANNUAL-001` | Plus/monthly active day 7 | `membership_compare`, yearly | I+O | M06/M13 |
| `NBI-ANNUAL-002` | Plus/monthly day 15 and readiness config met | `membership_compare`, yearly | I+O | M03/M06/M13 |
| `NBI-ANNUAL-003` | Plus/monthly expiry T-5 | `membership_compare`, yearly | I+O | M06/M13 |
| `NBI-ANNUAL-004` | Plus/monthly expiry T-1 | `membership_payment`, yearly | I+O | M08/M13 |
| `NBI-STREAK-001` | Streak 6 and today incomplete | `easiest_task` | I+O | M03 |
| `NBI-STREAK-002` | Streak lost and rescue card valid | `rescue_card_confirm` | I+O | M03/M08 |
| `NBI-REWARD-001` | Configured 3/7/15/30 milestone unclaimed | `reward_box` | I+O | M08 |
| `NBI-REPORT-001` | Weekly report ready and unread | `weekly_report` | I+O | Reporting |
| `NBI-REFERRAL-001` | Plus/yearly has invite allowance | `user_invite` | I | User invite |
| `NBI-CARE-001` | Near sleep and at least two required tasks remain | `easiest_task` | I+O | M03/profile |
| `NBI-CARE-002` | Foreground return after ≥72 hours | `dashboard_today` | I | M05 |
| `NBI-CARE-003` | Partial day or streak lost without rescue message | `today_tasks` | I+O | M03/M08 |
| `NBI-PROFILE-001` | Required field missing or profile stale >30 days | `partial_profile` | I+O | M01/M05 |

## Catalog invariants

- FamilyPlus is eligible only for care/reward/profile entries.
- Contextual entries are in-app only. Foreground wins over an OS twin for the same occurrence.
- `rewardPoints`, reward/invite limit, benefit list and readiness thresholds must come from active config.
- Each definition includes effective window, content version, priority, cooldown, max displays, policy key,
  action key, allowed channels, emotion and required template variables.

