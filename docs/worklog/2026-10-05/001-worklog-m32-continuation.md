Commit de xuat: docs(m32): chuan bi runtime review va xac nhan PO

# Worklog — M32 continuation and approval follow-up

## Thời gian

- Ngày: 2026-10-05
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: M32 implementation readiness review
- Module chính: M32 FITNESS_TRAINING
- Mục tiêu: tiếp tục feature tới runtime theo chỉ thị người dùng, giữ nguyên cổng phê duyệt của repo.

## Đã làm

- Người dùng tự xác nhận vai trò PO và phê duyệt BD/DD v1.0 trong hội thoại ngày 2026-10-01; trạng thái này được ghi ở M32 BD/DD, với ghi chú tên hiển thị không được cung cấp.
- Người dùng xác nhận hiện chưa có sign-off Tech/QA/Clinical-Privacy và yêu cầu Codex tự xử lý. Tìm trong `docs/` và `.codex/` không thấy hồ sơ duyệt M32 có tên/ngày; không mượn sign-off của module khác.
- Đọc source FeatureHub/router, M02 generation/quota, schedule normalizer/replacement, SQLite table/version và `nabi-ai-generate`; ghi các hạn chế tương thích vào `docs/DD/fitness_training/Import_File.md` để Tech/QA/Clinical/Privacy review.
- Không chỉnh runtime vì `.codex/design/15_CODING_PLAN.md` yêu cầu phê duyệt PO, Tech, QA và Clinical/Privacy trước hành vi module mới; ba approval còn thiếu không thể tự ký thay.

## Findings cần reviewer xử lý

- Generator hiện tại tạo lịch 7 ngày; Guest có một lần tạo lịch ban đầu theo M02. M32 cần chương trình 28 ngày, chỉ áp một tuần; giữ nguyên quy tắc actor/quota.
- Exercise normalizer đòi hai bài mỗi ngày; không hỗ trợ ngày nghỉ, sets/reps và ràng buộc thiết bị M32.
- `seedGeneratedSchedule(replaceExistingRange: true)` xóa mọi schedule row trong date range; không đáp ứng yêu cầu giữ task sức khỏe khác và task hoàn thành.
- SQLite đang ở v24, chưa có program/check-in aggregate M32. Schema và sync member/FamilyPlus cần Tech/Privacy quyết định.
- Gemini Edge Function là provider proxy generic; cần Tech duyệt operation contract và structured-output validation cho generate/replan. Quota gateway M02 hiện riêng với rate limit kỹ thuật của Edge Function.
- Q01 age proof/retention, Q02 clinical movement/nutrition, Q03 member/FamilyPlus storage/RLS/consent/deletion, Q04 QA/platform matrix vẫn Open.

## Validation

- `git diff --check` — PASS.
- `.codex/tools/validate_codex_integrity.ps1` — FAIL chỉ trên repo-wide existing findings: thiếu `docs/audit/source_truth_manifest.json` và stale paths trong generated worklog/task-skill files.
- Flutter analyze/tests, Supabase sandbox and player smoke — chưa chạy; không có runtime code change.

## Trạng thái

- M32 DD vẫn Draft, runtime Absent.
- PO: Approved per explicit user confirmation; display name unavailable.
- Tech Lead, QA Lead, Clinical/Privacy: Pending; cần evidence cụ thể.
- Runtime work and implementation tests remain blocked by the documented module gate.
