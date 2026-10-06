Commit de xuat: docs(feature): ghi nhan tich hop website nanobio

# NanoBio public website in Admin Web

## Mục tiêu

Đưa nội dung trong `admin-web/docs/nanobio_website/` vào ứng dụng React/Vite
hiện có, giữ website và trang quyền riêng tư công khai, đồng thời nhận đăng ký
Early Access qua Supabase Edge Function. Không tạo luồng deploy GitHub Pages thứ
hai và không tạo bảng lead song song.

## Luồng hiện tại

- `/#/nanobio` hiển thị landing page; `/#/nanobio/privacy` hiển thị chính sách.
- Cả hai route nằm ngoài `AuthProvider`; route `/admin/*` vẫn dùng
  `RequireAdmin`. Sidebar Admin có liên kết Website NanoBio.
- Nội dung landing được cô lập bằng Shadow DOM, dùng CSS riêng và ảnh local từ
  bundle. Trang có các breakpoint mobile/tablet, focus indicator, modal bàn
  phím, và nhánh `prefers-reduced-motion`.
- Form chỉ thu thập số điện thoại và consent. Client gọi trực tiếp function với
  `VITE_SUPABASE_URL` và `VITE_SUPABASE_ANON_KEY`; không gửi dữ liệu tới client
  Admin hoặc dùng service-role key.
- Server cố định nguồn `nanobio_web`, ưu đãi Plus 30 ngày và trạng thái lead
  ban đầu. UTM, referrer đã bỏ query/hash, landing path và user-agent được giới
  hạn độ dài. Không thu thập tên hoặc dữ liệu sức khỏe.
- Trùng số trả phản hồi thành công chung qua insert-ignore; không ghi đè trạng
  thái liên hệ hoặc cấp Plus. Khi không có APK trong bucket private, UI báo đã
  ghi nhận và không hiển thị link giả.

## Contract dữ liệu và bảo mật

Migration `supabase/migrations/20261007000000_nanobio_early_access.sql` tạo
`early_access_leads` cùng các metadata lead, giữ `vip_grant_status` tách khỏi
`status`, khóa direct client grants và tạo schema riêng cho rate state HMAC.
RPC atomic giới hạn 10 request mỗi IP mỗi giờ; cron dọn state hết hạn dưới 24
giờ. Bucket `early-access-apk` là private. Edge Function dùng allowlist origin
chính xác và khai báo `verify_jwt = false` vì đây là form public; function tự
kiểm tra input/consent/rate limit và chỉ giữ service-role key phía server.

## Trạng thái xác minh

| Hạng mục | Trạng thái |
|---|---|
| Admin Web tests, typecheck, build | PASS local |
| Handler/rate limiter Deno tests và `deno check` | PASS local |
| Migration, function, secrets trên Supabase sandbox/remote | Chưa áp dụng/chưa deploy |
| APK private bucket và link tải có hạn | Chưa xác minh; hiện không tạo URL giả |
| Browser render ở mobile/tablet/desktop và screen reader | Chưa xác minh trong browser; browser surface không khả dụng trong phiên |
| GitHub Pages publication | Chưa thực hiện trong lượt này |

Không coi mã nguồn migration, smoke fixture rollback-only hoặc unit tests thay
thế bằng bằng chứng migration/function thật trên sandbox. Trước khi rollout,
xác nhận lại project ref, migration history và phương án khôi phục; áp dụng
migration additive, deploy function/secrets, rồi kiểm tra luồng thật và trạng
thái bucket trên môi trường an toàn.

## Kiểm tra chính

- `npm test`: PASS, 46 tests.
- `npm run typecheck`: PASS.
- `npm run build`: PASS; Vite báo chunk JavaScript lớn hơn 500 kB do website
  content/assets được đóng cùng bundle.
- `deno fmt --check supabase/functions/register-early-access`: PASS.
- `deno test supabase/functions/register-early-access`: PASS, 8 tests.
- `deno check supabase/functions/register-early-access/index.ts`: PASS.
