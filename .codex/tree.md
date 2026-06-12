# NanoBio Project Structure

```text
D:.
|   main.dart
|   
+---app
|       app.dart
|       
+---core
|   |   core.dart
|   |   
|   +---constants
|   |   |   constant.dart
|   |   |   onboarding_constants.dart
|   |   |
|   |   +---api
|   |   |       supabase_constants.dart
|   |   |
|   |   +---app
|   |   |       app_assets.dart
|   |   |       app_constants.dart
|   |   |       app_duration.dart
|   |   |       app_radius.dart
|   |   |       app_spacing.dart
|   |   |       app_strings.dart
|   |   |
|   |   +---enums
|   |   |       gender_enum.dart
|   |   |
|   |   +---health
|   |   |       bmi_constants.dart
|   |   |       nutrition_constants.dart
|   |   |
|   |   +---network
|   |   |       endpoint_constants.dart
|   |   |
|   |   +---routes
|   |   |       route_names.dart
|   |   |
|   |   +---storage
|   |   |       storage_keys.dart
|   |   |
|   |   \---validation
|   |           regex_constants.dart
|   |
|   +---interfaces
|   |       health_data_interface.dart
|   |
|   +---network
|   |       dio_provider.dart
|   |
|   +---router
|   |       app_router.dart
|   |       navigation_service.dart
|   |       router.dart
|   |       route_guards.dart
|   |       transitions.dart
|   |
|   +---storage
|   |   \---localdb
|   |       |   app_prefs.dart
|   |       |   database_constants.dart
|   |       |   database_service.dart
|   |       |   database_version.dart
|   |       |
|   |       +---daos
|   |       |       ai_insights_dao.dart
|   |       |       ai_recommendations_dao.dart
|   |       |       food_allergies_dao.dart
|   |       |       health_conditions_dao.dart
|   |       |       health_goals_dao.dart
|   |       |       health_profiles_dao.dart
|   |       |       health_tracking_logs_dao.dart
|   |       |       lifestyle_habits_dao.dart
|   |       |       meal_plan_dao.dart
|   |       |       medical_treatments_dao.dart
|   |       |       notifications_dao.dart
|   |       |       nutrition_logs_dao.dart
|   |       |       survey_answers_dao.dart
|   |       |       users_dao.dart
|   |       |
|   |       +---migrations
|   |       |       migration_manager.dart
|   |       |       migration_v1.dart
|   |       |
|   |       +---models
|   |       |       ai_insight_model.dart
|   |       |       ai_recommendation_model.dart
|   |       |       food_allergy_model.dart
|   |       |       health_condition_model.dart
|   |       |       health_goal_model.dart
|   |       |       health_profile_model.dart
|   |       |       health_tracking_log_model.dart
|   |       |       lifestyle_habit_model.dart
|   |       |       meal_plan_model.dart
|   |       |       medical_treatment_model.dart
|   |       |       notification_model.dart
|   |       |       nutrition_log_model.dart
|   |       |       survey_answer_model.dart
|   |       |       user_model.dart
|   |       |
|   |       \---tables
|   |               ai_insights_table.dart
|   |               ai_recommendations_table.dart
|   |               food_allergies_table.dart
|   |               health_conditions_table.dart
|   |               health_goals_table.dart
|   |               health_profiles_table.dart
|   |               health_tracking_logs_table.dart
|   |               lifestyle_habits_table.dart
|   |               meal_plans_table.dart
|   |               medical_treatments_table.dart
|   |               notifications_table.dart
|   |               nutrition_logs_table.dart
|   |               survey_answers_table.dart
|   |               users_table.dart
|   |
|   +---theme
|   |       app_animations.dart
|   |       app_colors.dart
|   |       app_decoration.dart
|   |       app_duration.dart
|   |       app_gradients.dart
|   |       app_icons.dart
|   |       app_radius.dart
|   |       app_shadows.dart
|   |       app_spacing.dart
|   |       app_text_styles.dart
|   |       app_theme.dart
|   |       app_typography.dart
|   |       theme.dart
|   |
|   \---utils
|           .gitkeep
|
+---features
|   +---ai_chat
|   |   \---presentation
|   |       |   ai_chat_screen.dart
|   |       |
|   |       \---pages
|   |               ai_chat_page.dart
|   |
|   +---auth
|   |   |   auth.dart
|   |   |
|   |   +---data
|   |   |   +---datasource
|   |   |   |       auth_remote_datasource.dart
|   |   |   |
|   |   |   \---models
|   |   |           user_model.dart
|   |   |
|   |   +---domain
|   |   |   \---repositories
|   |   |           auth_repository.dart
|   |   |           auth_repository_impl.dart
|   |   |
|   |   +---presentation
|   |   |   +---controllers
|   |   |   |       login_controller.dart
|   |   |   |
|   |   |   \---pages
|   |   |           login_pages.dart
|   |   |
|   |   \---providers
|   |           auth_provider.dart
|   |
|   +---community
|   |   |   .gitkeep
|   |   |
|   |   \---presentation
|   |       \---pages
|   |               community_page.dart
|   |
|   +---dashboard
|   |   |   dashboard.dart
|   |   |
|   |   +---data
|   |   |   \---datasources
|   |   |           dashboard_local_datasource.dart
|   |   |
|   |   +---domain
|   |   |   +---entities
|   |   |   |       dashboard_entity.dart
|   |   |   |
|   |   |   \---repositories
|   |   |           dashboard_repository.dart
|   |   |           dashboard_repository_impl.dart
|   |   |
|   |   +---presentation
|   |   |   +---controllers
|   |   |   |       dashboard_controller.dart
|   |   |   |
|   |   |   +---enums
|   |   |   |       insight_type.dart
|   |   |   |
|   |   |   +---models
|   |   |   |       dashboard_mock_stats.dart
|   |   |   |
|   |   |   +---pages
|   |   |   |       dashboard_page.dart
|   |   |   |       menu_page.dart
|   |   |   |
|   |   |   +---utils
|   |   |   |       dashboard_helpers.dart
|   |   |   |
|   |   |   \---widgets
|   |   |       +---common
|   |   |       |       section_header.dart
|   |   |       |
|   |   |       +---goals
|   |   |       |       goal_chip.dart
|   |   |       |       goal_chips_grid.dart
|   |   |       |       goal_data.dart
|   |   |       |       goal_progress_row.dart
|   |   |       |       goal_progress_section.dart
|   |   |       |
|   |   |       +---hero
|   |   |       |       header_stat_pill.dart
|   |   |       |       hero_header.dart
|   |   |       |
|   |   |       +---insights
|   |   |       |       ai_insight_section.dart
|   |   |       |       insight_card.dart
|   |   |       |       insight_data.dart
|   |   |       |
|   |   |       +---lifestyle
|   |   |       |       conditions_card.dart
|   |   |       |       lifestyle_metric_card.dart
|   |   |       |       smart_lifestyle_section.dart
|   |   |       |
|   |   |       +---score
|   |   |       |       health_score_card.dart
|   |   |       |       score_metric_row.dart
|   |   |       |       score_ring_painter.dart
|   |   |       |
|   |   |       +---states
|   |   |       |       dashboard_error.dart
|   |   |       |       dashboard_loading.dart
|   |   |       |       skeleton_box.dart
|   |   |       |
|   |   |       +---stats
|   |   |       |       quick_stats_grid.dart
|   |   |       |       stat_card.dart
|   |   |       |       stat_item.dart
|   |   |       |
|   |   |       \---timeline
|   |   |               daily_timeline.dart
|   |   |               timeline_event.dart
|   |   |               timeline_row.dart
|   |   |
|   |   \---providers
|   |           dashboard_provider.dart
|   |
|   +---meal_plan
|   |   \---dashboard
|   |       +---data
|   |       |   \---datasources
|   |       |           meal_datasource.dart
|   |       |
|   |       +---domain
|   |       |   \---repositories
|   |       |           meal_plan_repository.dart
|   |       |           meal_plan_repository_impl.dart
|   |       |
|   |       +---presentation
|   |       |   +---controllers
|   |       |   |       meal_plan_controller.dart
|   |       |   |
|   |       |   \---pages
|   |       |           meal_plan_page.dart
|   |       |
|   |       \---providers
|   |               meal_plan_provider.dart
|   |
|   +---nutrition
|   |   |   .gitkeep
|   |   |
|   |   \---presentation
|   |       \---pages
|   |               nutrition_page.dart
|   |
|   +---onboarding
|   |   |   onboarding.dart
|   |   |
|   |   +---data
|   |   |   +---datasource
|   |   |   |       onboarding_local_datasource.dart
|   |   |   |
|   |   |   \---models
|   |   |           onboarding_model.dart
|   |   |
|   |   +---domain
|   |   |   +---entities
|   |   |   |       onboarding_entity.dart
|   |   |   |
|   |   |   \---repositories
|   |   |           ai_repository.dart
|   |   |           onboarding_repository.dart
|   |   |           onboarding_repository_impl.dart
|   |   |
|   |   +---presentation
|   |   |   +---controllers
|   |   |   |       onboarding_controller.dart
|   |   |   |
|   |   |   +---pages
|   |   |   |       onboarding_page.dart
|   |   |   |
|   |   |   \---widgets
|   |   |           basic_info_step.dart
|   |   |           conditions_step.dart
|   |   |           extras_step.dart
|   |   |           goals_step.dart
|   |   |           health_chip.dart
|   |   |           lifestyle_step.dart
|   |   |           onboarding_chip.dart
|   |   |           onboarding_step_shell.dart
|   |   |           onboarding_text_field.dart
|   |   |           result_step.dart
|   |   |           review_step.dart
|   |   |           welcome_step.dart
|   |   |
|   |   \---providers
|   |           onboarding_provider.dart
|   |           repository_providers.dart
|   |
|   +---other
|   |   \---presentation
|   |       \---pages
|   |               other_page.dart
|   |
|   +---profile
|   |   \---presentation
|   |       |   profile_screen.dart
|   |       |
|   |       \---pages
|   |               profile_page.dart
|   |
|   +---settings
|   |   \---presentation
|   |       \---pages
|   |               settings_page.dart
|   |
|   +---sleep_tracking
|   |   |   .gitkeep
|   |   |
|   |   \---presentation
|   |       \---pages
|   |               sleep_tracking_page.dart
|   |
|   +---splash
|   |   |   splash.dart
|   |   |
|   |   +---presentation
|   |   |   \---pages
|   |   |           splash_page.dart
|   |   |
|   |   \---providers
|   |           splash_provider.dart
|   |           splash_state.dart
|   |
|   \---stress_tracking
|       \---presentation
|           \---pages
|                   stress_tracking_page.dart
|
+---services
|   +---ai
|   |   |   ai_service.dart
|   |   |
|   |   +---models
|   |   |       ai_meal_response_model.dart
|   |   |
|   |   +---prompts
|   |   |       nutrition_prompt.dart
|   |   |
|   |   \---providers
|   |           ai_provider.dart
|   |
|   +---notification
|   |       .gitkeep
|   |
|   \---supabase
|           auth_service.dart
|           supabase_service.dart
|
\---shared
    \---widgets
            health_card.dart
            loading_genAI.dart

```

## Architecture

### Core Layer

* Constants
* Theme System
* Routing
* Local Database (SQLite/Drift)
* Network

### Feature Layer

Mỗi feature tuân theo cấu trúc:

```text
feature/
├── data/
├── domain/
├── presentation/
└── providers/
```

### Service Layer

* AI Service
* Notification Service
* Supabase Service

### Shared Layer

* Reusable Widgets
* Common Components

```
```
