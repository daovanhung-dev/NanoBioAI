Commit de xuat: feat(payment): VietQR Vietcombank chờ duyệt thủ công

# Feature - Thanh toán VietQR Vietcombank chờ duyệt thủ công

## Phạm vi

- Module: M13 / PAYMENT_MEMBERSHIP.
- Màn khách: /v2/payments.
- Màn xử lý: /admin/payments và thanh thông báo đầu Admin shell.
- Người nhận: Vietcombank, BIN 970436, tài khoản 1026806174, tên hiển thị Lê Phú Thạch.

## Luồng đã triển khai

1. Khách chọn Plus hoặc FamilyPlus và chu kỳ thanh toán.
2. Ứng dụng đọc full_name SQLite theo đúng Supabase user ID. Thiếu tên thì hướng dẫn cập nhật hồ sơ, không tạo QR.
3. Supabase dùng auth.uid(), tự tính giá và sinh mã bất biến NB + 12 ký tự hex. Nội dung chuyển khoản là mã ở đầu kèm tên ASCII không dấu, tối đa 25 ký tự.
4. Ứng dụng hiển thị QR VietQR, số tài khoản, chủ tài khoản, số tiền, mã giao dịch và nút sao chép nội dung.
5. Khách chuyển tiền và bấm “Đã chuyển khoản”. Yêu cầu chuyển sang pending_review; quyền gói vẫn chưa đổi.
6. Admin có payments.write thấy banner đếm pending_review, mở hàng chờ và tự đối chiếu mã/số tiền/nội dung trong ứng dụng VCB.
7. Admin duyệt hoặc từ chối. Chỉ duyệt mới kích hoạt quyền gói; lý do từ chối hiển thị cho khách.

## Hợp đồng an toàn

- Mã giao dịch, giá, số tài khoản nhận và nội dung chuyển khoản do Supabase sở hữu; Flutter không thể ghi đè.
- Retry cùng idempotency key trả lại cùng yêu cầu/mã; transfer_reference duy nhất trong payment_events.
- Khách chỉ xác nhận yêu cầu của auth.uid() ở trạng thái awaiting_transfer.
- Banner chỉ đếm pending_review; bản ghi pending cũ vẫn được Admin xử lý để không làm kẹt dữ liệu cũ.
- Admin review yêu cầu payments.write và ghi audit. Từ chối không tạo quyền.
- Không có upload biên lai, webhook, API/số dư ngân hàng, thông báo đẩy hoặc realtime RLS mới.

## Thành phần chính

- SQL migration chuyên biệt: docs/supabase/13-membership-payment-request.sql.
- Cấu hình end-state: docs/supabase/config.sql.
- Payload QR thuần dùng chung: lib/core/payments/viet_qr_payload_builder.dart.
- Feature khách: lib/app_versions/v2/features/payments.
- Hàng chờ/badge Admin: lib/app_versions/admin/features/admin_panel.

## Kiểm thử yêu cầu

- Payload VietQR có CRC16, memo ASCII giới hạn và thông tin người nhận đầy đủ.
- SQLite chỉ lấy tên của đúng user; tên trống khóa hành động tạo QR.
- Xác nhận chỉ tạo pending_review; quyền chỉ được làm mới khi backend trả succeeded.
- Contract SQL kiểm tra mã duy nhất, ownership, trạng thái, quyền payments.write, audit và không cấp quyền trước duyệt.
- UI Admin kiểm tra banner, drill-down, chi tiết đối chiếu và thao tác duyệt/từ chối.

## Bằng chứng còn cần trước production

- Áp dụng migration vào Supabase sandbox và chạy contract/RLS smoke bằng tài khoản khách/Admin.
- UAT quét QR bằng ứng dụng ngân hàng, kiểm tra người nhận, số tiền và nội dung.
- Admin đối chiếu giao dịch thật trong VCB sandbox/luồng vận hành rồi duyệt/từ chối.
