Commit de xuat: docs(worklog): ghi nhan cai Flutter va xuat AAB 1.0.2

# Worklog - Cài Flutter stable và xuất AAB Nabi 1.0.2

## Thời gian

- Ngày: 2026-10-22
- Bắt đầu: không ghi nhận chính xác
- Kết thúc: 19:09
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: cài Flutter, tăng version Android và xuất release artifact
- Module chính: Flutter SDK, Android App Bundle
- Yêu cầu gốc: cài Flutter stable mới nhất, tăng version lên `1.0.2+7`, build AAB ký release; không sửa app/web và không upload Play Console.

## Đã làm

- Nâng Flutter tại `/home/daovanhung/development/Flutter/flutter` lên stable `3.47.7`, revision `abaf9c523780a608bd46686fd5e53740a07077f8`; Dart `3.13.5`. Release metadata chính thức xác nhận revision và stable version này.
- Chạy `flutter doctor -v`: Android toolchain và các Android SDK licenses được xác nhận hợp lệ. Không chạy `flutter doctor --android-licenses` và không tự nhận điều khoản.
- Giữ bản AAB trước build tại `build/archives/app-release-before-1.0.2+7.aab`, SHA-256 `b06e662fa6ed1f1dad05ef11e53f10657e0c4a487f44ff96ec0d1dcd7a58bc19`.
- Đặt version ứng dụng là `1.0.2+7`; `flutter pub get` thành công, không cập nhật `pubspec.lock`.
- Build release thành công bằng `flutter build appbundle --release`; AAB mới có kích thước `589450283` bytes.
- Bundletool xác nhận AAB hợp lệ; manifest ghi package `com.nanobioai.app`, version name `1.0.2`, version code `7`, target SDK `36`.
- AAB mới có chữ ký release. SHA-256 fingerprint `0E:53:59:9A:7E:2D:0F:85:69:AA:68:0E:D5:98:0B:9F:22:94:01:90:ED:65:68:0D:CA:0C:FF:17:F4:4A:A7:3F` khớp với bản AAB cũ.
- SHA-256 AAB mới: `4a71a84792c3ae1e8e33bc7e926a878095093a795ce9682a72a9a8d60a5c6186`.
- Trong lúc build, nội dung description trong `pubspec.yaml` đổi từ giá trị working-tree ban đầu `Nano.` sang `NaBiAI Application`; thay đổi này không do lệnh build và được giữ nguyên.
- Không upload lên Google Play Console.

## File code/docs đã sửa

- `pubspec.yaml` - version `1.0.2+7`; giữ nguyên thay đổi description xuất hiện trong working tree.
- `docs/worklog/2026-10-22/002-worklog-flutter-install-and-aab.md` - cập nhật kết quả cuối cùng.
- `docs/test/release-aab-2026-10-22/001-test-release-aab.md` - tạo biên bản xác minh artifact.
- `/home/daovanhung/development/Flutter/flutter` - cài SDK stable 3.47.7 ngoài repository.
- `build/archives/app-release-before-1.0.2+7.aab` - bản lưu AAB trước build trong thư mục build bị ignore.
- `build/app/outputs/bundle/release/app-release.aab` - AAB release mới trong thư mục build bị ignore.

## Tài liệu liên quan

- [Flutter stable release metadata](https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json)
- `.metadata` - metadata Flutter có sẵn của dự án.
- `android/local.properties` - đường dẫn SDK Flutter và Android SDK.
- `docs/worklog/2026-10-05/005-worklog-release-aab.md` - lịch sử ký và xuất AAB trước.

## Commands

- `git -C /home/daovanhung/development/Flutter/flutter rev-parse HEAD`: PASS - khớp revision stable `abaf9c523780a608bd46686fd5e53740a07077f8`.
- `flutter --version`: PASS - Flutter 3.47.7, channel stable.
- `dart --version`: PASS - Dart 3.13.5.
- `flutter doctor -v`: PASS cho Android toolchain; Android SDK licenses báo `All Android licenses accepted`. Linux desktop thiếu `clang++` và `pkg-config`, không liên quan Android release.
- `flutter pub get`: PASS - `Got dependencies`; không đổi `pubspec.lock`.
- `flutter build appbundle --release`: PASS - `Built .../app-release.aab (589.5MB)` sau 403.4 giây.
- `java -jar /tmp/bundletool-all-1.18.3.jar validate --bundle=build/app/outputs/bundle/release/app-release.aab`: PASS - exit code 0.
- `bundletool dump manifest ... --module=base`: PASS - package/version/version code khớp `com.nanobioai.app` / `1.0.2` / `7`.
- `keytool -printcert -jarfile` với AAB mới và bản lưu cũ: PASS - SHA-256 fingerprint khớp.
- `stat` và `sha256sum`: PASS - kích thước và checksum AAB mới/backup được ghi ở trên.
- Unit tests: NOT_RUN - không sửa logic runtime; phạm vi là build release artifact.
- Upload Play Console: NOT_RUN - ngoài phạm vi.

## Lỗi/Rủi ro

- Đã xử lý: Flutter 3.35.6 báo trạng thái license không xác định; Flutter stable 3.47.7 xác nhận Android licenses đã hợp lệ. Không có thao tác chấp nhận license trong phiên.
- Chưa sửa: Flutter cảnh báo Gradle `8.14.0`, Android Gradle Plugin `8.11.1` và Kotlin `2.2.20` sẽ cần nâng trong tương lai; hiện build vẫn thành công.
- Cần kiểm tra tiếp: xác nhận version code `7` chưa được dùng trên Play Console trước khi tải lên.
- Chữ ký AAB mới trùng với artifact cũ tại máy; chưa xác nhận fingerprint với upload key đã đăng ký trên Play Console.

## Tỷ lệ hoàn thành

- Hoàn thành: cài Flutter stable mới nhất được release metadata ghi nhận, tăng version, build AAB ký release và xác minh manifest/chữ ký/checksum.
- Đang dở: tải lên Play Console và kiểm tra availability của version code `7` chưa thực hiện theo phạm vi đã chốt.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - AAB release mới được bundletool xác minh; chữ ký khớp bản trước và artifact cũ đã được giữ riêng.
- Mức độ hoàn thành task: hoàn thành yêu cầu build; chưa phát hành lên Play.
- Bằng chứng kiểm chứng: build exit code 0, bundletool validate/manifest, `keytool`, `stat`, `sha256sum`.
- Điểm tốn token/chưa tối ưu: Flutter `channel stable` khởi chạy precache rộng; đã dừng bước đó và xác minh channel bằng cách tái tạo metadata phiên bản sau khi checkout đúng stable revision.
- Cách tối ưu cho phiên sau: kiểm tra current stable metadata, license state và cấu hình ký trước khi bắt đầu tải SDK hoặc build.
- Task-skill cần đọc lần sau: `.codex/task-skills/test.md`
