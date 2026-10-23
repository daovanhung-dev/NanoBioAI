# Đánh giá chuyển từ Supabase sang backend tự quản

| Thuộc tính | Kết quả |
| --- | --- |
| Ngày rà soát | 2026-10-23, `Asia/Ho_Chi_Minh` |
| Phạm vi | Flutter app, Admin Web, backend FastAPI/PostgreSQL và hợp đồng Supabase liên quan |
| Phương pháp | Đối chiếu tĩnh source, API mapping, migration và tài liệu vận hành |
| Kết luận cutover | **CHƯA SẴN SÀNG TẮT SUPABASE** |
| Runtime/server thật | Chưa xác minh trong lần rà soát này |

## Kết luận

Backend tự quản đã có nền tảng FastAPI, PostgreSQL, auth riêng, một số API và migration schema. Tuy vậy, đây mới là **backend foundation**, chưa phải một bản thay thế đầu-cuối cho Supabase. Flutter và Admin Web vẫn gọi Supabase trực tiếp; dữ liệu và tài khoản Supabase chưa được nhập; một số luồng app gọi RPC hoặc Storage chưa có API thay thế; API đồng bộ dữ liệu của backend cũng khác giao thức app đang dùng.

Nếu ngừng Supabase ở trạng thái source hiện tại, phần app khách và các xử lý AI chạy cục bộ có thể tiếp tục hoạt động, nhưng đăng nhập/tài khoản, đồng bộ cloud, quota AI/lịch tập, membership, rewards, Sale, Admin và một số thao tác tệp sẽ lỗi hoặc mất dữ liệu cloud. Đây là suy luận từ wiring hiện tại; không có kiểm thử runtime trong lần rà soát này.

## Phát hiện có thể ảnh hưởng hoạt động

### F-01 — Blocker: Client chưa chuyển sang API backend

`lib/main.dart` vẫn nạp cấu hình và khởi tạo Supabase; auth provider tạo `SupabaseAuthRemoteDatasource`. Không tìm thấy cấu hình hoặc lời gọi `/api/v1` trong `lib/`. Admin Web vẫn yêu cầu `VITE_SUPABASE_URL` và `VITE_SUPABASE_ANON_KEY`, tạo Supabase client, rồi gọi RPC/Edge Functions trực tiếp.

**Ảnh hưởng:** Tắt Supabase sẽ làm đăng nhập, đăng ký, xác thực phiên, các thao tác quản trị và mọi chức năng vẫn dựa trên PostgREST/RPC/Storage không thể kết nối backend mới. Chỉ đổi địa chỉ server không đủ vì chưa có client adapter.

