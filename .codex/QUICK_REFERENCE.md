# QUICK REFERENCE — NanoBio / BioAI

Cheat sheet nhanh cho developers. Đọc khi cần tra cứu nhanh.

## 🚀 Quick Start

```bash
# Setup project
flutter pub get
cp .env.example .env
# Edit .env: Add SUPABASE_URL, SUPABASE_ANON_KEY, GEMINI_API_KEY

# Run app
flutter run

# Run tests
flutter test

# Format + analyze
dart format .
flutter analyze
```

---

## 📁 Project Structure

```
lib/
├── core/                    # Shared infrastructure
│   ├── constants/           # App-wide constants
│   ├── interfaces/          # Abstractions (HealthDataInterface)
│   ├── router/              # GoRouter config
│   ├── storage/localdb/     # SQLite (19 tables)
│   ├── theme/               # Design system 3-layer
│   └── utils/               # Helpers
├── features/                # Feature modules (feature-first)
│   ├── auth/                # Authentication (Supabase)
│   ├── onboarding/          # 7-step health wizard
│   ├── dashboard/           # Home screen + BMI
│   ├── meal_plan/           # AI meal planning
│   ├── daily_health_tracking/  # Health logs
│   ├── lifestyle_schedule/  # Schedule + reminders
│   └── [feature]/
│       ├── data/            # Models, Datasources
│       ├── domain/          # Entities, Repositories
│       ├── presentation/    # Pages, Widgets, Controllers
│       └── providers/       # Riverpod providers
├── services/                # External services
│   ├── ai/                  # Gemini AI
│   ├── notifications/       # Local notifications
│   └── supabase/            # Auth service
└── shared/                  # Shared widgets
```

---

## 🏗️ Architecture Cheat Sheet

### Layer Dependencies

```
Presentation → Domain → Data → Infrastructure
    (UI)      (Logic)   (Storage)  (SQLite/API)
```

### What Each Layer Can Do

| Layer | Can Import | Cannot Import | Contains |
|-------|------------|---------------|----------|
| **Presentation** | Domain, Riverpod | Data | Pages, Widgets, Controllers |
| **Domain** | Nothing | Presentation, Data | Entities, Repository interfaces |
| **Data** | Domain | Presentation | Models, Datasources, Repository impl |

### Feature Structure (FLAT)

```
features/dashboard/
├── data/
│   ├── models/dashboard_model.dart
│   ├── datasources/dashboard_local_datasource.dart
│   └── repositories/ (optional)
├── domain/
│   ├── entities/dashboard_entity.dart
│   └── repositories/
│       ├── dashboard_repository.dart (interface)
│       └── dashboard_repository_impl.dart
├── presentation/
│   ├── pages/dashboard_page.dart
│   ├── widgets/
│   └── controllers/dashboard_controller.dart
└── providers/dashboard_provider.dart
```

---

## 🔍 Common Commands

### Search Patterns

```bash
# Find class/provider usage
rg "ClassName|providerName" lib test

# Find mock/fake data
rg "mock|fake|sample|dummy|TODO" lib/features/

# Find AI-related code
rg "Gemini|generate|validator|normalizer" lib/services/ai

# Find notification code
rg "notification|payload|timezone|reminder" lib/services/

# Find database queries
rg "SELECT|INSERT|UPDATE|DELETE" lib/core/storage/
```

### Quick Checks

```bash
# Quick check (always run)
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test

# Full check (when changing native code)
flutter doctor -v
flutter pub get
dart format .
flutter analyze
flutter test
flutter build apk --debug
```

---

## 💾 Database Quick Reference

### Current Version: **8**

**19 Tables**:
- `users`, `health_profiles`, `health_goals`, `health_conditions`
- `lifestyle_habits`, `food_allergies`, `medical_treatments`
- `health_tracking_logs`, `daily_health_tasks`
- `lifestyle_schedule_items`, `meal_plans`
- `meal_catalog`, `exercise_catalog`, `schedule_task_catalog`
- `nutrition_logs`, `ai_insights`, `ai_recommendations`
- `notifications`, `survey_answers`

### Change Schema Checklist

When changing database schema:

1. [ ] `database_version.dart` → Tăng `currentVersion`
2. [ ] `tables/*.dart` → Update CREATE TABLE
3. [ ] `models/*.dart` → Update model class
4. [ ] `daos/*.dart` → Update DAO queries
5. [ ] `migrations/migration_vX.dart` → Tạo migration mới
6. [ ] `database_service.dart` → Update `_createTables()` if needed

