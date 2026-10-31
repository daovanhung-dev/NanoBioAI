# Features — NABI_ESP_ASSISTANT

Nguồn: kế hoạch tích hợp do người dùng duyệt trong phiên 2026-10-23. Tất cả feature nghiệp vụ đang Draft; chỉ preview trung thực được phép chạy trước review.

## NABI_ESP_ASSISTANT-F01 — Entry và trang preview Android

- Actor: mọi người dùng Android có thể mở preview; cần đăng nhập trước khi bắt đầu lượt có câu trả lời AI.
- Trigger: Feature Hub → “Sắp ra mắt” → “Nabi - Siêu trợ lý AI”.
- Hiện có: tile Android và trang thông tin; tile ẩn trên iOS; chưa mở thiết bị.
- Acceptance: hiện trạng thái chờ Tech/QA/Privacy; nêu firmware cần nạp USB; không gọi permission/native API/server.
- Function/View: FN01, V01.

## NABI_ESP_ASSISTANT-F02 — Chuẩn bị nhận dạng lời nói và voice local

- Kỳ vọng: tải Whisper tiếng Việt theo yêu cầu nếu chưa có; chọn voice TTS offline. Không nạp model văn bản cục bộ.
- Gate: chỉ cho phép khởi tạo kết nối khi Whisper và voice TTS sẵn sàng; câu trả lời yêu cầu Internet và phiên đăng nhập NanoBio.
- Acceptance: trạng thái sẵn sàng lấy từ runtime thật; lỗi tải Whisper/voice có cách thử lại; không tải model trong test.
- Trạng thái: Draft / chưa triển khai cho ESP. Function: FN02.

## NABI_ESP_ASSISTANT-F03 — Hotspot riêng và foreground service

- Kỳ vọng: Android LocalOnlyHotspot tự sinh SSID/password; service `connectedDevice` giữ hotspot/server và notification có thao tác dừng.
- Acceptance: xử lý từ chối quyền, hotspot bận/không hỗ trợ, địa chỉ/gateway đổi, khóa màn hình và dừng notification.
- Trạng thái: Draft / chưa triển khai. Function: FN03.

## NABI_ESP_ASSISTANT-F04 — BLE ghép đôi và cấp cấu hình

- Kỳ vọng: Espressif provisioning Security 2, mã dùng một lần 8 số (2 phút), thiết lập khóa thiết bị; gửi Wi-Fi hotspot qua endpoint BLE tùy chỉnh.
- Acceptance: credential chỉ đi trên BLE được mã hóa; token ghép thiết bị lưu bằng secure storage/NVS; xóa/đổi thiết bị có vòng đời được định nghĩa. Chưa hứa khóa sau 5 lần sai.
- Trạng thái: Source implementation started; Tech/Privacy và device test pending. Function: FN04.

## NABI_ESP_ASSISTANT-F05 — Phiên XiaoZhi HTTP/WebSocket v3

- Kỳ vọng: hợp đồng sinh chung, protocol v3, cổng 8386, `/nabi/ota/`, `/nabi/v1/`; host ESP tính từ DHCP gateway; device key cho OTA và Bearer auth theo phiên; tối đa một ESP.
- Acceptance: token sai 401, kết nối thứ hai bị từ chối, server dừng thì ESP không được tiếp tục; host không hard-code.
- Trạng thái: Source implementation started; device exchange pending. Function: FN05.

## NABI_ESP_ASSISTANT-F06 — Nhận dạng lời nói local, trả lời qua backend và điều khiển nghe

- Kỳ vọng: Opus 16 kHz → Whisper vi trên điện thoại → authenticated NanoBio AI API → TTS offline → Opus 24 kHz. History tối đa 6 lượt ở RAM.
- Điều khiển: `nabi.control` với `listen.start`/`listen.stop` và `nabi.control_ack` có `request_id`.
- Acceptance: xử lý luân phiên, hủy sạch khi ngắt socket; không log/lưu audio, transcript, prompt, response hoặc token; cần Internet và đăng nhập để tạo câu trả lời.
- Trạng thái: App/firmware handlers implemented in source; audio/device test and Tech/QA/Privacy review pending. Function: FN06, FN07.

## NABI_ESP_ASSISTANT-F07 — OSTB 3ST firmware và lần nạp ban đầu

- Kỳ vọng: profile XiaoZhi IDF ≥6.0.1, partition 16 MiB OTA/assets tương thích, mã ghép hiển thị, dynamic gateway, custom provisioning, auth header và control ack.
- Acceptance: cần nạp full firmware/partition bằng USB một lần trước kết nối; firmware demo hiện có không thể được app nâng cấp thành XiaoZhi.
- Trạng thái: Firmware implementation in source; build/flash/boot validation pending. Function: FN08.
