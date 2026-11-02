Commit de xuat: docs(worklog): ghi nhan fix trang thai tai khoan moi

# Worklog - Đảm bảo tài khoản mới luôn hoạt động

## Thời gian

- Ngày: 2026-11-02
- Bắt đầu: không ghi nhận
- Kết thúc: 09:00
- Timezone: Asia/Saigon

## Phạm vi

- Loại task: bugfix
- Module chính: Backend auth và admin account provisioning
- Yêu cầu gốc: Tài khoản mới phải ở trạng thái hoạt động ngay sau khi tạo.

## Đã làm

- Gán rõ `is_active=True` và `admin_status="active"` trong ba luồng tạo tài khoản: đăng ký điện thoại, Admin tạo đơn lẻ, Admin tạo hàng loạt.
- Bổ sung kiểm thử trạng thái lưu; kiểm thử signup xác nhận đăng nhập và truy cập hồ sơ được bảo vệ trong khi onboarding vẫn pending.
- Không đổi schema và không sửa trạng thái tài khoản đã tồn tại.
- Không thể triển khai backend: SSH đến máy chủ bằng khóa hiện có trả `Permission denied (publickey,password)`. Không thử mật khẩu yếu đã cung cấp trước đó.
- Không tạo thêm tài khoản trên production vì backend chưa nhận bản sửa; health 200 không xác minh revision.

## File code/docs đã sửa

- `backend/src/nanobio_backend/modules/auth/view.py` - đặt trạng thái hoạt động rõ khi signup.
- `backend/src/nanobio_backend/modules/admin/view.py` - đặt trạng thái hoạt động rõ cho tạo đơn lẻ và hàng loạt.
- `backend/tests/test_api_core.py` - regression coverage cho cả ba đường tạo tài khoản.
- `docs/fixbug/new-account-active/001-fixbug-new-account-active.md` - ghi nhận thay đổi và giới hạn triển khai.
- `.codex/history/` và `.codex/task-skills/` - refresh chỉ mục/skill từ worklog.

## Tài liệu liên quan

- `backend/.agents/project/08-auth-security.md`
- `backend/.agents/project/07-database.md`
- `backend/.agents/project/10-testing.md`
- `backend/.agents/project/11-devops-operations.md`

## Commands

- `uv run pytest -q tests/test_api_core.py::test_phone_signup_login_and_refresh_rotation tests/test_api_core.py::test_admin_create_accounts_generates_unique_one_time_passwords tests/test_api_core.py::test_admin_bulk_provision_creates_active_account`: PASS - 3 passed.
- `uv run ruff check .`: PASS.
- `uv run ruff format --check .`: PASS - 132 files formatted.
- `uv run mypy src/nanobio_backend`: PASS - 94 source files.
- `uv run pytest -q`: PASS - 71 passed, 2 skipped.
- `pwsh -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1`: FAIL - repo thiếu `docs/audit/source_truth_manifest.json` và có các stale path trong history cũ; không liên quan tới file mới của task.
- `ssh -o BatchMode=yes -o StrictHostKeyChecking=yes -o ConnectTimeout=6 nanobio@100.86.238.91 true`: FAIL - máy chủ từ chối xác thực khóa.
- `curl -k ... https://42.118.174.147/health/live`: PASS - HTTP 200; chỉ chứng minh dịch vụ live.
- Kiểm thử đăng ký mới trên điện thoại sau triển khai: SKIPPED - chưa triển khai được backend.
- `git diff --check`: PASS.

## Lỗi/Rủi ro

- Đã sửa: ba đường tạo account phụ thuộc vào giá trị mặc định ngầm thay vì khẳng định trạng thái hoạt động.
- Chưa xác định: revision/backend thực tế đang chạy khi quan sát tài khoản không hoạt động.
- Cần kiểm tra tiếp: triển khai bản backend này qua kênh SSH được cấp quyền, rồi xác nhận một signup mới có thể gọi hồ sơ bảo vệ và xuất hiện `active` trong Admin Web.

## Tỷ lệ hoàn thành

- Hoàn thành: thay đổi source, regression tests và backend quality checks.
- Đang dở: production deployment và xác nhận signup mới trên điện thoại.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - giới hạn source, test và production được tách rõ; không đụng dữ liệu tài khoản cũ.
- Mức độ hoàn thành task: code và kiểm thử hoàn thành; mục tiêu production chưa thể xác nhận vì thiếu quyền SSH.
- Bằng chứng kiểm chứng: 71 backend tests passed, 2 skipped; ruff, format check và mypy passed; health 200 không được xem là bằng chứng deploy.
- Điểm tốn token/chưa tối ưu: cần dò cả ba constructor User vì yêu cầu áp dụng cho public signup lẫn provisioning admin.
- Cách tối ưu cho phiên sau: xác nhận quyền deploy qua SSH trước khi lên lịch phone smoke test.
- Task-skill cần đọc lần sau: `.codex/task-skills/bugfix.md`