### Common DAO Patterns

```dart
// Insert
await db.insert('table_name', model.toMap());

// Query all
final results = await db.query('table_name');

// Query with where
final results = await db.query(
  'table_name',
  where: 'user_id = ?',
  whereArgs: [userId],
);

// Update
await db.update(
  'table_name',
  {'status': 'completed'},
  where: 'id = ?',
  whereArgs: [itemId],
);

// Delete
await db.delete('table_name', where: 'id = ?', whereArgs: [id]);
```

---

## 🎨 Design System Quick Reference

### 3-Layer Architecture

```
Foundation Tokens (primitive)
    ↓
Semantic Tokens (context-aware)
    ↓
Primitive Components (reusable)
```

### Common Tokens

```dart
// Colors
AppColorTokens.primary
AppColorTokens.surface
AppColorTokens.onSurface
AppColorTokens.error

// Spacing
AppSpacingTokens.pagePadding    // 16.0
AppSpacingTokens.sectionGap     // 24.0
AppSpacingTokens.cardPadding    // 12.0

// Radius
AppRadiusTokens.small           // 4.0
AppRadiusTokens.medium          // 8.0
AppRadiusTokens.large           // 16.0

// Text Styles
AppTextStyles.headingLarge
AppTextStyles.headingMedium
AppTextStyles.bodyLarge
AppTextStyles.bodyMedium
```

### Primitive Components

```dart
// Button
AppButton(
  variant: ButtonVariant.primary, // primary, secondary, outline, text, danger
  onPressed: () {},
  child: Text('Button'),
)

// Card
AppCard(
  variant: CardVariant.elevated, // elevated, outlined, filled
  child: /* content */,
)

// Chip
AppChip(
  variant: ChipVariant.filled, // filled, outlined, input
  label: 'Chip',
  onTap: () {},
)

// Badge
AppBadge(
  status: BadgeStatus.success, // success, warning, error, info, neutral
  label: 'Badge',
)
```

---

## 🔔 Notification Quick Reference

### Notification Payload

```dart
class NotificationPayload {
  final String type; // 'schedule_reminder', 'health_alert', etc.
  final String? scheduleItemId;
  final Map<String, dynamic>? data;
  
  // Serialize/deserialize
  String toJson();
  static NotificationPayload fromJson(String json);
}
```

### Schedule Notification

```dart
await flutterLocalNotificationsPlugin.zonedSchedule(
  notificationId,
  title,
  body,
  scheduledDate,
  notificationDetails,
  androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  uiLocalNotificationDateInterpretation: 
    UILocalNotificationDateInterpretation.absoluteTime,
  payload: payload.toJson(),
);
```

### Action Buttons

```dart
AndroidNotificationDetails(
  actions: [
    AndroidNotificationAction('complete', 'Đã làm'),
    AndroidNotificationAction('skip', 'Bỏ qua'),
  ],
)
```

---

## 🤖 AI Service Quick Reference

### Generate Meal Plan

```dart
final aiService = ref.read(aiServiceProvider);
final meals = await aiService.generateMealPlan(
  healthData: profile, // Implements HealthDataInterface
  userId: userId,
  startDate: DateTime.now(),
  days: 7,
);
```

### Generate Exercise Tasks

```dart
final exercises = await aiService.generateExerciseTasks(
  profile: profile,
  startDate: DateTime.now(),
  days: 7,
);
```

### AI Service Features

- **Retry logic**: 2 attempts per model, 4 total attempts
- **Fallback**: Local catalog if AI fails
- **Normalization**: Validates and maps AI output to Vietnamese text
- **Chunking**: Splits 7 days into 2+2+3 chunks

---

## 🚦 Navigation Quick Reference

### Route Paths

```dart
RoutePaths.splash          // '/splash'
RoutePaths.login           // '/login'
RoutePaths.onboarding      // '/onboarding'
RoutePaths.menu            // '/menu'
RoutePaths.dashboard       // '/dashboard'
RoutePaths.mealPlan        // '/meal-plan'
RoutePaths.healthTracking  // '/health-tracking'
RoutePaths.lifestyleSchedule // '/lifestyle-schedule'
RoutePaths.aiChat          // '/ai-chat'
```

### Navigate

```dart
// Go to route
context.go('/dashboard');

// Go with params
context.go('/meal-plan', extra: {'date': '2024-06-18'});

// Push route
context.push('/ai-chat');

// Pop
context.pop();
```

### Route Guards

