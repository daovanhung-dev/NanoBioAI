# Phần mở rộng đẩy glyph văn bản động

Tài liệu này định nghĩa phiên bản 1 của phần mở rộng giao thức `glyph_push`. Phần mở rộng cho phép máy chủ gửi các glyph bitmap còn thiếu trong phông chữ văn bản đã cài trên thiết bị. Phần mở rộng áp dụng như nhau cho WebSocket và MQTT/UDP vì việc quảng bá khả năng và xử lý JSON đầu vào được triển khai ở lớp protocol dùng chung.

Phần mở rộng chỉ bổ sung khả năng hiển thị văn bản. Nó không thay đổi ngữ nghĩa của văn bản, âm thanh TTS hoặc STT trong thông điệp chứa nó.

## 1. Quảng bá khả năng

Thiết bị quảng bá khả năng hỗ trợ trong thông điệp `hello` gửi từ client:

```json
{
  "type": "hello",
  "version": 1,
  "features": {
    "mcp": true,
    "glyph_push": true
  },
  "text_font": {
    "bundle": "noto-v1",
    "charset": "common",
    "size": 20,
    "bpp": 4
  }
}
```

`features.glyph_push` cho biết thiết bị hỗ trợ phần mở rộng này. Máy chủ phải xem thiết bị là không hỗ trợ nếu trường này không có hoặc có giá trị false. Trường `v` trong mỗi payload được đẩy lên mang phiên bản của phần mở rộng.

Đối tượng `text_font` mô tả chính xác dữ liệu phông chữ đã cài trên thiết bị:

| Trường | Kiểu | Ý nghĩa |
|---|---|---|
| `bundle` | string | Mã định danh tường minh của gói phông chữ. Mã này thay đổi khi metric glyph, hành vi hiển thị, bộ ký tự hoặc khả năng tương thích trên đường truyền thay đổi. |
| `charset` | string | Bộ ký tự đã cài đặt. Thiết bị phiên bản 1 báo cáo `basic` hoặc `common`. |
| `size` | number | Cấu hình kích thước pixel của phông chữ văn bản mà firmware sử dụng. |
| `bpp` | number | Số bit trên mỗi pixel của bitmap phông chữ văn bản; hiện là `1` hoặc `4`. |

`basic` là phông chữ được liên kết trực tiếp vào firmware. Sau khi tải phông chữ common từ phân vùng assets, bộ assets XiaoZhi tiêu chuẩn báo cáo `common`. Máy chủ phải sử dụng các giá trị do từng thiết bị gửi trong thông điệp hello, không được suy đoán từ model bo mạch.

Một gói assets OTA có thể thay phông chữ văn bản bằng phông chữ khác về kích thước, bpp, bộ ký tự hoặc họ phông. Firmware vẫn tải mọi phông CBIN có cấu trúc hợp lệ. Nếu gói đồng thời cung cấp đầy đủ các trường `text_font_meta`, thiết bị sẽ quảng bá các giá trị runtime đang hoạt động và dùng chúng để kiểm tra glyph được đẩy lên. Gói cũ hoặc gói tùy chỉnh không có metadata glyph tương thích vẫn tiếp tục dùng phông chữ, emoji, màu sắc và hình nền riêng, nhưng sẽ quảng bá `glyph_push: false` và bỏ trường `text_font`. Cách này ngăn glyph fallback không tương thích mà không hạn chế khả năng tùy chỉnh giao diện.

## 2. Payload glyph từ máy chủ

Máy chủ có thể đính kèm đối tượng `glyph_push` vào một trong hai loại thông điệp từ máy chủ đến thiết bị:

- Thông điệp TTS có `"type": "tts"` và `"state": "sentence_start"`;
- Thông điệp STT có `"type": "stt"`.

Ví dụ:

```json
{
  "type": "tts",
  "state": "sentence_start",
  "text": "𠮷野家",
  "glyph_push": {
    "v": 1,
    "bundle": "noto-v1",
    "size": 20,
    "bpp": 4,
    "glyphs": [
      {
        "codepoint": 134071,
        "adv_w": 320,
        "box_w": 20,
        "box_h": 20,
        "ofs_x": 0,
        "ofs_y": 0,
        "bitmap": "<base64-encoded bitmap>"
      }
    ]
  }
}
```

Header của payload phải khớp chính xác với khả năng của thiết bị:

| Trường | Yêu cầu |
|---|---|
| `v` | Phải bằng `1`. |
| `bundle` | Phải bằng `text_font.bundle`. |
| `size` | Phải bằng `text_font.size`. |
| `bpp` | Phải bằng `text_font.bpp`. |
| `glyphs` | Lô glyph tăng dần được đẩy lần này, tối đa 64 phần tử. |

Mỗi phần tử sử dụng các metric phông bitmap nguyên bản của LVGL:

| Trường | Ý nghĩa |
|---|---|
| `codepoint` | Unicode code point từ `1` đến `0x10FFFF`. |
| `adv_w` | Advance ngang theo đơn vị fixed-point của LVGL, có bốn bit phần lẻ (16 đơn vị bằng một pixel). |
| `box_w`, `box_h` | Kích thước bitmap theo pixel. Mỗi chiều phải nằm trong khoảng từ 0 đến 64. |
| `ofs_x`, `ofs_y` | Offset glyph có dấu, 16 bit, tính tương đối với baseline văn bản và vị trí con trỏ. |
| `bitmap` | Bitmap plain chưa nén của LVGL được mã hóa Base64. |

