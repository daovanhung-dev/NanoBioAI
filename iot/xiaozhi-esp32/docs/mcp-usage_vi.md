# Cách dùng MCP để điều khiển IoT

> Tài liệu này hướng dẫn triển khai điều khiển IoT cho thiết bị ESP32 bằng giao thức MCP. Để biết giao thức trên đường truyền, xem [`mcp-protocol_vi.md`](./mcp-protocol_vi.md).

## Giới thiệu

MCP (Model Context Protocol) là giao thức được khuyến nghị cho điều khiển IoT trong dự án này. Giao thức dùng JSON-RPC 2.0 để backend khám phá và gọi các “tool” do thiết bị đăng ký, nhờ đó có thể cung cấp chức năng của thiết bị một cách linh hoạt.

## Luồng điển hình

1. Thiết bị khởi động và kết nối với backend qua WebSocket hoặc MQTT.
2. Backend gửi lời gọi `initialize` để bắt đầu phiên MCP.
3. Backend gửi `tools/list` để khám phá các tool khả dụng cùng schema đầu vào.
4. Backend gọi từng tool bằng `tools/call` để điều khiển thiết bị.

Xem [`mcp-protocol_vi.md`](./mcp-protocol_vi.md) để biết chính xác định dạng thông điệp.

## Đăng ký tool trên thiết bị

Tool được đăng ký thông qua singleton `McpServer`. Có hai API đăng ký:

- `McpServer::AddTool` - tool thông thường, hiển thị trong phản hồi `tools/list` mặc định và model AI có thể gọi.
- `McpServer::AddUserOnlyTool` - tool ẩn, chỉ được trả về khi backend liệt kê tool với `withUserTools=true`. Dùng cho thao tác có đặc quyền hoặc do người dùng chủ động yêu cầu (khởi động lại, nâng cấp firmware, chụp ảnh màn hình, v.v.) mà model không được tự gọi.

Hai API có cùng chữ ký:

```cpp
void AddTool(
    const std::string& name,           // tên tool duy nhất, ví dụ self.dog.forward
    const std::string& description,    // mô tả ngắn cho model
    const PropertyList& properties,    // tham số đầu vào (có thể rỗng); hỗ trợ bool, int, string
    std::function<ReturnValue(const PropertyList&)> callback // phần triển khai
);

void AddUserOnlyTool(
    const std::string& name,
    const std::string& description,
    const PropertyList& properties,
    std::function<ReturnValue(const PropertyList&)> callback
);
```

- `name` - mã định danh duy nhất. Nên dùng quy ước đặt tên `module.action`.
- `description` - mô tả bằng ngôn ngữ tự nhiên, giúp AI quyết định khi nào gọi tool.
- `properties` - tham số đầu vào. Các kiểu thuộc tính được hỗ trợ là boolean, integer và string; có thể chỉ định giá trị min/max và mặc định.
- `callback` - phần triển khai. Giá trị trả về có thể là `bool`, `int` hoặc `std::string`.

## Ví dụ (ESP-Hi)

```cpp
void InitializeTools() {
    auto& mcp_server = McpServer::GetInstance();

    // Ví dụ 1: không có tham số - đưa robot tiến về phía trước
    mcp_server.AddTool("self.dog.forward",
        "Move the robot forward",
        PropertyList(),
        [this](const PropertyList&) -> ReturnValue {
            servo_dog_ctrl_send(DOG_STATE_FORWARD, NULL);
            return true;
        });

    // Ví dụ 2: có tham số - đặt màu đèn RGB
    mcp_server.AddTool("self.light.set_rgb",
        "Set the RGB color of the light",
        PropertyList({
            Property("r", kPropertyTypeInteger, 0, 255),
            Property("g", kPropertyTypeInteger, 0, 255),
            Property("b", kPropertyTypeInteger, 0, 255)
        }),
        [this](const PropertyList& properties) -> ReturnValue {
            int r = properties["r"].value<int>();
            int g = properties["g"].value<int>();
            int b = properties["b"].value<int>();
            led_on_ = true;
            SetLedColor(r, g, b);
            return true;
        });
}
```

