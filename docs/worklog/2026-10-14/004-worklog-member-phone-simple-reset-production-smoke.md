# Worklog - Member Phone Auth With Simple Admin Password Reset

## Thời gian

- Ngày: 2026-10-14
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Module: M05 `AUTH_PROFILE_SYNC`.
- Điều chỉnh theo yêu cầu mới: giữ Supabase Phone Auth tắt; thành viên đăng nhập
  bằng SĐT/mật khẩu; quên mật khẩu thì Admin thao tác đặt lại thành `12345678`.
- Giữ email login cho nhân viên Admin và giữ email cũ trong hồ sơ liên hệ.

## Thay đổi source

- Thành viên đăng ký/đăng nhập bằng SĐT Việt Nam chuẩn hóa. Server tạo alias
  Auth nội bộ; giao diện không hỏi email và không dùng Supabase Phone Auth.
- Bỏ hàng đợi yêu cầu duyệt mật khẩu, bảng/RPC liên quan và endpoint gửi yêu
  cầu. Thành viên tự đổi mật khẩu trong Cài đặt; màn Quên mật khẩu hướng dẫn
  liên hệ Admin.
- Admin Web có thao tác đặt lại mật khẩu thành viên. Edge Function chỉ cho
  Super Admin thực hiện, yêu cầu lý do, ghi audit, đặt `12345678` và bật cờ
  bắt buộc đổi mật khẩu ở lần đăng nhập kế tiếp.
- Cập nhật canonical SQL, migrations, seed, docs, test và nội dung lỗi để dùng
  luồng rút gọn.

## Kiểm chứng source

- `flutter analyze` trên auth/settings/auth-service và test liên quan: PASS.
- `flutter test test/app_versions/v2/features/auth test/services/supabase/auth test/docs/supabase_member_phone_auth_contract_test.dart`: 44 test PASS.
- `deno check` Edge Functions đăng ký, đổi mật khẩu, Admin management và
  provisioning: PASS.
- Deno tests cho signup, password change, Admin reset, single/bulk account
  provisioning và migration review: 31 test PASS khi chạy toàn bộ bộ liên quan;
  lượt kiểm tra rút gọn sau khi đơn giản hóa: 14 test PASS.
- Admin Web `npm run typecheck`: PASS; `npm test`: 67 test PASS.
- `deno fmt --check` và `git diff --check`: PASS.
- Dart Tooling Daemon hot reload trên Android: PASS. Flutter Driver extension
  chưa bật, nên chưa có thao tác UI login/reset trên thiết bị.
- Runtime error reader sau hot reload: không có lỗi runtime.

## Production: project `rnwohifdnylqfofkydfl`

- Trước khi ghi: liên kết project và migration history khớp project; dry-run chỉ
  liệt kê hai migration phone-auth additive.
- Snapshot số điện thoại: 7 hồ sơ; 6 lưu dạng local 10 chữ số và 1 dạng `84`;
  không có số trùng sau chuẩn hóa. Unique index trên `public.users.phone` đúng
  định nghĩa; RPC giới hạn signup chỉ cho `service_role` gọi.
- Áp dụng `20261014090000_member_phone_auth_security.sql` và
  `20261014110000_member_phone_login_alias.sql`; migration list sau đó xác nhận
  cả hai đã có trên remote. Không chạy canonical rebuild/seed.
- Deploy và xác minh `member-phone-signup`, `member-change-password`,
  `admin-user-management`, `admin-create-account` và
  `admin-provision-accounts-bulk` ở trạng thái ACTIVE với cấu hình JWT đúng.
- Production API smoke tạo một hồ sơ kiểm thử tổng hợp rồi đăng nhập bằng
  alias/mật khẩu qua Supabase Auth: signup PASS, password login PASS. Hồ sơ
  kiểm thử còn lại trên production; SĐT kết thúc bằng `6453`, không ghi mật
  khẩu hoặc toàn bộ SĐT vào worklog.
- Xác minh DB read-only thấy đúng một hồ sơ test và một Auth alias tương ứng.
- Snapshot sau smoke có 8 hồ sơ SĐT và 8 Auth user; chỉ tài khoản test mới đã
  dùng alias. Bảy Auth identity có sẵn chưa được chuyển sang alias, nên chưa
  đăng nhập được bằng SĐT cho đến khi được review/chuyển đổi theo migration.
