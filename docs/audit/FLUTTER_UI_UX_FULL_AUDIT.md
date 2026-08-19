# FLUTTER UI/UX FULL AUDIT — NanoBio / NamiAI

**Audit baseline:** `30587ab9b04d95aa621e5412502aafd0d0ca4827`  
**Repository:** `daovanhung-dev/NanoBioAI` (`main`)  
**Audit date:** 2026-08-19 (Asia/Bangkok / UTC+7)  
**Mode:** find-issues / audit only — **no runtime code modified**

## Executive result

- Logical UI surfaces reviewed/reconciled: **81** (80 repository registry surfaces + 1 runtime-discovered Settings tab).
- Route coverage: **100% of registered V1/V2/V3/Admin route entries at the baseline were reconciled against target widgets**.
- Shared/transient UI coverage: onboarding shell/components, replacement sheets, proof gallery/viewer, Nabi overlay/animation, Sale internal tabs/panels, Admin gate/shell/dialogs were included in cross-screen review.
- Issues recorded: **36** — Critical 0, High 9, Medium 22, Low 5.
- Potential/hidden issues explicitly labeled: **18**.
- No CRITICAL issue was proven from static source evidence at this baseline. This does **not** mean runtime/device QA is unnecessary.

### Audit evidence limitation
The execution environment could not clone GitHub (`github.com` DNS resolution unavailable) and the GitHub connector did not expose a downloadable repository archive/code-search index. The audit therefore used authenticated GitHub file/directory reads, route trees, design surface matrix, provider/controller source and cross-file evidence. No emulator, golden screenshot, Flutter analyze/test/build, keyboard injection or real device interaction is claimed. Findings requiring runtime confirmation are explicitly marked **Potential Issue** and lower confidence where appropriate.

## Project / architecture context

- Dart SDK: `^3.9.2`; Flutter project package `nano_app`.
- State: Riverpod `3.3.1`. Navigation: GoRouter `17.2.3` plus limited direct Navigator/MaterialPageRoute sub-surfaces.
- Architecture target: `Presentation → Provider/Controller → Repository → Datasource → DAO/API`.
- Local data: SQLite/sqflite; trusted cloud/access/payment/Sale/Admin state: Supabase/RPC.
- Runtime root: unified `BioAIApp` chooses user/admin surface after auth/access resolution.
- Current SQLite version at baseline: 20.
- Current release Nabi assets: V2 bundle; V1 retained source-only rollback.

# MASTER BUG TABLE

| ID | Module | Screen | Type | Severity | Priority | File | Summary | Status |
|---|---|---|---|---|---|---|---|---|
| BUG-UI-001 | Dashboard / Health | Quick Care | Interaction | HIGH | P1 | `lib/app_versions/v1/features/quick_care/presentation/pages/quick_care_page.dart` | Quick Care là route active nhưng không có hành động chăm sóc nào thực thi | TODO |
| BUG-UI-002 | Dashboard / Health | Weekly Summary | Data Consistency | HIGH | P1 | `lib/app_versions/v1/features/weekly_summary/presentation/pages/weekly_summary_page.dart` | Weekly Summary luôn hiển thị summary tĩnh, không đọc dữ liệu tuần thực tế | TODO |
| BUG-UI-003 | AI / Nutrition / Schedule | Today Tasks | State Management | HIGH | P1 | `lib/app_versions/v1/features/today_tasks/presentation/pages/today_tasks_page.dart` | Today Tasks không tự cập nhật trạng thái theo thời gian khi màn hình đang mở | TODO |
| BUG-UI-004 | Dashboard / Health | Body Metrics | Data Consistency | HIGH | P1 | `lib/app_versions/v1/features/body_metrics/providers/body_metrics_providers.dart` | Body Metrics có thể giữ dữ liệu cũ sau khi cập nhật Profile | TODO |
| BUG-UI-005 | Dashboard / Health | Gentle Care Mode | UX | HIGH | P1 | `lib/app_versions/v1/features/gentle_care_mode/presentation/pages/gentle_care_mode_page.dart` | Gentle Care nói sẽ “hạ mục tiêu” nhưng chỉ đổi state cục bộ và gợi ý tĩnh | TODO |
| BUG-UI-006 | Sale | Sale Participation | State Management | HIGH | P1 | `lib/sale_referral/presentation/pages/sale_participation_page.dart` | Sale Participation biến lỗi tải trạng thái thành trạng thái “chưa tham gia” hợp lệ | TODO |
| BUG-UI-007 | V2/V3 Access | Auth Gate | Potential Issue | HIGH | P1 | `lib/app_versions/v2/features/auth/presentation/pages/auth_gate_page.dart` | Auth Gate cho phép spam hành động merge/use-cloud khi đồng bộ đang chạy | TODO |
| BUG-UI-008 | V2/V3 Access | V2 Login / Register | Potential Issue | HIGH | P1 | `lib/app_versions/v2/features/auth/presentation/pages/auth_pages.dart` | V2 Login/Register có đường double-submit từ bàn phím | TODO |
| BUG-UI-009 | V2/V3 Access | FamilyPlus | Potential Issue | HIGH | P1 | `lib/app_versions/v3/features/familyplus/presentation/pages/familyplus_page.dart` | FamilyPlus tạo nhóm mặc định có thể phát nhiều command độc lập khi double-tap | TODO |
| BUG-UI-010 | V2/V3 Access | Advanced Tracking | Potential Issue | MEDIUM | P1 | `lib/app_versions/v3/features/advanced_tracking/presentation/pages/advanced_tracking_page.dart` | Advanced Tracking create-goal thiếu single-flight guard ở empty state | TODO |
| BUG-UI-011 | Profile / Settings | Settings tab | UX | MEDIUM | P1 | `lib/app_versions/v1/features/settings/presentation/pages/settings_page.dart` | Settings luôn phát feedback thành công dù một hoặc nhiều refresh thất bại | TODO |
| BUG-UI-012 | AI / Nutrition / Schedule | AI Chat | Accessibility | MEDIUM | P1 | `lib/app_versions/v1/features/ai_chat/presentation/pages/ai_chat_screen.dart` | AI Chat ép system bars dùng dark icons ngay cả trong dark theme | TODO |
| BUG-UI-024 | Admin | Admin Workspace Dialogs | Potential Issue | MEDIUM | P1 | `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_dialogs.dart` | Admin action confirmation dialog có thể overflow khi keyboard + large text | TODO |
| BUG-UI-025 | Admin | Admin Workspace | Code Quality | MEDIUM | P1 | `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_page.dart` | Admin presentation layer upload trực tiếp Supabase Storage | TODO |
| BUG-UI-013 | AI / Nutrition / Schedule | AI Chat | UX | MEDIUM | P2 | `lib/app_versions/v1/features/ai_chat/presentation/pages/ai_chat_screen.dart` | AI Chat tự cuộn xuống cuối ngay cả khi người dùng đang đọc lịch sử | TODO |
| BUG-UI-014 | AI / Nutrition / Schedule | Meal Plan | Navigation | MEDIUM | P2 | `lib/app_versions/v1/features/meal_plan/presentation/pages/meal_plan_page.dart` | Meal Plan thiếu nút Back hiển thị trong page chrome | TODO |
| BUG-UI-015 | AI / Nutrition / Schedule | Meal Plan / Today Tasks | Code Quality | MEDIUM | P2 | `lib/app_versions/v1/features/meal_plan/presentation/pages/meal_plan_page.dart` | Có hai implementation Meal Replacement sheet song song | TODO |
| BUG-UI-016 | AI / Nutrition / Schedule | Daily Health Tracking Alias | UX | MEDIUM | P2 | `lib/app_versions/v1/features/daily_health_tracking/presentation/pages/daily_health_tracking_page.dart` | Route Daily Health Tracking chỉ là alias nguyên màn Lifestyle Schedule | TODO |
| BUG-UI-017 | Cross-cutting UI | Body Metrics / Personal Goals / Water / Sale | Design System | MEDIUM | P2 | `lib/app_versions/v1/features/body_metrics/presentation/pages/body_metrics_page.dart` | Consumer UI hiển thị thuật ngữ kỹ thuật/nội bộ | TODO |
| BUG-UI-018 | AI / Nutrition / Schedule | Schedule Proof Gallery | Performance | MEDIUM | P2 | `lib/app_versions/v1/features/lifestyle_schedule/presentation/pages/schedule_proof_gallery_page.dart` | Proof Gallery tạo file-system Future trực tiếp trong build | TODO |
| BUG-UI-019 | AI / Nutrition / Schedule | Schedule Proof Gallery | Potential Issue | MEDIUM | P2 | `lib/app_versions/v1/features/lifestyle_schedule/presentation/pages/schedule_proof_gallery_page.dart` | Thumbnail proof có thể decode ảnh camera full-resolution | TODO |
| BUG-UI-020 | Dashboard / Health | Features Hub | Potential Issue | MEDIUM | P2 | `lib/app_versions/v1/features/features_hub/presentation/pages/features_hub_page.dart` | Features Hub giữ 3 cột cả ở màn 320px, nguy cơ truncate label khi text scale lớn | TODO |
| BUG-UI-021 | AI / Nutrition / Schedule | Nutrition | Potential Issue | MEDIUM | P2 | `lib/app_versions/v1/features/nutrition/presentation/pages/nutrition_page.dart` | Nutrition summary grid có nguy cơ overflow/truncate ở large text | TODO |
| BUG-UI-022 | AI / Nutrition / Schedule | Meal Plan | Potential Issue | MEDIUM | P2 | `lib/app_versions/v1/features/meal_plan/presentation/pages/meal_plan_page.dart` | Meal Plan date selector dùng kích thước tile cố định, rủi ro large-text | TODO |
| BUG-UI-023 | Foundation / Shell | Main Navigation | Potential Issue | MEDIUM | P2 | `lib/app_versions/v1/features/dashboard/presentation/pages/menu_page.dart` | Features Hub và Settings dùng cùng Nabi route context `/menu` | TODO |
| BUG-UI-026 | V2/V3 Access | Health Module Access | Potential Issue | MEDIUM | P2 | `lib/app_versions/v2/features/health_modules/presentation/pages/health_module_access_page.dart` | Health Module Access dùng pushReplacement khi forward, có nguy cơ mất return-to-feature | TODO |
| BUG-UI-027 | V2/V3 Access | Health Score | Potential Issue | MEDIUM | P2 | `lib/app_versions/v2/features/health_scoring/presentation/pages/health_score_habits_page.dart` | Health Score pull-to-refresh không có failure feedback giữ-nguyên-content rõ ràng | TODO |
| BUG-UI-028 | Dashboard / Health | Dashboard | Potential Issue | MEDIUM | P2 | `lib/app_versions/v1/features/dashboard/presentation/pages/dashboard_page.dart` | Dashboard periodic refresh có thể tiếp tục khi tab không hiển thị | TODO |
| BUG-UI-029 | Onboarding / Auth | Onboarding Result Step | Potential Issue | MEDIUM | P2 | `lib/app_versions/v1/features/onboarding/presentation/widgets/result_step.dart` | ResultStep source-only có default health score 82 có thể tạo dữ liệu giả nếu được wire nhầm | TODO |
| BUG-UI-030 | Onboarding / Auth | Splash | Potential Issue | MEDIUM | P2 | `lib/app_versions/v1/features/splash/presentation/pages/splash_page.dart` | Splash nuốt lỗi bootstrap và vẫn tiếp tục route decision | TODO |
| BUG-UI-031 | Foundation / Shell | Settings tab | Code Quality | MEDIUM | P2 | `.codex/design/12_UI_FILE_DESIGN_MATRIX.md` | Design surface registry bỏ sót Settings tab đang hoạt động | TODO |
| BUG-UI-032 | Cross-cutting UI | Onboarding / Features Hub / Nami Care / AI Voice | Design System | LOW | P2 | `multiple presentation files` | Tên mascot không nhất quán: Nabi / NaBi / Nami Care | TODO |
| BUG-UI-033 | Admin | Admin Workspace Shell | Accessibility | LOW | P2 | `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_shell.dart` | Admin sidebar utility touch targets chỉ 42–44dp | TODO |
| BUG-UI-034 | V2/V3 Access | V3 routing | Code Quality | LOW | P3 | `lib/app_versions/v3/router/v3_router.dart` | V3 standalone router lặp lại route V1/V2 ngoài unified router | TODO |
| BUG-UI-035 | Onboarding / Auth | Onboarding Journey Shell | Performance | LOW | P3 | `lib/app_versions/v1/features/onboarding/presentation/pages/onboarding_page.dart` | Onboarding ghi log trong build path | TODO |
| BUG-UI-036 | AI / Nutrition / Schedule | AI Voice | Potential Issue | LOW | P3 | `lib/app_versions/v1/features/ai_voice/presentation/pages/ai_voice_page.dart` | AI Voice dùng `context.go` khi chuyển sang AI Chat, có thể thay stack thay vì quay lại được | TODO |

# Module: Foundation / Shell
Screens scanned: 1
Files/surface roots scanned: 1
Issues: 2
Critical: 0
High: 0
Medium: 2
Low: 0
Top problems:
1. BUG-UI-023 — Features Hub và Settings dùng cùng Nabi route context `/menu`
2. BUG-UI-031 — Design surface registry bỏ sót Settings tab đang hoạt động
Technical debt:
1. Tab-context và surface registry cần dùng stable view IDs thay vì route alias chung.

# Module: Onboarding / Auth
Screens scanned: 16
Files/surface roots scanned: 15
Issues: 3
Critical: 0
High: 0
Medium: 2
Low: 1
Top problems:
1. BUG-UI-029 — ResultStep source-only có default health score 82 có thể tạo dữ liệu giả nếu được wire nhầm
2. BUG-UI-030 — Splash nuốt lỗi bootstrap và vẫn tiếp tục route decision
3. BUG-UI-035 — Onboarding ghi log trong build path
Technical debt:
1. Canonicalize Nabi naming và tách event logging khỏi build.

# Module: Dashboard / Health
Screens scanned: 14
Files/surface roots scanned: 14
Issues: 6
Critical: 0
High: 4
Medium: 2
Low: 0
Top problems:
1. BUG-UI-001 — Quick Care là route active nhưng không có hành động chăm sóc nào thực thi
2. BUG-UI-002 — Weekly Summary luôn hiển thị summary tĩnh, không đọc dữ liệu tuần thực tế
3. BUG-UI-004 — Body Metrics có thể giữ dữ liệu cũ sau khi cập nhật Profile
Technical debt:
1. Một số feature active vẫn ở mức preview/static; cần contract state/data rõ.

# Module: AI / Nutrition / Schedule
Screens scanned: 8
Files/surface roots scanned: 8
Issues: 11
Critical: 0
High: 1
Medium: 9
Low: 1
Top problems:
1. BUG-UI-003 — Today Tasks không tự cập nhật trạng thái theo thời gian khi màn hình đang mở
2. BUG-UI-012 — AI Chat ép system bars dùng dark icons ngay cả trong dark theme
3. BUG-UI-013 — AI Chat tự cuộn xuống cuối ngay cả khi người dùng đang đọc lịch sử
Technical debt:
1. Hợp nhất picker/route alias và chuẩn hóa async image/navigation patterns.

# Module: Profile / Settings
Screens scanned: 4
Files/surface roots scanned: 4
Issues: 1
Critical: 0
High: 0
Medium: 1
Low: 0
Top problems:
1. BUG-UI-011 — Settings luôn phát feedback thành công dù một hoặc nhiều refresh thất bại
Technical debt:
1. Cần cross-feature invalidation registry/test thay vì list thủ công dễ sót.

