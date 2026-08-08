# Coding Wave File Manifest

Exact file scope derived from the UI file matrix. W11 cleanup/certification spans all migrated files.

## Green Wellness delta - 2026-08-08

The counts below remain the historical 183-file inventory baseline. The working-tree Green migration also adds or newly exposes:

- `lib/core/theme/app_semantic_colors.dart` - context-aware light/dark semantic color extension.
- `lib/app_versions/v1/features/today_tasks/presentation/pages/today_tasks_page.dart`.
- `lib/app_versions/v1/features/today_tasks/presentation/widgets/today_tasks_states.dart`.
- `lib/app_versions/v1/features/today_tasks/presentation/widgets/today_task_card.dart`.
- V1 wellness and V3 FamilyPlus route deltas recorded in `14_ROUTE_MATRIX.md`.

Regenerate the machine inventory before treating the historical per-wave counts as a current exhaustive file count.

## W1 Foundation
- Files: **37**.

| File | Kind | LOC | Current motion evidence |
| --- | --- | --- | --- |
| lib/core/theme/app_animations.dart | theme | 285 | animated_container\|animated_switcher\|animated_opacity\|animated_scale\|fade_transition\|slide_transition\|scale_transition\|rotation_transition\|raw_duration\|app_motion |
| lib/core/theme/app_colors.dart | theme | 170 | raw_color |
| lib/core/theme/app_decoration.dart | theme | 309 | raw_color\|colors_direct |
| lib/core/theme/app_duration.dart | theme | 120 | raw_duration\|app_motion |
| lib/core/theme/app_experience.dart | theme | 78 | media_query\|text_scale |
| lib/core/theme/app_gradients.dart | theme | 182 | raw_color |
| lib/core/theme/app_icons.dart | theme | 285 | none |
| lib/core/theme/app_motion.dart | theme | 166 | animation_controller\|animated_scale\|fade_transition\|slide_transition\|scale_transition\|app_motion\|ticker\|media_query |
| lib/core/theme/app_radius.dart | theme | 43 | none |
| lib/core/theme/app_shadows.dart | theme | 100 | raw_color |
| lib/core/theme/app_spacing.dart | theme | 144 | none |
| lib/core/theme/app_text_scale.dart | theme | 96 | text_scale |
| lib/core/theme/app_text_styles.dart | theme | 245 | none |
| lib/core/theme/app_theme.dart | theme | 557 | raw_duration\|raw_color\|colors_direct\|app_motion |
| lib/core/theme/app_typography.dart | theme | 257 | media_query |
| lib/core/theme/design_system.dart | theme | 129 | app_motion |
| lib/core/theme/design_system_demo_page.dart | demo | 666 | none |
| lib/core/theme/foundation/colors.dart | token | 94 | raw_color\|colors_direct |
| lib/core/theme/foundation/motion.dart | token | 90 | animated_container\|raw_duration\|app_motion |
| lib/core/theme/foundation/radius.dart | token | 51 | none |
| lib/core/theme/foundation/shadows.dart | token | 120 | raw_color |
| lib/core/theme/foundation/spacing.dart | token | 82 | none |
| lib/core/theme/foundation/typography.dart | token | 63 | none |
| lib/core/theme/medical_ui.dart | theme | 782 | raw_duration\|colors_direct\|semantics\|nabi |
| lib/core/theme/primitives/badge.dart | primitive | 122 | semantics |
| lib/core/theme/primitives/button.dart | primitive | 358 | animated_container\|colors_direct\|app_motion\|semantics\|media_query |
| lib/core/theme/primitives/card.dart | primitive | 223 | animated_container\|colors_direct\|app_motion\|semantics\|media_query |
| lib/core/theme/primitives/chip.dart | primitive | 147 | animated_container\|colors_direct\|app_motion\|semantics\|media_query |
| lib/core/theme/primitives/input.dart | primitive | 272 | none |
| lib/core/theme/primitives/section_header.dart | primitive | 146 | none |
| lib/core/theme/primitives/states/empty_state.dart | primitive | 93 | semantics |
| lib/core/theme/primitives/states/error_state.dart | primitive | 86 | semantics\|nabi |
| lib/core/theme/primitives/states/loading_state.dart | primitive | 209 | animation_controller\|app_motion\|ticker\|semantics\|media_query\|nabi |
| lib/core/theme/theme.dart | theme | 15 | none |
| lib/core/theme/tokens/color_tokens.dart | token | 44 | raw_color |
| lib/core/theme/tokens/component_tokens.dart | token | 370 | animated_container\|raw_duration\|app_motion |
| lib/core/theme/tokens/spacing_tokens.dart | token | 192 | none |

