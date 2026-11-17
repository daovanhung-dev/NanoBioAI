# Overall — NABI_ESP_ASSISTANT / Nabi - Siêu trợ lý AI kết nối ESP

> Cập nhật 2026-11-18: người dùng đăng nhập Nabi khi điện thoại còn Internet, sau đó nối vào AP WPA2 của ESP và cấu hình tại chỗ; lúc gửi cấu hình không cần dữ liệu di động. App lưu credential đã mã hóa trong SQLite tới khi đăng xuất. ESP nhận Wi‑Fi cùng credential tài khoản qua HTTP trên AP WPA2, lưu trong NVS và tự đăng nhập NanoBio server qua HTTPS. Contract cloud là v4; voice WebSocket vẫn protocol v3.

## 0. Trạng thái tài liệu

| Trường | Giá trị |
|---|---|
| Mã module | `NABI_ESP_ASSISTANT` |
| DD decision | `Draft` — Tech, QA, Privacy review đang chờ |
| Implementation | `In Progress` — Android debug flow, backend device-login endpoint và firmware cloud profile có source |
| Verification | Flutter analyze, backend focused tests/Ruff/mypy, Android debug APK, ESP-IDF build và server health/OpenAPI pass; cloud v4 đã flash/hash-verify OTA0 và boot tới AP setup; app provisioning/voice E2E đang chờ |
| Nguồn yêu cầu | Kế hoạch triển khai do người dùng duyệt trong phiên 2026-11-17; chưa có BD riêng |
| Owner | PO NanoBio; Tech/QA/Privacy chưa ghi nhận |

## 1. Mục tiêu và giới hạn

Người dùng đăng nhập Nabi online trước khi bắt đầu. Sau khi điện thoại nối AP `Nabi-xxxx`, trang Nabi gửi SSID/mật khẩu Wi‑Fi nhà cùng loại tài khoản, identifier và mật khẩu tài khoản tới `http://192.168.4.1/nabi/provision`; không gọi cloud API trong lúc điện thoại chỉ còn kết nối AP. Ứng dụng lưu credential dạng ciphertext trong SQLite, khóa AES nằm trong Android Keystore, và xóa bản lưu khi đăng xuất. ESP lưu Wi‑Fi và credential tài khoản trong NVS theo yêu cầu, tự vào Wi‑Fi nhà rồi gửi credential qua HTTPS tới endpoint `/api/v1/iot/devices/credentials/login`. Backend kiểm tra Argon2 password hash sẵn có, gắn thiết bị với tài khoản và chỉ lưu hash device token. ESP dùng refresh token sau đó để kết nối voice v3 qua WSS. Audio được xử lý trên server bằng STT, AI và TTS.

Tính năng hiện vẫn là Android debug pilot. Bản release giữ thao tác thiết lập và quản lý thiết bị ở trạng thái khóa tới khi Tech, QA và Privacy sign-off. Khi điện thoại nối vào AP, không cần bật dữ liệu di động; AP chỉ cung cấp kết nối cục bộ và đóng sau khi ESP nhận cấu hình. Wi‑Fi và credential tài khoản được gửi trong mạng WPA2 cục bộ. ESP giữ credential tài khoản và refresh token trong NVS, access token trong RAM. OSTB 3ST hiện chưa bật Flash Encryption nên người có truy cập vật lý flash có thể khôi phục dữ liệu NVS.

### Ngoài phạm vi pilot

- Nạp firmware từ ứng dụng, OTA firmware qua server, hoặc ghi phân vùng/NVS/eFuse từ lượt này.
- Hội thoại qua app khi ESP ngoại tuyến, xử lý giọng nói trên điện thoại, hoặc dùng hotspot của điện thoại.
- iOS và nhiều loại board ESP. Profile hiện tại nhắm OSTB 3ST; cần xác minh cấu hình phần cứng trước khi nạp.
- Chia sẻ dữ liệu sức khỏe mặc định. Mỗi nhóm consent được người dùng bật riêng.
- Mở tính năng trong release trước khi hoàn tất các review và acceptance bên dưới.

## 2. Actor và quyền