```dart
// Auth guard - require login
redirect: RouteGuards.authGuard

// Guest guard - redirect if already logged in
redirect: RouteGuards.guestGuard
```

---

## 📝 Naming Convention Cheat Sheet

| Item | Pattern | Example |
|------|---------|---------|
| File - Page | `*_page.dart` | `dashboard_page.dart` |
| File - Controller | `*_controller.dart` | `dashboard_controller.dart` |
| File - Provider | `*_provider.dart` | `dashboard_provider.dart` |
| File - Model | `*_model.dart` | `dashboard_model.dart` |
| File - Entity | `*_entity.dart` | `dashboard_entity.dart` |
| File - Repository | `*_repository.dart` | `dashboard_repository.dart` |
| File - Local Datasource | `*_local_datasource.dart` | `dashboard_local_datasource.dart` |
| File - Remote Datasource | `*_remote_datasource.dart` | `auth_remote_datasource.dart` |
| Class - Page | `*Page` | `DashboardPage` |
| Class - Controller | `*Controller` | `DashboardController` |
| Class - Model | `*Model` | `DashboardModel` |
| Class - Entity | `*Entity` | `DashboardEntity` |
| Class - Local Datasource | `*LocalDatasource` | `DashboardLocalDatasource` |
| Class - Remote Datasource | `*RemoteDatasource` | `AuthRemoteDatasource` |
| Provider | `*Provider` | `dashboardProvider` |
| Controller Provider | `*ControllerProvider` | `dashboardControllerProvider` |

---

## ✅ Do's and ❌ Don'ts

### ✅ DO:

- Follow feature-first structure
- Use proper layer separation (Presentation → Domain → Data)
- Name datasources with `Local`/`Remote` prefix
- Convert Models ↔ Entities at repository layer
- Use Vietnamese diacritics for user-facing text
- Write tests for critical flows
- Update database version when schema changes
- Use `rg` to search before opening files
- Run `flutter analyze` before committing

### ❌ DON'T:

- Don't bypass layers (presentation → data directly)
- Don't import features from other features
- Don't use mock/fake data in production code
- Don't call real APIs in unit tests
- Don't hardcode API keys in code
- Don't nest feature folders (`features/meal_plan/dashboard/`)
- Don't use `dynamic`, `!`, `as` without good reason
- Don't commit `.env` files
- Don't create code and then comment it out (delete instead)

---

## 🐛 Common Issues & Solutions

### Issue: "Architecture violation detected"

**Symptoms**: Import from wrong layer  
**Solution**: Check `.codex/ARCHITECTURE.md` for correct dependencies

### Issue: "Text không có dấu"

**Symptoms**: Vietnamese text displays without diacritics  
**Solution**: Use proper Vietnamese: "Sức khỏe" not "Suc khoe"

### Issue: "Database version mismatch"

**Symptoms**: App crashes after schema change  
**Solution**: Increase `database_version.dart` and create migration

### Issue: "Notification không đổ chuông"

**Symptoms**: Scheduled notifications don't fire  
**Solution**: Check timezone initialization in `main.dart`

### Issue: "Test fails: API called"

**Symptoms**: Unit test makes real network request  
**Solution**: Mock datasource in test, don't use real service

### Issue: "Dashboard shows 0 data"

**Symptoms**: Dashboard empty after onboarding  
**Solution**: Check onboarding callback executed successfully

---

## 📚 Key Files to Know

| File | Purpose |
|------|---------|
| `lib/main.dart` | App entry point, onboarding callback |
| `lib/core/router/app_router.dart` | Route configuration |
| `lib/core/storage/localdb/database_service.dart` | Database initialization |
| `lib/core/storage/localdb/database_version.dart` | Current DB version |
| `lib/services/ai/ai_service.dart` | Gemini AI integration |
| `lib/services/notifications/notification_bootstrap.dart` | Notification init |
| `.codex/AGENTS.md` | Main rules and workflow |
| `.codex/PROJECT_MAP.md` | Task routing guide |
| `.codex/ARCHITECTURE.md` | Architecture decisions |
| `docs/issues/bug_architecture.md` | Known violations |

---

## 🔗 Useful Links

- **Flutter Docs**: https://docs.flutter.dev/
- **Riverpod Docs**: https://riverpod.dev/
- **GoRouter Docs**: https://pub.dev/packages/go_router
- **Gemini AI Docs**: https://ai.google.dev/docs
- **Supabase Docs**: https://supabase.com/docs

---

**Last Updated**: 2026-06-18  
**Version**: 1.0