## W2 Shell/Navigation
- Files: **18**.

| File | Kind | LOC | Current motion evidence |
| --- | --- | --- | --- |
| lib/app/app_surface_controller.dart | app_shell | 32 | none |
| lib/app/bio_ai_app.dart | app_shell | 104 | text_scale\|nabi |
| lib/app_versions/admin/app/bio_ai_admin_app.dart | app_shell | 35 | text_scale |
| lib/app_versions/admin/router/admin_route_paths.dart | router | 15 | none |
| lib/app_versions/admin/router/admin_router.dart | router | 53 | none |
| lib/app_versions/v1/app/bio_ai_v1_app.dart | app_shell | 66 | text_scale |
| lib/app_versions/v1/router/router.dart | router | 3 | none |
| lib/app_versions/v1/router/transitions.dart | router | 17 | fade_transition |
| lib/app_versions/v1/router/v1_navigation_service.dart | router | 47 | none |
| lib/app_versions/v1/router/v1_route_guards.dart | router | 65 | none |
| lib/app_versions/v1/router/v1_route_paths.dart | router | 37 | none |
| lib/app_versions/v1/router/v1_router.dart | router | 182 | none |
| lib/app_versions/v2/app/bio_ai_v2_app.dart | app_shell | 98 | text_scale |
| lib/app_versions/v2/router/v2_route_paths.dart | router | 16 | none |
| lib/app_versions/v2/router/v2_router.dart | router | 157 | none |
| lib/app_versions/v3/app/bio_ai_v3_app.dart | app_shell | 64 | text_scale |
| lib/app_versions/v3/router/v3_route_paths.dart | router | 4 | none |
| lib/app_versions/v3/router/v3_router.dart | router | 34 | none |

## W3 Splash/Onboarding
- Files: **22**.

