# Báo cáo đối chiếu trước khi nhập dữ liệu self-hosted

## Phạm vi và trạng thái

- Ngày đối chiếu: 2026-10-30.
- Nguồn: snapshot Supabase live đã khôi phục trong PostgreSQL cô lập.
- Đích: PostgreSQL `nanobio` trên máy chủ NanoBio.
- Đây là báo cáo đối chiếu trước nhập; chưa có bản ghi nào được nhập hoặc cập nhật trên máy chủ.
- DB `nanobio_legacy` được giữ nguyên. DB `nanobio` đã có bản backup custom-format trước cutover; danh mục `pg_restore` được kiểm tra.
- Snapshot SQL đang nằm trong thư mục staging riêng, quyền hạn chế. Artifact mã hóa AES-256 chưa hoàn tất: GPG đã dừng, không có recipient key cục bộ và chưa có khóa khôi phục được chọn. Không ghi passphrase vào repository hoặc worklog, không dùng mật khẩu SSH làm khóa.

## Kết quả khôi phục và kiểm tra nguồn

- Restore thử thành công vào PostgreSQL 17 cô lập: 118 bảng thuộc schema `public`, `auth` và `storage`.
- Không có lỗi restore, FK mồ côi hoặc constraint chưa validate.
- Auth snapshot giữ UUID và identity cần thiết; các lệnh nhập Auth không xuất password hash, confirmation/recovery token, refresh/access token. Payload Auth cũng không có các key token/password này.
- Số dòng nguồn quan trọng: `users` 50, `auth.users` 50, `auth.identities` 50, `admin_user_roles` 1, `health_subjects` 50, `health_profiles` 31, `membership_subscriptions` 42, `sale_profiles` 1, `referral_codes` 1, `sleep_safety_contacts` 2, `sleep_safety_preferences` 7, `sleep_safety_sessions` 31, `sleep_safety_events` 35, `wellness_reward_wallets` 1.
- Storage có 3 object. Cả 3 đường dẫn, kích thước và SHA-256 trong bản export đều khớp với metadata đã restore.

## Đối chiếu với DB đích

| Dữ liệu | Supabase snapshot | `nanobio` hiện tại | Va chạm đã đo |
|---|---:|---:|---:|
| Users | 50 | 1 | 0 UUID, 0 phone, 0 email; snapshot không có phone/email trùng lặp nội bộ |
| Health subjects | 50 | 1 | 0 UUID |
| Admin user roles | 1 | 0 | Chưa có hàng đích; phải nhập role cùng user tương ứng |
| Membership subscriptions | 42 | 0 | Chưa có hàng đích |
| File objects | 3 Storage objects nguồn | 0 backend file objects | Cần map metadata và copy bytes sau khi API/storage migration sẵn sàng |

Không thấy va chạm định danh ở những tập đã so trực tiếp. Các bảng legacy khác chưa được đối chiếu theo khóa vì schema/API self-hosted chưa có đầy đủ bảng tương ứng; kết quả này không phải phê duyệt import toàn bộ.

## Blocker trước khi duyệt import/cutover

1. Schema đích đang ở Alembic `0001_initial`; migrations local `0002`-`0004` chưa được triển khai. Bảng wellness/reward và phần đầy đủ của sleep safety, sale/referral, Admin vẫn thiếu model/API hoặc chỉ có API một phần.
2. Mobile vẫn còn gọi Supabase trực tiếp cho một số Admin, wellness reward/rank, sale/referral và payout proof. Sleep safety owner sync đã có route trong checkout nhưng chưa deploy; Admin Web vẫn thiếu các thao tác sale/reconciliation/reward/dashboard.
3. Server hiện chỉ truy cập API công khai qua HTTP cổng 8080. Cổng 80 và 443 không mở được từ bên ngoài; chưa cấp được chứng chỉ IP tin cậy nên không chuyển client qua HTTPS.
4. Chưa có artifact `.sql.gpg` hoàn chỉnh; GPG đã dừng, không có recipient key cục bộ và chưa có khóa khôi phục được chọn. Snapshot và Storage bytes vẫn được giữ ở staging hạn chế quyền cho đến khi mã hóa hoàn tất.
5. Chưa có credential admin self-hosted được nhập an toàn. Chưa freeze ghi Supabase, chưa import dữ liệu và chưa chuyển app/Admin Web sang nguồn ghi mới.

## Quyết định

Chưa chạy import production. Cần hoàn thiện các contract còn thiếu, deploy migrations sau khi được duyệt, tạo artifact backup mã hóa, mở HTTPS tin cậy và lập lại đối chiếu cuối ngay trước write-freeze. Sau đó mới dùng báo cáo này cùng báo cáo cuối để duyệt nhập.
