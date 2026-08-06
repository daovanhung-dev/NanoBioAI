# Motion and Feedback Debt Register

Danh sách này là bằng chứng static để ưu tiên cleanup; không đồng nghĩa từng usage là lỗi. Mỗi usage phải được review và map sang exception hoặc token/service canonical.

| File | Group | Evidence | Kind |
| --- | --- | --- | --- |
| lib/app_versions/admin/features/admin_panel/presentation/pages/admin_login_page.dart | 11_sale_admin | AnimatedSwitcher ×2 | page |
| lib/app_versions/admin/features/admin_panel/presentation/pages/admin_shell_page.dart | 11_sale_admin | Colors.* ×6, AnimationController ×2, AnimatedSwitcher ×2 | page |
| lib/app_versions/v1/features/ai_chat/presentation/pages/ai_chat_screen.dart | 04_ai_chat_voice | duration raw ×1, Colors.* ×3, haptic trực tiếp ×3, AnimationController ×2, AnimatedSwitcher ×1 | page |
| lib/app_versions/v1/features/ai_voice/presentation/pages/ai_voice_page.dart | 04_ai_chat_voice | AnimatedSwitcher ×1 | page |
| lib/app_versions/v1/features/daily_health_tracking/presentation/controllers/daily_health_tracking_controller.dart | 07_health_tracking | haptic trực tiếp ×1 | controller |
| lib/app_versions/v1/features/dashboard/presentation/pages/menu_page.dart | 03_dashboard_menu | Colors.* ×4, haptic trực tiếp ×1, AnimationController ×4 | page |
| lib/app_versions/v1/features/dashboard/presentation/widgets/score/score_metric_row.dart | 03_dashboard_menu | Colors.* ×1 | widget |
| lib/app_versions/v1/features/dashboard/presentation/widgets/score/score_ring_painter.dart | 03_dashboard_menu | Color raw ×1 | widget |
| lib/app_versions/v1/features/dashboard/presentation/widgets/states/skeleton_box.dart | 03_dashboard_menu | AnimationController ×2 | widget |
| lib/app_versions/v1/features/features_hub/presentation/pages/features_hub_page.dart | 03_dashboard_menu | Colors.* ×1 | page |
| lib/app_versions/v1/features/features_hub/presentation/widgets/nami_care_page.dart | 03_dashboard_menu | Colors.* ×2 | page |
| lib/app_versions/v1/features/lifestyle_schedule/presentation/controllers/lifestyle_schedule_controller.dart | 06_schedule_proof | haptic trực tiếp ×1 | controller |
| lib/app_versions/v1/features/lifestyle_schedule/presentation/pages/lifestyle_schedule_page.dart | 06_schedule_proof | duration raw ×2, Colors.* ×2 | page |
| lib/app_versions/v1/features/meal_plan/presentation/pages/meal_plan_page.dart | 05_meal_nutrition | duration raw ×1, Colors.* ×1, AnimationController ×2 | page |
| lib/app_versions/v1/features/nabi/presentation/widgets/nabi_character_widget.dart | 12_nabi_global | duration raw ×11, AnimationController ×28 | widget |
| lib/app_versions/v1/features/nabi/presentation/widgets/nabi_floating_overlay.dart | 12_nabi_global | haptic trực tiếp ×3, AnimationController ×2, AnimatedSwitcher ×1 | widget |
| lib/app_versions/v1/features/nutrition/presentation/pages/nutrition_profile_editor_page.dart | 05_meal_nutrition | AnimatedSwitcher ×1 | page |
| lib/app_versions/v1/features/onboarding/presentation/pages/onboarding_page.dart | 02_splash_onboarding | duration raw ×2, Colors.* ×1, AnimatedSwitcher ×1 | page |
| lib/app_versions/v1/features/onboarding/presentation/widgets/consent_step.dart | 02_splash_onboarding | duration raw ×1, Colors.* ×1, haptic trực tiếp ×1, AnimatedSwitcher ×1 | widget |
| lib/app_versions/v1/features/onboarding/presentation/widgets/health_chip.dart | 02_splash_onboarding | Colors.* ×1 | widget |
| lib/app_versions/v1/features/onboarding/presentation/widgets/nabi_onboarding_experience.dart | 02_splash_onboarding | duration raw ×2, Colors.* ×2, haptic trực tiếp ×1, AnimationController ×6, AnimatedSwitcher ×1 | widget |
| lib/app_versions/v1/features/onboarding/presentation/widgets/onboarding_chip.dart | 02_splash_onboarding | Colors.* ×1 | widget |
| lib/app_versions/v1/features/onboarding/presentation/widgets/onboarding_compact_ui.dart | 02_splash_onboarding | Colors.* ×3, haptic trực tiếp ×3, AnimatedSwitcher ×1 | widget |
| lib/app_versions/v1/features/onboarding/presentation/widgets/onboarding_step_shell.dart | 02_splash_onboarding | duration raw ×1 | widget |
| lib/app_versions/v1/features/onboarding/presentation/widgets/result_step.dart | 02_splash_onboarding | duration raw ×1, Colors.* ×1 | widget |
| lib/app_versions/v1/features/onboarding/presentation/widgets/review_step.dart | 02_splash_onboarding | Colors.* ×1 | widget |
| lib/app_versions/v1/features/settings/presentation/pages/settings_page.dart | 09_auth_profile_settings | Colors.* ×2 | page |
| lib/app_versions/v1/features/splash/presentation/pages/splash_page.dart | 02_splash_onboarding | duration raw ×2, Colors.* ×2, AnimationController ×17 | page |
| lib/app_versions/v1/shared/widgets/ai_chat_fab.dart | 04_ai_chat_voice | duration raw ×2, Colors.* ×1, haptic trực tiếp ×4, AnimationController ×6 | widget |
| lib/app_versions/v2/features/auth/presentation/pages/auth_pages.dart | 09_auth_profile_settings | Colors.* ×1, AnimatedSwitcher ×1 | page |
| lib/core/theme/app_animations.dart | 01_foundation_shell | duration raw ×1, AnimatedSwitcher ×1 | theme |
| lib/core/theme/app_colors.dart | 01_foundation_shell | Color raw ×88 | theme |
| lib/core/theme/app_decoration.dart | 01_foundation_shell | Color raw ×2, Colors.* ×2 | theme |
| lib/core/theme/app_duration.dart | 01_foundation_shell | duration raw ×37 | theme |
| lib/core/theme/app_gradients.dart | 01_foundation_shell | Color raw ×58 | theme |
| lib/core/theme/app_motion.dart | 01_foundation_shell | AnimationController ×2 | theme |
| lib/core/theme/app_shadows.dart | 01_foundation_shell | Color raw ×26 | theme |
| lib/core/theme/app_theme.dart | 01_foundation_shell | duration raw ×1, Color raw ×2, Colors.* ×15 | theme |
| lib/core/theme/foundation/colors.dart | 01_foundation_shell | Color raw ×33, Colors.* ×2 | token |
| lib/core/theme/foundation/motion.dart | 01_foundation_shell | duration raw ×3 | token |
| lib/core/theme/foundation/shadows.dart | 01_foundation_shell | Color raw ×5 | token |
| lib/core/theme/medical_ui.dart | 01_foundation_shell | duration raw ×1, Colors.* ×1 | theme |
| lib/core/theme/primitives/button.dart | 01_foundation_shell | Colors.* ×3 | primitive |
| lib/core/theme/primitives/card.dart | 01_foundation_shell | Colors.* ×1 | primitive |
| lib/core/theme/primitives/chip.dart | 01_foundation_shell | Colors.* ×1 | primitive |
| lib/core/theme/primitives/states/loading_state.dart | 01_foundation_shell | AnimationController ×2 | primitive |
| lib/core/theme/tokens/color_tokens.dart | 01_foundation_shell | Color raw ×8 | token |
| lib/core/theme/tokens/component_tokens.dart | 01_foundation_shell | duration raw ×4 | token |
| lib/features/nabi/presentation/widgets/nabi_animation_player.dart | 12_nabi_global | AnimationController ×2 | widget |
| lib/features/nabi/presentation/widgets/nabi_assistant_overlay.dart | 12_nabi_global | duration raw ×2, haptic trực tiếp ×2, AnimationController ×2 | widget |
| lib/features/nabi/presentation/widgets/nabi_character.dart | 12_nabi_global | duration raw ×2, AnimationController ×4 | widget |
| lib/features/nabi/presentation/widgets/nabi_floating_mascot.dart | 12_nabi_global | duration raw ×2, haptic trực tiếp ×2 | widget |
| lib/shared/widgets/loading_gen_ai.dart | 08_features_care | duration raw ×6, AnimationController ×6, AnimatedSwitcher ×1 | widget |

## Global blockers

- Không có audio playback service/package trong source audit.
- `pubspec.yaml` khai báo SFX path nhưng snapshot không chứa file audio vật lý.
- Có nhiều API motion/token song song; phải consolidate trước feature migration.
