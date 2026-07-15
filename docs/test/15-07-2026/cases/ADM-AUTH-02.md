Commit de xuat: test(real-device): ghi nhan case ADM-AUTH-02

# ADM-AUTH-02

- Trạng thái: PENDING
- Persona/tiền điều kiện: User thường hoặc Admin bị thu hồi role
- BD/DD/AC: BD §11.8 - role lifecycle
- Thiết bị bắt buộc: Xiaomi 220333QPG, Android 11/API 30, 720x1650

## Kịch bản và kết quả mong đợi

Login/restore không được vào route Admin; app sign-out Admin session và quay về login, không ảnh hưởng session V2.

## Thao tác thực tế

- Chưa thực thi trong chiến dịch 15-07-2026.

## Kết quả thực tế

- Chưa có kết quả quan sát từ điện thoại thật.

## Bằng chứng

- Ảnh điện thoại: chưa có.
- Command/log bổ trợ: chưa có.

## Bug và retest

- Chưa xác định.