| Actor | Quyền | Giới hạn |
|---|---|---|
| Người dùng đã đăng nhập | Thiết lập Wi‑Fi, xem/đổi tên/thu hồi thiết bị và quản lý consent | Chỉ sở hữu thiết bị đã gắn vào tài khoản; thao tác pilot chỉ có trong Android debug |
| Nabi Android | Đăng nhập online trước AP; giữ credential đã mã hóa trong SQLite; gửi Wi‑Fi và credential tài khoản tới AP local | Không cần Internet trong bước AP; không nhận device token |
| ESP OSTB 3ST | Lưu Wi‑Fi, credential tài khoản và refresh token; đăng nhập/refresh qua HTTPS; mở WebSocket giọng nói | Credential tài khoản ở NVS; chỉ nhận ngữ cảnh đã consent |
| NanoBio backend | Kiểm tra identifier/password Argon2, gắn thiết bị, quản lý consent/session và xử lý voice | Không lưu password thô; device token chỉ lưu dạng hash và không trả cho app |
| Speech worker | STT/TTS theo request server nội bộ | Lắng nghe loopback; không ghi audio/transcript vào file |

## 3. Luồng đề xuất

1. Người dùng đăng nhập thành công trên Nabi khi điện thoại có Internet. App lưu `{identifier_type, identifier, password}` đã mã hóa trong SQLite; chỉ Android Keystore giữ AES key. Mật khẩu backend tiếp tục được lưu dạng Argon2 hash trong PostgreSQL.
2. Người dùng kết nối điện thoại vào AP WPA2 `Nabi-xxxx`, nhập Wi‑Fi nhà và gửi cấu hình. Trong bước này điện thoại không cần Internet hay dữ liệu di động. Android gọi `GET /nabi/status` và `POST /nabi/provision` qua mạng Wi‑Fi của ESP, gửi SSID/mật khẩu Wi‑Fi, account identifier/password và contract version v4. ESP chỉ chấp nhận một lần trong phiên AP, lưu Wi‑Fi/account credential vào NVS rồi đóng AP.
3. ESP kết nối Wi‑Fi nhà, lấy giờ để xác minh TLS và gọi `POST /api/v1/iot/devices/credentials/login` qua HTTPS. Server kiểm tra account/password, từ chối thiết bị đang thuộc tài khoản khác, rồi trả access token 15 phút, refresh token 90 ngày, ID thiết bị và URL WSS protocol v3. Server chỉ lưu hash token; ESP giữ account credential và refresh token trong NVS, access token trong RAM. Refresh lỗi không tự kích hoạt account-password login; cần provision lại từ app để tránh tự liên kết lại sau khi hủy thiết bị.
4. ESP mở WSS và gửi audio theo giao thức voice v3. Backend dùng worker STT, dịch vụ AI và worker TTS; audio/transcript/context chỉ giữ trong bộ nhớ để xử lý, không ghi log payload hoặc lưu xuống ổ đĩa. Khi hết hạn, ESP gọi refresh; backend xoay refresh token cũ để chống phát lại.
5. Sau khi cấu hình được chấp nhận, app báo ESP đang chờ kết nối server. Khi điện thoại trở lại Internet, người dùng làm mới danh sách để xem trạng thái thiết bị. Consent mặc định false cho danh tính, hồ sơ/mục tiêu, sức khỏe nhạy cảm và theo dõi gần đây. Mở nhóm nhạy cảm yêu cầu bật consent, thiết bị đang kết nối và xác nhận mở trong 5 phút.
6. Người dùng có thể đổi tên, tắt consent hoặc hủy liên kết. Backend thu hồi credential/session; lease WebSocket bị đóng khi server nhận revocation.

Luồng rút gọn: app đăng nhập online và mã hóa credential trong SQLite → điện thoại nối AP ESP → app gửi Wi‑Fi/account credential qua WPA2 local, không cần mobile data → ESP lưu NVS và kết nối Wi‑Fi nhà → ESP đăng nhập server qua HTTPS, nhận device tokens → ESP mở WSS voice v3 → backend/worker xử lý voice → app quản lý consent hoặc thu hồi.

## 4. Quy tắc bảo mật và dữ liệu

