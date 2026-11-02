Commit de xuat: docs(worklog): ghi nhan dieu tra trang thai signup production

# Worklog - Điều tra trạng thái signup và tài khoản không hoạt động

## Thời gian

- Ngày: 2026-11-02
- Bắt đầu: 10:15
- Kết thúc: 10:23
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: bugfix / điều tra production
- Module chính: Backend auth, Admin account status
- Yêu cầu gốc: Tài khoản mới phải hoạt động; xác định nguyên nhân tài khoản hiện có đang không hoạt động.

## Đã làm

- Xác nhận signup trong source gán rõ `is_active=True` và `admin_status="active"`; Admin search trả trực tiếp hai trường trạng thái.
- Thêm regression test nối signup với Admin search, kiểm tra HTTP 201, bản ghi lưu hai trạng thái active, và phản hồi tìm kiếm có `status=active`, `is_active=true`.
- Cài đặt trên điện thoại đang ở phiên bản `1.0.2+7`. Cấu hình API trong source Flutter là `https://42.118.174.147`; bundle Admin Web đang mở cũng chứa cùng API host. Chưa trích xuất/đối chiếu được base URL bên trong APK cài trên máy, và chưa có trace của request signup mới.
- Admin Web đang hiển thị 5 tài khoản không hoạt động. Mở hồ sơ từng tài khoản bằng lý do truy cập có audit; trường `admin_roles` rỗng ở cả 5. Không lưu tên, số điện thoại hoặc ID hồ sơ vào worklog.
- Sau khi xem hồ sơ, Admin Web chuyển sang `API chưa sẵn sàng` và khóa thao tác ghi; probe HTTPS `/health/ready` timeout sau 12 giây.
- Không thay đổi trạng thái tài khoản trong phiên này. Cần API sẵn sàng và xác nhận ngay trước thao tác bật tài khoản vì đây là thay đổi quyền truy cập.
- Thử SSH key-only với xác minh host nghiêm ngặt; máy chủ từ chối xác thực. Không dùng mật khẩu yếu đã được cung cấp trước đó.
- Không tạo tài khoản test production vì chưa có tên và số điện thoại test do người dùng cung cấp; không triển khai hoặc restart backend.
- Giữ nguyên các thay đổi lịch AI đang có trong worktree.

## File code/docs đã sửa

- `backend/tests/test_api_core.py` - thêm regression test cho kết quả Admin search sau phone signup.
- `docs/fixbug/new-account-active/001-fixbug-new-account-active.md` - bổ sung bằng chứng điều tra production và giới hạn triển khai.
- `docs/worklog/2026-11-02/002-worklog-account-active-production-investigation.md` - ghi nhận kết quả và giới hạn phiên.

## Tài liệu liên quan

- `backend/src/nanobio_backend/modules/auth/view.py`
- `backend/src/nanobio_backend/modules/admin/view.py`
- `admin-web/src/App.tsx`
- `.github/workflows/deploy-admin-web.yml`

## Commands

- `uv run pytest -q tests/test_api_core.py::test_phone_signup_login_and_refresh_rotation tests/test_api_core.py::test_admin_search_reports_phone_signup_as_active tests/test_api_core.py::test_admin_create_accounts_generates_unique_one_time_passwords tests/test_api_core.py::test_admin_bulk_provision_creates_active_account`: PASS - 4 passed.
- `uv run ruff check tests/test_api_core.py`: PASS.
- `git diff --check`: PASS.
- `adb devices -l` và `adb shell dumpsys package com.nanobioai.app`: PASS - điện thoại có kết nối; app `1.0.2+7`.
- Đọc cấu hình API từ `assets/config/auth.env` và bundle trang Admin Web đã triển khai: PASS - cùng host `https://42.118.174.147`.
- `ssh -o BatchMode=yes -o StrictHostKeyChecking=yes -o ConnectTimeout=6 nanobio@100.86.238.91 true`: FAIL - `Permission denied (publickey,password)`.
- `curl -fsS --max-time 12 https://42.118.174.147/health/ready`: FAIL - connection timeout sau 12 giây.
- Đăng ký test trên production, cập nhật trạng thái 5 tài khoản, triển khai/restart backend: SKIPPED - API chưa sẵn sàng, thiếu tên/số điện thoại test và SSH key bị từ chối.

## Lỗi/Rủi ro

- Đã bổ sung: test sẽ bắt lệch giữa trạng thái bản ghi signup và trạng thái Admin search trong source hiện tại.
- Chưa xác định: revision backend và cờ trạng thái thật của luồng signup trên production. Cấu hình host khớp không chứng minh hai client đang dùng cùng revision backend.
- Chưa hoàn tất: API readiness, triển khai backend, signup production có trace/status, và bật các tài khoản hiện có.

## Tỷ lệ hoàn thành

- Hoàn thành: regression coverage và điều tra read-only các tài khoản đang hiển thị.
- Đang dở: production deploy, xác minh signup mới, và thay đổi trạng thái các tài khoản.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - phân biệt source, bundle client, trạng thái Admin đang thấy, và revision server chưa xác minh.
- Mức độ hoàn thành task: một phần; các thao tác production còn chờ xác nhận/quyền truy cập.
- Bằng chứng kiểm chứng: 4 test pass, Ruff pass, API host khớp giữa cấu hình app source và bundle Admin; SSH key bị từ chối.
- Điểm tốn token/chưa tối ưu: thử đọc asset trực tiếp từ APK tạo bản sao cục bộ lớn nhưng không trích được config; đã xóa file tạm.
- Cách tối ưu cho phiên sau: kiểm tra API readiness và quyền SSH trước khi mở nhiều hồ sơ; dùng bundle/config đã triển khai để đối chiếu origin.
- Task-skill cần đọc lần sau: `.codex/task-skills/bugfix.md`
