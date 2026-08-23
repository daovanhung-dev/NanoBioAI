# Supabase local/sandbox rebuild

Bộ SQL này chỉ dành cho Supabase local hoặc sandbox có thể xóa dữ liệu. Không
chạy các file rebuild/seed trên staging hoặc production.

## Nguồn tin cậy và trạng thái xác minh

Thứ tự ưu tiên khi có khác biệt:

1. Sáu file authored `01_schema_rebuild_local_sandbox.sql` đến
   `06_schema_runtime_support.sql` là nguồn có thẩm quyền cho cấu trúc, RLS,
   RPC, seed và hạ tầng runtime của bộ rebuild local/sandbox.
2. `config.sql` là bản dẫn xuất được sinh nguyên văn từ 01 → 06 bởi
   `tools/build_supabase_rebuild_config.py`; không sửa file này bằng tay.
3. Các file 90 → 94 chỉ là truy vấn/transaction xác minh sau rebuild. Chúng
   không định nghĩa hoặc thay thế schema, RPC hay seed.

Kiểm tra parity tĩnh của `config.sql`:

```bash
python3 tools/build_supabase_rebuild_config.py --check
```

Trạng thái tại baseline `25018e8`:

- Parity tĩnh giữa `config.sql` và 01 → 06: `STATIC-VERIFIED`.
- Sandbox runtime (thực thi 01 → 06 rồi 90 → 94): `UNVERIFIED`.
- Edge Function và luồng Flutter trên thiết bị: `UNVERIFIED`.

`UNVERIFIED` không có nghĩa là thất bại; nó có nghĩa là repository chưa có
bằng chứng chạy local/sandbox hoặc thiết bị cho baseline này.
Không suy diễn trạng thái production từ contract SQL hay contract test tĩnh.

## Thứ tự chạy

| Thứ tự | File | Mục đích |
| --- | --- | --- |
| 01 | `01_schema_rebuild_local_sandbox.sql` | Tạo lại toàn bộ public schema. |
| 02 | `02_schema_meal_nutrition_v18.sql` | Bổ sung nutrition v18 cho meal catalog và snapshot. |
| 03 | `03_schema_daily_health_hub_rewards.sql` | Bổ sung Daily Health Hub reward RPC. |
| 04 | `04_schema_auth_account_lock.sql` | Đồng bộ khóa/mở tài khoản với Supabase Auth session. |
| 05 | `05_seed_local_sandbox.sql` | Seed cấu hình, catalog, fixture và tài khoản test Plus. |
| 06 | `06_schema_runtime_support.sql` | Tạo bucket Storage runtime và xác nhận/grant các RPC Flutter dùng. |
| 90 | `90_validate_meal_catalog.sql` | Kiểm tra catalog 163 món ăn. |
| 91 | `91_validate_meal_nutrition_v18.sql` | Kiểm tra nutrition v18. |
| 92 | `92_validate_daily_health_hub_rewards.sql` | Kiểm tra static contract Daily Health Hub. |
| 93 | `93_validate_membership_vietqr.sql` | Tạo thử mã VietQR và rollback toàn bộ thay đổi. |
| 94 | `94_validate_runtime_support.sql` | Kiểm tra RPC, view, trigger, Storage và quyền runtime. |

`01` xóa `public` schema. `05` xóa toàn bộ Supabase Auth users/identities/sessions
trước khi seed. Luôn chạy 01 → 06 trước, sau đó mới chạy 90 → 94. Không chạy
`config.sql` sau khi đã chạy bộ 01 → 06, vì `config.sql` cũng là rebuild đầy đủ.

## Cách chạy

Trong SQL Editor local/sandbox, dán và chạy từng file theo bảng. Khi dùng
`psql`, bật dừng ngay khi lỗi:

```bash
psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f docs/supabase/01_schema_rebuild_local_sandbox.sql
```

Lặp lại lệnh cho các file còn lại theo đúng thứ tự. Hoặc chạy duy nhất
`docs/supabase/config.sql` để rebuild 01 → 06, rồi chạy 90 → 94. Chỉ ghi nhận
PASS runtime khi tất cả lệnh thực sự chạy thành công trên cùng một local/sandbox
có thể xóa dữ liệu; việc đọc file hoặc chạy contract test không thay thế bước
này.

## Edge Functions bắt buộc

`delete-account` là Edge Function bắt buộc cho thao tác xóa tài khoản. Nó xác
thực JWT của người gọi, chỉ xóa chính tài khoản đó bằng service role ở server,
và không trả dữ liệu tài khoản. Deploy riêng sau khi cấu hình secret runtime:

```bash
supabase functions deploy delete-account --project-ref "$SUPABASE_PROJECT_REF"
```

`voice-live-token` là phương án cũ; Voice runtime hiện không yêu cầu deploy
function này. Không đưa service-role key vào Flutter hoặc file `.env` của app.

## Tài khoản Plus local

Seed tạo một tài khoản Plus đã xác nhận email, profile/self subject và quyền
AI chat không giới hạn. Đây chỉ là fixture local/sandbox; không sao chép vào
môi trường dùng chung.

## Tạo mã giao dịch VietQR

Trong ứng dụng, người dùng tạo yêu cầu nâng cấp. RPC
`create_membership_payment_request` sinh mã đối soát `NB` bất biến, lấy số tiền
và tài khoản nhận từ cấu hình server. Flutter dùng `VietQrPayloadBuilder` để
render QR từ response đó.

Không truyền số tiền, ngân hàng, số tài khoản hoặc mã đối soát từ client. Cùng
idempotency key luôn trả lại cùng giao dịch; khi còn một yêu cầu mở, yêu cầu mới
bị từ chối. `93_validate_membership_vietqr.sql` kiểm tra chính flow này trong
một transaction rồi rollback, nên không tạo giao dịch tồn tại sau khi chạy.
