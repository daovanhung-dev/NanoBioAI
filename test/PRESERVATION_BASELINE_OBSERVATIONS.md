# Preservation Property Tests - Baseline Observations

**Date**: Generated from UNFIXED code analysis
**Status**: ✅ All 15 preservation property tests PASSED on unfixed code
**Purpose**: Document baseline functional behavior that MUST remain unchanged after architecture fixes

## Test Execution Summary

```
Running: flutter test test/architecture_preservation_property_test.dart
Result: 00:03 +15: All tests passed!
```

## Observed Behaviors (Must Be Preserved)

### 1. Onboarding → Meal Generation Flow (Property 3.1)

**Observation**:
- `onboarding_controller.dart` line 302 directly calls `ref.read(dashboardControllerProvider.notifier).genMealByWeeksToDB()`
- `saveOnboarding()` method triggers meal generation as part of onboarding completion
- `AppPrefs.setOnboardingCompleted(true)` is called to mark completion

**Invariant After Fix**:
- Meal generation MUST still be triggered when onboarding completes
- Mechanism may change (callback pattern instead of direct call), but behavior must remain
- Onboarding completed flag must still be set

**Test Coverage**:
- ✅ `saveOnboarding()` method exists and triggers meal generation
- ✅ 7-step wizard structure (steps 0-6) preserved
- ✅ State transitions work correctly

---

### 2. AI Service Gemini Integration (Property 3.2)

**Observation**:
- `ai_service.dart` delegates Gemini calls to `GeminiRestClient`
- API key is loaded through `AppEnv` and sent only in the `x-goog-api-key` header
- `generateMealPlan()` returns `Future<List<MealPlanModel>>`
- JSON response parsing with retry logic (3 attempts)
- Response cleaning: removes markdown, fixes trailing commas

**Invariant After Fix**:
- Gemini API integration behavior MUST remain available
- JSON parsing and cleaning logic MUST be preserved
- Retry mechanism MUST work the same way
- Return type `List<MealPlanModel>` MUST be unchanged

**Test Coverage**:
- ✅ `GeminiRestClient` usage confirmed
- ✅ API key from environment confirmed
- ✅ `generateContent` API call confirmed
- ✅ JSON parsing with `jsonDecode` confirmed
- ✅ `MealPlanModel.fromJson` deserialization confirmed
- ✅ Retry logic confirmed

---

### 3. Meal Plan Database Storage (Property 3.3)

**Observation**:
- `dashboard_local_datasource.dart` has `saveMealPlan(List<MealPlanModel>)` method
- Uses `DatabaseService.database` to get SQLite connection
- Uses `MealPlansDao.insertMany()` for batch inserts
- Saves to `meal_plans` table (via DAO)

**Invariant After Fix**:
- SQLite storage mechanism MUST remain unchanged
- Batch insert via `MealPlansDao` MUST be preserved
- Database schema MUST remain compatible

**Test Coverage**:
- ✅ `saveMealPlan` method exists
- ✅ `DatabaseService` usage confirmed
- ✅ `MealPlansDao` usage confirmed
- ✅ `insertMany` batch operation confirmed

---

### 4. Health Data Multi-Table Storage (Property 3.4)

**Observation**:
- `onboarding_remote_datasource.dart` (or `onboarding_local_datasource.dart` after rename) saves to 7 tables:
  1. `users` - user basic info
  2. `health_profiles` - height, weight, BMI, occupation
  3. `health_goals` - list of user goals
  4. `health_conditions` - list of health conditions
  5. `lifestyle_habits` - habits as boolean flags
  6. `food_allergies` - allergy name and notes
  7. `medical_treatments` - treatment and medication info
  8. `survey_answers` - additional survey data

**Invariant After Fix**:
- All 7 (8 including survey) tables MUST receive data
- Insert operations MUST maintain same data structure
- Field mappings MUST remain identical

**Test Coverage**:
- ✅ All 7 table names referenced in datasource
- ✅ `survey_answers` table handling confirmed

