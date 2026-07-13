Commit de xuat: docs(supabase): cap nhat checklist nghiem thu Supabase

# Checklist nghiem thu Supabase

## Chuan bi

- Tao moi truong Supabase sandbox/staging, khong chay truc tiep production.
- Chay SQL theo thu tu trong `README.md`.
- Chuan bi user test A, B, C va mot Admin test co role phu hop.
- Dung SQL Editor/Admin/backend test co service role cho seed/payment gia lap.
  Khong dua service role key vao Flutter.

## Auth va health

- [ ] Tao user email moi, co dung mot dong trong `auth.users`, `public.users`,
  `health_subjects`.
- [ ] User A khong doc/sua duoc health data cua user B.
- [ ] Client khong insert/delete duoc `public.users`.

## Mobile snapshot sync

- [ ] Guest hoan tat onboarding + tao account cloud moi: snapshot local duoc day
  qua `sync_my_mobile_snapshot`, local dung auth UUID va co du meal/task.
- [ ] Sparse snapshot thieu `created_at`, `updated_at` hoac cot default van
  sync thanh cong; Postgres tu cap default, khong gap loi not-null `23502`.
- [ ] Client thu ghi package/Sale/payment/commission/quota/subject cua user khac
  qua payload: RPC phai bo qua hoac tu choi.
- [ ] Snapshot có hoặc không có key `wellness_point_ledgers` đều không insert,
  update hay delete ledger server-owned; app chỉ pull/merge projection đọc.

## Nhiệm vụ, bằng chứng và Điểm chăm sóc

- [ ] Bật rollout bằng một config version mới trong sandbox; khi flag còn tắt,
  RPC mutation trả `wellness_rewards_disabled` và không tạo dữ liệu.
- [ ] Register chỉ chấp nhận member đã có schedule request `succeeded`, quota
  event hợp lệ, mốc giờ tương lai và đúng 10 item khác nhau mỗi ngày.
- [ ] Nhánh `member_new` vẫn bắt buộc manifest đầy đủ `days * 10` và quota
  commit cùng request ID; marker Member ghim canonical manifest và chỉ cho một
  registration identity. Manifest thiếu/thay item hoặc gọi lại bằng key khác
  phải bị từ chối, tổng eligibility không vượt `schedule_item_count`.
- [ ] Sau khi Guest đăng nhập, đúng một request `initial_guest/succeeded` được
  marker server-owned ghim cho tài khoản. Server xác minh toàn plan có đúng 10
  mốc AI khác giờ mỗi ngày, nhưng manifest đăng ký được là tập con item chưa
  hoàn thành có `window_start > now()` trong phạm vi plan. Marker ghim cả danh
  sách item có thể đăng ký và canonical hash gồm ID/ngày/giờ/source/snapshot;
  sửa row cùng UUID giữa hai batch phải bị từ chối.
- [ ] Retry hoặc batch bổ sung cùng request Guest không nhân đôi eligibility;
  request Guest thứ hai, request bị thay đổi sau khi ghim, request đã thuộc tài
  khoản khác hoặc có nhiều request Guest thành công đều trả stable code và
  không tạo eligibility. Client không đọc/ghi trực tiếp được bảng marker.
- [ ] `begin_my_schedule_completion` bị chặn trước `window_start` và tại đúng
  `window_end`; trong `[window_start, window_end)` trả path bất biến dạng
  `<uid>/<eligibility>/<attempt>.jpg`.
- [ ] Camera cancel/permission deny không upload object, không finalize và không
  tạo điểm. Retry begin/finalize cùng idempotency key không nhân đôi attempt,
  proof, ledger hoặc allocation.
- [ ] User A không upload/select path User B; MIME khác JPEG, file > 5 MB,
  upsert, path tự tạo và path finalize khác begin đều bị chặn.
- [ ] Object upload trước hạn có thể finalize retry sau hạn; object được tạo tại
  hoặc sau `window_end` trả `proof_upload_outside_window`.
- [ ] Finalize hợp lệ tạo đúng một proof active và `+10`: trạng thái pending đến
  `window_end`, sau đó available; expiry đúng `window_end + 180 days` theo
  program config version đã snapshot.
- [ ] Undo trước hạn giữ proof với trạng thái reversed, tạo `-10` và cho phép
  hoàn thành lại bằng ảnh mới; net của eligibility không vượt `+10`. Tại/sau
  hạn undo trả `undo_window_locked`.
- [ ] Các dòng cũ `wellness_schedule_v1` có delta `+1/-1` được chuyển thành
  `+10/-10`, `is_redeemable = false` và không seed wallet.
