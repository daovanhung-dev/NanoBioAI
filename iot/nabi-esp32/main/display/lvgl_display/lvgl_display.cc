#include <esp_err.h>
#include <esp_log.h>
#include <material_symbols.h>
#include <cstdlib>
#include <cstring>
#include <string>

#if defined(CONFIG_NABI_ESP_ASSISTANT) || defined(CONFIG_NABI_ESP_CLOUD_ASSISTANT)
extern "C" {
extern const uint8_t nabi_setup_rgb565_start[] asm("_binary_nabi_setup_rgb565_start");
extern const uint8_t nabi_setup_rgb565_end[] asm("_binary_nabi_setup_rgb565_end");
}
#endif

#include "application.h"
#include "assets/lang_config.h"
#include "audio_codec.h"
#include "board.h"
#include "dynamic_glyph_cache.h"
#include "jpg/image_to_jpeg.h"
#include "lvgl_display.h"
#include "lvgl_theme.h"
#include "settings.h"

#define TAG "Display"

LvglDisplay::LvglDisplay() {
    dynamic_glyph_cache_ = std::make_unique<DynamicGlyphCache>();
    // Notification timer
    esp_timer_create_args_t notification_timer_args = {
        .callback =
            [](void* arg) {
                LvglDisplay* display = static_cast<LvglDisplay*>(arg);
                DisplayLockGuard lock(display);
                lv_obj_add_flag(display->notification_label_, LV_OBJ_FLAG_HIDDEN);
                lv_obj_remove_flag(display->status_label_, LV_OBJ_FLAG_HIDDEN);
            },
        .arg = this,
        .dispatch_method = ESP_TIMER_TASK,
        .name = "notification_timer",
        .skip_unhandled_events = false,
    };
    ESP_ERROR_CHECK(esp_timer_create(&notification_timer_args, &notification_timer_));

    // Create a power management lock
    auto ret = esp_pm_lock_create(ESP_PM_APB_FREQ_MAX, 0, "display_update", &pm_lock_);
    if (ret == ESP_ERR_NOT_SUPPORTED) {
        ESP_LOGI(TAG, "Power management not supported");
    } else {
        ESP_ERROR_CHECK(ret);
    }
}

bool LvglDisplay::SetTextFont(std::shared_ptr<LvglFont> text_font) {
    if (text_font == nullptr || text_font->font() == nullptr) {
        return false;
    }

    DisplayLockGuard lock(this);
    auto& theme_manager = LvglThemeManager::GetInstance();
    auto light_theme = theme_manager.GetTheme("light");
    auto dark_theme = theme_manager.GetTheme("dark");
    if (light_theme == nullptr && dark_theme == nullptr) {
        return false;
    }

    // LVGL styles keep raw lv_font_t pointers. Keep the previous font owners alive until the
    // current theme has rebound every style to the new font.
    auto previous_light_font = light_theme != nullptr ? light_theme->text_font() : nullptr;
    auto previous_dark_font = dark_theme != nullptr ? dark_theme->text_font() : nullptr;
    if (light_theme != nullptr) {
        light_theme->set_text_font(text_font);
    }
    if (dark_theme != nullptr) {
        dark_theme->set_text_font(text_font);
    }
    if (current_theme_ != nullptr) {
        SetTheme(current_theme_);
    }
    previous_light_font.reset();
    previous_dark_font.reset();
    return true;
}

bool LvglDisplay::AddTextGlyphs(const std::vector<TextGlyph>& glyphs, uint8_t bpp) {
    if (dynamic_glyph_cache_ == nullptr) {
        return false;
    }
    if (glyphs.empty()) {
        if (!TextGlyphStorageUsesPsram()) {
            ClearTextGlyphs();
        }
        return false;
    }
    if (bpp != 1 && bpp != 4) {
        return false;
    }

    DisplayLockGuard lock(this);
    if (!lock || current_theme_ == nullptr) {
        return false;
    }
    auto text_font = current_theme_->GetTextFont();
    if (text_font == nullptr) {
        return false;
    }

    auto fallback = dynamic_glyph_cache_->EnsureFont(text_font->font(), bpp);
    if (fallback == nullptr) {
        return false;
    }
    text_font->SetFallback(fallback);
    return dynamic_glyph_cache_->AddGlyphs(glyphs);
}

