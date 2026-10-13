Commit de xuat: feat(ai): gui day du catalog ma ten khi tao lich

# Worklog - Gửi đầy đủ catalog SQLite vào prompt lập lịch

## Thời gian

- Ngày: 2026-10-13
- Bắt đầu: 15:15
- Kết thúc: 15:42
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: Feature implementation, prompt/backend limits, focused tests.
- Module chính: M02 `PERSONAL_SCHEDULE_AI`, SQLite catalog, Supabase Edge Function.
- Yêu cầu gốc: gửi đủ 163 món và 40 bài tập dạng mã/tên trong 14 lượt; 24 bài M32 chỉ làm ngữ cảnh; bỏ trần 32.000 ký tự và chặn theo giới hạn model/request thực.

## Đã làm

- Thêm DAO/datasource đọc toàn bộ hàng món và bài tập, không lọc `is_active` hoặc trạng thái phù hợp trước khi tạo prompt.
- Prompt món gửi danh sách đầy đủ dưới dạng `{code, name}`; prompt vận động gửi toàn bộ `{code, name}` và chia 16 mã active/selectable với 24 mã inactive/context-only.
- Giữ normalizer xác thực mã hoạt động và từ chối mã bài tập inactive; giữ staging, thứ tự 14 lượt và commit nguyên tử.
- Gỡ bộ lọc ứng viên và truy vấn enrichment khỏi luồng tạo lịch; giữ dữ liệu hồ sơ ở cục bộ/fingerprint.
- Bỏ ngưỡng ký tự 32.000 trên app và Edge Function. Edge Function lấy `inputTokenLimit`/`outputTokenLimit`, gọi `countTokens` trên toàn request trước `generateContent`, kiểm tra output token và giới hạn request body UTF-8 ở 1.500.000 byte.
- Ánh xạ vượt giới hạn token hoặc byte request thành HTTP 413 có mã rõ ràng và thông báo Flutter; đổi prompt version để staging cũ không được dùng lại với prompt mới.
- Bổ sung kiểm thử đủ 163/40 cặp, hai nhóm bài tập, chặn mã inactive, payload trên 32k, giới hạn byte, token preflight và luồng 14 lượt.

## File code/docs đã sửa

- `lib/core/storage/localdb/daos/ai_catalog_dao.dart` - thêm truy vấn toàn bộ catalog cho tạo lịch.
- `lib/core/storage/localdb/datasources/ai_catalog_local_datasource.dart` - expose bundle catalog đầy đủ không tải enrichment.
- `lib/app_versions/v1/services/ai/prompts/meal_plan_prompt.dart` - gửi nguyên 163 cặp mã/tên.
- `lib/app_versions/v1/services/ai/prompts/exercise_tasks_prompt.dart` - gửi nguyên bài tập và phân nhóm chọn/ngữ cảnh.
- `lib/app_versions/v1/services/ai/generated_plan_service.dart` - bỏ lọc/enrichment trước AI, dùng catalog đầy đủ và prompt version mới.
- `lib/app_versions/v1/services/ai/ai_service.dart` - bỏ trần payload ký tự và dùng datasource đầy đủ mặc định.
- `lib/app_versions/v1/services/ai/nabi_ai_backend_client.dart`, `ai_exceptions.dart`, `onboarding_controller.dart` - ánh xạ lỗi giới hạn model.
- `supabase/functions/nabi-ai-generate/handler.ts`, `index.ts`, `gemini_context.ts` - đếm token thật, giới hạn byte, lỗi 413; không log nội dung prompt.
- `test/services/ai/ai_service_test.dart`, `test/services/ai/nabi_ai_backend_client_contract_test.dart`, `test/app_versions/v1/services/ai/generated_plan_service_auth_test.dart`, `test/features/lifestyle_schedule/data/exercise_tasks_ai_normalizer_test.dart`, `test/core/storage/localdb/ai_catalog_schedule_bundle_test.dart`, `supabase/functions/nabi-ai-generate/handler_test.ts`, `gemini_context_test.ts` - hợp đồng hồi quy mới.
- `docs/features/ai-generated-plan/005-feature-full-catalog-ai-context.md`, `docs/checklist/checklist_complete_DD.md`, `docs/checklist/checklist_task_coding.md` - cập nhật mô tả hiện hành.

## Tài liệu liên quan