| File | Kind | LOC | Current motion evidence |
| --- | --- | --- | --- |
| lib/app_versions/v1/features/onboarding/presentation/constants/onboarding_options.dart | presentation_support | 487 | none |
| lib/app_versions/v1/features/onboarding/presentation/controllers/onboarding_controller.dart | controller | 702 | none |
| lib/app_versions/v1/features/onboarding/presentation/pages/onboarding_entry_page.dart | page | 370 | nabi |
| lib/app_versions/v1/features/onboarding/presentation/pages/onboarding_page.dart | page | 114 | animated_switcher\|fade_transition\|slide_transition\|raw_duration\|colors_direct\|nabi |
| lib/app_versions/v1/features/onboarding/presentation/pages/onboarding_text_scale_page.dart | page | 121 | text_scale\|nabi |
| lib/app_versions/v1/features/onboarding/presentation/widgets/basic_info_step.dart | widget | 318 | nabi |
| lib/app_versions/v1/features/onboarding/presentation/widgets/conditions_step.dart | widget | 139 | nabi |
| lib/app_versions/v1/features/onboarding/presentation/widgets/consent_step.dart | widget | 204 | animated_container\|animated_switcher\|scale_transition\|haptic\|raw_duration\|colors_direct\|app_motion\|semantics\|nabi |
| lib/app_versions/v1/features/onboarding/presentation/widgets/daily_routine_step.dart | widget | 113 | nabi |
| lib/app_versions/v1/features/onboarding/presentation/widgets/extras_step.dart | widget | 137 | nabi |
| lib/app_versions/v1/features/onboarding/presentation/widgets/goals_step.dart | widget | 83 | nabi |
| lib/app_versions/v1/features/onboarding/presentation/widgets/health_chip.dart | widget | 121 | animated_container\|colors_direct\|app_motion\|semantics\|nabi |
| lib/app_versions/v1/features/onboarding/presentation/widgets/lifestyle_step.dart | widget | 153 | nabi |
| lib/app_versions/v1/features/onboarding/presentation/widgets/nabi_onboarding_experience.dart | widget | 925 | animation_controller\|animated_container\|animated_switcher\|animated_scale\|haptic\|raw_duration\|colors_direct\|app_motion\|ticker\|semantics\|media_query\|image_asset\|nabi |
| lib/app_versions/v1/features/onboarding/presentation/widgets/onboarding_chip.dart | widget | 123 | animated_container\|colors_direct\|app_motion\|semantics\|nabi |
| lib/app_versions/v1/features/onboarding/presentation/widgets/onboarding_compact_ui.dart | widget | 1082 | animated_container\|animated_switcher\|animated_scale\|scale_transition\|haptic\|colors_direct\|app_motion\|semantics\|media_query\|nabi |
| lib/app_versions/v1/features/onboarding/presentation/widgets/onboarding_step_shell.dart | widget | 385 | animated_container\|tween_animation_builder\|raw_duration\|app_motion\|media_query\|nabi\|implicit_animation |
| lib/app_versions/v1/features/onboarding/presentation/widgets/onboarding_text_field.dart | widget | 264 | animated_container\|app_motion\|nabi\|implicit_animation |
| lib/app_versions/v1/features/onboarding/presentation/widgets/result_step.dart | widget | 184 | tween_animation_builder\|raw_duration\|colors_direct\|nabi |
| lib/app_versions/v1/features/onboarding/presentation/widgets/review_step.dart | widget | 569 | colors_direct\|nabi |
| lib/app_versions/v1/features/onboarding/presentation/widgets/welcome_step.dart | widget | 154 | nabi |
| lib/app_versions/v1/features/splash/presentation/pages/splash_page.dart | page | 1380 | animation_controller\|animated_container\|fade_transition\|slide_transition\|raw_duration\|colors_direct\|app_motion\|ticker\|semantics\|media_query\|repaint_boundary\|nabi |

## W4 Dashboard/Menu
- Files: **36**.

