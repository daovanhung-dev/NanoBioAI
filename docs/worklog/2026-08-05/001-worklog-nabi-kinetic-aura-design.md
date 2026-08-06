Commit de xuat: docs(design): lap Nabi Kinetic Aura design va coding plan

# Worklog - Nabi Kinetic Aura design toàn bộ UI

## Thời gian

- Ngày: 2026-08-05
- Bắt đầu: 20:14
- Kết thúc: 20:32
- Timezone: Asia/Saigon (UTC+07:00)

## Phạm vi

- Loại task: docs-context / UI design audit / coding plan
- Module chính: UI, Theme, Motion, Sound, Haptic, Nabi, toàn bộ presentation layer
- Yêu cầu gốc: triển khai kế hoạch thiết kế hiệu ứng chuyển đổi, micro-interaction, âm thanh nhỏ; lập design theo nhóm UI, từng view, từng file; đặt tài liệu trong `.codex/design`; sau đó lập kế hoạch coding.

## Đã làm

- Đọc `nano_context.md`, root `AGENTS.md`, `.codex/AGENTS.md`, project map, docs-context workflow/task-skill, UI domain, docs workflow và session review.
- Static audit 183 file UI/theme/router/app-shell, gồm 46 page/screen và 59 widget file.
- Xác định 40 file đang có motion, 21 file dùng duration raw, 33 file dùng màu trực tiếp, 11 file gọi haptic trực tiếp và 0 file có audio playback.
- Xác định theme drift giữa `app_*`, `foundation/*`, `tokens/*`, `primitives/*` và nhiều motion API song song.
- Tạo Nabi Kinetic Aura design system, color/depth, motion, micro-interaction, sound/haptic, navigation, Nabi orchestration, accessibility và performance budget.
- Lập design theo 12 nhóm UI.
- Lập file-by-file design matrix cho toàn bộ 183 file.
- Lập storyboard cho 46 view/page và interaction event matrix.
- Lập coding plan 11 wave và exact file manifest theo wave.
- Ghi blocker: `pubspec.yaml` khai báo SFX nhưng snapshot không chứa physical audio assets; chưa có audio playback service/package.
- Cập nhật `.codex` router/map để các task UI sau đọc đúng design source mà không nạp toàn bộ group docs.

## File code/docs đã sửa

### Tạo mới

- `.codex/design/` - 37 file design/audit/inventory/coding-plan.
- `.codex/design/groups/` - 12 design document theo UI group.
- `.codex/design/inventory/ui_source_audit.csv` - inventory máy đọc.
- `.codex/design/inventory/ui_source_audit.json` - static evidence chi tiết.
- `docs/worklog/2026-08-05/001-worklog-nabi-kinetic-aura-design.md` - worklog phiên.

### Cập nhật

- `.codex/AGENTS.md` - bổ sung design read pack cho UI refactor.
- `.codex/README.md` - đăng ký `.codex/design/`.
- `.codex/PROJECT_MAP.md` - thêm UI design source và routing.
- `.codex/MAP_TREE.md` - cập nhật context layout.
- `.codex/domains/ui-nami.md` - thêm required design read pack có chọn lọc.
- `.codex/workflows/coding.md` - thêm context bắt buộc khi coding UI/motion/sound/Nabi.

## Tài liệu liên quan

- `.codex/design/README.md`
- `.codex/design/00_NABI_KINETIC_AURA_MASTER_DESIGN.md`
- `.codex/design/12_UI_FILE_DESIGN_MATRIX.md`
- `.codex/design/15_CODING_PLAN.md`
- `.codex/design/16_ACCEPTANCE_CHECKLIST.md`
- `.codex/design/20_CODING_WAVE_FILE_MANIFEST.md`

## Commands

- `python /tmp/audit_ui.py`: PASS - audit 183 file và tạo CSV/JSON.
- `python /tmp/generate_design_docs.py`: PASS - tạo design artifacts.
- Custom design validation: PASS - 37 file, 183 matrix rows, 183 wave rows, 12 group docs, không broken link/trailing whitespace/probable secret.
- Targeted `rg -n ".codex/design" ...`: PASS - design source đã được đăng ký trong context router.
- Custom whitespace check: PASS - 0 issue.
- `powershell -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1`: SKIPPED - môi trường không có PowerShell.
- `powershell -ExecutionPolicy Bypass -File .codex/tools/update_worklog_learning.ps1`: SKIPPED - môi trường không có PowerShell; generated history/task-skills chưa được refresh.
- `git diff --check`: SKIPPED - snapshot giải nén không chứa `.git`.
- Flutter analyze/test/build: SKIPPED - phiên chỉ thay đổi docs/context, không sửa Dart runtime.

## Lỗi/Rủi ro

- Đã fix:
  - Thiếu design source canonical cho refactor UI toàn app.
  - Thiếu file-level migration matrix và exact coding wave scope.
  - Thiếu policy tập trung cho motion/sound/haptic/Nabi.
- Chưa fix:
  - Physical audio assets không có trong snapshot.
  - Chưa chọn audio dependency và chưa có playback adapter.
  - Chưa dựng prototype hình ảnh/recording và chưa chạy device performance QA.
  - History refresh chưa chạy do thiếu PowerShell.
- Cần kiểm tra tiếp:
  - Chạy integrity/history scripts trên máy Windows/PowerShell.
  - Duyệt visual prototype trước Wave 1.
  - Xác minh audio asset license, loudness và platform behavior.

## Tỷ lệ hoàn thành

- Hoàn thành: 100% static audit, design documents và coding plan theo phạm vi được yêu cầu.
- Đang dở: 0% coding runtime; prototype và device certification chưa bắt đầu.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - design được liên kết với 183 source file, có invariant, blocker, acceptance và wave rõ ràng.
- Mức độ hoàn thành task: hoàn thành phần design và plan coding; không tự ý coding khi chưa có xác nhận mới.
- Bằng chứng kiểm chứng: custom validator PASS, 183/183 matrix và wave coverage, 12/12 group docs, link/whitespace/secret checks PASS.
- Điểm tốn token/chưa tối ưu: file matrix lớn; đã giảm chi phí phiên sau bằng CSV/JSON inventory và yêu cầu chỉ đọc một group file theo matrix.
- Cách tối ưu cho phiên sau: bắt đầu từ Wave 1, đọc master + exact group + exact matrix rows; không đọc toàn bộ `.codex/design/groups/`.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`
