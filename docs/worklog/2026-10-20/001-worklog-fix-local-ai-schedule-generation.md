Commit đề xuất: docs(worklog): ghi nhận fix tạo lịch AI local

# Worklog - Fix tạo lịch bằng AI local trên Xiaomi

## Thời gian

- Ngày: 2026-10-20
- Bắt đầu: Không ghi nhận chính xác; tiếp tục QA debug trên Xiaomi.
- Kết thúc: 13:29
- Timezone: Asia/Saigon

## Phạm vi

- Loại task: Điều tra, fix bug, test và QA trên thiết bị thật theo plan đã duyệt.
- Module chính: local AI runtime, AI schedule generation, onboarding guest, event staging và SQLite.
- Yêu cầu gốc: Xác định vì sao AI local dừng ở 0/77, sửa để tạo lịch mới, chạy onboarding synthetic trên Xiaomi, và kiểm tra debug/release mà không ghi seed production.

## Đã làm

- Nạp context project/NanoBioAI và giữ nguyên các thay đổi dirty có trước task.
- Đo Qwen3 0.6B Q4 trên Xiaomi RAM 3,77 GB; catalog v36 lọc 3.113/3.163 món và prompt vừa context 2.048 token.
- Tìm ra candidate enum có mã selectable ngoài allowlist của slot. Model trả 5 mã compact, nhưng normalizer dừng fail-closed với `meal_code_not_eligible`.
- Sửa prompt/schema candidate theo từng slot, ghép code AI vào slot hợp lệ, ngân sách compact response và Android inference còn một thread.
- Thêm trace metadata allowlist và regression để chặn candidate ngoài allowlist; không ghi prompt/response, tên món hay hồ sơ sức khỏe vào trace.
- Chạy onboarding guest bằng fixture SyntheticQA qua UI thật. Debug tạo 7 ngày, 35 bữa, 14 bài tập và 77 schedule items; request succeeded với `generation_source=ai`; cả 35 bữa và 77 item đều `ai_generated=1`, staging rỗng, không có fallback. SQLite và timeline UI đều được xác nhận.
- Release APK build và signature verification PASS. MIUI/System Verifier từ chối cài cả release và debug qua ADB với `INSTALL_FAILED_USER_RESTRICTED`; không thay đổi/bypass cơ chế verifier. Release onboarding QA còn mở.
- Giữ máy offline trong các lượt tạo lịch, không login và không ghi Supabase production. Sau thử cài release, gói app bị gỡ; SQLite/model synthetic được giữ trong `/tmp`.

## File code/docs đã sửa

- `lib/app_versions/v1/services/ai/ai_service.dart` - giới hạn candidate theo slot, compact JSON/schema và matching code AI vào slot hợp lệ.
- `lib/app_versions/v1/services/ai/generated_plan_service.dart` - chuyển prefilter nặng sang compute và trace số liệu lọc an toàn.
- `lib/app_versions/v1/services/ai/ai_trace_logger.dart` - allowlist metadata diagnostics và compact-slot alignment.
- `lib/app_versions/v1/services/ai/prompts/meal_plan_prompt.dart` - hướng dẫn output compact một ngày đúng schema.
- `lib/core/ai_local/local_ai_runtime_service_native.dart` - Android inference dùng một worker để UI responsive.
- `test/services/ai/ai_service_test.dart` - regression candidate allowlist và compact output alignment.
- `docs/fixbug/local-ai-schedule-generation/001-fixbug-local-ai-schedule-generation.md` - nguyên nhân, sửa lỗi và bằng chứng QA.

## Tài liệu liên quan

- `.codex/DOCS_WORKFLOW.md`
- `docs/features/ai-generated-plan/009-feature-local-meal-catalog-prefilter.md`
- `docs/features/ai-generated-plan/010-feature-event-staged-plan-generation.md`
- `docs/worklog/2026-10-19/001-worklog-generated-plan-event-staging.md`
- `docs/worklog/2026-10-19/002-worklog-filtered-meal-progress.md`
- `docs/worklog/2026-10-19/003-worklog-local-classification-candidate-coverage.md`

## Commands

- `flutter test test/services/ai/ai_service_test.dart --plain-name 'meal array uses a constrained JSON items envelope'`: PASS.
- `flutter test test/services/ai/ai_service_test.dart --plain-name 'meal shortlist excludes selectable unclassified rows outside slot eligibility'`: PASS.
- `flutter test test/services/ai/ai_service_test.dart --plain-name 'active unreviewed candidate is rejected and excluded from fallback'`: PASS.
- `flutter test test/app_versions/v1/services/ai/generated_plan_request_store_test.dart test/app_versions/v1/services/ai/generated_plan_service_auth_test.dart test/features/meal_plan/data/meal_plan_ai_normalizer_test.dart`: PASS - 36 tests.
- `dart analyze` AI/runtime files and `ai_service_test.dart`: PASS - no issues.
- `flutter build apk --debug`: PASS - built and installed before release-signer QA.
- `flutter build apk --release`: PASS - 649.3 MB; signature verified with `apksigner`.
- `adb install --no-streaming app-release.apk`: FAIL - `INSTALL_FAILED_USER_RESTRICTED`; repeat with debug APK and direct `pm install` also rejected by device.
- `flutter analyze --no-pub`: FAIL - missing dependencies in nested `iot/xiaozhi-esp32/phone_app`, plus one unrelated dashboard info; touched files pass targeted analyze.
- `git diff --check`: PASS.

## Lỗi/Rủi ro

- Đã fix: AI candidate enum không tương thích allowlist từng slot; model response bị normalizer từ chối.
- Đã giảm rủi ro: native inference tranh CPU với UI trên Xiaomi RAM thấp.
- Chưa fix: device verifier/MIUI chặn cài APK unverified qua ADB, nên chưa lặp lại acceptance trên release.
- Cần kiểm tra tiếp: cài release sau khi có luồng ADB/phân phối được verifier chấp nhận; lặp lại onboarding synthetic và đối chiếu 77 item/source.

## Tỷ lệ hoàn thành

- Hoàn thành: sửa lỗi, targeted tests/analyze, debug build và guest onboarding + tạo lịch AI local trên Xiaomi.
- Đang dở: release APK đã build/ký nhưng chưa cài được trên Xiaomi; release device acceptance còn mở.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - root cause được tái hiện trên model thật, fix giữ nguyên safety/quota/horizon và có DB/UI evidence.
- Mức độ hoàn thành task: mục tiêu tạo lịch đạt trên debug; một phần trong plan release bị device verifier chặn.
- Bằng chứng kiểm chứng: 7/7 ngày AI, 35 bữa, 14 bài tập, 77 schedule items, onboarding guest hoàn tất, timeline hiển thị; không ghi Supabase.
- Điểm tốn token/chưa tối ưu: release native APK 649 MB và R8 cần 283 giây trên host; MIUI verifier ngăn install.
- Cách tối ưu cho phiên sau: kiểm tra sớm install policy/signature trên Xiaomi trước khi chạy release build dài; duy trì fixture local và thống kê DB aggregate.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md` và `.codex/task-skills/test.md`.
