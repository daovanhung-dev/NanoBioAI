# Hướng dẫn tạo bo mạch tùy chỉnh

Tài liệu này hướng dẫn cách thêm một bo mạch mới vào dự án trợ lý giọng nói AI XiaoZhi. XiaoZhi AI hỗ trợ hơn 70 bo thuộc dòng ESP32; mã của mỗi bo nằm trong thư mục riêng dưới `main/boards/`.

## Quan trọng

> **Cảnh báo**: Với bo tùy chỉnh có cấu hình I/O khác bo hiện có, tuyệt đối không ghi đè cấu hình của bo gốc. Luôn tạo một loại bo mới, hoặc dùng mảng `builds` trong `config.json` để tạo tên firmware riêng cùng các macro `sdkconfig` khác. Dùng `python scripts/build.py [board-directory]` để build firmware.
>
> Ghi đè cấu hình bo hiện có rất nguy hiểm vì cập nhật OTA có thể thay firmware tùy chỉnh bằng firmware gốc của bo ban đầu. Mỗi bo phải có danh tính riêng và kênh cập nhật firmware riêng.

## Cấu trúc thư mục

Một thư mục bo thường có:

- `xxx_board.cc` - mã khởi tạo và kết nối các thành phần cấp bo.
- `config.h` - ánh xạ chân và các thiết lập cấp bo.
- `config.json` - loại bo được báo cáo và cấu hình phát hành mà CMake cùng `scripts/build.py` sử dụng.
- `README.md` - ghi chú riêng cho bo.

