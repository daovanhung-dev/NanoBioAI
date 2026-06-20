# DD-AUTH-FR-07 - Hoàn thành Onboarding và kích hoạt Dashboard

**BD nguồn:** AUTH-FR-07  
**Dependencies:** `03_DATA_MODEL_RLS_AND_MIGRATIONS.md`, `10_FEATURE_PROFILE_UPDATE.md`, `14_FLUTTER_LAYER_CONTRACTS.md`

## 1. Mục tiêu

Onboarding cập nhật các row nền do trigger tạo sẵn, chỉ tạo collection data khi người dùng thực sự chọn/nhập. Khi dữ liệu bắt buộc hợp lệ, transaction logic set `onboarding_status=completed` và timestamp.

## 2. Dữ liệu theo loại persistence

| Nhóm | Target | Operation |
|---|---|---|
| User basics | `public.users` | update existing row |
| Health basics | `health_profiles` | update existing row |
| Lifestyle basics | `lifestyle_habits` | update existing row |
| Goals | `health_goals` | insert/upsert selected values; deactivate/remove unselected by agreed policy |
| Allergies | `food_allergies` | insert/delete delta or replace set inside transaction policy |
| Conditions | `health_conditions` | insert/upsert selected values |
| Survey | `survey_answers` | upsert by `(user_id, question_code)` |
| Treatment | `medical_treatments` | create only when supplied |

## 3. Lifecycle state transitions

| Event | Before | After |
|---|---|---|
| User opens onboarding first time | `not_started` | `in_progress` |
| Save draft | `not_started/in_progress` | `in_progress` |
| Final submit valid | `in_progress` | `completed`, timestamp `now()` |
| Final submit invalid | `in_progress` | unchanged; field error |

## 4. Required data contract

The exact required UI fields must be declared by the Onboarding module. At minimum, DD implementation must specify:

- Which fields block completion.
- Valid range/format (for example height, weight, birth year) where business policy exists.
- How BMI is calculated and whether server/client uses it.
- How optional medical fields are handled without forcing user disclosure.

Auth module only owns lifecycle completion, not health recommendation logic.

## 5. Finalization transaction boundary

Preferred design: repository orchestration submits base updates + selected collections, validates the result, then writes completion status last. When an atomic multi-table DB transaction/RPC is introduced, completion state must be changed in that same server transaction. Until then, retry-safe idempotent writes and an `in_progress` state prevent false Dashboard access.

## 6. Resume behavior

- App reopens with `in_progress` → navigate to saved/resumable onboarding step.
- No data deletion merely because user leaves mid-onboarding.
- Display progress only from persisted state/validated draft, not transient route state.

## 7. Constraints

- Do not `insert` baseline rows from client.
- Do not mark `completed` only because all UI pages were visited.
- Do not write health data into Auth metadata.

## 8. Acceptance

TC-AUTH-18 đến TC-AUTH-23.