---

### 5. Dashboard Health Data Retrieval (Property 3.5)

**Observation**:
- `dashboard_local_datasource.dart` `fetchDashboard()` reads from all 7 tables
- Query order: users → health_profiles → health_goals → health_conditions → lifestyle_habits → food_allergies → medical_treatments → survey_answers
- Constructs `DashboardEntity` with data from all tables
- Uses helper methods: `_readString`, `_readInt`, `_readDouble`, `_readBool`, `_readHabitsFromRow`

**Invariant After Fix**:
- All 7 table queries MUST be preserved
- `DashboardEntity` construction logic MUST remain unchanged
- Helper methods MUST work identically

**Test Coverage**:
- ✅ `fetchDashboard` method exists
- ✅ All 7 table queries confirmed
- ✅ `DashboardEntity` construction confirmed

---

### 6. JSON Serialization/Deserialization (Property 3.6)

**Observation**:
- `MealPlanModel` has 4 conversion methods:
  - `fromJson(Map<String, dynamic>)` - for AI response parsing
  - `toJson()` - for API requests
  - `fromMap(Map<String, dynamic>)` - for database reads
  - `toMap()` - for database writes
- Boolean conversion: `isCompleted` and `aiGenerated` convert to 1/0 for database
- Type conversions: `(json['protein'] as num).toDouble()`

**Invariant After Fix**:
- All 4 methods MUST be preserved
- Boolean ↔ int conversion MUST remain identical
- Type conversions MUST work the same way
- Field names and structure MUST be unchanged

**Test Coverage**:
- ✅ `fromJson` factory method confirmed
- ✅ `fromMap` factory method confirmed
- ✅ `toJson` method confirmed
- ✅ `toMap` method confirmed
- ✅ Boolean conversion logic confirmed

---

### 7. UI Navigation Flow (Property 3.7)

**Observation**:
- `saveOnboarding()` sets `AppPrefs.setOnboardingCompleted(true)`
- Success state: `savedLog: 'Mình đã lưu hồ sơ sức khỏe của bạn thành công.'`
- Error state: `savedLog: 'Mình chưa thể lưu hồ sơ lúc này: $e'`
- `isSaving` flag prevents duplicate saves

**Invariant After Fix**:
- Onboarding completed flag MUST still be set
- UI feedback mechanism MUST be preserved
- Success/error messages MAY change but feedback pattern must remain

**Test Coverage**:
- ✅ `AppPrefs.setOnboardingCompleted(true)` call confirmed
- ✅ `savedLog` state mechanism confirmed

---

### 8. Dashboard Meal Generation Orchestration (Property 3.8)

**Observation**:
- `dashboard_controller.dart` `genMealByWeeksToDB()` orchestrates 3 steps:
  1. `repository.fetchDashboard()` - fetch health data
  2. `aiService.generateMealPlan(healthData: dashboardData)` - AI generation
  3. `repository.saveMealPlan(mealPlan)` - save to database

**Invariant After Fix**:
- 3-step orchestration MUST be preserved
- Method signature MAY change but behavior must remain
- Error handling pattern MUST work the same way

**Test Coverage**:
- ✅ `genMealByWeeksToDB` method exists
- ✅ `fetchDashboard` call confirmed
- ✅ `generateMealPlan` call confirmed
- ✅ `saveMealPlan` call confirmed

---

### 9. Riverpod Provider API Surface (Property 3.9)

**Observation**:
- `onboardingProvider` - `NotifierProvider<OnboardingController, OnboardingState>`
- `dashboardControllerProvider` - `AsyncNotifierProvider<DashboardController, void>`
- Providers expose controller methods via `.notifier`
- Consumer code uses `ref.read()` and `ref.watch()`

**Invariant After Fix**:
- Provider names MUST remain unchanged
- Provider types MUST remain compatible
- `.notifier` access pattern MUST work identically

**Test Coverage**:
- ✅ `onboardingProvider` existence confirmed
- ✅ `dashboardControllerProvider` existence confirmed
- ✅ Provider types confirmed