| ID | Quy tắc |
|---|---|
| NABI-ESP-BR01 | Giữ DD Draft và khóa release cho tới khi Tech, QA, Privacy review cùng device acceptance hoàn tất. |
| NABI-ESP-BR02 | App chỉ gửi credential tài khoản sau khi login thành công. App lưu credential đã mã hóa bằng Android Keystore trong SQLite tới khi logout; PostgreSQL chỉ lưu Argon2 hash. ESP nhận credential qua AP WPA2, lưu trong NVS và dùng HTTPS device-login để lấy token riêng. |
| NABI-ESP-BR03 | ESP device-login chỉ nhận account credential qua HTTPS; backend dùng hash account hiện có để xác thực, gắn đúng một owner và chỉ lưu hash device token. |
| NABI-ESP-BR04 | AP cục bộ dùng mật mã WPA2 hiển thị trên thiết bị; mỗi phiên chỉ nhận một lần provision. Không cần dữ liệu di động khi nối AP. ESP giữ Wi‑Fi, credential tài khoản và refresh token trong NVS. |
| NABI-ESP-BR05 | Access token sống 15 phút và chỉ ở RAM ESP; refresh token xoay vòng, lưu hash server-side và có thể bị thu hồi. |
| NABI-ESP-BR06 | WSS phải dùng đúng URL/domain, TLS verification và protocol v3; không ghi token, audio, transcript hoặc nội dung AI vào log. |
| NABI-ESP-BR07 | Consent danh tính, profile/mục tiêu, sức khỏe nhạy cảm và tracking mặc định false. Sensitive context cần consent riêng, thiết bị kết nối và thao tác mở rõ ràng; thời hạn 5 phút. |
| NABI-ESP-BR08 | App chỉ quản lý thiết bị thuộc tài khoản đăng nhập. API không trả access/refresh token thiết bị cho app. |
| NABI-ESP-BR09 | Thiết bị OSTB 3ST hiện chưa có Flash Encryption; Wi‑Fi/password, account password và refresh token trong NVS có thể bị lộ khi truy cập vật lý flash. Không coi NVS là mã hóa phần cứng. |
| NABI-ESP-BR10 | Worker voice chỉ bind loopback. Audio/transcript/context xử lý trong RAM; cần kiểm thử và review độc lập trước release. |
| NABI-ESP-BR11 | Mạng Wi‑Fi phải có Internet và cho phép HTTPS/WSS; mất Internet thì ESP không thể hội thoại với server. |

## 5. Phụ thuộc và blocker

- API contract: POST /api/v1/iot/devices/credentials/login, credential refresh, list, rename, consent, sensitive unlock, unbind và WSS /api/v1/iot/ws. Cloud contract v4; voice protocol v3. Hằng số sinh từ iot/nabi_esp_cloud_contract.json.
- App: BackendAuthRepository lưu credential đã mã hóa khi đăng nhập; NabiEspCredentialVault, NabiEspAssistantRuntime, màn Nabi ESP và Android local network bridge gửi Wi‑Fi/account credential qua AP. Device tokens không đi qua Flutter app.
- Backend: IoT router/model/view/query, SQLAlchemy models, migration, authenticated voice websocket và speech worker. Worker dùng optional extra speech, systemd unit riêng và model files cần được cài trước khi triển khai.
- Firmware: profile riêng config.cloud-ai.json, WPA2 AP/local HTTP setup routes, NVS credential lifecycle, HTTPS device-login/refresh, SNTP và WebSocket protocol v3. config.local-ai.json và local contract được giữ nguyên.
- Board: OSTB 3ST, ESP-IDF 6.1, 16 MiB flash và 8 MiB PSRAM theo connected-device profile. Trước khi flash chỉ cập nhật app image vào OTA slot phù hợp; giữ nguyên partition table/NVS và xác nhận lại live layout.
- Migration history: local Web Push 0008 và deployed IoT 0008 được nối bằng 0009 merge. Fresh database và database mô phỏng từ deployed IoT revision đã qua disposable SQLite migration smoke.
- Production: endpoint device-login được triển khai trong release `nabi-web-20261117-01`; service `nanobio-backend` active, `/health/ready` trả `200`, public OpenAPI có route mới. Schema hiện tại dùng các bảng IoT sẵn có nên không chạy migration.

## 6. Review và acceptance gate

| Review | Trạng thái | Bằng chứng cần có |
|---|---|---|
| PO | Ý định trong phạm vi pilot đã được duyệt | Yêu cầu triển khai của người dùng trong phiên 2026-11-17 |
| Tech | Chờ | Review API/auth, migration, token rotation/revocation, TLS, NVS và firmware source/build |
| QA | Chờ | Xem kết quả backend tests, Android build và boot AP; nghiệm thu AP/Wi‑Fi, device-login/refresh/revoke, voice, consent, reconnect, mất Internet |
| Privacy | Chờ | Data flow, consent, voice retention/logging, NVS/physical access, user-facing copy |
| Device | Một phần — cloud contract v4 OTA0 flash/hash/boot/AP setup pass | Nghiệm thu AP provisioning qua APK, device-login, Wi‑Fi reconnect, WSS voice, token refresh/revoke và sensitive unlock |

Không lấy kiểm tra source hoặc contract làm bằng chứng thiết bị đã chạy. Release gate không thay đổi khi chỉ hoàn tất build/test cục bộ.
