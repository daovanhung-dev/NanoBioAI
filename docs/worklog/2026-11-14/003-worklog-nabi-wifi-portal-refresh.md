# Worklog - Nabi hóa portal Wi-Fi trên ESP

## Thời gian

- Ngày: 2026-11-14
- Bắt đầu: khoảng 21:10 (Asia/Bangkok; thời điểm bắt đầu không được ghi lại chính xác)
- Kết thúc: khoảng 21:44 (Asia/Bangkok)
- Timezone: Asia/Bangkok

## Phạm vi

- Loại task: Feature / coding, test, build và xác minh firmware IoT
- Module: `iot/nabi-esp32/third_party/esp-wifi-connect`
- Yêu cầu: làm mới UX cấu hình Wi-Fi tại `192.168.4.1` theo nhận diện Nabi, hiển thị ảnh Nabi, mặc định tiếng Việt lần đầu, giữ lựa chọn ngôn ngữ, sau đó nạp firmware lên ESP.

## Đã làm

- Hoàn thiện portal theo hệ màu Nabi Blue Wellness: xanh dương `#285CC5`, nền xanh nhạt `#F4F7FB`, chữ xanh navy, điểm nhấn xanh lá; có biến màu cho dark mode, tương phản focus, responsive/safe-area và giảm chuyển động.
- Dùng lại ảnh Nabi dạng data URI nhúng trong firmware; không gọi asset hoặc font từ Internet. Header nêu rõ địa chỉ portal `192.168.4.1`.
- Làm tab cấu hình Wi-Fi/nâng cao thành button tab semantic, giữ `aria-selected`, `tabindex`, `aria-hidden` đồng bộ; hỗ trợ phím mũi tên, `Home`, `End`; thêm thông báo lỗi trợ năng và dời danh sách AP lên trước form để chọn mạng theo thứ tự thao tác.
- Locale ưu tiên `lang` hợp lệ trong URL, rồi lựa chọn hợp lệ đã lưu; lần truy cập đầu mặc định `vi-VN`. Lỗi localStorage không chặn hiển thị trang. Tiêu đề tiếng Việt đổi thành “Kết nối Wi-Fi cho Nabi”.
- Làm mới trang hoàn tất với avatar, dải màu Nabi, responsive/safe-area, hỗ trợ reduced-motion và thông báo trạng thái trợ năng; vẫn giữ POST `/exit` sau 1 giây.
- Giữ nguyên các API `/scan`, `/saved/list`, `/saved/delete`, `/saved/set_default`, `/submit`, `/advanced/config`, `/advanced/submit`, `/exit`, cùng 38 locale, OTA URL, TX power, BSSID và sleep settings.
- Mở rộng regression test cho ngôn ngữ mặc định/URL/lưu lại, chuyển tab ARIA bằng chuột/bàn phím và dấu hiệu nhận diện/asset offline.
- Build firmware thành công với ESP-IDF 6.1, target `ostb/ostb-nabi-3st`, config `config.local-ai.json`, language `vi-VN`. App cuối `build/nabi.bin`: 3.178.000 byte (`0x307e10`), SHA-256 `476d9864b0575dc6c0bd84b4462a7c82ee2b6962daab19236cd0dc8f07efc554`.
- Đọc trực tiếp partition table tại `0x8000`: OTA0 `0x20000/0x3f0000`, OTA1 `0x410000/0x3f0000`, assets `0x800000/0x800000`. Đọc OTA metadata tại `0xd000/0x2000`: entry sequence `1`, state `VALID`, CRC theo `ota_seq` hợp lệ, chọn OTA0. App mới nhỏ hơn OTA0 live.
- Nạp riêng app image cuối ở `0x20000`; esptool ghi 3.178.000 byte, xác minh hash và hard reset. Không ghi bootloader, partition table, OTA metadata, NVS, assets hoặc `nvs_user`.
- IDF monitor xác nhận `Project name: nabi`, `After board/audio init`, rồi firmware bắt đầu quét Wi-Fi. Không thấy crash trong khoảng quan sát 21 giây; station chưa tìm thấy AP đã lưu. Chưa xác minh HTTP/captive portal thực tế bằng trình duyệt tại `192.168.4.1`.
- Gỡ ACL tạm của user `daovh`; `/dev/ttyACM0` trở về `root:uucp`, không còn ACL bổ sung.

