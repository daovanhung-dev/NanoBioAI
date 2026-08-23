Commit de xuat: fix(ai-voice): sua STT runtime va goi Gemini client-only

# Fixbug — Voice tuần tự không nghe được trên thiết bị Android

## Trạng thái

- Ngày: 2026-08-23
- Module: M07 `AI_CHAT` / `AI_CHAT-F03`
- Thiết bị tái hiện: Xiaomi `220333QPG`, Android 11
- Trạng thái hiện tại: STT/runtime và reaction speed đã nghiệm thu Android;
  delta hard cap nghe 3 phút đã PASS source, expanded 90/90 tests, analyze,
  Android build/install; continuity smoke qua mốc 60 giây còn pending. iOS vẫn
  chờ macOS/iPhone.

## Hiện tượng và nguyên nhân

Khi nhấn **Bắt đầu**, recognizer mở rồi bị hủy gần như ngay lập tức nên người
dùng không thể nói qua lại với Nabi.

Hai blocker đã được xác định:

1. `speech_to_text 7.4.0` hoàn tất `SpeechToText.listen()` mà không trả boolean;
   wrapper cũ phủ định giá trị `null`, phát sinh lỗi runtime và đi vào cleanup.
2. Voice gọi `voice-chat-turn` nhưng dự án không có backend đã deploy. Kiến trúc
   này không thể hoàn tất một turn trong môi trường người dùng hiện có.

## Hướng sửa đã chốt

- Chỉ await `SpeechToText.listen()`; không kiểm tra return như boolean.
- Dùng `androidNoBluetooth`, `ListenMode.dictation`, `vi_VN`, `listenFor` tối đa
  3 phút/180.000 ms và bốn endpointing threshold 200/500/1.000/2.000 ms, mặc định
  1.000 ms. Native listen bắt đầu với `pauseFor: null`; threshold chỉ được arm
  sau partial non-empty đầu tiên để mức 200 ms không đóng mic trước speech.
- `listenFor` là hard cap phía app/plugin, không phải thời lượng mic bắt buộc.
  Final result, endpointing, Stop/lifecycle/error hoặc recognizer của hệ điều
  hành vẫn có thể kết thúc lượt sớm hơn.
- Nới user transcript và history item Voice từ 2.000 lên 6.000 ký tự để lượt nói
  dài không bị reject bởi bound cũ. Gemini response vẫn giới hạn 2.000 ký tự và
  `maxOutputTokens = 256`.
- Chờ native recognizer về `done/notListening` trước lượt mới; start và cleanup
  đều có timeout hữu hạn để tránh `concurrent startListening`.
- Gọi Gemini REST trực tiếp từ Flutter qua `GeminiRestClient`; model resolve
  `GEMINI_CHAT_MODEL -> GEMINI_MODEL -> gemini-3.5-flash`.
- Timeout Gemini 30 giây; TTS kiểm tra tiếng Việt, await completion tối đa 60
  giây; chỉ mở mic lại sau TTS + 300 ms.
- Xóa Edge Function/Deno/config Voice; Supabase chỉ còn auth và dữ liệu quyền cho
  gate trong app.
- Giữ history RAM 6 lượt, Stop/background late-response guard và không có
  STT/TTS overlap.

## Ngoại lệ bảo mật được chấp nhận

- `GEMINI_API_KEY` lấy từ `AppEnv`; không hard-code/commit/log nhưng vẫn có thể
  bị trích xuất khỏi APK/runtime.
- Plus/FamilyPlus chỉ được enforce bởi route/page gate trong Flutter. APK bị sửa
  hoặc key bị lấy có thể bỏ qua giới hạn.
- Đây là quyết định client-only do người dùng chấp nhận. Nếu cần bảo vệ key hoặc
  enforce paid access tin cậy, phải khôi phục một backend proxy được vận hành.

## Regression và acceptance

| Hạng mục | Evidence cần có | Trạng thái |
|---|---|---|
| STT plugin contract | `listen()` trả `null` không cancel; partial/final/done, error, timeout, stop/cancel, dynamic endpointing và native settle | PASS — concrete MethodChannel gateway tests trong expanded suite 86/86 |
| Reaction speed | 200/500/1.000/2.000 ms, default 1.000 ms, selection RAM qua Stop/Start và selector khóa khi active | PASS — controller/state/widget/plugin tests + Xiaomi re-smoke |
| Turn loop | Ít nhất hai turn đúng thứ tự; không STT/TTS overlap; empty không gọi Gemini | PASS — controller/repository regression trong bundle 86 tests |
| Gemini datasource | Request/history/system/model, 30 s timeout, typed provider/config/invalid-response mapping | PASS — exact request và error-mapping tests |
| Lifecycle | Stop/background ở listening/thinking/speaking bỏ late work và không restart | PASS — unit tests; Stop/restart/background smoke Android |
| Static/build | Không còn runtime/APK `voice-chat-turn`; targeted analyze/test và Android debug build | PASS — format sạch, analyze 10 item/0 issue, 86/86 tests, debug APK build và scan sạch |
| Android device | Vietnamese multi-turn trên Xiaomi: listening → thinking → speaking → listening; Siêu nhanh delayed arm; Stop/restart/background/TTS-stop an toàn | PASS — ADB install và reaction-speed re-smoke trên Xiaomi `220333QPG`; một network failure fail-safe rồi retry thành công |
| Thời lượng/payload mỗi lượt | `listenFor = 180.000 ms`; không còn app hard cap 60 giây; final/endpointing/OS vẫn được phép dừng sớm; input 3.000 ký tự pass, 6.001 reject, response trên 2.000 reject | PARTIAL PASS — source/90 tests/analyze/build/install PASS; continuity smoke qua mốc 60 giây pending |
| iOS | Xcode build + iPhone mic/STT/TTS/background | Chưa claim; cần macOS/iPhone |

Không dùng response AI thật trong automated tests và không ghi transcript/key
vào fixture/log. Device log không có `concurrent startListening`; native
recognizer đóng microphone trước lượt kế tiếp và app trở về **Bắt đầu** sau
Stop/background. Các threshold đo khoảng lặng từ recognition-result event gần
nhất, không phải raw PCM hoặc tổng thời gian Gemini trả lời; OS final sớm hơn
vẫn được ưu tiên.
