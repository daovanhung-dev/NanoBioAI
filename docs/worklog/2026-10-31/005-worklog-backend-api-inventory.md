Commit de xuat: docs(worklog): ghi nhan danh muc API backend

# Worklog - Danh mục API backend

## Thời gian

- Ngày: 2026-10-31
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: docs-context
- Module chính: backend API
- Yêu cầu gốc: liệt kê API hiện có vào `docs/backend/listapi.md` bằng ba cột STT, endpoint, mục đích.

## Đã làm

- Ghi 95 route được khai báo trong backend, gồm API sức khỏe và các route dưới `/api/v1`.
- Endpoint ghi kèm HTTP method và path đầy đủ; mục đích được mô tả ngắn bằng tiếng Việt.
- Không đưa route tài liệu tự sinh của FastAPI, CORS preflight hoặc API lịch sử không còn đăng ký vào danh sách.

## File code/docs đã sửa

- `docs/backend/listapi.md` - điền danh sách 95 API theo đúng ba cột yêu cầu.
- `docs/worklog/2026-10-31/005-worklog-backend-api-inventory.md` - ghi nhận phiên tài liệu.

## Tài liệu liên quan

- `backend/src/nanobio_backend/main.py`
- `backend/src/nanobio_backend/api/v1/router.py`
- `backend/src/nanobio_backend/modules/*/router.py`
- `backend/.agents/project/05-api-contract.md`

## Commands

- Python AST so sánh route source với bảng: PASS, 95/95 endpoint; đủ ba cột, STT liên tục.
- `git diff --check`: PASS.
- `pwsh -NoProfile -ExecutionPolicy Bypass -File .codex/tools/update_worklog_learning.ps1`: PASS, cập nhật history/task-skill sinh tự động.
- `.codex/tools/validate_codex_integrity.ps1`: FAIL do thiếu `docs/audit/source_truth_manifest.json` và các đường dẫn lịch sử lỗi thời trong `.codex/history/WORKLOG_2026-08-16_meal_nutrition_estimation.md` và `.codex/task-skills/nabi-character/SKILL.md`; các lỗi này không thuộc thay đổi hiện tại.
- Runtime tests: SKIPPED vì chỉ thay đổi tài liệu.

## Lỗi/Rủi ro

- Đã fix: không có.
- Chưa fix: lỗi integrity toàn repo đã nêu trong phần kiểm chứng.
- Cần kiểm tra tiếp: cập nhật danh sách này khi router hoặc prefix API thay đổi.

## Tỷ lệ hoàn thành

- Hoàn thành: lập danh mục các route hiện đang khai báo trong source.
- Đang dở: không.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - đã đối chiếu đầy đủ method và path với route declarations.
- Mức độ hoàn thành task: hoàn thành yêu cầu tài liệu.
- Bằng chứng kiểm chứng: 95/95 route khớp source, cấu trúc bảng đúng ba cột, STT liên tục; `git diff --check` thành công.
- Điểm tốn token/chưa tối ưu: route được chia ở nhiều module nên cần ghép prefix từ router tổng.
- Cách tối ưu cho phiên sau: dùng kiểm tra AST tương tự để rà soát nhanh danh sách sau khi API thay đổi.
- Task-skill cần đọc lần sau: `.codex/task-skills/docs-context.md`
