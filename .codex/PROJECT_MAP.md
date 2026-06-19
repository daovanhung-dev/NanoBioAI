# PROJECT_MAP - NanoBio / BioAI

Dung file nay de chon dung source can doc. Khong doc tran lan.

## Current Source Map

- App bootstrap: `lib/main.dart`
- Router/app shell: `lib/core/router/`, `lib/app/app.dart`
- Theme/design tokens: `lib/core/theme/`
- SQLite core: `lib/core/storage/localdb/`
- AI service: `lib/services/ai/`
- Notifications: `lib/services/notifications/`
- Supabase auth: `lib/services/supabase/`
- Tests: `test/`

Feature folders hien co:

```text
ai_chat, auth, community, daily_health_tracking, dashboard,
features_hub, lifestyle_schedule, meal_plan, nutrition, onboarding,
other, profile, settings, sleep_tracking, splash, stress_tracking
```

## Task Routing

### Dashboard / Health Score / Trang chu

Doc:

- `.codex/playbooks/dashboard.md`
- `lib/features/dashboard/`
- `lib/features/daily_health_tracking/`
- `lib/features/lifestyle_schedule/`
- Test lien quan: `test/features/dashboard/`, `test/features/daily_health_tracking/`, `test/features/lifestyle_schedule/`

Tap trung: dashboard doc SQLite that qua provider/repository/datasource, score/progress/timeline khong dung mock production.

### Onboarding

Doc:

- `.codex/playbooks/onboarding.md`
- `lib/features/onboarding/`
- DAOs/models lien quan profile/goals/habits/conditions/allergies/treatments/survey answers.
- `lib/main.dart` neu task lien quan callback sau onboarding.

Tap trung: validate, luu du ho so, kich hoat meal/exercise/schedule.

### AI / Meal Plan / Exercise Parser

Doc:

- `.codex/playbooks/ai_service.md`
- `lib/services/ai/`
- `lib/features/meal_plan/`
- `lib/features/lifestyle_schedule/data/models/*normalizer*`
- `test/services/ai/`, `test/features/meal_plan/`, `test/features/lifestyle_schedule/`

Tap trung: schema, validator, normalizer, fallback, tieng Viet co dau, khong goi API that trong test.

### Lifestyle Schedule / Timeline

Doc:

- `.codex/playbooks/lifestyle_schedule.md`
- `lib/features/lifestyle_schedule/`
- `lib/services/notifications/` neu lien quan reminder/action.
- `test/features/lifestyle_schedule/`

Tap trung: meal + exercise + hydration + sleep, status pending/completed/skipped, khong tao item trung.

### Daily Health Tracking

Doc:

- `.codex/playbooks/health_tracking.md`
- `lib/features/daily_health_tracking/`
- health tracking logs/tasks DAO/table/model.
- `test/features/daily_health_tracking/`

Tap trung: validate range, upsert theo ngay, dashboard integration.

### Notification / Reminder / Action Button

Doc:

- `.codex/playbooks/notification.md`
- `lib/services/notifications/`
- schedule/task/notification DAO/service lien quan.
- `test/services/notifications/`

Tap trung: timezone init, stable id, payload parse, background action khong can `BuildContext`, complete/skip update SQLite.

### SQLite / DAO / Migration

Doc:

- `.codex/playbooks/sqlite.md`
- `lib/core/storage/localdb/database_version.dart`
- `lib/core/storage/localdb/database_service.dart`
- `lib/core/storage/localdb/migrations/`
- `lib/core/storage/localdb/tables/`
- `lib/core/storage/localdb/models/`
- `lib/core/storage/localdb/daos/`
- `test/core/storage/localdb/`

Tap trung: doi schema phai dong bo version, migration, onCreate, table, model, DAO, test.

### UI / Theme / Nami Copywriting

Doc:

- `.codex/playbooks/ui_nami.md`
- `lib/core/theme/`
- page/widget cua feature lien quan.
- Widget tests lien quan neu co.

Tap trung: theme tokens, responsive, no overflow, copy Nami, khong lo thuat ngu ky thuat.

### Settings / Profile / Auth

Doc theo pham vi:

- `lib/features/settings/`, `test/features/settings/`
- `lib/features/profile/`
- `lib/features/auth/`, `lib/services/supabase/`, `lib/core/router/`

Tap trung: state/session, validation, khong lo secret, khong pha route guard.

## Search Commands

```bash
rg "ClassName|providerName|routeName|tableName" lib test
rg "mock|fake|sample|dummy" lib/features
rg "Provider|AsyncNotifier|Repository|Datasource|Dao|DAO" lib/features/<feature> lib/services test
rg "CREATE TABLE|ALTER TABLE|databaseVersion|onCreate|migration" lib/core/storage/localdb test
rg "notification|payload|timezone|reminder|complete|skip" lib/services lib/features test
rg "Gemini|generateContent|validator|normalizer|catalog|fallback" lib/services/ai lib/features test
```

Architecture checks:

```bash
rg "import.*core/storage/localdb|import.*data/datasources" lib/features/*/presentation
rg "import.*package:nano_app/features/.*/data" lib/features/*/presentation
```

## Critical Files

Chi mo khi lien quan:

- `lib/main.dart` - app init, callback sau onboarding.
- `lib/core/router/app_router.dart` - navigation/routes.
- `lib/core/storage/localdb/database_service.dart` - DB init/onCreate.
- `lib/core/storage/localdb/database_version.dart` - DB version.
- `lib/services/ai/ai_service.dart` - Gemini integration.
- `lib/services/ai/ai_trace_logger.dart` - AI trace logging an toan.
- `lib/services/notifications/notification_bootstrap.dart` - notification init/action.
- `lib/services/notifications/notification_action_handler.dart` - complete/skip action.
- `test/architecture_preservation_property_test.dart` va `test/architecture_violation_exploration_test.dart` - kien truc/rui ro hien co.
