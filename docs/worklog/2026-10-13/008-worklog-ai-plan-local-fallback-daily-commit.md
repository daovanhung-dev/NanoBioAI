Commit de xuat: fix(ai): fallback theo catalog va luu lich tung ngay

# Worklog - Fallback AI và lưu lịch từng ngày

## Thời gian

- Ngày: 2026-10-13
- Bắt đầu: không được lưu chính xác trong trạng thái phiên
- Kết thúc: 20:17
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: bugfix M02 PERSONAL_SCHEDULE_AI.
- Mục tiêu: lỗi AI không làm hỏng khả năng tạo gợi ý lịch; ngày đã hợp lệ phải được ghi ngay vào SQLite và còn nguyên khi ngày sau lỗi.
- Giữ nguyên các thay đổi onboarding/catalog khác đang có trong worktree; không chạy tạo lịch trên dữ liệu thiết bị thật trong lượt này.

## Nguyên nhân

- Trước thay đổi, 14 chunk chỉ vào staging; bữa và hoạt động chính chỉ được ghi sau khi đủ cả tuần. Một lỗi muộn làm người dùng không thấy ngày đã tạo.
- Lỗi provider, JSON hoặc giới hạn backend có thể dừng yêu cầu dù catalog cục bộ có lựa chọn hợp lệ.
- Ghi theo ngày nhưng xóa mọi mục trong ngày sẽ làm mất mục người dùng tự thêm ở chế độ nối lịch.

## Đã làm

- Thêm fallback tạo mã bữa/bài từ SQLite, xác thực lại bằng normalizer và đánh dấu `local_fallback`. `GeneratedPlanService` giới hạn fallback theo selector hồ sơ: bệnh lý, dị ứng, mục tiêu, thiết bị và hạn chế vận động. Nếu không đủ ứng viên phù hợp, không dùng dữ liệu chưa xác minh để lấp chỗ.
- Quy tắc tránh lặp của fallback chỉ so với các lựa chọn còn đủ điều kiện cho hồ sơ đó; mã không phù hợp không làm chặn lựa chọn hợp lệ.
- Sau mỗi cặp chunk bữa/vận động, chuẩn hóa và xác thực một ngày rồi ghi bữa, mục lịch, tiến độ request và nguồn tạo trong cùng SQLite transaction. Ngày đã ghi được giữ khi phần sau lỗi và dùng lại khi tiếp tục.
- Chế độ nối lịch chỉ upsert các ID do yêu cầu tạo; chế độ thay lịch xóa các dòng trong ngày trước khi ghi. Bước cuối kiểm tra đúng ID/ngày của request, cho phép mục người dùng khác cùng ngày tồn tại, sau đó chỉ hoàn tất request/cờ khách và dọn staging.
- Staging lưu nguồn từng chunk trong envelope JSON; hàng staging cũ không có nguồn được coi là `unknown`.
- Cập nhật tài liệu luồng và kiểm thử SQLite cho lỗi giữa chừng, resume, nguồn fallback và mục tùy chỉnh cùng ngày.

## File chính

- `lib/app_versions/v1/services/ai/ai_service.dart`
- `lib/app_versions/v1/services/ai/generated_plan_service.dart`
- `lib/app_versions/v1/services/ai/generated_plan_request_store.dart`
- `lib/app_versions/v1/features/meal_plan/data/models/meal_plan_ai_normalizer.dart`
- `lib/app_versions/v1/features/lifestyle_schedule/data/models/exercise_tasks_ai_normalizer.dart`
- `test/services/ai/ai_service_test.dart`
- `test/app_versions/v1/services/ai/generated_plan_service_auth_test.dart`
- `test/app_versions/v1/services/ai/generated_plan_request_store_test.dart`
- `test/features/meal_plan/data/meal_plan_ai_normalizer_test.dart`
- `test/features/lifestyle_schedule/data/exercise_tasks_ai_normalizer_test.dart`
- `docs/features/ai-generated-plan/004-feature-ai-14-call-resumable-plan.md`

## Kiểm chứng

- `flutter analyze` trên 10 file nguồn/test trong phạm vi: PASS, không có issue.
- `LD_LIBRARY_PATH=/tmp/nanobio-sqlite-lib flutter test test/app_versions/v1/services/ai/generated_plan_service_auth_test.dart test/app_versions/v1/services/ai/generated_plan_request_store_test.dart test/features/meal_plan/data/meal_plan_ai_normalizer_test.dart test/features/lifestyle_schedule/data/exercise_tasks_ai_normalizer_test.dart`: PASS, 26 kiểm thử. SQLite in-memory xác nhận ngày đầu còn sau `markFailed`, ngày sau tiếp tục ghi, hoàn tất request, giữ mục người dùng và không ghi quota cho fallback.
- `LD_LIBRARY_PATH=/tmp/nanobio-sqlite-lib flutter test test/services/ai/ai_service_test.dart --plain-name 'fallback'`: PASS, 10 kiểm thử tên khớp bộ lọc, gồm fallback lịch và các case fallback khác.
- `LD_LIBRARY_PATH=/tmp/nanobio-sqlite-lib flutter test test/services/ai/ai_service_test.dart --plain-name 'day API'`: PASS, 3 kiểm thử.
- `dart format --set-exit-if-changed` trên 10 file Dart trong phạm vi: PASS; `git diff --check`: PASS.
- `python3 .codex/tools/update_worklog_learning.py --write`: PASS, cập nhật 19 file history/task-skill.
- `pwsh -NoProfile -File .codex/tools/validate_codex_integrity.ps1`: FAIL do thiếu `docs/audit/source_truth_manifest.json` và các đường dẫn cũ trong history/task-skill (các tham chiếu `docs/supabase/*` và `docs/features/Nabi_character/*`); không thuộc phạm vi sửa lịch.
- `flutter test test/services/ai/ai_service_test.dart` trong lần chạy tổng hợp: FAIL ở các kiểm thử khác với fallback/API theo ngày, gồm log/API key của AI Chat và đường tạo trực tiếp theo chunk/model retry. Không coi nhóm kiểm thử này là bằng chứng cho đường tạo lịch theo ngày; không sửa ngoài phạm vi.
- FFI SQLite ban đầu không nạp được `libsqlite3.so`; thư viện có sẵn dưới tên phiên bản `libsqlite3.so.0`. Tạo symlink tạm trong `/tmp/nanobio-sqlite-lib` và chạy lại; không thay đổi repo.
- DTD đã được tìm; danh sách không có app Flutter đang kết nối và hot reload xác nhận không có app để tải lại. Không xác nhận trên thiết bị. Chưa gọi Gemini, quota backend hoặc Supabase live.

## Giới hạn

- Không thể bảo đảm tạo lịch khi đăng nhập, quota, SQLite hoặc catalog phù hợp bị chặn/hỏng. Fallback chỉ xử lý lỗi AI khi catalog địa phương có đủ dữ liệu đã xác minh cho hồ sơ.
- Kiểm thử xác nhận mã và SQLite cục bộ; chưa chứng minh runtime Gemini, Supabase, thiết bị hoặc toàn bộ onboarding.
- Suite AIService đầy đủ còn lỗi trong các nhóm nêu trên.

## Tự đánh giá

- Lịch không còn đợi cả tuần mới xuất hiện: mỗi ngày hợp lệ ghi độc lập; staging vẫn cho phép tiếp tục sau lỗi.
- Fallback không hạ bộ lọc an toàn và không tính là lịch AI khi xét quota.
- Task-skill dùng: `.codex/task-skills/coding.md`, `.codex/task-skills/test.md`.
