# Runbook — cấp ưu đãi VIP 1 tháng (Plus 30 ngày)

## Nguyên tắc

- Website gọi ưu đãi là **VIP 1 tháng** để khách dễ hiểu.
- Trong hệ thống NanoBio, **không tạo tier `vip` mới**. Ưu đãi được cấp bằng gói `plus` trong 30 ngày.
- Browser/anon client **không được tự cấp** gói trả phí.
- Việc cấp gói dùng trusted Admin flow hiện có (`admin-grant-membership`) để giữ audit, thời hạn và kiểm soát quyền.
- Một SĐT chỉ có một record `early_access_leads`; việc tải lại không được làm mới ưu đãi đã `active/expired/cancelled`.

## Flow vận hành

1. Khách bấm **Tải ứng dụng miễn phí**.
2. Khách nhập SĐT + consent.
3. Edge Function `register-early-access` ghi:
   - `promotion_code = EARLY_ACCESS_PLUS_30D`
   - `requested_plan = plus`
   - `vip_duration_days = 30`
   - `vip_grant_status = pending_account_link`
4. Khách nhận signed APK URL nếu APK đã có trong private Storage.
5. Khi khách có tài khoản NanoBio, Support/Admin đối chiếu SĐT với tài khoản cần nhận ưu đãi.
6. Super Admin cấp `plus` 30 ngày qua function trusted `admin-grant-membership` của app chính.
7. Sau khi cấp thành công, cập nhật lead:
   - `claimed_user_id = <user_id>`
   - `vip_grant_status = active`
   - `vip_granted_at = starts_at`
   - `vip_expires_at = ends_at`
8. Khi hết hạn, hệ thống membership chính chịu trách nhiệm hết quyền Plus; lead có thể cập nhật `expired` để báo cáo.

## Payload cấp gói qua Admin function hiện có

Ví dụ body (thời gian phải do hệ thống/Admin tính thật, không copy nguyên ví dụ):

```json
{
  "user_id": "<UUID tài khoản>",
  "plan_code": "plus",
  "starts_at": "<ISO time bắt đầu>",
  "ends_at": "<ISO time + 30 ngày>",
  "reason": "Early Access - VIP 1 tháng",
  "idempotency_key": "early-access-plus-30d:<lead-id>",
  "preserve_existing_paid_plan": true
}
```

`preserve_existing_paid_plan=true` tránh ghi đè người dùng đang có gói trả phí hợp lệ. Chính sách cụ thể cho người đang có Plus/FamilyPlus nên được Product/Admin chốt trước khi chạy promotion quy mô lớn.

## Query hàng chờ

Chạy trong môi trường Admin/SQL được ủy quyền:

```sql
select
  id,
  phone_e164,
  phone_display,
  created_at,
  vip_grant_status,
  requested_plan,
  vip_duration_days
from public.early_access_leads
where vip_grant_status in ('pending_account_link', 'pending_activation')
order by created_at asc;
```

## Cập nhật sau khi cấp thành công

```sql
update public.early_access_leads
set
  claimed_user_id = '<USER_UUID>',
  vip_grant_status = 'active',
  vip_granted_at = '<STARTS_AT>',
  vip_expires_at = '<ENDS_AT>'
where id = '<LEAD_UUID>';
```

Không cập nhật `active` trước khi trusted membership grant thành công.
