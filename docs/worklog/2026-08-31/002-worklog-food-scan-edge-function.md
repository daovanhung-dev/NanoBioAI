Commit de xuat: docs(worklog): ghi nhan phien food scan edge function

# Worklog - Food Scan Edge Function

## Thời gian

- Ngày: 2026-08-31
- Bắt đầu: 05:45
- Kết thúc: 06:16
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: coding / deploy / test
- Module chính: V3 Food Scan, AI runtime, Supabase Edge Functions
- Yêu cầu gốc: tạo và chạy Edge Function cho chức năng quét thức ăn.

## Đã làm

- Tách resolver model và generation config dùng chung cho Gemini provider.
- Tạo `food-scan-analyze` với operation `vision` và `health`.
- Thêm JWT, Plus/FamilyPlus access check, rate limit, validation ảnh/text và
  safe error response.
- Mở rộng `NabiAiBackendClient` để gửi operation; nối Food Scan datasource tới
  function mới.
- Giữ ảnh, prompt, health context và kết quả ngoài log/database của Edge.
- Deploy function lên project Supabase đã link.

## File code/docs đã sửa

- `supabase/functions/_shared/gemini_provider.ts` - tạo shared model/config resolver.
- `supabase/functions/food-scan-analyze/` - tạo handler, entrypoint và tests.
- `supabase/functions/nabi-ai-generate/handler.ts` - dùng shared resolver.
- `supabase/config.toml` - khai báo function với `verify_jwt=true`.
- `lib/app_versions/v1/services/ai/nabi_ai_backend_client.dart` - thêm operation.
- `lib/app_versions/v3/features/food_scan/data/datasources/food_scan_ai_datasource.dart` - dùng endpoint mới.
- `test/app_versions/v3/features/food_scan/food_scan_ai_backend_contract_test.dart` - thêm contract check.
- `docs/features/food-scan/001-feature-food-scan-edge-function.md` - ghi runtime contract.
- `docs/test/edge-functions/002-test-food-scan-edge-function-2026-08-31.md` - ghi evidence.

Các thay đổi AI Voice có sẵn trong worktree được giữ nguyên.

## Tài liệu liên quan

- `docs/tasks/NanoBioAI_Task_Cross_Feature_Health_Orchestration.md`
- `docs/supabase/README.md`
- `.codex/domains/ai-service.md`
- `.codex/domains/access-membership-referral.md`

## Commands

- `deno test --no-lock supabase/functions/food-scan-analyze/handler_test.ts`: PASS - 11/11.
- `find supabase/functions -type f -name 'handler_test.ts' -print0 | xargs -0 deno test --no-lock`: PASS - 51/51.
- `find supabase/functions -type f -name 'index.ts' -print0 | xargs -0 deno check --no-lock`: PASS - 10/10.
- `deno fmt --check ...`: PASS.
- `git diff --check`: PASS.
- `supabase functions deploy food-scan-analyze --project-ref rnwohifdnylqfofkydfl --use-api`: PASS - deployed version 2.
- `supabase functions list --project-ref rnwohifdnylqfofkydfl`: PASS - function ACTIVE, verify_jwt true.
- `curl POST /functions/v1/food-scan-analyze` không Authorization: PASS - HTTP 401.
- `curl POST /functions/v1/food-scan-analyze` với anon token: PASS - HTTP 401 từ handler.
- `powershell -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1`: FAIL - baseline thiếu `docs/audit/source_truth_manifest.json` và còn stale paths lịch sử ngoài phạm vi task.
- `python3 tools/validate_docs_source_truth.py`: FAIL - baseline thiếu `docs/audit/source_truth_manifest.json`.
- `flutter test ...`: UNVERIFIED - không có Flutter SDK trong workspace.
- `flutter analyze ...`: UNVERIFIED - không có Flutter SDK trong workspace.

## Lỗi/Rủi ro

- Đã fix: function mới không còn dùng endpoint AI generic cho Food Scan; model
  config Gemini 2.5 được normalize trước provider call.
- Chưa fix: chưa có access token Plus để chạy remote `vision` và `health` thành công.
- Cần kiểm tra tiếp: chạy authorized smoke test và Flutter test/analyze trên
  máy có toolchain Flutter cùng tài khoản Plus test được cấp quyền.

## Tỷ lệ hoàn thành

- Hoàn thành: code, unit tests Edge, type-check, deploy remote và auth boundary smoke.
- Đang dở: authorized remote success smoke; Flutter verification.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - endpoint riêng, quyền server-side và contract tương thích.
- Mức độ hoàn thành task: partial - đã tạo và deploy; success path cần token Plus.
- Bằng chứng kiểm chứng: 51/51 Edge tests, 10/10 entrypoint checks, remote ACTIVE và 401 boundary.
- Điểm tốn token/chưa tối ưu: provider HTTP extraction còn lặp giữa các function.
- Cách tối ưu cho phiên sau: bổ sung authorized smoke bằng token tạm và cân nhắc shared provider transport.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`
