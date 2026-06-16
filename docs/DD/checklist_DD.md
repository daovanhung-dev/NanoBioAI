# Checklist DD - Model da coding

Cap nhat ngay: 2026-06-16

Pham vi doi chieu:
- Tai lieu nguon: `docs/DD/DD_Module/**`
- Code doi chieu: `lib/features/**`, `lib/core/storage/localdb/**`, `lib/services/ai/**`
- Quy uoc trang thai:
  - `[x]` Da co model/entity va dang duoc flow chinh su dung.
  - `[~]` Da co mot phan, nhung chua du contract theo DD hoac model chi la placeholder.
  - `[ ]` Chua thay model/entity rieng trong code.

## Tong quan theo module

| Module DD | Trang thai model | Model/entity da coding | Ghi chu |
| --- | --- | --- | --- |
| 01 - Profile Assessment | `[x]` | `OnboardingEntity`, `OnboardingModel`, `DashboardEntity`, `UserProfileEntity`, `UserProfileModel` | Da co model cho onboarding/profile va flow luu-doc SQLite. Du lieu duoc tach ra cac bang `users`, `health_profiles`, `health_goals`, `health_conditions`, `lifestyle_habits`, `food_allergies`, `medical_treatments`, `survey_answers`. Cac localdb model rieng cho cac bang nay hien phan lon chi co `id`, nen logic that dang nam trong datasource/table map. |
| 02 - Personalized MealPlan 30 Days | `[~]` | `MealPlanEntity`, `MealPlanModel`, `MealPlanModelAI` | Da co model thuc don day du field dinh duong va mapping JSON/SQLite. Tuy nhien code hien tai sinh meal plan theo flow 7 ngay, khong phai 30 ngay nhu DD. `MealPlanModelAI` bi trung y nghia voi `MealPlanModel`. |
| 03 - MealPlan Storage | `[x]` | `MealPlanModel`, `MealPlanEntity` | Da co `meal_plans` table, `MealPlansDao`, `MealPlanLocalDatasource`, `MealPlanRepositoryImpl`. CRUD co insert, insertMany, getAll, getByUserId, getByDate, update, updateCompleted, delete, deleteByUserId. Chua co model chu ky/lich su rieng. |
| 04 - Cycle Refresh After 30 Days | `[ ]` | Chua co model rieng | Chua thay `Cycle`, `PlanCycle`, `RefreshCycle`, `MealPlanCycle` hoac status ket thuc chu ky. Hien co the save lai onboarding va sinh meal moi, nhung chua co model danh dau chu ky cu/moi theo DD. |
| 05 - Daily Health Tracking | `[~]` | `HealthTrackingLogModel`, `NutritionLogModel` | Da co table `health_tracking_logs`, `nutrition_logs`, nhung model chi co field `id`; DAO tuong ung dang TODO va tra `[]`. Chua co model nhiem vu hang ngay, diem/ngay, icon nuoc-than-tam-tri theo DD. |
| 06 - Weekly Summary Scoring | `[ ]` | Chua co model rieng | Chua thay `WeeklySummary`, `WeeklyScore`, `WeeklyReport` model. Dashboard hien co mock stats/insight, nhung khong phai model scoring tuan theo lich thu 6 luc 21:00. |
| 07 - Health Assistant QA | `[x]` | `ChatMessageEntity`, `ChatMessageModel` | Da co model tin nhan chat, role user/assistant, timestamp, JSON mapping. Repository luu history in-memory, chua co persistence table/model lich su chat. |
| 08 - Zalo Special Care Group | `[ ]` | Chua co model rieng | Chua thay model invite/group membership/Zalo channel. |
| 09 - Health Knowledge Base | `[ ]` | Chua co model rieng | Chua thay model article/video/category/knowledge item. |

## Chi tiet model da co trong code

### Module 01 - Profile Assessment

- `[x]` `lib/features/onboarding/domain/entities/onboarding_entity.dart`
  - Field: thong tin ca nhan, chi so co the, muc tieu, benh/van de suc khoe, thoi quen, ngu, van dong, nuoc, di ung, dieu tri, `concernText`, `agreed`.
  - Co getter `bmi`, `hasAllergy`, `hasTreatment`, `toDebugMap`.
- `[x]` `lib/features/onboarding/data/models/onboarding_model.dart`
  - Extend `OnboardingEntity`.
  - Co `fromEntity`.
  - Chua co `fromMap/toMap`; viec map SQLite dang lam truc tiep trong datasource.
- `[x]` `lib/features/dashboard/domain/entities/dashboard_entity.dart`
  - Gom du lieu profile da luu de hien dashboard va lam input cho AI meal plan.
  - Implements `HealthDataInterface`.
- `[x]` `lib/features/settings/domain/entities/user_profile_entity.dart`
  - Profile tong hop tu `users` va `health_profiles`.
- `[x]` `lib/features/settings/data/models/user_profile_model.dart`
  - Co `fromMap`, `fromEntity`, `toMap`, `toUsersTableMap`, `toHealthProfilesTableMap`, `calculateBmi`.
