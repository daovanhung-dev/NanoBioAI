Commit de xuat: feat(iot): ca nhan hoa giao dien cau hinh mang nabi tren esp

# Worklog - Nabi hóa giao diện cấu hình mạng ESP

## Thời gian

- Ngày: 2026-11-14
- Bắt đầu: khoảng 18:00 (Asia/Bangkok; thời điểm bắt đầu không được ghi lại chính xác)
- Kết thúc: 21:07 (Asia/Bangkok)
- Timezone: Asia/Bangkok

## Phạm vi

- Loại task: Feature / coding và xác minh firmware IoT
- Module chính: `iot/nabi-esp32` — cấu hình Wi-Fi cho OSTB Nabi 3ST
- Yêu cầu gốc: Nabi hóa đầy đủ UX cấu hình mạng trên màn hình LCD và portal trình duyệt, thêm hình Nabi, rồi boot firmware lên ESP.

## Đã làm

- Thêm mô hình trạng thái provisioning có kiểu dữ liệu và overlay LCD Nabi cho các trạng thái ghép đôi, mã ghép đôi còn hạn, AP chờ cấu hình, đang kết nối, thành công và lỗi.
- Hiển thị thông tin AP/URL trong trạng thái chờ, dùng locale tiếng Việt cho portal của cấu hình Nabi, giữ nguyên SSID prefix và callback mạng hiện hành.
- Chỉ trả pairing code khi thiết bị chưa ghép đôi, chưa khóa và mã chưa hết hạn; không lưu thêm mã vào NVS hoặc log.
- Nabi hóa hai trang portal Wi-Fi: bảng màu xanh dương/xanh lá, header có ảnh Nabi, layout responsive, focus-visible, hỗ trợ reduced-motion; giữ nguyên endpoint, các mục cấu hình nâng cao, danh sách 38 locale và hành vi gửi form.
- Vendored `78/esp-wifi-connect` 3.3.3 vào `third_party/esp-wifi-connect` theo MIT license và cấu hình component override cục bộ.
- Thêm ảnh PNG nguồn, asset RGB565 được nhúng vào firmware và script tái tạo/cập nhật dữ liệu ảnh nhúng cho LCD và portal.
- Cập nhật IoT `FILE_INDEX.md` cho asset, script và component vendored.
- Build firmware Nabi OSTB 3ST cuối cùng thành công với ESP-IDF 6.1 bằng profile `ostb/ostb-nabi-3st`, cấu hình `config.local-ai.json` và ngôn ngữ `vi-VN`. Ảnh app `build/nabi.bin` có kích thước 3.170.112 bytes (`0x305f40`), SHA-256 `96af2f4d0e0fd394875180b4606779052b1702434a5ca2ed9486a0660c3d7a94`; OTA0 trong build table ở `0x20000`, kích thước `0x460000`.
- Đọc trực tiếp partition table live 4 KB tại `0x8000`: OTA0 `0x20000/0x3f0000`, OTA1 `0x410000/0x3f0000`, assets `0x800000/0x800000`. Bảng live khác CSV source/build; app 3.170.112 byte vừa OTA0.
- Đọc OTA metadata tại `0xd000/0x2000`: sequence `1`, CRC hợp lệ, chọn OTA0. Không ghi hoặc đổi OTA metadata.
- Nạp riêng `build/nabi.bin` tại `0x20000`; esptool ghi 3.170.112 byte, xác minh hash thành công và hard reset. Monitor sau reset nhận marker `After board/audio init`; không thấy marker crash trong khoảng quan sát 18 giây. Không ghi bootloader, partition table, OTA metadata, NVS, assets hoặc `nvs_user`.
- ACL serial tạm được gỡ sau khi xác minh; `/dev/ttyACM0` trở lại quyền `root:uucp` và không còn ACL mở rộng.

## File code/docs đã sửa

- `iot/nabi-esp32/main/display/display.h` — thêm kiểu trạng thái overlay setup Wi-Fi.
- `iot/nabi-esp32/main/display/lvgl_display/lvgl_display.h` — khai báo API overlay LCD.
- `iot/nabi-esp32/main/display/lvgl_display/lvgl_display.cc` — vẽ giao diện LCD Nabi và ảnh RGB565 nhúng.
- `iot/nabi-esp32/main/boards/common/wifi_board.h` — khai báo trạng thái/lifecycle setup Wi-Fi.
- `iot/nabi-esp32/main/boards/common/wifi_board.cc` — nối trạng thái provisioning với overlay LCD và portal.
- `iot/nabi-esp32/main/nabi_esp_provisioning.h` — khai báo truy cập mã pairing có kiểm tra trạng thái.
- `iot/nabi-esp32/main/nabi_esp_provisioning.cc` — giới hạn thời gian và điều kiện đọc mã pairing.
- `iot/nabi-esp32/main/CMakeLists.txt` — nhúng asset Nabi có điều kiện cho firmware Nabi.
- `iot/nabi-esp32/main/idf_component.yml` — dùng component Wi-Fi portal vendored.
- `iot/nabi-esp32/main/assets/nabi_setup.png` — ảnh Nabi cho giao diện.
- `iot/nabi-esp32/main/assets/nabi_setup.rgb565` — bản RGB565 nhúng cho LCD.
- `iot/nabi-esp32/scripts/generate_nabi_setup_assets.py` — tạo/cập nhật asset nhúng cho LCD và web.
- `iot/nabi-esp32/third_party/esp-wifi-connect/**` — component portal upstream 3.3.3, MIT.
- `iot/nabi-esp32/docs/agent-context/FILE_INDEX.md` — cập nhật index, snapshot và ownership.
- `docs/worklog/2026-11-14/002-worklog-iot-nabi-esp-network-config.md` — ghi nhận thay đổi, validation và hạn chế triển khai phần cứng.

