# UI/UX Screen Inventory — NanoBio Flutter

- Audit baseline: `30587ab9b04d95aa621e5412502aafd0d0ca4827`
- Source of truth: GitHub `daovanhung-dev/NanoBioAI` branch `main` at baseline commit.
- Discovery method: V1/V2/V3/Admin GoRouter trees + `.codex/design/12_UI_FILE_DESIGN_MATRIX.md` + MainNavigation/widget-tree reconciliation.
- Registry reconciliation: repository matrix lists 80 surfaces; audit discovered one additional active logical surface, **Settings tab**, so final logical surface count is **81**.

| ID | Module | Route / entry | Screen / surface | Source | Classification |
|---|---|---|---|---|---|
| V1-01 | Onboarding / Auth | `/` | Splash | `lib/app_versions/v1/features/splash/presentation/pages/splash_page.dart` | route/gate |
| V1-02 | Onboarding / Auth | `/login` | Đăng nhập V1 Entry | `lib/app_versions/v1/features/auth/presentation/pages/v1_auth_entry_page.dart` | route/gate |
| V1-03 | Onboarding / Auth | `/register` | Đăng ký V1 Entry | `lib/app_versions/v1/features/auth/presentation/pages/v1_auth_entry_page.dart` | route/gate |
| V1-04 | Dashboard / Health | `/dashboard` | Dashboard Hôm nay | `lib/app_versions/v1/features/dashboard/presentation/pages/dashboard_page.dart` | route/gate |
| V1-05 | Onboarding / Auth | `/start` | Onboarding Entry | `lib/app_versions/v1/features/onboarding/presentation/pages/onboarding_entry_page.dart` | route/gate |
| V1-06 | Onboarding / Auth | `/onboarding` | Onboarding Journey Shell | `lib/app_versions/v1/features/onboarding/presentation/pages/onboarding_page.dart` | route/gate |
| V1-07 | Foundation / Shell | `/menu` | Main Navigation | `lib/app_versions/v1/features/dashboard/presentation/pages/menu_page.dart` | route/gate |
| V1-08 | AI / Nutrition / Schedule | `/meal-plan` | Meal Plan | `lib/app_versions/v1/features/meal_plan/presentation/pages/meal_plan_page.dart` | route/gate |
| V1-09 | AI / Nutrition / Schedule | `/health-tracking` | Daily Health Tracking Alias | `lib/app_versions/v1/features/daily_health_tracking/presentation/pages/daily_health_tracking_page.dart` | route/gate |
| V1-10 | Dashboard / Health | `/body-metrics` | Body Metrics | `lib/app_versions/v1/features/body_metrics/presentation/pages/body_metrics_page.dart` | route/gate |
| V1-11 | AI / Nutrition / Schedule | `/lifestyle-schedule` | Lifestyle Schedule | `lib/app_versions/v1/features/lifestyle_schedule/presentation/pages/lifestyle_schedule_page.dart` | route/gate |
| V1-12 | Profile / Settings | `/daily-routine-preferences` | Daily Routine Preferences | `lib/app_versions/v1/features/daily_routine/presentation/pages/daily_routine_preferences_page.dart` | route/gate |
| V1-13 | Dashboard / Health | `/sleep-tracking` | Sleep Tracking Preview | `lib/app_versions/v1/features/sleep_tracking/presentation/pages/sleep_tracking_page.dart` | route/gate |
| V1-14 | Dashboard / Health | `/stress-tracking` | Stress Tracking Preview | `lib/app_versions/v1/features/stress_tracking/presentation/pages/stress_tracking_page.dart` | route/gate |
| V1-15 | AI / Nutrition / Schedule | `/ai-chat` | AI Chat | `lib/app_versions/v1/features/ai_chat/presentation/pages/ai_chat_screen.dart` | route/gate |
| V1-16 | AI / Nutrition / Schedule | `/ai-voice` | AI Voice | `lib/app_versions/v1/features/ai_voice/presentation/pages/ai_voice_page.dart` | route/gate |
| V1-17 | AI / Nutrition / Schedule | `/nutrition` | Nutrition | `lib/app_versions/v1/features/nutrition/presentation/pages/nutrition_page.dart` | route/gate |
| V1-18 | AI / Nutrition / Schedule | `/nutrition-profile` | Nutrition Profile Editor | `lib/app_versions/v1/features/nutrition/presentation/pages/nutrition_profile_editor_page.dart` | route/gate |
| V1-19 | Profile / Settings | `/profile` | Profile | `lib/app_versions/v1/features/profile/presentation/pages/profile_page.dart` | route/gate |
| V1-20 | Dashboard / Health | `/community` | Community Preview | `lib/app_versions/v1/features/community/presentation/pages/community_page.dart` | route/gate |
| V1-21 | Dashboard / Health | `/today-tasks` | Today Tasks | `lib/app_versions/v1/features/today_tasks/presentation/pages/today_tasks_page.dart` | route/gate |
| ONB-01 | Onboarding / Auth | `/onboarding (gate)` | Text Scale Setup | `lib/app_versions/v1/features/onboarding/presentation/pages/onboarding_text_scale_page.dart` | route/gate |
| ONB-02 | Onboarding / Auth | `/onboarding step 0` | Welcome Step | `lib/app_versions/v1/features/onboarding/presentation/widgets/welcome_step.dart` | internal/sub-surface |
| ONB-03 | Onboarding / Auth | `/onboarding step 1` | Basic Info Step | `lib/app_versions/v1/features/onboarding/presentation/widgets/basic_info_step.dart` | internal/sub-surface |
| ONB-04 | Onboarding / Auth | `/onboarding step 2` | Goals Step | `lib/app_versions/v1/features/onboarding/presentation/widgets/goals_step.dart` | internal/sub-surface |
| ONB-05 | Onboarding / Auth | `/onboarding step 3` | Conditions Step | `lib/app_versions/v1/features/onboarding/presentation/widgets/conditions_step.dart` | internal/sub-surface |
| ONB-06 | Onboarding / Auth | `/onboarding step 4` | Lifestyle Step | `lib/app_versions/v1/features/onboarding/presentation/widgets/lifestyle_step.dart` | internal/sub-surface |
| ONB-07 | Onboarding / Auth | `/onboarding step 5` | Extras Step | `lib/app_versions/v1/features/onboarding/presentation/widgets/extras_step.dart` | internal/sub-surface |
| ONB-08 | Onboarding / Auth | `/onboarding step 6` | Daily Routine Step | `lib/app_versions/v1/features/onboarding/presentation/widgets/daily_routine_step.dart` | internal/sub-surface |
| ONB-09 | Onboarding / Auth | `/onboarding step 7` | Consent Step | `lib/app_versions/v1/features/onboarding/presentation/widgets/consent_step.dart` | internal/sub-surface |
| ONB-10 | Onboarding / Auth | `/onboarding step 8` | Review Step | `lib/app_versions/v1/features/onboarding/presentation/widgets/review_step.dart` | internal/sub-surface |
| ONB-11 | Onboarding / Auth | `source-only` | Result Step | `lib/app_versions/v1/features/onboarding/presentation/widgets/result_step.dart` | source-only |
| V1-X01 | Dashboard / Health | `/menu (tab)` | Features Hub | `lib/app_versions/v1/features/features_hub/presentation/pages/features_hub_page.dart` | internal/sub-surface |
| V1-X02 | Dashboard / Health | `/menu (tab)` | Health Insights / Góc Nabi | `lib/app_versions/v1/features/other/presentation/pages/other_page.dart` | internal/sub-surface |
| V1-X03 | AI / Nutrition / Schedule | `Navigator sub-surface` | Schedule Proof Gallery | `lib/app_versions/v1/features/lifestyle_schedule/presentation/pages/schedule_proof_gallery_page.dart` | internal/sub-surface |
| V1-X04 | Profile / Settings | `source-only` | Dev Database Viewer | `lib/app_versions/v1/features/settings/presentation/pages/dev_database_viewer_page.dart` | source-only |
| V1-X05 | Dashboard / Health | `/water-tracking` | Water Tracking | `lib/app_versions/v1/features/water_tracking/presentation/pages/water_tracking_page.dart` | route/gate |
| V1-X06 | Dashboard / Health | `/weekly-summary` | Weekly Summary | `lib/app_versions/v1/features/weekly_summary/presentation/pages/weekly_summary_page.dart` | route/gate |
| V1-X07 | Dashboard / Health | `/quick-care` | Quick Care | `lib/app_versions/v1/features/quick_care/presentation/pages/quick_care_page.dart` | route/gate |
| V1-X08 | Dashboard / Health | `/gentle-care` | Gentle Care Mode | `lib/app_versions/v1/features/gentle_care_mode/presentation/pages/gentle_care_mode_page.dart` | route/gate |
| V1-X09 | Dashboard / Health | `/personal-goals` | Personal Goals | `lib/app_versions/v1/features/personal_goals/presentation/pages/personal_goals_page.dart` | route/gate |
| V1-X10 | Dashboard / Health | `/nami-care` | Nami Care Page | `lib/app_versions/v1/features/features_hub/presentation/widgets/nami_care_page.dart` | route/gate |
| DISC-01 | Profile / Settings | `/menu (tab Của bạn)` | Settings tab | `lib/app_versions/v1/features/settings/presentation/pages/settings_page.dart` | discovered-runtime |
| V2-01 | V2/V3 Access | `/auth-gate` | Auth Gate | `lib/app_versions/v2/features/auth/presentation/pages/auth_gate_page.dart` | route/gate |
| V2-02 | V2/V3 Access | `/auth/login` | Login | `lib/app_versions/v2/features/auth/presentation/pages/auth_pages.dart` | route/gate |
| V2-03 | V2/V3 Access | `/auth/register` | Register | `lib/app_versions/v2/features/auth/presentation/pages/auth_pages.dart` | route/gate |
| V2-04 | V2/V3 Access | `/auth/verify-email` | Verify Email | `lib/app_versions/v2/features/auth/presentation/pages/auth_pages.dart` | route/gate |
| V2-05 | V2/V3 Access | `/auth/forgot-password` | Forgot Password | `lib/app_versions/v2/features/auth/presentation/pages/auth_pages.dart` | route/gate |
| V2-06 | V2/V3 Access | `/auth/reset-password` | Reset Password | `lib/app_versions/v2/features/auth/presentation/pages/auth_pages.dart` | route/gate |
| V2-07 | V2/V3 Access | `/auth/callback` | Auth Callback | `lib/app_versions/v2/features/auth/presentation/pages/auth_pages.dart` | route/gate |
| V2-08 | Sale | `/v2/sale` | Sale Shell | `lib/sale_referral/presentation/pages/sale_shell_page.dart` | route/gate |
| V2-09 | V2/V3 Access | `/v2/health-score` | Health Score | `lib/app_versions/v2/features/health_scoring/presentation/pages/health_score_habits_page.dart` | route/gate |
| V2-10 | V2/V3 Access | `/v2/health-modules/:moduleId` | Health Module Access | `lib/app_versions/v2/features/health_modules/presentation/pages/health_module_access_page.dart` | route/gate |
| V2-11 | V2/V3 Access | `/v2/payments` | Membership Payment | `lib/app_versions/v2/features/payments/presentation/pages/membership_payment_page.dart` | route/gate |
| V2-12 | V2/V3 Access | `/v2/wellness-rewards` | Wellness Rewards | `lib/app_versions/v2/features/wellness_rewards/presentation/pages/wellness_rewards_page.dart` | route/gate |
| V2-13 | V2/V3 Access | `/v2` | V2 Home | `lib/app_versions/v2/features/home/presentation/pages/v2_home_page.dart` | route/gate |
| V3-01 | V2/V3 Access | `/v3` | V3 Home | `lib/app_versions/v3/features/home/presentation/pages/v3_home_page.dart` | route/gate |
| V3-02 | V2/V3 Access | `/v3/advanced-tracking` | Advanced Tracking | `lib/app_versions/v3/features/advanced_tracking/presentation/pages/advanced_tracking_page.dart` | route/gate |
| V3-03 | V2/V3 Access | `/v3/family-plus` | FamilyPlus | `lib/app_versions/v3/features/familyplus/presentation/pages/familyplus_page.dart` | route/gate |
| SALE-01 | Sale | `/v2/sale sub-surface` | Sale Participation | `lib/sale_referral/presentation/pages/sale_participation_page.dart` | internal/sub-surface |
| SALE-02 | Sale | `/v2/sale internal` | Payout Profile Gate | `lib/sale_referral/presentation/pages/sale_shell_page.dart` | internal/sub-surface |
| SALE-03 | Sale | `/v2/sale tab` | Sale Overview | `lib/sale_referral/presentation/pages/sale_shell_page.dart` | internal/sub-surface |
| SALE-04 | Sale | `/v2/sale tab` | Direct Customers | `lib/sale_referral/presentation/pages/sale_shell_page.dart` | internal/sub-surface |
| SALE-05 | Sale | `/v2/sale tab` | Point Ledger | `lib/sale_referral/presentation/pages/sale_shell_page.dart` | internal/sub-surface |
| SALE-06 | Sale | `/v2/sale tab` | Conversion Tools | `lib/sale_referral/presentation/pages/sale_shell_page.dart` | internal/sub-surface |
| SALE-07 | Sale | `/v2/sale internal` | Referral Code Panel | `lib/sale_referral/presentation/pages/sale_shell_page.dart` | internal/sub-surface |
| ADM-01 | Admin | `/admin/login` | Admin Login | `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_login_page.dart` | route/gate |
| ADM-02 | Admin | `/admin/dashboard` | Admin Dashboard | `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_page.dart + admin_workspace_sections.dart` | route/gate |
| ADM-03 | Admin | `/admin/users` | Admin Users | `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_page.dart + admin_workspace_sections.dart` | route/gate |
| ADM-04 | Admin | `/admin/payments` | Admin Payments | `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_page.dart + admin_workspace_sections.dart` | route/gate |
| ADM-05 | Admin | `/admin/sales` | Admin Sales | `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_page.dart + admin_workspace_sections.dart` | route/gate |
| ADM-06 | Admin | `/admin/sale-conversions` | Admin Sale Conversions | `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_page.dart + admin_workspace_sections.dart` | route/gate |
| ADM-07 | Admin | `/admin/wellness-rewards` | Admin Wellness Rewards | `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_page.dart + admin_workspace_sections.dart` | route/gate |
| ADM-08 | Admin | `/admin/reconciliation` | Admin Reconciliation | `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_page.dart + admin_workspace_sections.dart` | route/gate |
| ADM-09 | Admin | `/admin/plans` | Admin Plans | `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_page.dart + admin_workspace_sections.dart` | route/gate |
| ADM-10 | Admin | `/admin/reports` | Admin Reports | `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_page.dart + admin_workspace_sections.dart` | route/gate |
| ADM-11 | Admin | `/admin/audit` | Admin Audit | `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_page.dart + admin_workspace_sections.dart` | route/gate |
| ADM-12 | Admin | `/admin/config` | Admin Config | `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_page.dart + admin_workspace_sections.dart` | route/gate |
| ADM-X01 | Admin | `/admin/*` | Admin Workspace Shell | `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_shell.dart` | route/gate |
| ADM-X02 | Admin | `/admin/*` | Admin Access Gate | `lib/app_versions/admin/features/admin_panel/presentation/widgets/admin_access_gate.dart` | route/gate |
| ADM-X03 | Admin | `/admin/* modal` | Admin Workspace Dialogs | `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_workspace_dialogs.dart` | internal/sub-surface |

## Navigation inventory

- V1 registered routes: **27**. `V1RoutePaths` and `registeredV1Paths` reconcile at the baseline.
- V2 route entries: **13**, including dynamic health-module detail route.
- V3 unified routes: **3**; standalone V3 router also repeats V2 Login/Payments and V1 Lifestyle Schedule.
- Admin routes: Login + 11 protected workspace routes; protected routes share `AdminWorkspacePage` + `AdminAccessGate`.
- Non-GoRouter surfaces reviewed include onboarding internal steps, Sale tabs/panels, Admin dialogs, proof gallery/viewer, replacement bottom sheets and Nabi overlay.

## Coverage notes

- “Screen reviewed” means route/widget-tree semantics, layout/state/navigation contract and relevant source were reconciled. Several logical screens intentionally share one Dart file (V2 auth, Sale shell tabs, Admin sections).
- The historical design package references a 183-file UI-affecting baseline. This audit reconciled that baseline as a coverage map and directly inspected the current high-impact route/page/shared-widget sources through the GitHub connector. The connector did not provide a local checkout, so runtime rendering/golden screenshots were not executed.