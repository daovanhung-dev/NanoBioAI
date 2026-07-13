Commit de xuat: feat(wellness): hoan thien nhiem vu bang chung diem va voucher

# Worklog - Nhiệm vụ hằng ngày, bằng chứng, Điểm chăm sóc, voucher và Việt hóa

## Thoi gian

- Ngay: 2026-07-13
- Bat dau: trong phiên coding 2026-07-13
- Ket thuc: đang chờ root hoàn tất full validation
- Timezone: Asia/Saigon (UTC+07:00)

## Pham vi

- Loai task: coding/test/docs
- Module chinh: M03 DASHBOARD_SCHEDULE, M08 HEALTH_SCORE_HABITS, M09 SCHEDULE_NOTIFICATIONS, M15 ADMIN_DASHBOARD, M16 ADMIN_OPS; localization V1/V2/V3/Sale/Admin.
- Yeu cau goc: chỉ cho làm nhiệm vụ trong cửa sổ 30 phút, bắt buộc camera proof private, cộng `+10 Điểm chăm sóc` đồng bộ local/Supabase, catalog/voucher/Admin đầy đủ và Việt hóa toàn bộ production UI.

## Da lam

- Chuẩn hóa cửa sổ `[start_time, start_time + 30 phút)` theo
  `Asia/Ho_Chi_Minh`, parser fail-closed, trạng thái tương lai/chưa mở/đã khóa,
  auto refresh/resume và một completion use case dùng chung.
- Bắt buộc chụp camera; chuẩn hóa JPEG/orientation/EXIF, giới hạn 5 MB, lưu file
  app-private `schedule_proofs`, metadata sidecar SQLite và gallery proof với
  trạng thái hiệu lực/hoàn tác/không nhận điểm.
- Nâng SQLite lên v14 cho proof, eligibility/reward projection, catalog,
  redemption và sync cache; wellness ledger server-owned không được snapshot
  client push/delete. Mã voucher rõ được giữ trong secure storage, không lưu ở
  SQLite cache.
- Bổ sung online eligibility và completion flow `register/begin/upload/finalize/
  undo`, attempt reconciler và exact-item dashboard/notification deep-link.
  Guest/offline vẫn lưu completion/proof local nhưng không nhận điểm đổi voucher.
- Bổ sung migration 16 source cho private Storage/RLS, eligibility/attempt/proof,
  wallet/ledger/allocation, versioned `+10`/180 ngày, FEFO, offer/inventory/
  redemption, user/Admin RPC, append-only/revoke direct DML, audit và rollout
  feature flag mặc định tắt; đồng bộ `config.sql` và runbook/acceptance docs.
- Schema server gồm `schedule_reward_eligibilities`,
  `schedule_completion_attempts`, `schedule_completion_proofs`,
  `wellness_reward_wallets`, `wellness_point_ledgers`,
  `wellness_point_allocations`, catalog/code/redemption/allocation usage; audit
  không ghi mã voucher rõ. Private bucket dùng path
  `<uid>/<eligibility>/<attempt>.jpg`, JPEG tối đa 5 MB và không cho client
  update/delete.
- Bổ sung trang người dùng `Điểm chăm sóc và ưu đãi`: summary, catalog, lịch sử,
  đổi điểm atomic, voucher text/QR và secure code cache/fallback.
- Bổ sung Admin section/route/permissions `wellness_rewards.read/write`, catalog
  upsert, import mã, tồn kho/giao dịch và cancel/refund có lý do/xác nhận/audit.
- Thêm `gen-l10n`, ARB/delegates/locale `vi_VN`, normalize preference `en` →
  `vi`, copy quyền camera/thư viện và mapper/fallback/scanner tiếng Việt cho các
  bề mặt production do NanoBio kiểm soát.
- Tạo `BD-BIOAI-WELLNESS-REWARDS-001`, cập nhật DD Approved M03/M08/M09/M15/M16
  bằng implementation delta, checklist coding/evidence và risk rollout.

## File code/docs da sua

- `lib/app_versions/v1/features/lifestyle_schedule/` - sửa/tạo - time policy,
  camera proof, persistence, gallery, online reward gateway và controller/UI.
- `lib/app_versions/v1/services/notifications/` - sửa/tạo - `Mở để chụp ảnh`,
  payload validation và navigation coordinator.
- `lib/core/storage/localdb/` - sửa/tạo - SQLite v14, proof và wellness cache.
- `lib/app_versions/v2/features/wellness_rewards/` - tạo - user reward feature.
- `lib/app_versions/admin/features/wellness_rewards/` và Admin panel/router -
  tạo/sửa - quản trị catalog, inventory và redemption.
- `lib/core/localization/`, `lib/l10n/`, app roots/settings/native permission
  config - tạo/sửa - Việt hóa production.
- `docs/supabase/16-wellness-rewards.sql`,
  `docs/supabase/16-schedule-proof-storage.md`, `docs/supabase/config.sql` và
  RLS/acceptance docs - tạo/sửa - server-authoritative contract và runbook.
- `test/features/lifestyle_schedule/`, `test/services/notifications/`,
  `test/app_versions/v2/features/wellness_rewards/`,
  `test/app_versions/admin/features/wellness_rewards/`, localization/contracts,
  migration/cloud-sync tests - tạo/sửa - targeted regression/contract coverage.
