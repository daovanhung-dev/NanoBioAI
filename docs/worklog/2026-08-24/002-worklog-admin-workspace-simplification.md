# Worklog — Đơn giản hóa môi trường NanoBio Admin

## Metadata

- Ngày: 2026-08-24
- Workflow: `coding`
- Domain chính: Access / Membership / Referral Sale
- Baseline GitHub: `431257709907841400527e223ec0a4994e2a0c48`
- Phạm vi: Admin app, account management, Sale review/payout, membership payment review, trusted Edge Functions.
- Trạng thái xác minh: Static-verified; Edge handler smoke-verified; Flutter runtime-unverified; Supabase sandbox-unverified.

## Mục tiêu đã thực hiện

Thu gọn môi trường Admin từ workspace 11 section về 6 công việc người vận hành cần dùng:

1. Tạo tài khoản.
2. Nâng cấp tài khoản.
3. Quản trị tài khoản.
4. Duyệt Sale.
5. Thanh toán Sale.
6. Duyệt nâng cấp gói thành viên.

## Thay đổi runtime

### Router và shell

- Default Admin chuyển sang `/admin/accounts`.
- Thêm 6 destination mới:
  - `/admin/accounts/create`
  - `/admin/accounts/upgrade`
  - `/admin/accounts`
  - `/admin/sales/review`
  - `/admin/sales/payouts`
  - `/admin/memberships/review`
- 11 route workspace cũ được giữ dưới dạng redirect để bookmark/deep-link cũ không 404.
- Navigation mới chỉ render đúng 6 công việc, chia 3 nhóm Tài khoản / Sale / Thành viên.
- Compact dùng drawer; desktop dùng sidebar; không còn Dashboard/Đối soát/Báo cáo/Config trong navigation người dùng Admin.

### Tài khoản

- Tạo typed model `AdminAccountSummary`, create-account request/result và membership-grant request/result.
- Tách `AdminAccountsController` khỏi generic workspace controller.
- Quản trị tài khoản dùng RPC permissioned `admin_search_users` và `admin_update_user_status` hiện có.
- Tạo tài khoản mới đi qua `admin-create-account` Edge Function; Flutter không có service-role key.
- Nâng cấp thủ công Plus/FamilyPlus đi qua `admin-grant-membership` Edge Function; chỉ Super Admin.
- Idempotency key được giữ lại trong controller nếu request create/grant thất bại không chắc chắn, giúp retry cùng thao tác không tạo bản ghi thứ hai.

### Sale

- Tách `AdminSalesController` cho hai queue: hồ sơ Sale và quy đổi/chi trả.
- Duyệt/từ chối Sale tiếp tục dùng `admin_review_sale_profile` hiện có.
- Thanh toán Sale tiếp tục dùng `admin_review_sale_point_conversion` và repository upload payout proof hiện có.
- `mark_paid` bắt buộc có ảnh proof trước khi gọi backend.

### Duyệt nâng cấp gói thành viên

- Tách `AdminMembershipController`.
- Queue chỉ hiển thị payment có trạng thái backend cho phép review.
- Giữ rule Finance Admin/Super Admin từ `canReviewMembershipPayments`.
- Duyệt bắt buộc checkbox xác nhận đã đối chiếu Vietcombank + lý do.
- Tiếp tục dùng `admin_review_payment`; entitlement chỉ đổi sau backend success.

## Trusted backend mới

### `admin-create-account`

- JWT bắt buộc (`verify_jwt = true`).
- Chỉ Super Admin hoặc Support Admin có assignment + role đang hoạt động.
- Tạo Auth user bằng service role ở Edge Function.
- Không trả/ghi log mật khẩu.
- Bắt buộc reason + idempotency key.
- Ghi `admin_audit_events` sau success.
- Nếu audit fail, cố gắng xóa bù Auth user vừa tạo và trả safe error.

### `admin-grant-membership`

- JWT bắt buộc; chỉ Super Admin đang hoạt động.
- Chỉ nhận `plus` / `family_plus` và khoảng thời gian hợp lệ.
- Không thêm schema mới: dùng `membership_subscriptions.source = manual` đúng canonical constraint.
- Provenance/idempotency dùng `provider = admin_manual` và `provider_subscription_id = idempotency_key`.
- Subscription active/trialing cũ chuyển `canceled`; trigger canonical đồng bộ effective tier.
- Success cần cả subscription và audit evidence mới được coi là idempotent-complete.
- Retry cùng key có thể tiếp tục hoàn tất một grant dở; grant mới có best-effort compensation nếu bước cancel/audit lỗi.

