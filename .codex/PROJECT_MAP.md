# PROJECT_MAP — NanoBio / BioAI

File này giúp Codex chọn đúng tài liệu và đúng vùng source code. Chỉ đọc file cần thiết cho task.

## Global entry points

- App bootstrap: `lib/main.dart`
- App shell/router: `lib/app/`, `lib/core/router/`
- Theme/design system: `lib/core/theme/`
- Local DB: `lib/core/storage/localdb/`
- AI service: `lib/services/ai/`
- Notification service: `lib/services/notifications/`

## Task routing

### Dashboard / health score / trang chủ

Read:

- `.codex/playbooks/dashboard.md`
- `lib/features/dashboard/`
- `lib/features/daily_health_tracking/`
- `lib/features/lifestyle_schedule/`
- `lib/core/storage/localdb/daos/health_tracking_logs_dao.dart`
- `lib/core/storage/localdb/tables/daily_health_tasks_table.dart`
- `lib/core/storage/localdb/tables/lifestyle_schedule_items_table.dart`

Focus: Dashboard phải tính từ SQLite/data layer thật; không mock/fake production.

### Onboarding

Read:

- `.codex/playbooks/onboarding.md`
- `lib/features/onboarding/`
- DAOs liên quan: users, health_profiles, health_goals, lifestyle_habits, conditions, allergies.

Focus: Sau onboarding phải lưu đủ hồ sơ và kích hoạt tạo lịch trình cá nhân.

### Meal plan / exercise / AI parser

Read:

- `.codex/playbooks/ai_service.md`
- `lib/services/ai/`
- `lib/features/meal_plan/`
- Các normalizer/catalog/seed liên quan nếu có.

Focus: AI output không crash; text hiển thị tiếng Việt có dấu; test không gọi API thật.

### Notification / reminder / action button

Read:

- `.codex/playbooks/notification.md`
- `lib/services/notifications/`
- `lib/features/daily_health_tracking/`
- `notifications_dao` nếu có.

Focus: Timezone init, payload parse, id ổn định, action lưu DB.

### SQLite / DAO / migration

Read:

- `.codex/playbooks/sqlite.md`
- `lib/core/storage/localdb/database_service.dart`
- `lib/core/storage/localdb/database_version.dart`
- `lib/core/storage/localdb/migrations/`
- `lib/core/storage/localdb/tables/`
- `lib/core/storage/localdb/models/`
- `lib/core/storage/localdb/daos/`

Focus: Đổi schema phải đi đủ table/model/DAO/migration/onCreate.

### UI / theme / copywriting Nami

Read:

- `.codex/playbooks/ui.md`
- `lib/core/theme/`
- Widgets/pages của feature liên quan.

Focus: Dùng theme token, responsive, không overflow, tiếng Việt có dấu.

## Search commands ưu tiên

```bash
rg "ClassName|providerName|routeName|tableName" lib test
rg "mock|fake|sample|dummy|TODO" lib/features/dashboard lib/features/onboarding
rg "Gemini|generate|validator|normalizer" lib/services/ai lib/features
rg "notification|payload|timezone|reminder" lib/services/notifications lib/features
```
