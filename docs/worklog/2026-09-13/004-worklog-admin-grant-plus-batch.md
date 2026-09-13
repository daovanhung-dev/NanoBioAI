Commit đề xuất: ops(admin): chuẩn bị batch cấp Plus có idempotency

# Worklog - Batch tạo/cấp Plus cho danh sách Admin

## Phạm vi

- Xử lý 8 địa chỉ do người vận hành cung cấp, không ghi danh sách vào
  repository hoặc tài liệu.
- Tài khoản đã tồn tại: chỉ cấp Plus 30 ngày, không đổi mật khẩu.
- Tài khoản chưa tồn tại: tạo qua `admin-create-account`, sau đó cấp Plus qua
  `admin-grant-membership`.
- Không ghi trực tiếp vào `auth.users` hoặc `membership_subscriptions`.

## Đã làm

- Thêm `tools/admin-grant-plus/grant.ts`.
- Tra cứu bằng `admin_search_users`, tạo mới chỉ khi thiếu, xử lý tuần tự và
  dừng tại lỗi đầu tiên.
- JWT Admin và mật khẩu chỉ đọc từ stdin; không lưu trong source hoặc in ra.
- Mỗi email có idempotency key riêng; chạy lại dùng cùng key để tránh cấp trùng.

## Kiểm chứng

- `deno check --no-lock tools/admin-grant-plus/grant.ts`: PASS.
- Chưa thực thi production vì agent không có session JWT Super Admin và không
  nhận credential qua chat.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - thao tác đi qua Edge Function, có idempotency và
  không lộ credential.
- Mức độ hoàn thành task: công cụ đã sẵn sàng; batch production còn chờ người
  vận hành chạy với session JWT local.
- Bằng chứng kiểm chứng: Deno typecheck PASS.
- Điểm tốn token/chưa tối ưu: không có phiên browser Admin khả dụng để chạy.
- Cách tối ưu cho phiên sau: kiểm tra kết quả từng dòng và chỉ retry cùng key.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`

