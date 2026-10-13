Commit de xuat: fix(ai): giữ số lần dùng mã khi tạo lịch cá nhân

# Worklog - Sửa lỗi tạo lịch do prompt thiếu số lần dùng mã

## Thời gian

- Ngày: 2026-10-13
- Bắt đầu: 19:14 (tiếp tục phiên chẩn đoán)
- Kết thúc: 19:26
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: Bugfix, phân loại lỗi, kiểm chứng trên thiết bị thật.
- Module chính: AI generated plan, meal prompt, exercise prompt, onboarding retry.
- Yêu cầu gốc: xác định vì sao người dùng không tạo được lịch và tạo thành công lịch mới trên điện thoại.

## Đã làm

- Xác định lỗi runtime đầu tiên là `exercise_code_reuse_limit`: normalizer chặn mã bài tập đã dùng quá 2 lần khi còn lựa chọn ít dùng hơn; prompt trước chỉ nhận danh sách mã duy nhất, không nhận số lần dùng. Lỗi `FormatException` làm generation dừng và transaction all-or-nothing không lưu lịch một phần.
- Prompt bài tập nhận map số lần dùng, ghi rõ ngày chunk, yêu cầu hai mã khác nhau mỗi ngày và tránh mã đã dùng hai lần khi còn lựa chọn khác.
- Lượt tiếp theo vượt qua phần bài tập đến ngày 5 nhưng dừng ở `meal:6` với mã chung `invalid_generation`. Phiên bản khi đó chưa phân loại lỗi validator thực đơn.
- Prompt thực đơn nhận map số lần dùng, sắp xếp map ổn định, ghi ngày chunk vào schema và nêu giới hạn lặp tương ứng validator. Thêm các mã lỗi thực đơn an toàn; tăng prompt version lên v5 để sinh lại toàn bộ staging.
- Tạo lịch v5 trên Xiaomi thành công: 7 ngày 2026-10-13–2026-10-19, 35 bữa, 14 bài tập, 77 mục lịch. SQLite xác nhận 35 dòng `meal_plans`, 77 dòng `lifestyle_schedule_items`, đủ 7 ngày; staging rỗng. Dashboard hiển thị lịch hôm nay.
- Kiểm tra Edge Function `nabi-ai-generate`: version đang hoạt động 13, source trùng source local đã kiểm tra. Không sửa/deploy backend.

## File code/docs đã sửa

- `lib/app_versions/v1/services/ai/prompts/exercise_tasks_prompt.dart` - truyền tần suất dùng mã và ràng buộc reuse.
- `lib/app_versions/v1/services/ai/prompts/meal_plan_prompt.dart` - nhận số lần dùng mã và nêu hợp đồng reuse cho thực đơn.
- `lib/app_versions/v1/services/ai/ai_service.dart` - truyền count map nguyên vẹn vào hai prompt.
- `lib/app_versions/v1/services/ai/generated_plan_service.dart` - thêm mã lỗi validator thực đơn và prompt version v5.
- `test/app_versions/v1/services/ai/prompts/exercise_tasks_prompt_test.dart` - kiểm tra ngày/count/ràng buộc prompt.
- `test/app_versions/v1/services/ai/prompts/meal_plan_prompt_test.dart` - kiểm tra ngày/count/ràng buộc prompt.
- `test/services/ai/ai_service_test.dart`, `test/services/ai/schedule_ai_personalization_context_test.dart`, `test/core/storage/localdb/ai_catalog_schedule_bundle_test.dart` - cập nhật call sites prompt theo count map.
- `docs/fixbug/onboarding-unverified-catalog-block/001-fixbug-onboarding-unverified-catalog-block.md` - thêm kết luận dựa trên lần tái hiện runtime và đánh dấu chẩn đoán cũ đã được thay thế.
- `docs/worklog/2026-10-13/007-worklog-ai-schedule-reuse-limit.md` - worklog phiên.

## Tài liệu liên quan

- `.codex/workflows/bugfix.md`
- `.codex/domains/ai-service.md`
- `.codex/domains/onboarding.md`
- `.codex/history/SESSION_QUALITY_REVIEW.md`

## Commands

- `dart format` trên 7 file Dart liên quan: PASS.
- `flutter test --concurrency=1` cho meal/exercise prompt, AI service, personalization context và catalog bundle: prompt tests và các nhóm liên quan tới generation/catalog PASS; 14 lỗi còn lại nằm ở nhóm AI chat logging/missing-key, chưa xác minh baseline.
- `flutter test --concurrency=1 --plain-name 'meal generation' test/services/ai/ai_service_test.dart`: 2 PASS, 1 FAIL do test metadata logging nhận chuỗi rỗng; request sinh 35 bữa và kiểm tra invalid chunk đều PASS.
- `flutter analyze` trên 8 file nguồn/test liên quan: PASS, không có vấn đề.
- `git diff --check`: PASS.
- Dart Tooling Daemon hot restart Xiaomi: PASS.
- Tạo lịch bằng app trên Xiaomi: PASS; request `succeeded`, 35 meals, 14 exercises, 77 schedule items, không còn staging.
- Edge Function deploy: SKIPPED; source/version hiện hành trùng source local và không cần backend change.

## Lỗi/Rủi ro

- Đã sửa: mất tần suất mã đã dùng khi xây prompt; validator không còn áp một hợp đồng lặp khác với prompt.
- Đã xác nhận: lần lỗi đầu có mã `exercise_code_reuse_limit`; retry kế tiếp dừng ở `meal:6` với mã chung, nên nguyên nhân cụ thể của chunk thực đơn cũ chưa được xác nhận độc lập.
- Chưa xử lý: test logging/missing-key trong `ai_service_test.dart` vẫn fail ở môi trường hiện tại; các kiểm tra đó không chặn generation và không tác động tới kết quả thiết bị.
- Chưa làm: chưa tạo release build; chỉ xác nhận source debug đang chạy trên thiết bị.

## Tỷ lệ hoàn thành

- Hoàn thành: xác định lỗi gốc, sửa prompt, tạo và xác nhận lịch 7 ngày trên thiết bị.
- Đang dở: điều tra riêng các test chat logging/missing-key nếu chúng thuộc scope sau này.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - mã lỗi gốc được lấy từ request thật; không lưu prompt, phản hồi AI, định danh hoặc nội dung hồ sơ.
- Mức độ hoàn thành task: hoàn thành; lịch đã được commit cục bộ trên điện thoại và hiển thị trong dashboard.
- Bằng chứng kiểm chứng: request row `succeeded`; 35 meal rows; 77 schedule rows theo 7 ngày; dashboard hiển thị lịch hôm nay; prompt tests/analyzer/hot restart pass.
- Điểm tốn token/chưa tối ưu: lượt retry v4 cần thêm một request để lộ lỗi tiếp theo ở `meal:6`; mã lỗi meal-specific chưa tồn tại lúc đó.
- Cách tối ưu cho phiên sau: giữ mã lỗi validator ổn định và count map trong mọi prompt có giới hạn reuse; tiếp tục dùng aggregate DB counts và widget text thay vì đọc payloads.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`.
