Commit de xuat: docs(worklog): ghi nhan va fix trang thai active tren production

# Worklog - Sửa trạng thái active của tài khoản trên production

## Thời gian

- Ngày: 2026-11-02
- Bắt đầu: 12:20
- Kết thúc: 12:33
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: bugfix / production
- Module chính: Backend auth và Admin user search
- Mục tiêu: tài khoản tạo mới được gán active; Admin hiển thị đúng trạng thái thực.

## Nguyên nhân

- Production DB có 6 tài khoản hiện hữu, tất cả `is_active=true` và `admin_status=active`.
- Backend production ở revision `38ee4d0` không trả `is_active` trong `/api/v1/admin/users/search`; Admin Web xem trường thiếu như `false` và hiện nhãn “Không hoạt động”.
- Các luồng tạo tài khoản dựa vào mặc định model; cần gán tường minh active tại phone signup, Admin tạo đơn lẻ và bulk.

## Đã làm

- Lưu bản sao lưu của hai file backend đích vào `/var/backups/nanobio/` trước khi sửa.
- Vá đúng bốn vị trí trong checkout production: thêm `is_active=True` và `admin_status="active"` tại ba luồng tạo tài khoản; thêm `is_active` vào response Admin search.
- Bảo toàn các chỉnh sửa chưa commit khác trong checkout server; không pull, checkout, commit, push hoặc migrate. Không sửa DB trực tiếp; tài khoản mới được tạo qua API từ app.
- Restart `nanobio-backend`; service active sau restart.
- Readiness loopback trả HTTP 200. HTTPS readiness công khai trả 200 với TLS verification hợp lệ.
- Reload Admin Web trong Chrome sau đăng ký: báo API/database sẵn sàng, danh sách có 7 tài khoản; `Test1` đứng đầu và hiển thị “Đang hoạt động”. Sáu tài khoản cũ vẫn active.
- Người dùng tự hoàn tất form đăng ký trên điện thoại. Flutter Inspector ghi nhận app đã chuyển từ onboarding entry sang `OnboardingTextScalePage` sau đăng ký, tức đã qua đăng nhập/đăng ký và vào onboarding.
- Không mở hồ sơ sức khỏe hoặc ghi lại thông tin liên hệ.

## File tài liệu cập nhật

- `docs/fixbug/new-account-active/001-fixbug-new-account-active.md` - ghi nguyên nhân thực tế và bằng chứng sau sửa production.
- `docs/worklog/2026-11-02/004-worklog-active-account-production-fix.md` - worklog của lần xử lý này.

## Kiểm tra

- Backend tests tại checkout local: PASS - 4 tests.
- Ruff check và format check tại checkout local: PASS.
- `python3` AST parse hai file đã vá trên server: PASS.
- `git diff --check` và `git diff --cached --check` tại server: PASS.
- Public readiness `https://nanobio.s2w.click/health/ready`: PASS - HTTP 200, TLS verify result 0.
- Admin Web qua Chrome sau reload: PASS - 7 kết quả; tài khoản mới `Test1` hiển thị active, 6 tài khoản cũ vẫn active.
- Đăng ký trên điện thoại: PASS - người dùng xác nhận submit thành công; Admin xác nhận tài khoản active và app đã chuyển tới `OnboardingTextScalePage`.
- `uv run pytest` trên server: BLOCKED - không ghi được editable `.pth` trong `.venv`; `.venv/bin/pytest` không tồn tại.
- Tạo tài khoản mới qua điện thoại: PASS - signup hoàn tất và trạng thái active được xác minh trong Admin.

## Dữ liệu và giới hạn

- Không sửa DB trực tiếp, schema hoặc tài khoản cũ; signup qua app tạo đúng một tài khoản mới.
- Không ghi số điện thoại, mật khẩu, token hoặc secrets vào worklog.
- Source server đã được vá và restart; tài khoản mới đã được tạo qua app và trạng thái active được xác minh trong Admin.

## Tự đánh giá

- Nguyên nhân Admin báo sai đã được sửa và xác minh bằng giao diện production.
- Các luồng tạo mới hiện đặt tường minh trạng thái active trong source đang chạy.
- Kết quả production đã xác nhận bằng Admin UI và trạng thái onboarding trên app; không dùng riêng source tests làm bằng chứng runtime.