- [ ] Authenticated client không INSERT/UPDATE/DELETE được wallet, allocation,
  ledger, eligibility, attempt, proof, inventory hoặc redemption.

## Ưu đãi và voucher

- [ ] Summary chuyển pending sang available và hết hạn idempotent; số dư ví
  bằng tổng allocation còn hiệu lực.
- [ ] Redeem khóa wallet, chọn allocation sắp hết hạn trước và cấp đúng một mã
  bằng `FOR UPDATE SKIP LOCKED`; thiếu điểm/hết kho/lỗi cạnh tranh rollback toàn
  bộ, không trừ điểm.
- [ ] Hai thiết bị redeem đồng thời không nhận cùng code và không overspend.
  Retry cùng idempotency key trả cùng redemption/code.
- [ ] `list_my_reward_redemptions` không trả raw code; chỉ owner lấy code qua
  `get_my_reward_code`. User B không đọc được code/giao dịch User A.
- [ ] Admin upsert từ chối title/description không phải tiếng Việt có dấu; import
  trả đúng accepted/duplicate/rejected và audit không chứa raw code. Cùng một
  `code_hash` xuất hiện ở offer khác vẫn là duplicate toàn cục và không được cấp.
- [ ] Admin hủy bắt buộc `external_revocation_confirmed = true`, reason và
  idempotency; code chuyển retired, không về kho, refund đúng một lần thành
  allocation available mới với expiry theo config hiện hành.
- [ ] Permission `wellness_rewards.read/write` được kiểm tra ở từng Admin RPC;
  mọi upsert/import/cancel đều có `admin_audit_events`.

## Membership va quota

- [ ] Seed co du plan `free`, `plus`, `family_plus`.
- [ ] User Free co quota `ai_chat_message` 3 luot/ngay.
- [ ] User Free co quota `personal_schedule_generation` 3 luot/thang.
- [ ] `check_usage_quota` tra `allowed = false` sau lan thu 3 cua
  `ai_chat_message` trong ngay theo `Asia/Ho_Chi_Minh`.
- [ ] `commit_usage_quota` idempotent theo `p_request_id`: goi lai cung
  request khong tang `usage_quota_counters` lan hai.
- [ ] `check_personal_schedule_generation_quota` va
  `commit_personal_schedule_generation_quota` khop voi Flutter schedule
  gateway, reset theo thang trong `Asia/Ho_Chi_Minh`.
- [ ] Client khong insert/update/delete duoc subscription, quota counter hay
  usage event.

## FamilyPlus

- [ ] Tao family group bang backend/Admin cho chu goi FamilyPlus.
- [ ] Member khong thuoc family khong doc duoc subject family.
- [ ] Member co `can_view = true` doc duoc data duoc chia se; thieu `can_edit`
  thi khong sua duoc.

## Sale direct-only

- [ ] User Free bi chan dang ky Sale; user Plus/FamilyPlus active gui yeu cau
  Sale thi trang thai la `pending`; chi sau khi Admin approve moi thanh
  `active` va co referral code.
- [ ] Gan quan he A gioi thieu B bang `attach_my_referral_code` trong luc dang
  ky tai khoan; self/email/phone/device trung, user da co relationship hoac
  payment history khong gan duoc trong app.
- [ ] Trusted payment recorder chi tao `pending`; chi sau khi Admin duyet thu
  cong payment moi thanh `succeeded`, kich hoat goi va bat dau giu diem 24h.
- [ ] Payment thanh cong cua B tao commission/diem 10% theo gia niem yet/base
  snapshot cho A o trang thai pending/hold; Sale chi quy doi duoc sau
  `available_at` 24h.
- [ ] Yeu cau quy doi diem bi tu choi khi diem van trong 24h hold hoac Sale
  chua co CCCD + thong tin tai khoan ngan hang.
- [ ] Hoan/huy/chargeback tao `sale_point_adjustments` am ngay, khong overwrite
  `commission_records`; so du Sale co the am va bu bang diem tuong lai.
- [ ] Admin queue quy doi hien thong tin payout, QR payload va co the luu path
  anh minh chung trong private bucket `sale-payout-proofs` khi mark paid.
- [ ] Cho B thanh Sale active, gan quan he B gioi thieu C; payment thanh cong
  cua C chi tao commission 10% cho B, khong tao commission cho A.
- [ ] Neu C la khach truc tiep cua B, payment cua C chi sinh commission cho B.
- [ ] Neu Sale bi `suspended` hoac `closed`, payment moi cua khach cu khong sinh
  commission/diem moi cho Sale do.
- [ ] Client khong insert/update/delete duoc `payment_events`,
  `commission_records`, `sale_profiles`, `referral_relationships`,
  `sale_point_conversions`, `sale_payout_profiles`.