---

### 10. State Management Patterns (Property 3.10)

**Observation**:
- `OnboardingController extends Notifier<OnboardingState>` - synchronous state
- `DashboardController extends AsyncNotifier<void>` - async operations
- State updates via `state = state.copyWith(...)` (immutable pattern)
- Multiple update methods: `updateFullName()`, `updateGender()`, `toggleGoal()`, etc.

**Invariant After Fix**:
- Notifier/AsyncNotifier patterns MUST be preserved
- Immutable state update pattern MUST remain
- All public controller methods MUST remain accessible

**Test Coverage**:
- ✅ `Notifier` pattern for OnboardingController confirmed
- ✅ `AsyncNotifier` pattern for DashboardController confirmed
- ✅ `state.copyWith` immutable pattern confirmed
- ✅ Key controller methods confirmed

---

## Critical Integration Points

### End-to-End Flow

```
User completes onboarding (step 6)
  ↓
OnboardingController.saveOnboarding()
  ↓
OnboardingRepository.save() → 7 SQLite tables
  ↓
DashboardController.genMealByWeeksToDB() [CURRENTLY DIRECT CALL, WILL BECOME CALLBACK]
  ↓
DashboardRepository.fetchDashboard() → Read from 7 tables → DashboardEntity
  ↓
AIService.generateMealPlan(healthData: DashboardEntity) [WILL CHANGE TO HealthDataInterface]
  ↓
Gemini API call → JSON parsing → List<MealPlanModel>
  ↓
DashboardRepository.saveMealPlan() → Insert via MealPlansDao
  ↓
AppPrefs.setOnboardingCompleted(true)
  ↓
Navigate to dashboard → Display 7-day meal plan
```

**Invariant**: The complete flow MUST produce the same end result (meal plan in database) even though internal wiring changes.

---

## Post-Fix Validation Strategy

After applying architecture fixes, re-run the same preservation property tests:

```bash
flutter test test/architecture_preservation_property_test.dart
```

**Expected Result**: All 15 tests should still PASS, confirming:
- ✅ Meal generation still triggers on onboarding completion (via callback)
- ✅ AI service still uses Gemini API identically
- ✅ Database storage still works the same way
- ✅ All 7 tables still receive data correctly
- ✅ DashboardEntity construction still works
- ✅ JSON serialization still works identically
- ✅ UI navigation flow still works
- ✅ Orchestration flow still works
- ✅ Provider APIs still work
- ✅ State management patterns still work

---

## Architecture Changes That Will NOT Break Preservation

1. **Event-Based Communication** (Fix 1):
   - ✅ Change: Direct `dashboardControllerProvider` call → callback pattern
   - ✅ Preserved: Meal generation still triggers automatically

2. **Dependency Inversion** (Fix 2):
   - ✅ Change: `DashboardEntity` parameter → `HealthDataInterface` parameter
   - ✅ Preserved: Same data flows to AI service, same meal plans generated

3. **Datasource Rename** (Fix 3):
   - ✅ Change: `onboarding_remote_datasource.dart` → `onboarding_local_datasource.dart`
   - ✅ Preserved: Same SQLite operations, same data saved

4. **Folder Flattening** (Fix 4):
   - ✅ Change: `features/meal_plan/dashboard/...` → `features/meal_plan/...`
   - ✅ Preserved: Same files, same logic, just different paths

5. **Model Migration** (Fix 5):
   - ✅ Change: `core/storage/localdb/models/meal_plan_model.dart` → `features/meal_plan/data/models/meal_plan_model.dart`
   - ✅ Preserved: Same model structure, same serialization methods

---

## Conclusion

✅ **15/15 preservation property tests passed on UNFIXED code**
✅ **All functional behaviors documented and encoded as test properties**
✅ **Baseline established for post-fix validation**
✅ **Ready for architecture fixes with confidence that functionality will be preserved**

The preservation tests act as a regression suite ensuring that architectural improvements don't break existing features.
