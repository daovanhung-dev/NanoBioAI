# Architecture Bugs Report

**Date**: 2026-06-12  
**Project**: BioAI (nano_app)  
**Architecture**: Feature-first + Clean Architecture

---

## Executive Summary

Phát hiện **8 vi phạm kiến trúc nghiêm trọng** trong codebase, bao gồm:
- **3 vi phạm dependency rules** (cross-feature, circular, layer violations)
- **2 vi phạm naming conventions** (datasource naming)
- **1 vi phạm folder structure** (nested feature folder)
- **2 vi phạm model placement** (models in wrong layers)

Tất cả các vi phạm này phá vỡ nguyên tắc Clean Architecture và Feature-first, làm giảm khả năng maintainability, testability và scalability của dự án.

---

## Bug Classification

### Severity Levels:
- 🔴 **CRITICAL**: Phá vỡ dependency rules, circular dependencies
- 🟠 **HIGH**: Layer violations, cross-feature coupling
- 🟡 **MEDIUM**: Naming inconsistencies, structural issues
- 🔵 **LOW**: Minor violations có thể refactor sau

---

## Bug #1: Cross-Feature Dependency (Onboarding → Dashboard)

**Severity**: 🔴 **CRITICAL**

### Description
Feature `onboarding` import trực tiếp controller từ feature `dashboard`, vi phạm nguyên tắc feature independence trong Feature-first architecture.

### Location
```
File: lib/features/onboarding/presentation/controllers/onboarding_controller.dart
Line: 4
```

### Evidence
```dart
// Line 4
import 'package:nano_app/features/dashboard/presentation/controllers/dashboard_controller.dart';

// Line 302 - saveOnboarding() method
await ref.read(dashboardControllerProvider.notifier).genMealByWeeksToDB();
```

### Impact
- ❌ **Testability**: Không thể test `OnboardingController` độc lập mà không mock `DashboardController`
- ❌ **Maintainability**: Thay đổi dashboard controller có thể break onboarding feature
- ❌ **Reusability**: Onboarding feature không thể tái sử dụng trong project khác vì phụ thuộc dashboard
- ❌ **Scalability**: Tạo tight coupling giữa features, khó scale theo chiều ngang

### Architecture Principle Violated
> **Feature-first Rule**: Features KHÔNG được import lẫn nhau trực tiếp. Cross-feature communication phải thông qua events, callbacks, hoặc service layer.

### Root Cause
Thiếu event-based communication pattern. Developer cần trigger meal generation sau khi onboarding complete, nên gọi trực tiếp dashboard controller thay vì dùng callback pattern.

### Proposed Fix
Implement event-based communication pattern:
1. Add callback parameter to `OnboardingController`
2. Wire callback in provider layer (only place that knows about cross-feature coordination)
3. Remove direct import of `dashboard_controller.dart`

**Fix complexity**: MEDIUM (requires refactoring controller + provider)

---

## Bug #2: Circular Dependency Risk (AI Service ↔ Dashboard)

**Severity**: 🔴 **CRITICAL** (RESOLVED)

### Description
**Status**: ✅ **ĐÃ FIX** - AI service hiện đang sử dụng `HealthDataInterface` từ core thay vì `DashboardEntity`, phá vỡ circular dependency.

### Location
```
File: lib/services/ai/ai_service.dart
Line: 8 (import HealthDataInterface - CORRECT)
```

### Evidence (Current State)
```dart
// ✅ CORRECT - Using abstraction from core
import 'package:nano_app/core/interfaces/health_data_interface.dart';

// generateMealPlan method signature
Future<List<MealPlanModel>> generateMealPlan({
  required HealthDataInterface healthData,  // ✅ Using interface, not concrete entity
}) async {
```

### Previous Issue (NOW FIXED)
Trước đây AI service import `DashboardEntity` từ dashboard feature, tạo circular dependency:
- `dashboard_controller.dart` import `ai_service.dart`
- `ai_service.dart` import `dashboard_entity.dart` (from dashboard feature)

### Current State
✅ Circular dependency đã được phá vỡ bằng Dependency Inversion:
- AI service chỉ phụ thuộc vào abstraction (`HealthDataInterface` trong core)
- Dashboard entity implement interface
- Dependency flow: dashboard → ai_service → core/interfaces (unidirectional)

