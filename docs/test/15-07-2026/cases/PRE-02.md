Commit de xuat: test(real-device): ghi nhan case PRE-02

# PRE-02

- Trạng thái: PASS
- Persona/tiền điều kiện: Cau hinh local da ignore
- BD/DD/AC: Sandbox gate
- Thiết bị bắt buộc: Xiaomi 220333QPG, Android 11/API 30, 720x1650

## Kịch bản và kết quả mong đợi

Khoi chay v2 va Admin chi den sandbox; khong hien thi/ghi endpoint secret hay production credential.

## Thao tác thực tế

- Build APK debug từ `lib/main.dart` với cấu hình auth sandbox.
- Cài APK lên thiết bị `12b304f9`, mở launcher activity và chờ thiết bị ổn định.
- Chụp trực tiếp màn hình điện thoại sau khi UI hoàn tất bootstrap.

## Kết quả thực tế

- PASS: ứng dụng mở vào màn hình bắt đầu và hiển thị nội dung onboarding/auth.
- Lần chụp đầu chỉ có frame đen do thiết bị đang lag; ảnh này là INCONCLUSIVE, không phải lỗi màn hình ứng dụng.

## Bằng chứng

- Ảnh PASS: `../assets/PRE-02-device-settled.png`.
- Ảnh không kết luận khi máy lag: `../assets/PRE-02-device-lag-inconclusive.png`.
- Build APK: PASS; install APK: PASS; resumed activity: `com.example.nano_app/.MainActivity`.

## Bug và retest

- Không ghi nhận bug màn hình đen.
- Log Riverpod assertion được giữ làm tín hiệu kỹ thuật cần kiểm tra riêng; chưa đủ bằng chứng để gán là lỗi UI.
