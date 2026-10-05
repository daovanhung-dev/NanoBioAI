Commit de xuat: docs(worklog): ghi nhan doi thuong hieu Nabi

# Worklog - Đổi thương hiệu và nâng phiên bản Nabi

## Thời gian

- Ngày: 2026-10-05
- Bắt đầu: không ghi nhận riêng
- Kết thúc: 13:17
- Timezone: Asia/Saigon

## Phạm vi

- Loại task: coding, localization, platform branding và validation
- Module chính: tên ứng dụng, splash/onboarding, launcher icons, app version
- Yêu cầu gốc: dùng `assets/logo.jpg`, đổi tên thành “Nabi - Trợ lý sức khỏe AI”, tăng phiên bản thành `1.0.1+4`.

## Đã làm

- Cấu hình và sinh icon Android, iOS, Web, macOS, Windows từ logo người dùng cung cấp.
- Đổi nhãn điện thoại thành “Nabi”; cập nhật title ứng dụng, splash, onboarding và metadata Web/Windows.
- Giữ nguyên Admin, application ID `com.nanobioai.app`, deep link `nanobio` và các định danh kỹ thuật.
- Nâng version name/code; xác nhận lại trực tiếp từ APK debug.
- Chỉnh thời gian chờ chuyển route trong test onboarding vì test chạm CTA trước khi animation điều hướng hoàn tất.
- Thêm tài liệu tính năng tại `docs/features/rebrand-nabi/001-feature-rebrand-nabi.md`.

## File code/docs đã sửa

- `pubspec.yaml`, `lib/l10n/*`, splash và các chuỗi onboarding: đổi tên/version và khai báo sinh icon.
- `android/`, `ios/`, `macos/`, `windows/`, `web/`: nhãn, metadata và icon mới.
- `test/app_versions/v1/features/`, `test/core/localization/`: cập nhật assertion và chờ animation route.
- `docs/features/rebrand-nabi/001-feature-rebrand-nabi.md`: ghi chi tiết thay đổi.
- `docs/worklog/2026-10-05/004-worklog-rebrand-nabi.md`: ghi nhận phiên.
- `assets/logo.jpg`: nguồn icon do người dùng cung cấp; giữ nguyên nội dung.

## Tài liệu liên quan

- `.codex/DOCS_WORKFLOW.md`
- `.codex/history/SESSION_QUALITY_REVIEW.md`
- `docs/features/rebrand-nabi/001-feature-rebrand-nabi.md`

## Commands

- `/tmp/nabi_flutter_sdk/bin/flutter pub get`: PASS với Flutter 3.47.6; Flutter 3.35.6 ghim trong `.metadata` không giải được dependency `in_app_purchase 3.3.0` cần Dart 3.10+.
- `/tmp/nabi_flutter_sdk/bin/flutter gen-l10n`: PASS.
- `/tmp/nabi_flutter_sdk/bin/dart run flutter_launcher_icons`: PASS, đủ năm nền tảng.
- `/tmp/nabi_flutter_sdk/bin/flutter test test/app_versions/v1/features/splash/splash_page_test.dart test/app_versions/v1/features/onboarding/onboarding_entry_page_test.dart test/core/localization/app_localization_config_test.dart`: PASS, 7 tests.
- `/tmp/nabi_flutter_sdk/bin/flutter analyze`: PASS, không có issue.
- `/tmp/nabi_flutter_sdk/bin/flutter build apk --debug`: PASS; có cảnh báo Gradle/AGP/Kotlin/SDK XML.
- `/tmp/nabi_flutter_sdk/bin/flutter build web --release`: PASS; có cảnh báo tương thích WebAssembly từ plugin hiện có.
- `aapt dump badging build/app/outputs/flutter-apk/app-debug.apk`: PASS; xác nhận package, label Nabi, versionName 1.0.1, versionCode 4.
- `git diff --check`: PASS.
- `python3 .codex/tools/update_worklog_learning.py --write` và `--check`: PASS; làm mới 19 tệp history/task-skill.
- `.codex/tools/validate_codex_integrity.ps1`: FAIL do baseline repo thiếu `docs/audit/source_truth_manifest.json` và có backticked paths cũ trong history/task-skill có sẵn; các đường dẫn lỗi không nằm trong worklog mới.
- iOS/macOS/Windows native build: SKIPPED trên Linux; metadata và bộ icon đã kiểm tra tĩnh.

## Lỗi/Rủi ro

- Đã fix: test onboarding trước đây tap trong lúc transition còn chạy; tăng thời gian chờ để test xác nhận hành vi sau khi màn hình ổn định.
- Chưa fix: validator toàn repo còn lỗi cấu hình/đường dẫn cũ không thuộc thay đổi branding; không sửa dữ liệu nền ngoài phạm vi.
- Chưa fix: không thay dependency/toolchain cũ của dự án; cảnh báo Android/Web đã được ghi nhận, không ngăn build.
- Cần kiểm tra tiếp: build native iOS/macOS/Windows trên runner phù hợp trước phát hành.

## Tỷ lệ hoàn thành

- Hoàn thành: đổi thương hiệu, sinh icon, nâng version và build Android/Web.
- Đang dở: native build iOS/macOS/Windows không thực hiện được trên môi trường Linux.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - thay đổi phủ đủ metadata và icon năm nền tảng, đồng thời giữ định danh kỹ thuật.
- Mức độ hoàn thành task: hoàn thành theo phạm vi; native build Apple/Windows còn kiểm chứng trên runner tương ứng.
- Bằng chứng kiểm chứng: 7 tests, `flutter analyze`, APK debug với metadata đúng, Web release build, kiểm tra icon và `git diff --check`.
- Điểm tốn token/chưa tối ưu: SDK repo không tương thích dependency hiện tại; cần đọc `pubspec.lock`/yêu cầu SDK trước khi bắt đầu validation.
- Cách tối ưu cho phiên sau: xác định Flutter/Dart thực tế từ dependency lock trước khi tải SDK; dùng runner native cho các nền tảng ngoài Linux.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`
