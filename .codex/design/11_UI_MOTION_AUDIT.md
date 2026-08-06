# UI and Motion Audit

## 1. Scope

Static audit trên `183` file thuộc theme, app shell, routers, presentation và shared UI.

## 2. Quantitative findings

- Page/screen: **46**.
- Widget file: **59**.
- Có animation/motion hiện tại: **40 file**.
- Duration raw: **21 file**.
- Color trực tiếp: **33 file**.
- Haptic trực tiếp: **11 file**.
- Audio playback trong source: **0 file**.

| Group | Files | Pages | Raw duration files | Direct color files | Direct haptic files |
| --- | --- | --- | --- | --- | --- |
| 01_foundation_shell | 55 | 0 | 6 | 12 | 0 |
| 02_splash_onboarding | 22 | 4 | 6 | 9 | 3 |
| 03_dashboard_menu | 36 | 4 | 0 | 5 | 1 |
| 04_ai_chat_voice | 5 | 2 | 2 | 2 | 2 |
| 05_meal_nutrition | 5 | 3 | 1 | 1 | 0 |
| 06_schedule_proof | 6 | 3 | 1 | 1 | 1 |
| 07_health_tracking | 11 | 9 | 0 | 0 | 1 |
| 08_features_care | 7 | 4 | 1 | 0 | 0 |
| 09_auth_profile_settings | 10 | 7 | 0 | 2 | 0 |
| 10_v2_v3_membership | 7 | 6 | 0 | 0 | 0 |
| 11_sale_admin | 8 | 4 | 0 | 1 | 0 |
| 12_nabi_global | 11 | 0 | 4 | 0 | 3 |

## 3. Confirmed architecture drift

1. Có hai lớp token/theme song song: `app_*` và `foundation/tokens/primitives`.
2. `AppColors/AppSpacing/AppTextStyles` đang được dùng rộng hơn semantic token layer, nên không thể xóa trực tiếp.
3. `app_motion.dart`, `app_animations.dart`, `foundation/motion.dart` và `AppMotionTokens` chồng trách nhiệm.
4. `AppTextStyles` xuất hiện ở nhiều lớp và cần loại bỏ symbol trùng.
5. Route transition V1 hiện chỉ fade ở một helper trong khi theme có page transition khác.
6. Haptic được gọi trực tiếp ở page/widget/controller; chưa có policy/cooldown/test adapter.
7. `pubspec.yaml` khai báo audio SFX nhưng snapshot không có file vật lý và source chưa có player service.
8. Nhiều page quá lớn, khó bảo đảm stable widget identity và targeted animation.

## 4. Largest UI files

| Path | LOC | Kind | Current evidence |
| --- | --- | --- | --- |
| lib/app_versions/admin/features/admin_panel/presentation/pages/admin_shell_page.dart | 3874 | page | controller×2, AnimatedContainer×4, AnimatedSwitcher×2, AnimatedOpacity×1, AnimatedScale×2, Colors.*×6, motion token×9, Semantics×1, Nabi×5 |
| lib/app_versions/v1/features/meal_plan/presentation/pages/meal_plan_page.dart | 1900 | page | controller×2, AnimatedContainer×2, AnimatedScale×1, TweenAnimationBuilder×1, duration raw×1, Colors.*×1, motion token×3, Semantics×2, RefreshIndicator×1, Nabi×5 |
| lib/app_versions/v1/features/lifestyle_schedule/presentation/pages/lifestyle_schedule_page.dart | 1875 | page | AnimatedContainer×6, AnimatedOpacity×1, AnimatedScale×1, duration raw×2, Colors.*×2, motion token×14, Semantics×3, RefreshIndicator×1, Nabi×14 |
| lib/app_versions/v2/features/auth/presentation/pages/auth_pages.dart | 1745 | page | AnimatedSwitcher×1, Colors.*×1, motion token×1, Semantics×2, Nabi×10 |
| lib/app_versions/v1/features/splash/presentation/pages/splash_page.dart | 1380 | page | controller×17, AnimatedContainer×3, duration raw×2, Colors.*×2, motion token×5, Semantics×3, Nabi×46 |
| lib/app_versions/v1/features/settings/presentation/pages/settings_page.dart | 1243 | page | Colors.*×2, RefreshIndicator×1, Nabi×25 |
| lib/app_versions/v1/features/other/presentation/widgets/health_insights_widgets.dart | 1211 | widget | Nabi×5 |
| lib/app_versions/v1/features/ai_chat/presentation/pages/ai_chat_screen.dart | 1200 | page | controller×2, AnimatedContainer×2, AnimatedSwitcher×1, TweenAnimationBuilder×2, haptic trực tiếp×3, duration raw×1, Colors.*×3, motion token×6, Semantics×4, Nabi×6 |
| lib/app_versions/v1/features/onboarding/presentation/widgets/onboarding_compact_ui.dart | 1082 | widget | AnimatedContainer×3, AnimatedSwitcher×1, AnimatedScale×1, haptic trực tiếp×3, Colors.*×3, motion token×5, Semantics×2, Nabi×59 |
| lib/sale_referral/presentation/pages/sale_shell_page.dart | 1081 | page | Chưa có motion/feedback đáng kể |
| lib/app_versions/v1/features/nabi/presentation/widgets/nabi_character_widget.dart | 1022 | widget | controller×28, duration raw×11, motion token×8, Semantics×1, Nabi×72 |
| lib/app_versions/v1/features/dashboard/presentation/widgets/sections/dashboard_sections.dart | 1008 | widget | Semantics×1, Nabi×3 |
| lib/app_versions/v1/features/dashboard/presentation/widgets/overview/dashboard_overview_widgets.dart | 1005 | widget | TweenAnimationBuilder×1, motion token×1, Semantics×4 |
| lib/app_versions/v1/features/onboarding/presentation/widgets/nabi_onboarding_experience.dart | 925 | widget | controller×6, AnimatedContainer×1, AnimatedSwitcher×1, AnimatedScale×1, haptic trực tiếp×1, duration raw×2, Colors.*×2, motion token×3, Semantics×2, Nabi×92 |
| lib/app_versions/v1/features/nutrition/presentation/pages/nutrition_page.dart | 911 | page | RefreshIndicator×1, Nabi×15 |

## 5. Priority refactor hotspots

- `admin_shell_page.dart`: 3.8k LOC, nhiều animation/state/table/dialog trong một file.
- `meal_plan_page.dart`: 1.9k LOC; cần tách card/detail/replace/date controls.
- `lifestyle_schedule_page.dart`: 1.8k LOC; timeline/action/proof cần stable identity.
- `auth_pages.dart`: 1.7k LOC; tách login/register/recovery/shared form.
- `splash_page.dart`: 1.3k LOC; nhiều controller, cần một timeline orchestrator.
- `ai_chat_screen.dart`: 1.2k LOC; haptic/duration/controller cần chuẩn hóa.
- `settings_page.dart` và `sale_shell_page.dart`: >1k LOC; cần tách sections.

## 6. Design conclusion

Không nên bắt đầu bằng chỉnh hiệu ứng từng page. Phải khóa foundation, feedback service, primitive states và route registry trước; sau đó migrate theo wave để tránh thêm lớp motion thứ ba.
