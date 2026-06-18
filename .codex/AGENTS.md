# AGENTS — NanoBio / BioAI

Đây là file luật chính. Mục tiêu: Codex hiểu đúng dự án, sửa đúng phạm vi, test đúng quy trình, tiết kiệm token tối đa.

## 1. Project identity

- **App**: NanoBio / BioAI - AI-powered health tracking application
- **Package**: `nano_app`
- **Version**: 1.0.0+1 (Database v8)
- **Stack**: 
  - Flutter 3.9.2+, Dart 3.0+
  - State: Riverpod 3.3.1 (Notifier Gen 3)
  - Navigation: GoRouter 17.2.3
  - DB: SQLite (sqflite 2.4.2) - offline-first, 19 tables
  - Auth: Supabase 2.12.4 (auth only)
  - AI: Google Gemini 2.5 Flash (meal + exercise generation)
  - Notifications: flutter_local_notifications (reminder system)
- **Architecture**: Feature-first + Clean Architecture
- **UI Persona**: Nami — trợ lý sức khỏe tiếng Việt có dấu, nhẹ nhàng, ân cần, không phán xét
- **Design System**: 3-layer token architecture (Foundation → Semantic → Component)

## 2. Read order bắt buộc

Luôn đọc theo thứ tự:

1. **`.codex/AGENTS.md`** (file này) - Luật chính và identity
2. **`.codex/PROJECT_MAP.md`** - Entry points, task routing, search commands
3. **Playbook liên quan** - Chỉ đọc 1 playbook cho task hiện tại:
   - Dashboard/health score → `.codex/playbooks/dashboard.md`
   - Onboarding flow → `.codex/playbooks/onboarding.md`
   - AI/meal/exercise/parser → `.codex/playbooks/ai_service.md`
   - Notification/reminder/action → `.codex/playbooks/notification.md`
   - SQLite/DAO/migration → `.codex/playbooks/sqlite.md`
   - UI/theme/copywriting → `.codex/playbooks/ui.md`
   - Daily health tracking → `.codex/playbooks/health_tracking.md`
   - Lifestyle schedule → `.codex/playbooks/lifestyle_schedule.md`

**Token saving rule**: Không đọc toàn bộ project nếu task chỉ liên quan một module. Dùng `rg` để tìm usage trước khi mở file.

## 3. Luồng kiến trúc phải giữ

### Layer dependency rules (Clean Architecture)

```text
Presentation → Domain → Data
   (UI)      (Business)  (Storage)
```

**Dependency flow**:
```text
UI/Page/Widget 
  ↓ watch/read
Riverpod Provider 
  ↓
Controller/Notifier 
  ↓
Repository (interface) 
  ↓
Repository Impl 
  ↓
Datasource (Local/Remote) 
  ↓
DAO/SQLite hoặc API Service
```

### Quy tắc cứng - VI PHẠM SẼ GÂY BUG

**✅ PHẢI LÀM**:
- UI chỉ gọi Provider/Controller
- Controller chỉ gọi Repository interface
- Repository impl gọi Datasource
- Datasource gọi DAO hoặc Service
- Text tiếng Việt hiển thị cho user **PHẢI có dấu**
- Datasource phải có prefix: `*LocalDatasource` (SQLite) hoặc `*RemoteDatasource` (API)
- Feature folders phải FLAT: `features/[name]/{data,domain,presentation,providers}`

**❌ CẤM TUYỆT ĐỐI**:
- UI không query SQLite trực tiếp
- Presentation không import Data layer (bypass Repository)
- Feature không import feature khác trực tiếp (dùng callback/event/service)
- Không thêm mock/fake data vào production để che lỗi
- Không gọi Gemini/Supabase/network thật trong unit/widget test
- Không sửa `.env` thật, không hard-code API key
- Không dùng `dynamic`, `!`, nullable workaround không cần thiết
- Không nested feature folders (`features/meal_plan/dashboard/` → ❌)

### Architecture violations cần fix

