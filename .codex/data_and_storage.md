# Data And Storage

## Storage strategy

BioAI hien offline-first. Du lieu suc khoe/onboarding/meal plan duoc luu SQLite qua `sqflite`. Preferences nho dung `SharedPreferences`.

Database service:

- `lib/core/storage/localdb/database_service.dart`
- DB name: `bioai.db`
- Version: `DatabaseVersion.currentVersion = 3`
- `DatabaseService.database` lazy singleton.
- `onConfigure` va `onOpen`: `PRAGMA foreign_keys = OFF`.
- `onCreate`: tao tat ca bang.
- `onUpgrade`: goi `MigrationManager.runMigrations`.

Important: foreign key constraints dang bi tat, du schema co khai bao `FOREIGN KEY`.

## SQLite schema

Bang duoc tao trong `core/storage/localdb/tables`.

### `users`

Columns:

- `id TEXT PRIMARY KEY`
- `email TEXT UNIQUE`
- `phone TEXT UNIQUE`
- `full_name TEXT`
- `avatar_url TEXT`
- `gender TEXT`
- `birth_year INTEGER`
- `created_at TEXT`
- `updated_at TEXT`

### `health_profiles`

- `id TEXT PRIMARY KEY`
- `user_id TEXT`
- `occupation TEXT`
- `height_cm REAL`
- `weight_kg REAL`
- `bmi REAL`
- `blood_pressure TEXT`
- `blood_sugar TEXT`
- `created_at TEXT`
- `updated_at TEXT`

### `health_goals`

- `id TEXT PRIMARY KEY`
- `user_id TEXT`
- `goal_code TEXT`
- `goal_name TEXT`
- `is_active INTEGER DEFAULT 1`
- `created_at TEXT`

### `health_conditions`

- `id TEXT PRIMARY KEY`
- `user_id TEXT`
- `condition_code TEXT`
- `condition_name TEXT`
- `severity_level INTEGER`
- `created_at TEXT`

### `lifestyle_habits`

- `id TEXT PRIMARY KEY`
- `user_id TEXT`
- Boolean flags stored as int: `skip_breakfast`, `eat_late`, `eat_sweet`, `eat_oily`, `low_vegetable`, `low_water`, `fast_food`, `alcohol`, `coffee_high`.
- `sleep_quality TEXT`
- `activity_level TEXT`
- `water_per_day TEXT`
- `created_at TEXT`

### `food_allergies`

- `id TEXT PRIMARY KEY`
- `user_id TEXT`
- `allergy_name TEXT`
- `note TEXT`
- `created_at TEXT`

### `medical_treatments`

- `id TEXT PRIMARY KEY`
- `user_id TEXT`
- `treatment_name TEXT`
- `medication_name TEXT`
- `note TEXT`
- `created_at TEXT`

### `survey_answers`

- `id TEXT PRIMARY KEY`
- `user_id TEXT`
- `question_code TEXT`
- `answer_value TEXT`
- `created_at TEXT`

### `meal_plans`

- `id TEXT PRIMARY KEY`
- `user_id TEXT`
- `plan_date TEXT`
- `meal_type TEXT`
- `meal_name TEXT`
- `description TEXT`
- `calories INTEGER`
- `protein REAL`
- `carbs REAL`
- `fat REAL`
- `fiber REAL`
- `water_ml INTEGER`
- `meal_order INTEGER`
- `cooking_instructions TEXT`
- `is_completed INTEGER`
- `ai_generated INTEGER`
- `created_at TEXT`
- `updated_at TEXT`

### `daily_health_tasks`

- `id TEXT PRIMARY KEY`
- `user_id TEXT`
- `task_date TEXT NOT NULL`
- `task_code TEXT NOT NULL`
- `category TEXT NOT NULL`
- `title TEXT NOT NULL`
- `description TEXT`
- `target_value REAL`
- `current_value REAL DEFAULT 0`
- `unit TEXT`
- `is_completed INTEGER DEFAULT 0`
- `sort_order INTEGER DEFAULT 0`
- `source TEXT`
- `encouragement TEXT`
- `created_at TEXT`
- `updated_at TEXT`
- `UNIQUE(user_id, task_date, task_code)`

### Other tables

`health_tracking_logs`:

- weight, calories, water, sleep, stress, steps, mood per `created_at`.

`nutrition_logs`:

- food_name, calories, protein, carbs, fat, meal_type, eaten_at.

`ai_insights`:

- insight_type, title, content, risk_level.

`ai_recommendations`:

- recommendation_type, title, description, action_text, is_read.

`notifications`:

- title, body, type, is_read.

## Model/DAO status

Most localdb models are placeholders with only `id`, except meal plan and daily health tracking models.

Important working model:

`features/meal_plan/data/models/meal_plan_model.dart`

- Fields: id, userId, planDate, mealType, mealName, description, calories, protein, carbs, fat, fiber, waterMl, mealOrder, cookingInstructions, isCompleted, aiGenerated, createdAt, updatedAt.
- `fromMap` for DB rows.
- `fromJson` for AI JSON response.
- `toMap` stores boolean as 1/0 for SQLite.
- `toJson` stores boolean as bool.
- `copyWith`.

Important working DAO:

`features/meal_plan/data/daos/meal_plan_dao.dart`

- `insert`
- `insertMany` via batch and `ConflictAlgorithm.replace`
- `getAll` order by `plan_date ASC`
- `getByUserId`
- `getByDate` order by `meal_order ASC`
- `update`
- `updateCompleted`
- `delete`
- `deleteByUserId`

Daily health tracking:

