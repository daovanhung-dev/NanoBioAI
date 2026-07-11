Commit de xuat: docs(worklog): ghi nhan phien v2 admin p0 baseline

# Worklog - P0 baseline regression v2 + Admin

## Thời gian

- Ngày: 2026-07-11
- Bắt đầu: 22:30
- Kết thúc: 23:45
- Timezone: Asia/Saigon

## Phạm vi

- Loại task: bugfix
- Module chính: M01 Onboarding, M05 AI, M11 FamilyPlus automated-only và
  generated-plan logging.
- Yêu cầu gốc: triển khai P0 của kế hoạch kiểm thử toàn hệ thống v2 + Admin,
  sửa 6 baseline failures và loại bỏ raw AI prompt/response khỏi log.

## Đã làm

- Tái hiện chính xác 6 baseline failures trước khi sửa.
- Đối chiếu FamilyPlus với DD và xác định production copy đúng, test bị stale.
- Sửa responsive hero xuyên 8 bước onboarding trên viewport 390x844; khôi
  phục stable key của AI dev banner và cập nhật contract test.
- Thay AI trace tùy ý bằng metadata whitelist; redacted exception/stack,
  prompt, response, health profile và output dẫn xuất.
- Che request id của generated plan bằng fingerprint ổn định trong log.
- Thêm negative regression tests với sentinel cho AI plan/chat/error logging.
- Chạy targeted regression, full analyzer và full test suite.

## File code/docs đã sửa

- `lib/app_versions/v1/features/onboarding/presentation/widgets/welcome_step.dart` - sửa - responsive hero và stable AI banner key.
- `lib/app_versions/v1/features/onboarding/presentation/widgets/lifestyle_step.dart` - sửa - chống overflow headline/status chip.
- `lib/app_versions/v1/features/onboarding/presentation/widgets/extras_step.dart` - sửa - chống overflow headline/progress chip.
- `lib/app_versions/v1/features/onboarding/presentation/widgets/consent_step.dart` - sửa - chống overflow headline/status chip.
- `lib/app_versions/v1/services/ai/ai_trace_logger.dart` - sửa - metadata-only và redacted error.
- `lib/app_versions/v1/services/ai/ai_service.dart` - sửa - loại raw prompt/response/health/output log, thêm duration/count metadata.
- `lib/app_versions/v1/services/ai/ai_chat_service.dart` - sửa - dùng safe validation/cooldown metadata.
- `lib/app_versions/v1/services/ai/generated_plan_service.dart` - sửa - che request id và error type.
- `test/widget_test.dart` - sửa - stable banner/copy/mobile 8-step regression.
- `test/services/ai/ai_service_test.dart` - sửa - negative redaction regression.
- `test/app_versions/v3/features/familyplus/presentation/familyplus_page_test.dart` - sửa - expectation đúng DD/Nabitone.
- `docs/fixbug/v2-admin-p0-baseline/001-fixbug-v2-admin-p0-baseline.md` - tạo - mô tả root cause, fix và gate.
- `docs/worklog/2026-07-11/001-worklog-v2-admin-p0-baseline.md` - tạo - ghi nhận phiên P0.

## Tài liệu liên quan

- `.codex/workflows/bugfix.md`
- `.codex/task-skills/bugfix.md`
- `.codex/domains/onboarding.md`
- `.codex/domains/ai-service.md`
- `docs/test/v2-admin-regression/001-test-v2-admin-regression.md`
- `docs/DD/README.md`

## Commands

- Baseline `flutter test test/widget_test.dart test/app_versions/v3/features/familyplus/presentation/familyplus_page_test.dart`: FAIL 6 case, đã tái hiện trước patch.
- Targeted onboarding/AI/generated-plan/FamilyPlus suite: PASS 80/80.
- `flutter analyze`: PASS, no issues.
- `flutter test --reporter compact`: PASS 510/510.
- Source grep forbidden AI log steps: PASS, không còn call site raw payload.
- `git diff --check`: PASS, không có whitespace error.

## Lỗi/Rủi ro

- Đã fix: 6 baseline failures; các overflow mobile lần lượt lộ ra trong hành
  trình onboarding 8 bước; AI raw prompt/response/health/error logging.
- Chưa fix: các gap capability/RBAC/Supabase/E2E còn lại của kế hoạch tổng.
- Cần kiểm tra tiếp: boot v2/Admin trên thiết bị, Supabase sandbox/seed/RBAC,
  live Gemini remote source và evidence ảnh/note cho từng case.

## Tỷ lệ hoàn thành

- Hoàn thành: gate P0 code-level baseline và AI logging hardening.
- Đang dở: hybrid harness, sandbox, 101+ case v2/Admin và evidence audit.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - có reproduction, patch theo root cause, regression
  âm cho dữ liệu nhạy cảm và full suite sạch.
- Mức độ hoàn thành task: hoàn tất một gate P0, chưa hoàn tất objective toàn hệ thống.
- Bằng chứng kiểm chứng: 80 targeted PASS, 510 full PASS, analyzer PASS và static grep PASS.
- Điểm tốn token/chưa tối ưu: full suite log rất dài; lần sau lưu machine-readable summary và giới hạn console output.
- Cách tối ưu cho phiên sau: dựng harness/evidence schema trước, sinh case inventory từ matrix thay vì đọc từng case thủ công.
- Task-skill cần đọc lần sau: task-skill của workflow testing/E2E được router chọn ở phase kế tiếp.