Xem `docs/issues/bug_architecture.md` để biết 8 violations đang tồn tại:
1. 🔴 Cross-feature dependency (onboarding → dashboard)
2. 🟠 Nested feature structure (meal_plan/dashboard/)
3. 🟠 Model placement (MealPlanModel in core)
4. 🟠 Layer violation (presentation → datasource)
5. 🟡 Naming inconsistency (MealPlanDatasource)
6. 🟡 Presentation using core models

**Khi sửa code mới, KHÔNG lặp lại các violations này!**

## 4. Luồng nghiệp vụ lõi (Business Flow)

### Critical path: Onboarding → Schedule Generation → Dashboard

**Sau onboarding thành công** (callback trong `main.dart`):

1. **Lưu hồ sơ sức khỏe** → 8 tables SQLite:
   - `users`, `health_profiles`, `health_goals`, `health_conditions`
   - `lifestyle_habits`, `food_allergies`, `medical_treatments`, `survey_answers`

2. **Generate meal plan** (AI hoặc fallback):
   - Gemini AI tạo 21 meals (3 meals/day × 7 days)
   - Normalizer validate và map qua catalog → text tiếng Việt có dấu
   - Lưu vào `meal_plans` table

3. **Generate exercise tasks** (AI hoặc fallback):
   - Gemini AI tạo 7 days exercise
   - Normalizer validate và map qua catalog
   - Lưu vào `daily_health_tasks` table

4. **Build lifestyle schedule**:
   - Combine meals + exercises + hydration + sleep tasks
   - Timeline builder tạo schedule items
   - Lưu vào `lifestyle_schedule_items` table

5. **Schedule notifications**:
   - Reminder service đọc schedule items
   - Tạo local notifications với payload và actions
   - User có thể complete/skip từ notification

6. **Dashboard updates**:
   - Fetch data từ SQLite (KHÔNG DÙNG MOCK!)
   - Calculate health score, BMI, progress từ tracking logs
   - Display timeline, goals, insights

### Data flow validation

**✅ ĐÚNG**: Dashboard tính từ DB thật
```dart
final dashboardData = await repository.fetchDashboard(); // Query DB
final bmi = dashboardData.bmi; // Calculated from DB data
```

**❌ SAI**: Dashboard dùng mock data
```dart
final mockBmi = 22.5; // ← KHÔNG BAO GIỜ làm thế này!
```

## 5. Quy trình làm việc bắt buộc (DEV_WORKFLOW)

### Trước khi sửa (Discover phase):

1. **Xác định task thuộc module nào** (auth, onboarding, dashboard, meal_plan, etc.)
2. **Đọc `.codex/PROJECT_MAP.md`** → Biết vùng source cần xem
3. **Dùng `rg` tìm file liên quan** → Không mở tràn lan
   ```bash
   rg "ClassName|providerName" lib test
   rg "mock|fake|dummy" lib/features/dashboard
   ```
4. **Lập plan ngắn 3–5 ý** → Không quá chi tiết

### Khi sửa (Patch phase):

- **Sửa nhỏ nhất đủ đúng lỗi gốc** → Không refactor lan rộng
- **Không tạo code chết** → Xóa code không dùng, không comment bỏ
- **Type safety** → Ưu tiên type rõ ràng; tránh `dynamic`/`!`/`as`
- **Naming consistency**:
  - Datasource: `*LocalDatasource` hoặc `*RemoteDatasource`
  - Provider file: `*_provider.dart` trong `providers/` folder
  - Model: `*_model.dart` trong `data/models/`
  - Entity: `*_entity.dart` trong `domain/entities/`

### Khi đổi schema (SQLite):

**Bắt buộc cập nhật đủ 6 nơi**:
1. `database_version.dart` → Tăng version
2. `tables/*.dart` → Update CREATE TABLE statement
3. `models/*.dart` → Update model class
4. `daos/*.dart` → Update DAO queries
5. `migrations/migration_vX.dart` → Tạo migration mới
6. `database_service.dart` → Update onCreate nếu cần

### Khi đổi public API (Provider/Repository/Route):

