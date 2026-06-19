# Architecture Violations - Counterexamples Found

**Test Date**: Bug Condition Exploration Tests
**Test Status**: ✅ FAILED AS EXPECTED (confirms violations exist)
**Code Status**: UNFIXED

## Summary

All 6 bug condition exploration tests **failed as expected**, confirming that all 5 architecture violations exist in the unfixed codebase. These failures serve as proof that the violations are present and provide concrete counterexamples for each violation.

---

## Counterexample 1: Cross-Feature Dependency

**File**: `lib/app_versions/v1/features/onboarding/presentation/controllers/onboarding_controller.dart`

**Violation Details**:
- **Line 4**: Imports `dashboard_controller.dart` from a different feature
  ```dart
  import 'package:nano_app/app_versions/v1/features/dashboard/presentation/controllers/dashboard_controller.dart';
  ```
- **Line 302**: Direct cross-feature controller call
  ```dart
  await ref.read(dashboardControllerProvider.notifier).genMealByWeeksToDB();
  ```

**Test Result**: ❌ FAILED (Expected: no cross-feature import, Actual: import found)

**Impact**: 
- Cannot test OnboardingController in isolation without mocking DashboardController
- Tight coupling between onboarding and dashboard features
- Violates feature independence principle

**Expected Behavior After Fix**:
- OnboardingController should communicate through callbacks or events
- No direct import of DashboardController
- Features remain independently testable

---

## Counterexample 2: Circular Dependency

**Files**:
- `lib/app_versions/v1/services/ai/ai_service.dart` (line 9)
- `lib/app_versions/v1/features/dashboard/presentation/controllers/dashboard_controller.dart` (line 8)

**Violation Details**:
- **AIService line 9**: Imports DashboardEntity from dashboard feature
  ```dart
  import 'package:nano_app/app_versions/v1/features/dashboard/domain/entities/dashboard_entity.dart';
  ```
- **DashboardController line 8**: Imports AIService
  ```dart
  import 'package:nano_app/app_versions/v1/services/ai/ai_service.dart';
  ```

**Test Result**: ❌ FAILED (Expected: no service→feature dependency, Actual: circular dependency found)

**Impact**:
- Core service (AIService) depends on feature entity (DashboardEntity)
- Violates dependency inversion - services should not depend on features
- AIService cannot be reused for other features without carrying DashboardEntity dependency
- Creates maintenance burden and tight coupling

**Expected Behavior After Fix**:
- AIService should accept an abstract interface (HealthDataInterface) from core
- Dashboard implements the interface
- Unidirectional dependency: features → services (not both directions)

---

## Counterexample 3: Misnamed Datasource

**File**: `lib/app_versions/v1/features/onboarding/data/datasource/onboarding_remote_datasource.dart`

**Violation Details**:
- **Line 4**: Imports SQLite (local database)
  ```dart
  import 'package:sqflite/sqflite.dart';
  ```
- **Line 6**: Uses DatabaseService (local SQLite)
  ```dart
  import 'package:nano_app/core/storage/localdb/database_service.dart';
  ```
- **File name**: Claims to be "remote" datasource but performs local database operations

**Test Result**: ❌ FAILED (Expected: file named "local", Actual: file named "remote" but uses SQLite)

**Impact**:
- Misleading naming makes codebase harder to understand
- Developers might expect HTTP/API calls when they see "remote"
- Violates naming conventions (local = SQLite, remote = API)

**Expected Behavior After Fix**:
- File renamed to `onboarding_local_datasource.dart`
- Class renamed to `OnboardingLocalDatasource`
- Clear distinction between local and remote data sources

---

## Counterexample 4: Nested Feature Structure

**Path**: `lib/app_versions/v1/features/meal_plan/dashboard/`

**Violation Details**:
- Nested "dashboard" folder within meal_plan feature
- Contains its own `data/`, `domain/`, `presentation/`, and `providers/` subfolders
- Structure: 
  ```
  lib/app_versions/v1/features/meal_plan/
    └── dashboard/           ❌ WRONG - nested feature
        ├── data/
        ├── domain/
        ├── presentation/
        └── providers/
  ```

**Test Result**: ❌ FAILED (Expected: flat structure, Actual: nested dashboard folder found)

**Impact**:
- Violates Feature-first + Clean Architecture flat structure principle
- Creates confusion about feature boundaries
- Makes navigation and file discovery harder
- Inconsistent with other features in the codebase

**Expected Behavior After Fix**:
- Flat structure at feature root level:
  ```
  lib/app_versions/v1/features/meal_plan/
    ├── data/
    ├── domain/
    ├── presentation/
    └── providers/
  ```
- No nested feature-like folders

---

## Counterexample 5: Misplaced Model

**File**: `lib/core/storage/localdb/models/meal_plan_model.dart`

**Violation Details**:
- Feature-specific model (MealPlanModel) placed in core layer
- Location: `core/storage/localdb/models/` (should be in meal_plan feature)
- Model is specific to meal_plan feature, not a framework-level shared model

**Test Result**: ❌ FAILED (Expected: model in feature, Actual: model in core)

**Impact**:
- Violates layer boundaries (core should only contain truly shared, framework-level code)
- Creates false impression that MealPlanModel is a core concern
- Makes feature less cohesive (feature logic split across core and feature directories)
- Harder to understand feature boundaries

**Expected Behavior After Fix**:
- Model moved to `lib/app_versions/v1/features/meal_plan/data/models/meal_plan_model.dart`
- Feature-specific models contained within their feature
- Core layer only contains truly shared infrastructure

---

## Integration Test Results

The integration test detected **all 6 violation instances**:

```
ARCHITECTURE VIOLATIONS DETECTED:
1. Violation 1: OnboardingController imports DashboardController (line ~4)
2. Violation 1: OnboardingController calls dashboardControllerProvider directly (line ~302)
3. Violation 2: AIService imports DashboardEntity from feature (line ~9)
4. Violation 3: onboarding_remote_datasource.dart uses SQLite but named "remote"
5. Violation 4: Nested "dashboard" folder within meal_plan feature
6. Violation 5: MealPlanModel in core layer instead of meal_plan feature
```

**Test Result**: ❌ FAILED (Expected: no violations, Actual: 6 violations found)

---

## Conclusion

All bug condition exploration tests **failed as expected**, successfully proving that:

1. ✅ Cross-feature dependencies exist between onboarding and dashboard
2. ✅ Circular dependencies exist between AIService and dashboard feature
3. ✅ Datasource naming does not match implementation (remote vs local)
4. ✅ Nested feature structure exists in meal_plan feature
5. ✅ Feature-specific model is misplaced in core layer

These counterexamples confirm the architecture violations described in the bugfix requirements. The tests encode the expected correct behavior and will **pass once the fixes are implemented**.

---

## Next Steps

After fixes are implemented, these tests should:
- ✅ **PASS** - confirming violations are resolved
- Verify event-based communication replaces cross-feature imports
- Verify dependency inversion breaks circular dependencies
- Verify correct datasource naming
- Verify flat feature structure
- Verify correct model placement within features
