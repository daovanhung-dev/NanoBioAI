# M04 — Health Dashboard Delta 2026-08

## 1. Trạng thái

- Module: `M04 / BASIC_HEALTH_CALC`
- Feature runtime: `lib/app_versions/v1/features/body_metrics/`
- Route giữ nguyên: `/body-metrics`
- Mục đích delta: chuyển Body Metrics từ calculator nhập tay sang read-only personal health dashboard.
- Persistence mới: **Không**.
- DB migration mới: **Không**.

## 2. Business rules khóa khi triển khai

| ID | Rule |
|---|---|
| BM-BR-01 | Chỉ phân tích current user/current subject; không dùng recency của storage làm identity. |
| BM-BR-02 | Màn Body Metrics không cho sửa height/weight/age/sex/activity. |
| BM-BR-03 | Dữ liệu đi qua Repository/Datasource, Presentation không query DB/Supabase trực tiếp. |
| BM-BR-04 | Missing data hiển thị `Chưa đủ dữ liệu`; không dựng số `0` giả. |
| BM-BR-05 | Numeric truth được Dart tính/tổng hợp trước AI. |
| BM-BR-06 | AI chỉ diễn giải wellness; không chẩn đoán. |
| BM-BR-07 | AI không kê/đổi/ngừng thuốc và không đưa dosage. |
| BM-BR-08 | Không suy luận bệnh từ metric. |
| BM-BR-09 | Guest/Free chạy đúng 5 AI stages. |
| BM-BR-10 | Plus/FamilyPlus chạy đúng 15 AI stages. |
| BM-BR-11 | Paid access đọc từ trusted Supabase `effective_user_access.product_access`. |
| BM-BR-12 | Unknown/error/timeout access fail closed về Free. |
| BM-BR-13 | AI context không chứa user id, full name, email, phone, proof path hoặc raw DB row. |
| BM-BR-14 | Observation nâng cao chỉ có latest/average/trend/freshness; không clinical classification. |
| BM-BR-15 | Mỗi metric có `metricId`, `formulaVersion`, reference và data window. |
| BM-BR-16 | AI stage sai JSON/unknown metric/numeric claim/unsafe medical claim bị reject. |
| BM-BR-17 | AI failure không làm mất deterministic report. |
| BM-BR-18 | Partial stage failure được giữ và UI hiển thị số stage vượt safety validation. |
| BM-BR-19 | Data completeness là chất lượng dữ liệu, không phải health score. |
| BM-BR-20 | UI phân biệt dữ liệu ghi nhận, chỉ số deterministic và nhận định Nabi. |

## 3. Feature registry mới

1. Personal Health Snapshot
2. Body Composition Overview
3. Energy Requirement Analysis
4. Nutrition Metrics Analysis
5. Sleep & Recovery Analytics
6. Activity Analytics
7. Health Trend Analytics
8. Habit Context Analysis
9. Health Goal Alignment
10. Treatment/Condition Context
11. AI Core Analysis
12. Premium Deep Analysis
13. Personalized Improvement Plan
14. Data Quality & Confidence
15. Formula Version Management

## 4. Data flow

```text
BodyMetricsPage
  -> BodyMetricsController
  -> BodyMetricsRepository
  -> BodyMetricsLocalDatasource
  -> SQLite existing tables

BodyMetricsHealthSnapshot
  -> BodyMetricsFormulaEngine
  -> BodyMetricsHealthReport
  -> BodyMetricsAiContext (PII-minimized)
  -> BodyMetricsAnalysisOrchestrator
  -> 5 or 15 validated stages
```

Current subject được resolve bằng shared `LocalSubjectResolver` với authenticated actor hoặc durable guest identity. Không fallback sang "user cập nhật gần nhất".

## 5. Existing tables đọc

- `users`
- `health_profiles`
- `health_tracking_logs`
- `meal_plans`
- `lifestyle_habits`
- `health_conditions`
- `health_goals`
- `food_allergies`
- `medical_treatments`
- `lifestyle_schedule_items`

Không đọc `completion_proof_path` vào AI payload.

## 6. Data windows

- Tracking datasource: tối đa 60 ngày lịch sử để đủ nguồn tính xu hướng.
- Core dashboard: 7 ngày và 30 ngày.
- Nutrition: aggregate theo ngày trong 30 ngày lịch sử.
- Schedule: 30 ngày lịch sử tới ngày hiện tại.
- Không nội suy ngày thiếu.

## 7. Deterministic metric registry

Implementation hiện phát 60 metric IDs: 54 metric theo plan + 6 observation-only metric để tận dụng dữ liệu hiện có mà không vượt boundary Advanced Health.

### Body — 10

- `body.bmi`
- `body.bmi_category`
- `body.healthy_weight_lower`
- `body.healthy_weight_upper`
- `body.distance_healthy_range`
- `body.weight_change_7d`
- `body.weight_change_30d`
- `body.weight_change_percent`
- `body.weight_trend_slope`
- `body.weight_variability`

### Energy — 8

- `energy.mifflin_ree`
- `energy.eer`
- `energy.tdee`
- `energy.planned_calories`
- `energy.gap`
- `energy.alignment_percent`
- `energy.average_7d`
- `energy.average_30d`

### Nutrition — 17

