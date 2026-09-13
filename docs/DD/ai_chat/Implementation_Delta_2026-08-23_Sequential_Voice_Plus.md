# Implementation Delta 2026-08-23 — Sequential Voice Plus Client-Only

| Thuộc tính | Giá trị |
|---|---|
| Module | M07 / `AI_CHAT` |
| Nguồn | Kế hoạch Voice client-only, tốc độ phản ứng và hard cap nghe 3 phút do người dùng phê duyệt ngày 2026-08-23 |
| IDs | `AI_CHAT-F03`, `AI_CHAT-FN03`, `AI_CHAT-V03`, `AI_CHAT-API03` |
| Trạng thái | Contract Approved; runtime/Android reaction-speed acceptance PASS; hard cap 3 phút source + expanded 90/90 tests/analyze/build/install PASS, >60-second device continuity pending; iOS pending |

## 1. Quyết định thay thế

Delta này thay thế Gemini Live/full-duplex và cả Edge Function Voice đã thiết kế
trước đó. Contract hiện hành là:

```text
speech_to_text
  -> controller (mic off)
  -> repository (history RAM <= 12 messages)
  -> Flutter datasource + GeminiRestClient
  -> Gemini REST generateContent
  -> flutter_tts
  -> wait 300 ms
  -> speech_to_text
```

Không còn `voice-live-token`, `voice-chat-turn`, custom PCM, barge-in,
mute/pause/resume hoặc reconnect Live trong phạm vi M07 Voice. Supabase chỉ phục
vụ session và đọc quyền hiệu lực; không có backend Voice.

## 2. Quyền và rủi ro client-only

- Route `/ai-voice` yêu cầu đăng nhập và không thuộc guest allowlist.
- Page/controller chỉ được mount khi access thuộc exact current user, không
  anonymous và `hasPaidAccess == true` (Plus hoặc FamilyPlus).
- Loading, error, null, user mismatch và Free đều fail-closed. Free có CTA nâng
  cấp Plus nhưng không khởi tạo micro/controller.
- Quyền được đọc từ Supabase nhưng chỉ được áp dụng trong Flutter; không có
  server kiểm tra lại trước từng request Gemini.
- `GEMINI_API_KEY` lấy từ `AppEnv` và sẽ hiện diện trong binary/runtime của app.
  `.env` chỉ ngăn commit, không ngăn trích xuất key khỏi APK.
- Đây là ngoại lệ bảo mật được người dùng chấp nhận cho kiến trúc client-only:
  APK bị sửa hoặc key bị lấy có thể gọi Gemini ngoài gate Plus/FamilyPlus.
- Không hard-code/commit key và không log transcript, history, key, URL chứa key
  hoặc raw Gemini response.

## 3. State và lifecycle

```text
idle -> listening -> thinking -> speaking -> listening
```

- Mic chỉ bật ở `listening`; phải tắt ở `thinking` và `speaking`.
- STT dùng `vi_VN`, `ListenMode.dictation`, hard cap tối đa 3 phút/180.000 ms và threshold
  endpointing do người dùng chọn.
- `SpeechToText.listen()` chỉ được await; không coi kết quả `null` là boolean.
- Controller phải chờ recognizer về `done/notListening` trước lượt mới để tránh
  `concurrent startListening`.
- Transcript rỗng không gọi Gemini. TTS hoàn tất rồi chờ khoảng 300 ms trước khi
  nghe lại.
- Permission/Gemini/TTS error dừng vòng lặp; không auto retry.
- Stop/background/dispose hủy STT/TTS, tăng operation generation, bỏ late
  response, xóa history và không tự mở micro lại.
- History tối đa 6 cặp user/model (12 message), chỉ ở RAM, xóa khi Start phiên
  mới, Stop, background hoặc rời trang.

### 3.1. Tốc độ phản ứng / endpointing

| Lựa chọn UI | Threshold im lặng | Quy ước |
|---|---:|---|
| Siêu nhanh | 0,2 giây / 200 ms | Gửi turn sau khoảng ngắt lời rất ngắn. |
| Nhanh | 0,5 giây / 500 ms | Gửi nhanh nhưng chịu được khoảng ngắt ngắn hơn. |
| Bình thường | 1 giây / 1.000 ms | Mặc định cho controller/page mới. |
| Chậm | 2 giây / 2.000 ms | Dành cho người nói có nhiều khoảng ngắt. |

- Native listen khởi động với `pauseFor: null`. Chỉ sau partial non-empty
  đầu tiên gateway mới gọi `changePauseFor` với threshold đã chọn, tránh
  mức 200 ms tự đóng mic trước khi người dùng bắt đầu nói.
- Mỗi kết quả nhận dạng mới reset bộ đếm im lặng; final result vẫn
  kết thúc ngay. Threshold được hiểu là khoảng im lặng sau speech
  result gần nhất, không phải đo biên độ raw audio.
- Các con số này không phải Gemini/network response latency. Tổng thời gian
  chờ còn phụ thuộc callback STT, hệ điều hành, mạng, Gemini và TTS.
