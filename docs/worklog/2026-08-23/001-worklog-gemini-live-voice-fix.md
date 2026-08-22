# Worklog — Sửa Gemini Live Voice và chuẩn bị nghiệm thu Android

## Mục tiêu

Sửa phiên Gemini Live bị đóng ngay sau khi native audio khởi tạo, giữ nguyên WIP
AI text-stream, và nghiệm thu trên Xiaomi đang kết nối khi backend có thể deploy.

## Kết quả đã hoàn tất

- Cập nhật Edge Function AuthToken v1beta: `bidiGenerateContentSetup`, field
  mask cho model/audio/system instruction, đọc credential từ `name`, và thứ tự
  quota `auth → check → mint → commit`.
- Cập nhật Flutter Live constrained WebSocket, `generationConfig`, gate
  `setupComplete`, reconnect gate, stale non-resumable handle, redacted
  diagnostics và cancellation race.
- Cứng hóa lifecycle controller và native audio (Android background/route
  fallback + `MODIFY_AUDIO_SETTINGS`; iOS background fail-safe).
- Build/cài đè APK debug thành công lên Xiaomi 220333QPG; app process chạy và
  `MainActivity` là activity foreground sau khi launch.
- Chụp/tái hiện UI sau install: token gateway trả category `notDeployed` và UI
  hiển thị thông báo tiếng Việt an toàn thay vì lỗi mạng chung chung.

## Evidence validation

| Lệnh / kiểm tra | Kết quả |
|---|---|
| `flutter analyze` 9 file voice thay đổi | PASS — 0 issues |
| `flutter test` controller + protocol + gateway | PASS — 20 tests |
| `deno test --allow-net supabase/functions/voice-live-token/handler_test.ts` | PASS — 9 tests |
| `git diff --check` | PASS |
| `:app:compileDebugKotlin` | PASS (trước build APK) |
| `flutter build apk --debug` | PASS |
| `adb install -r build/app/outputs/flutter-apk/app-debug.apk` | PASS |
| Android launch/process/foreground check | PASS |
| Xiaomi packaged permission check | PASS — `MODIFY_AUDIO_SETTINGS` có mặt |
| Unauthenticated `voice-live-token` probe | FAIL đúng chẩn đoán — HTTP 404, function chưa deploy |

## Blocker nghiệm thu end-to-end

Kiểm tra an toàn trong terminal Codex cho thấy `SUPABASE_ACCESS_TOKEN`,
`SUPABASE_PROJECT_REF` và `GEMINI_API_KEY` đều chưa có. Vì vậy không thể đặt
Edge secret hoặc deploy `voice-live-token` mà không tự ý đọc/copy secret từ file
local. APK đã được cài, nhưng chưa thể khẳng định người dùng nói chuyện được cho
đến khi backend mới được deploy và có một lượt nói thật trên máy.

Kiểm tra chỉ-presence sau đó cho thấy `.env` có `SUPABASE_URL`,
`SUPABASE_ANON_KEY` và `GEMINI_API_KEY`, nhưng không có credential deploy
`SUPABASE_ACCESS_TOKEN`/project ref. URL được dùng duy nhất cho probe 404; không
đọc hoặc ghi giá trị secret ra log/chat.

`powershell`/`pwsh` cũng không có trong môi trường, nên chưa thể chạy tool bắt
buộc `.codex/tools/update_worklog_learning.ps1`; không chỉnh tay các file history
được sinh tự động.

## Bước tiếp theo có điều kiện

1. Cấp ba biến trên vào environment của terminal Codex (không gửi secret qua
   chat), rồi deploy secret và function với JWT verification bật.
2. Mở app đã cài, đăng nhập tài khoản test còn quota, chấp nhận consent Gemini
   và nói tiếng Việt nhiều lượt.
3. Xác nhận transcript input, audio Nabi, chen lời, pause/resume, Stop,
   background và network reset; ghi kết quả pass/fail riêng.

## Self-review

- Chất lượng: sửa đúng đường lỗi đã quan sát (token/WebSocket) thay vì che bằng
  retry native audio; protocol mới có test cho handshake và stale async.
- Hoàn thành: source, unit test, Kotlin compile, APK install và app launch hoàn
  tất; deploy/hội thoại thật chưa thể thực hiện vì credential không hiện diện.
- Evidence: tất cả kết quả trên là lệnh đã chạy trong phiên; không suy diễn
  acceptance iOS hoặc end-to-end từ unit test.
- Hiệu quả context: chỉ đọc workflow bugfix/domain AI cần thiết, không quét WIP
  text-stream hay `.env`.
- Tối ưu phiên sau: cung cấp environment deploy trước lúc build để có thể deploy
  và smoke cùng một phiên, đồng thời chuẩn bị thiết bị/Xcode riêng cho iOS.
