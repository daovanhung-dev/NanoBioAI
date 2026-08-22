# Fixbug — Gemini Live Voice đóng phiên ngay sau khi mở audio

## Trạng thái

Code fix và APK Android đã được xác minh; nghiệm thu hội thoại thật còn chờ
credential deploy được cấp vào terminal chạy Codex. Không coi đây là production
acceptance cho tới khi Edge Function được deploy và người dùng nói thử trên máy.

## Hiện tượng và nguyên nhân

Trên Xiaomi 220333QPG, `AudioRecord` và `AudioTrack` được tạo thành công nhưng
được giải phóng sau khoảng 0,45 giây, trước khi có PCM input. Điều này loại trừ
micro/native audio là nguyên nhân chính và chỉ ra phiên Gemini Live bị thất bại
ở token/WebSocket.

Hai lỗi protocol được sửa:

- Edge Function gửi AuthToken theo shape cũ (`lock` và credential `token`) thay
  vì `bidiGenerateContentSetup` và credential `name` của API v1beta.
- Flutter mở native capture trước khi server trả `setupComplete`; một setup lỗi,
  reconnect hoặc stop trong lúc đang kết nối có thể để lại race lifecycle.

### Theo dõi trên Xiaomi

Sau khi cài APK sửa protocol, thao tác **Bắt đầu trò chuyện** vẫn dừng ngay tại
token gateway. Probe `POST /functions/v1/voice-live-token` không có JWT trả
`404`, trong khi một function đã deploy với JWT verification phải trả `401`.
Điều này xác nhận function chưa được deploy lên project hiện dùng; micro và
Gemini WebSocket chưa được gọi trong lần tái hiện này.

## Cách sửa

- `voice-live-token` xác thực JWT, kiểm tra quota, mint AuthToken, rồi mới
  commit quota. Request khóa model/audio/system instruction qua
  `fieldMask: model,generationConfig,systemInstruction`; response chỉ trả
  ephemeral credential `name` và expiry.
- Gateway dùng endpoint `BidiGenerateContentConstrained?access_token=…`, đặt
  `responseModalities` trong `generationConfig`, chỉ subscribe capture/gửi PCM
  sau `setupComplete`, và áp dụng lại điều kiện này khi reconnect.
- Khi server đánh dấu `sessionResumptionUpdate.resumable: false`, gateway xóa
  handle cũ thay vì thử resume bằng credential đã hết hiệu lực sau GoAway/close.
- Generation cancellation trong controller/gateway chặn capture muộn nếu người
  dùng stop hoặc app xuống nền trong khi đang lấy token/kết nối.
- Android khai báo `MODIFY_AUDIO_SETTINGS`, giải phóng realtime audio ở
  `Activity.onStop`; route Bluetooth thiếu quyền rơi về loa. iOS thêm fail-safe
  khi app xuống nền.
- Log debug chỉ ghi category/status/type đã redaction; không ghi API key, token,
  audio hay transcript.
- Client phân loại status token an toàn: login hết hạn, quota, function `404`,
  hoặc lỗi tạm thời. Với `404`, UI báo rõ máy chủ voice chưa sẵn sàng thay vì
  gán sai nguyên nhân cho kết nối người dùng.

## Regression coverage

| Khu vực | Kiểm thử |
|---|---|
| Edge AuthToken | JWT, quota, thứ tự mint/commit, payload v1beta, `name`, redaction |
| Live protocol | constrained endpoint, setupComplete, PCM gate, interruption, reconnect, cancellation |
| Controller | explicit start, consent, lifecycle stop, pause/resume, stale startup, terminal error |
| Android | Kotlin compile; install đè và launch trên Xiaomi thật |

## Ngoài phạm vi

- Không thay đổi WIP AI text-stream/SSE.
- Không dùng lại `speech_to_text` hoặc `flutter_tts` trong realtime Live path.
- iPhone chưa được nghiệm thu vì phiên này không có Xcode/thiết bị iOS.

## Điều kiện đóng bug

Khi `SUPABASE_ACCESS_TOKEN`, `SUPABASE_PROJECT_REF` và `GEMINI_API_KEY` khả
dụng trong terminal Codex: deploy secret + `voice-live-token`, sau đó nói nhiều
lượt tiếng Việt trên Xiaomi (bao gồm chen lời, pause/resume, Stop và background)
và ghi kết quả nghiệm thu vào worklog kế tiếp.