void LvglDisplay::ClearTextGlyphs() {
    if (dynamic_glyph_cache_ == nullptr) {
        return;
    }
    DisplayLockGuard lock(this);
    dynamic_glyph_cache_->Clear();
}

LvglDisplay::~LvglDisplay() {
    if (notification_timer_ != nullptr) {
        esp_timer_stop(notification_timer_);
        esp_timer_delete(notification_timer_);
    }

    if (wifi_setup_screen_ != nullptr) {
        lv_obj_del(wifi_setup_screen_);
        wifi_setup_screen_ = nullptr;
    }

    if (network_label_ != nullptr) {
        lv_obj_del(network_label_);
    }
    if (notification_label_ != nullptr) {
        lv_obj_del(notification_label_);
    }
    if (status_label_ != nullptr) {
        lv_obj_del(status_label_);
    }
    if (mute_label_ != nullptr) {
        lv_obj_del(mute_label_);
    }
    if (battery_label_ != nullptr) {
        lv_obj_del(battery_label_);
    }
    if (low_battery_popup_ != nullptr) {
        lv_obj_del(low_battery_popup_);
    }
    if (pm_lock_ != nullptr) {
        esp_pm_lock_delete(pm_lock_);
    }
}

void LvglDisplay::SetStatus(const char* status) {
    if (!setup_ui_called_) {
        ESP_LOGW(TAG, "SetStatus('%s') called before SetupUI() - message will be lost!", status);
    }
    DisplayLockGuard lock(this);
    if (status_label_ == nullptr) {
        if (setup_ui_called_) {
            ESP_LOGW(TAG,
                     "SetStatus('%s') failed: status_label_ is nullptr (SetupUI() was called but "
                     "label not created)",
                     status);
        }
        return;
    }
    lv_label_set_text(status_label_, status);
    lv_obj_remove_flag(status_label_, LV_OBJ_FLAG_HIDDEN);
    lv_obj_add_flag(notification_label_, LV_OBJ_FLAG_HIDDEN);

    last_status_update_time_ = std::chrono::system_clock::now();
}

void LvglDisplay::ShowNotification(const std::string& notification, int duration_ms) {
    ShowNotification(notification.c_str(), duration_ms);
}

void LvglDisplay::ShowNotification(const char* notification, int duration_ms) {
    if (!setup_ui_called_) {
        ESP_LOGW(TAG, "ShowNotification('%s') called before SetupUI() - message will be lost!",
                 notification);
    }
    DisplayLockGuard lock(this);
    if (notification_label_ == nullptr) {
        if (setup_ui_called_) {
            ESP_LOGW(TAG,
                     "ShowNotification('%s') failed: notification_label_ is nullptr (SetupUI() was "
                     "called but label not created)",
                     notification);
        }
        return;
    }
    lv_label_set_text(notification_label_, notification);
    lv_obj_remove_flag(notification_label_, LV_OBJ_FLAG_HIDDEN);
    lv_obj_add_flag(status_label_, LV_OBJ_FLAG_HIDDEN);

    esp_timer_stop(notification_timer_);
    ESP_ERROR_CHECK(esp_timer_start_once(notification_timer_, duration_ms * 1000));
}

