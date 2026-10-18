#include "application.h"
#include "assets/lang_config.h"
#include "button.h"
#include "codecs/box_audio_codec.h"
#include "config.h"
#include "display/lcd_display.h"
#include "wifi_board.h"

#include <driver/gpio.h>
#include <driver/i2c_master.h>
#include <driver/spi_master.h>
#include <esp_lcd_nv3023.h>
#include <esp_lcd_panel_io.h>
#include <esp_lcd_panel_ops.h>
#include <esp_lcd_panel_vendor.h>
#include <esp_lcd_touch_cst816s.h>
#include <esp_log.h>
#include <esp_lvgl_port.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <algorithm>
#include <string>

static const nv3023_lcd_init_cmd_t lcd_init_cmds[] = {
    {0xFF, (uint8_t[]){0xA5}, 1, 0},   {0x3E, (uint8_t[]){0x09}, 1, 0},
    {0x3A, (uint8_t[]){0x65}, 1, 0},   {0x82, (uint8_t[]){0x00}, 1, 0},
    {0x98, (uint8_t[]){0x00}, 1, 0},   {0x63, (uint8_t[]){0x0F}, 1, 0},
    {0x64, (uint8_t[]){0x0F}, 1, 0},   {0xB4, (uint8_t[]){0x34}, 1, 0},
    {0xB5, (uint8_t[]){0x30}, 1, 0},   {0x83, (uint8_t[]){0x03}, 1, 0},
    {0x86, (uint8_t[]){0x04}, 1, 0},   {0x87, (uint8_t[]){0x16}, 1, 0},
    {0x88, (uint8_t[]){0x0A}, 1, 0},   {0x89, (uint8_t[]){0x27}, 1, 0},
    {0x93, (uint8_t[]){0x63}, 1, 0},   {0x96, (uint8_t[]){0x81}, 1, 0},
    {0xC3, (uint8_t[]){0x10}, 1, 0},   {0xE6, (uint8_t[]){0x00}, 1, 0},
    {0x99, (uint8_t[]){0x01}, 1, 0},   {0x70, (uint8_t[]){0x09}, 1, 0},
    {0x71, (uint8_t[]){0x1D}, 1, 0},   {0x72, (uint8_t[]){0x14}, 1, 0},
    {0x73, (uint8_t[]){0x0A}, 1, 0},   {0x74, (uint8_t[]){0x11}, 1, 0},
    {0x75, (uint8_t[]){0x16}, 1, 0},   {0x76, (uint8_t[]){0x38}, 1, 0},
    {0x77, (uint8_t[]){0x0B}, 1, 0},   {0x78, (uint8_t[]){0x08}, 1, 0},
    {0x79, (uint8_t[]){0x3E}, 1, 0},   {0x7A, (uint8_t[]){0x07}, 1, 0},
    {0x7B, (uint8_t[]){0x0D}, 1, 0},   {0x7C, (uint8_t[]){0x16}, 1, 0},
    {0x7D, (uint8_t[]){0x0F}, 1, 0},   {0x7E, (uint8_t[]){0x14}, 1, 0},
    {0x7F, (uint8_t[]){0x05}, 1, 0},   {0xA0, (uint8_t[]){0x04}, 1, 0},
    {0xA1, (uint8_t[]){0x28}, 1, 0},   {0xA2, (uint8_t[]){0x0C}, 1, 0},
    {0xA3, (uint8_t[]){0x11}, 1, 0},   {0xA4, (uint8_t[]){0x0B}, 1, 0},
    {0xA5, (uint8_t[]){0x23}, 1, 0},   {0xA6, (uint8_t[]){0x45}, 1, 0},
    {0xA7, (uint8_t[]){0x07}, 1, 0},   {0xA8, (uint8_t[]){0x0A}, 1, 0},
    {0xA9, (uint8_t[]){0x3B}, 1, 0},   {0xAA, (uint8_t[]){0x0D}, 1, 0},
    {0xAB, (uint8_t[]){0x18}, 1, 0},   {0xAC, (uint8_t[]){0x14}, 1, 0},
    {0xAD, (uint8_t[]){0x0F}, 1, 0},   {0xAE, (uint8_t[]){0x19}, 1, 0},
    {0xAF, (uint8_t[]){0x08}, 1, 0},   {0xFF, (uint8_t[]){0x00}, 1, 0},
    {0x11, (uint8_t[]){0x00}, 0, 120}, {0x29, (uint8_t[]){0x00}, 0, 10},
};

class OstbXiaozhi3stBoard : public WifiBoard {
private:
    Button boot_button_;
    Button volume_up_button_;
    Button volume_down_button_;
    i2c_master_bus_handle_t i2c_bus_ = nullptr;
    esp_lcd_panel_io_handle_t panel_io_ = nullptr;
    esp_lcd_panel_handle_t panel_ = nullptr;
    esp_lcd_touch_handle_t touch_ = nullptr;
    esp_lcd_panel_io_handle_t touch_io_ = nullptr;
    lv_indev_t* touch_indev_ = nullptr;
    SpiLcdDisplay* display_ = nullptr;

