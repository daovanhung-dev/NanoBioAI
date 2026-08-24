# Supabase local/sandbox rebuild

Bộ SQL này chỉ dành cho Supabase local hoặc sandbox có thể xóa dữ liệu. Không
chạy các file rebuild/seed trên staging hoặc production.

## Nguồn tin cậy và trạng thái xác minh

Thứ tự ưu tiên khi có khác biệt:

1. Tám file authored `01_schema_rebuild_local_sandbox.sql` đến
   `08_enable_sleep_safety_rollout.sql` là nguồn có thẩm quyền cho cấu trúc, RLS,
   RPC, seed và hạ tầng runtime của bộ rebuild local/sandbox.
2. `config.sql` là bản dẫn xuất được sinh nguyên văn từ 01 → 08 bởi
   `tools/build_supabase_rebuild_config.py`; không sửa file này bằng tay.
3. Các file 90 → 94 chỉ là truy vấn/transaction xác minh sau rebuild. Chúng
   không định nghĩa hoặc thay thế schema, RPC hay seed.

Kiểm tra parity tĩnh của `config.sql`:

```bash
python3 tools/build_supabase_rebuild_config.py --check
```

Trạng thái M31 trong delivery 2026-08-24:

- `07_schema_sleep_safety.sql`: authored schema M31.
- `08_enable_sleep_safety_rollout.sql`: authored rollout decision, bật `default.enabled=true`.
- Generator đã mở rộng source order tới 08.
- `config.sql`: **chưa được regenerate trong môi trường agent hiện tại** vì
  không có checkout đầy đủ của repository; phải chạy generator sau khi chép
  delivery vào workspace thật.
- Supabase sandbox runtime và Edge Functions M31: `UNVERIFIED` cho tới khi
  chạy rebuild/deploy/smoke thật.

`UNVERIFIED` không có nghĩa là thất bại; nó có nghĩa là repository chưa có
bằng chứng runtime cho thay đổi này. Không suy diễn trạng thái production từ
contract SQL hay contract test tĩnh.

## Thứ tự chạy

| Thứ tự | File | Mục đích |
| --- | --- | --- |
| 01 | `01_schema_rebuild_local_sandbox.sql` | Tạo lại toàn bộ public schema. |
| 02 | `02_schema_meal_nutrition_v18.sql` | Bổ sung nutrition v18 cho meal catalog và snapshot. |
| 03 | `03_schema_daily_health_hub_rewards.sql` | Bổ sung Daily Health Hub reward RPC. |
| 04 | `04_schema_auth_account_lock.sql` | Đồng bộ khóa/mở tài khoản với Supabase Auth session. |
| 05 | `05_seed_local_sandbox.sql` | Seed cấu hình, catalog, fixture và tài khoản test Plus. |
| 06 | `06_schema_runtime_support.sql` | Tạo bucket Storage runtime và xác nhận/grant các RPC Flutter dùng. |
| 07 | `07_schema_sleep_safety.sql` | M31 Sleep Safety: config rollout, preference/session/event, SafetyContact, verification, dispatch, RLS/RPC. |
| 08 | `08_enable_sleep_safety_rollout.sql` | Bật kill switch M31 cho runtime; không thay đổi membership/access. |
| 90 | `90_validate_meal_catalog.sql` | Kiểm tra catalog 163 món ăn. |
| 91 | `91_validate_meal_nutrition_v18.sql` | Kiểm tra nutrition v18. |
| 92 | `92_validate_daily_health_hub_rewards.sql` | Kiểm tra static contract Daily Health Hub. |
| 93 | `93_validate_membership_vietqr.sql` | Tạo thử mã VietQR và rollback toàn bộ thay đổi. |
| 94 | `94_validate_runtime_support.sql` | Kiểm tra RPC, view, trigger, Storage và quyền runtime. |

`01` xóa `public` schema. `05` xóa toàn bộ Supabase Auth users/identities/sessions
trước khi seed. Luôn chạy 01 → 08 trước, sau đó mới chạy 90 → 94. Không chạy
`config.sql` sau khi đã chạy bộ 01 → 08, vì `config.sql` cũng là rebuild đầy đủ.

## Cách chạy

Trong SQL Editor local/sandbox, dán và chạy từng file theo bảng. Khi dùng
`psql`, bật dừng ngay khi lỗi:

```bash
psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f docs/supabase/01_schema_rebuild_local_sandbox.sql
```

Lặp lại lệnh cho các file còn lại theo đúng thứ tự. Hoặc sau khi đã regenerate
`config.sql`, chạy duy nhất `docs/supabase/config.sql` để rebuild 01 → 08, rồi
chạy 90 → 94. Chỉ ghi nhận PASS runtime khi tất cả lệnh thực sự chạy thành công
trên cùng một local/sandbox có thể xóa dữ liệu.

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
- `07_schema_sleep_safety.sql` tạo kill switch M31 với `enabled=false`; `08_enable_sleep_safety_rollout.sql` là quyết định rollout hiện hành và chuyển cấu hình `default` sang `enabled=true`.
- Kill switch server-side vẫn phải được giữ để có thể tắt ngay khi có sự cố.
- Việc `enabled=true` không cấp quyền sử dụng: Flutter và Edge Function vẫn phải
  xác minh Plus/FamilyPlus từ trusted `effective_user_access`.
- M31 là cảnh báo hỗ trợ sớm phi y tế; không tự gọi 115 và không được mô tả như
  thiết bị y tế hoặc hệ thống cấp cứu chuyên dụng.

## Tài khoản Plus local

Seed hiện hành tiếp tục tạo tài khoản Plus local/sandbox theo contract trước M31.
M31 không tự sửa fixture đó trong file 07. Khi acceptance cần test Plus/FamilyPlus,
dùng fixture/trusted access hiện có hoặc fixture sandbox riêng; không hard-code
paid access vào client.

## Tạo mã giao dịch VietQR

Luồng VietQR hiện hành không thay đổi. RPC `create_membership_payment_request`
vẫn sinh mã đối soát `NB` bất biến, lấy số tiền và tài khoản nhận từ cấu hình
server. Flutter chỉ render dữ liệu server trả về; pending payment không cấp
quyền. M31 chỉ đọc `effective_user_access` và không thay đổi contract thanh toán.
