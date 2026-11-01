# Worklog - Đối chiếu API Admin Web và backend

## Thời gian

- Ngày: 2026-10-31
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: find-issues / API contract audit.
- Module chính: `admin-web` và FastAPI backend.
- Yêu cầu gốc: xác định API Admin Web gọi và API server cung cấp có khớp nhau không.
- Giới hạn: rà soát source hiện tại; không sửa runtime code, không gọi API production trong phiên này.

## Đã làm

- Lần theo API client và adapter RPC tương thích trong `admin-web/src/lib/admin-api.ts` xuống endpoint REST.
- Đối chiếu các nhóm auth, admin session, tài khoản/thành viên, người dùng, thanh toán, audit, Early Access, dashboard, business sections và tệp với router FastAPI tương ứng.
- Xác nhận các path/method chính có route backend tương ứng; adapter chuyển các thao tác business sang `GET/POST /admin/business/{section}`.
- Ghi nhận ba nhóm lệch contract đã xác nhận: metric key Dashboard, pagination/độ dài reason Early Access, và vai trò UI/backend.
- Không tìm thấy bằng chứng trong source cho thấy API origin/CORS là nguyên nhân của các lệch contract này; phiên audit không kiểm tra trạng thái mạng/deployment hiện tại.

## Kết luận

- Kết luận: khớp một phần. Định tuyến và HTTP method chính nhìn chung có route tương ứng; chưa thể xem contract tổng thể là khớp do response key, query validation và authorization khác nhau.
- Chi tiết issue:
  - [Dashboard metric contract](../../issues/admin-dashboard-metric-contract/001-issue-admin-dashboard-metric-contract.md)
  - [Early Access API contract](../../issues/admin-early-access-api-contract/001-issue-admin-early-access-api-contract.md)
  - [Role parity](../../issues/admin-api-role-parity/001-issue-admin-api-role-parity.md)

## File/docs đã tạo

- `docs/issues/admin-api-role-parity/001-issue-admin-api-role-parity.md`
- `docs/issues/admin-dashboard-metric-contract/001-issue-admin-dashboard-metric-contract.md`
- `docs/issues/admin-early-access-api-contract/001-issue-admin-early-access-api-contract.md`
- `docs/worklog/2026-10-31/004-worklog-admin-web-api-contract-audit.md`

## Kiểm chứng

- Rà soát source frontend/backend và đối chiếu route/method/schema/permission.
- `git diff --check`: PASS.
- Kiểm tra các liên kết tương đối trong ba issue và worklog: PASS.
- `pwsh -NoProfile -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1`: FAIL ở kiểm tra toàn repo do thiếu `docs/audit/source_truth_manifest.json` và các path lịch sử cũ trong `.codex/history/WORKLOG_2026-08-16_meal_nutrition_estimation.md` cùng `.codex/task-skills/nabi-character/SKILL.md`; không có báo lỗi đường dẫn mới trong worklog này.
- Runtime/API integration tests: không chạy trong phiên audit.
- Production acceptance/deployed artifact: chưa xác minh trong phiên này.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - phát hiện có dẫn chứng file/dòng và tách rõ routing, payload/response, authorization.
- Mức độ hoàn thành task: hoàn thành đối chiếu source; chưa xác nhận hành vi của bản deploy đang chạy.
- Bằng chứng kiểm chứng: route decorators, API adapter, request schemas và ma trận permission trong source; diff và liên kết docs sạch; validator toàn repo bị chặn bởi lỗi inventory/path cũ; chưa chạy browser hoặc server.
- Điểm tốn token/chưa tối ưu: backend router/view cần đọc qua nhiều module vì Admin API được chia theo domain.
- Cách tối ưu cho phiên sau: dựng bảng contract tự động từ router declarations và API client cases, sau đó thêm integration checks cho các mismatch.
- Task-skill cần đọc lần sau: `.codex/task-skills/find-issues.md`
