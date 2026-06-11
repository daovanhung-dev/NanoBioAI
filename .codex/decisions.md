# Decisions

## D1 — SQLite làm primary storage, không dùng Supabase database
**Quyết định**: Toàn bộ health data lưu local SQLite. Supabase chỉ dùng cho auth.  
**Bằng chứng**: `DatabaseService` + 14 tables trong local DB. Không có Supabase database queries ngoài auth.  
**Lý do suy ra [INFERRED]**: Offline-first để app hoạt động không cần internet. Data nhạy cảm giữ on-device.

---

## D2 — Feature-first + Clean Architecture
**Quyết định**: Mỗi feature tự chứa data/domain/presentation/providers.  
**Bằng chứng**: Cấu trúc thư mục `features/onboarding/`, `features/auth/`, `features/dashboard/` đều theo pattern này.  
**Lý do suy ra [INFERRED]**: Tăng khả năng mở rộng độc lập từng feature, dễ teamwork.

---

## D3 — Riverpod gen3 Notifier (không dùng StateNotifier legacy)
**Quyết định**: Dùng `Notifier` / `AsyncNotifier` + `NotifierProvider` / `AsyncNotifierProvider`.  
**Bằng chứng**: `OnboardingController extends Notifier<OnboardingState>`, `DashboardController extends AsyncNotifier<void>`, `MealPlanController extends AsyncNotifier<List<MealPlanModel>>`.  
**Ngoại lệ**: `LoginController extends StateNotifier` — auth chưa migrate lên gen3.

---

## D4 — AI meal plan sinh tự động sau onboarding
**Quyết định**: Trigger `genMealByWeeksToDB()` ngay sau `saveOnboarding()` thành công.  
**Bằng chứng**: `OnboardingController.saveOnboarding()` gọi `ref.read(dashboardControllerProvider.notifier).genMealByWeeksToDB()`.  
**Lý do suy ra [INFERRED]**: UX seamless — người dùng có meal plan ngay khi vào app lần đầu.

---

## D5 — Gemini 2.5 Flash (không dùng GPT/Claude)
**Quyết định**: Dùng Google Gemini API via official SDK.  
**Bằng chứng**: `google_generative_ai` package, `GEMINI_MODEL=gemini-2.5-flash` trong `.env`.  
**Lý do suy ra [INFERRED]**: Chi phí thấp hơn GPT-4, có free tier, SDK chính thức của Google.

---

## D6 — GoRouter cho navigation
**Quyết định**: Dùng GoRouter thay vì Navigator 2.0 thuần.  
**Bằng chứng**: `go_router ^17.2.3` trong pubspec, `appRouter = GoRouter(...)`.  
**Lý do suy ra [INFERRED]**: Declarative routing, dễ thêm guard, URL-based navigation cho web compatibility.

---

## D7 — TEXT PRIMARY KEY (không dùng INTEGER AUTOINCREMENT)
**Quyết định**: PK dạng TEXT, generate bằng timestamp milliseconds.  
**Bằng chứng**: `UsersTable`, `HealthProfilesTable` đều dùng `id TEXT PRIMARY KEY`. Code: `final generatedId = DateTime.now().millisecondsSinceEpoch.toString()`.  
**Lý do suy ra [INFERRED]**: Hỗ trợ sync với remote UUID trong tương lai, tránh conflict khi merge data.

---

## D8 — PRAGMA foreign_keys = OFF
**Quyết định**: Disable SQLite foreign key constraint.  
**Bằng chứng**: `database_service.dart` set `PRAGMA foreign_keys = OFF` ở cả `onConfigure` và `onOpen`.  
**Lý do suy ra [INFERRED]**: Đơn giản hóa data management khi delete/re-insert (onboarding upsert flow xóa và insert lại toàn bộ).

---

## D9 — Dashboard component chưa tách widget
**Quyết định**: Chưa refactor dashboard ra nhiều widget files.  
**Bằng chứng**: `docs/issues/ui_issues_dashboard.md` ghi nhận vấn đề, status = Pending.  
**Ghi chú**: Planned structure đã được document, chưa implement vì ưu tiên feature flow trước.
