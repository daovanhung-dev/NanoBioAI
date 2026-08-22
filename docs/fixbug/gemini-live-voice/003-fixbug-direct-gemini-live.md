# Fixbug — Voice đi thẳng Gemini Live, không cần Edge Function

## Hiện tượng

Trên Android, native audio đã khởi tạo nhưng phiên Voice đóng ngay vì Flutter
vẫn xin token từ `voice-live-token`. Function đó chưa deploy trên project nên
trả `404`; micro không phải nguyên nhân gốc.

## Cách sửa

- Thay constrained WebSocket dùng ephemeral token bằng Gemini Live WebSocket
  trực tiếp dùng API key.
- Bỏ token gateway, Supabase function invocation, JWT, kiểm tra membership và
  access gate khỏi runtime Voice.
- Cho guest mở `/ai-voice`; micro vẫn chỉ mở sau thao tác Bắt đầu.
- Chuyển system instruction Nabi vào setup trực tiếp, giữ audio PCM 16 kHz,
  output PCM, transcription, VAD, `setupComplete` gate, interruption và
  session resumption.
- Bỏ giới hạn 15 phút do app tự đặt, thêm sliding-window compression và cho
  phép các lần resume thành công liên tiếp.
- Khi thiếu cấu hình Gemini, fail trước native capture/socket và trả copy an
  toàn thay vì thông báo Edge/Supabase.

## Regression coverage

- Endpoint có `BidiGenerateContent` + `key`, không có `access_token`.
- PCM không gửi trước `setupComplete`, bao gồm sau reconnect.
- Interruption xóa playback đang chờ; GoAway có thể resume nhiều lần; stale
  WebSocket không thể mở capture sau Stop.
- Thiếu cấu hình không mở micro/socket; debug diagnostics không chứa key.
- Controller giữ explicit start, pause/resume, background Stop và lỗi cấu hình
  an toàn. Route V1/V2 cho phép guest vào Voice.

## Trạng thái nghiệm thu

Source, analyze, 31 test Voice/AppEnv/route liên quan và APK debug đều pass.
Thiết bị Xiaomi không còn kết nối ADB tại lúc cài APK mới, nên chưa thể khẳng
định audio hai chiều thật. Không còn blocker deploy server; chỉ cần thiết bị
kết nối lại để cài đè và nói thử.

## Rủi ro chấp nhận

Gemini vẫn xác thực API key và áp dụng quota/billing của Google. Do key được
nhúng trong APK theo yêu cầu direct mode, Plus-only không thể enforce đáng tin
cậy và key cần được hạn chế/rotate nếu bản APK bị phát tán.
