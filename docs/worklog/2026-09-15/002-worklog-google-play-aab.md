Commit de xuat: build(android): xuat AAB ban sua notification navigation

# Worklog - Xuất Android App Bundle cho bản vá Google Play

## Thời gian

- Ngày: 2026-09-15
- Kết thúc ghi nhận: 11:14
- Timezone: Asia/Ho_Chi_Minh (UTC+07:00)

## Phạm vi

- Loại task: test / release artifact
- Module chính: Android release build và Google Play handoff.
- Yêu cầu: xuất file `.aab` cho bản vá UI notification navigation.

## Đã làm

- Dùng Flutter SDK tại `/home/daovanhung/development/Flutter/flutter`.
- Build release AAB bằng runtime defines hiện có và release signing config trong `android/app/build.gradle.kts`.
- Giữ version `1.0.0`, tăng/giữ versionCode hiện tại `2`; không tự thay đổi version nếu chưa có dữ liệu Play Console cao hơn.
- Cập nhật release evidence với artifact, SHA-256, kích thước, package và version.
- Không upload lên Play Console và không thay đổi Play Console state.

## Artifact

- File: `build/app/outputs/bundle/release/app-release.aab`
- Package: `com.nanobioai.app`
- Version: `1.0.0`, versionCode `2`
- Kích thước: `128,499,940` bytes
- SHA-256: `f6dc09dca2fd9272db9bfc2e01f57703117284a181d47a3593f98f2f3b9bd501`
- Chữ ký AAB: archive có `META-INF/NANOBIO-.SF` và `META-INF/NANOBIO-.RSA`; local release signing config đã được dùng.

## Commands và bằng chứng

- `flutter build appbundle --release -t lib/main.dart --dart-define-from-file=.dart_tool/nanobio_defines.json`: PASS.
- `stat`/`sha256sum`: PASS, khớp artifact metadata ở trên.
- `jarsigner -verify -certs`: PASS với exit code `0` ở chế độ non-strict; strict mode cảnh báo cấu trúc multi-entry của AAB, không thay đổi artifact.
- `git diff --check`: PASS.
- Play Console upload/release: NOT RUN; môi trường không có quyền/phiên Play Console.
- Android device install sau build: BLOCKED vì serial `12b304f9` đang offline/không xuất hiện trong `adb devices -l`.

## Trạng thái bàn giao

- Artifact local: PASS, có thể tải file AAB và upload thủ công lên Play Console.
- Play App Signing, upload, review và rollout: OPEN/MANUAL; chưa claim đã cập nhật Play Store.
- Trước khi upload, đối chiếu versionCode `2` với versionCode cao nhất trên Play Console; Play yêu cầu versionCode mới lớn hơn bản đã phát hành.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - đã tạo đúng release AAB, ghi hash/kích thước/version và không lộ secret ký app.
- Mức độ hoàn thành task: hoàn tất xuất artifact; chưa hoàn tất upload/rollout Play Console vì không có quyền truy cập.
- Bằng chứng kiểm chứng: Flutter bundleRelease PASS, archive signature entries hiện diện, SHA-256 đã ghi nhận; device acceptance và Play Console chưa chạy.
- Điểm tốn token/chưa tối ưu: release Gradle build mất khoảng 4 phút; bước xác minh AAB cần bundletool/Play Console để kiểm tra sâu hơn.
- Cách tối ưu cho phiên sau: chuẩn bị sẵn bundletool và quyền Play Console, xác nhận versionCode cao nhất trước build, sau đó upload internal track và lưu artifact ID.
- Task-skill cần đọc lần sau: `.codex/task-skills/test.md`