- `docs/BD/wellness_rewards/BD_BioAI_Daily_Proof_Wellness_Rewards_v1.0.md` - tạo
  - business source Approved cho delta.
- `docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md` - sửa - liên
  kết addendum ưu tiên cho phạm vi mới.
- `docs/DD/{dashboard_schedule,health_score_habits,schedule_notifications,admin_dashboard,admin_operations}/` - sửa/tạo - link, changelog và implementation delta, giữ trạng thái Approved.
- `docs/DD/README.md` - sửa - route Approved addendum và năm implementation delta.
- `docs/checklist/checklist_complete_DD.md` và
  `docs/checklist/checklist_task_coding.md` - sửa - evidence mới và rollout gate.
- `.codex/history/OPEN_RISKS.md` - sửa - ghi migration 16/Storage/RLS/feature flag
  là P1 cần verification.

## Tai lieu lien quan

- `docs/BD/wellness_rewards/BD_BioAI_Daily_Proof_Wellness_Rewards_v1.0.md`
- `docs/DD/dashboard_schedule/Implementation_Delta_2026-07-13.md`
- `docs/DD/health_score_habits/Implementation_Delta_2026-07-13.md`
- `docs/DD/schedule_notifications/Implementation_Delta_2026-07-13.md`
- `docs/DD/admin_dashboard/Implementation_Delta_2026-07-13.md`
- `docs/DD/admin_operations/Implementation_Delta_2026-07-13.md`
- `docs/supabase/16-schedule-proof-storage.md`

## Commands

- `flutter pub get`: PASS - localization implementation agent reported success.
- Targeted daily/proof analyze: PASS.
- 59 lifestyle/migration/notification/cloud-sync tests: PASS.
- 50 dashboard bundle tests: PASS.
- Proof JPEG/orientation/EXIF tests: PASS.
- 96 targeted localization tests: PASS.
- 54 localization/settings/image tests: PASS; targeted analyze and Vietnamese UI contract scan PASS.
- 38/38 reward user/Admin/cache/secure-store/gateway tests: PASS; targeted analyze PASS.
- 40 Supabase static contract tests: PASS.
- Full `config.sql` rebuild trên PostgreSQL 18 tạm với Auth/Storage stub: PASS.
- Local end-to-end backend smoke register → begin → upload → finalize → undo →
  refinalize → redeem → cancel: PASS; cross-user RLS và direct-ledger rejection
  smoke: PASS.
- Full `flutter analyze` / full `flutter test`: chưa ghi PASS tại thời điểm tạo worklog; root đang chạy validation cuối.
- Supabase migration 16/RLS/Storage smoke trên dự án sandbox thật: SKIPPED - chưa deploy sandbox; local PostgreSQL evidence ở trên không thay thế bước này.
- Targeted link/source checks cho BD addendum, năm DD delta, checklist và risk:
  PASS.
- `.codex/tools/validate_codex_integrity.ps1`: PASS.
- `git diff --check` toàn worktree và scoped docs/history: PASS; chỉ có cảnh báo
  line-ending LF/CRLF, không có whitespace error.

## Loi/Rui ro

- Da fix: legacy completion path bỏ qua camera/time/reward đã được gom vào use
  case; reward code không còn được cache plaintext trong SQLite; permission/error
  code có mapper/fallback tiếng Việt; direct client ledger/inventory contract bị
  revoke trong migration source.
- Chua fix: chưa có bằng chứng migration 16, private bucket runtime, RLS, row-lock,
  concurrency, FEFO/expiry, inventory và cancel/refund đã chạy trong dự án
  Supabase sandbox thật; chưa có job xóa object proof khi xóa tài khoản.
- Can kiem tra tiep: giữ `wellness_rewards_rollout.enabled = false`; apply migration
  16/config; smoke hai user/two-device/real-device camera-notification; nhập catalog
  và mã thử; bổ sung/kiểm tra account-deletion cleanup; chỉ bật flag sau
  acceptance. Theo dõi `NB-RISK-001` và `NB-RISK-003`.

## Ty le hoan thanh

- Hoan thanh: source implementation, targeted tests/analyze đã báo, BD/DD/
  checklist/risk/worklog cho phạm vi coding.
- Dang do: full repo validation của root; Supabase sandbox/RLS/Storage và
  real-device/rollout production evidence.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tốt - business delta, source map, test evidence và release
  risk được tách rõ; không đổi sai trạng thái DD Approved và không claim sandbox.
- Muc do hoan thanh task: source-ready cao; production acceptance còn phụ thuộc
  sandbox/private Storage/RLS/concurrency và thiết bị thật.
- Bang chung kiem chung: các bundle targeted nêu ở Commands; integrity/diff check
  được chạy ở cuối docs subtask; full Flutter do root cập nhật khi hoàn tất.
- Diem ton token/chua toi uu: phạm vi cross-module rộng và DD baseline generic
  buộc đối chiếu năm module; lần sau nên đọc implementation delta trước DD raw.
- Cach toi uu cho phien sau: dùng addendum + delta files làm router, chạy sandbox
  acceptance theo ma trận trước rồi cập nhật risk/checklist bằng evidence ngắn.
- Task-skill can doc lan sau: `.codex/task-skills/coding.md`
