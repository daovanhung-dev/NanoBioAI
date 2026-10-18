# Cấu hình BluFi (tích hợp `esp-wifi-connect`)

Tài liệu này hướng dẫn cách bật và sử dụng BluFi (cấu hình WiFi qua BLE) trong firmware XiaoZhi, kết hợp với component `esp-wifi-connect` được tích hợp trong dự án để kết nối WiFi và lưu thông tin đăng nhập. Xem [tài liệu BluFi chính thức của Espressif](https://docs.espressif.com/projects/esp-idf/en/stable/esp32/api-guides/ble/blufi.html) để biết chi tiết giao thức.

## Điều kiện tiên quyết

- Chip và cấu hình firmware phải hỗ trợ BLE.
- Trong `idf.py menuconfig`, bật `WiFi Configuration Method -> ESP-BluFi` (`CONFIG_USE_ESP_BLUFI_WIFI_PROVISIONING=y`). Nếu muốn dùng BluFi, hãy tắt tùy chọn Hotspot trong cùng menu; nếu không, chế độ cấu hình qua hotspot sẽ được ưu tiên theo mặc định.
- Giữ nguyên phần khởi tạo NVS và event loop mặc định do `app_main` của dự án cung cấp.
- Chỉ được chọn một trong hai macro `CONFIG_BT_BLUEDROID_ENABLED` và `CONFIG_BT_NIMBLE_ENABLED`; chúng loại trừ lẫn nhau.

## Quy trình hoạt động

1. Điện thoại (dùng ứng dụng EspBlufi chính thức hoặc một client BluFi khác) kết nối với thiết bị qua BLE rồi gửi SSID/mật khẩu WiFi đích. Điện thoại cũng có thể yêu cầu danh sách các mạng WiFi mà thiết bị đã quét được qua giao thức BluFi.
2. Trong sự kiện `ESP_BLUFI_EVENT_REQ_CONNECT_TO_AP`, thiết bị lưu thông tin đăng nhập vào `SsidManager` (component `esp-wifi-connect` lưu thông tin này trong NVS).
3. Sau đó, thiết bị khởi chạy `WifiStation` để quét và kết nối; tiến trình được báo lại qua BluFi.
4. Khi cấu hình thành công, thiết bị tự động kết nối vào WiFi mới. Nếu thất bại, thiết bị gửi trạng thái lỗi về điện thoại.

## Các bước thực hiện

1. **Cấu hình**: bật `ESP-BluFi` trong menuconfig, sau đó build và flash firmware.
2. **Bắt đầu cấu hình**: ở lần khởi động đầu tiên khi chưa có thông tin WiFi đã lưu, thiết bị tự động vào chế độ cấu hình.
3. **Thao tác trên điện thoại**: mở ứng dụng EspBlufi (hoặc client BluFi khác), quét và kết nối với thiết bị, có thể bật mã hóa, sau đó nhập SSID/mật khẩu WiFi và gửi.
4. **Kiểm tra kết quả**:
   - Thành công: BluFi báo thành công và thiết bị kết nối WiFi.
   - Thất bại: BluFi báo thất bại; hãy thử lại hoặc kiểm tra router.

## Lưu ý

- Không thể đồng thời dùng BluFi và cấu hình qua hotspot. Nếu cấu hình hotspot đã được bật, thiết bị sẽ dùng phương thức đó. Chỉ giữ lại một phương thức cấu hình trong menuconfig.
- Khi thử nghiệm nhiều lần, hãy xóa hoặc ghi đè SSID đã lưu (namespace NVS `wifi`) để tránh thông tin cũ ảnh hưởng lần chạy tiếp theo.
- Nếu tự viết client BluFi, hãy tuân theo định dạng frame của giao thức chính thức ở liên kết trên.
- Liên kết tải ứng dụng EspBlufi được liệt kê trong tài liệu chính thức.
- Do API BluFi thay đổi ở IDF 5.5.2, firmware build bằng 5.5.2 quảng bá tên Bluetooth là `"Xiaozhi-Blufi"`, còn bản build bằng 5.5.1 dùng `"BLUFI_DEVICE"`.