# Module: V2/V3 Access
Screens scanned: 15
Files/surface roots scanned: 10
Issues: 7
Critical: 0
High: 3
Medium: 3
Low: 1
Top problems:
1. BUG-UI-007 — Auth Gate cho phép spam hành động merge/use-cloud khi đồng bộ đang chạy
2. BUG-UI-008 — V2 Login/Register có đường double-submit từ bàn phím
3. BUG-UI-009 — FamilyPlus tạo nhóm mặc định có thể phát nhiều command độc lập khi double-tap
Technical debt:
1. Mutation CTA cần single-flight/idempotency ở presentation boundary.

# Module: Sale
Screens scanned: 8
Files/surface roots scanned: 2
Issues: 1
Critical: 0
High: 1
Medium: 0
Low: 0
Top problems:
1. BUG-UI-006 — Sale Participation biến lỗi tải trạng thái thành trạng thái “chưa tham gia” hợp lệ
Technical debt:
1. Không được biến trusted-state failure thành business fallback hợp lệ.

# Module: Admin
Screens scanned: 15
Files/surface roots scanned: 5
Issues: 3
Critical: 0
High: 0
Medium: 2
Low: 1
Top problems:
1. BUG-UI-024 — Admin action confirmation dialog có thể overflow khi keyboard + large text
2. BUG-UI-025 — Admin presentation layer upload trực tiếp Supabase Storage
3. BUG-UI-033 — Admin sidebar utility touch targets chỉ 42–44dp
Technical debt:
1. Giữ API/storage mutation ngoài presentation; compact-dialog QA cần bổ sung.

# Module: Cross-cutting UI
Screens scanned: 0
Files/surface roots scanned: 0
Issues: 2
Critical: 0
High: 0
Medium: 1
Low: 1
Top problems:
1. BUG-UI-017 — Consumer UI hiển thị thuật ngữ kỹ thuật/nội bộ
2. BUG-UI-032 — Tên mascot không nhất quán: Nabi / NaBi / Nami Care
Technical debt:
1. Centralize copy glossary và brand naming.

# SCREEN-BY-SCREEN AUDIT

## Screen: Splash
Route: `/`
File: `lib/app_versions/v1/features/splash/presentation/pages/splash_page.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 6/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 1
Low: 0
Related: BUG-UI-030
### Overall
Needs Improvement

## Screen: Đăng nhập V1 Entry
Route: `/login`
File: `lib/app_versions/v1/features/auth/presentation/pages/v1_auth_entry_page.dart`
### Audit score
UI: 8/10
UX: 7/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 2/10
Accessibility: 8/10
Performance: 7/10
### Issues
Critical: 0
High: 1
Medium: 1
Low: 1
Related: BUG-UI-007, BUG-UI-026, BUG-UI-034
### Overall
Poor

## Screen: Đăng ký V1 Entry
Route: `/register`
File: `lib/app_versions/v1/features/auth/presentation/pages/v1_auth_entry_page.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 8/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 0
Low: 0
### Overall
Pass

## Screen: Dashboard Hôm nay
Route: `/dashboard`
File: `lib/app_versions/v1/features/dashboard/presentation/pages/dashboard_page.dart`
### Audit score
UI: 8/10
UX: 5/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 2/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 3
Medium: 1
Low: 0
Related: BUG-UI-002, BUG-UI-003, BUG-UI-004, BUG-UI-028
### Overall
Poor

## Screen: Onboarding Entry
Route: `/start`
File: `lib/app_versions/v1/features/onboarding/presentation/pages/onboarding_entry_page.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 6/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 1
Low: 0
Related: BUG-UI-030
### Overall
Needs Improvement

## Screen: Onboarding Journey Shell
Route: `/onboarding`
File: `lib/app_versions/v1/features/onboarding/presentation/pages/onboarding_page.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 8/10
Accessibility: 8/10
Performance: 7/10
### Issues
Critical: 0
High: 0
Medium: 0
Low: 1
Related: BUG-UI-035
### Overall
Needs Improvement

## Screen: Main Navigation
Route: `/menu`
File: `lib/app_versions/v1/features/dashboard/presentation/pages/menu_page.dart`
### Audit score
UI: 8/10
UX: 6/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 2/10
Accessibility: 6/10
Performance: 6/10
### Issues
Critical: 0
High: 0
Medium: 6
Low: 0
Related: BUG-UI-011, BUG-UI-012, BUG-UI-020, BUG-UI-023, BUG-UI-028, BUG-UI-031
### Overall
Poor

## Screen: Meal Plan
Route: `/meal-plan`
File: `lib/app_versions/v1/features/meal_plan/presentation/pages/meal_plan_page.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 6/10
State: 6/10
Accessibility: 8/10
Performance: 6/10
### Issues
Critical: 0
High: 0
Medium: 3
Low: 0
Related: BUG-UI-014, BUG-UI-015, BUG-UI-022
### Overall
Needs Improvement

## Screen: Daily Health Tracking Alias
Route: `/health-tracking`
File: `lib/app_versions/v1/features/daily_health_tracking/presentation/pages/daily_health_tracking_page.dart`
### Audit score
UI: 8/10
UX: 6/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 8/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 1
Low: 0
Related: BUG-UI-016
### Overall
Needs Improvement

## Screen: Body Metrics
Route: `/body-metrics`
File: `lib/app_versions/v1/features/body_metrics/presentation/pages/body_metrics_page.dart`
### Audit score
UI: 6/10
UX: 5/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 4/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 1
Medium: 2
Low: 0
Related: BUG-UI-004, BUG-UI-011, BUG-UI-017
### Overall
Poor

## Screen: Lifestyle Schedule
Route: `/lifestyle-schedule`
File: `lib/app_versions/v1/features/lifestyle_schedule/presentation/pages/lifestyle_schedule_page.dart`
### Audit score
UI: 8/10
UX: 2/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 2/10
Accessibility: 8/10
Performance: 6/10
### Issues
Critical: 0
High: 3
Medium: 3
Low: 0
Related: BUG-UI-002, BUG-UI-003, BUG-UI-005, BUG-UI-016, BUG-UI-018, BUG-UI-019
### Overall
Poor

## Screen: Daily Routine Preferences
Route: `/daily-routine-preferences`
File: `lib/app_versions/v1/features/daily_routine/presentation/pages/daily_routine_preferences_page.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 8/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 0
Low: 0
### Overall
Pass

## Screen: Sleep Tracking Preview
Route: `/sleep-tracking`
File: `lib/app_versions/v1/features/sleep_tracking/presentation/pages/sleep_tracking_page.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 8/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 0
Low: 0
### Overall
Pass

## Screen: Stress Tracking Preview
Route: `/stress-tracking`
File: `lib/app_versions/v1/features/stress_tracking/presentation/pages/stress_tracking_page.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 8/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 0
Low: 0
### Overall
Pass

## Screen: AI Chat
Route: `/ai-chat`
File: `lib/app_versions/v1/features/ai_chat/presentation/pages/ai_chat_screen.dart`
### Audit score
UI: 8/10
UX: 6/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 7/10
Accessibility: 6/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 2
Low: 1
Related: BUG-UI-012, BUG-UI-013, BUG-UI-036
### Overall
Needs Improvement

## Screen: AI Voice
Route: `/ai-voice`
File: `lib/app_versions/v1/features/ai_voice/presentation/pages/ai_voice_page.dart`
### Audit score
UI: 8/10
UX: 6/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 7/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 1
Low: 1
Related: BUG-UI-013, BUG-UI-036
### Overall
Needs Improvement

## Screen: Nutrition
Route: `/nutrition`
File: `lib/app_versions/v1/features/nutrition/presentation/pages/nutrition_page.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 4/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 2
Low: 0
Related: BUG-UI-021, BUG-UI-022
### Overall
Poor

## Screen: Nutrition Profile Editor
Route: `/nutrition-profile`
File: `lib/app_versions/v1/features/nutrition/presentation/pages/nutrition_profile_editor_page.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 6/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 1
Low: 0
Related: BUG-UI-021
### Overall
Needs Improvement

## Screen: Profile
Route: `/profile`
File: `lib/app_versions/v1/features/profile/presentation/pages/profile_page.dart`
### Audit score
UI: 8/10
UX: 5/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 4/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 1
Medium: 1
Low: 0
Related: BUG-UI-004, BUG-UI-011
### Overall
Poor

## Screen: Community Preview
Route: `/community`
File: `lib/app_versions/v1/features/community/presentation/pages/community_page.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 8/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 0
Low: 0
### Overall
Pass

## Screen: Today Tasks
Route: `/today-tasks`
File: `lib/app_versions/v1/features/today_tasks/presentation/pages/today_tasks_page.dart`
### Audit score
UI: 8/10
UX: 3/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 2/10
Accessibility: 8/10
Performance: 6/10
### Issues
Critical: 0
High: 3
Medium: 1
Low: 0
Related: BUG-UI-002, BUG-UI-003, BUG-UI-005, BUG-UI-015
### Overall
Poor

## Screen: Text Scale Setup
Route: `/onboarding (gate)`
File: `lib/app_versions/v1/features/onboarding/presentation/pages/onboarding_text_scale_page.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 8/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 0
Low: 0
### Overall
Pass

## Screen: Welcome Step
Route: `/onboarding step 0`
File: `lib/app_versions/v1/features/onboarding/presentation/widgets/welcome_step.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 8/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 0
Low: 0
### Overall
Pass

## Screen: Basic Info Step
Route: `/onboarding step 1`
File: `lib/app_versions/v1/features/onboarding/presentation/widgets/basic_info_step.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 8/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 0
Low: 0
### Overall
Pass

## Screen: Goals Step
Route: `/onboarding step 2`
File: `lib/app_versions/v1/features/onboarding/presentation/widgets/goals_step.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 8/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 0
Low: 0
### Overall
Pass

## Screen: Conditions Step
Route: `/onboarding step 3`
File: `lib/app_versions/v1/features/onboarding/presentation/widgets/conditions_step.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 8/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 0
Low: 0
### Overall
Pass

## Screen: Lifestyle Step
Route: `/onboarding step 4`
File: `lib/app_versions/v1/features/onboarding/presentation/widgets/lifestyle_step.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 8/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 0
Low: 0
### Overall
Pass

## Screen: Extras Step
Route: `/onboarding step 5`
File: `lib/app_versions/v1/features/onboarding/presentation/widgets/extras_step.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 8/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 0
Low: 0
### Overall
Pass

## Screen: Daily Routine Step
Route: `/onboarding step 6`
File: `lib/app_versions/v1/features/onboarding/presentation/widgets/daily_routine_step.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 8/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 0
Low: 0
### Overall
Pass

## Screen: Consent Step
Route: `/onboarding step 7`
File: `lib/app_versions/v1/features/onboarding/presentation/widgets/consent_step.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 8/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 0
Low: 0
### Overall
Pass

## Screen: Review Step
Route: `/onboarding step 8`
File: `lib/app_versions/v1/features/onboarding/presentation/widgets/review_step.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 8/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 0
Low: 0
### Overall
Pass

## Screen: Result Step
Route: `source-only`
File: `lib/app_versions/v1/features/onboarding/presentation/widgets/result_step.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 8/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 0
Low: 0
### Overall
Pass

## Screen: Features Hub
Route: `/menu (tab)`
File: `lib/app_versions/v1/features/features_hub/presentation/pages/features_hub_page.dart`
### Audit score
UI: 7/10
UX: 7/10
Responsive: 8/10
Interaction: 4/10
Navigation: 6/10
State: 4/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 1
Medium: 3
Low: 1
Related: BUG-UI-001, BUG-UI-014, BUG-UI-020, BUG-UI-023, BUG-UI-032
### Overall
Poor

## Screen: Health Insights / Góc Nabi
Route: `/menu (tab)`
File: `lib/app_versions/v1/features/other/presentation/pages/other_page.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 8/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 0
Low: 0
### Overall
Pass

## Screen: Schedule Proof Gallery
Route: `Navigator sub-surface`
File: `lib/app_versions/v1/features/lifestyle_schedule/presentation/pages/schedule_proof_gallery_page.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 6/10
Accessibility: 8/10
Performance: 6/10
### Issues
Critical: 0
High: 0
Medium: 2
Low: 0
Related: BUG-UI-018, BUG-UI-019
### Overall
Needs Improvement

## Screen: Dev Database Viewer
Route: `source-only`
File: `lib/app_versions/v1/features/settings/presentation/pages/dev_database_viewer_page.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 8/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 0
Low: 0
### Overall
Pass

## Screen: Water Tracking
Route: `/water-tracking`
File: `lib/app_versions/v1/features/water_tracking/presentation/pages/water_tracking_page.dart`
### Audit score
UI: 6/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 8/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 1
Low: 0
Related: BUG-UI-017
### Overall
Needs Improvement

## Screen: Weekly Summary
Route: `/weekly-summary`
File: `lib/app_versions/v1/features/weekly_summary/presentation/pages/weekly_summary_page.dart`
### Audit score
UI: 8/10
UX: 7/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 4/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 1
Medium: 0
Low: 0
Related: BUG-UI-002
### Overall
Poor

## Screen: Quick Care
Route: `/quick-care`
File: `lib/app_versions/v1/features/quick_care/presentation/pages/quick_care_page.dart`
### Audit score
UI: 8/10
UX: 7/10
Responsive: 8/10
Interaction: 4/10
Navigation: 8/10
State: 8/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 1
Medium: 0
Low: 0
Related: BUG-UI-001
### Overall
Poor

## Screen: Gentle Care Mode
Route: `/gentle-care`
File: `lib/app_versions/v1/features/gentle_care_mode/presentation/pages/gentle_care_mode_page.dart`
### Audit score
UI: 8/10
UX: 3/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 8/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 1
Medium: 0
Low: 0
Related: BUG-UI-005
### Overall
Poor

## Screen: Personal Goals
Route: `/personal-goals`
File: `lib/app_versions/v1/features/personal_goals/presentation/pages/personal_goals_page.dart`
### Audit score
UI: 6/10
UX: 3/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 8/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 1
Medium: 1
Low: 0
Related: BUG-UI-005, BUG-UI-017
### Overall
Poor

## Screen: Nami Care Page
Route: `/nami-care`
File: `lib/app_versions/v1/features/features_hub/presentation/widgets/nami_care_page.dart`
### Audit score
UI: 7/10
UX: 7/10
Responsive: 8/10
Interaction: 4/10
Navigation: 6/10
State: 4/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 1
Medium: 3
Low: 1
Related: BUG-UI-001, BUG-UI-014, BUG-UI-020, BUG-UI-023, BUG-UI-032
### Overall
Poor

## Screen: Settings tab
Route: `/menu (tab Của bạn)`
File: `lib/app_versions/v1/features/settings/presentation/pages/settings_page.dart`
### Audit score
UI: 8/10
UX: 6/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 6/10
Accessibility: 8/10
Performance: 6/10
### Issues
Critical: 0
High: 0
Medium: 3
Low: 0
Related: BUG-UI-011, BUG-UI-023, BUG-UI-031
### Overall
Needs Improvement

## Screen: Auth Gate
Route: `/auth-gate`
File: `lib/app_versions/v2/features/auth/presentation/pages/auth_gate_page.dart`
### Audit score
UI: 8/10
UX: 6/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 2/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 2
Medium: 1
Low: 0
Related: BUG-UI-007, BUG-UI-008, BUG-UI-030
### Overall
Poor

## Screen: Login
Route: `/auth/login`
File: `lib/app_versions/v2/features/auth/presentation/pages/auth_pages.dart`
### Audit score
UI: 8/10
UX: 6/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 2/10
Accessibility: 8/10
Performance: 7/10
### Issues
Critical: 0
High: 2
Medium: 1
Low: 1
Related: BUG-UI-007, BUG-UI-008, BUG-UI-026, BUG-UI-034
### Overall
Poor

## Screen: Register
Route: `/auth/register`
File: `lib/app_versions/v2/features/auth/presentation/pages/auth_pages.dart`
### Audit score
UI: 8/10
UX: 7/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 4/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 1
Medium: 0
Low: 0
Related: BUG-UI-008
### Overall
Poor

## Screen: Verify Email
Route: `/auth/verify-email`
File: `lib/app_versions/v2/features/auth/presentation/pages/auth_pages.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 8/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 0
Low: 0
### Overall
Pass