- `nutrition.protein_g_day`
- `nutrition.protein_g_kg`
- `nutrition.protein_energy_percent`
- `nutrition.carb_energy_percent`
- `nutrition.fat_energy_percent`
- `nutrition.macro_calories`
- `nutrition.calorie_reconciliation_error`
- `nutrition.macro_balance_count`
- `nutrition.fiber_density`
- `nutrition.fiber_reference_target`
- `nutrition.fiber_coverage`
- `nutrition.sodium_ratio`
- `nutrition.potassium_average`
- `nutrition.calcium_average`
- `nutrition.iron_average`
- `nutrition.sugar_average`
- `nutrition.saturated_fat_average`

### Hydration — 4

- `hydration.water_average_7d`
- `hydration.water_average_30d`
- `hydration.logging_consistency`
- `hydration.trend`

### Recovery — 7

- `recovery.sleep_average_7d`
- `recovery.sleep_average_30d`
- `recovery.sleep_adequacy`
- `recovery.sleep_variability`
- `recovery.stress_average`
- `recovery.stress_trend`
- `recovery.mood_distribution`

### Activity — 5

- `activity.steps_average`
- `activity.steps_trend`
- `activity.estimated_max_hr`
- `activity.moderate_hr_zone`
- `activity.vigorous_hr_zone`

### Observation-only — 6

- `observation.heart_rate_latest`
- `observation.heart_rate_average_30d`
- `observation.spo2_latest`
- `observation.spo2_average_30d`
- `observation.blood_pressure`
- `observation.blood_sugar`

### Adherence/Data Quality — 3

- `adherence.meal_completion`
- `adherence.schedule_completion`
- `data.completeness_freshness`

## 8. Formula version policy

- Release registry: `m04_health_dashboard_2026_08`.
- Công thức có definition riêng khi cần: BMI, BMI range, Mifflin REE, EER, TDEE, fiber density/target, sodium ratio, estimated HR and HR zones.
- Metric aggregate còn lại dùng version deterministic release, không rải magic version trong UI.
- Metric thiếu input vẫn tồn tại nhưng `status=insufficientData`.

## 9. Data quality

Weights:

- Profile: 20%
- Tracking: 20%
- Nutrition: 20%
- Lifestyle: 15%
- Schedule: 15%
- Context: 10%

Freshness groups:

- profile
- tracking
- nutrition
- lifestyle
- schedule
- context

Completeness/freshness không được gọi là health score.

## 10. AI pipeline

### Free/Guest — 5 stages

- P01 Baseline
- P02 Trends
- P03 Nutrition
- P04 Lifestyle
- P05 Free synthesis

### Plus/FamilyPlus — 15 stages

Bổ sung:

- P06 Weight/body deep dive
- P07 Energy balance
- P08 Macro
- P09 Fiber/mineral/meal quality
- P10 Hydration
- P11 Sleep/stress/mood
- P12 Activity/HR context
- P13 Conditions/goals/treatment context
- P14 30-day optimization strategy
- P15 Premium synthesis

Stage dependency chỉ truyền payload đã validate, không truyền raw output.

## 11. AI safety validator

Reject khi:

- JSON không hợp lệ.
- Field/schema sai.
- Narrative có numeric digits.
- Unknown metric id.
- Diagnosis/medical certainty wording.
- Drug start/stop/switch/dose instruction.
- Guarantee/certain outcome.
- List vượt giới hạn.

Một stage reject không xóa report deterministic và không bắt buộc dừng các stage độc lập còn lại.

## 12. Trusted access

Shared files:

```text
lib/services/access/
  product_access_level.dart
  product_access_reader.dart
  trusted_product_access_reader.dart
```

Trusted reader:

```text
Supabase effective_user_access.product_access
  guest       -> 5
  free        -> 5
  plus        -> 15
  family_plus -> 15
  unknown     -> 5
  error       -> 5
  timeout     -> 5
```

## 13. UI contract

Màn hình mới read-only và theo thứ tự:

1. Hero + completeness + tracking count + AI depth.
2. Dữ liệu sức khỏe hiện tại.
3. Body metrics.
4. Energy.
5. Nutrition.
6. Hydration.
7. Sleep/recovery.
8. Activity.
9. Advanced observations.
10. Adherence.
11. Data quality.
12. Trend chart 7d/30d.
13. Declared context.
14. Nabi analysis/progress.
15. Today/7d/30d action plan.
16. Data gaps.
17. Safety notice.

Không có `TextField`, `TextEditingController` hoặc dropdown sửa profile trong Body Metrics page.

## 14. Controller state

```text
loadingData
ready
calculating
analyzing
partial
success
error
```

AI progress lưu `currentAiStage`, `totalAiStages`, `currentStageId`.

## 15. Persistence decision

Không thêm table và không bump SQLite version. AI report chỉ giữ trong provider/controller state của phiên hiện tại.

## 16. Verification requirements

- Deterministic metric count > 50.
- Metric count khớp registry.
- Missing input -> `insufficientData`, không zero giả.
- Current subject resolver được repository sử dụng.
- Free exact 5 stage calls.
- Plus exact 15 stage calls.
- FamilyPlus exact 15 stage calls.
- Unsafe AI response reject.
- AI context không chứa identity/proof PII.
- Body Metrics UI không còn editable fields.
- Không import V2.
- Presentation không import SQLite/Supabase.
