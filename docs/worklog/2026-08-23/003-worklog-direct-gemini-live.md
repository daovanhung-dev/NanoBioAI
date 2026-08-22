# Worklog — Voice Gemini Live trực tiếp, không Supabase runtime

## Mục tiêu

Loại bỏ toàn bộ phụ thuộc Supabase/Edge Function/Plus khỏi **luồng Voice** để
APK Android kết nối Gemini Live trực tiếp bằng cấu hình Gemini đã có sẵn trong
app. Giữ việc người dùng chủ động chạm **Bắt đầu trò chuyện** trước khi micro
được mở.

## Thay đổi hoàn tất

- `GeminiLiveVoiceGateway` dùng endpoint Live thường
  `BidiGenerateContent?key=…`; không còn gọi `voice-live-token`, không dùng
  `access_token`, JWT, quota hay kiểm tra gói Plus.
- Provider Voice lấy `GEMINI_API_KEY` qua `AppEnv`. Android đã có đường
  `.env`/Gradle → `BuildConfig` → Method Channel → `AppEnv`, nên build debug
  thường có cấu hình trực tiếp mà không cần deploy Edge Function.
- Route `/ai-voice` mount thẳng `AiVoicePage` và được phép cho guest. Các route
  AI/chat, membership và Supabase khác không đổi.
- Setup Live nay mang system instruction Nabi, audio output, transcript,
  automatic VAD, session resumption và `contextWindowCompression`.
- Bỏ timer cục bộ 15 phút. Sau mỗi lần resume thành công, retry budget được
  reset để các lần `GoAway` tiếp theo vẫn có thể nối lại. Gemini vẫn có giới
  hạn dịch vụ/billing ở phía nhà cung cấp.
- Thiếu cấu hình Gemini thất bại trước khi xin micro hoặc mở socket; UI chỉ báo
  lỗi cấu hình an toàn, không hiển thị key.
- Giữ native PCM Android/iOS, chờ `setupComplete`, interruption xóa playback,
  pause/resume, lifecycle stop và redacted diagnostics.

## Ràng buộc bảo mật đã chấp nhận theo yêu cầu

Direct mode vẫn bắt buộc Gemini API key, nhưng key nằm trong APK Android và
không còn cách đáng tin cậy để thực thi “chỉ Plus”. Bất kỳ người có APK đều có
thể trích key và làm phát sinh chi phí Gemini. Không có API key, token, URI có
query key, audio hoặc transcript nào được ghi vào log/worklog này.

## Validation đã chạy

| Kiểm tra | Kết quả |
|---|---|
| `dart format` 15 file thay đổi | PASS |
| targeted `flutter analyze` 15 file | PASS — 0 issues |
| `flutter test` AppEnv + Voice protocol/gateway/controller + V1 route guard | PASS — 31 tests |
| V2 guest-route regression cho `/ai-voice` | PASS |
| `flutter build apk --debug` | PASS — tạo `build/app/outputs/flutter-apk/app-debug.apk` |
| `git diff --check` | PASS tại thời điểm kiểm tra |

Suite `v2_composed_route_guard_test.dart` đầy đủ còn có lỗi baseline ngoài
phạm vi Voice: `V2RouteGuards.canAccessMembershipPayment` trong WIP hiện trả
`null`. Không sửa chồng vào luồng thanh toán/membership.

## Nghiệm thu Android thật

APK mới đã build thành công, nhưng `adb devices` không còn thấy Xiaomi
`12b304f9`; chờ 30 giây qua `adb wait-for-device` cũng không có thiết bị. Vì
vậy chưa cài APK direct mode và chưa tuyên bố người dùng đã nói chuyện thật
được. Khi thiết bị nối lại, bước còn lại là cài đè `adb install -r`, mở Voice
không đăng nhập, chạm **Bắt đầu trò chuyện**, cấp micro và xác nhận audio hai
chiều/chen lời/pause-resume/Stop.

## iOS

iOS chưa có native BuildConfig bridge cho key. Bản iOS direct cần build với
`--dart-define=GEMINI_API_KEY=…` hoặc `--dart-define-from-file=.env`; không
đưa `.env` vào asset và không ghi key vào source.

`powershell`/`pwsh` không có trong môi trường, nên chưa chạy được
`.codex/tools/update_worklog_learning.ps1`; không chỉnh tay history sinh tự
động.