### Notes
Bug này đã được fix đúng theo Clean Architecture principles. Giữ lại trong report để document architecture evolution.

---

## Bug #3: Nested Feature Structure (meal_plan/dashboard/)

**Severity**: 🟠 **HIGH**

### Description
Feature `meal_plan` có cấu trúc nested với folder `dashboard` bên trong, vi phạm flat feature structure của Feature-first architecture.

### Location
```
lib/features/meal_plan/dashboard/
├── data/
│   └── datasources/
├── domain/
│   └── repositories/
├── presentation/
│   ├── controllers/
│   └── pages/
└── providers/
```

### Evidence
```
Directory exists: lib/features/meal_plan/dashboard/
Should be:        lib/features/meal_plan/
```

### Impact
- ❌ **Readability**: Cấu trúc thư mục phức tạp, khó navigate
- ❌ **Consistency**: Không nhất quán với các features khác (dashboard, onboarding, auth)
- ❌ **Maintainability**: Import paths dài và khó đọc
- ❌ **Confusion**: "dashboard" subfolder gây nhầm lẫn, không rõ mục đích

### Architecture Principle Violated
> **Feature-first Rule**: Mỗi feature phải có cấu trúc FLAT với các layer (data, domain, presentation, providers) trực tiếp dưới feature folder.

### Root Cause
Feature được tạo với nested structure ban đầu (có thể copy từ feature khác hoặc plan có multiple sub-features), nhưng không được refactor về flat structure.

### Proposed Fix
Flatten folder structure:
1. Move all files from `meal_plan/dashboard/*` up to `meal_plan/*`
2. Update all import paths
3. Delete empty `dashboard/` folder

**Fix complexity**: MEDIUM (requires moving files + updating imports)

---

## Bug #4: Model Placement Violation (MealPlanModel in Core)

**Severity**: 🟠 **HIGH**

### Description
`MealPlanModel` là feature-specific model nhưng lại được đặt trong core layer, vi phạm layer boundaries của Clean Architecture.

### Location
```
File: lib/core/storage/localdb/models/meal_plan_model.dart
Should be: lib/features/meal_plan/data/models/meal_plan_model.dart
```

### Evidence
```dart
// Current imports (WRONG)
import 'package:nano_app/core/storage/localdb/models/meal_plan_model.dart';

// Should be (CORRECT)
import 'package:nano_app/features/meal_plan/data/models/meal_plan_model.dart';
```

### Files Affected
1. `lib/services/ai/ai_service.dart` (line 7)
2. `lib/features/dashboard/presentation/controllers/dashboard_controller.dart` (line 3)
3. `lib/features/meal_plan/dashboard/presentation/controllers/meal_plan_controller.dart` (line 2)
4. `lib/features/meal_plan/dashboard/presentation/pages/meal_plan_page.dart` (line 4)
5. `lib/features/meal_plan/dashboard/domain/repositories/meal_plan_repository_impl.dart` (line 1)
6. `lib/features/dashboard/domain/repositories/dashboard_repository_impl.dart` (line 2)

### Impact
- ❌ **Layer Boundaries**: Core layer không nên chứa feature-specific logic/models
- ❌ **Feature Independence**: Các features khác phụ thuộc vào core model của meal_plan
- ❌ **Reusability**: Khó tái sử dụng meal_plan feature độc lập
- ❌ **Circular Risk**: Tạo risk cho circular dependencies trong tương lai

### Architecture Principle Violated
> **Clean Architecture Rule**: Core layer chỉ chứa shared infrastructure, utilities, và abstractions. Feature-specific models phải nằm trong feature layer.

### Root Cause
Model được đặt trong core layer trong quá trình rapid development, có thể vì nó được share giữa dashboard và meal_plan features. Nhưng đây là violation - nên sử dụng domain entities hoặc interfaces thay vì share models.

### Proposed Fix
Migrate model to feature layer:
1. Move `meal_plan_model.dart` from `core/storage/localdb/models/` to `features/meal_plan/data/models/`
2. Update all 6+ import statements
3. Remove from core barrel exports (if exists)

**Fix complexity**: MEDIUM (requires moving file + updating many imports)

---

## Bug #5: Presentation Layer Directly Accessing Datasources

**Severity**: 🟠 **HIGH**