- Phone Auth/email-confirmation không bị thay đổi trong lượt này. Lệnh đọc Auth
  settings timeout; không ghi nhận giá trị mới từ endpoint đó.
- Không có production smoke cho thao tác Admin reset vì không có phiên Admin
  tương tác trong công cụ hiện tại. Tại thời điểm snapshot này chưa có Android
  signup/login evidence.

## Trạng thái

- Source, focused tests, additive production migrations, Edge deployment và
  production API signup/password-login smoke: PASS.
- Android 11 smoke bổ sung: PASS qua chính `SupabaseAuthRemoteDatasource` trên
  thiết bị `220333QPG`. Datasource đăng ký bằng SĐT/mật khẩu, đăng xuất local,
  đăng nhập lại bằng SĐT/mật khẩu và xác nhận cùng Auth user ID.
- Smoke Android tạo thêm một tài khoản production tổng hợp. SĐT và mật khẩu
  ngẫu nhiên chỉ ở bộ nhớ trong lúc chạy; không in/ghi ra file. Không xóa tài
  khoản production sau kiểm thử.
- UI widget đăng ký/đăng nhập chưa được tự động chạm/gửi form trực tiếp; hiện
  mới có widget tests cho form và smoke live qua datasource mà controller dùng.
- Admin reset trực tiếp qua Admin Web và chuyển đổi tài khoản cũ trên
  production chưa được xác minh/thực hiện.
- Tài khoản cũ có SĐT local cần được chuẩn hóa/migration có kiểm soát trước khi
  người dùng đó đăng nhập bằng luồng mới; không đổi mật khẩu hoặc Auth ID.

## Bổ sung xác minh

- Chạy lại `flutter test test/app_versions/v2/features/auth test/services/supabase/auth test/docs/supabase_member_phone_auth_contract_test.dart`: PASS, 44 tests.
- Flutter widget inspector trên app Android đang kết nối trả về `V2RegisterPage`; runtime error reader không phát hiện lỗi.
- Chưa thao tác signup/login qua UI: Flutter Driver extension chưa bật. Chrome Supabase Dashboard có tab ở Auth Providers nhưng CUA báo debugger chưa attach; không chỉnh cấu hình production.
- Ở lượt xác minh trước, không tạo thêm tài khoản production; lượt sau bổ sung Android datasource smoke được ghi riêng bên dưới.
- Báo cáo test chi tiết: `docs/test/member-phone-signup-login/001-test-member-phone-signup-login.md`.
- `git diff --check`: PASS. `pwsh -NoProfile -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1`: FAIL do thiếu `docs/audit/source_truth_manifest.json` và stale path trong history/task-skill cũ, không liên quan thay đổi M05.
- Lần thử `flutter test` cho network smoke không gửi request: `TestWidgetsFlutterBinding` thay outbound HTTP bằng phản hồi 400; kết quả báo `accountCreated=false`. Đã bỏ test tạm đó và chạy smoke trên Android thật.
- `flutter analyze tools/live_member_phone_auth_smoke.dart`: PASS. Harness tạm gọi datasource thật và in `LIVE_MEMBER_PHONE_AUTH=PASS`; sau khi kiểm thử đã xóa file harness.
- Khởi chạy lại app chính bằng `pwsh -NoProfile -ExecutionPolicy Bypass -File tools/run_v2.ps1 -DeviceId 12b304f9`; build/install/launch PASS.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - production smoke chạy qua datasource của app trên Android và xác nhận cùng Auth user ID sau khi đăng nhập lại.
- Mức độ hoàn thành task: yêu cầu tạo tài khoản mới rồi đăng nhập bằng SĐT đã PASS; UI tap trực tiếp, Admin reset và tài khoản cũ vẫn ngoài kiểm chứng của mục tiêu này.
- Bằng chứng kiểm chứng: Android production datasource smoke; Flutter 44 tests; analyzer harness; runtime error reader.
- Điểm tốn token/chưa tối ưu: thử network trong `flutter test` bị TestWidgetsFlutterBinding chặn; lần sau chạy live network smoke trên device/emulator ngay từ đầu.
- Cách tối ưu cho phiên sau: không tạo thêm tài khoản production; nếu cần UI tap acceptance, dùng integration_test trên device với tài khoản test được cấp.
- Task-skill cần đọc lần sau: `.codex/task-skills/test.md`.
