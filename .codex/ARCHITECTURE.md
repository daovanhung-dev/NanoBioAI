# ARCHITECTURE — NanoBio / BioAI

This document explains architectural decisions, patterns, and constraints for the BioAI project.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Layer Responsibilities](#layer-responsibilities)
3. [Feature Structure](#feature-structure)
4. [Data Flow Patterns](#data-flow-patterns)
5. [Naming Conventions](#naming-conventions)
6. [Known Violations](#known-violations)
7. [Architecture Decisions (ADR)](#architecture-decisions-adr)

---

## Architecture Overview

**Pattern**: Feature-first + Clean Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     PRESENTATION                         │
│  (UI, Pages, Widgets, Controllers, Providers)           │
│  Depends on: Domain only                                │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ↓
┌─────────────────────────────────────────────────────────┐
│                       DOMAIN                             │
│  (Entities, Repository Interfaces, Use Cases)           │
│  Depends on: Nothing (pure business logic)              │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ↓
┌─────────────────────────────────────────────────────────┐
│                        DATA                              │
│  (Models, Repository Impl, Datasources, DAOs)           │
│  Depends on: Domain                                     │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ↓
┌─────────────────────────────────────────────────────────┐
│                   INFRASTRUCTURE                         │
│  (SQLite, Supabase, Gemini AI, Local Notifications)    │
└─────────────────────────────────────────────────────────┘
```

### Dependency Rule

**The dependency arrow points INWARD**:
- Presentation depends on Domain
- Data depends on Domain
- Domain depends on NOTHING

**This means**:
- Domain never imports from Presentation or Data
- Presentation never imports from Data (must go through Domain)
- Data can implement Domain interfaces

---

## Layer Responsibilities

### 1. Presentation Layer

**Location**: `lib/features/[feature]/presentation/`

**Responsibilities**:
- Display UI using Flutter widgets
- Handle user interactions
- Observe state changes via Riverpod
- Format data for display (e.g., date formatting, number formatting)

**Contains**:
- `pages/` - Screen-level widgets
- `widgets/` - Reusable UI components
- `controllers/` - Riverpod Notifiers/Controllers (state management)

**Rules**:
- ✅ Can import from `domain/`
- ✅ Can watch Riverpod providers
- ❌ Cannot import from `data/`
- ❌ Cannot query database directly
- ❌ Cannot call API services directly

**Example**:
```dart
// ✅ GOOD
class DashboardPage extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    return dashboardAsync.when(
      data: (dashboard) => /* Display UI */,
      loading: () => LoadingState(),
      error: (error, stack) => ErrorState(error: error),
    );
  }
}

// ❌ BAD - Direct database access
class DashboardPage extends StatefulWidget {
  Widget build(BuildContext context) {
    final db = DatabaseService.database; // ← WRONG!
    final data = db.query('health_profiles'); // ← NEVER do this!
    return /* ... */;
  }
}
```

---

### 2. Domain Layer

**Location**: `lib/features/[feature]/domain/`

**Responsibilities**:
- Define business entities (pure Dart classes)
- Define repository interfaces (contracts)
- Define use cases (optional, if complex business logic)
- NO implementation details (no SQL, no HTTP, no UI)

**Contains**:
- `entities/` - Business objects (pure Dart)
- `repositories/` - Repository interfaces (abstract classes)

**Rules**:
- ✅ Pure Dart code only (no Flutter, no sqflite, no http)
- ✅ Can define interfaces
- ❌ Cannot import from `data/` or `presentation/`
- ❌ Cannot have implementation details

**Example**:
```dart
// ✅ GOOD - Domain entity
class DashboardEntity {
  final String fullName;
  final double? heightCm;
  final double? weightKg;
  final List<String> goals;
  
  const DashboardEntity({
    required this.fullName,
    this.heightCm,
    this.weightKg,
    this.goals = const [],
  });
  
  double get bmi {
    if (heightCm == null || weightKg == null) return 0;
    final heightM = heightCm! / 100;
    return weightKg! / (heightM * heightM);
  }
}

// ✅ GOOD - Repository interface
abstract class DashboardRepository {
  Future<DashboardEntity> fetchDashboard();
  Future<void> updateHealthGoals(List<String> goals);
}
```

---

### 3. Data Layer

**Location**: `lib/features/[feature]/data/`

**Responsibilities**:
- Implement repository interfaces from Domain
- Convert between Models (DB) and Entities (Domain)
- Handle data sources (local database, remote API)
- Handle caching, error handling, retries

**Contains**:
- `models/` - Data models (JSON/SQL serialization)
- `datasources/` - Data source implementations (*LocalDatasource, *RemoteDatasource)
- `repositories/` - Repository implementations (*RepositoryImpl)

**Rules**:
- ✅ Implements Domain interfaces
- ✅ Can use Flutter plugins (sqflite, http, dio)
- ✅ Converts Models ↔ Entities
- ❌ Cannot import from Presentation

**Example**:
```dart
// ✅ GOOD - Data model
class DashboardModel {
  final String fullName;
  final double? heightCm;
  final double? weightKg;
  final String goalsJson; // JSON string from DB
  
  // fromMap for SQLite
  factory DashboardModel.fromMap(Map<String, dynamic> map) {
    return DashboardModel(
      fullName: map['full_name'],
      heightCm: map['height_cm'],
      weightKg: map['weight_kg'],
      goalsJson: map['goals_json'] ?? '[]',
    );
  }
  
  // Convert to Domain entity
  DashboardEntity toEntity() {
    return DashboardEntity(
      fullName: fullName,
      heightCm: heightCm,
      weightKg: weightKg,
      goals: (jsonDecode(goalsJson) as List).cast<String>(),
    );
  }
}

// ✅ GOOD - Repository implementation
class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardLocalDatasource datasource;
  
  const DashboardRepositoryImpl({required this.datasource});
  
  @override
  Future<DashboardEntity> fetchDashboard() async {
    final model = await datasource.fetchDashboardData();
    return model.toEntity(); // Convert Model → Entity
  }
}

// ✅ GOOD - Local datasource
class DashboardLocalDatasource {
  const DashboardLocalDatasource();
  
  Future<DashboardModel> fetchDashboardData() async {
    final db = await DatabaseService.database;
    final result = await db.query('health_profiles', limit: 1);
    return DashboardModel.fromMap(result.first);
  }
}
```

---

## Feature Structure

Each feature follows this FLAT structure (NO nested folders):

```
features/[feature_name]/
├── data/
│   ├── models/             # Data models (DB/API serialization)
│   │   └── *_model.dart
│   ├── datasources/        # Data sources
│   │   ├── *_local_datasource.dart
│   │   └── *_remote_datasource.dart  (if needed)
│   └── repositories/       # Repository implementations (optional)
│       └── *_repository_impl.dart
├── domain/
│   ├── entities/           # Business entities
│   │   └── *_entity.dart
│   └── repositories/       # Repository interfaces + impl
│       ├── *_repository.dart
│       └── *_repository_impl.dart
├── presentation/
│   ├── pages/              # Screen-level widgets
│   │   └── *_page.dart
│   ├── widgets/            # Feature-specific widgets
│   │   └── *.dart
│   └── controllers/        # State management
│       └── *_controller.dart
└── providers/              # Riverpod providers
    └── *_provider.dart
```

### Feature Independence Rule

**Features MUST NOT import other features directly!**

❌ **BAD**:
```dart
// In features/onboarding/
import 'package:nano_app/features/dashboard/presentation/controllers/dashboard_controller.dart';
```

✅ **GOOD** - Use callbacks/events/services:
```dart
// In main.dart (app-level coordination)
onboardingCompletionCallbackProvider.overrideWith((ref) {
  return () async {
    await ref.read(dashboardControllerProvider.notifier).generateMealPlan();
  };
});
```

---

## Data Flow Patterns

### 1. Reading Data (Query Flow)

```
User Action
  ↓
UI calls ref.watch(provider)
  ↓
Provider returns AsyncValue
  ↓
Controller/Notifier handles state
  ↓
Calls Repository interface
  ↓
Repository Impl calls Datasource
  ↓
Datasource queries Database/API
  ↓
Returns Model
  ↓
Repository converts Model → Entity
  ↓
Controller updates state
  ↓
UI rebuilds with new data
```

**Example**:
```dart
// 1. UI watches provider
final dashboardAsync = ref.watch(dashboardProvider);

// 2. Provider implementation
final dashboardProvider = FutureProvider<DashboardEntity>((ref) async {
  final repository = ref.read(dashboardRepositoryProvider);
  return await repository.fetchDashboard();
});

// 3. Repository queries datasource
Future<DashboardEntity> fetchDashboard() async {
  final model = await datasource.fetchDashboardData();
  return model.toEntity();
}

// 4. Datasource queries DB
Future<DashboardModel> fetchDashboardData() async {
  final db = await DatabaseService.database;
  final result = await db.query('health_profiles');
  return DashboardModel.fromMap(result.first);
}
```

### 2. Writing Data (Command Flow)

```
User Action
  ↓
UI calls Controller method
  ↓
Controller calls Repository interface
  ↓
Repository Impl converts Entity → Model
  ↓
Repository calls Datasource
  ↓
Datasource writes to Database/API
  ↓
Controller updates state
  ↓
UI shows success/error
```

---

## Naming Conventions

### File Naming

| Type | Pattern | Example |
|------|---------|---------|
| Page | `*_page.dart` | `dashboard_page.dart` |
| Controller | `*_controller.dart` | `dashboard_controller.dart` |
| Provider | `*_provider.dart` | `dashboard_provider.dart` |
| Model | `*_model.dart` | `dashboard_model.dart` |
| Entity | `*_entity.dart` | `dashboard_entity.dart` |
| Repository interface | `*_repository.dart` | `dashboard_repository.dart` |
| Repository impl | `*_repository_impl.dart` | `dashboard_repository_impl.dart` |
| Local datasource | `*_local_datasource.dart` | `dashboard_local_datasource.dart` |
| Remote datasource | `*_remote_datasource.dart` | `auth_remote_datasource.dart` |
| DAO | `*_dao.dart` | `health_profiles_dao.dart` |
| Table | `*_table.dart` | `health_profiles_table.dart` |

### Class Naming

| Type | Pattern | Example |
|------|---------|---------|
| Page | `*Page` | `DashboardPage` |
| Controller | `*Controller` | `DashboardController` |
| Model | `*Model` | `DashboardModel` |
| Entity | `*Entity` | `DashboardEntity` |
| Repository interface | `*Repository` | `DashboardRepository` |
| Repository impl | `*RepositoryImpl` | `DashboardRepositoryImpl` |
| Local datasource | `*LocalDatasource` | `DashboardLocalDatasource` |
| Remote datasource | `*RemoteDatasource` | `AuthRemoteDatasource` |

### Provider Naming

| Type | Pattern | Example |
|------|---------|---------|
| State provider | `*Provider` | `dashboardProvider` |
| Controller provider | `*ControllerProvider` | `dashboardControllerProvider` |
| Repository provider | `*RepositoryProvider` | `dashboardRepositoryProvider` |
| Datasource provider | `*DatasourceProvider` | `dashboardLocalDatasourceProvider` |

---

## Known Violations

See `docs/issues/bug_architecture.md` for detailed analysis.

### Critical Issues

1. **Cross-feature dependency** (onboarding → dashboard)
   - Status: ❌ NOT FIXED
   - Impact: Cannot test features in isolation
   - Fix: Implement callback pattern in main.dart

2. **Nested feature structure** (meal_plan/dashboard/)
   - Status: ❌ NOT FIXED
   - Impact: Confusing folder structure
   - Fix: Flatten to meal_plan/

3. **Model placement** (MealPlanModel in core)
   - Status: ❌ NOT FIXED
   - Impact: Tight coupling between features
   - Fix: Move to features/meal_plan/data/models/

4. **Layer violation** (presentation → datasource)
   - Status: ❌ NOT FIXED
   - Impact: Bypass repository layer
   - Fix: Move datasource provider to correct layer

5. **Naming inconsistency** (MealPlanDatasource)
   - Status: ❌ NOT FIXED
   - Impact: Unclear datasource type
   - Fix: Rename to MealPlanLocalDatasource

### Resolved Issues

1. **Circular dependency** (AI service ↔ Dashboard)
   - Status: ✅ FIXED
   - Solution: Use HealthDataInterface abstraction

---

## Architecture Decisions (ADR)

### ADR-001: Repository Implementation Placement

**Context**: Where should repository implementations be placed?

**Decision**: Repository implementations (e.g., `*RepositoryImpl`) are placed in `domain/repositories/` alongside their interfaces, NOT in `data/repositories/`.

**Rationale**:
- Simplifies navigation (interface + impl in same folder)
- Reduces boilerplate for small-to-medium projects
- Consistent across entire project

**Consequences**:
- ✅ Easier to find implementation
- ✅ Less folder nesting
- ⚠️ Deviates from strict Clean Architecture (where impl should be in Data layer)

**Status**: ACCEPTED (project decision)

---

### ADR-002: Offline-First with SQLite

**Context**: How should we store user data?

**Decision**: Use SQLite as primary storage, Supabase only for authentication.

**Rationale**:
- Privacy-focused (data stays on device)
- Works offline (no internet required)
- Fast queries (no network latency)
- No backend costs for data storage

**Consequences**:
- ✅ Better privacy
- ✅ Offline support
- ✅ Lower costs
- ❌ No cloud sync (data not backed up)
- ❌ Data lost if user uninstalls app

**Status**: ACCEPTED

---

### ADR-003: AI Generation with Fallback

**Context**: What happens when AI generation fails?

**Decision**: Use Gemini AI as primary, with local catalog fallback.

**Rationale**:
- AI provides personalized recommendations
- Fallback ensures app never breaks
- User always gets content (even if generic)

**Implementation**:
```dart
try {
  return await _runWithRetry(/* AI generation */);
} catch (error) {
  return normalizer.fallbackCodeItems(catalog: catalog);
}
```

**Consequences**:
- ✅ Reliable (never fails completely)
- ✅ Good UX (always shows content)
- ⚠️ Fallback content is generic (not personalized)

**Status**: ACCEPTED

---

### ADR-004: Feature-First Structure

**Context**: How should we organize code?

**Decision**: Use feature-first structure, not layer-first.

**Rationale**:
- Features are independent units
- Easier to understand and maintain
- Better scalability (add/remove features)
- Clearer ownership (each feature has all its layers)

**Structure**:
```
features/
  dashboard/
    data/
    domain/
    presentation/
    providers/
  meal_plan/
    data/
    domain/
    presentation/
    providers/
```

**Status**: ACCEPTED

---

### ADR-005: Vietnamese Text with Diacritics

**Context**: Should user-facing text have Vietnamese diacritics?

**Decision**: ALL user-facing text MUST have proper Vietnamese diacritics.

**Rationale**:
- Professional appearance
- Better readability
- Respects user language
- Improves SEO (if web version)

**Examples**:
- ✅ "Sức khỏe" (not "Suc khoe")
- ✅ "Dinh dưỡng" (not "Dinh duong")
- ✅ "Cân nặng" (not "Can nang")

**Enforcement**:
- Code review checks
- Linter rule (if possible)
- Test validation (check for missing diacritics)

**Status**: ACCEPTED (enforced in all new code)

---

## Quick Reference

### Do's ✅

- Follow feature-first structure
- Use proper layer separation
- Name datasources with Local/Remote prefix
- Convert Models ↔ Entities at repository layer
- Use Vietnamese diacritics for user-facing text
- Write tests for critical flows
- Update database version when schema changes

### Don'ts ❌

- Don't bypass layers (presentation → data)
- Don't import features from other features
- Don't use mock/fake data in production
- Don't call APIs in tests
- Don't hardcode API keys
- Don't nest feature folders
- Don't use dynamic/!/as without reason

---

**Last Updated**: 2026-06-18  
**Maintained By**: Development Team  
**Version**: 1.0
