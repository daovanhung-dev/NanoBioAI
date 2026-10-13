Commit de xuat: feat(ai): retry va tach slot cho ngay tao lich loi

# Worklog - Retry AI và tách món khi tạo lịch lỗi

## Thời gian

- Ngày: 2026-10-13
- Bắt đầu: không lưu chính xác trong trạng thái phiên
- Kết thúc: 20:49
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: bugfix M02 `PERSONAL_SCHEDULE_AI`.
- Yêu cầu: khi tạo lịch gặp lỗi/response rỗng/JSON sai, thử AI lại với model cao hơn; sau hơn năm lần lỗi ở ngày bữa thì tách món riêng; tiếp tục các ngày khác theo lượt ngày và cho phép resume.
- Giữ nguyên thay đổi ngoài M02 trong worktree; không gọi Gemini thật, deploy Supabase hay ghi dữ liệu lên thiết bị.

## Đã làm

- Mỗi đơn vị AI có một lượt đầu và tối đa năm lần retry (6 backend attempts). Retry đi dọc chuỗi model đã cấu hình, dùng model cuối cho các lần tiếp theo; lỗi transient có delay/cooldown.
- Tạo bữa theo ngày tắt local fallback toàn ngày để sau sáu lần lỗi ngày đó chuyển sang năm yêu cầu slot riêng. Mỗi slot cũng thử sáu lần, sau đó mới dùng fallback local qua selector và normalizer.
- Giữ từng slot trong SQLite staging để lần tiếp theo bỏ qua các slot đã xong và chỉ gọi lại slot lỗi. Ngày tiếp theo vẫn theo lượt tạo bữa đầy đủ; vận động tiếp tục có retry và fallback đã lọc.
- Nâng giới hạn local request ledger và Edge Function lên 300 backend calls. Tệ nhất với 7 ngày là 294 calls: 6 lượt ngày + 30 lượt slot + 6 lượt vận động mỗi ngày.
- Đưa Gemini 3.8 Flash vào server allowlist và chuẩn hóa `thinkingLevel`/`thinkingBudget` theo họ model ở Gemini provider.
- Thêm unit/integration regression cho sáu lần gọi, model escalation, slot local fallback, chỉ tách ngày lỗi và resume staging ở đúng slot. Cập nhật feature doc, M02 checklist và worklog.
- Giữ nhất quán quyền chọn AI giữa lượt ngày và lượt slot: AI slot có thể chọn mã active từ catalog đầy đủ; tập selector chỉ được áp dụng cho local fallback sau khi hết retry.

## File code/docs đã sửa

- `lib/app_versions/v1/services/ai/ai_service.dart` - 6 attempts, model escalation và API tạo slot.
- `lib/app_versions/v1/services/ai/generated_plan_service.dart` - tách bữa theo slot, staging/resume và tiếp tục ngày sau.
- `lib/app_versions/v1/services/ai/generated_plan_request_store.dart` - trần 300 backend calls mỗi phiên.
- `lib/app_versions/v1/services/ai/prompts/meal_plan_prompt.dart` - prompt chỉ định một loại bữa.
- `lib/app_versions/v1/features/meal_plan/data/models/meal_plan_ai_normalizer.dart` - validation riêng cho slot.
- `supabase/functions/_shared/gemini_provider.ts`, `supabase/functions/nabi-ai-generate/index.ts`, `supabase/functions/nabi-ai-generate/handler_test.ts` - thinking config, allowlist, rate limit và contract.
- `test/services/ai/ai_service_test.dart` - kiểm thử retry/model/fallback.
- `test/app_versions/v1/services/ai/generated_plan_service_auth_test.dart` - kiểm thử tách ngày và resume slot.
- `docs/features/ai-generated-plan/006-feature-model-escalation-meal-slot-split.md` - mô tả capability mới và giới hạn xác nhận.
- `docs/checklist/checklist_complete_DD.md`, `docs/checklist/checklist_task_coding.md` - cập nhật trạng thái M02.

## Commands

