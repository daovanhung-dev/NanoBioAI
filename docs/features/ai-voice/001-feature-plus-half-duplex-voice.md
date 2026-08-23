Commit de xuat: feat(ai-voice): cho phep nghe moi luot toi da ba phut

# Feature — Voice Plus tuần tự với Gemini client-only

## 1. Mục tiêu

Voice là hội thoại nửa song công tối giản: người dùng nói xong thì Nabi xử lý và
nói; Nabi nói xong mới mở micro cho lượt kế. Feature chỉ dành cho
Plus/FamilyPlus trong app, không dùng quota Voice NanoBio và gọi Gemini REST trực
tiếp từ Flutter.

Traceability: `AI_CHAT-F03 -> AI_CHAT-FN03 -> AI_CHAT-V03 -> AI_CHAT-API03`.

## 2. Phạm vi

### In scope

- `speech_to_text 7.4.0` nhận dạng từng câu bằng mic tích hợp.
- Datasource Flutter dùng `GeminiRestClient` hiện có để gọi `generateContent`.
- `flutter_tts 4.2.5` phát tiếng Việt và chờ completion.
- Bốn mức endpointing theo khoảng im lặng sau lời nói: **Siêu nhanh
  0,2 giây**, **Nhanh 0,5 giây**, **Bình thường 1 giây** (mặc định) và
  **Chậm 2 giây**.
- Hard cap nghe của mỗi lượt STT là **3 phút** (`listenFor = 180.000 ms`). Final
  result hoặc endpointing theo mức đã chọn vẫn kết thúc lượt sớm hơn.
- User transcript và mỗi history item Voice được nhận tối đa 6.000 ký tự để
  không cắt sai lượt nói dài; Gemini response vẫn tối đa 2.000 ký tự và 256
  output tokens.
- History RAM tối đa 6 lượt hỏi-đáp.
- Android/iOS built-in mic/speaker và lifecycle foreground/background.
- Guest/Free/Plus/FamilyPlus fail-closed access matrix trong app.

### Out of scope

- Backend/Edge Function Voice và server-side paid-access enforcement.
- Gemini Live/full-duplex, barge-in, waveform/audio streaming, custom PCM.
- Bluetooth acceptance, offline, persistent history, greeting tự động.
- NanoBio Voice quota, bảng/RPC/schema mới hoặc thay đổi
  `docs/supabase/config.sql`.

## 3. Kiến trúc

```text
AiVoiceAccessGate
  -> AiVoicePage
  -> AiVoiceController
       -> SpeechRecognitionGateway
       -> AiVoiceRepository (history RAM)
            -> VoiceChatTurnDatasource
                 -> GeminiRestClient.generateText
                      -> Gemini REST generateContent
       -> TextToSpeechGateway
```

Dependency direction: Presentation -> Controller -> Repository -> Datasource ->
Gemini client. Page/controller không gọi Gemini hoặc device plugin trực tiếp.
Supabase chỉ cung cấp session và `effective_user_access` cho gate trong app.

## 4. Access và security contract

- `/ai-voice` có auth guard và không thuộc guest allowlist.
- Gate theo dõi current auth user và effective access; chỉ mount page khi exact
  user match, không anonymous và paid access là Plus/FamilyPlus.
- Loading, fetch error, null, user mismatch và Free đều fail-closed.
- Guest chuyển tới đăng nhập. Free thấy CTA nâng cấp Plus.
- Không có backend kiểm tra lại quyền trước Gemini. Plus-only là product gate ở
  Flutter, không phải security boundary chống APK bị sửa.
- `GEMINI_API_KEY` lấy từ `AppEnv` và sẽ nằm trong app binary/runtime. `.env` chỉ
  tránh commit key; không bảo vệ key khỏi bị trích xuất khỏi APK.
- Người dùng đã chấp nhận rủi ro client-only này. Production có yêu cầu chống
  lạm dụng key hoặc enforce paid access tin cậy phải quay lại backend proxy.

## 5. Turn loop

1. Trang mở ở `idle`, micro tắt.
2. User nhấn **Bắt đầu**; controller reset history và khởi tạo STT/TTS.
3. STT dùng `SpeechToText.androidNoBluetooth`, `ListenMode.dictation`, locale
   `vi_VN` và đặt hard cap mỗi lượt là 3 phút (`listenFor = 180.000 ms`). Native
   listen khởi động với
   `pauseFor: null`; sau partial result non-empty đầu tiên, gateway mới áp
   threshold người dùng đã chọn để mức 0,2 giây không đóng mic
   trước khi họ bắt đầu nói.
4. `SpeechToText.listen()` chỉ được await; wrapper trả `null` không bị diễn giải
   thành lỗi. Controller chờ `done/notListening` trước lượt mới.
5. Final result dừng recognizer ngay. Nếu chưa có final, khoảng im lặng
   sau kết quả nhận dạng gần nhất đạt 0,2/0,5/1/2 giây theo mức
   đã chọn thì dừng và gửi transcript. Start/terminal settle dùng timeout
   hữu hạn để không kẹt hoặc gọi listen đồng thời. Hard cap 3 phút chỉ là giới
   hạn trên ở app/plugin: final result, endpointing, Stop/lifecycle/error hoặc
   recognizer của hệ điều hành có thể kết thúc sớm hơn.
