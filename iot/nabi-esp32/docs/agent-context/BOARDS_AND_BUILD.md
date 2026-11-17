# Board, variant và build

## Chuỗi chọn board

Board selection là một chuỗi cấu hình khép kín:

```text
main/boards/**/config.json
        -> scripts/build.py
        -> target + sdkconfig defaults/variant options
        -> main/Kconfig.projbuild (exactly one BOARD_TYPE)
        -> main/CMakeLists.txt (board source, fonts, emoji, assets)
        -> selected board source + config.h
        -> partition table and firmware artifact
```

Trong mỗi board directory, `config.json` khai báo `target`, board `type`, và các `builds` (release variants) gồm `name` cùng `sdkconfig_append`. `type` và `name` là nhận dạng tương thích OTA; giữ ổn định sau khi phát hành. `config.h` khai báo chân kết nối và macro phần cứng. Board source triển khai `Board`, và trong build phải có đúng một `DECLARE_BOARD(...)`. `README.md` mô tả phần cứng và cách build nếu board có ghi chú riêng.

Khi thêm board, dùng tên/directory riêng và cập nhật toàn bộ mắt xích liên quan trong JSON, Kconfig, CMake, source, partition và hướng dẫn board. Không sửa pin board hiện có để hỗ trợ một biến thể phần cứng khác. Đọc [`docs/custom-board.md`](../custom-board.md) và board gần nhất trước khi thay đổi.

## Chip, SDK và cấu hình

- ESP-IDF tối thiểu là 6.0.1; 6.1 được khuyến nghị; ESP-IDF 5.x không được hỗ trợ.
- Các target có cấu hình mặc định riêng nằm trong `sdkconfig.defaults.<target>`; `sdkconfig.defaults` chứa mặc định chung.
- Các target hiện diện trong cấu hình dự án gồm ESP32, ESP32-C3, ESP32-C5, ESP32-C6, ESP32-S3, ESP32-P4 và ESP32-S31. Không mặc định mọi chip có PSRAM hoặc peripheral của S3/P4.
- `sdkconfig` là cấu hình sinh/local của lần build hiện tại, không phải mặc định portable. `scripts/build.py` có thể thay đổi sdkconfig và trạng thái build; xác minh target trước khi build lại.

## Partition và assets

Các CSV dưới `partitions/v1/` và `partitions/v2/` định nghĩa bố cục flash. v1 thường dành vùng cho model; v2 có partition `assets` để cập nhật model/theme/font/emoji độc lập. Dung lượng app, NVS, assets và giới hạn mmap phụ thuộc board/chip/flash. Partition riêng của board trong `config.json` phải khớp dung lượng flash thực và yêu cầu lưu trữ thiết bị; đổi bố cục có thể ảnh hưởng NVS và asset cũ.

`main/CMakeLists.txt` tạo hoặc cấu hình assets theo lựa chọn Kconfig. `scripts/build_default_assets.py` đóng gói model và tài nguyên được chọn; `scripts/spiffs_assets/` chứa công cụ tạo/đóng gói assets. `managed_components/` là dependency do ESP-IDF resolve, không phải nơi sửa mã dự án.

## Lệnh build và kiểm chứng

Nạp môi trường ESP-IDF trước:

```sh
source /path/to/esp-idf/export.sh
idf.py --version
python3 scripts/build.py --list-boards
python3 scripts/build.py <board-directory> --name <variant-name>
```

Với thay đổi tooling, bộ kiểm tra host-side là `python3 -m unittest discover -s scripts/tests -v`. Chỉ chạy lệnh này khi task yêu cầu test/verify; task chỉ sửa docs không cần build firmware hay chạy unit test. Với thay đổi riêng cho board, build các variant bị ảnh hưởng và smoke-test phần cứng. Với thay đổi core/Kconfig/CMake/audio/protocol/display/dependency, build đường đi đại diện cho chip và mạng liên quan; kiểm tra cả WebSocket lẫn MQTT/UDP nếu hợp đồng chung thay đổi. CI chọn variant/build tại `.github/workflows/build.yml`; phát hành full matrix tại `.github/workflows/release.yml` và `docs/releasing.md`.

Build thành công không chứng minh hành vi trên thiết bị. Báo riêng build, kiểm chứng source/browser (nếu có), và phần còn cần thiết bị thật.