### Description
Presentation layer (controller) import trực tiếp từ data layer (datasource), bỏ qua domain layer và vi phạm dependency rules của Clean Architecture.

### Location
```
File: lib/features/meal_plan/dashboard/presentation/controllers/meal_plan_controller.dart
Line: 3
```

### Evidence
```dart
// Line 3 - VIOLATION: Presentation importing Data layer directly
import 'package:nano_app/features/meal_plan/dashboard/data/datasources/meal_datasource.dart';

// Line 8-10 - Creating datasource provider in presentation layer
final mealDataSource = Provider<MealPlanDatasource>((ref) {
  return const MealPlanDatasource();
});
```

### Impact
- ❌ **Layer Violation**: Presentation layer KHÔNG được biết về Data layer implementation
- ❌ **Testability**: Khó mock datasource trong controller tests
- ❌ **Flexibility**: Khó swap datasource implementation
- ❌ **Dependency Flow**: Vi phạm dependency rule (presentation → domain → data)

### Architecture Principle Violated
> **Clean Architecture Dependency Rule**: Presentation layer chỉ được phụ thuộc vào Domain layer (repositories, entities). Data layer chỉ được access qua repository interfaces.

### Root Cause
Provider được tạo sai vị trí. Datasource provider nên ở trong providers/ folder hoặc data layer, KHÔNG phải presentation layer.

### Proposed Fix
1. Move datasource provider to `features/meal_plan/providers/meal_plan_provider.dart`
2. Remove datasource import from controller
3. Controller chỉ nên import và sử dụng repository interface

**Fix complexity**: LOW (move provider + update imports)

---

## Bug #6: Datasource Naming Inconsistency (MealPlanDatasource)

**Severity**: 🟡 **MEDIUM**

### Description
`MealPlanDatasource` sử dụng SQLite (local storage) nhưng không có prefix "local" hoặc "remote" trong tên, gây confusion về datasource type.

### Location
```
File: lib/features/meal_plan/dashboard/data/datasources/meal_datasource.dart
```

### Evidence
```dart
import 'package:sqflite/sqflite.dart';  // ← Using SQLite (local)
import 'package:nano_app/core/storage/localdb/database_service.dart';

class MealPlanDatasource {  // ← Missing "Local" prefix
  const MealPlanDatasource();
  
  Future<Database> _db() async {
    return DatabaseService.database;  // ← Local SQLite database
  }
}
```

### Comparison with Other Datasources
✅ **CORRECT naming**:
- `OnboardingLocalDatasource` - uses SQLite → has "Local" prefix
- `AuthRemoteDatasource` - uses Supabase API → has "Remote" prefix
- `DashboardLocalDatasource` - uses SQLite → has "Local" prefix

❌ **INCORRECT naming**:
- `MealPlanDatasource` - uses SQLite → MISSING "Local" prefix

### Impact
- ⚠️ **Confusion**: Không rõ datasource type khi nhìn vào tên
- ⚠️ **Inconsistency**: Không nhất quán với naming convention của project
- ⚠️ **Maintenance**: Khó phân biệt local vs remote datasources khi refactor

### Architecture Principle Violated
> **Naming Convention**: Datasource phải có prefix "Local" (SQLite) hoặc "Remote" (API) để phân biệt rõ ràng data source type.

### Root Cause
Datasource được tạo mà không follow naming convention đã establish trong project.

### Proposed Fix
Rename to match convention:
1. Rename class from `MealPlanDatasource` to `MealPlanLocalDatasource`
2. Rename file from `meal_datasource.dart` to `meal_local_datasource.dart`
3. Update all imports and references

**Fix complexity**: LOW (simple rename + update imports)

---

## Bug #7: Presentation Layer Directly Accessing Core Models

**Severity**: 🟡 **MEDIUM**

### Description
Presentation layer (pages, controllers) import trực tiếp models từ core layer thay vì sử dụng domain entities, vi phạm layer separation.

### Locations
1. `lib/features/dashboard/presentation/controllers/dashboard_controller.dart` (line 3)
2. `lib/features/meal_plan/dashboard/presentation/controllers/meal_plan_controller.dart` (line 2)
3. `lib/features/meal_plan/dashboard/presentation/pages/meal_plan_page.dart` (line 4)

