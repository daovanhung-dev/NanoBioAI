# Views — NABI_ESP_ASSISTANT

## NABI_ESP_ASSISTANT-V01 — Trang thiết lập/quản lý Nabi ESP

- Entry: Feature Hub → “Sắp ra mắt” → “Nabi - Siêu trợ lý AI”.
- Platform: Android; thiết lập AP chỉ chạy trong debug pilot.
- Access: người dùng có thể xem trang; ghép và quản lý yêu cầu phiên đăng nhập. Release build khóa hành động.
- Inputs: tên/mật khẩu Wi‑Fi nhà 2.4 GHz. Người dùng đăng nhập Nabi trước, rồi nối AP `Nabi-xxxx` bằng mật mã trên ESP để gửi cấu hình tại chỗ.
- Device list: tên, trạng thái kết nối, device ID, consent; hành động đổi tên, thu hồi và bật/tắt nhóm chia sẻ.
- Sensitive context: nút riêng yêu cầu xác nhận, chỉ hiện khi consent nhóm nhạy cảm đã bật và ESP đang kết nối; server giới hạn unlock 5 phút.
- Privacy copy: nói rõ app lưu account credential mã hóa trong SQLite tới logout; credential gửi qua AP WPA2 và được lưu trong ESP NVS theo yêu cầu; backend lưu Argon2 hash, không lưu password thô.
- Error states: thiếu login hoặc credential cache, chưa nối AP ESP, hợp đồng firmware không khớp, lỗi mạng local/server, đăng nhập thiết bị chưa xong và chờ điện thoại có Internet để refresh trạng thái.
- Accessibility: trạng thái có chữ/icon và màu; nội dung cuộn trên màn nhỏ.

| State | Required copy/action | Current status |
|---|---|---|
| Review pending | Nêu rằng cài đặt chỉ mở cho bản Android thử nghiệm; release đang chờ review | Có trong UI |
| Signed out | Nút đăng nhập trước khi cấu hình hoặc quản lý device | Có trong UI |
| Wi‑Fi setup | Đăng nhập online trước; nối AP ESP, nhập SSID/password Wi‑Fi nhà; không cần mobile data khi setup | Source/build pass; local AP/device acceptance pending |
| Waiting for server | Hiện ESP đã nhận cấu hình và chờ kết nối Wi‑Fi/đăng nhập server; làm mới trạng thái khi điện thoại online | Có trong source; network/device chưa test |
| Connected / listed | Hiện thiết bị và quyền chia sẻ hiện hành | Có trong source; server/device chưa test |
| Consent / sensitive unlock | Bật/tắt từng nhóm; xác nhận mở sensitive context | Có trong source; privacy/integration test pending |
| Error / revoked | Thông báo an toàn và cho thử lại/ghép lại | Có trong source; lifecycle test pending |

## Không còn là owner hiện hành

Conversation voice/audio, Whisper, TTS, LocalOnlyHotspot, Android foreground service và notification không thuộc luồng cloud assistant hiện tại. Các source native cũ có thể còn trong repo, nhưng page/runtime không được mô tả là đang sử dụng chúng.
