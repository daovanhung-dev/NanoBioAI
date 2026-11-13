Commit de xuat: docs(worklog): ghi nhan onboarding ui polish

# Worklog - Onboarding UI polish

## Thời gian

- Ngày: 2026-11-13
- Bắt đầu: khoảng 12:00
- Kết thúc: 13:25
- Timezone: Asia/Bangkok

## Phạm vi

- Loại task: bugfix/coding/test/docs
- Module chính: M01 `ONBOARDING_PROFILE` — onboarding v1
- Yêu cầu gốc: làm sạch nền, tối giản màn chọn cỡ chữ, hỏi giờ sinh hoạt từng câu theo thứ tự sáng đến tối, rút gọn bước đồng ý.
- Chỉ thị bổ sung: xóa cả vệt nước và giữ background sạch.

## Đã làm

- Bỏ họa tiết lá, vệt nước và ambient orb khỏi nền onboarding; giữ nền semantic và nội dung foreground.
- Rút gọn màn chọn cỡ chữ còn preview trực tiếp, bốn lựa chọn và CTA tiếp tục.
- Bước lịch sinh hoạt hỏi bảy mốc riêng cho ngày thường và lặp lại cho cuối tuần. Bổ sung chọn giờ cho câu hiện tại, điều hướng back giữa các câu và phần giờ tùy chọn sau 14 câu.
- Bước đồng ý hiển thị hai tóm tắt ngắn và chi tiết kỹ thuật có thể mở rộng; consent gate không đổi.
- Tạo widget tests cho nền thuần, màn cỡ chữ, thứ tự lịch hai profile, back theo câu, giờ tùy chọn và consent.
- Cập nhật ba screen spec, checklist M01 và fixbug doc. Giữ nguyên các thay đổi onboarding có sẵn trong worktree.

## File code/docs đã sửa

- `lib/app_versions/v1/features/onboarding/presentation/widgets/nabi_onboarding_experience.dart` — dùng nền semantic thuần.
- `lib/app_versions/v1/features/onboarding/presentation/pages/onboarding_entry_page.dart` — gỡ họa tiết trang trí ở entry hero.
- `lib/app_versions/v1/features/onboarding/presentation/pages/onboarding_text_scale_page.dart` — rút gọn nội dung và CTA.
- `lib/app_versions/v1/features/onboarding/presentation/widgets/daily_routine_step.dart` — thêm flow câu hỏi thời gian tuần tự và phần tùy chọn.
- `lib/app_versions/v1/features/onboarding/presentation/widgets/consent_step.dart` — tóm tắt ngắn, chi tiết mở rộng.
- `lib/app_versions/v1/features/onboarding/presentation/controllers/onboarding_controller.dart` — lưu cursor câu hỏi tạm thời trong state và xử lý next/back.
- `lib/app_versions/v1/features/onboarding/presentation/pages/onboarding_page.dart` — system back quay lại câu lịch trước.
- `lib/app_versions/v1/features/daily_routine/presentation/widgets/daily_routine_preferences_editor.dart` — cho phép ẩn trường giờ lõi khi hiển thị mục tùy chọn.
- `test/app_versions/v1/features/onboarding/onboarding_ui_simplification_test.dart` — thêm 5 widget tests.
- `.codex/design/screens/onb-01-text-scale-setup.md`, `.codex/design/screens/onb-08-daily-routine-step.md`, `.codex/design/screens/onb-09-consent-step.md` — đồng bộ UI contract.
- `docs/checklist/checklist_complete_DD.md`, `docs/checklist/checklist_task_coding.md` — thêm evidence addendum M01.
- `docs/fixbug/onboarding-ui-polish/001-fixbug-onboarding-ui-polish.md` — ghi nhận bug và thay đổi.
- `docs/worklog/2026-11-13/003-worklog-onboarding-ui-polish.md` — ghi phạm vi và kiểm chứng.

## Tài liệu liên quan

- `.codex/workflows/coding.md`
- `.codex/task-skills/coding.md`
- `.codex/domains/onboarding-profile.md`
- `.codex/design/screens/onb-01-text-scale-setup.md`
- `.codex/design/screens/onb-08-daily-routine-step.md`
- `.codex/design/screens/onb-09-consent-step.md`
- `.codex/history/SESSION_QUALITY_REVIEW.md`

## Commands

- `dart format --set-exit-if-changed` over the 10 modified Dart source/test files: PASS — 0 files changed by the final check.
- Targeted `flutter analyze` over 9 modified source files and the new test: PASS — no issues found.
- `flutter test --no-pub --reporter expanded test/app_versions/v1/features/onboarding/onboarding_ui_simplification_test.dart`: PASS — 5 tests.
- `git diff --check`: PASS.
- `python3 .codex/tools/update_worklog_learning.py --write`: PASS — updated 19 generated history/task-skill files.
- `python3 .codex/tools/update_worklog_learning.py --check`: PASS — 19 files current.
- `.codex/tools/validate_codex_integrity.ps1`: SKIPPED — host has no `powershell`/`pwsh`; targeted analyzer, source checks and diff check were run.
- `python3 tools/validate_docs_source_truth.py`: FAIL — repository manifest `docs/audit/source_truth_manifest.json` is missing; unrelated to the onboarding changes.
- PowerShell `update_worklog_learning.ps1`: unavailable in this Linux environment; Python refresh equivalent is available.
- Android screenshots/device smoke: SKIPPED — no Android visual acceptance was run.

## Lỗi/Rủi ro

- Đã fix: background còn họa tiết lá/vệt nước; câu hỏi của bước lịch trước đó chỉ được truyền như semantics nên không hiện trực quan — đã thêm tiêu đề câu hỏi hiển thị.
- Chưa fix: không còn lỗi trong phạm vi targeted analysis/widget tests.
- Cần kiểm tra tiếp: Android visual/device acceptance; Supabase sandbox/RLS và consent/audit production evidence.

## Tỷ lệ hoàn thành

- Hoàn thành: các thay đổi UI và kiểm chứng widget/analyzer trong phạm vi yêu cầu.
- Đang dở: device/sandbox acceptance ngoài phạm vi môi trường hiện tại; không thay đổi M01 progress.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt — câu hỏi hiển thị trực quan, luồng back tuần tự và các dữ liệu/cổng đồng ý hiện có được giữ nguyên.
- Mức độ hoàn thành task: hoàn tất thay đổi code, test và docs; Android/device/Supabase evidence chưa xác minh.
- Bằng chứng kiểm chứng: targeted analyzer sạch; 5 widget tests pass; formatter pass; `git diff --check` và 19-file worklog history refresh pass.
- Điểm tốn token/chưa tối ưu: lượt analyzer đầu dùng nhầm đường dẫn cũ sau khi thư mục presentation được tổ chức lại; lần chạy thứ hai dùng đúng file paths.
- Cách tối ưu cho phiên sau: xác nhận path qua `rg --files` trước khi phân tích, rồi dùng `--no-pub` cho các lệnh Flutter lặp lại.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`
