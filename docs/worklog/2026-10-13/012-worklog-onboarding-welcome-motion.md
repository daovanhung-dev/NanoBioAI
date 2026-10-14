Commit de xuat: feat(onboarding): lam gon WelcomeStep va them motion cho entry

# Worklog - Tối giản WelcomeStep và motion màn vào

## Thời gian

- Ngày: 2026-10-13
- Bắt đầu: khoảng 22:48
- Kết thúc: khoảng 23:05
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: coding
- Module chính: M01 `ONBOARDING_PROFILE` / onboarding UI
- Yêu cầu gốc: thêm logo, tối giản WelcomeStep, dùng xanh Blue Wellness và chuyển động hai thẻ hành động từ hai phía; giữ nguyên điều hướng và xử lý nghiệp vụ.

## Đã làm

- Thay nội dung WelcomeStep bằng logo `assets/logo.jpg` và Nabi trong khung xanh bo góc có tỷ lệ vuông; logo và Nabi cùng mờ dần bằng `AppViewMotion`.
- Bỏ ba thẻ lợi ích và lời nhắc phụ; giữ tiêu đề, lời dẫn và nút bắt đầu của shell.
- Cho thẻ tạo lộ trình trượt từ trái và thẻ đăng nhập từ phải bằng `AppViewMotion`, `AppDuration.emphasized` và `AppDuration.stagger`.
- Giữ nguyên CTA, điều hướng và thẻ thử tạo lịch.
- Sửa test định tuyến để chạy trong `ProviderScope`, mở `OnboardingPage` thật, kiểm tra panel Welcome ở trạng thái cuối khi bật Reduce Motion và xác nhận CTA sang Basic Info; bổ sung assertion hai thẻ xuất phát từ hai phía và kết thúc ở vị trí giữa.
- Xem trực tiếp trên Xiaomi 220333QPG (720x1650) ở cỡ chữ hệ thống 1.3 và 0.86; logo, Nabi, tiêu đề và CTA không bị cắt. Sau QA đã khôi phục font scale hệ thống về 0.86 và cờ cấu hình cỡ chữ của app về `false` như trạng thái ban đầu.

## File code/docs đã sửa

- `lib/app_versions/v1/features/onboarding/presentation/widgets/welcome_step.dart` - thay phần nội dung WelcomeStep bằng panel vuông xanh chứa logo và Nabi.
- `lib/app_versions/v1/features/onboarding/presentation/pages/onboarding_entry_page.dart` - thêm chuyển động hai hướng cho thẻ guest và login.
- `test/app_versions/v1/features/onboarding/onboarding_entry_page_test.dart` - bổ sung ProviderScope, xác minh chuyển động hai phía, màn Welcome thật, điều hướng và thao tác khi bật Reduce Motion.
- `docs/worklog/2026-10-13/012-worklog-onboarding-welcome-motion.md` - ghi lại phạm vi và bằng chứng kiểm tra.
- `.codex/history/LEARNED_SKILLS.md`, `.codex/history/RISK_HISTORY.md`, `.codex/history/WORKLOG_INDEX.md`, `.codex/task-skills/README.md`, `.codex/task-skills/coding.md` - refresh tự động từ worklog.

## Tài liệu liên quan

- `.codex/design/README.md`
- `.codex/design/15_CODING_PLAN.md`
- `.codex/domains/onboarding.md`

## Commands

- `dart format lib/app_versions/v1/features/onboarding/presentation/widgets/welcome_step.dart lib/app_versions/v1/features/onboarding/presentation/pages/onboarding_entry_page.dart test/app_versions/v1/features/onboarding/onboarding_entry_page_test.dart`: PASS.
- `flutter test test/app_versions/v1/features/onboarding/onboarding_entry_page_test.dart`: PASS, 2 tests.
- `flutter analyze lib/app_versions/v1/features/onboarding/presentation/widgets/welcome_step.dart lib/app_versions/v1/features/onboarding/presentation/pages/onboarding_entry_page.dart test/app_versions/v1/features/onboarding/onboarding_entry_page_test.dart`: PASS, no issues.
- `powershell -ExecutionPolicy Bypass -File tools/run_v2.ps1 -ValidateOnly`: PASS; runtime environment hợp lệ.
- `powershell -ExecutionPolicy Bypass -File tools/run_v2.ps1`: PASS; build, cài đặt và chạy app debug trên Xiaomi 220333QPG.
- Dart MCP `hot_reload` trên app `nano_app`: PASS.
- Kiểm tra trực quan ảnh chụp thiết bị ở font scale 1.3 và 0.86: PASS; cỡ chữ hệ thống đã khôi phục về 0.86.
- `powershell -ExecutionPolicy Bypass -File .codex/tools/update_worklog_learning.ps1`: PASS; làm mới 19 tệp history/task-skill theo bộ sinh.
- `git diff --check`: PASS.
- `powershell -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1`: FAIL do thiếu `docs/audit/source_truth_manifest.json` và các đường dẫn cũ trong `.codex/history/WORKLOG_2026-08-16_meal_nutrition_estimation.md` cùng `.codex/task-skills/nabi-character/SKILL.md`; không liên quan tệp onboarding đã sửa.
- AI generation, lưu hồ sơ onboarding và tạo lịch: SKIPPED; không cần cho kiểm tra UI.

## Lỗi/Rủi ro

- Đã fix: test định tuyến cũ thiếu `ProviderScope`; test cũng chờ motion hoàn tất trước khi xác minh điều hướng.
- Chưa fix: không có lỗi còn mở trong phạm vi UI này.
- Cần kiểm tra tiếp: QA thủ công trên thiết bị khác nếu cần xác nhận thêm kích thước màn hình nhỏ hơn 720x1650.

## Tỷ lệ hoàn thành

- Hoàn thành: thay đổi UI, chuyển động, kiểm tra route/reduce-motion, phân tích tĩnh và kiểm tra trực quan trên thiết bị.
- Đang đo: không còn hạng mục trong yêu cầu đã chốt.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - giữ API và nghiệp vụ, chuyển động dùng contract chung, UI đã được xem ở cỡ chữ lớn.
- Mức độ hoàn thành task: hoàn thành phạm vi đã duyệt.
- Bằng chứng kiểm chứng: 2 widget tests, targeted analyzer, hot reload, screenshot thiết bị và xác nhận font scale đã khôi phục.
- Điểm tốn token/chưa tối ưu: test ban đầu thiếu `ProviderScope`; việc xác định route test cần thêm một vòng sửa fixture.
- Cách tối ưu cho phiên sau: test widget điều hướng nên dựng `ProviderScope` và kiểm tra thời điểm animation trước khi tap.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`