## File code/docs đã sửa

- `iot/nabi-esp32/third_party/esp-wifi-connect/assets/wifi_configuration.html` — theme, header/địa chỉ, danh sách AP, semantic tabs và locale startup.
- `iot/nabi-esp32/third_party/esp-wifi-connect/assets/wifi_configuration_done.html` — success UI, responsive behavior và reduced-motion.
- `iot/nabi-esp32/third_party/esp-wifi-connect/tests/test_portal.js` — kiểm tra locale, persistence, tabs và Nabi branding.
- `iot/nabi-esp32/docs/agent-context/CONNECTED_DEVICE_OSTB_3ST.md` — cập nhật bằng chứng app/boot mới.
- `iot/nabi-esp32/docs/agent-context/FILE_INDEX.md` — đồng bộ kích thước và mô tả các file thay đổi.
- `docs/worklog/2026-11-14/003-worklog-nabi-wifi-portal-refresh.md` — worklog task này.

## Commands và kết quả

- `node third_party/esp-wifi-connect/tests/test_portal.js`: PASS — 34 URL cases, sleep timers, Wi-Fi form isolation, 38 locale catalogs, default/persisted locale và keyboard-accessible tabs.
- `python3 scripts/build.py ostb/ostb-nabi-3st --config config.local-ai.json --language vi-VN`: PASS — app image 3.178.000 byte; nhỏ hơn OTA0 live 4.128.768 byte.
- Esptool đọc partition table live và OTA metadata: PASS — active OTA0, sequence `1`, state hợp lệ, CRC hợp lệ.
- Esptool app-only write tại `0x20000`: PASS — ghi 3.178.000 byte và xác minh hash, hard reset.
- IDF monitor: PASS — app Nabi qua board/audio initialization; chưa thấy crash trong lượt quan sát.
- ACL serial tạm: cấp để đọc/flash, sau đó gỡ thành công.
- CMake/ESP-IDF phát các warning Kconfig legacy boolean và component include dependency; build vẫn kết thúc thành công.
- `pwsh` không có trên host; deterministic history refresh bằng Python đã PASS với `--write` và `--check`. Chưa chạy `validate_codex_integrity.ps1` vì thiếu PowerShell.
- `python3 tools/validate_docs_source_truth.py` được chạy nhưng không qua do repository hiện thiếu `docs/audit/source_truth_manifest.json`; file này không có trong Git và task portal không tạo manifest thay thế.

## Lỗi, giới hạn và rủi ro

- Partition CSV của source/build khác partition table live. Chỉ nạp app OTA0 sau khi đọc lại layout thực và xác nhận app vừa slot; không dùng flash command mặc định của build vì command đó còn ghi partition table, OTA data và assets.
- Chưa có AP Wi-Fi để kết nối trình duyệt vào `192.168.4.1`, nên chưa có xác minh trực quan captive portal sau flash. Monitor cho thấy station tiếp tục quét và không tìm thấy AP đã lưu.
- Không chụp/đọc NVS hoặc credentials; thao tác flash chỉ phủ vùng image app ở OTA0.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: portal có nhận diện Nabi rõ, ảnh và toàn bộ UI chạy offline; form và API mạng hiện hành được giữ nguyên.
- Mức độ hoàn thành: code, regression test, firmware build, app-only flash và xác nhận boot đã xong; smoke test trình duyệt trên AP thật còn chờ thiết bị vào chế độ cấu hình.
- Bằng chứng kiểm chứng: test portal PASS; build PASS; partition/OTA metadata đọc trực tiếp; esptool hash verify PASS; monitor nhận boot marker; ACL được gỡ.
- Token/thời gian chưa tối ưu: build cold phát nhiều log dependency/Kconfig không liên quan trực tiếp. Lần sau có thể redirect log vào file tạm và chỉ hiển thị summary nếu cần.
- Cách tiếp tục: khi ESP vào configuration AP, kết nối client tới `192.168.4.1` để kiểm tra trực quan mobile layout, quét/chọn mạng và trang thành công; không ghi lại credentials.
- History refresh: chạy helper Python nếu tương thích với workflow; không sửa tay generated task-skill.
