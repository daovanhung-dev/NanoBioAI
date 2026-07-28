# Runbook Storage bằng chứng nhiệm vụ và Điểm chăm sóc

Migration tham chiếu: `16-wellness-rewards.sql`.

## Phạm vi

- Bucket `schedule-completion-proofs` là private, giới hạn `5 MB` và chỉ nhận
  `image/jpeg`.
- Client chỉ được `INSERT` đúng object path do
  `begin_my_schedule_completion` cấp và chỉ được `SELECT` object của chính
  mình. Không có policy `UPDATE` hoặc `DELETE`, vì vậy phải upload với
  `upsert: false`.
- Object path bất biến có dạng
  `<auth.uid>/<eligibility_id>/<attempt_id>.jpg`. Không tự ghép path ở client;
  luôn dùng trường `storage_path` từ RPC begin.
- Thời điểm `storage.objects.created_at` là bằng chứng thời gian phía server.
  `finalize_my_schedule_completion` chỉ thưởng khi object được tạo trong cửa
  sổ `[window_start, window_end]`, đúng MIME và kích thước.
- Ảnh được giữ đến khi xóa tài khoản. Không tạo nút xóa ảnh riêng và không cấp
  signed URL công khai. Khi cần xem ảnh, client đăng nhập đọc object qua SDK;
  RLS vẫn áp dụng cho mỗi request.

## Thứ tự triển khai

1. Chạy migration 16 trong local/sandbox bằng vai trò có quyền tạo policy trên
   `storage.objects`; không chạy `config.sql` trên remote.
2. Xác nhận bucket vẫn `public = false`, `file_size_limit = 5242880` và
   `allowed_mime_types = {image/jpeg}`.
3. Giữ `wellness_rewards_rollout.enabled = false` trong lúc kiểm thử RLS/RPC.
4. Tạo một offer thử nghiệm bằng Admin RPC, nhập mã thử và chạy smoke test với
   hai tài khoản khác nhau.
5. Sau khi toàn bộ acceptance check đạt, tạo version mới cho
   `wellness_rewards_rollout` bằng Admin config RPC với `enabled = true`.
   Không sửa trực tiếp version cũ.

## Hai giai doan local/sandbox

1. `config.sql` fold migration 16 va fixture canonical 19 de tao database/RLS
   review. Du lieu seed khong phai la anh da upload va khong thay the
   `storage.objects`; rollout mac dinh van tat.
2. Tren local/sandbox tach rieng, xac nhan case rollout tat truoc, sau do tao
   version rollout bat qua Admin workflow de smoke test begin/upload/finalize
   bang JPEG gia lap moi. Kiem tra RLS bang it nhat hai tai khoan; reset
   disposable environment de don dep evidence immutable, va khong dua
   object/path sang staging dung chung hay production.

## Runner fixture canonical

Voi fixture 19, dung `20-dev-sandbox-demo-profile.sql` de bat rollout demo,
sau do chay `tools/supabase/Seed-StorageFixtures.ps1` **ngay sau destructive
rebuild**. Runner dang nhap persona Wellness/Admin that, dung RPC
begin/upload/finalize/undo va Storage API; khong chen `storage.objects` bang
SQL.

- Runner la **one-shot cho moi rebuild**: proof va allocation la evidence bat
  bien. Neu runner bi loi hoac can chay lai, chay lai `config.sql`, ap dung
  profile demo, roi chay runner tu dau; khong ap dung rieng module 19 de reset
  trang thai da co proof.
- Hai eligibility mo chi co cua so 30 phut theo schema. Runner giu lai toi
  thieu hai phut de finalize/undo, vi vay hay chay trong khoang 27 phut sau
  rebuild/profile; neu qua han no se tu choi thay vi tao evidence khong hop le.
- Cung cap `NANOBIO_SUPABASE_URL`, `NANOBIO_SUPABASE_ANON_KEY` va
  `NANOBIO_SUPABASE_SERVICE_ROLE_KEY` qua environment. Runner chi tu dong
  chap nhan loopback, `.local` hoac hostname co nhan `sandbox`; staging can
  `-AllowNonLocal` ro rang va chi duoc dung neu da xac nhan moi truong
  disposable, khong phai shared staging.
