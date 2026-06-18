# PROJECT_MAP — NanoBio / BioAI

File này giúp Codex chọn đúng tài liệu và đúng vùng source code. **Chỉ đọc file cần thiết cho task.**

## Global entry points

- **App bootstrap**: `lib/main.dart` (init Supabase, notifications, onboarding callback)
- **App shell/router**: `lib/app/app.dart`, `lib/core/router/app_router.dart`
- **Theme/design system**: `lib/core/theme/` (3-layer token architecture)
- **Local DB**: `lib/core/storage/localdb/` (SQLite v8, 19 tables)
- **AI service**: `lib/services/ai/` (Gemini integration, retry, fallback)
- **Notification service**: `lib/services/notifications/` (local reminders, actions)
- **Supabase service**: `lib/services/supabase/` (auth only)

## Task routing

### 🔐 Authentication / Login

Read:

- `.codex/playbooks/ui.md` (if UI changes)
- `lib/features/auth/`
- `lib/services/supabase/`
- `lib/core/router/route_guards.dart`

Focus: Supabase auth integration, session management, route guards.

---

### 📝 Onboarding (7-step wizard)

Read:

- `.codex/playbooks/onboarding.md`
- `lib/features/onboarding/`
- DAOs liên quan: `users_dao`, `health_profiles_dao`, `health_goals_dao`, `lifestyle_habits_dao`, `health_conditions_dao`, `food_allergies_dao`, `medical_treatments_dao`

Focus: 
- Sau onboarding phải lưu đủ hồ sơ vào 8 tables
- Kích hoạt callback trong `main.dart` để generate schedule
- Validation rules cho từng step

---

### 🏠 Dashboard / Health Score / Trang chủ

Read:

- `.codex/playbooks/dashboard.md` ⭐ **CRITICAL**
- `lib/features/dashboard/`
- `lib/features/daily_health_tracking/`
- `lib/features/lifestyle_schedule/`
- `lib/core/storage/localdb/daos/health_tracking_logs_dao.dart`
- `lib/core/storage/localdb/tables/daily_health_tasks_table.dart`
- `lib/core/storage/localdb/tables/lifestyle_schedule_items_table.dart`

Focus: 
- Dashboard phải tính từ SQLite/data layer thật
- **KHÔNG mock/fake production data**
- BMI calculation từ DB
- Health score từ tracking logs
- Timeline từ schedule items

**Critical Rules**:
```dart
// ✅ CORRECT
final data = await repository.fetchDashboard(); // Query DB
final bmi = data.bmi; // Calculate from DB

// ❌ WRONG - NEVER DO THIS!
final mockBmi = 22.5; 
final mockData = DashboardEntity(...); // Fake data
```

---

### 🍽️ Meal Plan / Exercise / AI Parser

Read:

- `.codex/playbooks/ai_service.md` ⭐ **CRITICAL**
- `lib/services/ai/`
- `lib/features/meal_plan/`
- Normalizer/catalog/seed: 
  - `lib/features/meal_plan/data/models/meal_plan_ai_normalizer.dart`
  - `lib/features/lifestyle_schedule/data/models/exercise_tasks_ai_normalizer.dart`
  - `lib/core/storage/localdb/seeders/ai_catalog_seeder.dart`

Focus: 
- AI output không crash app
- Text hiển thị tiếng Việt có dấu
- Test không gọi API thật (mock AI service)
- Fallback khi AI fail
- Validator/normalizer validate schema

---

### 📊 Daily Health Tracking

Read:

- `.codex/playbooks/health_tracking.md`
- `lib/features/daily_health_tracking/`
- `lib/core/storage/localdb/daos/health_tracking_logs_dao.dart`
- `lib/core/storage/localdb/tables/health_tracking_logs_table.dart`

Focus:
- Tracking logs (weight, sleep, water, steps, stress)
- Validate input ranges
- Timestamp timezone-aware
- No duplicate entries (same metric + date)
- Integration với Dashboard

---

### 📅 Lifestyle Schedule / Timeline

Read:

- `.codex/playbooks/lifestyle_schedule.md`
- `lib/features/lifestyle_schedule/`
- `lib/features/lifestyle_schedule/data/models/lifestyle_schedule_timeline_builder.dart`
- `lib/core/storage/localdb/tables/lifestyle_schedule_items_table.dart`

Focus:
- Schedule generation (meals + exercises + hydration + sleep)
- Timeline builder logic
- Status flow: pending → completed/skipped
- Integration với notifications
- Refresh schedule after 7 days

---

### 🔔 Notification / Reminder / Action Button

Read:

- `.codex/playbooks/notification.md` ⭐ **CRITICAL**
- `lib/services/notifications/`
- `lib/features/daily_health_tracking/`
- `notifications_dao` nếu có

Focus: 
- Timezone init trước khi schedule
- Notification id ổn định
- Payload serialize/parse an toàn
- Background action không phụ thuộc BuildContext
- Test không gọi plugin thật
- Action button (complete/skip) update DB

