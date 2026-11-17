# DD — Nabi - Siêu trợ lý AI kết nối ESP OSTB 3ST

> Cập nhật runtime 2026-11-17: người dùng đăng nhập khi điện thoại còn Internet, sau đó nối AP WPA2 của ESP và gửi cấu hình tại chỗ; không cần dữ liệu di động trong bước này. App lưu credential đã mã hóa trong SQLite tới khi đăng xuất. ESP nhận Wi‑Fi và credential tài khoản qua HTTP trên AP WPA2, lưu trong NVS rồi đăng nhập server qua HTTPS. Cloud contract v4; voice WebSocket protocol v3.

| Thuộc tính | Giá trị |
|---|---|
| Module Code | `NABI_ESP_ASSISTANT` |
| Version | `v1.0-draft` |
| Lifecycle | `Current` |
| DD Decision | `Draft` |
| Implementation | `In Progress — AP provisioning, Android debug app, backend IoT service and OSTB cloud profile are implemented` |
| Verification | Flutter focused analyze/tests, contract check, Android/ESP-IDF builds and live server health pass; previous cloud image v3 booted on OSTB; current cloud contract v4 is not flashed; phone/voice E2E and reviews remain pending |
| Owner | `NanoBio product / mobile / backend / IoT` |
| Created / Updated | `2026-10-23 / 2026-11-17` |
| Source | `User-approved implementation plan; no separate BD exists` |

## Phạm vi

Bản thử nghiệm Android yêu cầu đăng nhập Nabi thành công trước khi kết nối Wi‑Fi `Nabi-xxxx`. Khi điện thoại ở AP, app chỉ gọi API local và không cần Internet; nó gửi Wi‑Fi cùng credential tài khoản đã mã hóa trên điện thoại tới ESP. ESP lưu credential trong NVS, kết nối Wi‑Fi nhà và xác thực account qua HTTPS device-login để nhận token riêng. Backend PostgreSQL tiếp tục lưu Argon2 password hash và chỉ lưu hash device token; không lưu password thô.

Mọi quyền chia sẻ hồ sơ/mục tiêu, dữ liệu sức khỏe nhạy cảm và theo dõi gần đây đều tắt mặc định. Mở dữ liệu nhạy cảm cần xác nhận rõ ràng và chỉ có hiệu lực 5 phút. Ứng dụng và firmware đang giới hạn ở bản thử nghiệm nội bộ; Tech, QA và Privacy chưa duyệt. Firmware đã build và nạp app-only vào OTA0; AP-to-claim và voice acceptance còn chờ.

## Tài liệu

- [Overall](Overall.md) — kiến trúc, luồng ghép tài khoản và bảo mật.
- [Features](List_Features.md) — feature và tiêu chí nghiệm thu.
- [Functions](Function_List.md) — chức năng source và giới hạn xác minh.
- [Views](Views.md) — trạng thái trang cấu hình/quản lý.
- [Import map](Import_File.md) — source app, backend và firmware.
- [Diagrams](diagrams/README.md) — luồng và vòng đời kết nối.
- [Assets](assets/README.md) — asset/copy cần thiết.
- [History](history/CHANGELOG.md) — lịch sử DD.

## Cổng phát hành

DD vẫn Draft. Bản app chỉ cho phép thao tác trên Android debug; release không thể thiết lập hoặc quản lý thiết bị cho tới khi Tech, QA và Privacy ký duyệt. APK mới và firmware cloud contract v4 đã build; device-login endpoint đã triển khai trong release backend riêng và health/OpenAPI pass. Board hiện không hiện ở serial nên firmware v4 chưa được nạp. Phone-to-AP provision, voice round trip, token rotation/revocation, consent, reconnect và mất mạng vẫn cần acceptance trên OSTB 3ST thật.