| File | Kind | LOC | Current motion evidence |
| --- | --- | --- | --- |
| lib/app_versions/v1/features/dashboard/presentation/controllers/dashboard_controller.dart | controller | 154 | none |
| lib/app_versions/v1/features/dashboard/presentation/enums/insight_type.dart | enum | 1 | none |
| lib/app_versions/v1/features/dashboard/presentation/mappers/dashboard_health_status_mapper.dart | mapper | 76 | none |
| lib/app_versions/v1/features/dashboard/presentation/pages/dashboard_page.dart | page | 284 | nabi |
| lib/app_versions/v1/features/dashboard/presentation/pages/menu_page.dart | page | 564 | animation_controller\|animated_container\|animated_opacity\|animated_scale\|tween_animation_builder\|haptic\|colors_direct\|app_motion\|ticker\|semantics\|repaint_boundary\|nabi\|implicit_animation |
| lib/app_versions/v1/features/dashboard/presentation/utils/dashboard_helpers.dart | utility | 43 | none |
| lib/app_versions/v1/features/dashboard/presentation/widgets/common/section_header.dart | widget | 52 | none |
| lib/app_versions/v1/features/dashboard/presentation/widgets/companion/dashboard_companion_widgets.dart | widget | 807 | animated_container\|app_motion\|media_query\|nabi |
| lib/app_versions/v1/features/dashboard/presentation/widgets/dashboard_content.dart | widget | 265 | nabi\|refresh_indicator |
| lib/app_versions/v1/features/dashboard/presentation/widgets/goals/goal_chip.dart | widget | 40 | none |
| lib/app_versions/v1/features/dashboard/presentation/widgets/goals/goal_chips_grid.dart | widget | 31 | none |
| lib/app_versions/v1/features/dashboard/presentation/widgets/goals/goal_data.dart | widget | 22 | none |
| lib/app_versions/v1/features/dashboard/presentation/widgets/goals/goal_progress_row.dart | widget | 91 | none |
| lib/app_versions/v1/features/dashboard/presentation/widgets/goals/goal_progress_section.dart | widget | 35 | none |
| lib/app_versions/v1/features/dashboard/presentation/widgets/health_status/health_metrics_overview_section.dart | widget | 355 | nabi |
| lib/app_versions/v1/features/dashboard/presentation/widgets/hero/header_stat_pill.dart | widget | 46 | none |
| lib/app_versions/v1/features/dashboard/presentation/widgets/insights/ai_insight_section.dart | widget | 44 | none |
| lib/app_versions/v1/features/dashboard/presentation/widgets/insights/insight_card.dart | widget | 138 | nabi |
| lib/app_versions/v1/features/dashboard/presentation/widgets/insights/insight_data.dart | widget | 18 | none |
| lib/app_versions/v1/features/dashboard/presentation/widgets/lifestyle/conditions_card.dart | widget | 70 | none |
| lib/app_versions/v1/features/dashboard/presentation/widgets/lifestyle/lifestyle_metric_card.dart | widget | 66 | none |
| lib/app_versions/v1/features/dashboard/presentation/widgets/overview/dashboard_overview_widgets.dart | widget | 1005 | tween_animation_builder\|app_motion\|semantics\|media_query\|text_scale |
| lib/app_versions/v1/features/dashboard/presentation/widgets/score/score_metric_row.dart | widget | 40 | colors_direct |
| lib/app_versions/v1/features/dashboard/presentation/widgets/score/score_ring_painter.dart | widget | 67 | raw_color |
| lib/app_versions/v1/features/dashboard/presentation/widgets/sections/dashboard_sections.dart | widget | 1008 | semantics\|nabi |
| lib/app_versions/v1/features/dashboard/presentation/widgets/states/dashboard_error.dart | widget | 48 | none |
| lib/app_versions/v1/features/dashboard/presentation/widgets/states/dashboard_loading.dart | widget | 49 | none |
| lib/app_versions/v1/features/dashboard/presentation/widgets/states/dashboard_state_widgets.dart | widget | 252 | nabi |
| lib/app_versions/v1/features/dashboard/presentation/widgets/states/skeleton_box.dart | widget | 59 | animation_controller\|app_motion\|ticker |
| lib/app_versions/v1/features/dashboard/presentation/widgets/stats/stat_card.dart | widget | 76 | none |
| lib/app_versions/v1/features/dashboard/presentation/widgets/stats/stat_item.dart | widget | 22 | none |
| lib/app_versions/v1/features/dashboard/presentation/widgets/timeline/daily_timeline.dart | widget | 36 | none |
| lib/app_versions/v1/features/dashboard/presentation/widgets/timeline/timeline_event.dart | widget | 18 | none |
| lib/app_versions/v1/features/dashboard/presentation/widgets/timeline/timeline_row.dart | widget | 84 | none |
| lib/app_versions/v1/features/features_hub/presentation/pages/features_hub_page.dart | page | 563 | colors_direct\|semantics\|nabi |
| lib/app_versions/v1/features/features_hub/presentation/widgets/nami_care_page.dart | page | 398 | animated_container\|colors_direct\|app_motion |

## W5 Meal/Nutrition
- Files: **5**.