## Quyết định khác plan ban đầu

Plan đề xuất có thể thêm RPC `admin_grant_membership`. Sau khi đọc source-of-truth Supabase mới, repo quy định `01..06` là authored canonical và `config.sql` là generated. Để không tạo drift schema/config trong phiên không có full local clone và vì thao tác tạo Auth user vốn đã cần service role, implementation đặt **manual membership grant sau authenticated Edge Function** thay vì thêm một RPC/schema delta. Business outcome, role guard, idempotency, audit và trusted-backend boundary vẫn được giữ.

## Documentation/source truth

- Cập nhật `docs/supabase/README.md` với hai Edge Function Admin và deploy contract.
- Cập nhật `supabase/config.toml` để cả hai function `verify_jwt = true`.
- Cập nhật `.codex/design/groups/08_admin.md` và `14_ROUTE_MATRIX.md`: Admin hiện có 7 active route (login + 6 work destinations), 11 URL cũ chỉ là compatibility redirects.
- Không sửa `docs/supabase/config.sql` vì không có schema/RPC canonical thay đổi.

## Test / verification evidence

PASS trong môi trường phiên này:

- TypeScript strict type-check cho hai handler `.ts`.
- Node TypeScript syntax check cho toàn bộ file của hai Edge Function.
- Node smoke test trực tiếp với Web `Request/Response` cho create-account và grant-membership handler.
- Static contract check:
  - đủ 6 active destinations;
  - đủ 11 legacy redirects;
  - `SUPABASE_SERVICE_ROLE_KEY` không xuất hiện trong `lib/**/*.dart`;
  - `source = manual` đúng canonical membership constraint;
  - cả 3 Edge Function bắt buộc có `verify_jwt = true`.
- Bổ sung Dart contract/model tests và Deno handler tests để chạy trong repo đầy đủ.

Chưa chạy được trong môi trường phiên này:

- `dart format`, `flutter analyze`, `flutter test`: runtime container không có Dart/Flutter SDK.
- Deno tests: container không có Deno runtime.
- Supabase sandbox deploy/RLS/UAT: không có sandbox project/CLI credential trong phiên.
- Android/iOS UI smoke: không có Flutter/device bridge trong runtime này.

Không claim các bước trên là PASS.

## Legacy cleanup

Các file `AdminWorkspacePage`/Dashboard/Reconciliation/Reports/Config cũ không còn reachable từ `adminRouter`, nhưng chưa xóa vật lý trong đợt này. Lý do: plan chỉ cho xóa sau regression/runtime tests; Flutter runtime hiện không khả dụng. Giữ file source-only giúp rollback an toàn và không làm tăng rủi ro compile do delete rộng trước khi full test.

## Self-review

### Output quality

- UI bám đúng 6 công việc, giảm cognitive load và không đưa backend terminology vào màn hình chính.
- New privileged flows giữ service-role ở server và role checks độc lập với UI.
- Tái sử dụng backend Sale/payment hiện có thay vì tạo logic song song.

### Completion

- Implementation source: hoàn thành theo phạm vi có thể xác minh tĩnh.
- Runtime/sandbox acceptance: chưa hoàn tất do thiếu SDK/runtime/sandbox, được ghi rõ thay vì suy diễn.

### Verification strength

- Tốt cho static contract và Edge handler behavior.
- Chưa đủ để gọi production-ready trước Flutter analyze/test + Supabase sandbox + device smoke.

### Token/resource efficiency

- Đọc router/domain/datasource và canonical Supabase contracts có mục tiêu; không tải toàn bộ `lib/**` hoặc toàn bộ worklog.
- Giữ legacy source thay vì refactor/xóa rộng khi không có Flutter gate, giảm phạm vi regression.

### Next-session optimization

Khi có full clone + Flutter/Deno/Supabase sandbox, ưu tiên chạy theo thứ tự:

1. `dart format` cho toàn bộ touched Dart.
2. targeted `flutter analyze` + tests Admin mới/legacy.
3. `deno test` hai Edge Function.
4. deploy sandbox, smoke create account/manual grant/payment/Sale payout.
5. UI adaptive smoke compact/desktop + dark/text-scale.
6. Chỉ sau khi toàn bộ gate PASS mới xóa source legacy không reachable và refresh `.codex/history`.