## Screen: Forgot Password
Route: `/auth/forgot-password`
File: `lib/app_versions/v2/features/auth/presentation/pages/auth_pages.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 8/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 0
Low: 0
### Overall
Pass

## Screen: Reset Password
Route: `/auth/reset-password`
File: `lib/app_versions/v2/features/auth/presentation/pages/auth_pages.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 8/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 0
Low: 0
### Overall
Pass

## Screen: Auth Callback
Route: `/auth/callback`
File: `lib/app_versions/v2/features/auth/presentation/pages/auth_pages.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 8/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 0
Low: 0
### Overall
Pass

## Screen: Sale Shell
Route: `/v2/sale`
File: `lib/sale_referral/presentation/pages/sale_shell_page.dart`
### Audit score
UI: 6/10
UX: 7/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 4/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 1
Medium: 1
Low: 0
Related: BUG-UI-006, BUG-UI-017
### Overall
Poor

## Screen: Health Score
Route: `/v2/health-score`
File: `lib/app_versions/v2/features/health_scoring/presentation/pages/health_score_habits_page.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 6/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 1
Low: 0
Related: BUG-UI-027
### Overall
Needs Improvement

## Screen: Health Module Access
Route: `/v2/health-modules/:moduleId`
File: `lib/app_versions/v2/features/health_modules/presentation/pages/health_module_access_page.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 6/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 1
Low: 0
Related: BUG-UI-026
### Overall
Needs Improvement

## Screen: Membership Payment
Route: `/v2/payments`
File: `lib/app_versions/v2/features/payments/presentation/pages/membership_payment_page.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 6/10
Accessibility: 8/10
Performance: 7/10
### Issues
Critical: 0
High: 0
Medium: 1
Low: 1
Related: BUG-UI-026, BUG-UI-034
### Overall
Needs Improvement

## Screen: Wellness Rewards
Route: `/v2/wellness-rewards`
File: `lib/app_versions/v2/features/wellness_rewards/presentation/pages/wellness_rewards_page.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 8/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 0
Low: 0
### Overall
Pass

## Screen: V2 Home
Route: `/v2`
File: `lib/app_versions/v2/features/home/presentation/pages/v2_home_page.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 6/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 1
Low: 0
Related: BUG-UI-027
### Overall
Needs Improvement

## Screen: V3 Home
Route: `/v3`
File: `lib/app_versions/v3/features/home/presentation/pages/v3_home_page.dart`
### Audit score
UI: 8/10
UX: 7/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 2/10
Accessibility: 8/10
Performance: 7/10
### Issues
Critical: 0
High: 1
Medium: 1
Low: 1
Related: BUG-UI-009, BUG-UI-010, BUG-UI-034
### Overall
Poor

## Screen: Advanced Tracking
Route: `/v3/advanced-tracking`
File: `lib/app_versions/v3/features/advanced_tracking/presentation/pages/advanced_tracking_page.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 6/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 1
Low: 0
Related: BUG-UI-010
### Overall
Needs Improvement

## Screen: FamilyPlus
Route: `/v3/family-plus`
File: `lib/app_versions/v3/features/familyplus/presentation/pages/familyplus_page.dart`
### Audit score
UI: 8/10
UX: 7/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 4/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 1
Medium: 0
Low: 0
Related: BUG-UI-009
### Overall
Poor

## Screen: Sale Participation
Route: `/v2/sale sub-surface`
File: `lib/sale_referral/presentation/pages/sale_participation_page.dart`
### Audit score
UI: 8/10
UX: 7/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 4/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 1
Medium: 0
Low: 0
Related: BUG-UI-006
### Overall
Poor

## Screen: Payout Profile Gate
Route: `/v2/sale internal`
File: `lib/sale_referral/presentation/pages/sale_shell_page.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 8/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 0
Low: 0
### Overall
Pass

## Screen: Sale Overview
Route: `/v2/sale tab`
File: `lib/sale_referral/presentation/pages/sale_shell_page.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 8/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 0
Low: 0
### Overall
Pass

## Screen: Direct Customers
Route: `/v2/sale tab`
File: `lib/sale_referral/presentation/pages/sale_shell_page.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 8/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 0
Low: 0
### Overall
Pass

## Screen: Point Ledger
Route: `/v2/sale tab`
File: `lib/sale_referral/presentation/pages/sale_shell_page.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 8/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 0
Low: 0
### Overall
Pass

## Screen: Conversion Tools
Route: `/v2/sale tab`
File: `lib/sale_referral/presentation/pages/sale_shell_page.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 8/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 0
Low: 0
### Overall
Pass

## Screen: Referral Code Panel
Route: `/v2/sale internal`
File: `lib/sale_referral/presentation/pages/sale_shell_page.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 8/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 0
Low: 0
### Overall
Pass

## Screen: Admin Login
Route: `/admin/login`
File: `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_login_page.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 8/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 0
Low: 0
### Overall
Pass

## Screen: Admin Dashboard
Route: `/admin/dashboard`
File: `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_page.dart + admin_workspace_sections.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 8/10
Accessibility: 7/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 0
Low: 1
Related: BUG-UI-033
### Overall
Needs Improvement

## Screen: Admin Users
Route: `/admin/users`
File: `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_page.dart + admin_workspace_sections.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 8/10
Accessibility: 7/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 0
Low: 1
Related: BUG-UI-033
### Overall
Needs Improvement

## Screen: Admin Payments
Route: `/admin/payments`
File: `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_page.dart + admin_workspace_sections.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 6/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 1
Low: 0
Related: BUG-UI-024
### Overall
Needs Improvement

## Screen: Admin Sales
Route: `/admin/sales`
File: `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_page.dart + admin_workspace_sections.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 8/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 0
Low: 0
### Overall
Pass

## Screen: Admin Sale Conversions
Route: `/admin/sale-conversions`
File: `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_page.dart + admin_workspace_sections.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 6/10
Accessibility: 8/10
Performance: 6/10
### Issues
Critical: 0
High: 0
Medium: 2
Low: 0
Related: BUG-UI-024, BUG-UI-025
### Overall
Needs Improvement

## Screen: Admin Wellness Rewards
Route: `/admin/wellness-rewards`
File: `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_page.dart + admin_workspace_sections.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 8/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 0
Low: 0
### Overall
Pass

## Screen: Admin Reconciliation
Route: `/admin/reconciliation`
File: `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_page.dart + admin_workspace_sections.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 8/10
Accessibility: 8/10
Performance: 6/10
### Issues
Critical: 0
High: 0
Medium: 1
Low: 0
Related: BUG-UI-025
### Overall
Needs Improvement

## Screen: Admin Plans
Route: `/admin/plans`
File: `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_page.dart + admin_workspace_sections.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 8/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 0
Low: 0
### Overall
Pass

## Screen: Admin Reports
Route: `/admin/reports`
File: `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_page.dart + admin_workspace_sections.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 8/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 0
Low: 0
### Overall
Pass

## Screen: Admin Audit
Route: `/admin/audit`
File: `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_page.dart + admin_workspace_sections.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 8/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 0
Low: 0
### Overall
Pass

