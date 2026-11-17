Commit de xuat: feat(nabi-esp): provision ESP OSTB qua server NanoBio

# Nabi - Siêu trợ lý AI kết nối ESP OSTB 3ST

## Trạng thái

PO intent đã được duyệt theo kế hoạch người dùng ngày 2026-11-17. App đăng nhập online trước khi cấu hình, lưu credential mã hóa tới khi logout; sau đó người dùng nối AP WPA2 của ESP và gửi Wi‑Fi cùng account credential qua API local. Không cần dữ liệu di động trong bước AP. ESP lưu account credential trong NVS, tự vào Wi‑Fi và xác thực qua HTTPS device-login trước khi dùng voice trực tiếp với NanoBio server. Tính năng vẫn Draft và release-gated; Tech, QA, Privacy chưa sign-off.

## Trải nghiệm

Người dùng đăng nhập Nabi thành công khi điện thoại có Internet. Khi nối vào AP WPA2 `Nabi-xxxx`, người dùng nhập SSID/password Wi‑Fi 2.4 GHz; app gửi Wi‑Fi cùng account credential qua `http://192.168.4.1/nabi/provision` mà không cần mobile data. ESP lưu credential trong NVS, kết nối Wi‑Fi nhà, xác thực qua `/api/v1/iot/devices/credentials/login`, lưu refresh token và mở WSS voice v3. Backend PostgreSQL chỉ lưu Argon2 password hash; device token lưu hash.

Sau khi ghép, app hiển thị thiết bị thuộc tài khoản, cho đổi tên, bật/tắt consent, xác nhận mở dữ liệu nhạy cảm trong 5 phút hoặc thu hồi. Consent identity, profile_goals, sensitive_health và recent_tracking mặc định tắt. Thiết lập AP chỉ cho thao tác trong Android debug; release vẫn khóa.

## Kiến trúc

- App Nabi lưu account credential đã mã hóa trong SQLite bằng Android Keystore và quản lý thiết bị qua API đăng nhập.
- ESP lấy access/refresh token từ server; access token chỉ giữ RAM, refresh token xoay vòng và lưu trong NVS.
- ESP gửi voice tới NanoBio server qua WSS; STT, AI và TTS ở server; app không relay audio.
- Speech worker chạy nội bộ trên loopback. Audio/transcript không được ghi vào log hoặc file.
- Cloud contract/profile tách biệt với local phone-AI contract và config.local-ai.json.

## Trạng thái source và acceptance

- Flutter page/runtime, Android local/crypto bridge, backend device-login source/test và OSTB cloud firmware profile có source.
- Flutter analyze, backend focused tests/Ruff/mypy, Android debug build và ESP-IDF build pass. Device-login endpoint đã deploy trong release riêng; service active, health/OpenAPI pass.
- Firmware cloud v4 đã được ghi app-only vào OTA0, xác minh hash và boot vào chế độ AP; NVS, OTA metadata, partition table, bootloader, assets và eFuse không bị ghi. APK chưa chạy trên điện thoại nên provisioning/login/voice E2E còn chờ.
- Chưa nghiệm thu qua điện thoại: AP/Wi‑Fi/account exchange, device-login/refresh/revocation, WSS voice round trip, consent, reconnect, mất Internet và TTS ra loa ESP.
- Release gate chỉ mở sau Tech, QA, Privacy sign-off và acceptance trên OSTB 3ST thật.

## Tài liệu

- [DD Overall](../../DD/nabi_esp_assistant/Overall.md)
- [DD Features](../../DD/nabi_esp_assistant/List_Features.md)
- [Worklog triển khai credential](../../worklog/2026-11-17/003-worklog-nabi-account-credential-setup.md)
- [Worklog build và nạp cloud v4](../../worklog/2026-11-18/001-worklog-nabi-esp-cloud-v4-flash.md)
