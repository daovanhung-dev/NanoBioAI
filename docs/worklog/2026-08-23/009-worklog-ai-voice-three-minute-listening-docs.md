Commit de xuat: docs(ai-voice): ghi contract nghe moi luot toi da ba phut

# Worklog — Voice nghe mỗi lượt tối đa 3 phút

## Thời gian

- Ngày: 2026-08-23
- Bắt đầu: trong phiên Codex hiện tại
- Kết thúc: sau docs validation
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: docs-context hỗ trợ coding M07
- Module chính: M07 `AI_CHAT` / `AI_CHAT-F03` Sequential Voice Plus
- Yêu cầu gốc: tăng thời lượng lắng nghe một lượt lên tối đa 3 phút, đồng thời
  giữ các mức im lặng 0,2/0,5/1/2 giây có thể kết thúc và gửi câu sớm hơn.

## Đã làm

- Nâng DD M07 từ v1.6 lên v1.7, tiếp tục dùng trace hiện có
  `AI_CHAT-F03/FN03/V03/API03` và thêm `AI_CHAT-BR11/ADR05/TC18`.
- Chốt `listenFor = 180.000 ms` là hard cap mỗi lượt ở app/plugin, thay hard cap
  60 giây; final result, endpointing, Stop/lifecycle/error hoặc recognizer OS
  vẫn có thể kết thúc sớm hơn.
- Ghi rõ không cam kết raw audio liên tục hoặc recognizer luôn chạy đủ đúng 3
  phút trên mọi Android/iOS.
- Nới user transcript và mỗi history item Voice từ 2.000 lên 6.000 ký tự để
  hỗ trợ lượt nói dài; giữ Gemini response tối đa 2.000 ký tự và
  `maxOutputTokens = 256`.
- Định nghĩa acceptance `AI_CHAT-TC18`: input 3.000 ký tự accepted, input/history
  item trên 6.000 rejected, response trên 2.000 rejected; final/endpointing vẫn
  kết thúc sớm; Android build/install và compatibility smoke qua mốc 60 giây.
- Nhận evidence từ implementation owner: gateway/controller truyền 3 phút,
  MethodChannel nhận 180.000 ms; input/history bound 6.000 Unicode character,
  input 3.000 accepted, 6.001 rejected, response >2.000 rejected và
  `maxOutputTokens = 256` giữ nguyên. Expanded targeted suite 90/90 PASS,
  analyze 10 item/0 issue và format 21 file/0 changed.
- Android debug APK build PASS và `adb install -r` thành công trên Xiaomi
  `220333QPG` (`12b304f9`). Giữ continuity smoke qua mốc 60 giây ở trạng thái
  pending. Reaction-speed evidence cũ vẫn PASS nhưng không được dùng để claim
  thay cho duration delta.

## File code/docs đã sửa

- `docs/features/ai-voice/001-feature-plus-half-duplex-voice.md` - sửa - contract,
  text bounds, test matrix và acceptance duration 3 phút.
- `docs/fixbug/ai-voice-sequential/001-fixbug-ai-voice-sequential-device-runtime.md`
  - sửa - hướng runtime và regression gate mới.
- `docs/DD/ai_chat/README.md` - sửa - summary DD v1.7.
- `docs/DD/ai_chat/Overall.md` - sửa - `AI_CHAT-BR11`, `AI_CHAT-ADR05`, trace và
  evidence backlog.
- `docs/DD/ai_chat/List_Features.md` - sửa - F03 contract và `AI_CHAT-TC18`.
- `docs/DD/ai_chat/Function_List.md` - sửa - input/output/listen duration của
  `AI_CHAT-FN03`.
- `docs/DD/ai_chat/Views.md` - sửa - interaction/acceptance của `AI_CHAT-V03`.
- `docs/DD/ai_chat/Import_File.md` - sửa - gateway/datasource/test mapping.
- `docs/DD/ai_chat/Implementation_Delta_2026-08-23_Sequential_Voice_Plus.md` -
  sửa - addendum hard cap 3 phút và text bounds.