## Ví dụ - Đăng ký tool chỉ dành cho người dùng

```cpp
mcp_server.AddUserOnlyTool("self.display.clear_cache",
    "Clear locally cached images. User-only action.",
    PropertyList(),
    [](const PropertyList&) -> ReturnValue {
        ClearLocalCache();
        return true;
    });
```

Tool đăng ký theo cách này sẽ không xuất hiện trong phản hồi `tools/list` thông thường. Backend phải đặt `params.withUserTools = true` để thấy tool đó.

## Tool tích hợp sẵn

`McpServer::AddCommonTools` và `McpServer::AddUserOnlyTools` tự động đăng ký một số tool:

### Mặc định (AI có thể gọi) - từ `AddCommonTools`

| Tool | Mô tả |
|------|-------------|
| `self.get_device_status` | Trả về âm lượng, màn hình, pin, mạng hiện tại, v.v. |
| `self.audio_speaker.set_volume` | Đặt âm lượng loa (`volume`: 0-100). |
| `self.screen.set_brightness` | Đặt độ sáng màn hình khi có đèn nền (`brightness`: 0-100). |
| `self.screen.set_theme` | Chuyển chủ đề giao diện (`theme`: `"light"` hoặc `"dark"`), khi bật LVGL. |
| `self.camera.take_photo` | Chụp ảnh bằng camera trên bo (nếu có) và trả lời câu hỏi `question` về ảnh. |

Tool riêng của từng bo được nối thêm sau danh sách này trong `InitializeTools()`.

### Tool chỉ dành cho người dùng - từ `AddUserOnlyTools`

Mặc định các tool này bị ẩn. Backend phải truyền `withUserTools=true` trong `tools/list` để xem chúng. Chúng dành cho ứng dụng đồng hành / người dùng cuối thay vì model AI.

| Tool | Mô tả |
|------|-------------|
| `self.get_system_info` | Trả về đối tượng JSON mô tả hệ thống. |
| `self.reboot` | Khởi động lại thiết bị sau một khoảng trễ ngắn. |
| `self.upgrade_firmware` | Tải firmware từ `url`, cài đặt rồi khởi động lại. |
| `self.screen.get_info` | Trả về chiều rộng, chiều cao hiện tại của màn hình và màn hình có đơn sắc hay không (chỉ bo LVGL). |
| `self.screen.snapshot` | Chụp màn hình thành JPEG và tải lên `url` (bo LVGL, khi `CONFIG_LV_USE_SNAPSHOT=y`). |
| `self.screen.preview_image` | Tải ảnh từ `url` rồi hiển thị trên màn hình. |
| `self.assets.set_download_url` | Đặt URL tải xuống cho phân vùng assets. |

## Ví dụ JSON-RPC

### 1. Lấy danh sách tool

```json
{
  "jsonrpc": "2.0",
  "method": "tools/list",
  "params": { "cursor": "", "withUserTools": false },
  "id": 1
}
```

### 2. Cho khung gầm tiến lên

```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "self.chassis.go_forward",
    "arguments": {}
  },
  "id": 2
}
```

### 3. Chuyển chế độ đèn

```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "self.chassis.switch_light_mode",
    "arguments": { "light_mode": 3 }
  },
  "id": 3
}
```

### 4. Khởi động lại thiết bị (chỉ dành cho người dùng)

```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "self.reboot",
    "arguments": {}
  },
  "id": 4
}
```

### 5. Lật hình camera (nếu thiết bị đăng ký tool này)

```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "self.camera.set_camera_flipped",
    "arguments": {}
  },
  "id": 5
}
```

## Lưu ý

- Tên tool, tham số và giá trị trả về phải khớp những gì thiết bị đăng ký qua `AddTool` / `AddUserOnlyTool`.
- Ưu tiên MCP cho mọi chức năng điều khiển IoT mới.
- Để biết giao thức trên đường truyền và các chủ đề nâng cao, xem [`mcp-protocol_vi.md`](./mcp-protocol_vi.md).