    static void HandleTouchEvent(lv_event_t* event) {
        auto* self = static_cast<OstbXiaozhi3stBoard*>(lv_event_get_user_data(event));
        if (self == nullptr) {
            return;
        }

        ESP_LOGI("OSTB_3ST", "Touch tap detected");
        Application::GetInstance().Schedule([self]() {
            auto& app = Application::GetInstance();
            if (app.GetDeviceState() == kDeviceStateStarting) {
                self->EnterWifiConfigMode();
            } else {
                app.ToggleChatState();
            }
        });
    }

    void PulseDisplayReset() {
        ESP_ERROR_CHECK(gpio_set_level(DISPLAY_RESET_PIN, 0));
        vTaskDelay(pdMS_TO_TICKS(50));
        ESP_ERROR_CHECK(gpio_set_level(DISPLAY_RESET_PIN, 1));
        vTaskDelay(pdMS_TO_TICKS(120));
    }

    void InitializeI2c() {
        i2c_master_bus_config_t bus_config = {
            .i2c_port = OSTB_I2C_PORT,
            .sda_io_num = AUDIO_CODEC_I2C_SDA_PIN,
            .scl_io_num = AUDIO_CODEC_I2C_SCL_PIN,
            .clk_source = I2C_CLK_SRC_DEFAULT,
            .glitch_ignore_cnt = 7,
            .intr_priority = 0,
            .trans_queue_depth = 0,
            .flags =
                {
                    .enable_internal_pullup = false,
                },
        };
        ESP_ERROR_CHECK(i2c_new_master_bus(&bus_config, &i2c_bus_));
    }

    void InitializeSpi() {
        spi_bus_config_t bus_config = {};
        bus_config.mosi_io_num = DISPLAY_SPI_MOSI_PIN;
        bus_config.miso_io_num = GPIO_NUM_NC;
        bus_config.sclk_io_num = DISPLAY_SPI_SCLK_PIN;
        bus_config.quadwp_io_num = GPIO_NUM_NC;
        bus_config.quadhd_io_num = GPIO_NUM_NC;
        bus_config.max_transfer_sz = DISPLAY_WIDTH * 80 * sizeof(uint16_t);
        ESP_ERROR_CHECK(spi_bus_initialize(SPI2_HOST, &bus_config, SPI_DMA_CH_AUTO));
    }

    void InitializeDisplay() {
        ESP_ERROR_CHECK(gpio_reset_pin(DISPLAY_RESET_PIN));
        ESP_ERROR_CHECK(gpio_set_direction(DISPLAY_RESET_PIN, GPIO_MODE_OUTPUT));

        esp_lcd_panel_io_spi_config_t io_config = {};
        io_config.cs_gpio_num = DISPLAY_SPI_CS_PIN;
        io_config.dc_gpio_num = DISPLAY_DC_PIN;
        io_config.spi_mode = 0;
        io_config.pclk_hz = OSTB_DISPLAY_SPI_CLOCK_HZ;
        io_config.trans_queue_depth = 10;
        io_config.lcd_cmd_bits = 8;
        io_config.lcd_param_bits = 8;
        ESP_ERROR_CHECK(esp_lcd_new_panel_io_spi(SPI2_HOST, &io_config, &panel_io_));

        nv3023_vendor_config_t vendor_config = {
            .init_cmds = lcd_init_cmds,
            .init_cmds_size = sizeof(lcd_init_cmds) / sizeof(lcd_init_cmds[0]),
        };
        esp_lcd_panel_dev_config_t panel_config = {};
        panel_config.reset_gpio_num = GPIO_NUM_NC;
        panel_config.rgb_ele_order = LCD_RGB_ELEMENT_ORDER_BGR;
        panel_config.bits_per_pixel = 16;
        panel_config.vendor_config = &vendor_config;
        ESP_ERROR_CHECK(esp_lcd_new_panel_nv3023(panel_io_, &panel_config, &panel_));
        PulseDisplayReset();
        ESP_ERROR_CHECK(esp_lcd_panel_init(panel_));
        ESP_ERROR_CHECK(esp_lcd_panel_swap_xy(panel_, DISPLAY_SWAP_XY));
        ESP_ERROR_CHECK(esp_lcd_panel_mirror(panel_, DISPLAY_MIRROR_X, DISPLAY_MIRROR_Y));
        ESP_ERROR_CHECK(esp_lcd_panel_invert_color(panel_, false));
        ESP_ERROR_CHECK(esp_lcd_panel_disp_on_off(panel_, true));
        display_ = new SpiLcdDisplay(panel_io_, panel_, DISPLAY_WIDTH, DISPLAY_HEIGHT,
                                     DISPLAY_OFFSET_X, DISPLAY_OFFSET_Y, DISPLAY_MIRROR_X,
                                     DISPLAY_MIRROR_Y, DISPLAY_SWAP_XY);
    }

