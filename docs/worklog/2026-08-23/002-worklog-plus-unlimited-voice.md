# Worklog — Voice Plus không giới hạn lượt

## Mục tiêu

Đơn giản hóa Gemini Live Voice để chỉ tài khoản có gói trả phí mới dùng được,
không trừ lượt AI, không có hộp xác nhận cục bộ, và không tự mở micro khi vừa
vào trang.

## Thay đổi hoàn tất

- `voice-live-token` chỉ giữ hai điều kiện tối thiểu: Supabase JWT hợp lệ và
  `effective_user_access.membership_plan` là `plus` hoặc `family_plus`.
- Xóa toàn bộ voice-specific `check_usage_quota`, `commit_usage_quota`,
  `ai_chat_message`, request-id/session-id và lỗi hết lượt khỏi luồng cấp
  token. Gemini AuthToken ngắn hạn vẫn ở Edge Function để API key không nằm
  trong APK.
- Flutter gửi body rỗng khi xin token, phân loại `403` thành lỗi cần Plus.
- Cổng `AiVoiceAccessGate` chỉ mount trang/controller voice khi quyền trả phí
  của đúng tài khoản hiện tại đã được xác nhận. Free, lỗi mạng hoặc quyền chưa
  xác định đều fail-closed và không thể mở micro.
- Xóa SharedPreferences consent và dialog Google Gemini. Tài khoản Plus chỉ
  cần chạm **Bắt đầu trò chuyện**; lần chạm này vẫn cần thiết để không tự bật
  micro ngoài ý muốn.
- `effectiveAccessProvider` phụ thuộc identity hiện tại để không tái dùng kết
  quả quyền của tài khoản trước sau khi đổi tài khoản.

`family_plus` được cho phép như một gói Plus cấp cao hơn, đúng predicate
`hasPaidAccess` hiện có của ứng dụng.

## Validation đã chạy

| Kiểm tra | Kết quả |
|---|---|
| `deno fmt --check` Edge files | PASS |
| `deno check` Edge files | PASS |
| `deno lint` Edge files | PASS |
| `deno test --allow-net supabase/functions/voice-live-token/handler_test.ts` | PASS — 9 tests |
| `dart format` 12 Dart files | PASS |
| targeted `flutter analyze` | PASS — 0 issues |
| targeted `flutter test` voice gate/controller/protocol/gateway | PASS — 24 tests |
| `flutter build apk --debug` | PASS |
| `adb install -r` trên Xiaomi 220333QPG | PASS |
| `git diff --check` | PASS |

Đã thêm regression cho controller (bắt đầu ngay, Plus-required) và access gate
(Free khóa, Plus/FamilyPlus mở trang, lỗi quyền fail-closed).

## Kiểm tra Android thật

- Bản APK mới mở đúng trang voice cho tài khoản đang có gói Plus; không hiện
  dialog consent và micro vẫn chưa mở khi mới vào trang.
- Chạm **Bắt đầu trò chuyện** hiện ra lỗi máy chủ `notDeployed` đã được map an
  toàn sang tiếng Việt. Native capture/Gemini Live không khởi động vì Function
  chưa tồn tại ở project, không phải vì gate Plus hay micro.

## Blocker còn lại trước khi nói chuyện thật

Function trên project đang chưa deploy (probe trước đó trả HTTP 404). Terminal
hiện không có Supabase CLI, `SUPABASE_ACCESS_TOKEN` hoặc
`SUPABASE_PROJECT_REF`; `.env` chỉ có key runtime, không có credential deploy.
Flutter SDK có sẵn ngoài `PATH`, nên targeted Dart validation đã chạy; chưa
thể nghiệm thu hội thoại thật vì backend không thể deploy.

Để nghiệm thu thật cần deploy `voice-live-token` với `GEMINI_API_KEY` ở Edge,
đăng nhập tài khoản có subscription `plus`/`family_plus` active, rồi mở Voice
trên Android và chạm **Bắt đầu trò chuyện**. Không khẳng định end-to-end pass
trước các bước này.