Thư mục bo có thể nằm trực tiếp dưới `main/boards/` hoặc được nhóm theo nhà sản xuất dưới `main/boards/<manufacturer>/<board>/` (xem phần [Thư mục con theo nhà sản xuất](#thư-mục-con-theo-nhà-sản-xuất)).

## Các bước

### 1. Tạo thư mục bo

Tạo thư mục mới dưới `main/boards/` theo quy ước đặt tên `[vendor]-[model]` (ví dụ `m5stack-tab5`):

```bash
mkdir main/boards/my-custom-board
```

### 2. Tạo các tệp cấu hình

#### config.h

Khai báo mọi thiết lập phần cứng trong `config.h`:

- Tần số lấy mẫu âm thanh và ánh xạ chân I2S.
- Địa chỉ I2C và các chân của codec âm thanh.
- Chân nút bấm và LED.
- Tham số và chân kết nối màn hình.

Ví dụ (từ `lichuang-c3-dev`):

```c
#ifndef _BOARD_CONFIG_H_
#define _BOARD_CONFIG_H_

#include <driver/gpio.h>

// Âm thanh
#define AUDIO_INPUT_SAMPLE_RATE  24000
#define AUDIO_OUTPUT_SAMPLE_RATE 24000

#define AUDIO_I2S_GPIO_MCLK GPIO_NUM_10
#define AUDIO_I2S_GPIO_WS   GPIO_NUM_12
#define AUDIO_I2S_GPIO_BCLK GPIO_NUM_8
#define AUDIO_I2S_GPIO_DIN  GPIO_NUM_7
#define AUDIO_I2S_GPIO_DOUT GPIO_NUM_11

#define AUDIO_CODEC_PA_PIN       GPIO_NUM_13
#define AUDIO_CODEC_I2C_SDA_PIN  GPIO_NUM_0
#define AUDIO_CODEC_I2C_SCL_PIN  GPIO_NUM_1
#define AUDIO_CODEC_ES8311_ADDR  ES8311_CODEC_DEFAULT_ADDR

// Nút bấm
#define BOOT_BUTTON_GPIO        GPIO_NUM_9

// Màn hình
#define DISPLAY_SPI_SCK_PIN     GPIO_NUM_3
#define DISPLAY_SPI_MOSI_PIN    GPIO_NUM_5
#define DISPLAY_DC_PIN          GPIO_NUM_6
#define DISPLAY_SPI_CS_PIN      GPIO_NUM_4

#define DISPLAY_WIDTH   320
#define DISPLAY_HEIGHT  240
#define DISPLAY_MIRROR_X true
#define DISPLAY_MIRROR_Y false
#define DISPLAY_SWAP_XY true

#define DISPLAY_OFFSET_X  0
#define DISPLAY_OFFSET_Y  0

#define DISPLAY_BACKLIGHT_PIN GPIO_NUM_2
#define DISPLAY_BACKLIGHT_OUTPUT_INVERT true

#endif // _BOARD_CONFIG_H_
```

#### config.json

`config.json` định nghĩa loại bo được báo cáo, yếu tố ảnh hưởng đến khả năng tương thích, và điều khiển `scripts/build.py`:

```json
{
    "type": "my-custom-board",
    "target": "esp32s3",
    "builds": [
        {
            "name": "my-custom-board",
            "sdkconfig_append": [
                "CONFIG_ESPTOOLPY_FLASHSIZE_8MB=y",
                "CONFIG_PARTITION_TABLE_CUSTOM_FILENAME=\"partitions/v2/8m.csv\""
            ]
        }
    ]
}
```

**Các trường**:
- `type`: họ bo tương thích được firmware báo cáo. Giữ ổn định sau khi phát hành.
- `target`: chip mục tiêu, phải khớp phần cứng thực tế (`esp32`, `esp32s3`, `esp32c3`, `esp32c6`, `esp32p4`, ...).
- `name`: tên biến thể firmware được báo cáo trong bản phát hành; thường trùng với `type`.
- `sdkconfig_append`: các dòng cấu hình sdkconfig bổ sung, được hợp nhất với giá trị mặc định.

Cả `type` và `name` chỉ được chứa chữ thường, chữ số, dấu chấm (`.`) và dấu gạch nối (`-`). Không cho phép dấu gạch dưới, dấu cách hoặc chữ hoa.

**Các mục `sdkconfig_append` thường dùng**:

```json
// Dung lượng flash
"CONFIG_ESPTOOLPY_FLASHSIZE_4MB=y"
"CONFIG_ESPTOOLPY_FLASHSIZE_8MB=y"

// Bảng phân vùng
"CONFIG_PARTITION_TABLE_CUSTOM_FILENAME=\"partitions/v2/4m.csv\""
"CONFIG_PARTITION_TABLE_CUSTOM_FILENAME=\"partitions/v2/8m.csv\""

// Pipeline âm thanh
"CONFIG_USE_DEVICE_AEC=y"          // bật AEC trên thiết bị
```

Trên các target áp dụng, dự án mặc định dùng flash 16 MB và `partitions/v2/16m.csv`. Không lặp lại các giá trị đã khớp với mặc định hiệu lực của dự án và target; chỉ dùng `sdkconfig_append` cho phần ghi đè thực sự riêng cho bo.

Không chọn ngôn ngữ hoặc từ đánh thức cụ thể trong `config.json` của bo. Đây là tùy chọn build của người dùng và phải được cấu hình thống nhất qua `menuconfig` hoặc tham số của build script để CLI, agent và dịch vụ build trực tuyến dùng chung một giao diện. `scripts/build.py` cũng chọn engine từ đánh thức, vì vậy không thêm mục `CONFIG_USE_*_WAKE_WORD` hoặc lựa chọn model vào preset bo hay chip. Bo cần tắt phát hiện từ đánh thức vì giới hạn bộ nhớ, flash hoặc hiệu năng có thể đặt `CONFIG_WAKE_WORD_DISABLED=y` trong `sdkconfig_append`. Build script giữ nguyên lựa chọn tắt này và báo `wake_word_supported` là `false` cho biến thể.

### 3. Triển khai lớp bo

Tạo `my_custom_board.cc` để chứa phần triển khai cấp bo.

Một lớp bo cơ bản có:

1. **Khai báo lớp**: kế thừa từ `WifiBoard` hoặc `Ml307Board`.
2. **Các hàm khởi tạo**: I2C, màn hình, nút bấm, công cụ IoT/MCP, v.v.
3. **Ghi đè hàm ảo**: `GetAudioCodec()`, `GetDisplay()`, `GetBacklight()`, ...
4. **Đăng ký bo**: `DECLARE_BOARD(ClassName)`.

```cpp
#include "wifi_board.h"
#include "codecs/es8311_audio_codec.h"
#include "display/lcd_display.h"
#include "application.h"
#include "button.h"
#include "config.h"
#include "mcp_server.h"

#include <esp_log.h>
#include <driver/i2c_master.h>
#include <driver/spi_common.h>

#define TAG "MyCustomBoard"

class MyCustomBoard : public WifiBoard {
private:
    i2c_master_bus_handle_t codec_i2c_bus_;
    Button boot_button_;
    LcdDisplay* display_;

    void InitializeI2c() {
        i2c_master_bus_config_t i2c_bus_cfg = {
            .i2c_port = I2C_NUM_0,
            .sda_io_num = AUDIO_CODEC_I2C_SDA_PIN,
            .scl_io_num = AUDIO_CODEC_I2C_SCL_PIN,
            .clk_source = I2C_CLK_SRC_DEFAULT,
            .glitch_ignore_cnt = 7,
            .intr_priority = 0,
            .trans_queue_depth = 0,
            .flags = {
                .enable_internal_pullup = 1,
            },
        };
        ESP_ERROR_CHECK(i2c_new_master_bus(&i2c_bus_cfg, &codec_i2c_bus_));
    }

    void InitializeSpi() {
        spi_bus_config_t buscfg = {};
        buscfg.mosi_io_num = DISPLAY_SPI_MOSI_PIN;
        buscfg.miso_io_num = GPIO_NUM_NC;
        buscfg.sclk_io_num = DISPLAY_SPI_SCK_PIN;
        buscfg.quadwp_io_num = GPIO_NUM_NC;
        buscfg.quadhd_io_num = GPIO_NUM_NC;
        buscfg.max_transfer_sz = DISPLAY_WIDTH * DISPLAY_HEIGHT * sizeof(uint16_t);
        ESP_ERROR_CHECK(spi_bus_initialize(SPI2_HOST, &buscfg, SPI_DMA_CH_AUTO));
    }

    void InitializeButtons() {
        boot_button_.OnClick([this]() {
            auto& app = Application::GetInstance();
            if (app.GetDeviceState() == kDeviceStateStarting) {
                EnterWifiConfigMode();
                return;
            }
            app.ToggleChatState();
        });
    }

    void InitializeDisplay() {
        esp_lcd_panel_io_handle_t panel_io = nullptr;
        esp_lcd_panel_handle_t panel = nullptr;

        esp_lcd_panel_io_spi_config_t io_config = {};
        io_config.cs_gpio_num = DISPLAY_SPI_CS_PIN;
        io_config.dc_gpio_num = DISPLAY_DC_PIN;
        io_config.spi_mode = 2;
        io_config.pclk_hz = 80 * 1000 * 1000;
        io_config.trans_queue_depth = 10;
        io_config.lcd_cmd_bits = 8;
        io_config.lcd_param_bits = 8;
        ESP_ERROR_CHECK(esp_lcd_new_panel_io_spi(SPI2_HOST, &io_config, &panel_io));

        esp_lcd_panel_dev_config_t panel_config = {};
        panel_config.reset_gpio_num = GPIO_NUM_NC;
        panel_config.rgb_ele_order = LCD_RGB_ELEMENT_ORDER_RGB;
        panel_config.bits_per_pixel = 16;
        ESP_ERROR_CHECK(esp_lcd_new_panel_st7789(panel_io, &panel_config, &panel));

        esp_lcd_panel_reset(panel);
        esp_lcd_panel_init(panel);
        esp_lcd_panel_invert_color(panel, true);
        esp_lcd_panel_swap_xy(panel, DISPLAY_SWAP_XY);
        esp_lcd_panel_mirror(panel, DISPLAY_MIRROR_X, DISPLAY_MIRROR_Y);

        display_ = new SpiLcdDisplay(panel_io, panel,
                                    DISPLAY_WIDTH, DISPLAY_HEIGHT,
                                    DISPLAY_OFFSET_X, DISPLAY_OFFSET_Y,
                                    DISPLAY_MIRROR_X, DISPLAY_MIRROR_Y, DISPLAY_SWAP_XY);
    }

    void InitializeTools() {
        // Đăng ký các công cụ MCP tại đây; xem docs/mcp-usage_vi.md.
    }

public:
    MyCustomBoard() : boot_button_(BOOT_BUTTON_GPIO) {
        InitializeI2c();
        InitializeSpi();
        InitializeDisplay();
        InitializeButtons();
        InitializeTools();
        GetBacklight()->SetBrightness(100);
    }

    virtual AudioCodec* GetAudioCodec() override {
        static Es8311AudioCodec audio_codec(
            codec_i2c_bus_,
            I2C_NUM_0,
            AUDIO_INPUT_SAMPLE_RATE,
            AUDIO_OUTPUT_SAMPLE_RATE,
            AUDIO_I2S_GPIO_MCLK,
            AUDIO_I2S_GPIO_BCLK,
            AUDIO_I2S_GPIO_WS,
            AUDIO_I2S_GPIO_DOUT,
            AUDIO_I2S_GPIO_DIN,
            AUDIO_CODEC_PA_PIN,
            AUDIO_CODEC_ES8311_ADDR);
        return &audio_codec;
    }

    virtual Display* GetDisplay() override {
        return display_;
    }

    virtual Backlight* GetBacklight() override {
        static PwmBacklight backlight(DISPLAY_BACKLIGHT_PIN, DISPLAY_BACKLIGHT_OUTPUT_INVERT);
        return &backlight;
    }
};

DECLARE_BOARD(MyCustomBoard);
```

### 4. Tích hợp hệ thống build

#### Thêm mục Kconfig

Trong `main/Kconfig.projbuild`, thêm mục vào khối `choice BOARD_TYPE`:

```kconfig
choice BOARD_TYPE
    prompt "Board Type"
    default BOARD_TYPE_BREAD_COMPACT_WIFI
    help
        Board type.

    # ... các mục khác ...

    config BOARD_TYPE_MY_CUSTOM_BOARD
        bool "My Custom Board"
        depends on IDF_TARGET_ESP32S3  # chọn target phù hợp
endchoice
```

Lưu ý:
- Mã định danh phải viết HOA và dùng dấu gạch dưới để phân tách.
- `depends on` giới hạn mục này ở target phù hợp (`IDF_TARGET_ESP32S3`, `IDF_TARGET_ESP32C3`, ...).
- Nhãn hiển thị có thể được bản địa hóa.

#### Thêm nhánh vào CMakeLists.txt

Mở `main/CMakeLists.txt` và bổ sung vào chuỗi chọn loại bo:

```cmake
elseif(CONFIG_BOARD_TYPE_MY_CUSTOM_BOARD)
    set(BOARD_DIR "my-custom-board")
    set(BUILTIN_TEXT_FONT font_puhui_basic_20_4)     # chọn phông cho màn hình
    set(BUILTIN_ICON_FONT font_awesome_20_4)
    set(DEFAULT_EMOJI_COLLECTION twemoji_64)         // tùy chọn, để hiển thị emoji
```

**Hướng dẫn chọn phông và emoji**:

Chọn cỡ phông phù hợp với độ phân giải màn hình:
- Nhỏ (OLED 128x64): `font_puhui_basic_14_1` / `font_awesome_14_1`
- Nhỏ-vừa (240x240): `font_puhui_basic_16_4` / `font_awesome_16_4`
- Vừa (240x320): `font_puhui_basic_20_4` / `font_awesome_20_4`
- Lớn (480x320 trở lên): `font_puhui_basic_30_4` / `font_awesome_30_4`

Các bộ emoji:
- `twemoji_32` - 32x32 pixel (màn hình nhỏ).
- `twemoji_64` - 64x64 pixel (màn hình lớn).

### 5. Build và flash

#### Phương án A - dùng idf.py thủ công

1. Chọn chip mục tiêu (lần đầu hoặc khi đổi target):
   ```bash
   idf.py set-target esp32s3     # ESP32-S3
   idf.py set-target esp32c3     # ESP32-C3
   idf.py set-target esp32       # ESP32
   ```

2. Xóa cấu hình cũ:
   ```bash
   idf.py fullclean
   ```

3. Chọn bo qua menuconfig:
   ```bash
   idf.py menuconfig
   ```
   Điều hướng đến `Xiaozhi Assistant -> Board Type` và chọn bo của bạn.

4. Build và flash:
   ```bash
   idf.py build
   idf.py flash monitor
   ```

#### Phương án B - dùng `build.py` (khuyến nghị)

Nếu thư mục bo có `config.json`, bạn có thể tự động cấu hình và build:

```bash
python scripts/build.py my-custom-board
```

Ngôn ngữ và từ đánh thức là các tùy chọn build của người dùng:

```bash
python scripts/build.py my-custom-board \
  --language en-US \
  --wake-word wn9_jarvis_tts
```

Ngôn ngữ mặc định trong Kconfig của dự án là tiếng Anh (`en-US`). `scripts/build.py` cũng chọn tiếng Anh nếu bỏ qua `--language`, kể cả khi lần build trước dùng ngôn ngữ khác. Truyền `--language zh-CN` để chọn tiếng Trung hoặc một locale khác trong `main/assets/locales/`. Lựa chọn này áp dụng cho nội dung giao diện và lời nhắc bằng giọng nói. Nếu bỏ qua `--wake-word` trên bo được hỗ trợ, script chọn “你好小智” cho `zh-CN` và `zh-TW`, và “Hi ESP” cho mọi ngôn ngữ khác. Bo hoặc biến thể không hỗ trợ, cũng như biến thể có opt-out tường minh, sẽ giữ tính năng tắt.

Tham số `--wake-word` ghi đè mặc định theo ngôn ngữ. Tham số chấp nhận tên model ESP-SR, `nihaoxiaozhi`, `hiesp` hoặc `disabled`. Hai bí danh chọn model tương thích với target. Target ESP32-C3/C5/C6 dùng model WakeNet9s (`wn9s_*`); ESP32-S3/P4/S31 dùng engine AFE và cần PSRAM. ESP32 cũng cần PSRAM và dùng engine không có AFE. Yêu cầu bật phát hiện từ đánh thức trên bo không hỗ trợ hoặc bị tắt tường minh sẽ bị từ chối trước khi cấu hình SDK.

Assets Custom và Emote giữ nguyên tài nguyên giao diện, nhưng model giọng nói được đóng gói sẽ được thay bằng model đã chọn trong `sdkconfig` hiện tại (hoặc bị gỡ nếu tắt phát hiện từ đánh thức). Gói kết quả phải vừa phân vùng assets. Khi build trực tiếp bằng `idf.py`, hãy chọn tường minh phần triển khai và model từ đánh thức trong `menuconfig`; preset chip không chọn model, còn cấu hình thủ công mới tạo sẽ để tính năng phát hiện từ đánh thức ở trạng thái tắt.

Tra cứu các giá trị được chấp nhận ở dạng văn bản hoặc máy đọc được:

```bash
python scripts/build.py --list-languages
python scripts/build.py --list-languages --json
python scripts/build.py --list-wake-words
python scripts/build.py --list-wake-words --json
```

Danh sách từ đánh thức được đọc từ component ESP-SR đã phân giải hiện tại, vì vậy hãy chạy `idf.py reconfigure` trước nếu `managed_components/` chưa được nạp.

Script:
- Hiển thị trợ giúp nếu chạy không có tham số. Dùng `--list-boards` để liệt kê loại bo và các biến thể.
- Yêu cầu chọn biến thể nếu bo được chọn có nhiều cấu hình build. Trong môi trường không tương tác, truyền `--name <variant>`.
- Đọc `target` từ `config.json`, chỉ xóa thư mục build hiện có khi target khác, sau đó cấu hình target, tên bo, mặc định và `sdkconfig_append` của build được chọn trong một lần gọi `idf.py reconfigure`. Lệnh `idf.py build` tiếp theo dùng lại cấu hình đó.
- Truyền `name` của build đã chọn làm tên biến thể firmware được báo cáo.
- Theo mặc định, tạo `build/merged-binary.bin` mà không tạo ZIP. Truyền `--zip` để tạo lại `releases/v<version>_<name>.zip`.

### 6. Viết README

Trong `README.md`, mô tả bo, yêu cầu phần cứng, hướng dẫn build và mọi lưu ý đặc biệt.

## Thư mục con theo nhà sản xuất

Có thể nhóm bo theo nhà sản xuất dưới `main/boards/<manufacturer>/<board>/`. Đây là bố cục được khuyến nghị khi một nhà cung cấp có nhiều biến thể dùng chung driver, assets hoặc tài liệu, ví dụ `main/boards/waveshare/esp32-p4-nano/` hoặc `main/boards/lceda-course-examples/eda-tv-pro/`.

Với bo nằm trong thư mục con theo nhà sản xuất, thêm cùng giá trị vào `config.json`, ví dụ `"manufacturer": "waveshare"`. Firmware báo cáo giá trị này dưới dạng `board.manufacturer` cùng với `board.type` và `board.name`. Bo cộng đồng đặt trực tiếp dưới thư mục boards và không có trường này sẽ báo chuỗi manufacturer rỗng.

Đặt `BOARD_DIR` thành đường dẫn đầy đủ tính từ `main/boards/`:

```cmake
elseif(CONFIG_BOARD_TYPE_WAVESHARE_ESP32_P4_NANO)
    set(BOARD_DIR "waveshare/esp32-p4-nano")
    set(BUILTIN_TEXT_FONT font_puhui_basic_30_4)
    set(BUILTIN_ICON_FONT font_awesome_30_4)
    set(DEFAULT_EMOJI_COLLECTION twemoji_64)
```

Hệ thống build nạp mã nguồn từ `main/boards/${BOARD_DIR}/` và đọc loại bo được báo cáo từ `config.json` trong thư mục đó. Nếu không có `config.json` hoặc thiếu trường cấp cao nhất `type`, toàn bộ `BOARD_DIR` sẽ được dùng làm loại bo dự phòng sau khi thay `/` bằng `-`.

Quy tắc kinh nghiệm:
- Dùng bố cục theo nhà sản xuất khi cùng nhà cung cấp có từ hai bo trở lên dùng chung driver, assets hoặc tài liệu.
- Dùng bố cục phẳng cho bo riêng lẻ và ví dụ cộng đồng.
- Tên thư mục dùng chữ thường và dấu gạch nối (ví dụ `waveshare`, `lceda-course-examples`).

## Component dùng chung cho bo

Một số component có thể tái sử dụng nằm trong `main/boards/common/`. Có thể include trực tiếp chúng trong lớp bo:

### Driver màn hình

Các họ LCD được hỗ trợ gồm:
- ST7789 (SPI)
- ILI9341 (SPI)
- SH8601 (QSPI)
- và nhiều loại khác.

### Codec âm thanh

- `Es8311AudioCodec` (phổ biến nhất)
- `Es8374AudioCodec`
- `Es8388AudioCodec`
- `Es8389AudioCodec`
- `BoxAudioCodec` (kết hợp mảng micro ES7210 và codec, dùng trên các bo ESP-Box)
- `NoAudioCodec` (I2S trực tiếp, không có codec ngoài)
- `DummyAudioCodec` (placeholder cho bo không có âm thanh)

### Quản lý nguồn

- Các helper cho IC quản lý nguồn `Axp2101`.
- Các helper cho bộ sạc pin `Sy6970`.
- `AdcBatteryMonitor` - bộ giám sát điện áp pin đơn giản dựa trên ADC.
- `PowerSaveTimer` / `SleepTimer` - helper lập lịch chế độ ngủ nhẹ.

### Kết nối mạng

- `WifiBoard` - lớp cơ sở chỉ dùng WiFi.
- `Ml307Board` / `Nt26Board` - lớp cơ sở cho modem 4G.
- `DualNetworkBoard` - lớp cơ sở có thể chuyển đổi WiFi / 4G.
- `RndisBoard` - kết nối mạng RNDIS qua USB (ESP32-S3 / ESP32-P4).
- Các helper `EspVideo` cho ESP-Video trên ESP32-S3 / ESP32-P4.

### Helper đầu vào

- `Button` - nút nhấn tiêu chuẩn (nhấn, nhấn giữ, nhấn nhiều lần).
- `Knob` - lớp bọc cho encoder xoay.
- `PressToTalkMcpTool` - công cụ nhấn để nói, tự đăng ký qua MCP.
- `SystemReset` - helper thực hiện khôi phục cài đặt gốc an toàn khi giữ nút lúc khởi động.

### Tích hợp MCP

Mọi bo đều có thể đăng ký công cụ tùy chỉnh như điều khiển loa, độ sáng màn hình, đọc pin, điều khiển đèn, v.v. Xem [Cách dùng MCP để điều khiển IoT](./mcp-usage_vi.md).

## Phân cấp lớp bo

- `Board` - lớp cơ sở
  - `WifiBoard` - bo kết nối WiFi
  - `Ml307Board` / `Nt26Board` - bo dùng modem 4G
  - `DualNetworkBoard` - bo chuyển đổi WiFi + 4G
  - `RndisBoard` - bo mạng qua USB RNDIS

## Mẹo

1. **Bắt đầu từ bo tương tự** - sao chép và điều chỉnh một bo hiện có thường nhanh hơn bắt đầu từ đầu.
2. **Khởi tạo từng phần** - làm cho màn hình hoạt động trước, sau đó đến âm thanh rồi toàn bộ hệ thống.
3. **Kiểm tra kỹ ánh xạ chân** - mọi chân trong `config.h` phải khớp sơ đồ mạch.
4. **Kiểm tra tương thích phần cứng** - đặc biệt là tổ hợp codec / PMIC / bộ điều khiển cảm ứng.

## Khắc phục sự cố

1. **Màn hình hiển thị sai** - kiểm tra cấu hình SPI, phép phản chiếu và đảo màu.
2. **Không có âm thanh** - kiểm tra dây I2S, chân bật PA và địa chỉ I2C của codec.
3. **Không kết nối được WiFi** - kiểm tra lại thông tin đăng nhập và phương thức cấu hình mạng.
4. **Không truy cập được máy chủ** - xác minh cấu hình endpoint WebSocket / MQTT.

## Tài liệu tham khảo

- Tài liệu ESP-IDF: https://docs.espressif.com/projects/esp-idf/
- Tài liệu LVGL: https://docs.lvgl.io/
- Tài liệu ESP-SR: https://github.com/espressif/esp-sr