| File | Kind | LOC | Current motion evidence |
| --- | --- | --- | --- |
| lib/app_versions/v1/features/meal_plan/presentation/controllers/meal_plan_controller.dart | controller | 34 | none |
| lib/app_versions/v1/features/meal_plan/presentation/pages/meal_plan_page.dart | page | 1900 | animation_controller\|animated_container\|animated_scale\|tween_animation_builder\|raw_duration\|colors_direct\|app_motion\|ticker\|semantics\|media_query\|nabi\|refresh_indicator |
| lib/app_versions/v1/features/nutrition/presentation/controllers/nutrition_profile_controller.dart | controller | 42 | none |
| lib/app_versions/v1/features/nutrition/presentation/pages/nutrition_page.dart | page | 911 | nabi\|refresh_indicator |
| lib/app_versions/v1/features/nutrition/presentation/pages/nutrition_profile_editor_page.dart | page | 860 | animated_switcher\|app_motion\|nabi |

## W5 Schedule/Proof
- Files: **6**.

| File | Kind | LOC | Current motion evidence |
| --- | --- | --- | --- |
| lib/app_versions/v1/features/daily_routine/presentation/pages/daily_routine_preferences_page.dart | page | 121 | nabi |
| lib/app_versions/v1/features/daily_routine/presentation/widgets/daily_routine_preferences_editor.dart | widget | 242 | media_query |
| lib/app_versions/v1/features/lifestyle_schedule/presentation/controllers/lifestyle_schedule_controller.dart | controller | 460 | haptic\|nabi |
| lib/app_versions/v1/features/lifestyle_schedule/presentation/controllers/lifestyle_schedule_state.dart | controller | 81 | none |
| lib/app_versions/v1/features/lifestyle_schedule/presentation/pages/lifestyle_schedule_page.dart | page | 1875 | animated_container\|animated_opacity\|animated_scale\|raw_duration\|colors_direct\|app_motion\|semantics\|nabi\|refresh_indicator |
| lib/app_versions/v1/features/lifestyle_schedule/presentation/pages/schedule_proof_gallery_page.dart | page | 386 | nabi |

## W6 AI/Voice
- Files: **5**.

| File | Kind | LOC | Current motion evidence |
| --- | --- | --- | --- |
| lib/app_versions/v1/features/ai_chat/presentation/controllers/ai_chat_controller.dart | controller | 170 | none |
| lib/app_versions/v1/features/ai_chat/presentation/pages/ai_chat_screen.dart | page | 1200 | animation_controller\|animated_container\|animated_switcher\|tween_animation_builder\|haptic\|raw_duration\|colors_direct\|app_motion\|ticker\|semantics\|nabi |
| lib/app_versions/v1/features/ai_voice/presentation/controllers/ai_voice_controller.dart | controller | 162 | none |
| lib/app_versions/v1/features/ai_voice/presentation/pages/ai_voice_page.dart | page | 344 | animated_container\|animated_switcher\|app_motion\|semantics\|nabi |
| lib/app_versions/v1/shared/widgets/ai_chat_fab.dart | widget | 493 | animation_controller\|animated_container\|animated_opacity\|animated_scale\|haptic\|raw_duration\|colors_direct\|app_motion\|ticker\|semantics\|media_query\|repaint_boundary\|nabi |

## W6 AI/Nabi
- Files: **11**.