---

### 💾 SQLite / DAO / Migration

Read:

- `.codex/playbooks/sqlite.md` ⭐ **CRITICAL**
- `lib/core/storage/localdb/database_service.dart`
- `lib/core/storage/localdb/database_version.dart`
- `lib/core/storage/localdb/migrations/`
- `lib/core/storage/localdb/tables/`
- `lib/core/storage/localdb/models/`
- `lib/core/storage/localdb/daos/`

Focus: 
- Đổi schema phải đi đủ table/model/DAO/migration/onCreate
- Tăng database version
- Migration không mất dữ liệu cũ
- Test CRUD operations

---

### 🎨 UI / Theme / Copywriting / Design System

Read:

- `.codex/playbooks/ui.md`
- `lib/core/theme/`
- Widgets/pages của feature liên quan
- `lib/core/theme/IMPLEMENTATION_STATUS.md`

Focus: 
- Dùng theme token (không hardcode)
- Responsive layout
- Không overflow
- Text tiếng Việt có dấu
- 3-layer token architecture (Foundation → Semantic → Component)

---

## Search commands ưu tiên

### Find class/provider usage
```bash
rg "ClassName|providerName|routeName|tableName" lib test
```

### Find mock/fake data (to remove)
```bash
rg "mock|fake|sample|dummy|TODO" lib/features/dashboard lib/features/onboarding
```

### Find AI-related code
```bash
rg "Gemini|generate|validator|normalizer" lib/services/ai lib/features
```

### Find notification code
```bash
rg "notification|payload|timezone|reminder" lib/services/notifications lib/features
```

### Find database queries
```bash
rg "SELECT|INSERT|UPDATE|DELETE" lib/core/storage/localdb/daos/
```

### Find architecture violations
```bash
# Cross-feature imports (BAD!)
rg "import.*features/dashboard" lib/features/onboarding
rg "import.*features/meal_plan" lib/features/dashboard

# Presentation importing Data (BAD!)
rg "import.*data/datasources" lib/features/*/presentation/

# Using core models in presentation (BAD!)
rg "import.*core/storage/localdb/models" lib/features/*/presentation/
```

---

## Module dependency map

```
┌──────────────┐
│     UI       │ (Presentation)
└──────┬───────┘
       │ calls
       ↓
┌──────────────┐
│  Controller  │ (Riverpod Notifier)
└──────┬───────┘
       │ calls
       ↓
┌──────────────┐
│  Repository  │ (Interface + Impl)
└──────┬───────┘
       │ calls
       ↓
┌──────────────┐
│  Datasource  │ (*LocalDatasource / *RemoteDatasource)
└──────┬───────┘
       │ calls
       ↓
┌──────────────┐
│   DAO/API    │ (SQLite / HTTP)
└──────────────┘
```

**Never bypass layers!** UI → Controller → Repository → Datasource → DAO

---

## Feature status map

| Feature | Status | Main Files | Tests | Notes |
|---------|--------|------------|-------|-------|
| Auth | ✅ Done | `features/auth/` | ⚠️ Partial | Supabase integration |
| Onboarding | ✅ Done | `features/onboarding/` | ⚠️ Partial | 7-step wizard |
| Dashboard | 🚧 In Progress | `features/dashboard/` | ⚠️ Partial | Has mock data (needs fix) |
| Meal Plan | ✅ Done | `features/meal_plan/` | ⚠️ Partial | AI generation + fallback |
| Health Tracking | ✅ Done | `features/daily_health_tracking/` | ⚠️ Partial | Tracking logs |
| Lifestyle Schedule | ✅ Done | `features/lifestyle_schedule/` | ⚠️ Partial | Timeline + notifications |
| AI Chat | 🚧 Planned | `features/ai_chat/` | ❌ None | Future feature |
| Sleep Tracking | 🚧 Planned | `features/sleep_tracking/` | ❌ None | Future feature |
| Stress Tracking | 🚧 Planned | `features/stress_tracking/` | ❌ None | Future feature |

Legend:
- ✅ Done - Feature implemented and working
- 🚧 In Progress - Partially implemented
- 🚧 Planned - Not started yet
- ⚠️ Partial - Some tests exist, not comprehensive
- ❌ None - No tests yet

---

## Critical files (always check before major changes)

1. `lib/main.dart` - App entry, onboarding callback ⭐
2. `lib/core/router/app_router.dart` - Route config
3. `lib/core/storage/localdb/database_service.dart` - DB init
4. `lib/core/storage/localdb/database_version.dart` - DB version ⭐
5. `lib/services/ai/ai_service.dart` - AI integration
6. `lib/services/notifications/notification_bootstrap.dart` - Notification init
7. `.codex/AGENTS.md` - Main rules
8. `.codex/ARCHITECTURE.md` - Architecture decisions
9. `docs/issues/bug_architecture.md` - Known violations ⭐

⭐ = Must read if making related changes

---

**Last Updated**: 2026-06-18  
**Version**: 1.0
