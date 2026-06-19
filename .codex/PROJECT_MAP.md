# PROJECT_MAP - NanoBio / BioAI

Dung file nay de chon dung source can doc. Khong doc tran lan.

## Current Source Map

- App bootstrap: `lib/main.dart`
- Router/app shell: `lib/core/router/`, `lib/app/app.dart`
- Constants/interfaces/network/utils: `lib/core/constants/`, `lib/core/interfaces/`, `lib/core/network/`, `lib/core/utils/`
- Theme/design tokens: `lib/core/theme/`
- SQLite core: `lib/core/storage/localdb/`
- AI service: `lib/services/ai/`
- Notifications: `lib/services/notifications/`
- Supabase auth: `lib/services/supabase/`
- Biometric/image picker services: `lib/services/biometric/`, `lib/services/image_picker/`
- Shared widgets: `lib/shared/widgets/`
- Tests: `test/`
- Product/design docs: `docs/DD/`, `docs/features/`
- Issues/todo/worklog: `docs/issues/`, `docs/todo/`, `docs/worklog/`

Feature folders hien co:

```text
ai_chat, auth, body_metrics, community, daily_health_tracking,
dashboard, features_hub, gentle_care_mode, lifestyle_schedule,
meal_plan, nutrition, onboarding, other, personal_goals, profile,
quick_care, settings, sleep_tracking, splash, stress_tracking,
water_tracking, weekly_summary
```

## Task Routing

### Dashboard / Health Score / Trang chu

Doc:

- `.codex/playbooks/dashboard.md`
- `lib/features/dashboard/`
- `lib/features/daily_health_tracking/`
- `lib/features/lifestyle_schedule/`
- Neu can: `lib/features/meal_plan/`, `lib/services/notifications/`
- Tests: `test/features/dashboard/`, `test/features/daily_health_tracking/`, `test/features/lifestyle_schedule/`

Tap trung: dashboard doc SQLite that qua provider/repository/datasource, score/progress/timeline khong dung mock production.

### Onboarding / Profile Assessment

Doc:

- `.codex/playbooks/onboarding.md`
- `lib/features/onboarding/`
- `lib/main.dart` neu task lien quan callback sau onboarding.
- DAOs/models lien quan profile/goals/habits/conditions/allergies/treatments/survey answers.

Tap trung: validate, luu du ho so, kich hoat meal/exercise/schedule.

### AI / Meal Plan / Exercise Parser / AI Chat

Doc:

- `.codex/playbooks/ai_service.md`
- `lib/services/ai/`
- `lib/features/meal_plan/`
- `lib/features/ai_chat/`
- `lib/features/lifestyle_schedule/data/models/*normalizer*`
- `lib/features/daily_health_tracking/data/models/*normalizer*`
- Tests: `test/services/ai/`, `test/features/meal_plan/`, `test/features/lifestyle_schedule/`, `test/features/daily_health_tracking/`

Tap trung: schema, validator, normalizer, fallback, dotenv/API key, token/context growth, tieng Viet co dau, khong goi API that trong test.

### Lifestyle Schedule / Timeline

Doc:

- `.codex/playbooks/lifestyle_schedule.md`
- `lib/features/lifestyle_schedule/`
- `lib/services/notifications/` neu lien quan reminder/action.
- Meal/daily task DAO/service neu schedule lay nguon tu do.
- Tests: `test/features/lifestyle_schedule/`, `test/services/notifications/`

Tap trung: meal + exercise + hydration + sleep, status pending/completed/skipped, khong tao item trung.

### Daily Health Tracking

Doc:

- `.codex/playbooks/health_tracking.md`
- `lib/features/daily_health_tracking/`
- health tracking logs/tasks DAO/table/model.
- Tests: `test/features/daily_health_tracking/`

Tap trung: validate range, upsert theo ngay, dashboard integration.

### Notification / Reminder / Action Button

Doc:

- `.codex/playbooks/notification.md`
- `lib/services/notifications/`
- `lib/features/lifestyle_schedule/`
- schedule/task/notification DAO/service lien quan.
- Tests: `test/services/notifications/`, `test/features/lifestyle_schedule/`

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
- Tests: `test/core/storage/localdb/`

