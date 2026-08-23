Commit de xuat: feat(ai-voice): them tuy chon toc do phan ung

# Worklog — Tùy chọn tốc độ phản ứng Voice

## Thời gian

- Ngày: 2026-08-23
- Bắt đầu: trong phiên Codex hiện tại
- Kết thúc: sau docs validation
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: coding + docs + Android device acceptance M07
- Module chính: M07 `AI_CHAT` / Sequential Voice Plus
- Yêu cầu gốc: cho người dùng chọn khoảng im lặng trước khi gửi
  turn Voice sang AI: Siêu nhanh 0,2 giây, Nhanh 0,5 giây, Bình thường
  1 giây mặc định và Chậm 2 giây.

## Đã làm

- Cập nhật feature/DD v1.6 mà không tạo feature/function/view/API ID mới:
  tiếp tục trace qua `AI_CHAT-F03/FN03/V03/API03`.
- Chốt bản chất các con số là endpointing silence sau speech result
  được nhận dạng gần nhất, không phải Gemini/network response latency.
- Ghi contract native listen bắt đầu với `pauseFor: null`; gateway chỉ arm
  200/500/1.000/2.000 ms sau partial non-empty đầu tiên; final result vẫn
  kết thúc turn ngay.
- Ghi UI dropdown **Tốc độ phản ứng**, helper copy, default 1 giây và
  quy tắc khóa control trong starting/listening/thinking/speaking/stopping.
- Ghi selection chỉ ở `AiVoiceState` RAM: giữ qua Stop/Start trong cùng
  page/controller, không lưu SQLite/Supabase/env và reset 1 giây khi page/
  controller được tạo lại.
- Thêm controller/widget/MethodChannel regression tests cho mapping, default,
  selection RAM, delayed arm và native settle; `AI_CHAT-TC15..TC17` PASS.
- Build/install APK mới và re-smoke trên Xiaomi `220333QPG`: dropdown đủ bốn
  mức, Siêu nhanh không tự đóng mic trước speech, STT→Gemini→TTS→STT chạy đúng,
  selector khóa/persist đúng và Stop trong TTS ngắt an toàn.

## File code/docs đã sửa

- `lib/app_versions/v1/features/ai_voice/domain/entities/ai_voice_state.dart` -
  thêm bốn reaction speed và default 1 giây.
- `lib/app_versions/v1/features/ai_voice/presentation/controllers/ai_voice_controller.dart`
  - truyền selection vào từng lượt và khóa setter khi session chạy.
- `lib/app_versions/v1/features/ai_voice/presentation/pages/ai_voice_page.dart`
  - thêm dropdown/helper copy, disable khi active.
- `lib/app_versions/v1/features/ai_voice/data/gateways/speech_to_text_gateway.dart`
  - delayed arm threshold sau partial non-empty đầu tiên.
- `test/app_versions/v1/features/ai_voice/` - thêm mapping, Stop/Start
  persistence, widget lock và concrete MethodChannel endpointing tests.
- `docs/features/ai-voice/001-feature-plus-half-duplex-voice.md` - sửa -
  contract, UI, lifecycle, test matrix và acceptance tốc độ phản ứng.
- `docs/DD/ai_chat/README.md` - sửa - nâng summary M07 lên v1.6.
- `docs/DD/ai_chat/Overall.md` - sửa - thêm `AI_CHAT-BR10`, ADR, risk,
  trace và evidence backlog.
- `docs/DD/ai_chat/List_Features.md` - sửa - luồng F03 và
  `AI_CHAT-TC15..TC17`.
- `docs/DD/ai_chat/Function_List.md` - sửa - input/state/gateway contract cho
  `AI_CHAT-FN03`.
- `docs/DD/ai_chat/Views.md` - sửa - dropdown, enabled states và interaction
  mapping cho `AI_CHAT-V03`.
- `docs/DD/ai_chat/Import_File.md` - sửa - dependency/file/config/test mapping.
- `docs/DD/ai_chat/Implementation_Delta_2026-08-23_Sequential_Voice_Plus.md`
  - sửa - reaction-speed addendum và evidence gate.