- `features/daily_health_tracking/data/models/daily_health_task_model.dart` maps `daily_health_tasks`.
- `features/daily_health_tracking/data/daos/daily_health_tasks_dao.dart` supports `upsertMany`, `getByUserAndDate`, `updateTask`, `deleteByUserAndDate`.
- `features/daily_health_tracking/data/models/daily_health_ai_task_normalizer.dart` normalizes Gemini JSON to 7 days x 4 categories, with stable ids and `source = ai`.

Other DAO files mostly TODO and return empty list.

## Onboarding save mapping

`OnboardingLocalDatasource.saveOnboarding(entity)` is the main multi-table writer.

Transaction behavior:

1. Query existing user by `email = ? OR phone = ?`.
2. If exists, update user fields and use existing `userId`.
3. If not, generate text id from `DateTime.now().millisecondsSinceEpoch.toString()`, insert into `users`.
4. Delete old rows for same user in:
   - `health_profiles`
   - `health_goals`
   - `health_conditions`
   - `lifestyle_habits`
   - `food_allergies`
   - `medical_treatments`
   - `survey_answers`
5. Insert health profile.
6. Insert goal rows.
7. Insert condition rows.
8. Insert lifestyle row.
9. Optionally insert allergy row.
10. Optionally insert treatment row.
11. Insert survey rows.
12. Debug-print snapshot.

Important caveat: rows inserted into tables with `id TEXT PRIMARY KEY` often do not provide `id`. SQLite does not auto-generate TEXT primary keys. Because foreign keys are off, inserts may still fail if `id` is truly required by SQLite primary key semantics. Before relying on this flow in production, test full onboarding save on a real database.

Mappings:

- `_healthProfileRow`: occupation, height, weight, bmi, blood_pressure null, blood_sugar null.
- `_goalRows`: selected goals plus `other_goal`; maps code to Vietnamese label.
- `_conditionRows`: selected conditions plus `other_condition`; maps code to Vietnamese label.
- `_lifestyleRow`: converts selected habits to int flags and stores sleep/activity/water labels.
- `_allergyRow`: allergy_name and optional note.
- `_treatmentRow`: treatment_name, medication_name, note.
- `_surveyRows`: full_name, email, phone, gender, birth_year. `concernText` currently is not included in survey rows, while dashboard tries to read `surveyAnswers['concern_text']`.

## Dashboard read mapping

`DashboardLocalDatasource.fetchDashboard()`:

1. Query latest user by `created_at DESC limit 1`.
2. Read one `health_profiles` by user_id.
3. Read all `health_goals`.
4. Read all `health_conditions`.
5. Read one `lifestyle_habits`.
6. Read one `food_allergies`.
7. Read one `medical_treatments`.
8. Read all `survey_answers`.
9. Build `DashboardEntity`.

Helpers:

- `_readString`
- `_readInt`
- `_readDouble`
- `_readBool`
- `_readHabitsFromRow`

Potential issue:

- `DashboardEntity.userId` is `int`, but `users.id` is TEXT timestamp; `_readInt` parses string if possible. If user id becomes UUID/text non-numeric later, `userId` becomes 0.
- `concernText` is read from survey key `concern_text`, but onboarding datasource does not save that key.

## Meal plan persistence flow

After onboarding save:

```txt
OnboardingController.saveOnboarding()
  -> onboardingCompletionCallbackProvider()
  -> DashboardController.genMealByWeeksToDB(requireComplete: true)
  -> DashboardRepository.fetchDashboard()
  -> AIService.generateMealPlan(healthData)
  -> DashboardRepository.saveMealPlan(mealPlans)
  -> DashboardLocalDatasource.saveMealPlan()
  -> MealPlansDao.insertMany()
  -> meal_plans
  -> DailyHealthTrackingLocalDatasource.fetchLatestProfile()
  -> AIService.generateDailyHealthTasks(profile, startDate tomorrow, days 7)
  -> DailyHealthTrackingLocalDatasource.seedGeneratedTasks(requireComplete: true)
  -> DailyHealthTasksDao.upsertMany()
  -> daily_health_tasks
```

Meal plan page reads:

```txt
MealPlanController.build()
  -> MealPlanRepositoryImpl.getMealByWeeks()
  -> MealPlanDatasource.getMealByWeeks()
  -> MealPlansDao.getAll()
```

## SharedPreferences

`core/storage/localdb/app_prefs.dart`:

- `_onboardingKey = 'onboarding_completed'`.
- `setOnboardingCompleted(bool)`.
- `isOnboardingCompleted()` default false.

`SettingsPreferencesModel` keys:

- `theme_mode`
- `language_code`
- `biometric_enabled`
- `push_enabled`
- `meal_reminder_enabled`
- `meal_reminder_time`
- `goal_reminder_enabled`
- `ai_chat_notification_enabled`
- `ai_personality`
- `data_privacy_mode`

Defaults:

- light mode
- language `vi`
- biometric/push/reminders off
- AI personality `friendly`
- privacy mode `local`

## Cache and local files

`SettingsLocalDatasource.calculateCacheSize()`:

- Uses `getTemporaryDirectory()`.
- Recursively sums file sizes.
- Returns 0 on error.

`SettingsLocalDatasource.clearCache()`:

- Deletes direct children of temp dir, directories recursively.

`ImagePickerService.saveImageLocally()`:

- Uses `getApplicationDocumentsDirectory()`.
- Saves into `avatars/`.

## Migration status

- `database_version.dart`: current version 3.
- v2 creates `daily_health_tasks`, adds `log_date` and `updated_at` to `health_tracking_logs`, and creates unique user/date index.
- v3 adds `meal_plans.cooking_instructions TEXT`.
- `migration_v1.dart`: empty.

If changing schema, add real migration and bump `DatabaseVersion.currentVersion`.