6. Transcript rỗng: không gọi datasource, tiếp tục nghe nếu session còn active.
7. Transcript hợp lệ: state `thinking`, mic tắt, gọi repository/Gemini.
8. Text hợp lệ: state `speaking`, TTS đọc và controller await completion tối đa
   60 giây.
9. Chờ khoảng 300 ms; nếu operation token còn hợp lệ thì quay lại `listening`.
10. Stop/background/dispose invalidate token trước, cancel STT, stop TTS, clear
    history và về idle. Response/TTS callback đến muộn bị bỏ.

Không được có STT/TTS overlap. Gemini/TTS/permission failure đều dừng loop và
yêu cầu người dùng chủ động Bắt đầu lại.

Khoảng 0,2/0,5/1/2 giây là **thời gian endpointing sau lời nói được
nhận dạng gần nhất**, không phải thời gian Gemini phản hồi. Thời gian từ lúc
dừng nói đến lúc Nabi trả lời còn phụ thuộc callback STT, lập lịch của hệ
điều hành, mạng, Gemini và TTS.

Mốc 3 phút không cam kết thu raw audio liên tục hoặc luôn tạo một transcript dài
đúng 3 phút trên mọi thiết bị. `speech_to_text` và dịch vụ nhận dạng của Android/
iOS có thể phát final result hoặc dừng sớm hơn theo giới hạn nền tảng.

## 6. Datasource và Gemini contract

- Repository giữ interface `sendTurn(message)`; datasource nhận message cùng
  tối đa 12 history item có role `user`/`model`.
- User message và mỗi history item được trim, không nhận text rỗng hoặc dài quá
  6.000 ký tự. Gemini response sau trim phải non-empty và không quá 2.000 ký tự.
- Datasource gọi `GeminiRestClient.generateText` với bounded contents, system
  instruction Nabi và `maxOutputTokens: 256`; timeout mỗi turn là 30 giây.
- Model resolve theo `GEMINI_CHAT_MODEL`, rồi `GEMINI_MODEL`, cuối cùng
  `gemini-3.5-flash`.
- 408/429/network/5xx ánh xạ thành tạm thời không khả dụng.
- Thiếu/sai key, 401/403 hoặc model/config không dùng được ánh xạ thành Voice
  không khả dụng; response rỗng/không hợp lệ không được append history.
- Không auto retry provider. Người dùng chủ động bắt đầu lại.

## 7. Gemini và safety

- Key đọc bằng `AppEnv.maybeString('GEMINI_API_KEY')`; không hard-code hoặc
  commit giá trị thật.
- System instruction định danh Nabi, trả lời tiếng Việt ngắn gọn, không chẩn
  đoán thay bác sĩ; khi có dấu hiệu khẩn cấp phải khuyên liên hệ cấp cứu 115/cơ
  sở y tế phù hợp.
- Không log transcript, history, key, header/URL có key hoặc raw Gemini response.
  Chỉ log stage/status/error type nếu cần chẩn đoán.
- Không hiển thị raw provider error/stack trace cho người dùng.

## 8. UI

`AI_CHAT-V03` gồm trạng thái hiện tại, transcript cuối, câu trả lời cuối,
dropdown **Tốc độ phản ứng**, một nút **Bắt đầu/Dừng** và liên kết
**Nhập chữ**. Helper copy: “Nabi sẽ gửi câu hỏi khi bạn im lặng đủ thời
gian đã chọn.”

Mức chọn chỉ nằm trong `AiVoiceState` RAM: giữ qua Stop/Start khi cùng
controller/page còn sống, không lưu SQLite/Supabase/env và trở về **Bình
thường 1 giây** khi controller/page được tạo lại. Dropdown và controller
setter chỉ cho đổi khi session đã dừng; trong
starting/listening/thinking/speaking/stopping, control bị khóa và turn đang nghe
giữ nguyên threshold đã chọn khi Start.

Bỏ mute, pause/resume, nói chen, reconnect Live, greeting tự động và copy nói
rằng người dùng có thể chen lời.

## 9. Cleanup contract

- Xóa Gemini Live protocol/gateway/events, diagnostics và custom PCM cũ.
- Xóa `voice-live-token`, `voice-chat-turn`, Deno tests và block Function tương
  ứng trong `supabase/config.toml`; giữ nguyên `delete-account`.
- Giữ Android runtime-config bridge đang dùng cho AI Chat chữ.
- Giữ `RECORD_AUDIO`, speech recognition/TTS declarations và iOS mic/speech
  usage descriptions.
- Không tạo/sửa Supabase schema, RPC hoặc Voice quota.

## 10. Test matrix

### Flutter unit/plugin contract