- `docs/DD/ai_chat/history/CHANGELOG.md` - sửa - ghi v1.6.
- `docs/checklist/checklist_complete_DD.md` và
  `docs/checklist/checklist_task_coding.md` - sửa - ghi source/test/device
  evidence PASS, giữ iOS và Chat quota sandbox ở backlog.
- `docs/worklog/2026-08-23/008-worklog-ai-voice-reaction-speed-docs.md` - tạo -
  worklog docs-context này.

## Tài liệu liên quan

- `docs/worklog/2026-08-23/007-worklog-ai-voice-client-only-device-runtime.md`
- `docs/fixbug/ai-voice-sequential/001-fixbug-ai-voice-sequential-device-runtime.md`
- `.codex/workflows/docs-context.md`
- `.codex/domains/ai-service.md`

## Commands

- Targeted stale-reference/trace scan: PASS - không còn contract M07 hiện hành
  cố định endpointing 2 giây; trace 200/500/1.000/2.000 ms và
  `AI_CHAT-TC15..TC17` hiện diện trong feature/DD/checklist.
- Dart format: PASS — 21 file, 0 file cần đổi ở validation gate cuối.
- Expanded targeted Flutter tests: PASS — 86/86.
- Targeted Flutter analyze: PASS — 10 item, 0 issue.
- `flutter build apk --debug`: PASS.
- `adb install -r build/app/outputs/flutter-apk/app-debug.apk`: PASS trên Xiaomi
  `220333QPG` (`12b304f9`).
- Android reaction-speed smoke: PASS — default/dropdown, Siêu nhanh delayed arm,
  Gemini/TTS/re-listen, selector lock/persistence, safe network retry và Stop
  trong TTS; không `concurrent startListening` hoặc STT/TTS overlap.
- `git diff --check`: PASS.
- `.codex/tools/update_worklog_learning.ps1`: BLOCKED - môi trường không có
  `powershell`/`pwsh`; không sửa generated history/task-skill bằng tay.

## Lỗi/Rủi ro

- Đã fix trong docs: phân biệt endpointing silence với Gemini response
  latency, tránh hứa sai rằng AI sẽ trả lời trong 0,2/0,5/1/2 giây.
- Một lượt device smoke dừng an toàn khi Wi-Fi phát sinh
  `SocketException/Broken pipe`; retry sau khi Android báo mạng phục hồi đã
  hoàn tất Gemini/TTS và tự nghe tiếp. Đây là external network failure, không
  phải regression endpointing.
- Giới hạn còn lại: threshold được tính từ recognition-result event, không phải
  raw PCM; OS final sớm hơn vẫn thắng. Key-in-APK/client-gate risk và iOS pending
  không thay đổi.

## Tỷ lệ hoàn thành

- Hoàn thành: source, regression tests, feature/DD/checklist/worklog, Android
  build/install và reaction-speed device acceptance.
- Đang dở: iOS vẫn chờ macOS/iPhone; Chat quota sandbox không thuộc delta này.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - source/UI/gateway thống nhất bốn giá trị, delayed arm
  tránh cắt mic trước speech và tài liệu không nhầm endpointing với AI latency.
- Mức độ hoàn thành task: hoàn tất Android source, test, build/install và device
  acceptance; iOS được ghi pending đúng giới hạn môi trường.
- Bằng chứng kiểm chứng: format sạch, analyze 10 item/0 issue, 86/86 tests,
  Android build/install, log + màn hình Xiaomi smoke và `git diff --check` PASS.
- Điểm tốn token/chưa tối ưu: M07 trace nằm ở nhiều file; đã giảm
  đọc rộng bằng grep theo ID và chỉ mở section F03/FN03/V03/API03.
- Cách tối ưu cho phiên sau: giữ một evidence block chuẩn theo TC15..TC17 và
  chỉ cập nhật checklist/worklog từ block đó sau validation cuối.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`
