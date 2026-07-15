# Implementation Delta — M03 nhiệm vụ hằng ngày và bằng chứng

| Thuộc tính | Giá trị |
|---|---|
| Module | M03 `DASHBOARD_SCHEDULE` |
| Trạng thái DD gốc | Approved — giữ nguyên |
| Nguồn bổ sung | `BD-BIOAI-WELLNESS-REWARDS-001` |
| Ngày | 2026-07-13 |
| Phạm vi | Cửa sổ 30 phút, camera proof, local/cloud completion và Điểm chăm sóc |

## 1. Delta nghiệp vụ được chấp nhận

- `start_time` được hiểu theo `Asia/Ho_Chi_Minh`; chỉ hoàn thành trong
  `[start_time, start_time + 30 phút]`. Ngày tương lai và mốc chưa mở chỉ xem;
  sau `window_end` khóa thao tác. Dữ liệu giờ lỗi khóa an toàn.
- Hoàn thành bắt buộc chụp trực tiếp bằng camera. Ảnh được chuẩn hóa JPEG,
  hướng xoay và metadata trước khi ghi; giới hạn 5 MB.
- Ảnh local nằm trong `schedule_proofs`, metadata sidecar nằm ngoài snapshot
  schedule. Hủy camera/lỗi quyền không thay đổi task.
- Gallery `Bằng chứng nhiệm vụ` giữ cả ảnh đã hoàn tác và ảnh không nhận điểm;
  có thể xem toàn màn hình, và client có contract tải lại cloud nếu local thiếu.
- Hoàn tác đến hết `window_end`, giữ ảnh và đảo khoản thưởng đang chờ.
- Guest/offline được hoàn thành local nhưng không nhận số dư đổi voucher.
- Member online đi qua một use case `begin` → camera/local → upload private →
  `finalize`; retry/reconcile phải idempotent.

## 2. Contract function, view và API

| ID delta | Contract |
|---|---|
| M03-DELTA-FN01 | `LifestyleScheduleWindowPolicy` parse ngày/giờ, tính trạng thái và mốc refresh theo cửa sổ đóng 30 phút. |
| M03-DELTA-FN02 | Controller hoàn thành dùng camera proof và một transaction local cho schedule, proof, linked meal/task và health-score projection. |
| M03-DELTA-FN03 | `ScheduleRewardOnlineGateway` đăng ký eligibility, begin, upload `upsert:false`, finalize, undo và reconcile attempt mất response. |
| M03-DELTA-V01 | Trang lịch hiển thị trạng thái `Chưa mở`, khả dụng, `Đã khóa`, cảnh báo Guest/offline và section proof ở cuối. |
| M03-DELTA-V02 | Route gallery proof hiển thị thumbnail, snapshot nhiệm vụ, capture time, proof/reward status và full-screen viewer. |

RPC server-authoritative:

- `register_my_schedule_reward_eligibilities`
- `begin_my_schedule_completion`
- `finalize_my_schedule_completion`
- `undo_my_schedule_completion`

Storage contract: bucket private `schedule-completion-proofs`, path do `begin`
trả về theo `<auth.uid>/<eligibility>/<attempt>.jpg`; client không update/delete.

## 3. Dữ liệu và implementation map

| Khu vực | Source-ready evidence |
|---|---|
| Time policy | `lib/app_versions/v1/features/lifestyle_schedule/domain/services/lifestyle_schedule_window_policy.dart` |
| Proof image | `lib/app_versions/v1/features/lifestyle_schedule/application/schedule_proof_image_service.dart` |
| Online flow | `lib/app_versions/v1/features/lifestyle_schedule/application/schedule_reward_online_gateway.dart` |
| Eligibility projection | `lib/app_versions/v1/features/lifestyle_schedule/application/schedule_reward_eligibility_projection_store.dart` |
| Local persistence | `schedule_completion_proofs` DAO/model/table, lifestyle datasource và SQLite migration v14 |
| UI/controller | lifestyle controller/page và `schedule_proof_gallery_page.dart` |
| Server contract | `docs/supabase/16-wellness-rewards.sql`, `docs/supabase/16-schedule-proof-storage.md`, `docs/supabase/config.sql` |

SQLite v14 bổ sung proof sidecar và reward projection/cache. Proof là local-owned
metadata, không được đẩy/xóa như snapshot schedule; wellness ledger cloud là
server-owned và client chỉ pull/merge read-only.

## 4. Bằng chứng kiểm tra hiện có

- Targeted analyze cho daily/proof: PASS.
- 59 test lifestyle/migration/notification/cloud-sync và 50 test dashboard
  bundle: PASS theo evidence của phiên triển khai.
- Test chuẩn hóa ảnh/EXIF: PASS.
- Reward client/gateway bundle 38/38: PASS; targeted analyze sạch.
- Supabase static contract bundle: 40 test PASS. `config.sql` rebuild đầy đủ trên
  PostgreSQL 18 tạm với Auth/Storage stub: PASS.
- Local backend smoke đã chạy chuỗi register → begin → upload → finalize → undo →
  refinalize → redeem → cancel; smoke RLS chéo người dùng và chặn direct ledger
  DML: PASS.

Đây là bằng chứng source/targeted/local PostgreSQL, không phải bằng chứng migration
16 đã deploy, bucket private đã tạo/kiểm tra runtime hoặc RLS/concurrency đã pass
trong một dự án Supabase sandbox thật.

## 5. Acceptance còn phải chạy trước production

- Apply migration 16 và `config.sql` vào local/sandbox với feature flag tắt.
- Smoke hai tài khoản cho owner path, MIME/size/upsert, direct DML rejection.
- Smoke exact `window_end`, upload trước hạn/finalize sau hạn, upload sau hạn,
  double tap, retry và hai thiết bị.
- Smoke camera/permission/resume trên thiết bị Android/iOS thật và cloud download
  khi file local bị thiếu.
- Bổ sung job xóa object proof khi xóa tài khoản, theo đúng chính sách lưu giữ.
