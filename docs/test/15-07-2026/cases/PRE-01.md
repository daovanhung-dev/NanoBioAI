Commit de xuat: test(real-device): ghi nhan case PRE-01

# PRE-01

- Trạng thái: PASS
- Persona/tiền điều kiện: Android `12b304f9` ket noi
- BD/DD/AC: Device gate
- Thiết bị bắt buộc: Xiaomi 220333QPG, Android 11/API 30, 720x1650

## Kịch bản và kết quả mong đợi

Xac nhan device dung, package ID dung va co the chup man hinh truoc khi chay case nghiep vu.

## Thao tác thực tế

- Xác nhận thiết bị `12b304f9` online qua Android SDK.
- Mở trang thông tin package `com.example.nano_app` trên chính điện thoại.
- Chụp và kéo ảnh PNG nguyên gốc về thư mục chiến dịch.

## Kết quả thực tế

- PASS: điện thoại hiển thị trang thông tin ứng dụng NanoBio phiên bản 1.0.0.
- Ảnh được thu thành công từ thiết bị Xiaomi 220333QPG, Android API 30.

## Bằng chứng

- Ảnh PASS: `../assets/PRE-01-app-info-pass.png`.
- Log bổ trợ: serial `12b304f9`, model `220333QPG`, package `com.example.nano_app`.

## Bug và retest

- Không phát hiện bug trong case này.