- Khi muon truyen `SecureString`, goi script trong **cung PowerShell session**;
  hoac bo tham so de script prompt password. Khong truyen `SecureString` qua
  mot process `powershell -File` moi.

Khong chen truc tiep metadata proof hay object gia lap de coi nhu bang chung.
Chi path do `begin_my_schedule_completion` cap va object upload dung session
moi co the duoc dung cho `finalize_my_schedule_completion`.

## Contract client

```text
register_my_schedule_reward_eligibilities(
  p_request_id,
  p_items,              -- JSON array; mỗi dòng có schedule_item_id hoặc id
  p_idempotency_key
)

begin_my_schedule_completion(p_schedule_item_id, p_idempotency_key)
-> eligibility_id, attempt_id, storage_path, window_end,
   bucket_id, content_type, max_bytes

Storage.upload(storage_path, jpegBytes, upsert: false)

finalize_my_schedule_completion(
  p_attempt_id,
  p_storage_path,
  p_idempotency_key
)
-> proof_id, reward_status, points_delta = 10,
   available_at, expires_at, pending_points, available_points

undo_my_schedule_completion(p_schedule_item_id, p_idempotency_key)
-> proof_status = reversed, reward_status = reversed, points_delta = -10
```

Với request `member_new`, manifest phải bao phủ toàn bộ plan `days * 10` và có
quota commit hợp lệ; marker server-owned ghim một registration identity và
canonical full manifest nên key thứ hai không thể bổ sung eligibility. Với
request `initial_guest` sau đăng nhập, server ghim duy nhất một request Guest
cho tài khoản, kiểm tra cấu trúc toàn plan 10 mốc/ngày, nhưng cho phép manifest
là tập con item AI chưa hoàn thành còn ở tương lai tại thời điểm ghim. Canonical
hash gồm ID, ngày, giờ, title/category/source; sửa row cùng UUID giữa các batch
cũng bị từ chối. Batch sau vẫn phải dùng đúng request và eligible-item set đã
ghim; request Guest thứ hai bị từ chối.
Các stable code riêng của nhánh này là
`guest_schedule_request_ambiguous`,
`guest_schedule_request_already_registered`,
`guest_schedule_request_changed`,
`guest_schedule_request_claimed` và `guest_schedule_plan_invalid`.

`finalize` có thể được retry sau `window_end` nếu object đã được Storage ghi
trước hạn. Object tải lên lần đầu sau hạn không được thưởng. Server chỉ xác
nhận sự tồn tại, quyền sở hữu, định dạng, kích thước và thời gian upload; việc
đánh giá nội dung ảnh cần một quy trình kiểm duyệt riêng nếu sản phẩm bổ sung
sau này.

## Kiểm tra RLS tối thiểu

- User A begin được attempt A và upload đúng `storage_path` A.
- User A không upload được path tự chọn, path của User B, MIME khác JPEG, file
  quá 5 MB hoặc ghi đè object A.
- User B không select object A dù biết đầy đủ path.
- User A không update/delete object A qua client.
- Finalize với path khác path begin trả `storage_path_mismatch`.
- Finalize trước upload trả `proof_not_uploaded`; upload sau hạn trả
  `proof_upload_outside_window`.
- Xóa tài khoản bằng trusted account-deletion flow phải xóa metadata nghiệp vụ
  theo cascade và dọn object Storage tương ứng bằng service-role job.

## Vận hành và cảnh báo

- Theo dõi tỷ lệ `proof_not_uploaded`, `proof_upload_outside_window`,
  `storage_path_mismatch`, retry finalize và chênh lệch wallet/allocation.
- Không ghi raw voucher code, object URL hoặc ảnh vào audit/log. Audit nhập kho
  chỉ lưu số lượng accepted/duplicate/rejected.
- Nếu cần bảo trì ledger, chỉ trusted SQL session được đặt
  `set local nanobio.wellness_ledger_maintenance = 'on'`; không đặt GUC này từ
  client hoặc Edge Function không được kiểm soát.