1. **Search usage trước**: `rg "providerName|routeName" lib test`
2. **Update tất cả references**
3. **Run tests** để verify không break

### Sau khi sửa (Validate phase):

**Quick check** (luôn chạy):
```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

**Full check** (khi đổi Android/native/notification/build):
```bash
flutter doctor -v
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
```

### Definition of Done

Task chỉ hoàn thành khi:
- ✅ Code compile và analyze sạch
- ✅ Tests pass (hoặc có lý do rõ vì sao skip)
- ✅ Không làm hỏng luồng: onboarding → schedule → dashboard → notification
- ✅ Báo cáo cuối task đầy đủ (xem section 7)
- ✅ Text tiếng Việt có dấu (nếu user-facing)

## 6. Commands (Cross-platform)

### Windows (PowerShell)

**Quick check**:
```powershell
powershell -ExecutionPolicy Bypass -File .codex/tool/codex_quick_check.ps1
```

**Full check** (with format fix + APK build):
```powershell
powershell -ExecutionPolicy Bypass -File .codex/tool/codex_check.ps1 -FixFormat -BuildApk
```

### Git Bash / WSL / macOS / Linux

**Quick check**:
```bash
bash .codex/tool/codex_quick_check.sh
```

**Full check** (with format fix + APK build):
```bash
bash .codex/tool/codex_check.sh --fix-format --build-apk
```

### Manual commands (nếu script không chạy được)

```bash
# Quick check
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test

# Full check
flutter doctor -v
flutter pub get
dart format . --line-length 80
flutter analyze
flutter test
flutter build apk --debug
```

## 7. Report format (Task completion)

Cuối mỗi task **BẮT BUỘC** báo cáo theo format:

```markdown
## Task Summary

**Đã làm**:
- [Mô tả ngắn gọn những gì đã thực hiện]
- [Liệt kê các thay đổi chính]

**Files đã sửa/tạo**:
- `path/to/file1.dart` - [Mô tả thay đổi]
- `path/to/file2.dart` - [Mô tả thay đổi]

**Commands đã chạy**:
- `flutter pub get`: ✅ PASS / ❌ FAIL / ⊝ SKIPPED
- `dart format --set-exit-if-changed .`: ✅ PASS / ❌ FAIL / ⊝ SKIPPED
- `flutter analyze`: ✅ PASS / ❌ FAIL / ⊝ SKIPPED (X issues)
- `flutter test`: ✅ PASS / ❌ FAIL / ⊝ SKIPPED (X passed, Y failed)
- `flutter build apk --debug`: ✅ PASS / ❌ FAIL / ⊝ SKIPPED

**Rủi ro/Lưu ý**:
- [Nếu có breaking changes]
- [Nếu cần manual testing]
- [Nếu còn TODO items]

**Next steps** (nếu có):
- [Bước tiếp theo cần làm]
```

### Ví dụ report tốt:

```markdown
## Task Summary

**Đã làm**:
- Fix cross-feature dependency: onboarding → dashboard
- Implement callback pattern trong main.dart
- Remove direct import của dashboard_controller từ onboarding

**Files đã sửa/tạo**:
- `lib/main.dart` - Override onboardingCompletionCallbackProvider
- `lib/features/onboarding/providers/onboarding_completion_provider.dart` - Tạo callback provider
- `lib/features/onboarding/presentation/controllers/onboarding_controller.dart` - Dùng callback thay vì gọi trực tiếp

**Commands đã chạy**:
- `flutter pub get`: ✅ PASS
- `dart format --set-exit-if-changed .`: ✅ PASS
- `flutter analyze`: ✅ PASS (0 issues)
- `flutter test`: ✅ PASS (145 passed, 0 failed)
- `flutter build apk --debug`: ⊝ SKIPPED (không cần build APK)

**Rủi ro/Lưu ý**:
- Cần test manual onboarding flow end-to-end
- Callback phải được wire đúng trong main.dart

**Next steps**:
- Fix Bug #3: Flatten meal_plan folder structure
```
