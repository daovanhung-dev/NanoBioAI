Commit đề xuất: feat(admin-web): tạo workspace vận hành NanoBio trên GitHub Pages

# Worklog - NanoBio Admin Web trên GitHub Pages

## Thời gian

- Ngày: 2026-09-13
- Múi giờ: Asia/Ho_Chi_Minh (UTC+07:00)

## Phạm vi

- Loại task: coding / web / test / docs / deployment workflow
- Module chính: Admin workspace, Supabase adapter, GitHub Pages
- Yêu cầu: tạo SPA React + TypeScript + Vite độc lập trong `admin-web/`, giữ
  Auth/RPC/RLS hiện có và deploy bằng GitHub Pages.

## Đã làm

- Tạo `admin-web/` với React, TypeScript, Vite, Supabase JS, HashRouter và CSS
  token system responsive desktop-first.
- Tạo route Admin cho dashboard, users, payments, sales, sale conversions,
  wellness rewards, reconciliation, plans, reports, audit và config; hỗ trợ
  alias route membership/accounts/payout theo parity hiện tại.
- Tạo Auth/session guard dùng `get_my_admin_session`, xử lý signed out,
  forbidden, session restore, expiry/revoke role và safe error.
- Tạo typed adapter cho list RPC, mutation RPC, Edge Functions tạo account/cấp
  membership, payout proof upload/signed URL và response normalization.
- Tạo confirmation/reason/idempotency flow cho write action, payment transfer
  verification, reward external revocation confirmation và double-submit guard.
- Tạo `.github/workflows/deploy-admin-web.yml` với `npm ci`, typecheck, test,
  preflight cấu hình, build và Pages artifact/deploy. Preflight dừng job nếu
  thiếu `NANOBIO_SUPABASE_URL`, `NANOBIO_SUPABASE_ANON_KEY` hoặc URL không hợp lệ
  mà không in giá trị secret.
- Tạo feature note và README hướng dẫn local/GitHub Variables/Secrets.
- Giữ nguyên các thay đổi chưa commit có sẵn trong worktree; không thay đổi
  schema Supabase trong task này.

## Contract đã kiểm tra

- `admin_search_users`, `admin_list_payments`, `admin_list_sales`,
  `admin_list_sale_point_conversions`, `admin_list_wellness_rewards`,
  `admin_list_reconciliation_discrepancies`, `admin_list_plan_config_versions`,
  `admin_list_report_catalog`, `admin_list_report_exports`,
  `admin_list_config_versions`, `admin_list_audit_events`.
- Mutation/Edge contract cho payment transfer verification, Sale/conversion,
  reconciliation, config, rewards, account và membership.
- Storage bucket `sale-payout-proofs`: JPG/PNG, tối đa 5 MB, path theo
  `sale-point-conversions/<conversion>/...`, upload mới và không update/delete.

## Commands và bằng chứng

- `npm install`/`npm ci` tại `admin-web/`: PASS; tạo và xác minh
  `package-lock.json`.
- `npm run typecheck`: PASS.
- `npm test`: PASS - 2 test files, 11 tests; gồm permission matrix, response
  normalization, payload reason/idempotency, payment transfer verification,
  payout proof path/file validation và key generation.
- `npm run build`: PASS - Vite production build thành công; kiểm tra
  `admin-web/dist/index.html` dùng `/NanoBioAI/assets/...`.
- `npm audit --omit=dev --audit-level=high`: PASS - 0 production
  vulnerabilities; npm vẫn báo dependency dev audit tổng thể khi cài đặt.
- `git diff --check`: PASS.
- `flutter test`/Dart Supabase contract tests: SKIPPED - môi trường không có
  `flutter` hoặc `dart` executable.
- `validate_codex_integrity.ps1`: FAIL baseline - thiếu
  `docs/audit/source_truth_manifest.json` và có stale path trong
  `.codex/history/WORKLOG_2026-08-16_meal_nutrition_estimation.md` cùng
  `.codex/task-skills/nabi-character/SKILL.md`; không phát sinh từ Admin Web.

## Rủi ro và giới hạn

- Vite cảnh báo JavaScript bundle lớn hơn 500 kB; chưa ảnh hưởng build, có thể
  code-split khi cần tối ưu tải lần đầu.
- Chưa có evidence GitHub Actions hoặc Supabase production runtime trong
  workspace; frontend build không chứng minh RLS/RPC production-ready.
- Cần cấu hình `NANOBIO_SUPABASE_URL` và `NANOBIO_SUPABASE_ANON_KEY` trên GitHub,
  bật Pages bằng GitHub Actions và kiểm tra runtime sau lần deploy đầu tiên.

## Tự đánh giá

- Kết quả: hoàn thành code scaffold và luồng Admin web theo phạm vi kế hoạch.
- Chất lượng: typecheck/test/build pass; contract backend đã đọc đối chiếu,
  không lộ secret và không thêm CRUD bảng tài chính/membership/audit.
- Chưa thể xác nhận: browser smoke test với Supabase session thật, GitHub
  Actions deploy thật và contract tests Dart do thiếu runtime/credentials.