bool LvglDisplay::ShowWifiSetup(const WifiSetupView& view) {
#if defined(CONFIG_NABI_ESP_ASSISTANT) || defined(CONFIG_NABI_ESP_CLOUD_ASSISTANT)
    if (!setup_ui_called_ || display_ == nullptr) {
        return false;
    }

    DisplayLockGuard lock(this);
    if (!lock) {
        return false;
    }

    const lv_coord_t kScreenWidth = lv_display_get_horizontal_resolution(display_);
    const lv_coord_t kScreenHeight = lv_display_get_vertical_resolution(display_);
    constexpr lv_coord_t kInset = 12;
    constexpr uint32_t kBlue = 0x285CC5;
    constexpr uint32_t kBlueDark = 0x1C478F;
    constexpr uint32_t kGreen = 0x16845C;
    constexpr uint32_t kText = 0x14243A;
    constexpr uint32_t kMuted = 0x53657E;
    constexpr uint32_t kBackground = 0xF4F7FB;
    constexpr uint32_t kBlueSoft = 0xE7EEFC;
    constexpr uint32_t kGreenSoft = 0xE5F3EB;

    auto* screen = lv_screen_active();
    if (wifi_setup_screen_ == nullptr || lv_obj_get_parent(wifi_setup_screen_) != screen) {
        if (wifi_setup_screen_ != nullptr) {
            lv_obj_del(wifi_setup_screen_);
        }
        wifi_setup_screen_ = lv_obj_create(screen);
        lv_obj_set_size(wifi_setup_screen_, kScreenWidth, kScreenHeight);
        lv_obj_set_pos(wifi_setup_screen_, 0, 0);
        lv_obj_set_style_radius(wifi_setup_screen_, 0, 0);
        lv_obj_set_style_border_width(wifi_setup_screen_, 0, 0);
        lv_obj_set_style_pad_all(wifi_setup_screen_, 0, 0);
        lv_obj_set_style_bg_color(wifi_setup_screen_, lv_color_hex(kBackground), 0);
        lv_obj_set_style_bg_opa(wifi_setup_screen_, LV_OPA_COVER, 0);
        lv_obj_set_scrollbar_mode(wifi_setup_screen_, LV_SCROLLBAR_MODE_OFF);
        lv_obj_clear_flag(wifi_setup_screen_, LV_OBJ_FLAG_SCROLLABLE);

        auto* accent = lv_obj_create(wifi_setup_screen_);
        lv_obj_set_size(accent, kScreenWidth, 5);
        lv_obj_set_pos(accent, 0, 0);
        lv_obj_set_style_bg_color(accent, lv_color_hex(kBlue), 0);
        lv_obj_set_style_bg_opa(accent, LV_OPA_COVER, 0);
        lv_obj_set_style_border_width(accent, 0, 0);
        lv_obj_set_style_radius(accent, 0, 0);
        lv_obj_clear_flag(accent, LV_OBJ_FLAG_SCROLLABLE);

        wifi_setup_image_ = lv_image_create(wifi_setup_screen_);
        lv_obj_set_size(wifi_setup_image_, 62, 62);
        lv_obj_set_pos(wifi_setup_image_, kInset, 14);

        static lv_img_dsc_t nabi_image = {};
        nabi_image.header.magic = LV_IMAGE_HEADER_MAGIC;
        nabi_image.header.cf = LV_COLOR_FORMAT_RGB565;
        nabi_image.header.w = 128;
        nabi_image.header.h = 128;
        nabi_image.header.stride = 128 * 2;
        nabi_image.data = nabi_setup_rgb565_start;
        nabi_image.data_size = nabi_setup_rgb565_end - nabi_setup_rgb565_start;
        lv_image_set_src(wifi_setup_image_, &nabi_image);

        wifi_setup_title_label_ = lv_label_create(wifi_setup_screen_);
        lv_obj_set_pos(wifi_setup_title_label_, 84, 16);
        lv_obj_set_width(wifi_setup_title_label_, kScreenWidth - 96);
        lv_obj_set_style_text_color(wifi_setup_title_label_, lv_color_hex(kBlueDark), 0);
        lv_obj_set_style_text_letter_space(wifi_setup_title_label_, 1, 0);

        wifi_setup_body_label_ = lv_label_create(wifi_setup_screen_);
        lv_obj_set_pos(wifi_setup_body_label_, 84, 40);
        lv_obj_set_width(wifi_setup_body_label_, kScreenWidth - 96);
        lv_label_set_long_mode(wifi_setup_body_label_, LV_LABEL_LONG_WRAP);
        lv_obj_set_style_text_color(wifi_setup_body_label_, lv_color_hex(kMuted), 0);

        wifi_setup_code_card_ = lv_obj_create(wifi_setup_screen_);
        lv_obj_set_size(wifi_setup_code_card_, kScreenWidth - 2 * kInset, 57);
        lv_obj_set_pos(wifi_setup_code_card_, kInset, 78);
        lv_obj_set_style_bg_color(wifi_setup_code_card_, lv_color_hex(kBlueSoft), 0);
        lv_obj_set_style_bg_opa(wifi_setup_code_card_, LV_OPA_COVER, 0);
        lv_obj_set_style_border_width(wifi_setup_code_card_, 0, 0);
        lv_obj_set_style_radius(wifi_setup_code_card_, 12, 0);
        lv_obj_set_style_pad_all(wifi_setup_code_card_, 0, 0);
        lv_obj_clear_flag(wifi_setup_code_card_, LV_OBJ_FLAG_SCROLLABLE);

        wifi_setup_code_caption_ = lv_label_create(wifi_setup_screen_);
        lv_obj_set_pos(wifi_setup_code_caption_, kInset + 10, 87);
        lv_obj_set_width(wifi_setup_code_caption_, kScreenWidth - 2 * (kInset + 10));
        lv_obj_set_style_text_align(wifi_setup_code_caption_, LV_TEXT_ALIGN_CENTER, 0);
        lv_obj_set_style_text_color(wifi_setup_code_caption_, lv_color_hex(kBlueDark), 0);
        lv_obj_set_style_text_letter_space(wifi_setup_code_caption_, 1, 0);

        wifi_setup_code_label_ = lv_label_create(wifi_setup_screen_);
        lv_obj_set_pos(wifi_setup_code_label_, kInset + 8, 106);
        lv_obj_set_width(wifi_setup_code_label_, kScreenWidth - 2 * (kInset + 8));
        lv_obj_set_style_text_align(wifi_setup_code_label_, LV_TEXT_ALIGN_CENTER, 0);
        lv_obj_set_style_text_color(wifi_setup_code_label_, lv_color_hex(kBlueDark), 0);
        lv_obj_set_style_text_letter_space(wifi_setup_code_label_, 5, 0);

        wifi_setup_details_label_ = lv_label_create(wifi_setup_screen_);
        lv_obj_set_pos(wifi_setup_details_label_, kInset + 2, 153);
        lv_obj_set_width(wifi_setup_details_label_, kScreenWidth - 2 * (kInset + 2));
        lv_label_set_long_mode(wifi_setup_details_label_, LV_LABEL_LONG_WRAP);
        lv_obj_set_style_text_color(wifi_setup_details_label_, lv_color_hex(kText), 0);

        wifi_setup_touch_label_ = lv_label_create(wifi_setup_screen_);
        lv_obj_set_pos(wifi_setup_touch_label_, kInset, 218);
        lv_obj_set_width(wifi_setup_touch_label_, kScreenWidth - 2 * kInset);
        lv_obj_set_style_text_align(wifi_setup_touch_label_, LV_TEXT_ALIGN_CENTER, 0);
        lv_obj_set_style_text_color(wifi_setup_touch_label_, lv_color_hex(kMuted), 0);
    }

    const char* title = "Nabi đang khởi động";
    const char* body = "Mình sẽ giúp bạn kết nối mạng.";
    const char* code_caption = "MÃ GHÉP ĐÔI NABI";
    const char* details = "Kết nối Wi-Fi để hoàn tất thiết lập.";
    const char* touch_hint = "Chạm màn hình để kiểm tra mic và loa";
    uint32_t accent_color = kBlue;
    bool show_code = !view.pairing_code.empty() && (view.stage == WifiSetupStage::kPairing ||
                                                    view.stage == WifiSetupStage::kWaiting);

    switch (view.stage) {
        case WifiSetupStage::kPairing:
            title = "Chào bạn, mình là Nabi";
            body = "Mở ứng dụng Nabi và nhập mã ghép đôi này.";
            code_caption = "MÃ GHÉP ĐÔI · CÓ HIỆU LỰC 2 PHÚT";
            details = "Sau khi ghép đôi, hãy kết nối Wi-Fi để mình lên mạng.";
            break;
        case WifiSetupStage::kPairingExpired:
            title = "Mã ghép đôi đã hết hạn";
            body = "Khởi động lại Nabi để tạo mã ghép đôi mới.";
            code_caption = "GHÉP ĐÔI NABI";
            details = "Bạn vẫn có thể kết nối Wi-Fi bên dưới để hoàn tất thiết lập.";
            show_code = false;
            accent_color = kBlueDark;
            break;
        case WifiSetupStage::kWaiting:
            title = "Nabi sẵn sàng kết nối";
#ifdef CONFIG_NABI_ESP_CLOUD_ASSISTANT
            body = view.pairing_code.empty()
                       ? "Kết nối điện thoại vào Wi-Fi hiển thị bên dưới."
                       : "Nhập mã này khi kết nối Wi-Fi Nabi trên điện thoại.";
            code_caption = "MÃ WI-FI DÙNG MỘT LẦN";
            details = "Mở ứng dụng Nabi để gửi Wi-Fi nhà bạn.";
#else
            body = "Kết nối điện thoại vào điểm phát Wi-Fi hiển thị bên dưới.";
            code_caption = "MÃ GHÉP ĐÔI NABI";
            details = "Mở trang cấu hình mạng trên điện thoại.";
            if (show_code) {
                body = "Mở ứng dụng Nabi để ghép đôi và kết nối Wi-Fi bên dưới.";
            }
#endif
            break;
        case WifiSetupStage::kConnecting:
            title = "Đang kết nối Wi-Fi";
            body = "Nabi đang thử vào mạng bạn đã chọn.";
            code_caption = "MẠNG ĐANG KẾT NỐI";
            details = view.network_name.empty() ? "Vui lòng chờ trong giây lát."
                                                : view.network_name.c_str();
            show_code = false;
            accent_color = kBlueDark;
            break;
        case WifiSetupStage::kConnected:
            title = "Nabi đã kết nối!";
            body = "Kết nối mạng thành công.";
            code_caption = "WI-FI ĐÃ KẾT NỐI";
            details = view.network_name.empty() ? "Mình đã sẵn sàng đồng hành cùng bạn."
                                                : view.network_name.c_str();
            show_code = false;
            accent_color = kGreen;
            break;
        case WifiSetupStage::kFailed:
            title = "Chưa kết nối được Wi-Fi";
            body = "Kiểm tra lại mật khẩu hoặc chọn mạng khác.";
            code_caption = "THỬ LẠI TRÊN ĐIỆN THOẠI";
            details = "Kết nối lại vào Wi-Fi của Nabi để cấu hình mạng.";
            show_code = false;
            accent_color = kBlueDark;
            break;
    }

    std::string details_text = details;
    if (!view.access_point_name.empty()) {
        details_text = "1. Wi-Fi: " + view.access_point_name;
#ifdef CONFIG_NABI_ESP_CLOUD_ASSISTANT
        details_text += "\n2. Nhập mã trên màn hình\n3. Mở ứng dụng Nabi";
#else
        if (!view.portal_url.empty()) {
            details_text += "\n2. Mở: " + view.portal_url;
        }
#endif
    }

    lv_obj_set_style_bg_color(lv_obj_get_child(wifi_setup_screen_, 0), lv_color_hex(accent_color),
                              0);
    lv_label_set_text(wifi_setup_title_label_, title);
    lv_label_set_text(wifi_setup_body_label_, body);
    lv_label_set_text(wifi_setup_code_caption_, code_caption);
    lv_label_set_text(wifi_setup_code_label_, view.pairing_code.c_str());
    lv_label_set_text(wifi_setup_details_label_, details_text.c_str());
    lv_label_set_text(wifi_setup_touch_label_, touch_hint);
    if (show_code) {
        lv_obj_set_pos(wifi_setup_details_label_, kInset + 2, 153);
        lv_obj_remove_flag(wifi_setup_code_card_, LV_OBJ_FLAG_HIDDEN);
        lv_obj_remove_flag(wifi_setup_code_caption_, LV_OBJ_FLAG_HIDDEN);
        lv_obj_remove_flag(wifi_setup_code_label_, LV_OBJ_FLAG_HIDDEN);
    } else {
        lv_obj_set_pos(wifi_setup_details_label_, kInset + 2, 111);
        lv_obj_add_flag(wifi_setup_code_card_, LV_OBJ_FLAG_HIDDEN);
        lv_obj_add_flag(wifi_setup_code_caption_, LV_OBJ_FLAG_HIDDEN);
        lv_obj_add_flag(wifi_setup_code_label_, LV_OBJ_FLAG_HIDDEN);
    }
    lv_obj_set_style_bg_color(
        wifi_setup_code_card_,
        lv_color_hex(view.stage == WifiSetupStage::kConnected ? kGreenSoft : kBlueSoft), 0);
    lv_obj_set_style_text_color(wifi_setup_code_caption_, lv_color_hex(accent_color), 0);
    lv_obj_set_style_text_color(wifi_setup_code_label_, lv_color_hex(accent_color), 0);
    lv_obj_move_foreground(wifi_setup_screen_);
    return true;
#else
    (void)view;
    return false;
#endif
}

