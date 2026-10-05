Commit de xuat: feat(branding): rebrand app as Nabi

# Đổi thương hiệu và nâng phiên bản Nabi

## Phạm vi

- Tên người dùng nhìn thấy: **Nabi - Trợ lý sức khỏe AI**.
- Nhãn icon ứng dụng: **Nabi**.
- Nguồn icon: `assets/logo.jpg`.
- Phiên bản Flutter: `1.0.1+4`.
- Giữ nguyên tên Admin, application ID `com.nanobioai.app`, deep link `nanobio` và tên package Dart `nano_app`.

## Triển khai

- Cập nhật cấu hình `flutter_launcher_icons` để tạo icon Android, iOS, Web, macOS và Windows từ logo mới.
- Đổi tên hiển thị native trên Android/iOS/macOS; đặt ProductName và FileDescription đầy đủ cho Windows.
- Cập nhật title, mô tả, Apple web-app title và manifest Web; nhãn ngắn vẫn là Nabi.
- Cập nhật localization title, splash và các chuỗi thương hiệu ở onboarding. Tên Admin giữ nguyên.
- Đồng bộ version build từ `pubspec.yaml` sang Android và metadata native thông qua Flutter.

## Kiểm chứng

- `flutter_launcher_icons` tạo đủ tài nguyên icon cho năm nền tảng.
- Test splash, onboarding entry và localization: 7 test qua.
- `flutter analyze`: không có lỗi.
- APK debug: `com.nanobioai.app`, version name `1.0.1`, version code `4`, application label `Nabi`.
- Web release build: title và manifest hiển thị đúng tên/nhãn, màu nền cũ được giữ nguyên.
- iOS/macOS/Windows: tài nguyên icon và metadata được kiểm tra tĩnh trên Linux; chưa chạy native build.

## Giới hạn kiểm chứng

- Web release báo các cảnh báo WebAssembly từ `flutter_secure_storage_web` và `flutter_tts`; build JavaScript release vẫn thành công.
- Android build báo cảnh báo tương thích sắp tới cho Gradle/AGP/Kotlin và SDK XML; APK vẫn build thành công.
- Không upload store, commit hoặc push trong phạm vi thay đổi này.