Độ dài bitmap sau giải mã phải chính xác bằng:

```text
ceil(box_w * box_h * bpp / 8)
```

Bitmap phải dùng cùng cách bố trí plain, stride bằng 0 như phông Noto full-bundle CBIN tương ứng. Máy chủ nên trích xuất và chuyển tiếp trực tiếp bitmap cùng metric từ profile CBIN đó, thay vì raster hóa một phông chữ khác tại thời điểm xử lý yêu cầu.

Tổng kích thước các bitmap sau giải mã trong một payload không được vượt quá 64 KiB. Nếu header, glyph hoặc bitmap bất kỳ không hợp lệ, thiết bị từ chối toàn bộ payload glyph nhưng vẫn hiển thị văn bản thông điệp bằng phông đã cài. Thiết bị có PSRAM cũng có thể dùng glyph fallback được lưu từ các thông điệp trước.

## 3. Thuật toán chọn glyph phía máy chủ

Với mỗi kết nối quảng bá `glyph_push: true`, máy chủ nên:

1. Tìm gói phông đầy đủ được nhận diện bởi `text_font.bundle`.
2. Chọn profile CBIN khớp với `text_font.size` và `text_font.bpp`.
3. Giải mã văn bản thông điệp thành các Unicode code point.
4. Loại bỏ ký tự điều khiển, ký tự trùng lặp và code point đã có trong `text_font.charset`.
5. Trích xuất các glyph còn lại từ gói đầy đủ.
6. Áp dụng giới hạn cho từng thông điệp và đính kèm một đối tượng `glyph_push` vào thông điệp văn bản.
7. Bỏ `glyph_push` nếu không còn glyph bị thiếu nào để gửi.

Thiết bị tìm trong phông văn bản đã cài trước khi tìm trong phông fallback động. Vì vậy, glyph được đẩy lên chỉ bổ sung code point còn thiếu; chúng không ghi đè glyph đã có trong `basic` hoặc `common`.

Một tiến trình máy chủ có thể dùng chung gói phông đầy đủ cho tất cả kết nối thiết bị. Công việc theo từng kết nối chỉ cần sử dụng bộ khả năng `(bundle, charset, size, bpp)` để chọn glyph còn thiếu và profile cần đọc.

## 4. Hành vi bộ nhớ đệm trên thiết bị

Tất cả glyph trong một thông điệp được đưa vào trước, sau đó chỉ dựng lại phông fallback một lần. Thiết bị không dựng lại phông sau từng glyph.

Trên thiết bị đã khởi tạo PSRAM:

- bộ nhớ cho bitmap, cmap, descriptor và mục cache được cấp phát trong PSRAM;
- glyph được giữ lại qua nhiều thông điệp;
- cache chứa tối đa 256 glyph và 64 KiB dữ liệu bitmap sau giải mã;
- khi vượt giới hạn, các mục được chèn hoặc cập nhật lâu nhất trước sẽ bị loại bỏ.

Trên thiết bị không có PSRAM:

- dữ liệu được lưu trong RAM nội bộ;
- chỉ giữ lại lô glyph của thông điệp hiện tại;
- thông điệp văn bản kế tiếp sẽ thay thế hoặc xóa lô trước đó.

Khác biệt này không ảnh hưởng giao thức. Máy chủ có thể gửi glyph cần thiết cho từng thông điệp mà không cần biết thiết bị có PSRAM hay không.

## 5. Khả năng tương thích và quản lý phiên bản

Máy chủ không được gửi glyph khi có bất kỳ điều kiện nào sau đây:

- `features.glyph_push` không có, hoặc máy chủ không hỗ trợ phần mở rộng này;
- máy chủ không có gói được thiết bị quảng bá;
- không có profile phông đầy đủ khớp với size và bpp được quảng bá;
- dữ liệu glyph không đáp ứng quy tắc kiểm tra của phiên bản 1.

Cơ chế fallback là tự động: thông điệp không có `glyph_push` hoặc có payload glyph bị từ chối vẫn được xử lý bình thường.

Khi trình tạo phông thay đổi metric, cách bố trí bitmap, phông nguồn, bộ ký tự hoặc hành vi hiển thị, hãy phát hành mã định danh bundle tường minh mới. Không gửi glyph của bundle này dưới mã định danh của bundle khác, kể cả khi size và bpp tình cờ giống nhau.

## 6. Yêu cầu bảo mật

Payload glyph là dữ liệu đầu vào mạng không đáng tin cậy. Phần triển khai phải kiểm tra toàn bộ payload trước khi thay đổi phông đang hoạt động, giới hạn cả số phần tử lẫn kích thước sau giải mã, xác minh độ dài sau khi giải mã Base64, đồng thời từ chối code point hoặc metric không hợp lệ. Máy chủ cũng nên giới hạn lượng xử lý cho mỗi thông điệp và tránh gửi lại glyph đã có trong bộ ký tự được quảng bá.