| File | Kind | LOC | Current motion evidence |
| --- | --- | --- | --- |
| lib/app_versions/v1/features/nabi/presentation/nabi_page_mixin.dart | presentation_support | 76 | nabi |
| lib/app_versions/v1/features/nabi/presentation/nabi_route_observer.dart | presentation_support | 57 | nabi |
| lib/app_versions/v1/features/nabi/presentation/widgets/nabi_character_widget.dart | widget | 1022 | animation_controller\|raw_duration\|app_motion\|ticker\|semantics\|image_asset\|nabi |
| lib/app_versions/v1/features/nabi/presentation/widgets/nabi_floating_overlay.dart | widget | 307 | animation_controller\|animated_switcher\|animated_opacity\|animated_scale\|haptic\|app_motion\|ticker\|media_query\|nabi |
| lib/features/nabi/presentation/navigation/nabi_route_mapper.dart | presentation_support | 43 | nabi |
| lib/features/nabi/presentation/navigation/nabi_route_observer.dart | presentation_support | 47 | nabi |
| lib/features/nabi/presentation/widgets/nabi_animation_player.dart | widget | 155 | animation_controller\|ticker\|repaint_boundary\|image_asset\|nabi |
| lib/features/nabi/presentation/widgets/nabi_app_shell.dart | widget | 29 | nabi |
| lib/features/nabi/presentation/widgets/nabi_assistant_overlay.dart | widget | 310 | animation_controller\|animated_scale\|animated_size\|fade_transition\|scale_transition\|haptic\|raw_duration\|app_motion\|ticker\|semantics\|nabi |
| lib/features/nabi/presentation/widgets/nabi_character.dart | widget | 601 | animation_controller\|raw_duration\|ticker\|repaint_boundary\|nabi |
| lib/features/nabi/presentation/widgets/nabi_floating_mascot.dart | widget | 215 | animated_scale\|haptic\|raw_duration\|app_motion\|semantics\|media_query\|nabi |

## W7 Health Tracking
- Files: **11**.

| File | Kind | LOC | Current motion evidence |
| --- | --- | --- | --- |
| lib/app_versions/v1/features/body_metrics/presentation/pages/body_metrics_page.dart | page | 301 | nabi |
| lib/app_versions/v1/features/daily_health_tracking/presentation/controllers/daily_health_tracking_controller.dart | controller | 88 | haptic |
| lib/app_versions/v1/features/daily_health_tracking/presentation/controllers/daily_health_tracking_state.dart | controller | 31 | none |
| lib/app_versions/v1/features/daily_health_tracking/presentation/pages/daily_health_tracking_page.dart | page | 12 | none |
| lib/app_versions/v1/features/personal_goals/presentation/pages/personal_goals_page.dart | page | 113 | nabi |
| lib/app_versions/v1/features/sleep_tracking/presentation/pages/sleep_tracking_page.dart | page | 24 | none |
| lib/app_versions/v1/features/stress_tracking/presentation/pages/stress_tracking_page.dart | page | 24 | none |
| lib/app_versions/v1/features/water_tracking/presentation/pages/water_tracking_page.dart | page | 117 | nabi |
| lib/app_versions/v1/features/weekly_summary/presentation/pages/weekly_summary_page.dart | page | 92 | nabi |
| lib/app_versions/v2/features/health_scoring/presentation/pages/health_score_habits_page.dart | page | 364 | nabi\|refresh_indicator |
| lib/app_versions/v3/features/advanced_tracking/presentation/pages/advanced_tracking_page.dart | page | 371 | nabi\|refresh_indicator |

## W7 Care/Shared
- Files: **7**.

| File | Kind | LOC | Current motion evidence |
| --- | --- | --- | --- |
| lib/app_versions/v1/features/community/presentation/pages/community_page.dart | page | 24 | none |
| lib/app_versions/v1/features/gentle_care_mode/presentation/pages/gentle_care_mode_page.dart | page | 170 | nabi |
| lib/app_versions/v1/features/other/presentation/pages/other_page.dart | page | 110 | media_query\|refresh_indicator |
| lib/app_versions/v1/features/other/presentation/widgets/health_insights_widgets.dart | widget | 1211 | nabi |
| lib/app_versions/v1/features/quick_care/presentation/pages/quick_care_page.dart | page | 99 | nabi |
| lib/shared/widgets/loading_gen_ai.dart | widget | 520 | animation_controller\|animated_container\|animated_switcher\|fade_transition\|slide_transition\|raw_duration\|app_motion\|ticker\|semantics\|nabi |
| lib/shared/widgets/vietnamese_ui_text.dart | widget | 138 | nabi |

