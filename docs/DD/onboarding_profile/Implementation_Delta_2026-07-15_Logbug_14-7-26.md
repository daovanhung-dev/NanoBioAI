# Implementation Delta 2026-07-15 — Logbug 14-7-26

| Thuộc tính | Giá trị |
|---|---|
| Module | M01 / `ONBOARDING_PROFILE` |
| Nguồn | Kế hoạch logbug 14-7-26 do người dùng cung cấp ngày 2026-07-15 |
| Ảnh hưởng | `ONBOARDING_PROFILE-F01`, `ONBOARDING_PROFILE-F02`, `ONBOARDING_PROFILE-BR01` |

## Quyết định bổ sung

| ID | Quyết định |
|---|---|
| ONBOARDING_PROFILE-DELTA-BR01 | Hồ sơ nhịp sinh hoạt là dữ liệu bắt buộc trước khi gọi AI tạo lịch đầu tiên. Hồ sơ cũ thiếu dữ liệu phải mở editor và yêu cầu xác nhận; không tự động gọi quota/AI. |
| ONBOARDING_PROFILE-DELTA-BR02 | Mỗi template ngày thường/cuối tuần có giờ thức/ngủ, năm bữa, ngủ trưa tùy chọn, hai khoảng tập và khoảng bận tùy chọn; ngủ qua đêm hợp lệ, các khoảng bắt buộc phải hợp lệ theo validator. |
| ONBOARDING_PROFILE-DELTA-ADR01 | Lưu JSON version `1` bằng stable id và `question_code = daily_routine_v1` trong `survey_answers`; dùng outbox/sync hiện có, không tăng DB version. |

## Luồng, file và evidence

- Onboarding thêm `DailyRoutineStep` trước consent/review; chỉ chuyển tiếp khi validate và xác nhận thành công.
- Route `/daily-routine-preferences` dành cho người dùng cũ và chỉnh sửa từ Settings/Lịch trình. Khi sửa từ CTA tạo lịch, UI phải quay lại hộp xác nhận trước khi sinh lịch.
- Runtime: `lib/app_versions/v1/features/daily_routine/`, onboarding controller/page/widgets và router/settings.
- Test: `test/features/daily_routine/daily_routine_preferences_test.dart`, `test/app_versions/v1/features/onboarding/onboarding_completion_flow_test.dart`.
- Sandbox sync/RLS thực tế vẫn là evidence gate trước production.