**Bằng chứng:** [`main.dart`](../../lib/main.dart#L59-L60), [`auth_dependencies.dart`](../../lib/app_versions/v2/features/auth/providers/auth_dependencies.dart#L15-L25), [`supabase_auth_remote_datasource.dart`](../../lib/app_versions/v2/features/auth/data/datasources/supabase_auth_remote_datasource.dart#L68-L110), [`admin-web config`](../../admin-web/src/lib/config.ts#L13-L28), [`admin-api.ts`](../../admin-web/src/lib/admin-api.ts#L553-L568).

### F-02 — Blocker: Tài khoản và dữ liệu hiện hữu chưa được chuyển

Tài liệu backend xác nhận giai đoạn này không nhập tài khoản hoặc dữ liệu Supabase; tài khoản Supabase hiện hữu chưa thể đăng nhập vào auth mới nếu chưa có một đợt migration riêng. Không có source importer dữ liệu Supabase trong `backend/scripts/`; hiện có script backup PostgreSQL và kiểm tra context.

Auth backend là phone/password và phát hành JWT riêng, trong khi Flutter hiện dùng Supabase Auth session. Vì vậy, kể cả khi API đã chạy, tài khoản, liên kết user ID, hồ sơ, membership, health subjects, lịch sử cloud và quyền hiện tại vẫn chưa tự xuất hiện ở database mới.

**Ảnh hưởng:** Người dùng hiện tại có nguy cơ không đăng nhập được hoặc thấy tài khoản/dữ liệu/quyền lợi trống sau cutover.

**Bằng chứng:** [`01-product-context.md`](../../backend/.agents/project/01-product-context.md#L6-L9), [`backend README`](../../backend/README.md#L17-L18), [`auth backend decisions`](../../backend/.agents/project/13-decisions.md#L5-L11), [`backup_postgres.sh`](../../backend/scripts/backup_postgres.sh), [`validate_agent_context.py`](../../backend/scripts/validate_agent_context.py).

### F-03 — High: API cloud sync chưa tương thích giao thức app

Flutter hiện đọc hồ sơ `users`, tải từng bảng cloud riêng, rồi ghi dữ liệu qua RPC `sync_my_mobile_snapshot`. Backend nhận `PUT /cloud-sync/snapshot` với `{snapshot, expected_revision}` và lưu một JSON snapshot có allowlist. Contract backend ghi rõ chưa thay thế subject, reward eligibility và các quan hệ/side effect của RPC cũ.

**Ảnh hưởng:** Client hiện tại không thể dùng endpoint backend bằng cách đổi URL. Nếu đồng bộ chỉ ghi JSON snapshot, các luồng cần cập nhật bảng quan hệ hoặc hiệu ứng nghiệp vụ có thể không được khôi phục đầy đủ.

**Bằng chứng:** [`Supabase sync datasource`](../../lib/app_versions/v2/features/cloud_sync/data/datasources/supabase_user_data_sync_remote_datasource.dart#L30-L90), [`backend cloud sync router`](../../backend/src/nanobio_backend/modules/cloud_sync/router.py#L16-L37), [`backend RPC mapping`](../../backend/contracts/supabase-rpc-mapping.md#L46-L46).

### F-04 — High: Quota AI/lịch vẫn gọi Supabase và thiếu trong backend

Các gateway Flutter gọi `check_usage_quota`, `commit_usage_quota`, `check_personal_schedule_generation_quota` và `commit_personal_schedule_generation_quota` qua Supabase. Backend không có module/router quota và các RPC này không có trong bảng 38 app RPC của `supabase-rpc-mapping.md`, dù được định nghĩa trong SQL Supabase.

**Ảnh hưởng:** Khi Supabase tắt, chat AI cần kiểm tra/ghi quota sẽ báo quota service không khả dụng; tạo lịch thành viên và chương trình tập cũng dừng ở bước kiểm tra hoặc commit quota. AI inference chạy cục bộ không loại bỏ phụ thuộc quota này.

**Bằng chứng:** [`usage_quota_gateway.dart`](../../lib/services/supabase/usage_quota/usage_quota_gateway.dart#L183-L195), [`personal_schedule_quota_gateway.dart`](../../lib/app_versions/v1/services/ai/personal_schedule_quota_gateway.dart#L60-L103), [`AI chat repository`](../../lib/app_versions/v1/features/ai_chat/domain/repositories/ai_chat_repository_impl.dart#L31-L51), [`generated_plan_service.dart`](../../lib/app_versions/v1/services/ai/generated_plan_service.dart#L573-L603), [`canonical quota SQL`](../../docs/supabase/01_build_system.sql#L1985-L1997), [`API router modules`](../../backend/src/nanobio_backend/api/v1/router.py#L1-L26).

### F-05 — High: Schedule reward RPC và proof storage chưa có thay thế

App dùng RPC `register_my_schedule_reward_eligibilities`, `begin_my_schedule_completion`, `finalize_my_schedule_completion`, `undo_my_schedule_completion`, `finalize_my_schedule_health_checkin` và `undo_my_schedule_health_checkin`; ảnh proof được tải lên bucket `schedule-completion-proofs`. Các luồng này không xuất hiện trong RPC mapping hoặc router backend. Storage backend hiện chỉ cho phép bucket `sale-payout-proofs`.

**Ảnh hưởng:** Hoàn tất lịch có xác minh, check-in sức khỏe có thưởng, tải/xem proof và ghi nhận điểm thưởng sẽ không có đường thay thế tương đương khi Supabase ngừng hoạt động.

**Bằng chứng:** [`schedule reward gateway`](../../lib/app_versions/v1/features/lifestyle_schedule/application/schedule_reward_online_gateway.dart#L245-L282), [`proof upload/download`](../../lib/app_versions/v1/features/lifestyle_schedule/application/schedule_reward_online_gateway.dart#L302-L377), [`health check-in RPC`](../../lib/app_versions/v1/features/lifestyle_schedule/application/schedule_health_checkin_reward_gateway.dart#L53-L84), [`backend storage allowlist`](../../backend/src/nanobio_backend/modules/storage/view.py#L13-L21), [`backend RPC mapping`](../../backend/contracts/supabase-rpc-mapping.md#L9-L50).

### F-06 — High: Membership, Sale/rewards và Admin còn thiếu hoặc chỉ port một phần

Trong 38 RPC được liệt kê: 22 được đánh dấu `NOT_YET_PORTED`, 6 `PARTIAL`, 10 `DONE` theo phạm vi contract ghi trong bảng. Sale và wellness rewards có nhiều RPC chưa port; một số API membership/access chỉ chiếu entitlement cục bộ; Admin Web còn nhiều thao tác chưa có endpoint và vẫn dùng Supabase Auth/RPC. Bảng mapping còn bỏ sót các quota và schedule reward RPC đang được app gọi, nên 38 không phải danh sách đầy đủ mọi lời gọi hiện hành.

**Ảnh hưởng:** Referral/Sale, điểm và đổi thưởng, một số tác vụ Admin, quyền lợi legacy/anonymous, và dữ liệu thanh toán cũ không được đảm bảo hoạt động như trước. Không nên coi API có cùng tên nghiệp vụ là đã tương đương nếu mapping ghi `PARTIAL`.

**Bằng chứng:** [`RPC mapping — app`](../../backend/contracts/supabase-rpc-mapping.md#L9-L50), [`RPC mapping — Admin Web`](../../backend/contracts/supabase-rpc-mapping.md#L52-L76), [`membership/access mapping`](../../backend/contracts/supabase-rpc-mapping.md#L78-L87), [`Admin Web auth`](../../admin-web/src/auth/AuthProvider.tsx#L21-L40).

### F-07 — High: Backend chưa được triển khai và xác minh vận hành trên server thật

README nói rõ các bước Ubuntu/systemd là hướng dẫn, chưa chạy trên server. Chưa có bằng chứng trong phạm vi rà soát này về domain/TLS, cấu hình môi trường production, migration database production, health check, backup/restore hoặc kết nối client tới host mới.

**Ảnh hưởng:** Dù source backend có thể chạy ở môi trường local, chưa thể kết luận dịch vụ production sẵn sàng nhận traffic hoặc có thể khôi phục khi sự cố.

**Bằng chứng:** [`backend README — deployment`](../../backend/README.md#L19-L63), [`Ubuntu operations context`](../../backend/.agents/project/11-devops-operations.md#L1-L5).

## Điều không được xem là blocker độc lập

Các endpoint backend `/ai/generate` và `/food/scan/analyze` trả `503 FEATURE_NOT_ENABLED` theo quyết định thiết kế. Vì AI inference hiện chạy trên thiết bị, riêng hai endpoint này không chứng minh chức năng AI local bị hỏng. Tuy nhiên, quota AI còn phụ thuộc Supabase như F-04.

README nói mọi JSON response dùng envelope chung, nhưng hai health endpoint hiện trả object đơn giản `{status: ...}` và `{status: ..., database: ...}`. Đây là lệch tài liệu ở health check, mức thấp và không phải blocker cutover nếu monitoring chỉ kiểm tra HTTP/status; nên ghi ngoại lệ hoặc đồng nhất hợp đồng trước khi client phụ thuộc vào envelope.

**Bằng chứng:** [`backend README`](../../backend/README.md#L75-L80), [`main.py health endpoints`](../../backend/src/nanobio_backend/main.py#L50-L61).

## Phạm vi xác minh

Đây là rà soát source và hợp đồng ở trạng thái worktree ngày 2026-10-23. Không chạy test/build, không kết nối Supabase/PostgreSQL production, không triển khai backend và không kiểm tra UI trên thiết bị. Kết quả xác nhận **mức độ chưa hoàn tất cutover từ source**, không xác nhận tình trạng hoạt động hiện tại của server production.

## Tiêu chí tối thiểu trước khi tắt Supabase

1. Chuyển Flutter và Admin Web sang API backend, gồm auth/session/token refresh, lỗi mạng, retry và logout.
2. Chốt và thực hiện kế hoạch nhập tài khoản, hồ sơ, membership, health subjects, cloud data, lịch sử thanh toán cần giữ, cùng Storage object; có đối soát số lượng và quy tắc đặt lại mật khẩu.
3. Port các quota, schedule reward/check-in, proof storage và các RPC cần cho scope release; hoàn thiện contract mapping để bao phủ toàn bộ lời gọi thực tế.
4. Kiểm tra payload/response giữa client và API, ownership/RBAC, idempotency, đồng thời chứng minh app flow chính chạy trên backend mới.
5. Triển khai PostgreSQL/backend có TLS, secrets, migrations, monitoring, backup và restore drill; chỉ cutover sau khi có kết quả staging và phương án rollback.
