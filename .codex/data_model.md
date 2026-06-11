# Data Model

## SQLite Database
- **File**: `bioai.db` (via `sqflite`)
- **Version**: 1
- **Foreign keys**: DISABLED (`PRAGMA foreign_keys = OFF`)
- **Primary keys**: TEXT (timestamp-based string: `DateTime.now().millisecondsSinceEpoch.toString()`)

---

## Bảng chính

### `users`
| Column | Type | Ghi chú |
|---|---|---|
| id | TEXT PK | timestamp string |
| email | TEXT UNIQUE | nullable |
| phone | TEXT UNIQUE | nullable |
| full_name | TEXT | |
| avatar_url | TEXT | |
| gender | TEXT | |
| birth_year | INTEGER | |
| created_at | TEXT | ISO8601 |
| updated_at | TEXT | ISO8601 |

### `health_profiles`
| Column | Type | Ghi chú |
|---|---|---|
| id | TEXT PK | |
| user_id | TEXT FK→users | |
| occupation | TEXT | |
| height_cm | REAL | |
| weight_kg | REAL | |
| bmi | REAL | tính sẵn khi insert |
| blood_pressure | TEXT | nullable |
| blood_sugar | TEXT | nullable |
| created_at, updated_at | TEXT | |

### `health_goals`
| Column | Type | Ghi chú |
|---|---|---|
| id | TEXT PK | |
| user_id | TEXT FK | |
| goal_code | TEXT | e.g. `lose_weight`, `sleep_better` |
| goal_name | TEXT | label tiếng Việt |
| is_active | INTEGER | default 1 |
| created_at | TEXT | |

### `health_conditions`
| Column | Type | Ghi chú |
|---|---|---|
| id | TEXT PK | |
| user_id | TEXT FK | |
| condition_code | TEXT | e.g. `insomnia`, `stress` |
| condition_name | TEXT | label tiếng Việt |
| severity_level | INTEGER | default 1 |
| created_at | TEXT | |

### `lifestyle_habits`
| Column | Type | Ghi chú |
|---|---|---|
| id | TEXT PK | |
| user_id | TEXT FK | |
| skip_breakfast...coffee_high | INTEGER | 0/1 boolean flags (9 cột) |
| sleep_quality | TEXT | |
| activity_level | TEXT | |
| water_per_day | TEXT | |
| created_at | TEXT | |

### `food_allergies`
| Column | Type | |
|---|---|---|
| id | TEXT PK | |
| user_id | TEXT FK | |
| allergy_name | TEXT | |
| note | TEXT | nullable |
| created_at | TEXT | |

### `medical_treatments`
| Column | Type | |
|---|---|---|
| id | TEXT PK | |
| user_id | TEXT FK | |
| treatment_name | TEXT | |
| medication_name | TEXT | nullable |
| note | TEXT | nullable |
| created_at | TEXT | |

### `meal_plans`
| Column | Type | Ghi chú |
|---|---|---|
| id | TEXT PK | UUID từ AI response |
| user_id | TEXT | |
| plan_date | TEXT | YYYY-MM-DD |
| meal_type | TEXT | breakfast / lunch / dinner |
| meal_name | TEXT | tên món tiếng Việt |
| description | TEXT | |
| calories | INTEGER | |
| protein, carbs, fat, fiber | REAL | gram |
| water_ml | INTEGER | |
| meal_order | INTEGER | 1/2/3 |
| is_completed | INTEGER | 0/1 |
| ai_generated | INTEGER | 1 nếu do AI tạo |
| created_at, updated_at | TEXT | |

### `survey_answers`
Lưu câu trả lời dạng key-value: `question_code` → `answer_value`

### `ai_insights`
| Column | Ghi chú |
|---|---|
| insight_type | TEXT |
| title, content | TEXT |
| risk_level | TEXT |

### `ai_recommendations`, `health_tracking_logs`, `nutrition_logs`, `notifications`
Bảng tồn tại trong schema nhưng chưa có logic sử dụng trong code hiện tại.

---

## Dart entities / models

- **Entity** (`domain/entities/`) — pure Dart, không phụ thuộc framework
- **Model** (`data/models/`) — extends Entity, có `fromJson`/`fromMap`/`toMap`
- Ví dụ: `OnboardingEntity` ← `OnboardingModel.fromEntity(entity)`

## SharedPreferences

| Key | Type | Mô tả |
|---|---|---|
| `onboarding_completed` | bool | Đã hoàn thành onboarding chưa |
