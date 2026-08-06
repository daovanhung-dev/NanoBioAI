# Meal Plan và Nutrition

## Goal

Duy trì identity của món ăn, chuyển đổi card-to-detail, thay món tại chỗ và animate số liệu thay đổi.

## Current evidence

- Files: **5**.
- Page/screen: **3**.
- Files có motion: **2**.
- Files dùng duration raw: **1**.
- Files dùng color trực tiếp: **1**.
- Files gọi haptic trực tiếp: **0**.

## Group design rules

- Meal code/date/type là identity cho card/replace.
- Macro values tween từ old→new; không từ 0.
- Allergen/condition warning ưu tiên clarity.
- Recipe detail dùng shared transition.

## Views

| View | Entrance | State transition | Feedback | Design intent |
| --- | --- | --- | --- | --- |
| lib/app_versions/v1/features/meal_plan/presentation/pages/meal_plan_page.dart | Date/meal identity-preserving fade-slide | Day/meal/detail/replace/macro delta | Press visual; selection haptic; sound chỉ cho success/error/voice/milestone semantic | Tách file lớn; day indicator glide, meal card identity, card-to-recipe shared transition, replace-in-place và macro number tween. |
| lib/app_versions/v1/features/nutrition/presentation/pages/nutrition_page.dart | Date/meal identity-preserving fade-slide | Day/meal/detail/replace/macro delta | Press visual; selection haptic; sound chỉ cho success/error/voice/milestone semantic | Refresh delta animation, macro visualization, insight expand; loading/empty/error dùng primitive canonical. |
| lib/app_versions/v1/features/nutrition/presentation/pages/nutrition_profile_editor_page.dart | Date/meal identity-preserving fade-slide | Day/meal/detail/replace/macro delta | Press visual; selection haptic; sound chỉ cho success/error/voice/milestone semantic | Section progression, validation reveal, sticky save state; success chỉ sau repository commit. |

## File-by-file design

| File | Kind | Role | Current evidence | Target design | Transition contract | Wave |
| --- | --- | --- | --- | --- | --- | --- |
| lib/app_versions/v1/features/meal_plan/presentation/controllers/meal_plan_controller.dart | controller | MealPlanController | Chưa có motion/feedback đáng kể | Giữ nguyên nghiệp vụ; chuẩn hóa UI phase/state identity; loại bỏ haptic trực tiếp khỏi controller và phát feedback sau khi state thành công/thất bại được xác nhận. | Stable state/identity contract | W5 Meal/Nutrition |
| lib/app_versions/v1/features/meal_plan/presentation/pages/meal_plan_page.dart | page | MealPlanPage / _MealPlanPageState / _MealPlanHeader / _DecorativeCircle | controller×2, AnimatedContainer×2, AnimatedScale×1, TweenAnimationBuilder×1, duration raw×1, Colors.*×1, motion token×3, Semantics×2, RefreshIndicator×1, Nabi×5 | Tách file lớn; day indicator glide, meal card identity, card-to-recipe shared transition, replace-in-place và macro number tween. | Day/meal/detail/replace/macro delta | W5 Meal/Nutrition |
| lib/app_versions/v1/features/nutrition/presentation/controllers/nutrition_profile_controller.dart | controller | NutritionProfileController | Chưa có motion/feedback đáng kể | Giữ nguyên nghiệp vụ; chuẩn hóa UI phase/state identity; loại bỏ haptic trực tiếp khỏi controller và phát feedback sau khi state thành công/thất bại được xác nhận. | Stable state/identity contract | W5 Meal/Nutrition |
| lib/app_versions/v1/features/nutrition/presentation/pages/nutrition_page.dart | page | NutritionPage / _NutritionLoadingState / _Header / _NamiNoteCard | RefreshIndicator×1, Nabi×15 | Refresh delta animation, macro visualization, insight expand; loading/empty/error dùng primitive canonical. | Day/meal/detail/replace/macro delta | W5 Meal/Nutrition |
| lib/app_versions/v1/features/nutrition/presentation/pages/nutrition_profile_editor_page.dart | page | NutritionProfileEditorPage / _NutritionProfileForm / _NutritionProfileFormState / _StepHeader | AnimatedSwitcher×1, motion token×1, Nabi×3 | Section progression, validation reveal, sticky save state; success chỉ sau repository commit. | Day/meal/detail/replace/macro delta | W5 Meal/Nutrition |

## Acceptance

- Không raw sound/haptic call ngoài feedback service.
- Không motion replay khi state không đổi.
- Có reduced-motion behavior.
- Có loading/empty/error/ready hoặc lý do không áp dụng.
- Targeted widget/route/state test được bổ sung trong coding wave.