### Evidence
```dart
// WRONG: Presentation importing Core models
import 'package:nano_app/core/storage/localdb/models/meal_plan_model.dart';

// CORRECT: Should use Domain entities
import 'package:nano_app/features/meal_plan/domain/entities/meal_plan_entity.dart';
```

### Impact
- ❌ **Layer Coupling**: Presentation layer coupled to data models instead of domain entities
- ❌ **Business Logic**: Models chứa database serialization logic, không phải business logic
- ❌ **Testability**: Khó test với mock data vì phụ thuộc vào concrete models
- ❌ **Flexibility**: Không thể thay đổi data layer mà không ảnh hưởng presentation

### Architecture Principle Violated
> **Clean Architecture**: Presentation layer chỉ nên biết về Domain entities. Models là implementation details của Data layer.

### Root Cause
1. Missing `MealPlanEntity` in domain layer
2. Repository trả về Models thay vì Entities
3. Presentation layer sử dụng trực tiếp Models vì dễ dàng hơn

### Proposed Fix
1. Create `MealPlanEntity` in `features/meal_plan/domain/entities/`
2. Update repository interface to return entities
3. Update repository impl to convert models → entities
4. Update presentation layer to use entities

**Fix complexity**: HIGH (requires creating entity + updating repository + updating presentation)

**Note**: Bug này liên quan đến Bug #4. Nên fix cùng lúc khi migrate MealPlanModel về feature layer.

---

## Bug #8: Repository Implementation in Domain Layer

**Severity**: 🔵 **LOW** (Documentation issue, not architecture violation)

### Description
File `meal_plan_repository_impl.dart` nằm trong `domain/repositories/` folder. Về mặt lý thuyết, implementations nên ở `data/repositories/`, nhưng project này có quyết định architecture đặt impl luôn trong domain layer.

### Location
```
File: lib/features/meal_plan/dashboard/domain/repositories/meal_plan_repository_impl.dart
```

### Evidence
```
domain/
└── repositories/
    ├── meal_plan_repository.dart          ← Abstract interface
    └── meal_plan_repository_impl.dart     ← Concrete implementation
```

