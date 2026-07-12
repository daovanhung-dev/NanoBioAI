Commit de xuat: feat(auth-sync): hoan thien Auth V2 Admin va dong bo M05 an toan

# Hoàn thiện Auth V2, Admin access và đồng bộ M05

## Mục tiêu

- Hoàn thiện vòng đời Auth V2 gồm đăng ký, xác thực email, đăng nhập, khôi phục session, quên/đặt lại mật khẩu và đăng xuất.
- Bảo vệ dữ liệu local theo nguyên tắc push outbox trước pull cloud.
- Yêu cầu người dùng xác nhận trước khi chuyển dữ liệu Guest sang tài khoản hoặc thay dữ liệu Guest bằng dữ liệu cloud đã có.
- Tách session Admin khỏi session người dùng V2 và dùng một `AdminAccessState` duy nhất cho router/login/gate.
- Giữ contract full snapshot M05 hiện tại; không triển khai merge đồng thời đa thiết bị.

## Auth V2 và deep link

- `AuthDeepLinkCoordinator` là đầu mối duy nhất cho cold/warm link `nanobio://auth/callback`.
- Supabase được khởi tạo với `detectSessionInUri: false`; app tự gọi `recoverSessionFromUri` đúng một lần.
- Android tắt Flutter deep-link handler mặc định để callback chỉ đi qua coordinator của ứng dụng.
- Callback được phân loại thành `emailConfirmation`, `passwordRecovery` hoặc `unknown`.
- Recovery đi tới màn đặt mật khẩu; xác thực email quay qua Auth Gate.
- Callback lỗi giữ người dùng ở màn hỗ trợ để retry, không điều hướng trong `finally`.
- Router phản ứng theo auth state, bảo vệ route V2 nghiệp vụ và vẫn giữ route Guest V1.
- Thông báo lỗi cho người dùng dùng copy tiếng Việt an toàn, không lộ Supabase/RPC/database/URL/UUID/exception/stack trace.
- Lỗi trigger signup chung khi có referral được quy về trạng thái mã không dùng được để người dùng sửa hoặc xóa mã.

## Đăng ký và referral

- `RegisterCommand` có `referralCode`.
- Repository tạo device fingerprint dạng opaque install ID và gửi trong metadata `signUp`.
- Migration `15-auth-sync-completion.sql` kiểm tra referral, Sale active, email/phone/device collision và direct-only policy ngay trong transaction tạo `auth.users`.
- Referral không hợp lệ làm trigger báo lỗi để transaction signup rollback; mobile không còn gọi attach referral sau signup.
- Không nhập referral vẫn đăng ký bình thường.
- Workflow Super Admin sửa referral có audit nằm ngoài UI Auth của thay đổi này.

## Đồng bộ authenticated và Guest consent

- `personal_schedule_ai_requests` trở lại snapshot, map local/cloud và serializer với khóa `request_id`.
- Bảng request ledger dùng trigger/outbox riêng; không bị đưa nhầm vào generic trigger dùng cột `id`.
- `UserDataSyncState` hỗ trợ `idle`, `awaitingConsent`, `syncing`, `pendingUpload`, `success`, `error`, pending count, lần thành công gần nhất, lỗi an toàn và retry.
- Coordinator single-flight gộp trigger auth/startup/resume/connectivity/manual retry.
- Trình tự bắt buộc: drain outbox đúng auth user -> nếu còn marker thì bỏ qua pull -> chỉ pull sau push thành công -> thay cache trong transaction -> chỉ xóa marker đã xác nhận.
- Transaction thay cache kiểm tra lại outbox để chặn race khi local write xuất hiện trong lúc network pull.
- Pull lỗi đặt durable retry marker; local data và outbox không bị xóa.
- Sign-out chạy preflight flush có timeout; UI có thể force sign-out nhưng marker vẫn được giữ để retry ở lần đăng nhập sau.
- Guest mới chỉ rekey/upload khi chọn **Đồng bộ ngay**. Chọn **Để sau** giữ Guest data và ở Auth Gate.
- Tài khoản đã có cloud data phải qua cảnh báo hai bước; chỉ chọn **Dùng dữ liệu tài khoản** mới thay cache Guest bằng cloud.
- Settings có mục **Dữ liệu của bạn** để xem trạng thái/retry; dashboard chỉ hiện banner khi pending hoặc lỗi.
- Access, membership, Sale và Admin vẫn đọc server; snapshot chỉ chứa dữ liệu sức khỏe/lịch/request ledger do chính user sở hữu.

## Admin access

- Admin dùng storage key riêng `nanobio_admin_auth_session`.
- `AdminAccessController` theo dõi auth event, kiểm tra session còn hạn và gọi `get_my_admin_session`.
- Route Admin đi qua gate `checking/authorized/unauthorized/error`.
- Mỗi lần vào route Admin được bảo vệ, gate chủ động kiểm tra lại session và role từ server.
- Session thường, role bị thu hồi hoặc token hết hạn bị sign-out và về login.
- Thiếu cấu hình backend hoặc lỗi kiểm tra role hiển thị support state; `main_admin` không crash.

## SQL và tài liệu

- Migration không phá hủy: `docs/supabase/15-auth-sync-completion.sql`.
- Nội dung migration được đồng bộ vào `docs/supabase/config.sql` để rebuild local/sandbox.
- Không chạy `config.sql` trên remote/production.

## Giới hạn

- Không hỗ trợ merge concurrent đa thiết bị.
- Full snapshot vẫn là contract hiện tại; pending write của thiết bị hiện tại thắng trước pull.
- Cloud đã có thắng Guest chỉ sau xác nhận rõ ràng.
- Chưa có bằng chứng Supabase sandbox và thiết bị Android trong môi trường thực thi hiện tại; không claim production acceptance.

## Liên kết

- Fix P0: `../../fixbug/auth-sync-pull-data-loss/001-fixbug-auth-sync-pull-data-loss.md`
- Test plan/result: `../../test/auth-v2-admin-m05-completion/001-test-auth-v2-admin-m05-completion.md`
- Worklog: `../../worklog/2026-07-12/001-worklog-auth-v2-admin-m05-completion.md`
