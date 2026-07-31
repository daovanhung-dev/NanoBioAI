Commit de xuat: feat(payment): VietQR Vietcombank chờ duyệt thủ công

# Worklog - VietQR Vietcombank chờ duyệt thủ công

## Thời gian

- Ngày: 2026-07-31
- Bắt đầu: 09:30
- Kết thúc: 10:56
- Timezone: Asia/Saigon

## Phạm vi

- Loại task: coding + Supabase contract + test + DD/docs.
- Module chính: M13 PAYMENT_MEMBERSHIP và Admin payment queue.
- Yêu cầu gốc: khách quét QR Vietcombank, bấm “Đã chuyển khoản”, Admin tự đối chiếu VCB và duyệt hoặc từ chối; không có biên lai, webhook, API/số dư ngân hàng.

## Đã làm

- Thêm trạng thái awaiting_transfer, pending_review, succeeded, failed; giữ pending cũ để Admin xử lý.
- Thêm transfer_reference NB + 12 ký tự hex, memo ASCII tối đa 25 ký tự, snapshot ngân hàng/nội dung/xác nhận vào metadata.
- Thêm RPC tạo yêu cầu, lấy yêu cầu hiện tại, xác nhận chuyển khoản, alert Admin và mở rộng hàng chờ/duyệt.
- Lưu recipient VCB phía server: BIN 970436, tài khoản 1026806174, LE PHU THACH / Lê Phú Thạch.
- Tạo shared VietQR payload/CRC16 builder; màn khách hiển thị QR/chi tiết/copy memo và chặn nếu SQLite thiếu full_name đúng user ID.
- Thêm banner Admin mỗi 30 giây và khi resume, liên kết đến Payments; Admin đối chiếu mã/số tiền/memo trước quyết định.
- Cập nhật DD M13, feature doc, checklist coding/DD và test evidence.

## File code/docs đã sửa

- docs/supabase/13-membership-payment-request.sql và docs/supabase/config.sql - contract/migration VietQR.
- lib/core/payments/viet_qr_payload_builder.dart - payload QR thuần dùng chung.
- lib/app_versions/v2/features/payments - data, domain, controller và UI checkout/confirmation.
- lib/app_versions/admin/features/admin_panel - alert, queue reconciliation và refresh UI.
- test/core/payments, test/app_versions/v2/features/payments, test/app_versions/admin, test/docs - focused unit/widget/contract coverage.
- docs/DD/payment_membership, docs/features/payment_membership, docs/test/payment_membership và docs/checklist - thiết kế, traceability và backlog.

## Tài liệu liên quan

- docs/DD/payment_membership/Overall.md
- docs/features/payment_membership/001-feature-vietqr-manual-payment-review.md
- docs/test/payment_membership/001-test-vietqr-manual-payment-review.md
- docs/supabase/README.md

## Commands

- flutter analyze lib/core/payments lib/app_versions/v2/features/payments lib/app_versions/admin/features/admin_panel test/core/payments test/app_versions/v2/features/payments test/app_versions/admin test/docs/supabase_config_contract_test.dart test/docs/supabase_admin_contract_test.dart: PASS - không có lỗi.
- flutter test test/core/payments test/app_versions/v2/features/payments test/app_versions/admin test/docs/supabase_config_contract_test.dart test/docs/supabase_admin_contract_test.dart: PASS - 100 tests.
- Focused SQL static comparison giữa M13 migration và config.sql: PASS - sáu function blocks khớp.
- git diff --check: PASS.

## Lỗi/Rủi ro

- Đã fix: mã/giá/ngân hàng không do client quyết định; khách không mở quyền bằng nút xác nhận; alert không đếm pending cũ.
- Chưa fix: chưa có bằng chứng sandbox/RLS hoặc UAT ngân hàng vì không có môi trường/quyền rollout trong phiên này.
- Cần kiểm tra tiếp: apply migration vào sandbox, quét QR, kiểm tra người nhận/số tiền/memo, xác nhận ownership và Admin payments.write, duyệt/từ chối rồi kiểm tra entitlement/audit.

## Tỷ lệ hoàn thành

- Hoàn thành: source Flutter, SQL contract, DD/docs và focused local tests cho toàn bộ phạm vi đã yêu cầu.
- Đang dở: sandbox migration/RLS smoke và UAT VCB trước production.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - flow khách/Admin tách quyền rõ ràng, không có đường cấp quyền trước duyệt.
- Mức độ hoàn thành task: hoàn thành code/test/docs; chưa đủ bằng chứng production acceptance.
- Bằng chứng kiểm chứng: targeted analyze sạch, 100 tests pass, SQL contract comparison và diff check pass.
- Điểm tốn token/chưa tối ưu: cần đọc cả payment và Admin contracts để giữ backward compatibility với pending cũ.
- Cách tối ưu cho phiên sau: chuẩn bị sandbox account/SQL runner trước khi coding để chạy ngay UAT/RLS sau contract change.
- Task-skill cần đọc lần sau: .codex/task-skills/supabase-schema.md