### Analysis
**Current approach (Project's decision)**:
```
domain/repositories/
  ├── repository.dart (abstract)
  └── repository_impl.dart (concrete)
```

**Traditional Clean Architecture**:
```
domain/repositories/
  └── repository.dart (abstract only)
data/repositories/
  └── repository_impl.dart (concrete)
```

### Impact
⚠️ **Moderate** - Không phải violation nghiêm trọng vì:
- Project có quyết định architecture nhất quán (tất cả features đều làm như vậy)
- Documented trong `.codex/architecture.md`:
  > "domain/repositories/ ← abstract + impl (chứa impl luôn tại đây)"

### Architecture Principle Consideration
> **Clean Architecture**: Về lý thuyết, Domain layer chỉ chứa abstractions, implementations nên ở Data layer. Nhưng project này chọn cách đơn giản hóa bằng cách đặt impl cùng chỗ với interface.

### Root Cause
Architecture decision để giảm complexity - developer không phải navigate giữa nhiều folders để tìm implementation.

### Recommendation
**Option 1 (RECOMMENDED)**: Giữ nguyên current approach
- ✅ Đã consistent across project
- ✅ Đã documented trong architecture guide
- ✅ Đơn giản hơn cho small-to-medium projects
- ⚠️ Cần update documentation để clarify đây là intentional decision

**Option 2**: Refactor về traditional Clean Architecture
- ❌ Tốn effort lớn
- ❌ Break nhiều imports
- ✅ Theo đúng lý thuyết Clean Architecture
- ✅ Tốt cho large-scale projects

**Decision**: Giữ nguyên, nhưng add comment trong code clarifying architecture decision.

**Fix complexity**: NONE (document only) hoặc VERY HIGH (nếu refactor)

---

## Summary Table

| Bug # | Severity | Type | Location | Status | Fix Complexity |
|-------|----------|------|----------|--------|----------------|
| #1 | 🔴 CRITICAL | Cross-Feature Dependency | onboarding_controller.dart | ❌ NOT FIXED | MEDIUM |
| #2 | 🔴 CRITICAL | Circular Dependency | ai_service.dart | ✅ FIXED | N/A |
| #3 | 🟠 HIGH | Nested Structure | features/meal_plan/dashboard/ | ❌ NOT FIXED | MEDIUM |
| #4 | 🟠 HIGH | Model Placement | core/.../meal_plan_model.dart | ❌ NOT FIXED | MEDIUM |
| #5 | 🟠 HIGH | Layer Violation | meal_plan_controller.dart | ❌ NOT FIXED | LOW |
| #6 | 🟡 MEDIUM | Naming Inconsistency | meal_datasource.dart | ❌ NOT FIXED | LOW |
| #7 | 🟡 MEDIUM | Layer Coupling | presentation imports core | ❌ NOT FIXED | HIGH |
| #8 | 🔵 LOW | Documentation | repository_impl placement | ⚠️ BY DESIGN | NONE |

**Total bugs**: 8  
**Critical**: 1 not fixed, 1 fixed  
**High**: 3 not fixed  
**Medium**: 2 not fixed  
**Low**: 1 by design

---

## Impact Analysis

### Immediate Risks
1. ❌ **Cannot test features in isolation** (Bug #1, #5)
2. ❌ **Tight coupling between features** (Bug #1, #4)
3. ❌ **Confusing folder structure** (Bug #3, #6)

### Long-term Risks
1. 🔻 **Decreased maintainability** - Changes in one feature affect others
2. 🔻 **Reduced testability** - Cannot unit test features independently
3. 🔻 **Poor scalability** - Hard to add new features without breaking existing ones
4. 🔻 **Knowledge debt** - New developers confused by architecture violations

---

## Recommendations

### Priority 1: Critical Fixes (Do First)
1. **Fix Bug #1**: Implement event-based communication for onboarding → dashboard
   - Estimated effort: 4-6 hours
   - Risk: Medium (requires testing complete onboarding flow)

### Priority 2: High-Impact Structural Fixes (Do Soon)
2. **Fix Bug #3**: Flatten meal_plan folder structure
   - Estimated effort: 2-3 hours
   - Risk: Low (mostly file moves + import updates)

3. **Fix Bug #4 + #7 together**: Migrate model to feature + create domain entity
   - Estimated effort: 6-8 hours
   - Risk: Medium (affects multiple features)

4. **Fix Bug #5**: Move datasource provider to correct layer
   - Estimated effort: 1 hour
   - Risk: Very Low

### Priority 3: Consistency Fixes (Nice to Have)
5. **Fix Bug #6**: Rename datasource for consistency
   - Estimated effort: 30 minutes
   - Risk: Very Low

### Priority 4: Documentation
6. **Bug #8**: Document repository implementation placement decision
   - Estimated effort: 15 minutes
   - Risk: None

**Total estimated effort**: ~14-18 hours

---

## Prevention Strategies

### Architecture Rules to Enforce

1. **Feature Independence Rule**
   ```
   Features MUST NOT import other features directly.
   Use: callbacks, events, service layer, or mediator pattern.
   ```

2. **Layer Dependency Rule**
   ```
   presentation → domain → data
   NEVER: presentation → data (skip domain)
   ```

3. **Naming Convention Rule**
   ```
   Local datasources: *LocalDatasource (uses SQLite)
   Remote datasources: *RemoteDatasource (uses APIs)
   ```

4. **Model Placement Rule**
   ```
   Feature-specific models → features/[name]/data/models/
   Shared infrastructure → core/
   ```

5. **Flat Feature Structure Rule**
   ```
   features/[name]/
   ├── data/
   ├── domain/
   ├── presentation/
   └── providers/
   
   NO nested feature folders!
   ```

### Tools to Consider

1. **Dart Analyzer Custom Rules**
   - Add lint rules to detect cross-feature imports
   - Add rules to detect layer violations

2. **Import Path Validation**
   - Pre-commit hook to check import patterns
   - CI/CD check for architecture violations

3. **Architecture Decision Records (ADR)**
   - Document all architecture decisions (như Bug #8)
   - Review in code review process

---

## References

- `.codex/architecture.md` - Project architecture documentation
- `.kiro/specs/architecture-violations-fix/` - Fix specification (in progress)
- Clean Architecture by Robert C. Martin
- Flutter architecture best practices

---

**Generated**: 2026-06-12  
**Analyzer**: Kiro AI  
**Version**: 1.0