## Screen: Admin Config
Route: `/admin/config`
File: `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_page.dart + admin_workspace_sections.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 8/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 0
Low: 0
### Overall
Pass

## Screen: Admin Workspace Shell
Route: `/admin/*`
File: `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_shell.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 8/10
Accessibility: 7/10
Performance: 6/10
### Issues
Critical: 0
High: 0
Medium: 1
Low: 1
Related: BUG-UI-025, BUG-UI-033
### Overall
Needs Improvement

## Screen: Admin Access Gate
Route: `/admin/*`
File: `lib/app_versions/admin/features/admin_panel/presentation/widgets/admin_access_gate.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 8/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 0
Low: 0
### Overall
Pass

## Screen: Admin Workspace Dialogs
Route: `/admin/* modal`
File: `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_dialogs.dart`
### Audit score
UI: 8/10
UX: 8/10
Responsive: 8/10
Interaction: 8/10
Navigation: 8/10
State: 6/10
Accessibility: 8/10
Performance: 8/10
### Issues
Critical: 0
High: 0
Medium: 1
Low: 0
Related: BUG-UI-024
### Overall
Needs Improvement

# DETAILED ISSUES

## BUG-UI-001 — Quick Care là route active nhưng không có hành động chăm sóc nào thực thi
### Classification
- Type: Interaction
- Severity: HIGH
- Priority: P1
- Confidence: High
- Status: TODO
### Location
- Module: Dashboard / Health
- Screen: Quick Care
- Route: `/quick-care`
- File: `lib/app_versions/v1/features/quick_care/presentation/pages/quick_care_page.dart`
- Widget: QuickCarePage / NamiCareInfoTile
- Lines: ≈ 15–70 (baseline; line numbers may shift after commit)
### Description
Màn hình hướng dẫn người dùng chọn một gợi ý chăm sóc ngắn nhưng các tile chỉ hiển thị nội dung; không có onTap/onPressed, CTA bắt đầu, timer hay trạng thái hoàn tất. Đây là mismatch trực tiếp với screen spec của dự án, nơi Quick Care được định nghĩa là quick-action có một CTA chính và thời lượng rõ.
### Current behavior
Người dùng vào Quick Care, thấy các gợi ý như một lựa chọn có thể bắt đầu nhưng chạm vào tile không tạo hành động nào.
### Expected behavior
Mỗi gợi ý phải có hành động rõ hoặc có một CTA chính để bắt đầu, phản hồi và kết thúc tác vụ.
### Reproduction
1. Mở Features Hub.
2. Chọn Quick Care.
3. Chạm vào từng gợi ý chăm sóc; không có action/flow tiếp theo.
### Evidence
`QuickCarePage` render các `NamiCareInfoTile` không truyền callback. Spec `.codex/design/screens/v1-x07-quick-care.md` yêu cầu “one primary CTA” và success outcome có next action/result.
### Root cause
Presentation hiện mới là nội dung tĩnh, chưa nối interaction contract của feature.
### Impact
Feature active không hoàn thành user job; người dùng rơi vào dead-end và mất niềm tin vào CTA của Features Hub.
### Recommended fix
Bổ sung action model/CTA theo contract; dùng controller/service thật; trạng thái idle/running/completed/error; không giả lập hoàn thành.
### Related files
- `.codex/design/screens/v1-x07-quick-care.md`
- `lib/app_versions/v1/features/features_hub/presentation/pages/features_hub_page.dart`
### Related screens
- Features Hub

## BUG-UI-002 — Weekly Summary luôn hiển thị summary tĩnh, không đọc dữ liệu tuần thực tế
### Classification
- Type: Data Consistency
- Severity: HIGH
- Priority: P1
- Confidence: High
- Status: TODO
### Location
- Module: Dashboard / Health
- Screen: Weekly Summary
- Route: `/weekly-summary`
- File: `lib/app_versions/v1/features/weekly_summary/presentation/pages/weekly_summary_page.dart`
- Widget: WeeklySummaryPage
- Lines: ≈ 1–95 (baseline; line numbers may shift after commit)
### Description
Weekly Summary là route active nhưng widget là StatelessWidget, không watch provider/repository và luôn render cùng một trạng thái “chưa đủ thông tin” bất kể lịch sử người dùng.
### Current behavior
Người dùng có dữ liệu hoàn thành nhiệm vụ vẫn nhận cùng một summary tĩnh.
### Expected behavior
Summary phải phản ánh dữ liệu tuần hiện tại hoặc có empty/loading/error rõ ràng từ nguồn dữ liệu thật.
### Reproduction
1. Tạo/hoàn thành nhiệm vụ trong nhiều ngày.
2. Mở /weekly-summary.
3. Quan sát nội dung không thay đổi theo dữ liệu.
### Evidence
Source không import/watch bất kỳ provider dữ liệu tuần nào; toàn bộ copy và preview items là hằng số trong build.
### Root cause
Feature được đưa vào route/UI trước khi data/state contract được nối.
### Impact
Thông tin sức khỏe tổng hợp sai theo nghĩa “không phản ánh dữ liệu”, làm user hiểu rằng hệ thống không ghi nhận tiến trình.
### Recommended fix
Thiết kế repository/provider weekly aggregate từ task/meal/health logs; thêm loading/empty/error/ready và refresh.
### Related files
- `lib/app_versions/v1/features/today_tasks/`
- `lib/app_versions/v1/features/lifestyle_schedule/`
### Related screens
- Today Tasks
- Lifestyle Schedule
- Dashboard

## BUG-UI-003 — Today Tasks không tự cập nhật trạng thái theo thời gian khi màn hình đang mở
### Classification
- Type: State Management
- Severity: HIGH
- Priority: P1
- Confidence: High
- Status: TODO
### Location
- Module: AI / Nutrition / Schedule
- Screen: Today Tasks
- Route: `/today-tasks`
- File: `lib/app_versions/v1/features/today_tasks/presentation/pages/today_tasks_page.dart`
- Widget: TodayTasksPage / TodayTaskCard
- Lines: ≈ 20–55 (baseline; line numbers may shift after commit)
### Description
Today Tasks lấy `now` bằng cách watch một provider trả về hàm `DateTime Function()`. Provider không phát state khi thời gian trôi, nên các nhãn/CTA dựa trên thời điểm có thể đóng băng cho tới khi có rebuild do nguyên nhân khác.
### Current behavior
Một task có thể vẫn hiện “Sắp tới” sau khi đã đến giờ hoặc giữ CTA eligibility cũ nếu user để màn hình mở qua boundary.
### Expected behavior
Trạng thái thời gian phải cập nhật đúng tại boundary tương tự Lifestyle Schedule.
### Reproduction
1. Mở Today Tasks trước giờ bắt đầu một task.
2. Giữ màn hình mở qua thời điểm bắt đầu/kết thúc.
3. Quan sát label/CTA không có nguồn rebuild định kỳ/boundary.
### Evidence
`ref.watch(lifestyleScheduleClockProvider)()` chỉ sample thời gian; provider bản chất không thay đổi. Lifestyle Schedule có timer boundary riêng, Today Tasks không có.
### Root cause
Clock abstraction được dùng như dependency value thay vì reactive time source/boundary scheduler.
### Impact
Interaction và quy tắc hoàn thành/điểm có thể hiển thị lệch giữa Today Tasks và Lifestyle Schedule.
### Recommended fix
Dùng shared boundary ticker/provider hoặc schedule timer tới mốc gần nhất; refresh khi app resume; test crossing start/end boundary.
### Related files
- `lib/app_versions/v1/features/lifestyle_schedule/providers/lifestyle_schedule_provider.dart`
- `lib/app_versions/v1/features/today_tasks/presentation/widgets/today_task_card.dart`
### Related screens
- Lifestyle Schedule
- Dashboard

## BUG-UI-004 — Body Metrics có thể giữ dữ liệu cũ sau khi cập nhật Profile
### Classification
- Type: Data Consistency
- Severity: HIGH
- Priority: P1
- Confidence: High
- Status: TODO
### Location
- Module: Dashboard / Health
- Screen: Body Metrics
- Route: `/body-metrics`
- File: `lib/app_versions/v1/features/body_metrics/providers/body_metrics_providers.dart`
- Widget: BodyMetricsController
- Lines: multiple; load/build + invalidation contract (baseline; line numbers may shift after commit)
### Description
Body Metrics dùng Notifier giữ snapshot và load riêng. Sau khi Profile lưu thành công, helper invalidate user-scoped providers không invalidate `bodyMetricsControllerProvider`/personal context, nên quay lại Body Metrics có thể thấy chiều cao/cân nặng/BMI cũ.
### Current behavior
Profile cập nhật durable data nhưng Body Metrics không được buộc reload.
### Expected behavior
Mọi consumer của hồ sơ cơ thể phải cập nhật sau profile save.
### Reproduction
1. Mở Body Metrics và ghi nhận BMI.
2. Sang Profile, đổi chiều cao/cân nặng và lưu.
3. Quay lại Body Metrics; provider không có invalidation trong save contract.
### Evidence
`invalidateUserScopedProviders(ref)` invalidates dashboard/dynamic/tracking/schedule/meal/nutrition/settings nhưng thiếu body metrics; controller không autoDispose và chỉ reload khi gọi load.
### Root cause
Danh sách cross-feature invalidation không bao phủ consumer mới của profile.
### Impact
Chỉ số sức khỏe hiển thị mâu thuẫn giữa Profile, Dashboard/Body Metrics; nguy cơ lời khuyên dựa trên snapshot cũ.
### Recommended fix
Đưa body metrics vào invalidation contract hoặc chuyển sang provider phụ thuộc trực tiếp profile version/repository; thêm contract test Profile→BodyMetrics.
### Related files
- `lib/app_versions/v1/features/profile/presentation/pages/profile_page.dart`
- `lib/app_versions/v1/features/settings/providers/settings_provider.dart`
### Related screens
- Profile
- Dashboard

## BUG-UI-005 — Gentle Care nói sẽ “hạ mục tiêu” nhưng chỉ đổi state cục bộ và gợi ý tĩnh
### Classification
- Type: UX
- Severity: HIGH
- Priority: P1
- Confidence: High
- Status: TODO
### Location
- Module: Dashboard / Health
- Screen: Gentle Care Mode
- Route: `/gentle-care`
- File: `lib/app_versions/v1/features/gentle_care_mode/presentation/pages/gentle_care_mode_page.dart`
- Widget: GentleCareModePage
- Lines: ≈ 15–170 (baseline; line numbers may shift after commit)
### Description
Copy hứa “Nabi sẽ giúp bạn hạ mục tiêu xuống thật vừa sức”, nhưng interaction chỉ set `_selectedIndex` và hiển thị danh sách suggestion tĩnh; không có write vào goals/schedule/provider.
### Current behavior
User chọn trạng thái mệt/cần nhẹ nhàng và UI tạo cảm giác hệ thống đã điều chỉnh mục tiêu, trong khi dữ liệu nhiệm vụ không đổi.
### Expected behavior
Hoặc thực sự điều chỉnh kế hoạch qua domain service, hoặc copy phải nói rõ đây chỉ là gợi ý và yêu cầu user xác nhận thay đổi.
### Reproduction
1. Mở Gentle Care.
2. Chọn một mức trạng thái.
3. Quay lại lịch/nhiệm vụ; không có write path điều chỉnh mục tiêu.
### Evidence
Source chỉ dùng local selection state; không import repository/controller schedule/goal để persist change.
### Root cause
Copy và product semantics vượt quá implementation hiện có.
### Impact
Người dùng có thể bỏ nhiệm vụ vì tin rằng mục tiêu đã được hạ; gây hiểu sai behavior sức khỏe.
### Recommended fix
Chọn một contract: advisory-only với copy trung thực, hoặc action xác nhận cập nhật schedule/goals + refresh cross-screen.
### Related files
- `lib/app_versions/v1/features/lifestyle_schedule/`
- `lib/app_versions/v1/features/personal_goals/`
### Related screens
- Lifestyle Schedule
- Personal Goals
- Today Tasks

## BUG-UI-006 — Sale Participation biến lỗi tải trạng thái thành trạng thái “chưa tham gia” hợp lệ
### Classification
- Type: State Management
- Severity: HIGH
- Priority: P1
- Confidence: High
- Status: TODO
### Location
- Module: Sale
- Screen: Sale Participation
- Route: `/v2/sale (entry/sub-surface)`
- File: `lib/sale_referral/presentation/pages/sale_participation_page.dart`
- Widget: SaleParticipationPage
- Lines: ≈ 35–75 (baseline; line numbers may shift after commit)
### Description
Trong `saleState.when(error:)`, UI dựng `_BuildTermsBody` với `SaleState.none`. Lỗi backend vì vậy bị che thành một business state hợp lệ và có thể hiện form tham gia.
### Current behavior
Khi fetch trạng thái Sale thất bại, user vẫn có thể thấy UI như chưa tham gia thay vì error/retry.
### Expected behavior
Error phải giữ semantic error; không được suy ra SaleStatus.none từ failure.
### Reproduction
1. Làm cho load `saleStateProvider` thất bại.
2. Mở màn tham gia Sale.
3. UI render terms body với `SaleState.none` thay vì error state.
### Evidence
`error: (_, __) => _BuildTermsBody(... state: SaleState.none, ...)` trong source.
### Root cause
Fallback UX ưu tiên “có màn hình” hơn tính đúng của trusted state.
### Impact
User có thể gửi action không phù hợp trạng thái thật; làm tăng request trùng/nhầm và giảm trust ở flow tài chính/referral.
### Recommended fix
Render safe error state với Retry; chỉ hiển thị join action khi trusted state load thành công.
### Related files
- `lib/sale_referral/providers/sale_providers.dart`
- `lib/services/supabase/sale/`
### Related screens
- Sale Shell

## BUG-UI-007 — Auth Gate cho phép spam hành động merge/use-cloud khi đồng bộ đang chạy
### Classification
- Type: Potential Issue
- Severity: HIGH
- Priority: P1
- Confidence: Medium
- Status: TODO
### Location
- Module: V2/V3 Access
- Screen: Auth Gate
- Route: `/auth-gate`
- File: `lib/app_versions/v2/features/auth/presentation/pages/auth_gate_page.dart`
- Widget: _GuestConsentState / _applyGuestAction
- Lines: ≈ 20–135 (baseline; line numbers may shift after commit)
### Description
`_GuestConsentState` luôn nhận `loading: false`; `_applyGuestAction` là async nhưng không set local busy. Button merge/use-cloud vì vậy vẫn enabled trong lúc sync request đầu đang chạy. Controller có thể tự guard, nhưng UI source không chứng minh điều đó.
### Current behavior
Người dùng có thể nhấn nhiều lần action có ảnh hưởng guest/cloud data.
### Expected behavior
Action phải single-flight và disabled ngay từ tap đầu tới khi outcome rõ.
### Reproduction
1. Vào Auth Gate ở trạng thái awaitingConsent.
2. Nhấn nhanh “Đồng bộ ngay” hoặc “Dùng dữ liệu tài khoản” nhiều lần.
3. UI không có busy flag disable tức thời.
### Evidence
Builder truyền `loading: false`; callbacks gọi Future nhưng không setState busy.
### Root cause
Loading state của consent card không được nối với sync in-flight state.
### Impact
Potential duplicate sync/merge, race notification và nhiều feedback; flow dữ liệu nhạy cảm cần tránh concurrent action.
### Recommended fix
Derive loading từ sync controller hoặc local `_applyingGuestAction`; disable tất cả consent actions; test double-tap.
### Related files
- `lib/app_versions/v2/features/cloud_sync/`
### Related screens
- Login
- Menu

## BUG-UI-008 — V2 Login/Register có đường double-submit từ bàn phím
### Classification
- Type: Potential Issue
- Severity: HIGH
- Priority: P1
- Confidence: Medium
- Status: TODO
### Location
- Module: V2/V3 Access
- Screen: V2 Login / Register
- Route: `/auth/login, /auth/register`
- File: `lib/app_versions/v2/features/auth/presentation/pages/auth_pages.dart`
- Widget: V2LoginPage / V2RegisterPage _submit
- Lines: submit handlers + onFieldSubmitted (baseline; line numbers may shift after commit)
### Description
Field cuối gọi `_submit()` qua `onFieldSubmitted`. Các `_submit()` quan sát được không có early `if (_loading) return`, trong khi disable chủ yếu nằm ở button/legal consent. Keyboard action có thể được gửi lặp trước/giữa rebuild.
### Current behavior
Nút UI có loading, nhưng Enter/Done vẫn có callback riêng gọi submit.
### Expected behavior
Mọi entrypoint submit phải dùng cùng single-flight guard và fields nên disabled khi request in-flight.
### Reproduction
1. Nhập login/register hợp lệ.
2. Nhấn Done/Enter liên tục khi mạng chậm.
3. Quan sát source không có `_loading` guard đầu `_submit`.
### Evidence
`onFieldSubmitted: (_) => _submit()` xuất hiện ở password/referral fields; `_submit()` bắt đầu bằng backend/validation checks, không có loading guard. AdminLogin là counterexample có `if (_submitting) return`.
### Root cause
Busy state được áp dụng presentation button nhưng chưa áp dụng command handler toàn cục.
### Impact
Potential duplicate auth/register call, duplicate feedback và race route state.
### Recommended fix
Đặt `if (_loading) return` đầu tất cả auth submit handlers; disable input; add widget test rapid keyboard submit.
### Related files
- `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_login_page.dart`
### Related screens
- Auth Gate

## BUG-UI-009 — FamilyPlus tạo nhóm mặc định có thể phát nhiều command độc lập khi double-tap
### Classification
- Type: Potential Issue
- Severity: HIGH
- Priority: P1
- Confidence: Medium
- Status: TODO
### Location
- Module: V2/V3 Access
- Screen: FamilyPlus
- Route: `/v3/family-plus`
- File: `lib/app_versions/v3/features/familyplus/presentation/pages/familyplus_page.dart`
- Widget: Empty family create action
- Lines: create default group action/provider (baseline; line numbers may shift after commit)
### Description
CTA tạo nhóm không có local busy guard; provider command tạo idempotency key mới theo microseconds mỗi invocation. Double-tap có thể tạo hai command không cùng idempotency scope.
### Current behavior
Hai tap nhanh có thể đi qua hai invocation với hai key khác nhau.
### Expected behavior
UI action tạo group phải single-flight và reuse command idempotency cho cùng user intent.
### Reproduction
1. Vào FamilyPlus khi chưa có nhóm.
2. Double-tap CTA tạo nhóm trên mạng chậm.
3. Mỗi invocation sinh key mới, UI không disable ngay.
### Evidence
`familyPlusCreateDefaultGroupProvider` sinh idempotency key theo thời gian; page không có in-flight local guard ở empty CTA.
### Root cause
Idempotency được gắn theo request, không theo user intent; presentation không chống repeat.
### Impact
Potential duplicate group/mutation hoặc lỗi backend khó hiểu.
### Recommended fix
Dùng AsyncNotifier/mutation state, disable CTA, giữ key ổn định tới outcome; test double-tap.
### Related files
- `lib/app_versions/v3/features/familyplus/providers/familyplus_providers.dart`
### Related screens
- V3 Home

## BUG-UI-010 — Advanced Tracking create-goal thiếu single-flight guard ở empty state
### Classification
- Type: Potential Issue
- Severity: MEDIUM
- Priority: P1
- Confidence: Medium
- Status: TODO
### Location
- Module: V2/V3 Access
- Screen: Advanced Tracking
- Route: `/v3/advanced-tracking`
- File: `lib/app_versions/v3/features/advanced_tracking/presentation/pages/advanced_tracking_page.dart`
- Widget: Empty goal CTA
- Lines: empty-state create callback (baseline; line numbers may shift after commit)
### Description
CTA tạo hydration goal chạy async nhưng không có local busy/disabled state rõ ràng trong page. Rapid taps có thể dispatch nhiều request nếu tầng use-case không tự serialize.
### Current behavior
CTA vẫn là interactive source path trong khi Future chưa hoàn tất.
### Expected behavior
Create mutation phải single-flight với loading feedback.
### Reproduction
1. Vào Advanced Tracking khi chưa có goal.
2. Nhấn CTA tạo goal nhiều lần nhanh.
3. Kiểm tra page không sở hữu busy flag cho mutation.
### Evidence
Async callback được gọi trực tiếp từ button; không thấy `_creating`/AsyncValue mutation state trong page source.
### Root cause
Read-state và mutation-state chưa tách riêng.
### Impact
Potential duplicate writes/rebuild race.
### Recommended fix
Mutation provider/AsyncValue riêng; disable button, show progress, idempotent use-case.
### Related files
- `lib/app_versions/v3/features/advanced_tracking/providers/`
### Related screens
- V3 Home

## BUG-UI-011 — Settings luôn phát feedback thành công dù một hoặc nhiều refresh thất bại
### Classification
- Type: UX
- Severity: MEDIUM
- Priority: P1
- Confidence: High
- Status: TODO
### Location
- Module: Profile / Settings
- Screen: Settings tab
- Route: `/menu (tab Của bạn)`
- File: `lib/app_versions/v1/features/settings/presentation/pages/settings_page.dart`
- Widget: SettingsPage refresh handler
- Lines: refresh-all handler (baseline; line numbers may shift after commit)
### Description
Refresh nhiều provider được bọc try/catch rỗng; sau đó code luôn emit success. UI có thể báo refresh thành công trong khi data vẫn stale.
### Current behavior
Lỗi refresh bị nuốt và haptic/feedback success vẫn phát.
### Expected behavior
Chỉ báo success khi các nguồn bắt buộc thành công; partial failure phải có notice/retry phù hợp.
### Reproduction
1. Mở Settings.
2. Gây lỗi một provider/network refresh.
3. Kích hoạt refresh; source nuốt exception rồi emit success.
### Evidence
Các `try { ... } catch (_) {}` liên tiếp và unconditional `AppFeedbackType.success` ở cuối.
### Root cause
Refresh orchestration không aggregate result/error semantics.
### Impact
False success làm user tin dữ liệu tài khoản/quyền đã mới nhất.
### Recommended fix
Collect results; phân biệt success/partial/error; giữ existing content khi refresh nền.
### Related files
- `lib/app_versions/v1/features/settings/providers/settings_provider.dart`
### Related screens
- Profile
- Body Metrics
- Main Navigation

## BUG-UI-012 — AI Chat ép system bars dùng dark icons ngay cả trong dark theme
### Classification
- Type: Accessibility
- Severity: MEDIUM
- Priority: P1
- Confidence: High
- Status: TODO
### Location
- Module: AI / Nutrition / Schedule
- Screen: AI Chat
- Route: `/ai-chat`
- File: `lib/app_versions/v1/features/ai_chat/presentation/pages/ai_chat_screen.dart`
- Widget: AnnotatedRegion/SystemUiOverlayStyle
- Lines: top-level build/app bar overlay style (baseline; line numbers may shift after commit)
### Description
AI Chat cấu hình system status/navigation bar icon brightness dark cố định thay vì theo Theme/Brightness.
### Current behavior
Dark mode vẫn yêu cầu icon hệ thống màu tối, có nguy cơ tương phản thấp trên nền tối.
### Expected behavior
System overlay style phải derive từ actual surface brightness/theme.
### Reproduction
1. Bật dark mode.
2. Mở AI Chat.
3. Quan sát source dùng `SystemUiOverlayStyle.dark` cố định.
### Evidence
AnnotatedRegion/AppBar systemOverlayStyle hard-code dark.
### Root cause
Overlay style được tối ưu cho light theme ban đầu và không semantic.
### Impact
Khó nhìn status/navigation icons, đặc biệt accessibility/contrast.
### Recommended fix
Dùng `ThemeData.brightness`/semantic surface để chọn `SystemUiOverlayStyle.light/dark`; add dark widget/golden check.
### Related files
- `lib/core/theme/`
### Related screens
- Main Navigation

## BUG-UI-024 — Admin action confirmation dialog có thể overflow khi keyboard + large text
### Classification
- Type: Potential Issue
- Severity: MEDIUM
- Priority: P1
- Confidence: Medium
- Status: TODO
### Location
- Module: Admin
- Screen: Admin Workspace Dialogs
- Route: `/admin/* modal`
- File: `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_dialogs.dart`
- Widget: _AdminReasonDialog
- Lines: ≈ 20–120 (baseline; line numbers may shift after commit)
### Description
AlertDialog content là `SizedBox(width:480)` + non-scrollable `Column(mainAxisSize:min)` chứa autofocus TextField 3–5 lines và optional long CheckboxListTile. Trên compact admin, keyboard + textScale có thể vượt available vertical height.
### Current behavior
Không có SingleChildScrollView/viewInsets-specific layout trong reason dialog.
### Expected behavior
Critical admin confirmation phải usable ở short screen/keyboard/large text.
### Reproduction
1. Mở Admin trên phone/short height.
2. Set textScale 1.5.
3. Mở action reason dialog yêu cầu transfer verification; keyboard autofocus mở.
### Evidence
Non-scroll Column trong AlertDialog; TextField autofocus; optional checkbox copy dài.
### Root cause
Dialog được tối ưu desktop width nhưng admin shell hỗ trợ compact mobile.
### Impact
Potential CTA bị che/RenderFlex overflow, chặn action quản trị.
### Recommended fix
Wrap content in scroll view, cap height via MediaQuery, ensure actions reachable; widget test 360x640 + keyboard inset.
### Related files
- `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_page.dart`
### Related screens
- Admin Payments
- Admin Sale Conversions

## BUG-UI-025 — Admin presentation layer upload trực tiếp Supabase Storage
### Classification
- Type: Code Quality
- Severity: MEDIUM
- Priority: P1
- Confidence: High
- Status: TODO
### Location
- Module: Admin
- Screen: Admin Workspace
- Route: `/admin/*`
- File: `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_page.dart`
- Widget: proof upload action
- Lines: _pickAndUploadSalePayoutProof (baseline; line numbers may shift after commit)
### Description
Presentation page import/use Supabase client/storage trực tiếp để upload payout proof, phá dependency boundary `Presentation → Provider/Controller → Repository → Datasource/API`.
### Current behavior
UI sở hữu network/storage mutation và error handling.
### Expected behavior
Presentation chỉ gọi controller/use-case; storage upload nằm datasource/repository/service.
### Reproduction
1. Đọc AdminWorkspacePage.
2. Tìm `_pickAndUploadSalePayoutProof`.
3. Quan sát gọi `Supabase.instance.client.storage...uploadBinary` trực tiếp.
### Evidence
Direct Supabase Storage call nằm trong presentation source.
### Root cause
Operational flow được thêm nhanh tại page thay vì domain/data layer.
### Impact
Khó test, khó retry/cancel, dễ UI-state drift khi upload contract đổi; future bug risk cao ở flow tài chính.
### Recommended fix
Tách upload command vào controller/repository/datasource; expose typed AsyncValue/progress/safe error.
### Related files
- `lib/app_versions/admin/features/admin_panel/data/`
### Related screens
- Admin Sale Conversions
- Admin Reconciliation

## BUG-UI-013 — AI Chat tự cuộn xuống cuối ngay cả khi người dùng đang đọc lịch sử
### Classification
- Type: UX
- Severity: MEDIUM
- Priority: P2
- Confidence: High
- Status: TODO
### Location
- Module: AI / Nutrition / Schedule
- Screen: AI Chat
- Route: `/ai-chat`
- File: `lib/app_versions/v1/features/ai_chat/presentation/pages/ai_chat_screen.dart`
- Widget: auto-scroll synchronization
- Lines: message/loading listener + scroll-to-bottom (baseline; line numbers may shift after commit)
### Description
Auto-scroll kích hoạt khi message count/loading đổi nhưng không kiểm tra user đang ở gần bottom. Khi AI trả lời, user đang đọc tin nhắn cũ có thể bị kéo khỏi vị trí.
### Current behavior
Mọi response mới ưu tiên scroll bottom.
### Expected behavior
Chỉ auto-scroll nếu user đang gần bottom hoặc vừa gửi message; nếu không, show “tin nhắn mới” affordance.
### Reproduction
1. Mở cuộc chat dài.
2. Cuộn lên đọc tin cũ.
3. Chờ AI response/loading state đổi; code schedule scroll bottom.
### Evidence
Scroll sync dựa vào data changes, không có threshold `pixels/maxScrollExtent` trước khi animate.
### Root cause
Auto-scroll policy chưa phân biệt active composition và historical reading.
### Impact
Mất ngữ cảnh đọc, gây khó chịu trong hội thoại dài.
### Recommended fix
Track near-bottom threshold; preserve position; add new-message chip.
### Related files
- None beyond primary source identified.
### Related screens
- AI Voice

## BUG-UI-014 — Meal Plan thiếu nút Back hiển thị trong page chrome
### Classification
- Type: Navigation
- Severity: MEDIUM
- Priority: P2
- Confidence: High
- Status: TODO
### Location
- Module: AI / Nutrition / Schedule
- Screen: Meal Plan
- Route: `/meal-plan`
- File: `lib/app_versions/v1/features/meal_plan/presentation/pages/meal_plan_page.dart`
- Widget: MealPlanPage header
- Lines: page header/build (baseline; line numbers may shift after commit)
### Description
Meal Plan dùng custom header trong body và không cung cấp affordance Back rõ, dù route thường được push từ Features Hub/Dashboard. User phải dựa vào system back gesture/button.
### Current behavior
Không có visible back control như nhiều detail pages khác.
### Expected behavior
Detail route pushed từ navigation stack nên có back affordance nhất quán hoặc shell navigation rõ ràng.
### Reproduction
1. Từ Features Hub mở Meal Plan.
2. Quan sát header.
3. Không có Back button hiển thị.
### Evidence
Page source dùng custom header, không AppBar leading/back control.
### Root cause
Màn được thiết kế như top-level feature trong khi navigation call site dùng detail-route semantics.
### Impact
Discoverability/back navigation kém, đặc biệt web/desktop/accessibility.
### Recommended fix
Chuẩn hóa route role: top-level tab hoặc detail page; nếu detail, thêm AppBar/MedicalPageScaffold back.
### Related files
- `lib/app_versions/v1/features/features_hub/presentation/pages/features_hub_page.dart`
### Related screens
- Features Hub

## BUG-UI-015 — Có hai implementation Meal Replacement sheet song song
### Classification
- Type: Code Quality
- Severity: MEDIUM
- Priority: P2
- Confidence: High
- Status: TODO
### Location
- Module: AI / Nutrition / Schedule
- Screen: Meal Plan / Today Tasks
- Route: `/meal-plan, /today-tasks`
- File: `lib/app_versions/v1/features/meal_plan/presentation/pages/meal_plan_page.dart`
- Widget: private _MealReplacementSheet vs reusable MealReplacementPickerSheet
- Lines: meal replacement sheet definitions (baseline; line numbers may shift after commit)
### Description
MealPlan page chứa sheet private trong khi `meal_replacement_picker.dart` cung cấp reusable picker được dùng ở TodayTaskCard. Hai implementation cùng job dễ drift loading/error/selection/layout.
### Current behavior
Thay món từ hai entrypoint có UI/logic presentation khác nhau.
### Expected behavior
Một component/contract picker dùng chung, parameterize context/callback.
### Reproduction
1. Mở thay món từ Meal Plan.
2. Mở thay món từ Today Tasks.
3. Đối chiếu source: hai sheet khác nhau.
### Evidence
Hai class/sheet độc lập cùng fetch candidate + select replacement.
### Root cause
Feature được mở rộng qua nhiều entrypoint mà chưa consolidate component.
### Impact
Design drift, bug fix phải làm hai nơi, behavior không nhất quán.
### Recommended fix
Hợp nhất vào reusable picker + shared state contract; giữ wrapper mỏng nếu copy khác.
### Related files
- `lib/app_versions/v1/features/meal_plan/presentation/widgets/meal_replacement_picker.dart`
- `lib/app_versions/v1/features/today_tasks/presentation/widgets/today_task_card.dart`
### Related screens
- Today Tasks

## BUG-UI-016 — Route Daily Health Tracking chỉ là alias nguyên màn Lifestyle Schedule
### Classification
- Type: UX
- Severity: MEDIUM
- Priority: P2
- Confidence: High
- Status: TODO
### Location
- Module: AI / Nutrition / Schedule
- Screen: Daily Health Tracking Alias
- Route: `/health-tracking`
- File: `lib/app_versions/v1/features/daily_health_tracking/presentation/pages/daily_health_tracking_page.dart`
- Widget: DailyHealthTrackingPage
- Lines: entire file (baseline; line numbers may shift after commit)
### Description
Route “health tracking” render trực tiếp `LifestyleSchedulePage`, tạo hai tên/entrypoint cho cùng UI mà không giải thích semantics.
### Current behavior
User chọn Health Tracking hoặc Lifestyle Schedule có thể đến cùng một màn, back/history/analytics bị khó hiểu.
### Expected behavior
Nếu intentional alias, navigation/copy phải thống nhất và canonicalize route; nếu là feature riêng, phải có UI riêng.
### Reproduction
1. Mở /health-tracking.
2. Mở /lifestyle-schedule.
3. Hai route render cùng LifestyleSchedulePage.
### Evidence
`DailyHealthTrackingPage` chỉ return `const LifestyleSchedulePage()`.
### Root cause
Legacy feature route được giữ khi implementation hợp nhất nhưng chưa canonicalize product/navigation.
### Impact
Duplicate function perception, route analytics/deep-link confusion, maintenance drift.
### Recommended fix
Chọn canonical route; redirect alias hoặc tạo tracking hub riêng nếu business yêu cầu.
### Related files
- `lib/app_versions/v1/router/v1_router.dart`
### Related screens
- Lifestyle Schedule

## BUG-UI-017 — Consumer UI hiển thị thuật ngữ kỹ thuật/nội bộ
### Classification
- Type: Design System
- Severity: MEDIUM
- Priority: P2
- Confidence: High
- Status: TODO
### Location
- Module: Cross-cutting UI
- Screen: Body Metrics / Personal Goals / Water / Sale
- Route: `multiple`
- File: `lib/app_versions/v1/features/body_metrics/presentation/pages/body_metrics_page.dart`
- Widget: user-facing copy
- Lines: multiple files (baseline; line numbers may shift after commit)
### Description
Một số consumer-facing copy chứa thuật ngữ như deterministic, observation, completion, freshness, wellness, “Read-only tại màn này”, “feature sở hữu dữ liệu”, “contract”, “giới hạn lưu trữ kỹ thuật”, “dashboard”. Điều này vi phạm UI domain rule không lộ implementation/internal terms.
### Current behavior
User phải hiểu từ ngữ developer/product-internal thay vì health language.
### Expected behavior
Copy tiếng Việt, health-first, giải thích hành động/kết quả, không nhắc contract/read-only/feature/storage internals.
### Reproduction
1. Mở Body Metrics/Personal Goals/Water/Sale.
2. Đọc các note trạng thái/hint.
3. Thấy thuật ngữ kỹ thuật/nội bộ.
### Evidence
Các string literal xuất hiện trực tiếp trong presentation source; `.codex/domains/ui-nami.md` cấm internal terminology.
### Root cause
Debug/architecture vocabulary rò vào copy khi feature được harden.
### Impact
Giảm hiểu biết, tăng cognitive load, không nhất quán persona Nabi.
### Recommended fix
Tạo copy glossary/linter test; chuyển nội dung sang user outcome language.
### Related files
- `lib/app_versions/v1/features/personal_goals/presentation/pages/personal_goals_page.dart`
- `lib/app_versions/v1/features/water_tracking/presentation/pages/water_tracking_page.dart`
- `lib/sale_referral/presentation/pages/sale_shell_page.dart`
### Related screens
- Body Metrics
- Personal Goals
- Water Tracking
- Sale Shell

## BUG-UI-018 — Proof Gallery tạo file-system Future trực tiếp trong build
### Classification
- Type: Performance
- Severity: MEDIUM
- Priority: P2
- Confidence: High
- Status: TODO
### Location
- Module: AI / Nutrition / Schedule
- Screen: Schedule Proof Gallery
- Route: `Navigator sub-surface`
- File: `lib/app_versions/v1/features/lifestyle_schedule/presentation/pages/schedule_proof_gallery_page.dart`
- Widget: _ProofImage
- Lines: ≈ _ProofImage.build() (baseline; line numbers may shift after commit)
### Description
`FutureBuilder<File>(future: service.resolveProofFile(...))` và nested `FutureBuilder<bool>(future: file.exists())` tạo Future mới mỗi rebuild. Flutter có thể lặp file I/O và flicker loading khi parent rebuild.
### Current behavior
Rebuild card tái tạo resolve/existence futures.
### Expected behavior
Future phải stable/cache theo proof hoặc được resolve ở provider/controller/model layer.
### Reproduction
1. Mở proof gallery có nhiều ảnh.
2. Trigger rebuild (theme/provider/parent).
3. Mỗi `_ProofImage.build` tạo futures mới theo source.
### Evidence
Future expressions nằm trực tiếp trong builder argument.
### Root cause
Async file resolution đặt trong presentation build tree.
### Impact
I/O lặp, loading placeholder nhấp nháy và scroll jank trên gallery lớn.
### Recommended fix
Memoize future theo proof id/stateful widget hoặc expose async provider/cache; pre-resolve metadata.
### Related files
- `lib/app_versions/v1/features/lifestyle_schedule/application/schedule_proof_image_service.dart`
### Related screens
- Lifestyle Schedule

## BUG-UI-019 — Thumbnail proof có thể decode ảnh camera full-resolution
### Classification
- Type: Potential Issue
- Severity: MEDIUM
- Priority: P2
- Confidence: Medium
- Status: TODO
### Location
- Module: AI / Nutrition / Schedule
- Screen: Schedule Proof Gallery
- Route: `Navigator sub-surface`
- File: `lib/app_versions/v1/features/lifestyle_schedule/presentation/pages/schedule_proof_gallery_page.dart`
- Widget: _ProofImage
- Lines: Image.file in thumbnail path (baseline; line numbers may shift after commit)
### Description
Thumbnail 112/164px dùng `Image.file(file, fit: BoxFit.cover)` không `cacheWidth/cacheHeight`. Nếu proof là ảnh camera lớn, decoder có thể giữ bitmap lớn hơn cần thiết.
### Current behavior
UI size nhỏ nhưng decode hint không được cung cấp.
### Expected behavior
Thumbnail nên decode theo target pixel size/DPR hoặc dùng generated thumbnail.
### Reproduction
1. Có nhiều proof ảnh camera độ phân giải cao.
2. Mở gallery và scroll.
3. Source Image.file không có decode dimensions.
### Evidence
`Image.file` thumbnail không set cacheWidth/cacheHeight.
### Root cause
Image pipeline dùng original file cho cả thumbnail và viewer.
### Impact
Potential memory pressure/jank/OOM trên thiết bị RAM thấp.
### Recommended fix
Tạo thumbnail/cacheWidth theo rendered size*dpr; giữ original chỉ cho viewer.
### Related files
- None beyond primary source identified.
### Related screens
- Lifestyle Schedule

## BUG-UI-020 — Features Hub giữ 3 cột cả ở màn 320px, nguy cơ truncate label khi text scale lớn
### Classification
- Type: Potential Issue
- Severity: MEDIUM
- Priority: P2
- Confidence: Medium
- Status: TODO
### Location
- Module: Dashboard / Health
- Screen: Features Hub
- Route: `/menu (feature tab)`
- File: `lib/app_versions/v1/features/features_hub/presentation/pages/features_hub_page.dart`
- Widget: compact feature grid
- Lines: grid delegate/layout (baseline; line numbers may shift after commit)
### Description
Grid dùng 3 columns cho width <720; ở 320px sau padding mỗi tile rất hẹp. MainAxisExtent tăng theo text scale nhưng horizontal width không đổi; title maxLines=2 có thể ellipsize nhiều nhãn dài.
### Current behavior
Compact screen vẫn 3 cột.
### Expected behavior
Breakpoint nên giảm 2 cột khi available tile width thấp hoặc dùng min-tile-width adaptive grid.
### Reproduction
1. Chạy width 320.
2. Set textScale 1.5.
3. Mở Features Hub với nhãn dài tiếng Việt.
### Evidence
CrossAxisCount cố định 3 dưới 720; title giới hạn maxLines=2.
### Root cause
Breakpoint theo viewport tier, không theo minimum content width.
### Impact
Potential mất nội dung/khó phân biệt feature ở accessibility text scale.
### Recommended fix
Dùng LayoutBuilder tính columns theo min tile width; widget tests 320/360 x textScale 1.5.
### Related files
- None beyond primary source identified.
### Related screens
- Main Navigation

## BUG-UI-021 — Nutrition summary grid có nguy cơ overflow/truncate ở large text
### Classification
- Type: Potential Issue
- Severity: MEDIUM
- Priority: P2
- Confidence: Medium
- Status: TODO
### Location
- Module: AI / Nutrition / Schedule
- Screen: Nutrition
- Route: `/nutrition`
- File: `lib/app_versions/v1/features/nutrition/presentation/pages/nutrition_page.dart`
- Widget: summary metric Grid
- Lines: metric grid layout (baseline; line numbers may shift after commit)
### Description
Compact layout dùng 2 cột với childAspectRatio cố định khoảng 1.05 trong khi metric card có label/hint tiếng Việt nhiều dòng. Height không derive text scale.
### Current behavior
Grid cell height cố định theo aspect ratio.
### Expected behavior
Card height co giãn theo text hoặc breakpoint/list at large scale.
### Reproduction
1. Width 320–360.
2. textScale 1.5.
3. Mở Nutrition với metric hint dài.
### Evidence
2-column grid + fixed childAspectRatio; hint maxLines giới hạn.
### Root cause
Card sizing dựa viewport, chưa dựa intrinsic accessible content.
### Impact
Potential crop/ellipsis quá mức hoặc overflow.
### Recommended fix
Adaptive min-height/mainAxisExtent theo textScale hoặc Wrap/list.
### Related files
- None beyond primary source identified.
### Related screens
- Nutrition Profile Editor

## BUG-UI-022 — Meal Plan date selector dùng kích thước tile cố định, rủi ro large-text
### Classification
- Type: Potential Issue
- Severity: MEDIUM
- Priority: P2
- Confidence: Medium
- Status: TODO
### Location
- Module: AI / Nutrition / Schedule
- Screen: Meal Plan
- Route: `/meal-plan`
- File: `lib/app_versions/v1/features/meal_plan/presentation/pages/meal_plan_page.dart`
- Widget: date strip/date tile
- Lines: date selector layout (baseline; line numbers may shift after commit)
### Description
Date strip dùng các dimension cố định (tile width/height) để chứa weekday/day. Với textScale 1.5+ hoặc localized labels, vertical/horizontal fit có thể không đủ.
### Current behavior
Kích thước không scale theo text metrics.
### Expected behavior
Date tile cần min constraints/adaptive height hoặc semantic compact mode.
### Reproduction
1. Set textScale 1.5–2.0.
2. Mở Meal Plan.
3. Kiểm tra date strip trên 320/360px.
### Evidence
Fixed-sized date tile/strip trong source, không thấy branch textScale tương ứng.
### Root cause
Calendar chip thiết kế pixel-fixed.
### Impact
Potential overflow/truncated date, touch density kém.
### Recommended fix
Use min constraints, Fitted/Wrap phù hợp hoặc calculate height from text scale; test accessibility.
### Related files
- None beyond primary source identified.
### Related screens
- Nutrition

## BUG-UI-023 — Features Hub và Settings dùng cùng Nabi route context `/menu`
### Classification
- Type: Potential Issue
- Severity: MEDIUM
- Priority: P2
- Confidence: High
- Status: TODO
### Location
- Module: Foundation / Shell
- Screen: Main Navigation
- Route: `/menu`
- File: `lib/app_versions/v1/features/dashboard/presentation/pages/menu_page.dart`
- Widget: tab→Nabi route mapping
- Lines: routeByTab mapping (baseline; line numbers may shift after commit)
### Description
Feature tab và Settings tab đều map Nabi context sang `V1RoutePaths.menu`. Nabi provider `setRoute` return sớm nếu routePath không đổi, nên chuyển trực tiếp giữa hai tab có thể giữ transient context/bubble của tab trước.
### Current behavior
Hai logical contexts khác nhau có cùng route key.
### Expected behavior
Nabi context key phải phân biệt feature hub/settings hoặc reset context on tab change.
### Reproduction
1. Ở Features Hub trigger Nabi state/context.
2. Chuyển tab Của bạn/Settings.
3. `setRoute(/menu)` có thể early-return vì route không đổi.
### Evidence
`routeByTab = [dashboard, menu, /health-insights, menu]`; V1 nabi provider skip update on equal route.
### Root cause
Nabi context keyed bằng route string trong shell có nhiều tabs không có route riêng.
### Impact
Potential speech bubble/emotion/context không phù hợp màn hiện tại.
### Recommended fix
Dùng explicit view-context/tab id hoặc unique pseudo route `/settings` internal; reset transient state on tab change.
### Related files
- `lib/app_versions/v1/features/nabi/providers/nabi_provider.dart`
- `lib/features/nabi/presentation/navigation/nabi_route_mapper.dart`
### Related screens
- Features Hub
- Settings tab

## BUG-UI-026 — Health Module Access dùng pushReplacement khi forward, có nguy cơ mất return-to-feature
### Classification
- Type: Potential Issue
- Severity: MEDIUM
- Priority: P2
- Confidence: Medium
- Status: TODO
### Location
- Module: V2/V3 Access
- Screen: Health Module Access
- Route: `/v2/health-modules/:moduleId`
- File: `lib/app_versions/v2/features/health_modules/presentation/pages/health_module_access_page.dart`
- Widget: forward navigation
- Lines: post-frame forward branch (baseline; line numbers may shift after commit)
### Description
Gate forward sang login/upgrade bằng replacement. Source page không cho thấy return URL/module id được preserve; sau auth/payment user có thể không quay lại feature yêu cầu ban đầu.
### Current behavior
Gate route bị thay khỏi stack.
### Expected behavior
Locked deep link nên preserve intended destination qua login/upgrade và return sau success.
### Reproduction
1. Deep-link vào paid/protected health module khi chưa đủ access.
2. Gate forward sang login/payment.
3. Kiểm tra source không truyền return target trong forward branch.
### Evidence
Navigation dùng replacement và route arguments không chứa return destination trong page source.
### Root cause
Access decision tách khỏi navigation intent restoration.
### Impact
Potential flow drop-off/dead-end sau upgrade/auth.
### Recommended fix
Encode `returnTo` safely hoặc navigation coordinator giữ intent; add integration tests.
### Related files
- `lib/app_versions/v2/router/v2_router.dart`
- `lib/app_versions/v2/features/payments/presentation/pages/membership_payment_page.dart`
### Related screens
- Membership Payment
- Login

## BUG-UI-027 — Health Score pull-to-refresh không có failure feedback giữ-nguyên-content rõ ràng
### Classification
- Type: Potential Issue
- Severity: MEDIUM
- Priority: P2
- Confidence: Medium
- Status: TODO
### Location
- Module: V2/V3 Access
- Screen: Health Score
- Route: `/v2/health-score`
- File: `lib/app_versions/v2/features/health_scoring/presentation/pages/health_score_habits_page.dart`
- Widget: RefreshIndicator handler
- Lines: refresh handler (baseline; line numbers may shift after commit)
### Description
Refresh invalidates/awaits provider nhưng không thấy catch/partial error UX ở ready state. Failure có thể bubble qua RefreshIndicator hoặc thay ready content bằng error state thay vì giữ snapshot với notice.
### Current behavior
Background/manual refresh failure semantics không rõ trong presentation.
### Expected behavior
Giữ dữ liệu cũ, show non-destructive “chưa cập nhật” + retry.
### Reproduction
1. Mở Health Score có data.
2. Ngắt mạng/ép provider lỗi.
3. Pull refresh.
### Evidence
Refresh callback trực tiếp await provider refresh; không local failure feedback trong handler.
### Root cause
Initial-load error và refresh error dùng cùng async source nhưng không tách state.
### Impact
Potential UI jump/feedback kém.
### Recommended fix
Stale-while-refresh pattern; catch safe error and preserve last data.
### Related files
- None beyond primary source identified.
### Related screens
- V2 Home

## BUG-UI-028 — Dashboard periodic refresh có thể tiếp tục khi tab không hiển thị
### Classification
- Type: Potential Issue
- Severity: MEDIUM
- Priority: P2
- Confidence: Medium
- Status: TODO
### Location
- Module: Dashboard / Health
- Screen: Dashboard
- Route: `/dashboard / /menu tab`
- File: `lib/app_versions/v1/features/dashboard/presentation/pages/dashboard_page.dart`
- Widget: DashboardPage timer
- Lines: initState periodic 15s timer (baseline; line numbers may shift after commit)
### Description
Dashboard tạo Timer.periodic 15s invalidate dynamic provider. MainNavigation giữ các page trong PageView/tab shell; nếu Dashboard state còn mounted khi chuyển tab, timer vẫn invalidates/rebuilds data offscreen.
### Current behavior
Timer lifecycle chỉ gắn widget dispose, không gắn tab visibility.
### Expected behavior
Periodic refresh nên pause khi page không active hoặc dùng shared visibility-aware scheduler.
### Reproduction
1. Mở menu Dashboard.
2. Chuyển sang Features/Health Insights/Settings.
3. Nếu Dashboard vẫn mounted, periodic timer tiếp tục.
### Evidence
Timer periodic trong Dashboard state; MainNavigation sử dụng PageView với tab pages.
### Root cause
Refresh lifecycle dựa mount state, không view visibility.
### Impact
Potential battery/network/SQLite work và rebuild không cần thiết.
### Recommended fix
Visibility-aware refresh; AppLifecycle + tab active provider; prefer event/boundary-driven updates.
### Related files
- `lib/app_versions/v1/features/dashboard/presentation/pages/menu_page.dart`
### Related screens
- Main Navigation

## BUG-UI-029 — ResultStep source-only có default health score 82 có thể tạo dữ liệu giả nếu được wire nhầm
### Classification
- Type: Potential Issue
- Severity: MEDIUM
- Priority: P2
- Confidence: High
- Status: TODO
### Location
- Module: Onboarding / Auth
- Screen: Onboarding Result Step
- Route: `source-only`
- File: `lib/app_versions/v1/features/onboarding/presentation/widgets/result_step.dart`
- Widget: ResultStep
- Lines: constructor defaults (baseline; line numbers may shift after commit)
### Description
`ResultStep` có `healthScore = 82`, `userName = Bạn`, message mặc định. Matrix phân loại source-only, nhưng nếu component được tái sử dụng mà caller bỏ healthScore, UI sẽ trình bày một chỉ số sức khỏe giả như dữ liệu thật.
### Current behavior
Default non-null realistic score tồn tại trong production source.
### Expected behavior
Health metric phải required hoặc nullable/empty state; không dùng realistic production mock defaults.
### Reproduction
1. Instantiate `const ResultStep()` trong bất kỳ flow nào.
2. Màn hiển thị “Điểm khởi đầu 82”.
3. Không có nguồn dữ liệu health score.
### Evidence
Constructor mặc định `this.healthScore = 82`.
### Root cause
Preview/demo convenience nằm trong reusable production widget.
### Impact
Potential fabricated health information nếu component được nối lại trong tương lai.
### Recommended fix
Make healthScore required/nullable; explicit preview fixture chỉ trong test/story/demo.
### Related files
- `.codex/design/12_UI_FILE_DESIGN_MATRIX.md`
### Related screens
- Onboarding Review

## BUG-UI-030 — Splash nuốt lỗi bootstrap và vẫn tiếp tục route decision
### Classification
- Type: Potential Issue
- Severity: MEDIUM
- Priority: P2
- Confidence: High
- Status: TODO
### Location
- Module: Onboarding / Auth
- Screen: Splash
- Route: `/`
- File: `lib/app_versions/v1/features/splash/presentation/pages/splash_page.dart`
- Widget: _initializeSafely / _readOnboardingCompletedSafely
- Lines: bootstrap helpers (baseline; line numbers may shift after commit)
### Description
Splash catch lỗi initialize và read onboarding state, chỉ debugPrint; read failure trả `false`, sau đó flow vẫn điều hướng. Một lỗi local state tạm thời có thể đẩy user đã onboard về onboarding thay vì error/retry.
### Current behavior
Initialization failures bị che khỏi UI; onboarding read failure biến thành “not completed”.
### Expected behavior
Critical bootstrap state failure nên phân biệt unknown/error với false và có safe retry/recovery.
### Reproduction
1. Làm AppPrefs read throw.
2. Mở app.
3. Helper return false và route decision tiếp tục như user chưa onboarding.
### Evidence
catch in `_readOnboardingCompletedSafely` returns false; `_initializeSafely` chỉ log.
### Root cause
Fail-open UX dùng business default thay vì tri-state result.
### Impact
Potential user bị đưa sai flow và nhập lại onboarding không cần thiết.
### Recommended fix
Use typed bootstrap result {ready, recoverableError}; retry/continue-with-warning policy rõ.
### Related files
- `lib/app_versions/v1/features/splash/domain/services/splash_route_decision.dart`
### Related screens
- Onboarding Entry
- Auth Gate

## BUG-UI-031 — Design surface registry bỏ sót Settings tab đang hoạt động
### Classification
- Type: Code Quality
- Severity: MEDIUM
- Priority: P2
- Confidence: High
- Status: TODO
### Location
- Module: Foundation / Shell
- Screen: Settings tab
- Route: `/menu (tab Của bạn)`
- File: `.codex/design/12_UI_FILE_DESIGN_MATRIX.md`
- Widget: 80-surface registry
- Lines: surface table (baseline; line numbers may shift after commit)
### Description
Registry tuyên bố 80 surface nhưng không có SettingsPage, trong khi MainNavigation import/render Settings và map một tab “Của bạn” riêng. Audit/design refactor dựa matrix có thể bỏ sót màn thật.
### Current behavior
Settings tồn tại runtime nhưng không có entry surface riêng trong matrix.
### Expected behavior
Surface registry phải bao phủ mọi logical tab/page thực tế.
### Reproduction
1. Đọc MainNavigation imports/tabs.
2. Đọc 80-surface matrix.
3. Không tìm thấy SettingsPage entry.
### Evidence
`menu_page.dart` import settings page và routeByTab có settings; matrix list không có Settings surface.
### Root cause
Registry được refresh theo route/source catalog nhưng tab nội bộ chưa được thêm.
### Impact
Future design/a11y audit có thể bỏ sót Settings; coverage claim sai lệch.
### Recommended fix
Thêm Settings surface ID/spec vào design matrix và coverage tooling.
### Related files
- `lib/app_versions/v1/features/dashboard/presentation/pages/menu_page.dart`
- `lib/app_versions/v1/features/settings/presentation/pages/settings_page.dart`
### Related screens
- Main Navigation

## BUG-UI-032 — Tên mascot không nhất quán: Nabi / NaBi / Nami Care
### Classification
- Type: Design System
- Severity: LOW
- Priority: P2
- Confidence: High
- Status: TODO
### Location
- Module: Cross-cutting UI
- Screen: Onboarding / Features Hub / Nami Care / AI Voice
- Route: `multiple`
- File: `multiple presentation files`
- Widget: user-facing copy
- Lines: multiple (baseline; line numbers may shift after commit)
### Description
Brand/persona xuất hiện dưới nhiều dạng “Nabi”, “NaBi”, “Nami Care”, trong khi feature hub có label “Nabi Care” nhưng destination page là “Nami Care”.
### Current behavior
Cùng nhân vật/tính năng có spelling khác giữa các màn.
### Expected behavior
Một canonical display name và naming glossary.
### Reproduction
1. Đi qua Onboarding, Features Hub, Nami/Nabi Care, AI Voice.
2. So sánh heading/copy.
3. Thấy Nabi/NaBi/Nami khác nhau.
### Evidence
Literal strings trong onboarding steps, `nami_care_page.dart`, FeaturesHub và AI Voice.
### Root cause
Di sản rename Nami→Nabi chưa được sweep toàn bộ copy.
### Impact
Minor brand inconsistency và cognitive friction.
### Recommended fix
Define canonical `AppStrings.nabiName`/copy glossary; add string audit test.
### Related files
- `lib/app_versions/v1/features/features_hub/presentation/widgets/nami_care_page.dart`
- `lib/app_versions/v1/features/ai_voice/presentation/pages/ai_voice_page.dart`
### Related screens
- Features Hub
- Onboarding

## BUG-UI-033 — Admin sidebar utility touch targets chỉ 42–44dp
### Classification
- Type: Accessibility
- Severity: LOW
- Priority: P2
- Confidence: Medium
- Status: TODO
### Location
- Module: Admin
- Screen: Admin Workspace Shell
- Route: `/admin/*`
- File: `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_shell.dart`
- Widget: _SidebarDestination / _SidebarUtility
- Lines: minHeight constraints (baseline; line numbers may shift after commit)
### Description
Sidebar destination minHeight 44 và utility minHeight 42, thấp hơn guideline dự án “touch targets ≥48dp where practical”. Desktop pointer có thể ổn, nhưng compact/drawer cũng reuse component.
### Current behavior
Một số interactive rows có min target <48dp.
### Expected behavior
Compact/touch surface nên đạt 48dp hoặc có hitbox mở rộng.
### Reproduction
1. Mở admin drawer trên thiết bị touch.
2. Inspect utility/destination constraints.
3. MinHeight là 42/44.
### Evidence
`BoxConstraints(minHeight: 44)` và `minHeight: 42` trong shell source.
### Root cause
Desktop density token được reuse cho mobile drawer.
### Impact
Tap accuracy giảm với accessibility/motor impairment.
### Recommended fix
Adaptive minHeight 48 trên touch/compact; retain dense desktop if needed.
### Related files
- None beyond primary source identified.
### Related screens
- Admin Dashboard
- Admin Users

## BUG-UI-034 — V3 standalone router lặp lại route V1/V2 ngoài unified router
### Classification
- Type: Code Quality
- Severity: LOW
- Priority: P3
- Confidence: High
- Status: TODO
### Location
- Module: V2/V3 Access
- Screen: V3 routing
- Route: `/v3 + duplicated login/payments/schedule`
- File: `lib/app_versions/v3/router/v3_router.dart`
- Widget: v3StandaloneRoutes
- Lines: route list (baseline; line numbers may shift after commit)
### Description
V3 standalone routes copy lại V2 Login/Payments và V1 LifestyleSchedule bên cạnh unified V2 router. Hai definitions có thể drift builder/query parsing/guards theo thời gian.
### Current behavior
Same path có nhiều route definitions ở codebase.
### Expected behavior
Shared canonical route factory/list hoặc standalone router tái dùng exact route definitions.
### Reproduction
1. So sánh v2_router.dart và v3_router.dart.
2. Tìm login/payments/lifestyleSchedule.
3. Thấy definitions lặp.
### Evidence
`v3StandaloneRoutes` tự tạo GoRoute cho các path đã có ở V1/V2.
### Root cause
Standalone test/dev surface phát triển song song unified app.
### Impact
Potential navigation drift khi một router được sửa mà router kia không cập nhật.
### Recommended fix
Extract route builders/factories hoặc deprecate standalone runtime nếu không còn cần.
### Related files
- `lib/app_versions/v2/router/v2_router.dart`
- `lib/app_versions/v1/router/v1_router.dart`
### Related screens
- V3 Home
- Login
- Membership Payment

## BUG-UI-035 — Onboarding ghi log trong build path
### Classification
- Type: Performance
- Severity: LOW
- Priority: P3
- Confidence: Medium
- Status: TODO
### Location
- Module: Onboarding / Auth
- Screen: Onboarding Journey Shell
- Route: `/onboarding`
- File: `lib/app_versions/v1/features/onboarding/presentation/pages/onboarding_page.dart`
- Widget: OnboardingPage build
- Lines: build logging statement (baseline; line numbers may shift after commit)
### Description
Build path có `AppLogger.info`/logging state, nên mọi rebuild từ input/Riverpod có thể tạo log I/O/noise không cần thiết.
### Current behavior
Logging gắn render frequency.
### Expected behavior
Log semantic event/transition, không log mỗi build.
### Reproduction
1. Nhập dữ liệu onboarding gây nhiều rebuild.
2. Quan sát build path có logger.
3. Mỗi render có thể phát log.
### Evidence
Logger invocation nằm trực tiếp trong build.
### Root cause
Diagnostic instrumentation đặt sai lifecycle.
### Impact
Minor overhead/noisy logs, khó debug event thực.
### Recommended fix
Move log to controller state transition/listener, throttle if needed.
### Related files
- None beyond primary source identified.
### Related screens
- Onboarding steps

## BUG-UI-036 — AI Voice dùng `context.go` khi chuyển sang AI Chat, có thể thay stack thay vì quay lại được
### Classification
- Type: Potential Issue
- Severity: LOW
- Priority: P3
- Confidence: Medium
- Status: TODO
### Location
- Module: AI / Nutrition / Schedule
- Screen: AI Voice
- Route: `/ai-voice`
- File: `lib/app_versions/v1/features/ai_voice/presentation/pages/ai_voice_page.dart`
- Widget: “Nhập chữ” action
- Lines: navigation action (baseline; line numbers may shift after commit)
### Description
Action chuyển từ Voice sang Chat dùng `context.go(aiChat)` thay vì push/pop semantics. Nếu Voice được push từ một feature, `go` có thể reset location stack và Back từ Chat không quay về Voice/nguồn trước đó như user kỳ vọng.
### Current behavior
Navigation semantics là location replace.
### Expected behavior
Chọn rõ UX: switch mode trong cùng conversation hoặc push Chat giữ return path.
### Reproduction
1. Push AI Voice từ một màn khác.
2. Chọn “Nhập chữ”.
3. Source dùng `context.go` tới AI Chat.
### Evidence
Direct `context.go` in AI Voice action.
### Root cause
Mode switch được implement như top-level navigation.
### Impact
Potential back-stack surprise, mức ảnh hưởng thấp.
### Recommended fix
Use shared AI shell/mode switch hoặc pushReplacement có explicit semantics và tests.
### Related files
- `lib/app_versions/v1/features/ai_chat/presentation/pages/ai_chat_screen.dart`
### Related screens
- AI Chat

# CROSS-SCREEN CONSISTENCY

## Meal / nutrition
- Meal replacement is available from Meal Plan and Today Tasks but uses two presentation implementations (BUG-UI-015).
- Meal/Nutrition screens otherwise expose explicit loading/error/refresh states in the inspected source; no confirmed stale write path was proven in this static pass.

## Schedule / task / proof / score
- Today Tasks and Lifestyle Schedule share schedule data but differ in time-boundary refresh behavior (BUG-UI-003).
- Proof Gallery performs async filesystem work in build and can decode full-size camera images for thumbnails (BUG-UI-018/019).
- Daily Health Tracking route is an alias of Lifestyle Schedule (BUG-UI-016), increasing product/navigation duplication.

## Profile / body metrics
- Profile save invalidation does not include Body Metrics controller, creating a proven stale-snapshot path (BUG-UI-004).

## Auth / guest merge / access
- Auth Gate data choice is correctly explicit, but its mutation CTA lacks UI single-flight state (BUG-UI-007).
- Login/Register keyboard submit path needs a global busy guard (BUG-UI-008).
- Health Module forwarding may lose intended destination after auth/upgrade (BUG-UI-026, Potential).

## Sale / Admin
- Sale Participation incorrectly treats load failure as `SaleState.none` (BUG-UI-006).
- Admin actions generally have stronger busy/confirmation handling; however payout proof upload violates the architecture boundary (BUG-UI-025) and compact reason dialog needs runtime responsive validation (BUG-UI-024).

# TOP 20 VẤN ĐỀ QUAN TRỌNG NHẤT

## #1 BUG-UI-001
Impact: Feature active không hoàn thành user job; người dùng rơi vào dead-end và mất niềm tin vào CTA của Features Hub.
Why priority: HIGH/P1; confidence High; Có static evidence trực tiếp.
Recommended action: Bổ sung action model/CTA theo contract; dùng controller/service thật; trạng thái idle/running/completed/error; không giả lập hoàn thành.
Files: `lib/app_versions/v1/features/quick_care/presentation/pages/quick_care_page.dart`

## #2 BUG-UI-002
Impact: Thông tin sức khỏe tổng hợp sai theo nghĩa “không phản ánh dữ liệu”, làm user hiểu rằng hệ thống không ghi nhận tiến trình.
Why priority: HIGH/P1; confidence High; Có static evidence trực tiếp.
Recommended action: Thiết kế repository/provider weekly aggregate từ task/meal/health logs; thêm loading/empty/error/ready và refresh.
Files: `lib/app_versions/v1/features/weekly_summary/presentation/pages/weekly_summary_page.dart`

## #3 BUG-UI-003
Impact: Interaction và quy tắc hoàn thành/điểm có thể hiển thị lệch giữa Today Tasks và Lifestyle Schedule.
Why priority: HIGH/P1; confidence High; Có static evidence trực tiếp.
Recommended action: Dùng shared boundary ticker/provider hoặc schedule timer tới mốc gần nhất; refresh khi app resume; test crossing start/end boundary.
Files: `lib/app_versions/v1/features/today_tasks/presentation/pages/today_tasks_page.dart`

## #4 BUG-UI-004
Impact: Chỉ số sức khỏe hiển thị mâu thuẫn giữa Profile, Dashboard/Body Metrics; nguy cơ lời khuyên dựa trên snapshot cũ.
Why priority: HIGH/P1; confidence High; Có static evidence trực tiếp.
Recommended action: Đưa body metrics vào invalidation contract hoặc chuyển sang provider phụ thuộc trực tiếp profile version/repository; thêm contract test Profile→BodyMetrics.
Files: `lib/app_versions/v1/features/body_metrics/providers/body_metrics_providers.dart`

## #5 BUG-UI-005
Impact: Người dùng có thể bỏ nhiệm vụ vì tin rằng mục tiêu đã được hạ; gây hiểu sai behavior sức khỏe.
Why priority: HIGH/P1; confidence High; Có static evidence trực tiếp.
Recommended action: Chọn một contract: advisory-only với copy trung thực, hoặc action xác nhận cập nhật schedule/goals + refresh cross-screen.
Files: `lib/app_versions/v1/features/gentle_care_mode/presentation/pages/gentle_care_mode_page.dart`

## #6 BUG-UI-006
Impact: User có thể gửi action không phù hợp trạng thái thật; làm tăng request trùng/nhầm và giảm trust ở flow tài chính/referral.
Why priority: HIGH/P1; confidence High; Có static evidence trực tiếp.
Recommended action: Render safe error state với Retry; chỉ hiển thị join action khi trusted state load thành công.
Files: `lib/sale_referral/presentation/pages/sale_participation_page.dart`

## #7 BUG-UI-007
Impact: Potential duplicate sync/merge, race notification và nhiều feedback; flow dữ liệu nhạy cảm cần tránh concurrent action.
Why priority: HIGH/P1; confidence Medium; Potential Issue cần runtime verify.
Recommended action: Derive loading từ sync controller hoặc local `_applyingGuestAction`; disable tất cả consent actions; test double-tap.
Files: `lib/app_versions/v2/features/auth/presentation/pages/auth_gate_page.dart`

## #8 BUG-UI-008
Impact: Potential duplicate auth/register call, duplicate feedback và race route state.
Why priority: HIGH/P1; confidence Medium; Potential Issue cần runtime verify.
Recommended action: Đặt `if (_loading) return` đầu tất cả auth submit handlers; disable input; add widget test rapid keyboard submit.
Files: `lib/app_versions/v2/features/auth/presentation/pages/auth_pages.dart`

## #9 BUG-UI-009
Impact: Potential duplicate group/mutation hoặc lỗi backend khó hiểu.
Why priority: HIGH/P1; confidence Medium; Potential Issue cần runtime verify.
Recommended action: Dùng AsyncNotifier/mutation state, disable CTA, giữ key ổn định tới outcome; test double-tap.
Files: `lib/app_versions/v3/features/familyplus/presentation/pages/familyplus_page.dart`

## #10 BUG-UI-010
Impact: Potential duplicate writes/rebuild race.
Why priority: MEDIUM/P1; confidence Medium; Potential Issue cần runtime verify.
Recommended action: Mutation provider/AsyncValue riêng; disable button, show progress, idempotent use-case.
Files: `lib/app_versions/v3/features/advanced_tracking/presentation/pages/advanced_tracking_page.dart`

## #11 BUG-UI-011
Impact: False success làm user tin dữ liệu tài khoản/quyền đã mới nhất.
Why priority: MEDIUM/P1; confidence High; Có static evidence trực tiếp.
Recommended action: Collect results; phân biệt success/partial/error; giữ existing content khi refresh nền.
Files: `lib/app_versions/v1/features/settings/presentation/pages/settings_page.dart`

## #12 BUG-UI-012
Impact: Khó nhìn status/navigation icons, đặc biệt accessibility/contrast.
Why priority: MEDIUM/P1; confidence High; Có static evidence trực tiếp.
Recommended action: Dùng `ThemeData.brightness`/semantic surface để chọn `SystemUiOverlayStyle.light/dark`; add dark widget/golden check.
Files: `lib/app_versions/v1/features/ai_chat/presentation/pages/ai_chat_screen.dart`

## #13 BUG-UI-024
Impact: Potential CTA bị che/RenderFlex overflow, chặn action quản trị.
Why priority: MEDIUM/P1; confidence Medium; Potential Issue cần runtime verify.
Recommended action: Wrap content in scroll view, cap height via MediaQuery, ensure actions reachable; widget test 360x640 + keyboard inset.
Files: `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_dialogs.dart`

## #14 BUG-UI-025
Impact: Khó test, khó retry/cancel, dễ UI-state drift khi upload contract đổi; future bug risk cao ở flow tài chính.
Why priority: MEDIUM/P1; confidence High; Có static evidence trực tiếp.
Recommended action: Tách upload command vào controller/repository/datasource; expose typed AsyncValue/progress/safe error.
Files: `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_page.dart`

## #15 BUG-UI-013
Impact: Mất ngữ cảnh đọc, gây khó chịu trong hội thoại dài.
Why priority: MEDIUM/P2; confidence High; Có static evidence trực tiếp.
Recommended action: Track near-bottom threshold; preserve position; add new-message chip.
Files: `lib/app_versions/v1/features/ai_chat/presentation/pages/ai_chat_screen.dart`

## #16 BUG-UI-014
Impact: Discoverability/back navigation kém, đặc biệt web/desktop/accessibility.
Why priority: MEDIUM/P2; confidence High; Có static evidence trực tiếp.
Recommended action: Chuẩn hóa route role: top-level tab hoặc detail page; nếu detail, thêm AppBar/MedicalPageScaffold back.
Files: `lib/app_versions/v1/features/meal_plan/presentation/pages/meal_plan_page.dart`

## #17 BUG-UI-015
Impact: Design drift, bug fix phải làm hai nơi, behavior không nhất quán.
Why priority: MEDIUM/P2; confidence High; Có static evidence trực tiếp.
Recommended action: Hợp nhất vào reusable picker + shared state contract; giữ wrapper mỏng nếu copy khác.
Files: `lib/app_versions/v1/features/meal_plan/presentation/pages/meal_plan_page.dart`

## #18 BUG-UI-016
Impact: Duplicate function perception, route analytics/deep-link confusion, maintenance drift.
Why priority: MEDIUM/P2; confidence High; Có static evidence trực tiếp.
Recommended action: Chọn canonical route; redirect alias hoặc tạo tracking hub riêng nếu business yêu cầu.
Files: `lib/app_versions/v1/features/daily_health_tracking/presentation/pages/daily_health_tracking_page.dart`

## #19 BUG-UI-017
Impact: Giảm hiểu biết, tăng cognitive load, không nhất quán persona Nabi.
Why priority: MEDIUM/P2; confidence High; Có static evidence trực tiếp.
Recommended action: Tạo copy glossary/linter test; chuyển nội dung sang user outcome language.
Files: `lib/app_versions/v1/features/body_metrics/presentation/pages/body_metrics_page.dart`

## #20 BUG-UI-018
Impact: I/O lặp, loading placeholder nhấp nháy và scroll jank trên gallery lớn.
Why priority: MEDIUM/P2; confidence High; Có static evidence trực tiếp.
Recommended action: Memoize future theo proof id/stateful widget hoặc expose async provider/cache; pre-resolve metadata.
Files: `lib/app_versions/v1/features/lifestyle_schedule/presentation/pages/schedule_proof_gallery_page.dart`

# DUPLICATED UI / COMPONENT REPORT

Chi tiết đầy đủ: `docs/audit/UI_UX_DUPLICATION_REPORT.md`.

1. **Meal replacement**: hai sheet cùng user job → merge reusable component.
2. **Daily Health Tracking / Lifestyle Schedule**: hai route, cùng page → canonicalize.
3. **Nabi context `/menu`**: Features + Settings share một context key → tách view id.
4. **V3 standalone router**: lặp V1/V2 route builders → shared factory/deprecate standalone.
5. **Green/Blue token naming residue**: compatibility aliases tồn tại sau Blue Wellness cutover → document/canonicalize; không xóa mù quáng.
6. **Nabi V1 assets**: tồn tại như rollback source-only; pubspec chỉ bundle Nabi V2 → intentional, không ghi thành bug asset.

# UX IMPROVEMENTS

Các mục dưới đây là recommendation, **không phải confirmed bug** trừ khi đã có BUG-ID ở trên.

1. Rút ngắn auth wrapper V1 → V2 nếu không còn cần surface trung gian; tránh cảm giác “bấm đăng nhập rồi lại sang màn đăng nhập”.
2. Nutrition Profile Editor: cân nhắc date picker/segmented date input thay cho nhập tay `YYYY-MM-DD` để giảm lỗi định dạng.
3. AI Chat: action xóa hội thoại nên có confirmation hoặc undo nếu lịch sử có giá trị với user.
4. Feature screens được push nên thống nhất visible Back affordance, không dựa hoàn toàn system gesture.
5. Coming-soon pages nên có CTA quay về feature hub/notify-me nếu product cho phép, nhưng không giả lập availability.
6. Weekly Summary khi triển khai nên ưu tiên “3 điều thay đổi + 1 hành động tiếp theo” thay vì dashboard dày đặc.
7. Gentle Care nên phân biệt rõ “gợi ý” và “điều chỉnh lịch thật” bằng CTA xác nhận.
8. Settings nên gom các row chưa có action vào section “Sắp có” thay vì để giống menu enabled nếu visual treatment chưa đủ khác.
9. Health Module lock/upgrade nên hiển thị rõ user sẽ quay lại đâu sau khi nâng cấp.
10. Sale/Admin copy nên tránh English product-internal terms như dashboard/contract trong consumer contexts.

# POTENTIAL / HIDDEN UI BUGS

- **BUG-UI-007 (HIGH/P1)** — Auth Gate cho phép spam hành động merge/use-cloud khi đồng bộ đang chạy. Evidence: `lib/app_versions/v2/features/auth/presentation/pages/auth_gate_page.dart`. Runtime/device confirmation still required.
- **BUG-UI-008 (HIGH/P1)** — V2 Login/Register có đường double-submit từ bàn phím. Evidence: `lib/app_versions/v2/features/auth/presentation/pages/auth_pages.dart`. Runtime/device confirmation still required.
- **BUG-UI-009 (HIGH/P1)** — FamilyPlus tạo nhóm mặc định có thể phát nhiều command độc lập khi double-tap. Evidence: `lib/app_versions/v3/features/familyplus/presentation/pages/familyplus_page.dart`. Runtime/device confirmation still required.
- **BUG-UI-010 (MEDIUM/P1)** — Advanced Tracking create-goal thiếu single-flight guard ở empty state. Evidence: `lib/app_versions/v3/features/advanced_tracking/presentation/pages/advanced_tracking_page.dart`. Runtime/device confirmation still required.
- **BUG-UI-024 (MEDIUM/P1)** — Admin action confirmation dialog có thể overflow khi keyboard + large text. Evidence: `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_dialogs.dart`. Runtime/device confirmation still required.
- **BUG-UI-019 (MEDIUM/P2)** — Thumbnail proof có thể decode ảnh camera full-resolution. Evidence: `lib/app_versions/v1/features/lifestyle_schedule/presentation/pages/schedule_proof_gallery_page.dart`. Runtime/device confirmation still required.
- **BUG-UI-020 (MEDIUM/P2)** — Features Hub giữ 3 cột cả ở màn 320px, nguy cơ truncate label khi text scale lớn. Evidence: `lib/app_versions/v1/features/features_hub/presentation/pages/features_hub_page.dart`. Runtime/device confirmation still required.
- **BUG-UI-021 (MEDIUM/P2)** — Nutrition summary grid có nguy cơ overflow/truncate ở large text. Evidence: `lib/app_versions/v1/features/nutrition/presentation/pages/nutrition_page.dart`. Runtime/device confirmation still required.
- **BUG-UI-022 (MEDIUM/P2)** — Meal Plan date selector dùng kích thước tile cố định, rủi ro large-text. Evidence: `lib/app_versions/v1/features/meal_plan/presentation/pages/meal_plan_page.dart`. Runtime/device confirmation still required.
- **BUG-UI-023 (MEDIUM/P2)** — Features Hub và Settings dùng cùng Nabi route context `/menu`. Evidence: `lib/app_versions/v1/features/dashboard/presentation/pages/menu_page.dart`. Runtime/device confirmation still required.
- **BUG-UI-026 (MEDIUM/P2)** — Health Module Access dùng pushReplacement khi forward, có nguy cơ mất return-to-feature. Evidence: `lib/app_versions/v2/features/health_modules/presentation/pages/health_module_access_page.dart`. Runtime/device confirmation still required.
- **BUG-UI-027 (MEDIUM/P2)** — Health Score pull-to-refresh không có failure feedback giữ-nguyên-content rõ ràng. Evidence: `lib/app_versions/v2/features/health_scoring/presentation/pages/health_score_habits_page.dart`. Runtime/device confirmation still required.
- **BUG-UI-028 (MEDIUM/P2)** — Dashboard periodic refresh có thể tiếp tục khi tab không hiển thị. Evidence: `lib/app_versions/v1/features/dashboard/presentation/pages/dashboard_page.dart`. Runtime/device confirmation still required.
- **BUG-UI-029 (MEDIUM/P2)** — ResultStep source-only có default health score 82 có thể tạo dữ liệu giả nếu được wire nhầm. Evidence: `lib/app_versions/v1/features/onboarding/presentation/widgets/result_step.dart`. Runtime/device confirmation still required.
- **BUG-UI-030 (MEDIUM/P2)** — Splash nuốt lỗi bootstrap và vẫn tiếp tục route decision. Evidence: `lib/app_versions/v1/features/splash/presentation/pages/splash_page.dart`. Runtime/device confirmation still required.
- **BUG-UI-033 (LOW/P2)** — Admin sidebar utility touch targets chỉ 42–44dp. Evidence: `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_shell.dart`. Runtime/device confirmation still required.
- **BUG-UI-034 (LOW/P3)** — V3 standalone router lặp lại route V1/V2 ngoài unified router. Evidence: `lib/app_versions/v3/router/v3_router.dart`. Runtime/device confirmation still required.
- **BUG-UI-036 (LOW/P3)** — AI Voice dùng `context.go` khi chuyển sang AI Chat, có thể thay stack thay vì quay lại được. Evidence: `lib/app_versions/v1/features/ai_voice/presentation/pages/ai_voice_page.dart`. Runtime/device confirmation still required.

# DEAD / UNUSED / SOURCE-ONLY UI

- `ResultStep` is classified source-only by the design matrix and contains a realistic default score (BUG-UI-029). Keep it out of production flow until data is explicit.
- `DevDatabaseViewerPage` is source-only/developer-oriented; ensure no production navigation entry is exposed.
- Sleep Tracking, Stress Tracking and Community are explicit coming-soon pages; they are not counted as missing implementations/bugs by themselves.
- V1 Nabi assets remain source-only rollback according to `pubspec.yaml`; do not delete automatically.
- V3 includes planned/premium surfaces; a “planned” screen is not a bug when copy/access clearly states availability.

# ACCESSIBILITY SUMMARY

- Strong patterns observed: SafeArea usage on key pages, semantics on consent/Nabi overlay, reduced-motion policy in Splash/Nabi/onboarding, tooltips on many icon buttons, responsive admin toolbar/drawer.
- Main risks: AI Chat system-bar contrast (BUG-UI-012), compact admin touch targets (BUG-UI-033), and text-scale risks in dense grids/date strips/dialogs (BUG-UI-020/021/022/024).
- Static source review cannot prove WCAG contrast ratios for every semantic color in all themes; golden/device accessibility QA remains required.

# PERFORMANCE UI SUMMARY

- Controllers/timers are generally disposed correctly in inspected high-impact pages (Splash, Admin login/workspace, Nabi animation, Lifestyle Schedule).
- Main evidence-backed concerns: Future creation/filesystem I/O inside Proof image build (BUG-UI-018), possible full-resolution thumbnail decode (BUG-UI-019), and potential offscreen Dashboard polling (BUG-UI-028).
- Nabi animation player uses `RepaintBoundary`, reduced-motion/performance-tier suppression and disposes controller; no leak was proven there.

# PROJECT UI/UX AUDIT SUMMARY
Total modules/audit domains: 8 primary + cross-cutting
Total screens/logical surfaces: 81
Total widgets reviewed: 183 UI-affecting baseline entries were used as the component/file coverage map; high-impact shared/transient widgets were directly inspected.
Total files reviewed: 90+ source/docs/router/provider/design files were directly inspected through GitHub connector; the 183-file historical UI baseline was reconciled as coverage metadata.
Total issues: 36
Critical: 0
High: 9
Medium: 22
Low: 5
UI: 0
UX: 4
Responsive: 0
Navigation: 1
Interaction: 1
State Management: 2
Data Consistency: 2
Accessibility: 2
Performance: 2
Design System: 2
Asset: 0
Code Quality: 4
Potential Issue: 16
Overall UI score: 7.4/10
Overall UX score: 6.8/10
Overall quality score: 7.0/10

# FINAL COVERAGE VALIDATION

| Check | Result | Evidence |
|---|---|---|
| Route map re-read | PASS | V1/V2/V3/Admin router + route-path/guard reconciliation |
| Registered route → target screen | PASS | All route entries mapped in `UI_UX_SCREEN_INVENTORY.md` |
| Design surface registry | PASS WITH DRIFT | 80 registered surfaces reconciled; Settings tab discovered as 81st logical surface (BUG-UI-031) |
| Onboarding internal steps | PASS | shell + Welcome/Basic/Goals/Conditions/Lifestyle/Extras/Daily Routine/Consent/Review/Result reconciled |
| Dialog/sheet/overlay review | PASS for high-impact sources | meal replacement, proof viewer, Auth merge/signout dialogs, payment/admin dialogs, Nabi overlay |
| Shared component review | PASS as mapped static audit | Medical primitives, onboarding primitives, Nabi global components, Admin shell, feature-local shared pickers reviewed/reconciled |
| Duplicate issue merge | PASS | Cross-screen root causes merged; naming/internal-copy issues consolidated |
| Severity normalization | PASS | No CRITICAL without crash/data-loss proof; potential issues explicitly marked |
| Runtime device/golden verification | NOT RUN | No local checkout/emulator available in execution environment |
| Flutter analyze/test/build | NOT RUN | Audit-only task; connector source review, no runtime code edits |

## Final conclusion
NanoBio có nền tảng UI engineering tương đối tốt ở các surface mới/hardened: design primitives, async states, SafeArea, responsive Admin, onboarding shell và lifecycle disposal được dùng khá nhất quán. Rủi ro release lớn nhất không nằm ở cosmetic spacing mà ở **semantic UI correctness**: feature active nhưng chưa thực hiện lời hứa (Quick/Weekly/Gentle), stale cross-screen state (Body Metrics), non-reactive time state (Today Tasks), trusted-state fallback sai (Sale), và mutation không single-flight ở một số access/paid flows. Nên ưu tiên sửa HIGH/P1 trước khi tiếp tục polish visual.