- `docs/DD/ai_chat/history/CHANGELOG.md` - sửa - thêm v1.7.
- `docs/checklist/checklist_complete_DD.md` và
  `docs/checklist/checklist_task_coding.md` - sửa - ghi contract/source/test/
  build/install hoàn tất nhưng >60-second device continuity pending.
- `docs/worklog/2026-08-23/009-worklog-ai-voice-three-minute-listening-docs.md` -
  tạo - worklog docs-context hiện tại.

## Tài liệu liên quan

- `docs/worklog/2026-08-23/008-worklog-ai-voice-reaction-speed-docs.md`
- `.codex/workflows/docs-context.md`
- `.codex/domains/ai-service.md`

## Commands

- Targeted stale-reference/trace scan: PASS - không còn M07 contract hiện hành
  đặt hard cap STT 60 giây; `BR11/ADR05/TC18`, 180.000 ms và text bounds hiện
  diện nhất quán. Mọi nhắc 60 giây còn lại là baseline cũ, TTS timeout hoặc mốc
  continuity cần smoke.
- `git diff --check` scoped docs: PASS.
- `.codex/tools/validate_codex_integrity.ps1`: BLOCKED - môi trường không có
  `pwsh`; targeted docs scan và scoped `git diff --check` đã PASS.
- `.codex/tools/update_worklog_learning.ps1`: BLOCKED - môi trường không có
  `pwsh`; không sửa generated history/task-skill bằng tay.
- Dart format: PASS - 21 file, 0 changed.
- Targeted Flutter analyze: PASS - 10 item, 0 issue.
- Expanded targeted Flutter tests: PASS - 90/90; cover 180.000 ms ở
  MethodChannel/controller, input 3.000 accepted, 6.001 rejected và response
  >2.000 rejected.
- `flutter build apk --debug`: PASS.
- `adb install -r build/app/outputs/flutter-apk/app-debug.apk`: PASS trên Xiaomi
  `220333QPG` (`12b304f9`).
- Android >60-second device continuity smoke: PENDING; worklog này chưa claim
  recognizer thực tế tiếp tục qua mốc 60 giây.

## Lỗi/Rủi ro

- Đã xử lý trong docs: phân biệt hard cap app/plugin với khả năng thực tế của
  speech recognizer hệ điều hành; không hứa mic/raw audio luôn chạy đủ 3 phút.
- Đã verify ở source/test: 180.000 ms và text bounds đúng contract.
- Cần kiểm tra tiếp: Android device continuity smoke qua mốc 60 giây; iOS vẫn
  cần macOS/iPhone riêng.

## Tỷ lệ hoàn thành

- Hoàn thành: feature/DD/fixbug/checklist/worklog contract cho delta 3 phút.
- Đang dở: Android >60-second continuity evidence của `AI_CHAT-TC18`; iOS acceptance.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - contract nêu rõ hard cap, đường kết thúc sớm, text
  bounds và giới hạn nền tảng, tránh lời hứa sai trên thiết bị thật.
- Mức độ hoàn thành task: hoàn tất docs scope; source/test/build/install đã được
  cập nhật theo evidence, còn >60-second device continuity pending đúng phân
  công và không suy diễn từ acceptance reaction speed cũ.
- Bằng chứng kiểm chứng: expanded 90/90 tests, analyze 10 item/0 issue, format
  21 file/0 changed, Android debug build và Xiaomi install PASS từ implementation
  owner; targeted docs scan và `git diff --check` sẽ được ghi sau khi chạy.
  >60-second device continuity evidence còn thiếu.
- Điểm tốn token/chưa tối ưu: DD M07 phân tán qua nhiều file; đã tiết kiệm bằng
  grep theo `AI_CHAT-F03/BR11/ADR05/TC18` và chỉ đọc section liên quan.
- Cách tối ưu cho phiên sau: cập nhật một lần từ evidence block TC18 của root,
  rồi đồng bộ trạng thái ở delta, hai checklist và worklog thay vì scan rộng.
- Task-skill cần đọc lần sau: `.codex/task-skills/docs-context.md`
