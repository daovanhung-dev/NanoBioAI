Commit de xuat: docs(test): xac minh AAB Nabi 1.0.2

# Kiểm tra Android App Bundle Nabi 1.0.2

## Phạm vi

- Ngày: 2026-10-22
- Artifact: `build/app/outputs/bundle/release/app-release.aab`
- Mục tiêu: build AAB release có chữ ký cho package `com.nanobioai.app`, version `1.0.2`, version code `7`.
- Môi trường: Flutter 3.47.7 stable (`abaf9c523780a608bd46686fd5e53740a07077f8`), Dart 3.13.5, Android SDK 36, JDK 21.

## Kết quả

- `flutter pub get`: PASS.
- `flutter build appbundle --release`: PASS; hoàn tất sau 403.4 giây.
- Kích thước AAB: `589450283` bytes.
- `bundletool validate`: PASS, exit code 0.
- `bundletool dump manifest`: PASS; `package=com.nanobioai.app`, `versionName=1.0.2`, `versionCode=7`, `targetSdkVersion=36`.
- `keytool -printcert -jarfile`: PASS; AAB có chứng thư ký release với SHA-256 fingerprint `0E:53:59:9A:7E:2D:0F:85:69:AA:68:0E:D5:98:0B:9F:22:94:01:90:ED:65:68:0D:CA:0C:FF:17:F4:4A:A7:3F`. Fingerprint trùng với AAB đã lưu trước build.
- SHA-256 AAB mới: `4a71a84792c3ae1e8e33bc7e926a878095093a795ce9682a72a9a8d60a5c6186`.
- AAB cũ được bảo toàn tại `build/archives/app-release-before-1.0.2+7.aab`, size `420002333` bytes, SHA-256 `b06e662fa6ed1f1dad05ef11e53f10657e0c4a487f44ff96ec0d1dcd7a58bc19`.
- `flutter doctor -v`: Android toolchain PASS và Android SDK license state báo `All Android licenses accepted`; không chạy lệnh nhận license.
- Unit tests: NOT_RUN; không thay đổi logic runtime.
- Upload Play Console: NOT_RUN.

## Lưu ý

- Flutter báo Gradle `8.14.0`, Android Gradle Plugin `8.11.1` và Kotlin `2.2.20` sẽ cần nâng trong tương lai; cảnh báo không chặn lần build này.
- Cần xác nhận version code `7` chưa tồn tại trên Play Console trước khi tải lên. Chưa kiểm tra việc Play Console chấp nhận artifact hoặc upload key đã đăng ký.

## Lệnh xác minh

```sh
flutter build appbundle --release
java -jar /tmp/bundletool-all-1.18.3.jar validate --bundle=build/app/outputs/bundle/release/app-release.aab
java -jar /tmp/bundletool-all-1.18.3.jar dump manifest --bundle=build/app/outputs/bundle/release/app-release.aab --module=base
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab
sha256sum build/app/outputs/bundle/release/app-release.aab
```
