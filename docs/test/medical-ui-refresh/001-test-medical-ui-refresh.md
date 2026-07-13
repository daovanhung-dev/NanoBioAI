Commit de xuat: test(ui): bo sung contract cho medical design system

# Test - Medical UI Refresh

## Phạm vi kiểm chứng

- Kiểm tra V1, V2, V3 và Admin đều dùng `AppExperience.builder`.
- Kiểm tra theme barrel export medical UI và app experience.
- Kiểm tra Material 3 cùng các theme component quan trọng đã được cấu hình.
- Kiểm tra page production không dùng trực tiếp `Scaffold` ngoài primitive nội bộ và trang demo.
- Kiểm tra cấu trúc Dart, import, delimiter và asset/ZIP bằng static script trong môi trường hiện tại.

## Kết quả

- Static source contracts: PASS.
- Import/path checks: PASS.
- Delimiter checks trên các file thay đổi: PASS sau khi loại trừ false-positive từ parser chuỗi đơn giản ở file legacy.
- Flutter format/analyze/test/build: SKIPPED vì môi trường thực thi không có Flutter/Dart SDK.
- Device smoke và kiểm tra trực quan trên nhiều kích thước màn hình: CHƯA THỰC HIỆN.

## Lệnh cần chạy ở máy phát triển

```bash
flutter clean
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter run -t lib/main.dart
```

## Rủi ro còn lại

- Cần kiểm tra screenshot/golden trên điện thoại nhỏ, tablet và desktop.
- Cần kiểm tra overflow khi text scale 1.3-2.0.
- Cần kiểm tra tương phản và focus thực tế bằng TalkBack/VoiceOver hoặc Accessibility Scanner.
