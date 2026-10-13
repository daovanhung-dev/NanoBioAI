Commit de xuat: docs(worklog): ghi nhan phien onboarding-progress-ui

# Worklog - Hiển thị tiến độ tạo lịch trong onboarding

## Thời gian

- Ngày: 2026-10-13
- Bắt đầu: không lưu chính xác trong trạng thái phiên
- Kết thúc: 21:30
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: coding và UI.
- Module chính: M01 Onboarding, M02 AI generated plan.
- Yêu cầu gốc: hiển thị phần trăm hoàn thiện và những ngày lịch đã lưu khi AI tạo lịch ban đầu.

## Đã làm

- Thêm `GeneratedPlanProgress` và callback từ service tạo lịch lên state onboarding.
- Chỉ báo ngày mới sau khi thao tác lưu ngày thành công; khi resume, báo trước các ngày đã lưu trọn vẹn của đúng request.
- Thêm panel trong màn tạo lịch với phần trăm, số ngày đã lưu, thanh tiến độ có semantics và chip từng ngày.
- Giữ panel onboarding tách khỏi widget loading dùng chung bằng tham số `progressContent`.
- Cập nhật tài liệu thiết kế ONB-10, feature note và test cho service, controller, panel.
- Giữ nguyên các thay đổi ngoài phạm vi đang có trong worktree.

## File code/docs đã sửa

- `lib/app_versions/v1/services/ai/generated_plan_service.dart` - progress model/callback sau khi lưu ngày và khôi phục tiến độ ngày đã lưu.
- `lib/app_versions/v1/features/onboarding/presentation/controllers/onboarding_controller.dart` - giữ progress callback trong onboarding state.
- `lib/app_versions/v1/features/onboarding/providers/onboarding_completion_provider.dart`, `lib/main.dart` - truyền callback từ bootstrap tới service.
- `lib/app_versions/v1/features/onboarding/presentation/widgets/review_step.dart` - truyền panel vào màn tạo lịch.
- `lib/app_versions/v1/features/onboarding/presentation/widgets/onboarding_schedule_progress_panel.dart` - panel phần trăm và danh sách ngày.
- `lib/shared/widgets/loading_gen_ai.dart` - slot nội dung progress và copy tạo lịch.
- `test/app_versions/v1/services/ai/generated_plan_service_auth_test.dart` - kiểm tra phát progress sau lưu và khi resume.
- `test/app_versions/v1/features/onboarding/onboarding_completion_flow_test.dart` - kiểm tra controller nhận progress.
- `test/app_versions/v1/features/onboarding/onboarding_schedule_progress_panel_test.dart` - kiểm tra phần trăm và nhãn ngày.
- `.codex/design/screens/onb-10-review-step.md`, `docs/features/ai-generated-plan/007-feature-onboarding-plan-progress-ui.md` - hợp đồng UI và mô tả feature.

## Tài liệu liên quan

- `.codex/design/screens/onb-10-review-step.md`
- `docs/features/ai-generated-plan/007-feature-onboarding-plan-progress-ui.md`

## Commands

- `dart format --set-exit-if-changed <10 file nguồn/test của flow>`: PASS, 0 files changed.
- `LD_LIBRARY_PATH=/tmp/nanobio-sqlite-lib flutter test test/app_versions/v1/services/ai/generated_plan_service_auth_test.dart test/app_versions/v1/features/onboarding/onboarding_completion_flow_test.dart test/app_versions/v1/features/onboarding/onboarding_schedule_progress_panel_test.dart`: PASS, all tests passed.
- `flutter analyze <10 file nguồn/test của flow>`: PASS, không có issue.
- `flutter run --debug --no-pub -d chrome`: app khởi chạy; gửi `r` hot reload: PASS, 453 ms. Web runtime báo asset `.env` trả 404; không gọi AI/backend thật.
- `git diff --check`: PASS.
- `pwsh -NoProfile -File .codex/tools/validate_codex_integrity.ps1`: FAIL do thiếu `docs/audit/source_truth_manifest.json` và stale paths trong `.codex/history/WORKLOG_2026-08-16_meal_nutrition_estimation.md` cùng `.codex/task-skills/nabi-character/SKILL.md`; các lỗi đã có ngoài phạm vi thay đổi này.
- Android/device acceptance: chưa chạy. Android Gradle không khai báo QA flavor hoặc application ID suffix; không cài đè package ứng dụng chính.

## Lỗi/Rủi ro

- Đã làm: phần trăm và ngày hoàn thành lấy từ ngày đã lưu xác nhận, không dựa vào thời gian chờ hay output chưa lưu.
- Chưa xác nhận: render trên thiết bị Android và kết nối AI/backend thật.
- Theo dõi tiếp: chuẩn bị QA application ID riêng nếu cần kiểm thử luồng onboarding end-to-end trên Xiaomi.

## Tỷ lệ hoàn thành

- Hoàn thành: source UI/progress, focused tests, targeted analyze, browser app startup và hot reload.
- Đang đo: Android device acceptance và AI/backend thật; không thuộc bằng chứng đã có trong phiên này.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - tiến độ gắn với ngày đã lưu, giữ ranh giới presentation/controller/service và có semantics.
- Mức độ hoàn thành task: yêu cầu UI đã được triển khai và kiểm chứng bằng focused tests; native device/backend acceptance chưa xác nhận.
- Bằng chứng kiểm chứng: 3 test files PASS, 10-file analyzer PASS, format PASS, Chrome hot reload PASS; integrity validator còn lỗi repo-wide đã nêu.
- Điểm tốn token/chưa tối ưu: lần đầu khởi chạy Chrome mất khoảng một phút; lần đầu Flutter format phát hiện hai file cần định dạng trước khi chạy lại kiểm tra sạch.
- Cách tối ưu cho phiên sau: khi cần device proof, tạo hoặc dùng QA variant có application ID riêng thay vì cài đè app chính.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`