- `[~]` Localdb placeholder models:
  - `UserModel`
  - `HealthProfileModel`
  - `HealthGoalModel`
  - `HealthConditionModel`
  - `LifestyleHabitModel`
  - `FoodAllergyModel`
  - `MedicalTreatmentModel`
  - `SurveyAnswerModel`
  - Cac model nay hien chi co `id/fromMap/toMap`, chua map day du column cua table.

### Module 02 va 03 - Meal Plan va MealPlan Storage

- `[x]` `lib/features/meal_plan/domain/entities/meal_plan_entity.dart`
  - Field: `id`, `userId`, `planDate`, `mealType`, `mealName`, `description`, calories, macro, fiber, water, order, completed, AI flag, timestamps.
  - Co `copyWith`.
- `[x]` `lib/features/meal_plan/data/models/meal_plan_model.dart`
  - Co `fromMap`, `fromJson`, `toMap`, `toJson`, `toEntity`, `fromEntity`, `copyWith`.
  - Dang duoc `AIService`, `DashboardLocalDatasource`, `MealPlansDao` va meal plan repository su dung.
- `[~]` `lib/services/ai/models/ai_meal_response_model.dart`
  - `MealPlanModelAI` co field gan nhu trung `MealPlanModel`.
  - Chua thay la model chinh trong flow meal plan hien tai.
- `[x]` `lib/features/meal_plan/data/daos/meal_plan_dao.dart`
  - DAO da implement cac thao tac doc/ghi chinh cho `meal_plans`.
- `[~]` Gap DD:
  - DD yeu cau 30 ngay va chu ky; code/prompt hien tai dang theo 7 ngay.
  - Chua co model `MealPlanCycle`/`MealPlanHistory` rieng cho chu ky luu tru.

### Module 05 - Daily Health Tracking

- `[~]` `lib/core/storage/localdb/models/health_tracking_log_model.dart`
  - Hien chi co `id`.
  - Table co cac cot that: `weight_kg`, `calories`, `water_ml`, `sleep_hours`, `stress_level`, `steps_count`, `mood`.
- `[~]` `lib/core/storage/localdb/models/nutrition_log_model.dart`
  - Hien chi co `id`.
  - Table co cac cot that: `food_name`, `calories`, `protein`, `carbs`, `fat`, `meal_type`, `eaten_at`.
- `[~]` DAO lien quan:
  - `HealthTrackingLogsDao`
  - `NutritionLogsDao`
  - Cac DAO nay con TODO cho insert/update/delete va `getAll()` tra list rong.
- `[ ]` Chua thay model cho daily task/checklist, daily score, hoac icon state `nuoc/than/tam/tri`.

### Module 06 - Weekly Summary Scoring

- `[ ]` Chua co model rieng cho weekly scoring.
- `[~]` Cac model co the ho tro ve sau nhung hien chua du:
  - `AIInsightModel`: chi co `id`, table co `insight_type`, `title`, `content`, `risk_level`, `created_at`.
  - `AIRecommendationModel`: chi co `id`, table co `recommendation_type`, `title`, `description`, `action_text`, `is_read`, `created_at`.
  - `NotificationModel`: chi co `id`, table co `title`, `body`, `type`, `is_read`, `created_at`.

### Module 07 - Health Assistant QA

- `[x]` `lib/features/ai_chat/domain/entities/chat_message_entity.dart`
  - Field: `id`, `content`, `role`, `timestamp`, `isLoading`.
  - Co `copyWith`, `toJson`, `fromJson`.
- `[x]` `lib/features/ai_chat/data/models/chat_message_model.dart`
  - Extend `ChatMessageEntity`.
  - Co `fromEntity`, `copyWith`, `fromJson`.
- `[~]` Gap DD:
  - Chat history dang in-memory trong `AIChatRepositoryImpl`.
  - Chua co SQLite table/model luu lich su hoi dap.
  - AI response co system instruction rieng, nhung chua thay model context ca nhan hoa rieng cho QA.

### Module 08 - Zalo Special Care Group

- `[ ]` Chua co model/entity/table cho:
  - Zalo group invite
  - membership status
  - special care group
  - external support channel

### Module 09 - Health Knowledge Base

- `[ ]` Chua co model/entity/table cho:
  - article
  - video
  - category/topic
  - knowledge item/content library

## Model ngoai DD nhung da coding

- `[x]` `SettingsPreferencesEntity`
- `[x]` `SettingsPreferencesModel`
- `[x]` `UserProfileEntity`
- `[x]` `UserProfileModel`

Nhom nay phuc vu Settings/Profile, khong phai mot module DD doc lap trong `DD_Module`, nhung co lien quan den Profile Assessment va cau hinh ung dung.

## Ket luan ngan

- Model da code kha day du: Profile/Onboarding, MealPlan, MealPlan Storage, AI Chat message, Settings profile/preferences.
- Model moi co khung/placeholder: localdb models cho health goals/conditions/habits/allergy/treatment/survey, health tracking, nutrition logs, AI insights/recommendations, notifications.
- Chua co model theo DD: 30-day cycle refresh, weekly scoring/report, Zalo care group, knowledge base.
- Sai lech lon nhat voi DD: DD noi 30 ngay va chu ky, code hien tai van chu yeu la meal plan 7 ngay va chua co cycle model.
