# Features — NABI_ESP_ASSISTANT

Nguồn: kế hoạch triển khai Nabi ESP được người dùng duyệt ngày 2026-11-17. DD vẫn Draft; source có thể chạy thử trên Android debug, còn release/device acceptance đang chờ.

## NABI_ESP_ASSISTANT-F01 — Thiết lập ESP từ Nabi

- Actor: người dùng Android đã đăng nhập.
- Trigger: đăng nhập thành công khi online, mở Nabi ESP, kết nối AP và nhập SSID/mật khẩu Wi‑Fi 2.4 GHz.
- Acceptance: chỉ Android debug mới thao tác; hiển thị tiến trình/lỗi an toàn; không log hoặc lưu mật khẩu Wi‑Fi trong app.
- Status: source có trang/runtime; focused Flutter analyze/tests và Android debug APK pass; setup trên điện thoại/thiết bị pending.

## NABI_ESP_ASSISTANT-F02 — AP cục bộ ghép và cấp Wi‑Fi

- Actor: app Nabi và ESP OSTB 3ST.
- Trigger: người dùng nối vào AP WPA2 `Nabi-xxxx` và gửi cấu hình trong app; dữ liệu di động không bắt buộc.
- Acceptance: `GET /nabi/status` và `POST /nabi/provision` chỉ đi qua Wi‑Fi ESP; app gửi Wi‑Fi và account credential đã lưu mã hóa; ESP lưu credential trong NVS và đóng AP sau khi nhận.
- Status: Dart/Kotlin/firmware source và APK build pass; board không hiện tại serial trong lượt hiện tại nên chưa nạp firmware v4 hoặc chạy phone-to-AP acceptance.

## NABI_ESP_ASSISTANT-F03 — Đăng nhập ESP và cấp credential thiết bị

- Trigger: ESP kết nối Wi‑Fi sau cấu hình.
- Acceptance: ESP đăng nhập qua HTTPS device-login bằng account credential, server kiểm tra Argon2 hash và quyền sở hữu; trả device ID/access/refresh tokens, chỉ lưu token hashes. ESP giữ account credential + refresh token trong NVS, access token trong RAM. Refresh xoay token; refresh lỗi không tự đăng nhập lại bằng mật khẩu.
- Status: API source/tests pass; endpoint triển khai trong backend release `nabi-web-20261117-01`, health/OpenAPI pass; thiết bị login/refresh E2E pending.

## NABI_ESP_ASSISTANT-F04 — Hội thoại AI trên server

- Trigger: ESP mở WebSocket voice v3 và gửi audio.
- Acceptance: HTTPS/WSS TLS; STT, AI và TTS thực hiện bởi server; không cần điện thoại duy trì kết nối hội thoại; audio, transcript và context không ghi log hoặc lưu ổ đĩa.
- Status: source backend/worker và firmware có; live voice routes/worker health verified; server round trip và loa ESP chưa được nghiệm thu.

## NABI_ESP_ASSISTANT-F05 — Quyền chia sẻ dữ liệu

- Nhóm: identity, profile_goals, sensitive_health, recent_tracking.
- Acceptance: tất cả false khi tạo thiết bị; context giới hạn theo quyền hiện hành; sensitive context chỉ gửi khi consent đang bật, thiết bị có session và người dùng vừa xác nhận thời hạn 5 phút.
- Status: backend/app source có và backend tests pass; privacy review và hardware integration pending.

## NABI_ESP_ASSISTANT-F06 — Quản lý thiết bị

- Acceptance: người dùng liệt kê, đổi tên, cập nhật consent, mở sensitive context hoặc hủy liên kết thiết bị thuộc tài khoản; revoke đóng WebSocket lease và chặn refresh tiếp theo.
- Status: UI/API source có; full backend tests và focused app service tests pass; device acceptance pending.

## NABI_ESP_ASSISTANT-F07 — Profile OSTB 3ST riêng

- Acceptance: profile cloud tách khỏi config.local-ai.json, dùng contract generator riêng và đúng board/partition đã xác minh; không ghi firmware/partition/NVS/eFuse trước khi có kế hoạch triển khai được review.
- Status: profile/source generator và ESP-IDF cloud contract v4 build pass; cloud contract v3 image trước đó đã được ghi/boot trên board, nhưng v4 chưa được flash; voice/device acceptance pending.