- Hai turn tuyệt đối tuần tự; không STT/TTS overlap.
- Concrete `speech_to_text` MethodChannel test chứng minh public `listen()` trả
  `null` không gây cancel/lỗi; cover partial/final/done, empty, permission,
  platform error, timeout, stop/cancel và native settle.
- Transcript rỗng không gọi Gemini.
- Stop/background ở listening/thinking/speaking không restart; late response bị bỏ.
- Gemini config/request/history/model/timeout và mapping 408/429/network/5xx,
  key/model sai, response rỗng.
- TTS kiểm tra `vi-VN`, completion/timeout và cleanup an toàn.
- History đúng 6 lượt và xóa giữa phiên/lifecycle.
- Mapping đúng 0,2/0,5/1/2 giây; mặc định 1 giây; timeout chỉ
  được arm sau partial non-empty đầu tiên và reset theo kết quả nhận dạng
  mới; final result vẫn dừng ngay.
- `listenFor` truyền đúng 3 phút/180.000 ms; endpointing/final vẫn thắng hard
  cap và không làm thay đổi start/native-settle/concurrency contract.
- Transcript 3.000 ký tự được chấp nhận; user/history item trên 6.000 ký tự và
  Gemini response trên 2.000 ký tự bị từ chối an toàn, không append history.

### Widget/route

- Guest chuyển đăng nhập.
- Free không mount controller/micro và có CTA nâng cấp.
- Plus/FamilyPlus vào được; micro chỉ mở sau Bắt đầu.
- Loading/error/null/user mismatch fail-closed; đổi account refetch access.
- Dropdown hiển thị đúng bốn mức; selection giữ qua Stop/Start trong
  cùng page và reset 1 giây khi controller/page được tạo lại.

### Native/acceptance

- Targeted Flutter format/analyze/tests và Android debug build.
- Cài bằng `adb install -r` trên Xiaomi `220333QPG`; smoke ít nhất hai lượt tiếng
  Việt theo `listening -> thinking -> speaking -> listening`.
- Xác nhận không cancel tức thì, không `concurrent startListening`, không
  STT/TTS overlap; Stop/restart/background không tự mở mic lại.
- Static/APK scan không còn `voice-chat-turn`.
- Android reaction-speed re-smoke phải cover ít nhất mức **Siêu nhanh
  0,2 giây**, thao tác Stop → đổi mức → Start trong cùng page và vòng
  lặp nhiều lượt. Evidence 2026-08-23 đã PASS trên Xiaomi
  `220333QPG`: dropdown đủ bốn mức, delayed arm không premature cutoff,
  two-turn loop/retry an toàn, selector khóa khi active và giữ selection sau Stop.
- Duration smoke phải xác nhận build mới không còn hard cap 60 giây ở app và một
  lượt có thể tiếp tục qua mốc 60 giây khi recognizer thiết bị cho phép. Đây là
  compatibility evidence, không phải cam kết OS luôn giữ mic đủ 3 phút.
- iOS chỉ được claim sau Xcode build + iPhone smoke trên macOS.

## 11. Cấu hình client

Local config dùng file `.env` đã ignore; `.env.example` chỉ chứa placeholder:

```dotenv
GEMINI_API_KEY=<local-secret>
GEMINI_MODEL=gemini-3.5-flash
```

Không đưa key thật vào git, tài liệu, test fixture hoặc log. Khi build, key có
thể được nạp từ `.env`, `--dart-define` hoặc native runtime config theo `AppEnv`,
nhưng mọi cách client-side đều khiến key có thể bị lấy từ APK/runtime.

Tham khảo:

- [speech_to_text intermittent-use scope](https://pub.dev/packages/speech_to_text)
- [Gemini API key security](https://ai.google.dev/gemini-api/docs/api-key)
- [Gemini pricing/service limits](https://ai.google.dev/gemini-api/docs/pricing)

## 12. Trạng thái bàn giao

- DD/client-only/security-risk contract: documented.
- Edge Function Voice và Deno contract: removed from current architecture.
- Runtime Flutter fix và expanded targeted validation: PASS — format 21 file
  không đổi, analyze 10 item không issue và 86/86 tests.
- Android device acceptance: PASS — debug build/install và baseline ba lượt
  tiếng Việt trên Xiaomi `220333QPG`; Stop/restart/background an toàn.
- Reaction-speed Android re-smoke: PASS — default 1 giây, dropdown đủ bốn
  mức, Siêu nhanh delayed-arm an toàn, turn loop đúng thứ tự, không
  `concurrent startListening` hoặc STT/TTS overlap; network failure dừng an
  toàn và retry thành công sau khi kết nối phục hồi.
- Hard cap nghe 3 phút/text bounds: source + targeted validation PASS — Voice
  expanded 90/90 tests, analyze 10 item/0 issue, format 21 file/0 changed;
  gateway/controller truyền 3 phút/180.000 ms, input 3.000 ký tự accepted,
  6.001 rejected và response >2.000 rejected. Android debug build và cài APK
  trên Xiaomi `220333QPG` PASS; continuity smoke qua mốc 60 giây vẫn pending.
- iOS build/device acceptance: pending macOS/iPhone.
