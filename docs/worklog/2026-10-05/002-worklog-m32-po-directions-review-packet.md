Commit de xuat: docs(m32): ghi nhan dinh huong PO va goi review

# Worklog — M32 PO directions and review packet

## Thời gian

- Ngày: 2026-10-05
- Bắt đầu: Trong phiên hiện tại; không ghi timestamp riêng
- Kết thúc: 11:00 Asia/Ho_Chi_Minh
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: docs-dd / implementation readiness
- Module chính: M32 FITNESS_TRAINING
- Yêu cầu gốc: triển khai M32 theo lựa chọn sản phẩm PO; tuân thủ coding gate yêu cầu Tech, Privacy, Clinical và QA review trước runtime.

## Đã làm

- Ghi nhận xác nhận sản phẩm PO ngày 2026-10-05: trusted profile/attestation cho adult proof, Member/FamilyPlus sync theo hướng M05, wellness boundary, Android/iOS và video YouTube tùy chọn với fallback.
- Cập nhật BD/DD, feature summary, catalog status, DD registry/checklist và changelog để không còn mô tả lựa chọn cũ như chưa có định hướng.
- Tạo `docs/DD/fitness_training/Review_Packet.md` với checklist riêng cho Tech Lead, Privacy, Clinical và QA cùng trường ghi sign-off.
- Giữ DD Draft, implementation Absent và các sign-off reviewer Pending; không sửa runtime, schema, route, quota hay catalog runtime.

## File code/docs đã sửa

- `docs/BD/fitness_training/BD_NanoBio_Fitness_Training_M32_v1.0.md` — ghi các hướng sản phẩm PO và duy trì reviewer gate.
- `docs/DD/fitness_training/README.md`, `Overall.md`, `List_Features.md`, `Views.md`, `Function_List.md`, `assets/README.md`, `history/CHANGELOG.md` — đồng bộ contract M32 với lựa chọn mới.
- `docs/DD/fitness_training/Review_Packet.md` — tạo checklist, bằng chứng và bảng ghi reviewer approvals.
- `docs/features/fitness-training/001-feature-fitness-training.md` — sửa mô tả tuổi, sync, media và số atlas.
- `docs/DD/README.md`, `docs/checklist/checklist_create_DD.md` — cập nhật registry M32 và trạng thái reviewer gate.
- `docs/worklog/2026-10-05/002-worklog-m32-po-directions-review-packet.md` — worklog phiên này.

## Tài liệu liên quan

- `.codex/design/15_CODING_PLAN.md` — business module mới cần PO, Tech, QA và Clinical/Privacy approval trước runtime.
- `.codex/workflows/docs-dd.md`, `.codex/skills/create-dd-from-bd/SKILL.md` — workflow DD và yêu cầu traceability/review.

## Commands

- `git diff --check`: PASS.
- `python3` check 14 M32-related docs, trailing whitespace and Review Packet links: PASS.
- `pwsh -NoProfile -File .codex/tools/update_worklog_learning.ps1`: PASS; regenerated 19 deterministic history/task-skill files.
- `python3 .codex/tools/update_worklog_learning.py --check`: PASS; 19 files current.
- `pwsh -NoProfile -File .codex/tools/validate_codex_integrity.ps1`: FAIL on repository-wide baseline findings: missing `docs/audit/source_truth_manifest.json` and stale paths in generated history/Nabi skill. No M32 path was reported.
- Flutter analyze/test/build: skipped vì không có runtime source change và reviewer gate chưa đóng.

## Lỗi/Rủi ro

- Đã fix: cập nhật các tài liệu M32 đang dùng mô tả cũ cho tuổi, số lượng nguyên liệu và platform/video.
- Chưa fix: chưa có sign-off có tên/ngày của Tech Lead, Privacy, Clinical hoặc QA; runtime vẫn bị khóa.
- Cần kiểm tra tiếp: reviewer xác nhận age proof, consent/RLS/retention, tiêu chí an toàn, QA matrix và media/catalog trước khi bắt đầu code.

## Tỷ lệ hoàn thành

- Hoàn thành: ghi nhận hướng PO và tạo gói review M32.
- Đang dở: runtime feature chưa được triển khai vì sign-off theo vai trò còn thiếu.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt — các lựa chọn PO được ghi tách biệt khỏi quyết định reviewer, không giả lập phê duyệt.
- Mức độ hoàn thành task: một phần — đã chuẩn bị hồ sơ review; chưa được phép triển khai runtime theo coding gate.
- Bằng chứng kiểm chứng: docs links/whitespace and history refresh pass; project-wide Codex integrity remains blocked by the missing source-truth manifest and unrelated stale references.
- Điểm tốn token/chưa tối ưu: lần vá lớn đầu tiên bị từ chối do hunk không khớp; tách nhỏ theo file đã xử lý.
- Cách tối ưu cho phiên sau: dùng Review Packet để nhập reviewer responses một lần, đóng các Q đang mở rồi chuyển sang coding workflow.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md` sau khi M32 sign-off được ghi nhận.
