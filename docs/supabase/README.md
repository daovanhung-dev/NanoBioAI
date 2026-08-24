# Supabase local/sandbox rebuild

Bộ SQL này chỉ dành cho Supabase local hoặc sandbox có thể xóa dữ liệu. Không
chạy các file rebuild/seed trên staging hoặc production.

## Nguồn tin cậy và trạng thái xác minh

Thứ tự ưu tiên khi có khác biệt:

1. `01_build_system.sql` là nguồn có thẩm quyền để dựng public schema, RLS,
   RPC, Storage runtime, Daily Health Hub, account lock và M31 Sleep Safety.
2. `02_seed_data.sql` là nguồn có thẩm quyền để reset Auth sandbox, nạp cấu
   hình, catalog, tài khoản thử và toàn bộ fixture nghiệp vụ.

Không có file SQL tổng hợp hoặc file validate chạy riêng. Các assertion và
smoke rollback-only cần thiết được nhúng trong đúng script sở hữu dữ liệu đó.

Trạng thái M31 trong delivery 2026-08-24:

- `01_build_system.sql` tạo fail-safe M31 `enabled=false`, thêm runtime
  support, rồi áp dụng rollout hiện hành `default.enabled=true` ở pha cuối.
- Việc bật rollout không cấp quyền sử dụng: Flutter và Edge Function vẫn phải
  xác minh Plus/FamilyPlus từ trusted `effective_user_access`.
- Supabase sandbox runtime và Edge Functions M31 là `UNVERIFIED` cho tới khi
  chạy rebuild/deploy/smoke thật.

`UNVERIFIED` không có nghĩa là thất bại; nó có nghĩa là repository chưa có
bằng chứng runtime cho thay đổi này. Không suy diễn trạng thái production từ
contract SQL hay contract test tĩnh.

## Thứ tự chạy

| Thứ tự | File | Mục đích |
| --- | --- | --- |
| 01 | `01_build_system.sql` | Dựng lại toàn bộ hệ thống: schema, RLS, RPC, Storage, runtime support và rollout M31. |
| 02 | `02_seed_data.sql` | Reset Auth sandbox, seed cấu hình/catalog/fixture/tài khoản thử, rồi chạy assertion seed và smoke VietQR rollback-only. |

`01_build_system.sql` xóa `public` schema. `02_seed_data.sql` xóa toàn bộ
Supabase Auth users/identities/sessions trước khi seed. Luôn chạy `01` rồi
`02` trên cùng local/sandbox disposable.

Các assertion Daily Health Hub/runtime nằm trong `01_build_system.sql`.
`02_seed_data.sql` kiểm tra catalog/nutrition trước commit và chạy smoke VietQR
trong transaction rollback-only sau commit, nên không để lại giao dịch thử.

## Cách chạy

Trong SQL Editor local/sandbox, chạy đúng hai file theo bảng. Khi dùng `psql`,
bật dừng ngay khi lỗi:

```bash
psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f docs/supabase/01_build_system.sql
psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f docs/supabase/02_seed_data.sql
```

Chỉ ghi nhận PASS runtime khi cả hai lệnh thực sự chạy thành công trên cùng một
local/sandbox có thể xóa dữ liệu; việc đọc file hoặc chạy contract test không
thay thế bước này.

## Edge Functions bắt buộc

`delete-account` tiếp tục là Edge Function bắt buộc cho thao tác xóa tài khoản.
Nó xác thực JWT của người gọi, chỉ xóa chính tài khoản đó bằng service role ở
server, và không trả dữ liệu tài khoản.

M31 bổ sung ba Edge Functions:

- `sleep-safety-contact-verification`: OTP xác minh SafetyContact; OTP không trả
  về Flutter và chỉ hash được lưu trong DB.
- `sleep-safety-dispatch`: kiểm tra lại Plus/FamilyPlus, rollout, sự kiện gần
  thời gian hiện tại, rate limit và người liên hệ đã xác minh trước khi gửi.
- `sleep-safety-provider-webhook`: nhận callback provider có secret và tiếp tục
  cascade `voice → SMS → người ưu tiên tiếp theo` khi provider báo thất bại hoặc
  không bắt máy.

Các function M31 dùng provider-neutral HTTP facade. Secret chỉ nằm ở Edge
Function runtime:

```text
SLEEP_SAFETY_PROVIDER_BASE_URL
SLEEP_SAFETY_PROVIDER_TOKEN
SLEEP_SAFETY_PROVIDER_WEBHOOK_SECRET
```

Không đưa service-role key, provider token hoặc webhook secret vào Flutter,
Android/iOS source hay `.env` được bundle vào app.

Ví dụ deploy sau khi đã cấu hình secret trên sandbox:

```bash
supabase functions deploy sleep-safety-contact-verification --project-ref "$SUPABASE_PROJECT_REF"
supabase functions deploy sleep-safety-dispatch --project-ref "$SUPABASE_PROJECT_REF"
supabase functions deploy sleep-safety-provider-webhook --project-ref "$SUPABASE_PROJECT_REF"
```

## M31 privacy / rollout contract

- Không có cột raw audio, audio blob, audio path hoặc transcript trong M31.
- Audio chỉ được xử lý tạm thời trên thiết bị.
- `01_build_system.sql` giữ kill switch server-side để có thể tắt ngay khi có
  sự cố, dù rollout hiện hành đặt `default.enabled=true`.
- M31 là cảnh báo hỗ trợ sớm phi y tế; không tự gọi 115 và không được mô tả như
  thiết bị y tế hoặc hệ thống cấp cứu chuyên dụng.

## Tài khoản Plus local

`02_seed_data.sql` tạo các fixture local/sandbox theo contract hiện hành. Khi
acceptance cần test Plus/FamilyPlus, dùng fixture/trusted access hiện có hoặc
fixture sandbox riêng; không hard-code paid access vào client.

## Tạo mã giao dịch VietQR

Luồng VietQR không thay đổi. RPC `create_membership_payment_request` vẫn sinh
mã đối soát `NB` bất biến, lấy số tiền và tài khoản nhận từ cấu hình server.
Flutter chỉ render dữ liệu server trả về; pending payment không cấp quyền. M31
chỉ đọc `effective_user_access` và không thay đổi contract thanh toán.