Tap trung: doi schema phai dong bo version, migration, onCreate, table, model, DAO, test.

### UI / Theme / Nami Copywriting

Doc:

- `.codex/playbooks/ui_nami.md`
- `lib/core/theme/`
- page/widget cua feature lien quan.
- Widget tests lien quan neu co.

Tap trung: theme tokens, responsive, no overflow, copy Nami, khong lo thuat ngu ky thuat.

### Settings / Profile / Auth / Splash

Doc theo pham vi:

- `lib/features/settings/`, `test/features/settings/`
- `lib/features/profile/`
- `lib/features/auth/`, `lib/services/supabase/`, `lib/core/router/`
- `lib/features/splash/`

Tap trung: state/session, validation, route guard, khong lo secret.

### Feature Hub / Care Pages / Tracking Pages

Doc:

- `.codex/playbooks/ui_nami.md` neu chu yeu UI/copy.
- `.codex/playbooks/health_tracking.md` neu co tracking data.
- `lib/features/features_hub/`
- `lib/features/body_metrics/`
- `lib/features/gentle_care_mode/`
- `lib/features/personal_goals/`
- `lib/features/quick_care/`
- `lib/features/water_tracking/`
- `lib/features/sleep_tracking/`
- `lib/features/stress_tracking/`
- `lib/features/weekly_summary/`
- Tests: `test/features/features_hub/` va tests gan nhat neu co.

Tap trung: phan biet UI session-only voi data persisted; neu them persistence phai di qua provider/repository/datasource/DAO.

### Docs / DD / Issue / Todo

Doc:

- `.codex/DOCS_WORKFLOW.md`
- `.codex/ISSUE_TODO_WORKFLOW.md` neu lien quan issue/todo.
- `docs/DD/README.md`, `docs/DD/MODULE_INDEX.md` neu user yeu cau DD.
- Folder docs cu the user nhac.

Tap trung: khong sua code khi mode chi la docs/find-issues/create-todo; worklog dung so `NNN`.

## Search Commands

```bash
rg "ClassName|providerName|routeName|tableName" lib test
rg "mock|fake|sample|dummy" lib/features
rg "Provider|AsyncNotifier|Notifier|Repository|Datasource|Dao|DAO" lib/features/<feature> lib/services test
rg "CREATE TABLE|ALTER TABLE|databaseVersion|currentVersion|onCreate|migration" lib/core/storage/localdb test
rg "notification|payload|timezone|reminder|complete|skip" lib/services lib/features test
rg "Gemini|generateContent|validator|normalizer|catalog|fallback|dotenv|ChatSession" lib/services/ai lib/features test
```

Architecture checks:

```bash
rg "import.*core/storage/localdb|import.*data/datasources" lib/features/*/presentation
rg "import.*package:nano_app/features/.*/data" lib/features/*/presentation
```

Inventory commands:

```bash
rg --files -g '!build/**' -g '!.dart_tool/**' -g '!.git/**'
Get-ChildItem lib\features -Directory
Get-ChildItem test -Directory
```

## Critical Files

Chi mo khi lien quan:

- `lib/main.dart` - app init, callback sau onboarding.
- `lib/core/router/app_router.dart` - navigation/routes.
- `lib/core/router/route_guards.dart` - auth/session guards.
- `lib/core/storage/localdb/database_service.dart` - DB init/onCreate.
- `lib/core/storage/localdb/database_version.dart` - DB version.
- `lib/services/ai/ai_service.dart` - Gemini plan integration.
- `lib/services/ai/ai_chat_service.dart` - AI chat session/context/API key.
- `lib/services/ai/ai_trace_logger.dart` - AI trace logging an toan.
- `lib/services/notifications/notification_bootstrap.dart` - notification init/action.
- `lib/services/notifications/notification_action_handler.dart` - complete/skip action.
- `test/architecture_preservation_property_test.dart` va `test/architecture_violation_exploration_test.dart` - kien truc/rui ro hien co.
