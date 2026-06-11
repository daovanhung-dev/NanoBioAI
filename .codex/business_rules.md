# Business Rules

## Onboarding

### Validation để cho phép save
`OnboardingState.canSave` = true khi:
- `fullName` không rỗng
- `gender` không rỗng
- `birthYear > 1900`
- `occupation` không rỗng
- `agreed == true`

### BMI tự động tính
`bmi = weightKg / (heightCm / 100)²`
Tính trong cả `OnboardingState` và `OnboardingEntity`. Được lưu vào `health_profiles.bmi`.

### Upsert user khi save onboarding
- Lookup bằng `email OR phone`
- Nếu tìm thấy: UPDATE user info
- Nếu không: INSERT mới với `id = timestamp.toString()`
- Sau đó: DELETE toàn bộ records cũ (health_profiles, goals, conditions, lifestyle, allergies, treatments, surveys) rồi INSERT mới → đảm bảo idempotent

### Conditional insert
- `food_allergies`: chỉ insert nếu `allergyName` không rỗng (`hasAllergy`)
- `medical_treatments`: chỉ insert nếu có `treatmentName` hoặc `medicationName` hoặc `treatmentNote` (`hasTreatment`)

### Max step onboarding
- Tổng 7 steps (index 0–6)
- `nextStep()` không cho vượt quá index 6
- `previousStep()` không cho xuống dưới 0

---

## Routing / Auth

### Splash routing
- Đọc `SharedPreferences.onboarding_completed`
- `true` → go Dashboard
- `false` → go Onboarding

### authGuard
- `Supabase.currentUser == null` → redirect `/login`
- Áp dụng cho: `/ai-chat`, `/nutrition`, `/profile`

### guestGuard
- `Supabase.currentUser != null` → redirect `/dashboard`
- Áp dụng cho: `/login`

### Dashboard auth guard
- Hiện tại **bị comment out** → dashboard accessible mà không cần đăng nhập

---

## AI Meal Plan

### Trigger
Meal plan chỉ được generate sau khi `saveOnboarding()` thành công — gọi `genMealByWeeksToDB()`.

### Dữ liệu đầu vào
Lấy từ SQLite qua `DashboardLocalDatasource.fetchDashboard()` → user mới nhất theo `created_at DESC`.

### Schema output
AI phải trả về JSON array theo schema `meal_plans`. Nếu response không parse được sau 3 lần retry → trả về `[]` (không throw error ra UI).

### JSON cleanup
Response được clean: xóa markdown fences, sửa trailing comma, extract từ `[` đầu đến `]` cuối.

---

## Lifestyle habits
9 boolean flags lưu dưới dạng `INTEGER (0/1)` trong `lifestyle_habits`:
`skip_breakfast`, `eat_late`, `eat_sweet`, `eat_oily`, `low_vegetable`, `low_water`, `fast_food`, `alcohol`, `coffee_high`

---

## Goal codes hợp lệ (15 mã)
`lose_weight`, `gain_weight`, `lose_belly_fat`, `gain_muscle`, `improve_digestion`, `sleep_better`, `reduce_fatigue`, `increase_energy`, `beautify_skin`, `immune_boost`, `stable_blood_sugar`, `stable_blood_pressure`, `joint_health`, `detox_body`, `overall_health`

## Condition codes hợp lệ (14 mã)
`stomach_pain`, `constipation`, `bloating`, `insomnia`, `stress`, `joint_pain`, `high_blood_sugar`, `blood_pressure_issue`, `high_cholesterol`, `fatty_liver`, `tired_always`, `overweight`, `underweight`, `no_special_issue`