## W8 Auth/Profile/Settings
- Files: **10**.

| File | Kind | LOC | Current motion evidence |
| --- | --- | --- | --- |
| lib/app_versions/v1/features/auth/presentation/pages/v1_auth_entry_page.dart | page | 80 | nabi |
| lib/app_versions/v1/features/profile/presentation/pages/profile_page.dart | page | 737 | media_query\|nabi\|refresh_indicator |
| lib/app_versions/v1/features/profile/presentation/profile_screen.dart | page | 12 | none |
| lib/app_versions/v1/features/settings/presentation/pages/dev_database_viewer_page.dart | page | 904 | refresh_indicator |
| lib/app_versions/v1/features/settings/presentation/pages/settings_page.dart | page | 1243 | colors_direct\|media_query\|text_scale\|nabi\|refresh_indicator |
| lib/app_versions/v1/features/settings/presentation/widgets/font_scale_selector.dart | widget | 99 | semantics\|text_scale\|nabi |
| lib/app_versions/v1/features/settings/presentation/widgets/guest_account_access_card.dart | widget | 81 | none |
| lib/app_versions/v2/features/auth/presentation/controllers/auth_controller.dart | controller | 246 | none |
| lib/app_versions/v2/features/auth/presentation/pages/auth_gate_page.dart | page | 339 | nabi |
| lib/app_versions/v2/features/auth/presentation/pages/auth_pages.dart | page | 1745 | animated_switcher\|colors_direct\|app_motion\|semantics\|media_query\|nabi |

## W9 V2/V3/Membership
- Files: **7**.

| File | Kind | LOC | Current motion evidence |
| --- | --- | --- | --- |
| lib/app_versions/v2/features/cloud_sync/presentation/controllers/user_data_sync_controller.dart | controller | 82 | none |
| lib/app_versions/v2/features/health_modules/presentation/pages/health_module_access_page.dart | page | 170 | nabi |
| lib/app_versions/v2/features/home/presentation/pages/v2_home_page.dart | page | 113 | nabi |
| lib/app_versions/v2/features/payments/presentation/pages/membership_payment_page.dart | page | 557 | semantics |
| lib/app_versions/v2/features/wellness_rewards/presentation/pages/wellness_rewards_page.dart | page | 756 | semantics\|nabi\|refresh_indicator |
| lib/app_versions/v3/features/familyplus/presentation/pages/familyplus_page.dart | page | 280 | none |
| lib/app_versions/v3/features/home/presentation/pages/v3_home_page.dart | page | 99 | nabi |

## W10 Sale/Admin
- Files: **8**.

| File | Kind | LOC | Current motion evidence |
| --- | --- | --- | --- |
| lib/app_versions/admin/features/admin_panel/presentation/controllers/admin_access_controller.dart | controller | 109 | none |
| lib/app_versions/admin/features/admin_panel/presentation/controllers/admin_controller.dart | controller | 338 | nabi |
| lib/app_versions/admin/features/admin_panel/presentation/pages/admin_login_page.dart | page | 618 | animated_switcher\|fade_transition\|scale_transition\|app_motion\|semantics\|media_query\|implicit_animation |
| lib/app_versions/admin/features/admin_panel/presentation/pages/admin_shell_page.dart | page | 3874 | animation_controller\|animated_container\|animated_switcher\|animated_opacity\|animated_scale\|fade_transition\|slide_transition\|colors_direct\|app_motion\|ticker\|semantics\|media_query\|repaint_boundary\|nabi |
| lib/app_versions/admin/features/admin_panel/presentation/widgets/admin_access_gate.dart | widget | 109 | none |
| lib/app_versions/admin/features/wellness_rewards/presentation/admin_wellness_rewards_panel.dart | presentation_support | 856 | nabi |
| lib/sale_referral/presentation/pages/sale_participation_page.dart | page | 368 | none |
| lib/sale_referral/presentation/pages/sale_shell_page.dart | page | 1081 | media_query |
