Commit đề xuất: feat(admin): tạo nhanh tài khoản Gmail và cấp gói

# Worklog - Tạo nhanh nhiều tài khoản và cấp gói

## Thời gian

- Ngày: 2026-09-13
- Múi giờ: Asia/Ho_Chi_Minh (UTC+07:00)

## Phạm vi

- Thêm luồng Super Admin preview rồi tạo tối đa 100 tài khoản Gmail theo danh
  sách `email | họ tên`, chọn Plus/FamilyPlus và thời hạn tháng.
- Tài khoản mới được tạo qua Auth Admin API ở Edge Function; tài khoản hiện có
  không bị đổi password.
- Gói Plus/FamilyPlus còn hạn được bảo toàn; xử lý tuần tự, idempotency cố định,
  dừng khi lỗi và không ghi credential vào audit.
- Bổ sung bắt đổi password ở lần đăng nhập đầu trong Auth V2.
- Không thay đổi schema, RLS, payment hoặc service-role key phía client.

## Đã làm

- Thêm parser strict Gmail, phát hiện dòng sai, email trùng và giới hạn 100 dòng.
- Thêm modal Admin Web preview/confirmation và API adapter không gọi Auth Admin
  API trực tiếp từ trình duyệt.
- Thêm `admin-provision-accounts-bulk` với JWT, Super Admin, fingerprint,
  calendar-month expiry, Auth Admin create, preservation và audit tổng hợp.
- Thêm `must_change_password` vào Auth V2 route state, Auth metadata update và
  chuyển tài khoản mới tới màn hình đổi password hiện có.
- Bổ sung config `verify_jwt = true` và tài liệu deploy riêng Function.

## Bằng chứng

- `deno test --no-lock supabase/functions/admin-provision-accounts-bulk/handler_test.ts`:
  PASS - 7/7.
- `deno check --no-lock` cho handler và index: PASS.
- Admin Web typecheck tương đương bằng TypeScript local package qua Deno: PASS.
- Admin Web test tương đương Vitest local package qua Deno: PASS - 21/21.
- Admin Web production build tương đương Vite local package qua Deno: PASS.
- `deno fmt --check` và `git diff --check`: PASS.
- Lệnh chính thức `npm` và `flutter` không có trong môi trường (`command not
  found`), nên chưa có bằng chứng chạy trực tiếp bằng hai executable này.

## Trạng thái production

- Chưa deploy Edge Function và chưa publish Admin Web trong phiên này.
- Cần phát hành bản app có logic bắt đổi password trước khi bật Function ở
  production.
- Chưa chạy batch production và chưa tạo tài khoản thực.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - luong ghi co preview, fingerprint, idempotency,
  preservation va khong dua credential vao audit/log.
- Muc do hoan thanh task: hoan tat code va validation local; deploy/publish va
  production acceptance con cho rollout co kiem soat.
- Bang chung kiem chung: 7/7 Edge handler tests, 21/21 Admin Web tests,
  TypeScript/Vite/Deno checks va diff hygiene deu PASS.
- Diem ton token/chua toi uu: khong co Node/npm/Flutter native trong runtime;
  khong the thuc hien browser/device acceptance hoac production deploy.
- Cach toi uu cho phien sau: chuan bi toolchain release, deploy rieng Function
  sau khi app da phat hanh, roi acceptance voi mot batch test co idempotency.
- Task-skill can doc lan sau: `.codex/task-skills/coding.md`
