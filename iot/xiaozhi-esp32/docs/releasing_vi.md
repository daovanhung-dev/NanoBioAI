# Phát hành firmware

Workflow **Release Firmware** (`.github/workflows/release.yml`) được khởi chạy thủ công. Workflow build mọi biến thể phát hành được ESP-IDF 6.1 hỗ trợ bằng lệnh `scripts/build.py <board> --name <variant> --zip`. Workflow không dùng lựa chọn CI incremental và không bao gồm các biến thể tùy chọn chỉ dành cho CI.

Phiên bản phát hành lấy từ `PROJECT_VER` trong `CMakeLists.txt` ở thư mục gốc. Hãy cập nhật giá trị đó trước khi phát hành phiên bản tiếp theo. Workflow cố định mọi lần checkout ở commit kích hoạt workflow và ghi commit, SDK, thư mục bo cùng danh sách biến thể đầy đủ vào `release-manifest.json`.

## Chạy workflow

Trước tiên, hãy merge workflow vào nhánh mặc định để GitHub hiển thị nút chạy thủ công. Trong **Actions → Release Firmware → Run workflow**, chọn nhánh mặc định và để bật **Publish as the latest release** nếu muốn phát hành công khai. Tắt tùy chọn này để build và tải lên một bản nháp chưa phát hành.

Các lệnh tương đương:

```sh
# Build mọi biến thể, tải mọi gói lên và phát hành bản mới nhất.
gh workflow run release.yml --repo 78/xiaozhi-esp32 --ref main -f publish=true

# Build mọi biến thể và giữ bản phát hành tạo ra ở trạng thái nháp.
gh workflow run release.yml --repo 78/xiaozhi-esp32 --ref main -f publish=false
```

Muốn phát hành công khai, phải dùng nhánh mặc định. Workflow chỉ dùng `GITHUB_TOKEN` tích hợp sẵn; không cần personal access token hoặc cài ESP-IDF trên máy cục bộ. Workflow phát hành GitHub Release, không sửa dịch vụ OTA hay kho OSS.

## Nội dung được tải lên

Mỗi biến thể tạo `v<version>_<full_name>.zip`, chứa một tệp `merged-binary.bin` theo định dạng đã dùng từ v2.5.0. Hai tệp đính kèm bổ sung chứa manifest toàn bộ biến thể và `SHA256SUMS` cho mọi ZIP. Ghi chú phát hành kết hợp thông tin build với danh sách thay đổi do GitHub tạo kể từ bản phát hành mới nhất trước đó.

Mọi build trong ma trận phải thành công trước khi tác vụ upload chạy. Tác vụ upload từ chối gói bị thiếu hoặc ngoài dự kiến, ZIP không đọc được, thành viên archive ngoài dự kiến, phiên bản ứng dụng nhúng sai, target chip sai hoặc phiên bản SDK không khớp. Tác vụ xác minh tên và kích thước tệp đính kèm đã tải lên, cùng các digest SHA-256 GitHub cung cấp nếu có, trước khi đánh dấu bản phát hành là công khai.

Khi build thất bại, các artifact build thành công vẫn có trong lần chạy workflow. Dùng **Re-run failed jobs** để tiếp tục. Nếu upload thất bại, một bản nháp chưa công khai vẫn được giữ lại; chỉ có thể thử lại và thay tệp đính kèm trùng tên khi bản nháp và tag trỏ đến cùng commit nguồn. Bản phát hành đã công khai và tag trỏ đến commit khác sẽ bị từ chối. Các lần chạy phát hành đồng thời được tuần tự hóa.

Build thành công và kiểm tra gói không thay thế việc xác minh trên phần cứng thật. Hãy thử trên phần cứng liên quan trước khi khuyến nghị sử dụng bản phát hành.

