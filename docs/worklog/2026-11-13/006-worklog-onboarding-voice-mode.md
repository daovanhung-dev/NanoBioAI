# Worklog - Onboarding bằng giọng nói trên thiết bị

## Thời gian

- Ngày: 2026-11-13
- Timezone: Asia/Bangkok

## Phạm vi

- Loại task: coding/docs
- Module chính: M01 `ONBOARDING_PROFILE`
- Yêu cầu: thêm lựa chọn onboarding bằng giọng nói cho toàn bộ luồng.
- Ranh giới: giữ controller, validation, persistence, consent gate, API và schema hiện có.

## Đã làm

- Thêm CTA vào voice mode ở màn vào onboarding; voice mode hỏi cỡ chữ trước các bước và chỉ xuất hiện trên Android/iOS.
- Tạo luồng PCM mono 16 kHz trong bộ nhớ, nhận dạng bằng model Whisper tiếng Việt đã có và dùng chung cache với Nabi ESP. Không ghi audio ra file, không gửi bản ghi hoặc transcript tới backend.
- Nabi hỏi theo từng trường: hồ sơ cơ bản, goals, conditions, habits/lifestyle, extras, medication reminders và toàn bộ giờ routine ngày thường/cuối tuần.
- Danh sách ngắn được đọc và nhận câu trả lời theo nhãn/số. Danh sách dài được chọn trực tiếp. Có nhập liệu, thử lại và chuyển chạm; câu trả lời nháp được giữ khi đổi mode.
- Consent được đọc bằng TTS nhưng phải chạm xác nhận. Review đọc tóm tắt và lệnh “Tạo lộ trình” gọi lại submit handler hiện có.
- Cập nhật quyền micro iOS, screen specs, checklist M01 và feature note.

## File đã sửa/thêm

- `lib/app_versions/v1/features/onboarding/data/onboarding_voice_runtime.dart`
- `lib/app_versions/v1/features/onboarding/providers/onboarding_voice_provider.dart`
- `lib/app_versions/v1/features/onboarding/presentation/onboarding_voice_questions.dart`
- `lib/app_versions/v1/features/onboarding/presentation/widgets/onboarding_voice_step.dart`
- `lib/app_versions/v1/features/onboarding/presentation/pages/onboarding_entry_page.dart`
- `lib/app_versions/v1/features/onboarding/presentation/pages/onboarding_page.dart`
- `lib/app_versions/v1/features/onboarding/presentation/pages/onboarding_text_scale_page.dart`
- `lib/app_versions/v1/features/onboarding/presentation/widgets/onboarding_step_shell.dart`
- `lib/app_versions/v1/features/onboarding/presentation/widgets/consent_step.dart`
- `lib/app_versions/v1/features/onboarding/presentation/widgets/review_step.dart`
- `pubspec.yaml`, `pubspec.lock`, generated Flutter registrants, `ios/Runner/Info.plist`
- `.codex/design/screens/*onboarding*`, `docs/checklist/checklist_complete_DD.md`, `docs/checklist/checklist_task_coding.md`
- `docs/features/onboarding-voice-mode/001-feature-onboarding-voice-mode.md`

## Commands và kết quả

- `dart format` trên 10 file Dart liên quan: PASS.
- `flutter analyze --no-pub` trên 10 file Dart liên quan: PASS — không có issue.
- `git diff --check`: PASS.
- Automated tests: không chạy trong lượt này.
- `flutter build apk --debug --no-pub`: PASS trên source mới nhất; tạo `build/app/outputs/flutter-apk/app-debug.apk`.
- Android/iOS device smoke: chưa chạy.
- `.codex/tools/validate_codex_integrity.ps1`: chưa chạy; host Linux không có PowerShell theo worklog trước.
- `python3 .codex/tools/update_worklog_learning.py --write` và `--check`: PASS.

## Giới hạn và acceptance còn thiếu

- Chưa xác minh cấp quyền micro, model download/cache, cài TTS tiếng Việt ngoại tuyến, chất lượng nhận giọng và luồng submit trên Android/iOS thật.
- Câu trả lời số/giờ dùng parser xác định; khi không rõ, người dùng có thể nói lại, nhập, chạm lựa chọn hoặc chuyển sang onboarding chạm.
- M01 device/sandbox verification không được nâng bởi analyzer hoặc build cục bộ.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: voice mode cập nhật dữ liệu qua controller hiện có, không tạo nhánh lưu hoặc consent thứ hai; các trường tùy chọn và routine conditional đều có prompt riêng.
- Mức độ hoàn thành: source, UI, quyền iOS và tài liệu đã cập nhật; APK build thành công trên source mới nhất, thiết bị chưa xác minh.
- Bằng chứng hiện có: targeted analyzer, formatter, diff check, APK debug build.
- Tối ưu phiên sau: bắt đầu bằng API shape của `record`/Whisper hiện có để tránh tạo gateway speech-to-text dùng mạng cho dữ liệu onboarding.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`.