void LvglDisplay::ClearWifiSetup() {
#if defined(CONFIG_NABI_ESP_ASSISTANT) || defined(CONFIG_NABI_ESP_CLOUD_ASSISTANT)
    if (wifi_setup_screen_ == nullptr) {
        return;
    }
    DisplayLockGuard lock(this);
    if (!lock) {
        return;
    }
    lv_obj_del(wifi_setup_screen_);
    wifi_setup_screen_ = nullptr;
    wifi_setup_image_ = nullptr;
    wifi_setup_title_label_ = nullptr;
    wifi_setup_body_label_ = nullptr;
    wifi_setup_code_card_ = nullptr;
    wifi_setup_code_caption_ = nullptr;
    wifi_setup_code_label_ = nullptr;
    wifi_setup_details_label_ = nullptr;
    wifi_setup_touch_label_ = nullptr;
#endif
}

void LvglDisplay::UpdateStatusBar(bool update_all) {
    auto& app = Application::GetInstance();
    auto& board = Board::GetInstance();
    auto codec = board.GetAudioCodec();

    // Update mute icon
    {
        DisplayLockGuard lock(this);
        if (mute_label_ == nullptr) {
            return;
        }

        // Update icon if mute state changes
        if (codec->output_volume() == 0 && !muted_) {
            muted_ = true;
            lv_label_set_text(mute_label_, MATERIAL_SYMBOLS_VOLUME_OFF);
        } else if (codec->output_volume() > 0 && muted_) {
            muted_ = false;
            lv_label_set_text(mute_label_, "");
        }
    }

    // Update time — show HH:MM when idle; refresh immediately on state
    // transitions (update_all=true) and on every minute change thereafter.
    if (app.GetDeviceState() == kDeviceStateIdle) {
        time_t now = time(NULL);
        struct tm* tm_now = localtime(&now);
        if (tm_now->tm_year >= 2025 - 1900) {
            int cur_min = tm_now->tm_hour * 60 + tm_now->tm_min;
            if (update_all || cur_min != last_displayed_clock_min_) {
                last_displayed_clock_min_ = cur_min;
                char time_str[16];
                strftime(time_str, sizeof(time_str), "%H:%M", tm_now);
                SetStatus(time_str);
            }
        } else {
            ESP_LOGW(TAG, "System time not set (tm_year=%d)", tm_now->tm_year);
        }
    } else {
        // Reset so the clock re-appears immediately when idle resumes.
        last_displayed_clock_min_ = -1;
    }

    esp_pm_lock_acquire(pm_lock_);
    // Update battery icon
    int battery_level;
    bool charging, discharging;
    const char* icon = nullptr;
    if (board.GetBatteryLevel(battery_level, charging, discharging)) {
        if (charging) {
            icon = MATERIAL_SYMBOLS_BATTERY_ANDROID_FRAME_BOLT;
        } else {
            const char* levels[] = {
                MATERIAL_SYMBOLS_BATTERY_ANDROID_0,
                MATERIAL_SYMBOLS_BATTERY_ANDROID_FRAME_1,
                MATERIAL_SYMBOLS_BATTERY_ANDROID_FRAME_2,
                MATERIAL_SYMBOLS_BATTERY_ANDROID_FRAME_3,
                MATERIAL_SYMBOLS_BATTERY_ANDROID_FRAME_4,
                MATERIAL_SYMBOLS_BATTERY_ANDROID_FRAME_5,
                MATERIAL_SYMBOLS_BATTERY_ANDROID_FRAME_6,
                MATERIAL_SYMBOLS_BATTERY_ANDROID_FRAME_FULL,
            };
            int level_index = battery_level <= 0
                                  ? 0
                                  : (battery_level >= 100 ? 7 : 1 + ((battery_level - 1) * 6 / 99));
            icon = levels[level_index];
        }
        DisplayLockGuard lock(this);
        if (battery_label_ != nullptr && battery_icon_ != icon) {
            battery_icon_ = icon;
            lv_label_set_text(battery_label_, battery_icon_);
        }

        // Check low battery popup only when clock tick event is triggered
        // Because when initializing, the battery level is not ready yet.
        if (low_battery_popup_ != nullptr && !update_all) {
            if (strcmp(icon, MATERIAL_SYMBOLS_BATTERY_ANDROID_0) == 0 && discharging) {
                if (lv_obj_has_flag(low_battery_popup_,
                                    LV_OBJ_FLAG_HIDDEN)) {  // Show if low battery popup is hidden
                    lv_obj_remove_flag(low_battery_popup_, LV_OBJ_FLAG_HIDDEN);
                    app.Schedule([&app]() { app.PlaySound(Lang::Sounds::OGG_LOW_BATTERY); });
                }
            } else {
                // Hide the low battery popup when the battery is not empty
                if (!lv_obj_has_flag(low_battery_popup_,
                                     LV_OBJ_FLAG_HIDDEN)) {  // Hide if low battery popup is shown
                    lv_obj_add_flag(low_battery_popup_, LV_OBJ_FLAG_HIDDEN);
                }
            }
        }
    }

    // Update network icon every 10 seconds
    static int seconds_counter = 0;
    if (update_all || seconds_counter++ % 10 == 0) {
        // Don't read 4G network status during firmware upgrade to avoid occupying UART resources
        auto device_state = Application::GetInstance().GetDeviceState();
        static const std::vector<DeviceState> allowed_states = {
            kDeviceStateIdle,      kDeviceStateStarting,   kDeviceStateWifiConfiguring,
            kDeviceStateListening, kDeviceStateActivating,
        };
        if (std::find(allowed_states.begin(), allowed_states.end(), device_state) !=
            allowed_states.end()) {
            icon = board.GetNetworkStateIcon();
            if (network_label_ != nullptr && icon != nullptr && network_icon_ != icon) {
                DisplayLockGuard lock(this);
                network_icon_ = icon;
                lv_label_set_text(network_label_, network_icon_);
            }
        }
    }

    esp_pm_lock_release(pm_lock_);
}

