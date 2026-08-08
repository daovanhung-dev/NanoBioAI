Commit de xuat: docs(worklog): ghi nhận phiên dashboard blue wellness

# Worklog - Dashboard Blue Wellness

## Thời gian

- Ngày: 2026-08-04
- Bắt đầu: 20:46
- Kết thúc: 21:14
- Timezone: Asia/Bangkok (UTC+07:00)

## Phạm vi

- Loại task: coding
- Module chính: M03 `DASHBOARD_SCHEDULE`
- Domain phụ: UI/theme/Nabi copy
- Yêu cầu gốc: đổi tông màu sang xanh dương và tối ưu Dashboard theo hướng tối giản, dễ dùng, dễ nhìn, ưu tiên UX.

## Đã làm

- Nạp `nano_context.md`, root/canonical AGENTS, PROJECT_MAP, workflow coding, task-skill coding, dashboard/ui domain, DD M03 và coding checklist.
- Chuyển canonical palette và gradient/shadow foundation sang Blue Wellness.
- Giữ xanh lá cho semantic success, không biến warning/error thành màu brand.
- Tách Dashboard orchestration khỏi các widget UI; giảm page từ 2.241 xuống 284 dòng.
- Tổ chức lại information architecture theo snapshot, quick actions, 2×2 metrics, timeline preview, progress, primary insight và health details mở rộng.
- Loại bỏ pulse animation vô hạn ở Dashboard hero.
- Giữ nguyên provider/controller/repository/data-write/deep-link callbacks.
- Thêm test source cho narrow screen, text scale 130%, concise copy và orchestration contract.
- Cập nhật M03 implementation evidence/checklist.

## File code/docs đã sửa

- `lib/core/theme/` — sửa — semantic Blue Wellness palette/gradient/shadow và label.
- `lib/app_versions/v1/features/dashboard/presentation/pages/dashboard_page.dart` — sửa — orchestration-only.
- `lib/app_versions/v1/features/dashboard/presentation/widgets/dashboard_content.dart` — tạo — Dashboard composition và bottom-sheet orchestration.
- `lib/app_versions/v1/features/dashboard/presentation/widgets/overview/dashboard_overview_widgets.dart` — tạo — header/snapshot/quick actions/metrics.
- `lib/app_versions/v1/features/dashboard/presentation/widgets/sections/dashboard_sections.dart` — tạo — timeline/progress/insight/health details.
- `lib/app_versions/v1/features/dashboard/presentation/widgets/states/dashboard_state_widgets.dart` — tạo — loading/error/sync states.
- `test/app_versions/v1/features/dashboard/dashboard_green_ui_test.dart` — widget/static contract source; đổi tên ở đợt Green Wellness ngày 2026-08-08.
- `test/core/theme/blue_wellness_contract_test.dart` — đổi từ Green Wellness contract và cập nhật palette.
- `tools/validate_nabi_green_wellness.py` — sửa nội dung label sang Blue Wellness, giữ filename tương thích lịch sử.
- `docs/features/dashboard-blue-wellness/001-feature-dashboard-blue-wellness.md` — tạo.
- `docs/checklist/checklist_complete_DD.md` — cập nhật M03 evidence.
- `docs/checklist/checklist_task_coding.md` — cập nhật next validation tasks.

## Commands

- `python3 tools/validate_nabi_green_wellness.py`: PASS — 740 Dart files, 0 blocking findings; 57 asset path warnings do snapshot đầu vào thiếu assets.
- Package import existence check cho file mới: PASS.
- Semantic token member check: PASS.
- Lexical delimiter balance check: PASS.
- Presentation boundary scan: PASS.
- Old brand-hex scan: PASS.
- `dart format`: SKIPPED — không có Dart executable.
- `flutter analyze`: SKIPPED — không có Flutter executable.
- `flutter test`: SKIPPED — không có Flutter executable.
- `flutter build apk --debug`: SKIPPED — không có Flutter executable.
- `.codex/tools/update_worklog_learning.ps1`: SKIPPED — không có PowerShell executable.

## Lỗi/Rủi ro

- Đã fix: Dashboard quá dài, hero copy/pulse gây phân tâm, metric card một cột, card tiến độ phân mảnh, brand green không phù hợp yêu cầu mới.
- Chưa fix: visual/device validation chưa thể chạy trong container.
- Cần kiểm tra tiếp: Flutter analyze/test/build và smoke Android tại các kích thước/text scale mục tiêu.

## Tỷ lệ hoàn thành

- Hoàn thành: source/theme/UI restructure, static checks, docs và đóng gói bàn giao.
- Đang dở: Flutter SDK validation và device visual smoke.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt — scope presentation-only, code được modular hóa và invariants được giữ.
- Mức độ hoàn thành task: cao; chưa thể claim compile/device PASS do thiếu toolchain.
- Bằng chứng kiểm chứng: static validator + import/token/balance/boundary scans và test source.
- Điểm tốn token/chưa tối ưu: đọc dashboard file 2.241 dòng ban đầu tạo output lớn; lần sau dùng line-range/index sớm hơn.
- Cách tối ưu cho phiên sau: chạy targeted analyzer/test ngay trên máy có Flutter, chỉ mở source theo diagnostic.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`.
