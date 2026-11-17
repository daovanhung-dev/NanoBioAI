# Diagrams — NABI_ESP_ASSISTANT

Luồng hiện hành là thiết lập qua Nabi rồi ESP giao tiếp voice trực tiếp với NanoBio server. Sequence chi tiết được mô tả trong [Overall](../Overall.md#3-luồng-đề-xuất).

Luồng: app đăng nhập online và mã hóa credential trong SQLite → ESP phát AP WPA2 → điện thoại nối AP, không cần mobile data → Android gửi Wi‑Fi/account credential qua API local → ESP lưu NVS rồi device-login/refresh bằng HTTPS → ESP mở WSS voice v3 → backend/worker xử lý STT, AI và TTS → app quản lý consent hoặc thu hồi thiết bị.

Các trạng thái lỗi chính: chưa đăng nhập/cached credential, chưa nối AP ESP, Wi‑Fi nhà sai, firmware contract không khớp, device credential bị thu hồi, server voice không khả dụng. Provision chờ server khi điện thoại chưa có Internet; sau khi unbind, cần provision lại từ app, không tự đăng nhập lại bằng account password.
