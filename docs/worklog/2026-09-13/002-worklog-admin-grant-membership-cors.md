Commit đề xuất: fix(admin-web): xử lý CORS preflight cấp gói

# Worklog - Fix cấp gói Plus từ NanoBio Admin Web

## Thời gian

- Ngày: 2026-09-13
- Múi giờ: Asia/Ho_Chi_Minh (UTC+07:00)

## Phạm vi

- Loại task: bugfix / Supabase Edge Function / Admin Web
- Module chính: `admin-grant-membership`
- Yêu cầu gốc: thao tác cấp gói Plus từ trang người dùng bị thất bại.

## Đã làm

- Đọc Network evidence: request `OPTIONS` tới Function trả `405 Method Not
  Allowed`, nên browser không gửi được `POST` cấp gói.
- Thêm xử lý CORS preflight vào handler.
- Thêm CORS headers cho response thành công và lỗi.
- Thêm regression test cho preflight.
- Không đổi schema/RLS, role guard, payload, idempotency hoặc logic cấp gói.

## File code/docs đã sửa

- `supabase/functions/admin-grant-membership/handler.ts` - thêm CORS
  preflight và headers cho response.
- `supabase/functions/admin-grant-membership/handler_test.ts` - thêm test
  preflight.
- `docs/fixbug/admin-grant-membership-cors/001-fixbug-admin-grant-membership-cors.md`
  - ghi nhận nguyên nhân, thay đổi và rollout.

## Commands

- `deno test --allow-net supabase/functions/admin-grant-membership/handler_test.ts`:
  PASS - 8 tests.
- `git diff --check`: PASS.
- `npm run typecheck`: UNVERIFIED - không có `npm`/`node` trong môi trường.
- `npm test -- --run`: UNVERIFIED - không có `npm`/`node` trong môi trường.
- `npm run build`: UNVERIFIED - không có `npm`/`node` trong môi trường.
- Supabase production deploy: NOT RUN - chưa thực hiện deploy hoặc thao tác
  cấp gói thật.

## Lỗi/Rủi ro

- Đã fix: CORS preflight `OPTIONS` trả `405`.
- Chưa fix: Function production cần được deploy lại để nhận code mới.
- Cần kiểm tra tiếp: sau deploy, xác nhận `OPTIONS` là `200`; nếu `POST` còn
  lỗi thì lấy response backend để kiểm tra role/secret/runtime.

## Tỷ lệ hoàn thành

- Hoàn thành: bản vá handler và regression test.
- Đang dở: production deploy và browser smoke test.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - nguyên nhân được xác nhận bằng Network status cụ thể.
- Mức độ hoàn thành task: code fix hoàn tất; rollout production chưa thực hiện.
- Bằng chứng kiểm chứng: Deno handler test 8/8 và diff whitespace pass.
- Điểm tốn token/chưa tối ưu: không chạy được frontend checks do thiếu Node runtime.
- Cách tối ưu cho phiên sau: deploy Function trước, sau đó kiểm tra preflight và
  POST bằng browser Network với cùng idempotency key nếu request trước chưa có
  response chắc chắn.
- Task-skill cần đọc lần sau: `.codex/task-skills/bugfix.md`