    void InitializeTouch() {
        esp_lcd_touch_config_t touch_config = {
            .x_max = DISPLAY_WIDTH - 1,
            .y_max = DISPLAY_HEIGHT - 1,
            .rst_gpio_num = GPIO_NUM_NC,
            .int_gpio_num = GPIO_NUM_NC,
            .levels =
                {
                    .reset = 0,
                    .interrupt = 0,
                },
            .flags =
                {
                    .swap_xy = DISPLAY_SWAP_XY,
                    .mirror_x = DISPLAY_MIRROR_X,
                    .mirror_y = DISPLAY_MIRROR_Y,
                },
        };
        esp_lcd_panel_io_i2c_config_t io_config = {};
        io_config.dev_addr = ESP_LCD_TOUCH_IO_I2C_CST816S_ADDRESS;
        io_config.scl_speed_hz = 100 * 1000;
        io_config.control_phase_bytes = 1;
        io_config.dc_bit_offset = 0;
        io_config.lcd_cmd_bits = 8;
        io_config.lcd_param_bits = 0;
        io_config.flags.disable_control_phase = 1;
        ESP_ERROR_CHECK(esp_lcd_new_panel_io_i2c(i2c_bus_, &io_config, &touch_io_));
        ESP_ERROR_CHECK(esp_lcd_touch_new_i2c_cst816s(touch_io_, &touch_config, &touch_));

        const lvgl_port_touch_cfg_t lvgl_touch_config = {
            .disp = lv_display_get_default(),
            .handle = touch_,
        };
        touch_indev_ = lvgl_port_add_touch(&lvgl_touch_config);
        if (touch_indev_ == nullptr) {
            ESP_LOGE("OSTB_3ST", "Failed to register touch input");
            return;
        }
        if (lvgl_port_lock(0)) {
            lv_indev_add_event_cb(touch_indev_, HandleTouchEvent, LV_EVENT_SHORT_CLICKED, this);
            lvgl_port_unlock();
        } else {
            ESP_LOGE("OSTB_3ST", "Failed to lock LVGL while registering touch action");
        }
    }

    void InitializeButtons() {
        boot_button_.OnClick([this]() {
            Application::GetInstance().Schedule([this]() {
                auto& app = Application::GetInstance();
                if (app.GetDeviceState() == kDeviceStateStarting) {
                    EnterWifiConfigMode();
                } else {
                    app.ToggleChatState();
                }
            });
        });
        boot_button_.OnLongPress(
            [this]() { Application::GetInstance().Schedule([this]() { EnterWifiConfigMode(); }); });

        volume_up_button_.OnClick([this]() {
            Application::GetInstance().Schedule([this]() {
                auto* codec = GetAudioCodec();
                int volume = std::min(codec->output_volume() + 10, 100);
                codec->SetOutputVolume(volume);
                GetDisplay()->ShowNotification(Lang::Strings::VOLUME + std::to_string(volume / 10));
            });
        });
        volume_up_button_.OnLongPress([this]() {
            Application::GetInstance().Schedule([this]() {
                GetAudioCodec()->SetOutputVolume(100);
                GetDisplay()->ShowNotification(Lang::Strings::MAX_VOLUME);
            });
        });
        volume_down_button_.OnClick([this]() {
            Application::GetInstance().Schedule([this]() {
                auto* codec = GetAudioCodec();
                int volume = std::max(codec->output_volume() - 10, 0);
                codec->SetOutputVolume(volume);
                GetDisplay()->ShowNotification(Lang::Strings::VOLUME + std::to_string(volume / 10));
            });
        });
        volume_down_button_.OnLongPress([this]() {
            Application::GetInstance().Schedule([this]() {
                GetAudioCodec()->SetOutputVolume(0);
                GetDisplay()->ShowNotification(Lang::Strings::MUTED);
            });
        });
    }

public:
    OstbXiaozhi3stBoard()
        : boot_button_(BOOT_BUTTON_GPIO),
          volume_up_button_(VOLUME_UP_BUTTON_GPIO),
          volume_down_button_(VOLUME_DOWN_BUTTON_GPIO) {
        InitializeI2c();
        InitializeSpi();
        InitializeButtons();
        InitializeDisplay();
        InitializeTouch();
        GetBacklight()->RestoreBrightness();
    }

    AudioCodec* GetAudioCodec() override {
        static BoxAudioCodec audio_codec(
            i2c_bus_, AUDIO_INPUT_SAMPLE_RATE, AUDIO_OUTPUT_SAMPLE_RATE, AUDIO_I2S_GPIO_MCLK,
            AUDIO_I2S_GPIO_BCLK, AUDIO_I2S_GPIO_WS, AUDIO_I2S_GPIO_DOUT, AUDIO_I2S_GPIO_DIN,
            AUDIO_CODEC_PA_PIN, AUDIO_CODEC_ES8311_ADDR, AUDIO_CODEC_ES7210_ADDR,
            AUDIO_INPUT_REFERENCE);
        return &audio_codec;
    }

    Display* GetDisplay() override { return display_; }

    Backlight* GetBacklight() override {
        static PwmBacklight backlight(DISPLAY_BACKLIGHT_PIN, DISPLAY_BACKLIGHT_INVERT);
        return &backlight;
    }
};

DECLARE_BOARD(OstbXiaozhi3stBoard);