- [ ] Khi `sale_point_conversion.enabled = false` hoac thieu config, Sale UI
  chi hien trang thai chua mo quy doi; khi bat config thi Sale tao duoc yeu cau
  quy doi va Admin co `sales.write` duyet qua RPC co audit.
- [ ] Sale UI doc cloud RPC truc tiep, khong luu payment/referral/commission
  trong SQLite.

## Admin

- [ ] `super_admin`, `finance_admin`, `support_admin`, `content_admin`,
  `operations_admin` deu la Admin active
  full capability qua RPC/backend co audit; Flutter khong ghi truc tiep bang
  server-only.
- [ ] Admin dashboard dung filter thoi gian `Asia/Ho_Chi_Minh` va metric co
  drill-down theo section.
- [ ] Finance Admin duyet/reject payment thanh cong, co reason/timestamp/actor
  va audit.
- [ ] Payment approval bat buoc thu cong; `record_trusted_payment_event` khong
  duoc grant cho Flutter roles va khong auto-approve.
- [ ] Admin dieu chinh thu cong Diem Sale qua RPC co reason/idempotency/audit;
  chi can mot Admin duyet.
- [ ] Admin tao/list/classify reconciliation discrepancy qua RPC; adjustment
  tao ledger rieng, khong overwrite lich su.
- [ ] Admin update Sale/user/config/report export deu ghi `admin_audit_events`.
- [ ] Flutter Admin khong co service-role key va khong ghi bang server-only truc
  tiep.

## Tieu chi hoan tat

- RLS khong lo du lieu cheo user/family.
- Bang server-only khong ghi duoc tu client.
- Trigger signup khong lam loi tao account trong sandbox.
- SQL seed chay lai duoc ma khong nhan ban du lieu.
- Khong claim production-ready neu chua co sandbox/staging verification.

## Auth V2 / M05 completion acceptance (2026-07-12)

Các mục dưới đây là gate bắt buộc trước khi đánh dấu production acceptance. Source/migration đã được cập nhật nhưng kết quả sandbox/device vẫn `PENDING` trong phiên này.

| ID | Kiểm tra | Kết quả mong đợi | Trạng thái |
| --- | --- | --- | --- |
| AUTH-M05-SBX-01 | Signup không referral | Tạo đúng một `auth.users`, một `public.users` và một self subject. | PENDING |
| AUTH-M05-SBX-02 | Signup referral hợp lệ | Referral active/direct-only được tạo cùng transaction, không cần attach sau signup. | PENDING |
| AUTH-M05-SBX-03 | Referral sai/inactive/collision | Toàn bộ signup rollback; không có auth user/profile/subject/referral mồ côi. | PENDING |
| AUTH-M05-SBX-04 | User A/User B và server-owned fields | RLS chặn đọc/ghi chéo; snapshot không sửa membership/Sale/Admin/server-owned fields. | PENDING |
| AUTH-M05-SBX-05 | Guest profile/meal/task/schedule/request ledger | Push/pull không mất hoặc nhân đôi; `personal_schedule_ai_requests` round-trip theo `request_id`. | PENDING |
| AUTH-M05-SBX-06 | Pending outbox/push lỗi | Không pull hoặc replace cache; local write và marker được giữ. | PENDING |
| AUTH-M05-SBX-07 | Pull lỗi/retry | Local cache được giữ; durable retry chạy lại idempotent khi connectivity/resume. | PENDING |
| AUTH-M05-SBX-08 | Sparse snapshot | Default/nullable columns hợp lệ, retry không nhân đôi dữ liệu. | PENDING |
| ADMIN-SBX-01 | Phiên hợp nhất và chọn giao diện | Một Supabase session được restore; user-only vào user UI, admin-only vào Admin UI, dual-role vào user UI và có thể chuyển hai chiều. | PENDING |
| ADMIN-SBX-02 | Role revoked/session expired | Role Admin bị thu hồi chuyển về user UI mà không sign-out nhầm; token hết hạn mới trở về auth gate. | PENDING |
| ADMIN-SBX-03 | `app_access_mode` | `admin` không hiện nút user UI; `both` hiện nút chuyển trong Cài đặt/Admin top bar; thay đổi mode có hiệu lực sau refresh auth/access. | PENDING |

- Chạy migration `15-auth-sync-completion.sql` và `17-unified-app-role-surface.sql` trên sandbox theo migration workflow.
- Không chạy `config.sql` trên remote/production; file này chỉ dành cho destructive rebuild local/sandbox.
- Ghi evidence không chứa token, UUID thật, email/phone thật hoặc dữ liệu sức khỏe nhạy cảm.