- Selection chỉ ở `AiVoiceState` RAM: giữ qua Stop/Start khi cùng
  controller/page còn sống, không persistence và reset về **Bình thường
  1 giây** khi controller/page được tạo lại.
- Dropdown/setter chỉ enabled khi session không in-progress. Trong
  starting/listening/thinking/speaking/stopping, selection không được đổi;
  threshold của turn hiện tại là giá trị được đọc khi `listenOnce`
  bắt đầu.

### 3.2. Hard cap nghe mỗi lượt

- Mỗi lần gọi recognizer đặt `listenFor = 180.000 ms` (3 phút), thay hard cap
  60 giây trước đây.
- Đây là giới hạn trên phía app/plugin, không trì hoãn final result hoặc
  endpointing. Sau partial non-empty đầu tiên, khoảng im lặng 0,2/0,5/1/2 giây
  vẫn có thể đóng lượt và gửi transcript sớm hơn.
- Stop/background/dispose, permission/platform error và recognizer của hệ điều
  hành cũng có thể kết thúc sớm hơn. Contract không cam kết thu raw audio liên
  tục hoặc giữ một lượt đủ đúng 3 phút trên mọi Android/iOS.
- Để transcript dài không bị chặn bởi bound 60 giây cũ, user message và mỗi
  history item Voice được phép tối đa 6.000 ký tự. Gemini response vẫn phải
  non-empty, tối đa 2.000 ký tự; NanoBio không truyền `maxOutputTokens`.

## 4. AI_CHAT-API03 — Gemini client datasource

- Repository giữ contract `sendTurn(message)` và truyền history RAM cho
  datasource.
- User message/history item sau trim tối đa 6.000 ký tự; response Gemini hợp lệ
  tối đa 2.000 ký tự. Text vượt bound bị từ chối an toàn và không append history.
- Datasource gọi `GeminiRestClient.generateText` trực tiếp từ Flutter, gửi
  history `user/model` cùng message hiện tại.
- Model resolve theo `GEMINI_CHAT_MODEL -> GEMINI_MODEL -> gemini-3.5-flash`.
- System instruction giữ Nabi nói tiếng Việt ngắn gọn, không chẩn đoán thay bác
  sĩ và hướng dẫn liên hệ cấp cứu/cơ sở y tế phù hợp khi có dấu hiệu khẩn cấp.
- NanoBio không truyền `maxOutputTokens`; mỗi lượt timeout sau 30 giây.
- 408/429/network/5xx ánh xạ thành tạm thời không khả dụng; key/model/config sai
  thành Voice không khả dụng; text rỗng thành phản hồi không hợp lệ.
- Chỉ response hợp lệ mới được append đủ cặp user/model vào history.

## 5. Quota và persistence

- Không tạo bảng/RPC/quota mới và không sửa quota M06 cho Voice.
- Không check/commit `ai_chat_message` cho `AI_CHAT-F03`.
- “Không giới hạn” chỉ có nghĩa NanoBio không đặt quota Voice; giới hạn/rate
  limit của Gemini vẫn áp dụng.
- Không lưu audio, transcript hoặc history vào SQLite/Supabase.

## 6. Evidence gate

| Gate | Evidence bắt buộc | Trạng thái |
|---|---|---|
| Source baseline | Direct Gemini datasource, STT null-return/native-settle fix, TTS timeout, xóa Edge Function Voice | PASS |
| Flutter | Format, targeted analyze, controller/repository/datasource/device-gateway/reaction-speed tests | PASS — format 21 file/0 changed, analyze 10 item/0 issue, 86/86 tests |
| Android | Debug build + ít nhất hai lượt tiếng Việt trên Xiaomi `220333QPG` | PASS — build/install và ba lượt liên tục; Stop/restart/background an toàn |
| Reaction speed | Unit/widget/plugin tests cho bốn mapping, default/selection RAM, arm sau partial đầu tiên và final result | PASS — nằm trong expanded 86/86 tests |
| Android reaction re-smoke | Build/install lại; Siêu nhanh 0,2 giây, Stop → đổi mức → Start trong cùng page và multi-turn | PASS — Xiaomi `220333QPG`; delayed arm, two-turn/retry, selector lock/persistence và Stop trong TTS an toàn |
| Hard cap nghe 3 phút + text bounds | `listenFor = 180.000 ms`; final/endpointing vẫn dừng sớm; input 3.000 ký tự accepted, 6.001 rejected, response >2.000 rejected; Android compatibility smoke qua mốc 60 giây khi OS cho phép | PARTIAL PASS — source, MethodChannel/controller assertions, expanded 90/90 tests, analyze 10 item/0 issue, format 21 file/0 changed, Android build/install PASS; >60-second device continuity pending |
| Static | Không còn runtime/APK reference `voice-chat-turn`; không log secret/transcript | PASS |
| iOS | Xcode build + iPhone mic/STT/TTS/background smoke | Chưa claim; cần macOS/iPhone |

Không còn Deno, Edge Function deploy hoặc Supabase sandbox Voice gate trong
acceptance client-only. Chi tiết: [feature doc](../../features/ai-voice/001-feature-plus-half-duplex-voice.md).
