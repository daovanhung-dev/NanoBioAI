Commit de xuat: docs(worklog): ghi nhan tao lich theo su kien

# Worklog - Tạo lịch theo sự kiện và duyệt món riêng

## Thời gian

- Ngày: 2026-10-19
- Bắt đầu: Tiếp tục từ phiên trước; mốc bắt đầu ban đầu không được truyền trong context.
- Kết thúc: 10:10
- Timezone: Asia/Saigon

## Phạm vi

- Loại task: Coding và kiểm chứng theo plan đã duyệt.
- Module chính: `GeneratedPlanService`, staging request, lọc catalog, panel tiến độ onboarding/tạo lịch thêm.
- Yêu cầu gốc: Tạo lịch 7 ngày cục bộ theo sự kiện; chặn nhãn catalog sai trước AI; cho duyệt món AI riêng; lưu nháp theo sự kiện và ghi ngày vào lịch chính sau khi hợp lệ.

## Đã làm

- Kiểm tra nhãn bữa của catalog đủ điều kiện trước AI và trước quota thành viên.
- Tạo món riêng theo schema cố định khi một suất không còn ứng viên sau lọc; dừng yêu cầu cho tới khi người dùng duyệt hoặc yêu cầu món khác.
- Lưu đề xuất món trong staging theo request; món đã duyệt chỉ được dùng trong request đó, không thêm vào catalog và không xem dinh dưỡng chưa xác minh là số 0.
- Lưu các sự kiện đã xác thực theo giờ vào staging, cập nhật tiến độ từng sự kiện và chỉ commit từng ngày sau khi timeline hợp lệ.
- Cập nhật luồng tiếp tục theo request/event ID ổn định và panel dùng chung cho onboarding/tạo thêm lịch.
- Bổ sung regression cho preflight quota, thay/duyệt món, schema AI, phần trăm tiến độ và hiển thị theo ngày.
- Lần rà soát hoàn tất phát hiện một lint thiếu ngoặc nhọn trong nhánh lỗi cập nhật staging; đã sửa và chạy lại analyzer không còn issue.

## File code/docs đã sửa

- `lib/app_versions/v1/features/meal_plan/domain/services/meal_catalog_prefilter.dart` - kiểm tra nhãn và chọn nhóm món theo buổi/suất.
- `lib/app_versions/v1/services/ai/generated_plan_service.dart` - preflight, đề xuất món riêng, staging event-level, resume và commit theo ngày.
- `lib/app_versions/v1/services/ai/generated_plan_request_store.dart` - cập nhật mục staging có kiểm tra giá trị kỳ vọng và giữ nháp khi chỉ đổi phiên bản prompt.
- `lib/app_versions/v1/services/ai/ai_service.dart` - tạo món riêng theo schema JSON có giới hạn.
- `lib/app_versions/v1/features/meal_plan/data/models/meal_plan_ai_normalizer.dart` - lặp món theo đúng nhóm khi đã dùng hết món độc nhất; chuẩn hóa món riêng đã duyệt.
- `lib/shared/widgets/generated_plan_progress_panel.dart` - panel ngày/sự kiện, phần trăm, món chờ duyệt và danh sách món sau lọc.
- `lib/app_versions/v1/features/onboarding/` và `lib/app_versions/v1/features/dashboard/` - nối panel/luồng duyệt vào onboarding và tạo thêm lịch.
- `test/app_versions/v1/services/ai/generated_plan_service_auth_test.dart`, `test/app_versions/v1/features/meal_plan/meal_catalog_prefilter_test.dart`, `test/app_versions/v1/features/onboarding/`, `test/services/ai/ai_service_test.dart` - regression lịch, lọc, UI và schema món riêng.
- `docs/features/ai-generated-plan/010-feature-event-staged-plan-generation.md` - tài liệu hành vi và giới hạn kiểm chứng.

## Tài liệu liên quan

- Plan: Tạo lịch 7 ngày theo sự kiện, có tiến độ lưu và món chờ duyệt.
- Worklog lọc catalog: `docs/worklog/2026-10-18/004-worklog-local-meal-catalog-prefilter.md`.

