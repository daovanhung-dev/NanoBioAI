# Supabase local/sandbox rebuild

Bộ SQL này chỉ dành cho Supabase local hoặc sandbox có thể xóa dữ liệu. Không
chạy các file rebuild/seed trên staging hoặc production.

## Nguồn tin cậy

Tại HEAD hiện tại, bộ rebuild canonical vẫn chỉ gồm hai file:

1. `01_build_system.sql` — schema, RLS, RPC và runtime contracts.
2. `02_seed_data.sql` — cấu hình/catalog và fixture sandbox không nhạy cảm.

`03_ai_runtime_enablement.sql` là preflight AI tùy chọn, chỉ đọc và không
thuộc rebuild sequence. Chạy file này sau cặp canonical để xác minh database
AI chat, tạo lịch, phản hồi nội dung và quota đã sẵn sàng; nó không tạo schema,
seed, Edge Function hay provider credential.

Không có các file `01_schema_rebuild_local_sandbox.sql` đến `06_*` hoặc
`config.sql`. Không tạo file giả để bù cho đường dẫn lịch sử; cập nhật cặp
canonical khi schema/runtime thay đổi, và chỉ cập nhật preflight khi contract
AI thay đổi.

## Thứ tự chạy

Chạy `01_build_system.sql` trước, sau đó `02_seed_data.sql`, trên cùng một
project local/sandbox có thể xóa. Script đầu tiên dựng lại public schema; script
thứ hai tạo dữ liệu cấu hình và tài khoản fixture. Không chạy trên production.

Ví dụ với `psql` (dùng biến môi trường của sandbox, không ghi giá trị vào repo):

```bash
psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f docs/supabase/01_build_system.sql
psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f docs/supabase/02_seed_data.sql
```

Chỉ ghi nhận `PASS` khi cả hai lệnh thực sự chạy thành công trên cùng một
sandbox. Đọc SQL hoặc chạy contract test tĩnh không thay thế được runtime
evidence.

Nếu cần xác minh AI database sau rebuild, chạy thêm preflight tùy chọn này:

```bash
psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f docs/supabase/03_ai_runtime_enablement.sql
```

Preflight chỉ xác minh PostgreSQL; endpoint AI và provider vẫn cần được deploy
riêng.

## Google Play Billing

Play consumer builds dùng các product ID tập trung trong
`StoreMembershipProduct`:

- `nanobio_plus_monthly`
- `nanobio_plus_yearly`
- `nanobio_family_plus_monthly`
- `nanobio_family_plus_yearly`

Các subscription/base plan tương ứng phải được tạo trong Play Console trước
khi chạy internal-track purchase test. App chỉ gửi giao dịch tới Edge Function
`google-play-verify-purchase`; function xác minh với Google, ghi
`google_play_purchase_ledger` và cập nhật membership qua RPC bảo mật. Client
không được tự cấp gói từ trạng thái giao dịch cục bộ.

AI runtime dùng Edge Function `nabi-ai-generate`. Gemini API key chỉ được đặt
ở secret của Edge Function; Flutter chỉ gửi prompt đã giới hạn kích thước và
không nhận/ghi credential nhà cung cấp. `report-ai-content` cho phép guest gửi
phản hồi có giới hạn tốc độ và lưu qua service role.

Food Scan dùng Edge Function riêng `food-scan-analyze` cho hai operation
`vision` và `health`. Function xác thực JWT, kiểm tra quyền Plus/FamilyPlus
qua `effective_user_access`, giới hạn request theo user, rồi chuyển tiếp tạm
thời tới Gemini. Ảnh và kết quả Food Scan không được lưu ở Edge Function; app
tiếp tục lưu kết quả local và chỉ tạo nutrition log sau khi người dùng xác
nhận đã ăn.

Trước khi deploy `nabi-ai-generate`, export key ở shell an toàn (không commit
vào repo), rồi đặt secret vào đúng Supabase project:

```bash
supabase secrets set GEMINI_API_KEY="$GEMINI_API_KEY" --project-ref "$SUPABASE_PROJECT_REF"
```

Một preflight SQL `PASS` không chứng minh Edge route đã tồn tại hoặc provider
key hợp lệ. Sau deploy, chạy `tools/test_gemini_connection.ps1` với cấu hình
đúng project để kiểm tra endpoint thực.

## Edge Functions bắt buộc

`delete-account` xác thực JWT của người gọi, chỉ xóa chính tài khoản đó bằng
service role ở server và không trả dữ liệu tài khoản.

`admin-create-account` và `admin-grant-membership` là các thao tác đặc quyền
được xác thực ở server; không đưa service-role key hoặc mật khẩu vào Flutter.

`admin-grant-membership-bulk` là thao tác đặc quyền dành riêng cho chiến dịch
cấp Plus vĩnh viễn theo phạm vi đã định nghĩa. Function chỉ nhận JWT của Super
Admin, gọi RPC transactional bằng service role và ghi audit/idempotency cho
từng tài khoản. Không gọi function này từ client thường hoặc chạy SQL ghi trực
tiếp từ Flutter.

`admin-provision-accounts-bulk` dành riêng cho Super Admin để preview rồi tạo
tối đa 100 tài khoản Gmail và cấp Plus/FamilyPlus theo thời hạn tháng. Function
tính lại fingerprint, xử lý tuần tự, bảo toàn gói trả phí còn hạn và chỉ dùng
password tạm cho tài khoản mới. Chỉ deploy sau khi bản app có bắt đổi mật khẩu
lần đăng nhập đầu đã được phát hành.

Khi xóa `public.users`, trigger `anonymize_deleted_user_records` bỏ liên kết
user khỏi purchase ledger để giữ reconciliation tối thiểu, đồng thời xóa
snapshot/note/installation khỏi báo cáo AI. Đây là retention policy có chủ đích,
không phải lỗi cascade.

Các function có JWT bắt buộc giữ `verify_jwt = true`; `nabi-ai-generate` và
`report-ai-content` để `verify_jwt = false` vì hỗ trợ guest nhưng vẫn tự kiểm
tra/rate-limit ở handler. Deploy sau khi cấu hình secret runtime:

```bash
supabase functions deploy delete-account --project-ref "$SUPABASE_PROJECT_REF"
supabase functions deploy admin-create-account --project-ref "$SUPABASE_PROJECT_REF"
supabase functions deploy admin-grant-membership --project-ref "$SUPABASE_PROJECT_REF"
supabase functions deploy admin-grant-membership-bulk --project-ref "$SUPABASE_PROJECT_REF"
supabase functions deploy admin-provision-accounts-bulk --project-ref "$SUPABASE_PROJECT_REF"
supabase functions deploy google-play-verify-purchase --project-ref "$SUPABASE_PROJECT_REF"
supabase functions deploy nabi-ai-generate --project-ref "$SUPABASE_PROJECT_REF"
supabase functions deploy food-scan-analyze --project-ref "$SUPABASE_PROJECT_REF"
supabase functions deploy report-ai-content --project-ref "$SUPABASE_PROJECT_REF"
```

## Xác minh sau rebuild

Kiểm tra tối thiểu: hai user không đọc được dữ liệu riêng tư của nhau; client
không tự ghi membership/quota/payment; Sale không tự biến thành membership;
FamilyPlus chỉ thấy phạm vi được cấp; purchase ledger chỉ đọc được bản ghi của
chính user; và lặp lại callback thanh toán không tạo thêm entitlement.

Runtime/sandbox verification vẫn là gate riêng và phải được ghi vào
`.codex/history/OPEN_RISKS.md` bằng evidence thực thi, không suy diễn từ source.