## Tài liệu liên quan

- `iot/nabi-esp32/AGENTS.md`
- `iot/nabi-esp32/.codex/PROJECT_MAP.md`
- `iot/nabi-esp32/.codex/workflows/coding.md`
- `iot/nabi-esp32/.codex/domains/iot.md`
- `iot/nabi-esp32/docs/agent-context/FILE_INDEX.md`

## Commands

- `python3 -m unittest discover -s scripts/tests -v`: PASS — 132 test, 1 skipped.
- `python3 -m unittest discover -s docker/firmware-builder -p 'test_*.py' -v`: PASS — 10 test.
- `node third_party/esp-wifi-connect/tests/test_portal.js`: PASS — 34 URL cases, timer, form isolation và 38 locale catalogs.
- `flutter test test/app_versions/v1/features/splash`: PASS — 10 test; `flutter analyze` trên các file splash đã sửa: không có issue.
- `flutter test test/nabi_esp_contract_test.dart` và `flutter analyze` trên các file phone app đã sửa: PASS, không có issue.
- `python3 iot/tools/generate_nabi_esp_contract.py --check`: PASS — contract outputs đồng bộ.
- `git diff --check`: PASS.
- `.codex/tools/validate_codex_integrity.ps1`: SKIPPED — môi trường Linux không có `pwsh`/PowerShell; đã kiểm tra thủ công đường dẫn và chỉ mục.
- Firmware build bằng `python3 scripts/build.py ostb/ostb-nabi-3st --config config.local-ai.json --language vi-VN` với ESP-IDF 6.1: PASS — app 3.170.112 bytes.
- Đọc live partition table và OTA metadata qua esptool: PASS — OTA0 đang active, app slot đủ chỗ.
- Nạp app-only với esptool tại `0x20000`: PASS — 3.170.112 bytes, hash verified, hard reset.
- IDF monitor với filter `main:I Application:I`: PASS — nhận marker `After board/audio init`; không thấy marker crash trong lượt quan sát.
- Gỡ ACL tạm bằng `setfacl`: PASS — thiết bị trở lại quyền `root:uucp`.

## Lỗi/Rủi ro

- Đã fix: linker symbols ban đầu tham chiếu `_binary_assets_nabi_setup_rgb565_*`, trong khi ESP-IDF sinh `_binary_nabi_setup_rgb565_*`; sửa symbol để build link thành công.
- Đã xác minh: partition table live khác CSV source/build; app vừa OTA0 thực tế và firmware khởi động tới bước init board/audio.
- Chưa kiểm tra trực quan: chưa có ảnh/video xác nhận LCD và chưa smoke test portal/Wi-Fi trên firmware cuối.
- Cần kiểm tra tiếp: kiểm tra trực quan UX LCD và portal trên thiết bị; nếu vẫn cần log boot, dùng UART console chính của board hoặc debugger phần cứng.

## Tỷ lệ hoàn thành

- Hoàn tất phần mềm: UI/UX Nabi, asset ảnh, luồng provisioning, ngôn ngữ khởi động tiếng Việt, đổi nhận diện sản phẩm, build firmware và kiểm tra tự động.
- Firmware cuối đã nạp và boot tới board/audio initialization; smoke test trực quan LCD/portal vẫn chưa thực hiện.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: hai UX surface dùng chung nhận diện Nabi, luồng mạng hiện tại được giữ nguyên, firmware build thành công và các kiểm tra phần mềm chính đều pass.
- Mức độ hoàn thành task: phần mềm, nạp app riêng vào OTA0 và xác nhận ứng dụng khởi tạo board/audio đã hoàn tất; kiểm tra UI vật lý còn lại.
- Bằng chứng kiểm chứng: test portal, firmware, Flutter, contract và `git diff --check` pass; esptool hash verified; monitor nhận boot marker. Không lưu raw log.
- Điểm tốn token/chưa tối ưu: cài toolchain ESP-IDF lần đầu và build cold mất thời gian; lần link đầu còn sai tên embedded symbol.
- Cách tiếp tục: kiểm tra trực quan LCD và portal trên ESP; nếu cần boot log chi tiết, dùng UART console chính hoặc debugger phần cứng.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`