- `dart format` trên các Dart files thuộc flow và test: PASS; kiểm tra cuối `dart format --set-exit-if-changed` xác nhận 8 files không còn đổi format.
- `LD_LIBRARY_PATH=/tmp/nanobio-sqlite-lib flutter test test/app_versions/v1/services/ai/generated_plan_service_auth_test.dart --plain-name 'splits only the failed meal day into slots and resumes full days afterward'`: PASS.
- `LD_LIBRARY_PATH=/tmp/nanobio-sqlite-lib flutter test test/app_versions/v1/services/ai/generated_plan_service_auth_test.dart --plain-name 'resumes a failed meal slot without regenerating the day'`: PASS.
- `LD_LIBRARY_PATH=/tmp/nanobio-sqlite-lib flutter test test/services/ai/ai_service_test.dart --plain-name 'day API retries HTTP 429 using the higher model'`: PASS.
- `LD_LIBRARY_PATH=/tmp/nanobio-sqlite-lib flutter test test/services/ai/ai_service_test.dart --plain-name 'all transient model failures stop plan generation'`: PASS.
- `LD_LIBRARY_PATH=/tmp/nanobio-sqlite-lib flutter test test/services/ai/ai_service_test.dart --plain-name 'split meal generation uses local choice after six failed AI calls'`: PASS.
- `LD_LIBRARY_PATH=/tmp/nanobio-sqlite-lib flutter test test/services/ai/ai_service_test.dart --plain-name 'slot AI may use active catalog items outside local fallback subset'`: PASS.
- `LD_LIBRARY_PATH=/tmp/nanobio-sqlite-lib flutter test test/services/ai/ai_service_test.dart --plain-name 'allows one initial request and five retries per generation chunk'`: PASS.
- `LD_LIBRARY_PATH=/tmp/nanobio-sqlite-lib flutter test test/services/ai/ai_service_test.dart --plain-name 'prioritizes primary, fallback, overflow, and de-duplicates'`: PASS.
- `LD_LIBRARY_PATH=/tmp/nanobio-sqlite-lib flutter test test/app_versions/v1/services/ai/generated_plan_request_store_test.dart`: PASS.
- `flutter analyze` trên 8 source/test files thuộc flow sau thay đổi cuối: PASS, không có issue.
- `deno test supabase/functions/nabi-ai-generate/handler_test.ts supabase/functions/nabi-ai-generate/gemini_context_test.ts`: PASS, 17 tests.
- Hai lần đầu dùng `--plain-name` với nhiều tên ngăn bằng `|` nên Flutter không khớp test; chạy lại từng tên đơn và tất cả đều PASS.
- DTD discovery tìm thấy IDE instance nhưng không có app Flutter kết nối. Xiaomi đang mở `com.nanobioai.app`; không cài đè package chính. Đã thử `flutter run --debug --no-pub -d linux` để hot restart trong môi trường riêng nhưng Linux build dừng vì thiếu CMake. Device/hot reload QA còn chưa xác nhận.
- `pwsh -NoProfile -File .codex/tools/validate_codex_integrity.ps1`: FAIL do thiếu `docs/audit/source_truth_manifest.json` và các stale backticked paths ở `.codex/history/WORKLOG_2026-08-16_meal_nutrition_estimation.md` và `.codex/task-skills/nabi-character/SKILL.md`; không thuộc phạm vi M02.
- `git diff --check`: PASS.
- `pwsh -NoProfile -File .codex/tools/update_worklog_learning.ps1`: PASS, refresh 19 deterministic history/task-skill files.

## Lỗi/Rủi ro

- Đã fix: tách ngưỡng thành đúng một lượt ban đầu + năm lần retry trước khi đổi đơn vị tạo bữa; resume không gọi lại ngày/slot đã staging.
- Chưa fix: không có lỗi source còn lại trong phạm vi kiểm thử mục tiêu.
- Cần kiểm tra tiếp: Gemini thật, model allowlist sau deploy, quota/rate limit Supabase sandbox, dữ liệu catalog phù hợp trên profile thật và onboarding trên thiết bị.

## Tỷ lệ hoàn thành

- Hoàn thành: source, focused tests, model/server contract và tài liệu/checklist.
- Đang đo: device/runtime/provider/Supabase acceptance; chưa coi đây là production acceptance.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - retry có giới hạn rõ, fallback tôn trọng selector an toàn, staging cho phép tiếp tục tại slot lỗi.
- Mức độ hoàn thành task: source và regression tests hoàn thành; live Gemini, device và sandbox chưa xác minh.
- Bằng chứng kiểm chứng: analyzer sạch; tests retry, model escalation, split/resume, request store và Deno đều PASS.
- Điểm tốn token/chưa tối ưu: test name OR filter không được Flutter nhận; lần sau chạy theo từng tên hoặc suite mục tiêu.
- Cách tối ưu cho phiên sau: tiếp tục từ M02 feature doc và chạy một synthetic QA request sau khi model 3.8 được deploy vào sandbox.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`.