- `.codex/workflows/coding.md`
- `.codex/domains/ai-service.md`
- `.codex/domains/sqlite.md`
- `docs/features/ai-generated-plan/004-feature-ai-14-call-resumable-plan.md`
- Gemini API: [models.get](https://ai.google.dev/api/models), [models.countTokens](https://ai.google.dev/api/tokens)

## Commands

- `dart format <tệp Dart trong phạm vi>`: PASS.
- `deno fmt <handler/provider/test files>`: PASS.
- `dart analyze <14 tệp Dart liên quan>`: PASS, không có vấn đề.
- `flutter test --concurrency=1 --plain-name 'AI prompts' test/services/ai/ai_service_test.dart`: PASS, 8 tests.
- `flutter test --concurrency=1 --plain-name 'AI service sends request content above 32,000 characters' test/services/ai/ai_service_test.dart`: PASS, 1 test.
- `flutter test --concurrency=1 test/core/storage/localdb/ai_catalog_schedule_bundle_test.dart test/services/ai/nabi_ai_backend_client_contract_test.dart test/features/lifestyle_schedule/data/exercise_tasks_ai_normalizer_test.dart`: PASS, 7 tests.
- `flutter test --concurrency=1 --plain-name 'model token limit failures' test/services/ai/ai_service_test.dart`: PASS, 1 test.
- `flutter test --concurrency=1 --plain-name 'request byte limit failures' test/services/ai/ai_service_test.dart`: PASS, 1 test.
- `flutter test --concurrency=1 --plain-name 'empty local meal catalog fails' test/app_versions/v1/services/ai/generated_plan_service_auth_test.dart`: PASS, 1 test.
- `flutter test --concurrency=1 --plain-name 'seven day plan runs fourteen ordered AI chunks before commit' test/app_versions/v1/services/ai/generated_plan_service_auth_test.dart`: PASS, 1 test.
- `deno check supabase/functions/nabi-ai-generate/index.ts`: PASS.
- `deno test supabase/functions/nabi-ai-generate/handler_test.ts supabase/functions/nabi-ai-generate/gemini_context_test.ts`: PASS, 15 tests; no live Gemini request.
- Dart Tooling Daemon `hot_reload` on connected Xiaomi 220333QPG app: PASS; runtime errors query: none.
- `git diff --check`: PASS.
- `.codex/tools/validate_codex_integrity.ps1`: FAIL due missing `docs/audit/source_truth_manifest.json` and stale paths in existing `.codex/history`/`task-skills/nabi-character` content; no files in those stale references were part of this task.
- Initial broad multi-file `flutter test` invocation: NOT CLEAN. It showed AIChat/trace logging expectations with empty captured logs, an old normalizer fixture with fields outside the current AI output schema, and native SQLite FFI unavailable for the first DAO harness. The fixture was aligned to `day`/`exercise_code`, and the DAO contract test now uses a fake query executor; all focused catalog/prompt/staging tests passed afterward. The whole AIService suite was not rerun, so broader test acceptance remains open.
- Gemini live call, Edge deploy, Supabase quota, and schedule generation on device: NOT RUN.

## Lỗi/Rủi ro

- Đã sửa: full catalog no longer disappears behind activity/safety filters; old 32k request gate is removed; actual model token overflow is reported explicitly.
- Chưa sửa: AI can only judge catalog names, not verified nutrition, allergens, conditions, or exercise contraindications. Context-only draft exercises can be seen but remain rejected at normalization.
- Chưa xác minh: deployed Edge Function, real Gemini token count, provider quota and end-to-end device-generated plan.
- Cần kiểm tra tiếp: deploy Edge Function in QA, then run one authorized plan request and verify the saved 7-day/35-meal/14-activity result.

## Tỷ lệ hoàn thành

- Hoàn thành: source path, prompt contents, token/request guards, response mapping, focused tests, and hot reload.
- Đang dở: hosted Edge deployment and live provider/device acceptance.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - giữ đủ danh sách, giữ cổng mã lưu và không giả định dữ liệu y tế từ tên.
- Mức độ hoàn thành task: source implementation hoàn tất; production/device evidence chưa có.
- Bằng chứng kiểm chứng: focused Flutter tests pass, Deno 15/15, targeted analyzer clean, Xiaomi hot reload succeeded.
- Điểm tốn token/chưa tối ưu: broad Flutter invocation exposed unrelated legacy logging-test issues; smaller test filters produced clear evidence.
- Cách tối ưu cho phiên sau: deploy QA Edge Function first; then check request counts and saved plan without exporting health payload.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`
