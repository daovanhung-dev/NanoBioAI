Commit đề xuất: feat(admin-web): hiển thị và điều chỉnh thời hạn gói

# Worklog - Admin Web membership period

## Thời gian

- Ngày: 2026-09-13
- Bắt đầu: 20:00
- Kết thúc: đang hoàn thiện validation
- Timezone: Asia/Ho_Chi_Minh (UTC+07:00)

## Phạm vi

- Loại task: Implement feature trên Admin Web và trusted Supabase backend.
- Module chính: M16 `ADMIN_OPS`, membership administration.
- Yêu cầu gốc: hiển thị start/end; Super Admin chỉnh manual subscription bằng
  cộng/trừ ngày hoặc set ngày kết thúc; giữ nguyên Flutter Admin cũ, bulk
  provisioning, payment provider và Google Play.

## Đã làm

- Mở rộng `admin_search_users` với plan hiện hành và membership summary gồm
  subscription ID, status, source, start/end; sửa mapper TypeScript và hiển thị
  cột `Thời hạn` theo `Asia/Ho_Chi_Minh`.
- Bổ sung `subscriptionId` vào chi tiết user và hiển thị plan/source/start/end
  trong drawer; gói paid không có `ends_at` hiển thị `Không thời hạn`.
- Bổ sung lựa chọn `Tùy chỉnh` với `datetime-local` vào form cấp gói; parse giờ
  Việt Nam và lưu UTC, vẫn giữ reason bắt buộc và bước xác nhận hiện có.
- Bổ sung form `Chỉnh thời hạn` với add/subtract/set-end, validation, preview,
  cảnh báo hết hạn ngay và không optimistic success.
- Tạo `admin_adjust_membership_period` trong canonical SQL: Super Admin
  active, manual/current-only, user/subscription ownership, `FOR UPDATE`,
  expected end chống stale, permanent-package guard, expiry-now, đồng bộ
  `current_period_end`, trigger access sync, audit before/after và idempotency.
- Tạo Edge Function `admin-adjust-membership-period` với JWT validation,
  Super Admin guard, service-role RPC boundary, response/error an toàn và
  `verify_jwt = true`.
- Bổ sung unit/contract tests, Supabase README, feature doc, DD Admin Ops và
  checklist M16.

## File code/docs đã sửa

- `admin-web/src/pages/AccountsPage.tsx` - UI cột thời hạn, drawer action,
  custom grant và adjustment modal.
- `admin-web/src/types.ts` - membership summary, input/result và permission
  helper.
- `admin-web/src/lib/admin-api.ts` - API adapter Edge Function và detail mapper.
- `admin-web/src/lib/labels.ts` - status/audit labels và timezone helpers.
- `admin-web/src/lib/membership-period.ts` - pure validation/preview helpers.
- `admin-web/src/lib/membership-period.test.ts` - form validation/payload tests.
- `admin-web/src/types.test.ts`, `admin-web/src/lib/admin-api.test.ts` - mapper,
  permission, timezone và API contract tests.
- `admin-web/src/components/Ui.tsx`, `admin-web/src/styles.css` - expired badge,
  table/action layout.
- `docs/supabase/01_build_system.sql` - search RPC và adjustment RPC.
- `supabase/functions/admin-adjust-membership-period/{handler.ts,index.ts}` -
  protected Edge Function và handler tests.
- `supabase/functions/admin-user-management/index.ts` - trả subscription ID.
- `supabase/config.toml` - bật `verify_jwt` cho function mới.
- `test/docs/{supabase_admin_contract_test.dart,supabase_config_contract_test.dart,admin_edge_functions_contract_test.dart}` - SQL/config/Edge contract.
- `docs/features/admin-membership-period/001-feature-admin-membership-period.md` -
  feature contract và rollout boundary.
- `docs/DD/admin_operations/README.md`,
  `docs/checklist/checklist_complete_DD.md`,
  `docs/checklist/checklist_task_coding.md` - cập nhật evidence M16.

## Tài liệu liên quan

- `.codex/workflows/coding.md`
- `.codex/task-skills/coding.md`
- `.codex/domains/access-membership-referral.md`
- `docs/supabase/README.md`
- `docs/DD/admin_operations/README.md`
- `docs/features/admin-membership-period/001-feature-admin-membership-period.md`

## Commands

- `PATH=/home/daovanhung/.local/node-v24.21.0-linux-x64/bin:$PATH npm test`:
  PASS - 27/27 Admin Web tests.
- `PATH=/home/daovanhung/.local/node-v24.21.0-linux-x64/bin:$PATH npm run typecheck`:
  PASS.
- `PATH=/home/daovanhung/.local/node-v24.21.0-linux-x64/bin:$PATH npm run build`:
  PASS - Vite build; có warning bundle lớn hơn 500 kB, không ảnh hưởng exit code.
- `deno test --allow-net supabase/functions/admin-adjust-membership-period/handler_test.ts`:
  PASS - 5/5.
- `deno check --no-lock supabase/functions/admin-adjust-membership-period/handler.ts supabase/functions/admin-adjust-membership-period/index.ts`:
  PASS.
- `deno fmt --check supabase/functions/admin-adjust-membership-period/handler.ts supabase/functions/admin-adjust-membership-period/index.ts supabase/functions/admin-adjust-membership-period/handler_test.ts`:
  PASS.
- `git diff --check`: PASS.
- `pwsh -NoProfile -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1`:
  FAIL baseline - thiếu `docs/audit/source_truth_manifest.json` và còn stale
  paths trong history/task-skill; không phải lỗi do feature này.
- Flutter/Dart contract tests: SKIPPED - môi trường không có executable
  `flutter`/`dart`.
- Supabase SQL apply, Edge deploy và browser-smoke: SKIPPED - chưa có sandbox
  project/ref/credential runtime trong workspace.

## Lỗi/Rủi ro

- Đã fix: payload add/sub gửi `ends_at = null` để RPC tự tính; RPC adjustment
  không còn nằm trong authenticated grant manifest; concurrent retry cùng key
  re-check audit sau row lock.
- Chưa fix: validator Codex vẫn fail do baseline manifest/stale path; cần xử lý
  trong task integrity riêng để không sửa lịch sử không liên quan.
- Cần kiểm tra tiếp: apply canonical SQL trên sandbox; deploy function; smoke
  finite/permanent/provider-managed/reduce-to-expired/stale/idempotent retry;
  chạy Dart contract tests khi có Flutter toolchain.

## Tỷ lệ hoàn thành

- Hoàn thành: code Admin Web, API types/mapper, SQL/RPC, Edge Function, local
  tests, docs/checklist và static validation.
- Đang dở: Supabase sandbox/deploy/browser acceptance và Flutter contract test
  do thiếu môi trường; production acceptance chưa được claim.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - đã rà lại service-role boundary, payload semantics,
  stale-period và concurrency/idempotency trước khi chốt.
- Mức độ hoàn thành task: hoàn tất implementation trong phạm vi; rollout
  runtime còn pending theo đúng risk boundary.
- Bằng chứng kiểm chứng: 27/27 Admin Web tests, typecheck/build, 5/5 Deno
  handler tests, Deno check/format và diff check PASS; Codex validator fail
  baseline; Flutter contract/sandbox chưa chạy.
- Điểm tốn token/chưa tối ưu: phải đọc nhiều DD/checklist lịch sử để tránh
  claim runtime; `rg` không có trong image nên dùng `grep` fallback.
- Cách tối ưu cho phiên sau: chuẩn bị Flutter toolchain và sandbox fixture;
  thêm test integration RPC chạy rollback/row-lock thay vì chỉ static contract.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`
