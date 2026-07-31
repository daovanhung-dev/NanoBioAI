Commit de xuat: test(payment): ghi nhan kiem thu VietQR duyet thu cong

# Test - VietQR Vietcombank chờ duyệt thủ công

## Phạm vi kiểm tra

- Payload VietQR EMV/CRC16 và giới hạn memo ASCII.
- Đọc tên SQLite theo exact Supabase user ID, tên trống và UI chặn tạo QR.
- Retry yêu cầu, khôi phục yêu cầu, xác nhận chuyển khoản và chỉ làm mới quyền sau succeeded.
- Admin banner/chờ duyệt, hàng chi tiết đối chiếu và action gate pending_review hoặc pending cũ.
- Contract Supabase cho mã giao dịch, quyền, trạng thái, audit và kích hoạt gói.

## Kết quả local

| Lệnh | Kết quả | Ghi chú |
|---|---|---|
| flutter analyze lib/core/payments lib/app_versions/v2/features/payments lib/app_versions/admin/features/admin_panel test/core/payments test/app_versions/v2/features/payments test/app_versions/admin test/docs/supabase_config_contract_test.dart test/docs/supabase_admin_contract_test.dart | PASS | Không có lỗi phân tích. |
| flutter test test/core/payments test/app_versions/v2/features/payments test/app_versions/admin test/docs/supabase_config_contract_test.dart test/docs/supabase_admin_contract_test.dart | PASS | 100 tests; gồm QR/V2, Admin và contract SQL trong phạm vi lệnh. |
| git diff --check | PASS | Không có lỗi whitespace. |

## Điểm đã kiểm chứng

- QR dùng BIN 970436, tài khoản 1026806174, tên QR LE PHU THACH và CRC16 xác định.
- Memo chỉ gồm ASCII, không dài quá 25 ký tự; mã NB đứng đầu.
- Local datasource không đọc tên của một hàng SQLite khác ID đăng nhập.
- Khách xác nhận chuyển yêu cầu sang pending_review, không kích hoạt quyền.
- Chỉ response succeeded làm mới effective access.
- Admin banner chỉ có dữ liệu từ pending_review, còn pending cũ vẫn được phép xử lý.
- Hợp đồng SQL kiểm tra payments.write, ownership auth.uid(), review audit và activation chỉ khi approve.

## Chưa thực hiện trong môi trường này

- Không áp dụng migration vào Supabase sandbox.
- Không có UAT quét QR bằng ứng dụng ngân hàng hoặc đối chiếu VCB thật.
- Cần kiểm tra sandbox/RLS với ít nhất một khách và một Admin có payments.write trước production.
