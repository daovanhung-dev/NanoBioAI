# Testing And Quality

## Test files

Current test tree:

- `test/widget_test.dart`
- `test/architecture_violation_exploration_test.dart`
- `test/architecture_preservation_property_test.dart`
- `test/core/theme/foundation/motion_test.dart`
- `test/core/theme/foundation/gradient_test.dart`
- `test/core/theme/primitives/button_test.dart`
- `test/features/settings/domain/validators/settings_validator_test.dart`
- `test/features/settings/data/datasources/settings_local_datasource_test.dart`
- `test/services/biometric/biometric_service_test.dart`
- `test/services/image_picker_service_test.dart`

Docs in test folder:

- `test/PRESERVATION_BASELINE_OBSERVATIONS.md`
- `test/ARCHITECTURE_VIOLATIONS_COUNTEREXAMPLES.md`

## Important: intentional failing tests

`test/architecture_violation_exploration_test.dart` is designed to fail on the current code until architecture issues are fixed. Do not treat its failure as a surprise regression.

It checks:

- Onboarding must not import DashboardController.
- AIService must not import DashboardEntity.
- Misnamed onboarding remote datasource should be gone.
- `meal_plan` should not have nested `dashboard` folder.
- `MealPlanModel` should not live in core.

Current expected reality:

- Some checks are already fixed/stale:
  - AIService no longer imports DashboardEntity; it uses `HealthDataInterface`.
  - Onboarding datasource is now `onboarding_local_datasource.dart`.
- Some still fail:
  - Onboarding still imports DashboardController.
  - `meal_plan/dashboard` nested structure still exists.
  - `MealPlanModel` still lives in core.

Use this test as a target after architecture refactor, not as a required green test today unless user explicitly asks to fix architecture.

## Preservation tests

`test/architecture_preservation_property_test.dart` should pass before and after architecture refactor. It encodes behavior that must remain:

- Onboarding completion triggers meal generation.
- 7-step onboarding remains.
- Gemini integration and JSON parsing remain.
- Meal plan DB save uses `DatabaseService`, `MealPlansDao`, `insertMany`.
- Onboarding saves all health tables.
- Dashboard reads all health tables.
- `MealPlanModel` fields and serialization remain.
- `AppPrefs.setOnboardingCompleted(true)` remains.
- `DashboardController.genMealByWeeksToDB()` orchestration remains.
- Provider API surfaces remain available.

When refactoring architecture, run this test before/after.

## Settings tests

`settings_validator_test.dart` verifies:

- Meal reminder time must be `HH:mm`.
- Valid hours 00-23, minutes 00-59.
- Language code must be `vi` or `en`.

`settings_local_datasource_test.dart` is partly behavioral for SharedPreferences and partly documentation/spec tests for DB logic. It does not fully integration-test SQLite profile operations.

## Service tests

`biometric_service_test.dart` validates:

- Service instantiation.
- `BiometricException` shape.
- API method existence.

It does not perform device-level biometric integration.

`image_picker_service_test.dart` validates:

- Allowed formats: png/jpg/jpeg.
- Max size: 5MB.
- Basic API method existence.

It does not mock real `XFile` operations.

## Useful commands

Run all tests:

```powershell
flutter test
```

Run preservation tests:

```powershell
flutter test test/architecture_preservation_property_test.dart
```

Run architecture exploration tests:

```powershell
flutter test test/architecture_violation_exploration_test.dart
```

Run settings tests:

```powershell
flutter test test/features/settings
```

Run theme tests:

```powershell
flutter test test/core/theme
```

Analyze:

```powershell
flutter analyze
```

Format:

```powershell
dart format .
```

## Quality observations

- There are TODO DAOs for most local tables except meal plans.
- Several UI screens are large single files with many private widgets.
- Some provider definitions are duplicated.
- Some docs are stale relative to code, especially architecture bug docs.
- Some routes are unguarded while auth assumptions exist.
- Debug `print()`/`debugPrint()` is common in AI/onboarding/dashboard.

## When changing code

For narrow changes:

- Read the feature folder first.
- Preserve public provider names if tests/docs mention them.
- Keep DB serialization contract stable.
- Run targeted tests plus `flutter analyze` if feasible.

For architecture refactor:

- Run `architecture_preservation_property_test.dart` first.
- Make one boundary change at a time.
- Keep onboarding -> meal generation behavior intact.
- Update `.codex` context if file paths or core flow change.
