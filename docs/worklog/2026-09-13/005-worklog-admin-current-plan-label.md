Commit đề xuất: docs(worklog): ghi nhận fix hiển thị gói hiện tại

# Worklog - Fix hiển thị gói hiện tại trong NanoBio Admin Web

## Thời gian

- Ngày: 2026-09-13
- Múi giờ: Asia/Ho_Chi_Minh (UTC+07:00)

## Phạm vi

- Loại task: bugfix / Admin Web UI adapter
- Module chính: danh sách người dùng và nhãn membership
- Yêu cầu gốc: cột `Gói hiện tại` hiển thị `Miễn phí` dù dữ liệu user có
  `plus` hoặc `family_plus`.

## Đã làm

- Xác nhận RPC `admin_search_users` truyền trạng thái gói trong subtitle,
  trong khi UI đọc metadata không được mapper điền.
- Thêm `toUserWorkItems` với parser strict và ưu tiên dữ liệu gói có cấu trúc.
- Thêm nhãn gói chuẩn và thay fallback sai `Miễn phí` bằng `Chưa xác định`.
- Bổ sung regression tests cho bốn mã gói, dữ liệu sai và metadata ưu tiên.
- Không thay đổi Supabase schema/RPC/RLS, membership, payment hoặc credential.

## File code/docs đã sửa

- `admin-web/src/types.ts` - thêm mã gói, parser và user mapper.
- `admin-web/src/lib/admin-api.ts` - dùng user mapper cho section users.
- `admin-web/src/lib/labels.ts` - thêm nhãn gói và fallback an toàn.
- `admin-web/src/pages/AccountsPage.tsx` - hiển thị nhãn gói chuẩn.
- `admin-web/src/types.test.ts` - thêm 5 regression assertions cho plan data.
- `docs/fixbug/admin-current-plan-label/001-fixbug-admin-current-plan-label.md`
  - ghi nhận nguyên nhân, thay đổi và rollout.

## Commands

- `git diff --check`: PASS.
- `npm run typecheck`: PASS.
- `npm test`: PASS - 2 test files, 16 tests.
- `npm run build`: PASS - production bundle; có cảnh báo chunk > 500 kB.
- Publish production: CHƯA THỰC HIỆN - cần chạy workflow GitHub Pages.

## Lỗi/Rủi ro

- Đã fix: cột gói hiện tại không còn mặc định sai thành `Miễn phí` khi response
  có mã `plus` hoặc `family_plus`.
- Chưa fix: bundle live chưa được publish trong phiên này.
- Cần kiểm tra tiếp: browser smoke test trên Admin Web sau khi GitHub Pages
  hoàn tất deploy.

## Tỷ lệ hoàn thành

- Hoàn thành: code, mapper, nhãn và regression tests.
- Đang dở: publish bundle và xác nhận trực tiếp trên môi trường live.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - root cause được đối chiếu giữa RPC contract, adapter
  và JSX; patch chỉ chạm đúng đường hiển thị.
- Mức độ hoàn thành task: hoàn tất phần code và kiểm chứng local; rollout live
  chưa thực hiện.
- Bằng chứng kiểm chứng: typecheck pass, 16/16 test pass, production build
  pass, diff whitespace pass.
- Điểm tốn token/chưa tối ưu: môi trường thiếu npm trong PATH nên phải dùng
  Node local với PATH tạm thời.
- Cách tối ưu cho phiên sau: chuẩn hóa Node/npm runtime trước khi chạy chuỗi
  kiểm tra frontend.
- Task-skill cần đọc lần sau: `.codex/task-skills/bugfix.md`
