# Domain Map

Use one domain context file by default.

| Domain                          | File                                           | Source roots                                                                                   |
| ------------------------------- | ---------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| Dashboard/health score/home     | `.codex/domains/dashboard.md`                  | `lib/app_versions/v1/features/dashboard/`                                                      |
| Onboarding/profile assessment   | `.codex/domains/onboarding.md`                 | `lib/app_versions/v1/features/onboarding/`                                                     |
| AI/meal/exercise/chat           | `.codex/domains/ai-service.md`                 | `lib/app_versions/v1/services/ai/`, meal/schedule/task features                                |
| Access/auth/membership/referral | `.codex/domains/access-membership-referral.md` | `lib/app_versions/v2/`, `lib/app_versions/v3/`, `lib/sale_referral/`, `lib/services/supabase/` |
| Notification/reminder/action    | `.codex/domains/notification.md`               | `lib/app_versions/v1/services/notifications/`                                                  |
| SQLite/DAO/migration            | `.codex/domains/sqlite.md`                     | `lib/core/storage/localdb/`                                                                    |
| UI/theme/Nabicopy               | `.codex/domains/ui-Nabi.md`                    | `lib/core/theme/`, feature presentation files                                                  |
| Daily health tracking           | `.codex/domains/health-tracking.md`            | `lib/app_versions/v1/features/daily_health_tracking/`                                          |
| Lifestyle schedule/timeline     | `.codex/domains/lifestyle-schedule.md`         | `lib/app_versions/v1/features/lifestyle_schedule/`                                             |

If a task crosses domains, read the primary domain first, then the second domain only after confirming the dependency by `rg`.
