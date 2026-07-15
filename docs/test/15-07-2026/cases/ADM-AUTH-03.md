Commit de xuat: test(real-device): ghi nhan case ADM-AUTH-03

# ADM-AUTH-03

- Trạng thái: PENDING
- Persona/tiền điều kiện: Token hết hạn hoặc thiếu cấu hình
- BD/DD/AC: BD §11 - error/session
- Thiết bị bắt buộc: Xiaomi 220333QPG, Android 11/API 30, 720x1650

## Kịch bản và kết quả mong đợi

Token hết hạn về login; thiếu cấu hình/lỗi kiểm tra role hiển thị support state và retry, không làm `main_admin` crash.

## Thao tác thực tế

- Chưa thực thi trong chiến dịch 15-07-2026.

## Kết quả thực tế

- Chưa có kết quả quan sát từ điện thoại thật.

## Bằng chứng

- Ảnh điện thoại: chưa có.
- Command/log bổ trợ: chưa có.

## Bug và retest

- Chưa xác định.