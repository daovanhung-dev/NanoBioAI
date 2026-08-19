# UI File Design Matrix — Re-execution

The repository carries a historical **183-file UI-affecting baseline matrix** plus a working-tree **81 surface registry**. The 81 repository surfaces are distinct from the Stitch reference pairs; neither count is permission to ignore supporting widgets/theme/router files or claim visual acceptance.

Baseline audit commit: `30587ab9b04d95aa621e5412502aafd0d0ca4827`.

| Surface | Group | Source | Classification | Spec |
|---|---|---|---|---|
| V1-01 Splash | 02_onboarding_auth | `lib/app_versions/v1/features/splash/presentation/pages/splash_page.dart` | active-route | [open](screens/v1-01-splash.md) |
| V1-02 Đăng nhập V1 Entry | 02_onboarding_auth | `lib/app_versions/v1/features/auth/presentation/pages/v1_auth_entry_page.dart` | active-route | [open](screens/v1-02-ng-nh-p-v1-entry.md) |
| V1-03 Đăng ký V1 Entry | 02_onboarding_auth | `lib/app_versions/v1/features/auth/presentation/pages/v1_auth_entry_page.dart` | active-route | [open](screens/v1-03-ng-k-v1-entry.md) |
| V1-04 Dashboard Hôm nay | 03_dashboard_health | `lib/app_versions/v1/features/dashboard/presentation/pages/dashboard_page.dart` | active-route | [open](screens/v1-04-dashboard-h-m-nay.md) |
| V1-05 Onboarding Entry | 02_onboarding_auth | `lib/app_versions/v1/features/onboarding/presentation/pages/onboarding_entry_page.dart` | active-route | [open](screens/v1-05-onboarding-entry.md) |
| V1-06 Onboarding Journey Shell | 02_onboarding_auth | `lib/app_versions/v1/features/onboarding/presentation/pages/onboarding_page.dart` | active-route | [open](screens/v1-06-onboarding-journey-shell.md) |
| V1-07 Main Navigation | 01_foundation_shell | `lib/app_versions/v1/features/dashboard/presentation/pages/menu_page.dart` | active-route | [open](screens/v1-07-main-navigation.md) |
| V1-08 Meal Plan | 04_ai_nutrition_schedule | `lib/app_versions/v1/features/meal_plan/presentation/pages/meal_plan_page.dart` | active-route | [open](screens/v1-08-meal-plan.md) |
| V1-09 Daily Health Tracking | 04_ai_nutrition_schedule | `lib/app_versions/v1/features/daily_health_tracking/presentation/pages/daily_health_tracking_page.dart` | active-route | [open](screens/v1-09-daily-health-tracking-alias.md) |
| V1-10 Body Metrics | 03_dashboard_health | `lib/app_versions/v1/features/body_metrics/presentation/pages/body_metrics_page.dart` | active-route | [open](screens/v1-10-body-metrics.md) |
| V1-11 Lifestyle Schedule | 04_ai_nutrition_schedule | `lib/app_versions/v1/features/lifestyle_schedule/presentation/pages/lifestyle_schedule_page.dart` | active-route | [open](screens/v1-11-lifestyle-schedule.md) |
| V1-12 Daily Routine Preferences | 05_profile_settings | `lib/app_versions/v1/features/daily_routine/presentation/pages/daily_routine_preferences_page.dart` | active-route | [open](screens/v1-12-daily-routine-preferences.md) |
| V1-13 Sleep Tracking Preview | 03_dashboard_health | `lib/app_versions/v1/features/sleep_tracking/presentation/pages/sleep_tracking_page.dart` | coming-soon | [open](screens/v1-13-sleep-tracking-preview.md) |
| V1-14 Stress Tracking Preview | 03_dashboard_health | `lib/app_versions/v1/features/stress_tracking/presentation/pages/stress_tracking_page.dart` | coming-soon | [open](screens/v1-14-stress-tracking-preview.md) |
| V1-15 AI Chat | 04_ai_nutrition_schedule | `lib/app_versions/v1/features/ai_chat/presentation/pages/ai_chat_screen.dart` | active-route | [open](screens/v1-15-ai-chat.md) |
| V1-16 AI Voice | 04_ai_nutrition_schedule | `lib/app_versions/v1/features/ai_voice/presentation/pages/ai_voice_page.dart` | active-route | [open](screens/v1-16-ai-voice.md) |
| V1-17 Nutrition | 04_ai_nutrition_schedule | `lib/app_versions/v1/features/nutrition/presentation/pages/nutrition_page.dart` | active-route | [open](screens/v1-17-nutrition.md) |
| V1-18 Nutrition Profile Editor | 04_ai_nutrition_schedule | `lib/app_versions/v1/features/nutrition/presentation/pages/nutrition_profile_editor_page.dart` | active-route | [open](screens/v1-18-nutrition-profile-editor.md) |
| V1-19 Profile | 05_profile_settings | `lib/app_versions/v1/features/profile/presentation/pages/profile_page.dart` | active-route | [open](screens/v1-19-profile.md) |
| V1-20 Community Preview | 03_dashboard_health | `lib/app_versions/v1/features/community/presentation/pages/community_page.dart` | coming-soon | [open](screens/v1-20-community-preview.md) |
| V1-21 Today Tasks | 03_dashboard_health | `lib/app_versions/v1/features/today_tasks/presentation/pages/today_tasks_page.dart` | active-route | [open](screens/v1-21-today-tasks.md) |
| ONB-01 Text Scale Setup | 02_onboarding_auth | `lib/app_versions/v1/features/onboarding/presentation/pages/onboarding_text_scale_page.dart` | source-sub-surface | [open](screens/onb-01-text-scale-setup.md) |
| ONB-02 Welcome Step | 02_onboarding_auth | `lib/app_versions/v1/features/onboarding/presentation/widgets/welcome_step.dart` | internal-step | [open](screens/onb-02-welcome-step.md) |
| ONB-03 Basic Info Step | 02_onboarding_auth | `lib/app_versions/v1/features/onboarding/presentation/widgets/basic_info_step.dart` | internal-step | [open](screens/onb-03-basic-info-step.md) |
| ONB-04 Goals Step | 02_onboarding_auth | `lib/app_versions/v1/features/onboarding/presentation/widgets/goals_step.dart` | internal-step | [open](screens/onb-04-goals-step.md) |
| ONB-05 Conditions Step | 02_onboarding_auth | `lib/app_versions/v1/features/onboarding/presentation/widgets/conditions_step.dart` | internal-step | [open](screens/onb-05-conditions-step.md) |
| ONB-06 Lifestyle Step | 02_onboarding_auth | `lib/app_versions/v1/features/onboarding/presentation/widgets/lifestyle_step.dart` | internal-step | [open](screens/onb-06-lifestyle-step.md) |
| ONB-07 Extras Step | 02_onboarding_auth | `lib/app_versions/v1/features/onboarding/presentation/widgets/extras_step.dart` | internal-step | [open](screens/onb-07-extras-step.md) |
| ONB-08 Daily Routine Step | 02_onboarding_auth | `lib/app_versions/v1/features/onboarding/presentation/widgets/daily_routine_step.dart` | internal-step | [open](screens/onb-08-daily-routine-step.md) |
| ONB-09 Consent Step | 02_onboarding_auth | `lib/app_versions/v1/features/onboarding/presentation/widgets/consent_step.dart` | internal-step | [open](screens/onb-09-consent-step.md) |
| ONB-10 Review Step | 02_onboarding_auth | `lib/app_versions/v1/features/onboarding/presentation/widgets/review_step.dart` | internal-step | [open](screens/onb-10-review-step.md) |
| ONB-11 Result Step | 02_onboarding_auth | `lib/app_versions/v1/features/onboarding/presentation/widgets/result_step.dart` | source-only | [open](screens/onb-11-result-step.md) |
| V1-X01 Features Hub | 03_dashboard_health | `lib/app_versions/v1/features/features_hub/presentation/pages/features_hub_page.dart` | source-sub-surface | [open](screens/v1-x01-features-hub.md) |
| V1-X02 Health Insights / Góc Nabi | 03_dashboard_health | `lib/app_versions/v1/features/other/presentation/pages/other_page.dart` | source-sub-surface | [open](screens/v1-x02-health-insights-g-c-nabi.md) |
| V1-X03 Schedule Proof Gallery | 03_dashboard_health | `lib/app_versions/v1/features/lifestyle_schedule/presentation/pages/schedule_proof_gallery_page.dart` | source-sub-surface | [open](screens/v1-x03-schedule-proof-gallery.md) |
| V1-X04 Dev Database Viewer | 03_dashboard_health | `lib/app_versions/v1/features/settings/presentation/pages/dev_database_viewer_page.dart` | source-only | [open](screens/v1-x04-dev-database-viewer.md) |
| V1-X05 Water Tracking | 03_dashboard_health | `lib/app_versions/v1/features/water_tracking/presentation/pages/water_tracking_page.dart` | active-route | [open](screens/v1-x05-water-tracking.md) |
| V1-X06 Weekly Summary | 03_dashboard_health | `lib/app_versions/v1/features/weekly_summary/presentation/pages/weekly_summary_page.dart` | active-route | [open](screens/v1-x06-weekly-summary.md) |
| V1-X07 Quick Care | 03_dashboard_health | `lib/app_versions/v1/features/quick_care/presentation/pages/quick_care_page.dart` | active-route | [open](screens/v1-x07-quick-care.md) |
| V1-X08 Gentle Care Mode | 03_dashboard_health | `lib/app_versions/v1/features/gentle_care_mode/presentation/pages/gentle_care_mode_page.dart` | active-route | [open](screens/v1-x08-gentle-care-mode.md) |
| V1-X09 Personal Goals | 03_dashboard_health | `lib/app_versions/v1/features/personal_goals/presentation/pages/personal_goals_page.dart` | active-route | [open](screens/v1-x09-personal-goals.md) |
| V1-X10 Nabi Care Page | 03_dashboard_health | `lib/app_versions/v1/features/features_hub/presentation/widgets/nami_care_page.dart` | active-route | [open](screens/v1-x10-nami-care-page.md) |
| V1-X11 Settings / Của bạn | 05_profile_settings | `lib/app_versions/v1/features/settings/presentation/pages/settings_page.dart` | source-sub-surface | [open](screens/v1-x11-settings.md) |
| V2-01 Auth Gate | 06_v2_v3_access | `lib/app_versions/v2/features/auth/presentation/pages/auth_gate_page.dart` | gate | [open](screens/v2-01-auth-gate.md) |
| V2-02 Login | 06_v2_v3_access | `lib/app_versions/v2/features/auth/presentation/pages/auth_pages.dart` | active-route | [open](screens/v2-02-login.md) |
| V2-03 Register | 06_v2_v3_access | `lib/app_versions/v2/features/auth/presentation/pages/auth_pages.dart` | active-route | [open](screens/v2-03-register.md) |
| V2-04 Verify Email | 06_v2_v3_access | `lib/app_versions/v2/features/auth/presentation/pages/auth_pages.dart` | active-route | [open](screens/v2-04-verify-email.md) |
| V2-05 Forgot Password | 06_v2_v3_access | `lib/app_versions/v2/features/auth/presentation/pages/auth_pages.dart` | active-route | [open](screens/v2-05-forgot-password.md) |
| V2-06 Reset Password | 06_v2_v3_access | `lib/app_versions/v2/features/auth/presentation/pages/auth_pages.dart` | active-route | [open](screens/v2-06-reset-password.md) |
| V2-07 Auth Callback | 06_v2_v3_access | `lib/app_versions/v2/features/auth/presentation/pages/auth_pages.dart` | active-route | [open](screens/v2-07-auth-callback.md) |
| V2-08 Sale Shell | 06_v2_v3_access | `lib/sale_referral/presentation/pages/sale_shell_page.dart` | active-route | [open](screens/v2-08-sale-shell.md) |
| V2-09 Health Score | 06_v2_v3_access | `lib/app_versions/v2/features/health_scoring/presentation/pages/health_score_habits_page.dart` | active-route | [open](screens/v2-09-health-score.md) |
| V2-10 Health Module Access | 06_v2_v3_access | `lib/app_versions/v2/features/health_modules/presentation/pages/health_module_access_page.dart` | active-route | [open](screens/v2-10-health-module-access.md) |
| V2-11 Membership Payment | 06_v2_v3_access | `lib/app_versions/v2/features/payments/presentation/pages/membership_payment_page.dart` | active-route | [open](screens/v2-11-membership-payment.md) |
| V2-12 Wellness Rewards | 06_v2_v3_access | `lib/app_versions/v2/features/wellness_rewards/presentation/pages/wellness_rewards_page.dart` | active-route | [open](screens/v2-12-wellness-rewards.md) |
| V2-13 V2 Home | 06_v2_v3_access | `lib/app_versions/v2/features/home/presentation/pages/v2_home_page.dart` | active-route | [open](screens/v2-13-v2-home.md) |
| V3-01 V3 Home | 06_v2_v3_access | `lib/app_versions/v3/features/home/presentation/pages/v3_home_page.dart` | active-route | [open](screens/v3-01-v3-home.md) |
| V3-02 Advanced Tracking | 06_v2_v3_access | `lib/app_versions/v3/features/advanced_tracking/presentation/pages/advanced_tracking_page.dart` | active-route | [open](screens/v3-02-advanced-tracking.md) |
| V3-03 FamilyPlus | 06_v2_v3_access | `lib/app_versions/v3/features/familyplus/presentation/pages/familyplus_page.dart` | active-route | [open](screens/v3-03-familyplus.md) |
| SALE-01 Sale Participation | 07_sale | `lib/sale_referral/presentation/pages/sale_participation_page.dart` | source-sub-surface | [open](screens/sale-01-sale-participation.md) |
| SALE-02 Payout Profile Gate | 07_sale | `lib/sale_referral/presentation/pages/sale_shell_page.dart` (`_SalePayoutProfileGate`) | internal-surface | [open](screens/sale-02-payout-profile-gate.md) |
| SALE-03 Sale Overview | 07_sale | `lib/sale_referral/presentation/pages/sale_shell_page.dart` (`_OverviewTab`) | internal-surface | [open](screens/sale-03-sale-overview.md) |
| SALE-04 Direct Customers | 07_sale | `lib/sale_referral/presentation/pages/sale_shell_page.dart` (`_DirectCustomersTab`) | internal-surface | [open](screens/sale-04-direct-customers.md) |
| SALE-05 Point Ledger | 07_sale | `lib/sale_referral/presentation/pages/sale_shell_page.dart` (`_PointLedgerTab`) | internal-surface | [open](screens/sale-05-point-ledger.md) |
| SALE-06 Conversion Tools | 07_sale | `lib/sale_referral/presentation/pages/sale_shell_page.dart` (`_ConversionToolsTab`) | internal-surface | [open](screens/sale-06-conversion-tools.md) |
| SALE-07 Referral Code Panel | 07_sale | `lib/sale_referral/presentation/pages/sale_shell_page.dart` (`_ReferralCodePanel`) | internal-surface | [open](screens/sale-07-referral-code-panel.md) |
| ADM-01 Admin Login | 08_admin | `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_login_page.dart` | active-route | [open](screens/adm-01-admin-login.md) |
| ADM-02 Admin Dashboard | 08_admin | `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_page.dart + admin_workspace_sections.dart` | active-route | [open](screens/adm-02-admin-dashboard.md) |
| ADM-03 Admin Users | 08_admin | `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_page.dart + admin_workspace_sections.dart` | active-route | [open](screens/adm-03-admin-users.md) |
| ADM-04 Admin Payments | 08_admin | `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_page.dart + admin_workspace_sections.dart` | active-route | [open](screens/adm-04-admin-payments.md) |
| ADM-05 Admin Sales | 08_admin | `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_page.dart + admin_workspace_sections.dart` | active-route | [open](screens/adm-05-admin-sales.md) |
| ADM-06 Admin Sale Conversions | 08_admin | `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_page.dart + admin_workspace_sections.dart` | active-route | [open](screens/adm-06-admin-sale-conversions.md) |
| ADM-07 Admin Wellness Rewards | 08_admin | `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_page.dart + admin_workspace_sections.dart` | active-route | [open](screens/adm-07-admin-wellness-rewards.md) |
| ADM-08 Admin Reconciliation | 08_admin | `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_page.dart + admin_workspace_sections.dart` | active-route | [open](screens/adm-08-admin-reconciliation.md) |
| ADM-09 Admin Plans | 08_admin | `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_page.dart + admin_workspace_sections.dart` | active-route | [open](screens/adm-09-admin-plans.md) |
| ADM-10 Admin Reports | 08_admin | `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_page.dart + admin_workspace_sections.dart` | active-route | [open](screens/adm-10-admin-reports.md) |
| ADM-11 Admin Audit | 08_admin | `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_page.dart + admin_workspace_sections.dart` | active-route | [open](screens/adm-11-admin-audit.md) |
| ADM-12 Admin Config | 08_admin | `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_page.dart + admin_workspace_sections.dart` | active-route | [open](screens/adm-12-admin-config.md) |
| ADM-X01 Admin Workspace Shell | 08_admin | `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_shell.dart` | source-sub-surface | [open](screens/adm-x01-admin-workspace-shell.md) |
| ADM-X02 Admin Access Gate | 08_admin | `lib/app_versions/admin/features/admin_panel/presentation/widgets/admin_access_gate.dart` | gate | [open](screens/adm-x02-admin-access-gate.md) |
| ADM-X03 Admin Workspace Dialogs | 08_admin | `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_dialogs.dart` | dialog-surface | [open](screens/adm-x03-admin-workspace-dialogs.md) |

## Coding rule

Before editing a Dart UI file, map it to one of the groups and exact screen/surface spec. Supporting theme/router/widget files remain governed by the existing 183-file baseline requirement and the relevant group contract.
