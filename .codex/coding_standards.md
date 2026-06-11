# Coding Standards

## Naming conventions

| Loại | Convention | Ví dụ |
|---|---|---|
| Class | PascalCase | `OnboardingController`, `MealPlanModel` |
| File | snake_case | `onboarding_controller.dart` |
| Provider | camelCase + `Provider` suffix | `dashboardRepositoryProvider` |
| State class | PascalCase + `State` | `OnboardingState`, `SplashStatus` |
| Route paths | snake_case trong constant | `RoutePaths.mealPlan = '/meal-plan'` |

## Cấu trúc file trong mỗi feature

```
feature_name/
├── data/
│   ├── datasources/feature_datasource.dart   ← tương tác DB/API
│   └── models/feature_model.dart             ← extends entity, có fromJson/fromMap
├── domain/
│   ├── entities/feature_entity.dart          ← plain Dart, không import flutter
│   └── repositories/
│       ├── feature_repository.dart           ← abstract class
│       └── feature_repository_impl.dart      ← implementation
├── presentation/
│   ├── controllers/feature_controller.dart   ← Notifier / AsyncNotifier
│   ├── pages/feature_page.dart               ← ConsumerWidget / ConsumerStatefulWidget
│   └── widgets/                              ← private widgets của feature
└── providers/
    ├── feature_provider.dart                 ← Provider wiring
    └── repository_providers.dart             ← (optional) tách riêng repo providers
```

## Riverpod patterns

- **Notifier** (gen3): `class XController extends Notifier<XState>` với `NotifierProvider`
- **AsyncNotifier**: `class XController extends AsyncNotifier<T>` với `AsyncNotifierProvider`
- **FutureProvider**: dùng cho read-only async data
- **Provider**: dùng cho DI (datasource, repository, service)
- Không dùng `StateProvider`, `ChangeNotifierProvider`
- Inject dependency qua `ref.read(provider)` trong controller

## State pattern

`copyWith` pattern cho immutable state:
```dart
state = state.copyWith(fieldName: newValue);
```

## SQLite conventions

- Primary key: `TEXT` (timestamp string), không dùng `INTEGER AUTOINCREMENT`
- Boolean: `INTEGER` 0/1
- DateTime: `TEXT` ISO8601
- Tất cả foreign key constraints bị `PRAGMA foreign_keys = OFF` → không tự enforce
- Sử dụng `transaction()` cho write operations phức tạp

## Import style
- Dùng barrel file (`*.dart` export) để import gộp:
  - `import 'package:nano_app/core/theme/theme.dart'` (export tất cả theme)
  - `import 'package:nano_app/core/core.dart'`
- Không import từng file riêng lẻ khi có barrel file

## Tổ chức constants
- Route paths: `core/constants/routes/route_names.dart` → `RoutePaths`
- Navigation: `core/router/navigation_service.dart` → `AppNavigator`
- Design tokens: `core/theme/` (AppColors, AppSpacing, AppRadius, AppGradients, etc.)

## Đặt tên bảng SQLite
`snake_case` plural: `users`, `health_profiles`, `health_goals`, `meal_plans`

## Debug logging
Dùng `debugPrint()` (không dùng `print()`) cho production-safe logging. Thực tế code có mix cả hai — `print()` thường được dùng cho quick debug.