## Commands

- `flutter test test/app_versions/v1/services/ai/generated_plan_service_auth_test.dart test/app_versions/v1/features/meal_plan/meal_catalog_prefilter_test.dart --reporter compact`: PASS - 32 test.
- `flutter test test/app_versions/v1/features/onboarding/onboarding_schedule_progress_panel_test.dart test/app_versions/v1/features/onboarding/onboarding_completion_flow_test.dart --reporter compact`: PASS - 11 test.
- `flutter test test/services/ai/ai_service_test.dart --plain-name 'custom meal proposal' --reporter expanded`: PASS - 2 test.
- `flutter test test/app_versions/v1/services/ai/generated_plan_service_auth_test.dart test/app_versions/v1/features/meal_plan/meal_catalog_prefilter_test.dart test/app_versions/v1/features/onboarding/onboarding_schedule_progress_panel_test.dart test/app_versions/v1/features/onboarding/onboarding_completion_flow_test.dart --reporter compact`: PASS - 43 test sau khi sửa lint.
- `flutter test test/services/ai/ai_service_test.dart --plain-name 'custom meal proposal' --reporter compact`: PASS - 2 test sau khi sửa lint.
- `flutter test test/services/ai/ai_service_test.dart --reporter json`: FAIL - 2 test chat cũ kỳ vọng `TimeoutException` failover; lỗi nằm trong `AIChatService`, không thuộc luồng lịch.
- `dart analyze` trên các file runtime/test liên quan: PASS - `No issues found!` sau khi sửa lint.
- `dart format --set-exit-if-changed lib/app_versions/v1/services/ai/generated_plan_request_store.dart`: PASS - không cần format thêm.
- `flutter build apk --debug`: PASS - xác nhận lại sau khi sửa lint; artifact tại `build/app/outputs/flutter-apk/app-debug.apk`.
- `git diff --check`: PASS sau cập nhật worklog/checklist.
- `flutter devices`: RUN - chỉ có Linux/Chrome, không có Android device.
- DTD `listDtdUris`/`listConnectedApps`/`hot_reload`: SKIPPED - IDE có DTD nhưng không có app Flutter đang kết nối; không thể hot reload hoặc xác minh inference Qwen.

## Lỗi/Rủi ro

- Đã fix: các test fixture cũ tính phần trăm theo ngày đã được chuyển sang số sự kiện; test schema món riêng xác nhận số lần gọi lại theo chính sách retry.
- Chưa fix: hai test chat timeout/fallback thất bại do thay đổi chat sẵn có; giữ ngoài phạm vi task lịch trình.
- Cần kiểm tra tiếp: inference Qwen trên Android 11 và hot reload thực tế khi có thiết bị/app đang kết nối.

## Tỷ lệ hoàn thành

- Hoàn thành: code, regression test tập trung, widget tests và Android debug build.
- Đang dở: thiết bị Android/Qwen không hiện diện để chạy inference và quota flow thực tế; analyzer, tests và APK build đã xác minh.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - lưu nháp/duyệt món tách biệt với catalog, tiến độ phản ánh sự kiện, và có đường tiếp tục theo ID ổn định.
- Mức độ hoàn thành task: source, focused tests, analyzer và Android debug build hoàn tất; chỉ còn acceptance trực tiếp trên Android 11/Qwen và quota backend.
- Bằng chứng kiểm chứng: 43 test lịch/lọc/UI/onboarding pass, 2 test schema món riêng pass, targeted analysis không issue, format/diff check và Android debug APK build pass.
- Điểm tốn token/chưa tối ưu: Android thiết bị và app Flutter không được kết nối trong phiên này; không thể xác nhận inference thật.
- Cách tối ưu cho phiên sau: kết nối Android 11 có model Qwen đã tải và app chạy, sau đó thực hiện một lịch tổng hợp không chứa dữ liệu sức khỏe thật để xác nhận tiến độ và quota.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`.
