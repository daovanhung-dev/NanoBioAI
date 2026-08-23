# Worklog — Sequential Voice Plus

## Mục tiêu

Thay toàn bộ Gemini Live/full-duplex bằng hội thoại giọng nói tuần tự tối giản:
`speech_to_text -> voice-chat-turn -> Gemini REST -> flutter_tts`. Chỉ user
Plus/FamilyPlus đúng phiên được dùng; Voice không trừ quota NanoBio và Gemini
key không nằm trong luồng Flutter Voice.

## Thay đổi hoàn tất

- Khôi phục auth route + `AiVoiceAccessGate` fail-closed. Guest về login; Free
  thấy CTA Plus; loading/error/null/anonymous/user mismatch không mount page,
  controller hoặc micro; đổi account làm mới access.
- Viết lại controller thành `idle -> listening -> thinking -> speaking ->
  listening`. STT được stop trước backend, TTS được await hoàn tất và có khoảng
  chờ 300 ms trước lượt mới.
- Stop/background/route dispose tăng generation trước khi cancel STT/TTS; late
  backend response không được phát, restart micro hoặc ghi history trở lại.
- Thêm repository giữ tối đa 12 message/6 lượt trong RAM và datasource chỉ gọi
  Edge Function `voice-chat-turn`.
- Edge Function xác thực JWT, đọc `effective_user_access` dưới caller JWT, chỉ
  nhận Plus/FamilyPlus rồi mới gọi Gemini `generateContent`; không quota, không
  persistence và không log transcript/history/key/raw response.
- Tối giản UI còn trạng thái, transcript cuối, câu trả lời cuối, nút Bắt đầu/
  Dừng và liên kết Nhập chữ.
- Xóa Gemini Live protocol/gateway/events/tests, custom Android/iOS PCM bridge,
  Live diagnostics/chunker, `voice-live-token`, permission Live-only và
  `GEMINI_LIVE_MODEL`. Giữ Android runtime-config bridge cho AI Chat chữ,
  `RECORD_AUDIO`, speech/TTS declarations và iOS usage descriptions.
- Cập nhật DD M07 bằng `AI_CHAT-F03/FN03/V03/API03`, feature/deploy guide và
  checklist implementation evidence.

## Validation đã chạy

| Kiểm tra | Kết quả |
|---|---|
| Targeted `dart format` | PASS |
| Targeted `flutter analyze` | PASS — 0 issue |
| Voice/access/V1+V2 guest route/AppEnv targeted tests | PASS — 43 tests |
| Deno 2.9.5 `fmt --check`, `check`, `lint` | PASS |
| Deno `handler_test.ts` | PASS — 13 tests |
| Static scan Live/PCM/client Voice key/copy nói chen | PASS — không còn source runtime reference |
| `flutter build apk --debug` | PASS — `build/app/outputs/flutter-apk/app-debug.apk` |
| `git diff --check` | PASS |

`architecture_version_boundary_test.dart` vẫn có 1 test fail vì ba bridge V1→V2
có sẵn ngoài phạm vi Voice (`nutrition_profile_providers.dart`,
`membership_upgrade_card.dart`, `water_tracking_page.dart`). Voice gate bridge
đã được khai báo intentional và controller Voice không còn import layer V2.

## Chưa nghiệm thu

- Không deploy Supabase sandbox vì môi trường không có Supabase CLI, project ref
  và access token được cấp cho task.
- Chưa smoke Guest/Free/Plus/FamilyPlus hoặc hội thoại tiếng Việt nhiều lượt
  trên thiết bị Android thật.
- Chưa build Xcode hoặc smoke iPhone vì môi trường hiện tại không phải macOS.
- `powershell`/`pwsh` không có nên chưa chạy
  `.codex/tools/update_worklog_learning.ps1`; không chỉnh tay generated history.

## Bảo mật và dữ liệu

- Không đọc/in/log/copy giá trị secret từ `.env`.
- Không sửa `docs/supabase/config.sql`, không thêm bảng/RPC/quota và không deploy
  production.
- History chỉ ở RAM và bị xóa khi Start phiên mới, Stop, background, rời trang
  hoặc provider dispose.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - luồng tuần tự nhỏ, typed failure, backend enforcement
  và cleanup Live/PCM khớp cùng một contract.
- Muc do hoan thanh task: hoàn tất source, tests, Android build và deploy guide;
  sandbox/device/iOS acceptance còn pending đúng giới hạn môi trường.
- Bang chung kiem chung: targeted analyze 0 issue, 43 Flutter tests, 13 Deno
  tests, Android debug build và static/diff scans PASS.
- Diem ton token/chua toi uu: worktree có nhiều WIP Supabase/payment không liên
  quan nên cần target file và phân biệt baseline architecture failure.
- Cach toi uu cho phien sau: deploy function trước, chạy access/error matrix,
  sau đó smoke hai lượt tiếng Việt với Stop/background trên Android và iPhone.
- Task-skill can doc lan sau: `.codex/task-skills/coding.md`