void LvglDisplay::SetPreviewImage(std::unique_ptr<LvglImage> image) {}

void LvglDisplay::SetPowerSaveMode(bool on) {
    if (on) {
        SetChatMessage("system", "");
        SetEmotion("sleepy");
    } else {
        SetChatMessage("system", "");
        SetEmotion("neutral");
    }
}

bool LvglDisplay::SnapshotToJpeg(std::string& jpeg_data, int quality) {
#if CONFIG_LV_USE_SNAPSHOT
    DisplayLockGuard lock(this);

    lv_obj_t* screen = lv_screen_active();
    lv_draw_buf_t* draw_buffer = lv_snapshot_take(screen, LV_COLOR_FORMAT_RGB565);
    if (draw_buffer == nullptr) {
        ESP_LOGE(TAG, "Failed to take snapshot, draw_buffer is nullptr");
        return false;
    }

    // swap bytes
    uint16_t* data = (uint16_t*)draw_buffer->data;
    size_t pixel_count = draw_buffer->data_size / 2;
    for (size_t i = 0; i < pixel_count; i++) {
        data[i] = __builtin_bswap16(data[i]);
    }

    // Clear output string and use callback version to avoid pre-allocating large memory blocks
    jpeg_data.clear();

    // Use callback-based JPEG encoder to further save memory
    bool ret =
        image_to_jpeg_cb((uint8_t*)draw_buffer->data, draw_buffer->data_size, draw_buffer->header.w,
                         draw_buffer->header.h, V4L2_PIX_FMT_RGB565, quality,
                         [](void* arg, size_t index, const void* data, size_t len) -> size_t {
                             std::string* output = static_cast<std::string*>(arg);
                             if (data && len > 0) {
                                 output->append(static_cast<const char*>(data), len);
                             }
                             return len;
                         },
                         &jpeg_data);
    if (!ret) {
        ESP_LOGE(TAG, "Failed to convert image to JPEG");
    }

    lv_draw_buf_destroy(draw_buffer);
    return ret;
#else
    ESP_LOGE(TAG, "LV_USE_SNAPSHOT is not enabled");
    return false;
#endif
}
