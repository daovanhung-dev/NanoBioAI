#include "wifi_board.h"

#include "application.h"
#include "assets/lang_config.h"
#include "display.h"
#include "nabi_esp_provisioning.h"
#include "settings.h"
#include "system_info.h"

#include <esp_log.h>
#include <esp_mac.h>
#include <esp_network.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <utility>

#include <material_symbols.h>
#include <ssid_manager.h>
#include <wifi_manager.h>
#include <wifi_station.h>
#ifdef CONFIG_USE_ESP_BLUFI_WIFI_PROVISIONING
#include "blufi.h"
#endif

static const char* TAG = "WifiBoard";

// Connection timeout in seconds
static constexpr int CONNECT_TIMEOUT_SEC = 60;
#ifdef CONFIG_NABI_ESP_ASSISTANT
static constexpr int64_t NABI_PAIRING_CODE_TTL_US = 120LL * 1000 * 1000;
static constexpr int64_t NABI_CONNECTED_SCREEN_DURATION_US = 2500LL * 1000;
#endif

WifiBoard::WifiBoard() {
    // Create connection timeout timer
    esp_timer_create_args_t timer_args = {.callback = OnWifiConnectTimeout,
                                          .arg = this,
                                          .dispatch_method = ESP_TIMER_TASK,
                                          .name = "wifi_connect_timer",
                                          .skip_unhandled_events = true};
    esp_timer_create(&timer_args, &connect_timer_);
#ifdef CONFIG_NABI_ESP_ASSISTANT
    const esp_timer_create_args_t nabi_timer_args = {
        .callback = OnNabiSetupTimer,
        .arg = this,
        .dispatch_method = ESP_TIMER_TASK,
        .name = "nabi_setup_ui",
        .skip_unhandled_events = true,
    };
    ESP_ERROR_CHECK(esp_timer_create(&nabi_timer_args, &nabi_setup_timer_));
#endif
}

WifiBoard::~WifiBoard() {
    if (connect_timer_) {
        esp_timer_stop(connect_timer_);
        esp_timer_delete(connect_timer_);
    }
#ifdef CONFIG_NABI_ESP_ASSISTANT
    if (nabi_setup_timer_ != nullptr) {
        esp_timer_stop(nabi_setup_timer_);
        esp_timer_delete(nabi_setup_timer_);
    }
#endif
}

std::string WifiBoard::GetBoardType() { return "wifi"; }

void WifiBoard::StartNetwork() {
    auto& wifi_manager = WifiManager::GetInstance();

    // Initialize WiFi manager
    WifiManagerConfig config;
    config.ssid_prefix = "Nabi";
    config.language = Lang::CODE;
#ifdef CONFIG_NABI_ESP_ASSISTANT
    config.language = "vi-VN";
#endif
    config.show_ota_config = true;
    config.show_sleep_config = true;

    // Set a DHCP hostname so the router shows a friendly name instead of "espressif".
    // Uses the same "<prefix>-<last 2 MAC bytes>" scheme as the config AP SSID.
    uint8_t mac[6];
    if (esp_read_mac(mac, ESP_MAC_WIFI_STA) == ESP_OK) {
        char hostname[32];
        snprintf(hostname, sizeof(hostname), "%s-%02X%02X", config.ssid_prefix.c_str(), mac[4],
                 mac[5]);
        config.station_hostname = hostname;
    }
    wifi_manager.Initialize(config);
#ifdef CONFIG_NABI_ESP_ASSISTANT
    NabiEspProvisioning::GetInstance().Start();
    if (!NabiEspProvisioning::GetInstance().GetPairingCode().empty()) {
        UpdateNabiSetup(WifiSetupStage::kPairing);
        ESP_ERROR_CHECK(esp_timer_start_once(nabi_setup_timer_, NABI_PAIRING_CODE_TTL_US));
    }
#endif

    // Set unified event callback - forward to NetworkEvent with SSID data
    wifi_manager.SetEventCallback([this](WifiEvent event, const std::string& data) {
        switch (event) {
            case WifiEvent::Scanning:
                OnNetworkEvent(NetworkEvent::Scanning);
                break;
            case WifiEvent::Connecting:
                OnNetworkEvent(NetworkEvent::Connecting, data);
                break;
            case WifiEvent::Connected:
                OnNetworkEvent(NetworkEvent::Connected, data);
                break;
            case WifiEvent::Disconnected:
                OnNetworkEvent(NetworkEvent::Disconnected);
                break;
            case WifiEvent::ConfigModeEnter:
                OnNetworkEvent(NetworkEvent::WifiConfigModeEnter);
                break;
            case WifiEvent::ConfigModeExit:
                OnNetworkEvent(NetworkEvent::WifiConfigModeExit);
                break;
        }
    });

    // Try to connect or enter config mode
    TryWifiConnect();
}

void WifiBoard::TryWifiConnect() {
    auto& ssid_manager = SsidManager::GetInstance();
    bool have_ssid = !ssid_manager.GetSsidList().empty();

    if (have_ssid) {
        // Start connection attempt with timeout
        ESP_LOGI(TAG, "Starting WiFi connection attempt");
        esp_timer_start_once(connect_timer_, CONNECT_TIMEOUT_SEC * 1000000ULL);
        WifiManager::GetInstance().StartStation();
    } else {
        // No SSID configured, enter config mode
        // Wait for the board version to be shown
        vTaskDelay(pdMS_TO_TICKS(1500));
        StartWifiConfigMode();
    }
}

void WifiBoard::OnNetworkEvent(NetworkEvent event, const std::string& data) {
    switch (event) {
        case NetworkEvent::Connected:
            // Stop timeout timer
            esp_timer_stop(connect_timer_);
#ifdef CONFIG_USE_ESP_BLUFI_WIFI_PROVISIONING
            // make sure blufi resources has been released
            Blufi::GetInstance().deinit();
#endif
            in_config_mode_ = false;
            ESP_LOGI(TAG, "Connected to WiFi: %s", data.c_str());
#ifdef CONFIG_NABI_ESP_ASSISTANT
            UpdateNabiSetup(WifiSetupStage::kConnected, data);
            esp_timer_stop(nabi_setup_timer_);
            clear_nabi_setup_on_timeout_ = true;
            ESP_ERROR_CHECK(
                esp_timer_start_once(nabi_setup_timer_, NABI_CONNECTED_SCREEN_DURATION_US));
#endif
            break;
        case NetworkEvent::Scanning:
            ESP_LOGI(TAG, "WiFi scanning");
            break;
        case NetworkEvent::Connecting:
            ESP_LOGI(TAG, "WiFi connecting to %s", data.c_str());
#ifdef CONFIG_NABI_ESP_ASSISTANT
            UpdateNabiSetup(WifiSetupStage::kConnecting, data);
#endif
            break;
        case NetworkEvent::Disconnected:
            ESP_LOGW(TAG, "WiFi disconnected");
#ifdef CONFIG_NABI_ESP_ASSISTANT
            UpdateNabiSetup(in_config_mode_ ? WifiSetupStage::kWaiting : WifiSetupStage::kFailed,
                            "", in_config_mode_);
#endif
            break;
        case NetworkEvent::WifiConfigModeEnter:
            ESP_LOGI(TAG, "WiFi config mode entered");
            in_config_mode_ = true;
#ifdef CONFIG_NABI_ESP_ASSISTANT
            UpdateNabiSetup(WifiSetupStage::kWaiting, "", true);
#endif
            break;
        case NetworkEvent::WifiConfigModeExit:
            ESP_LOGI(TAG, "WiFi config mode exited");
            in_config_mode_ = false;
#ifdef CONFIG_NABI_ESP_ASSISTANT
            UpdateNabiSetup(WifiSetupStage::kConnecting);
#endif
            // Try to connect with the new credentials
            TryWifiConnect();
            break;
        default:
            break;
    }

    // Notify external callback if set
    if (network_event_callback_) {
        network_event_callback_(event, data);
    }
}

#ifdef CONFIG_NABI_ESP_ASSISTANT
void WifiBoard::UpdateNabiSetup(WifiSetupStage stage, const std::string& network_name,
                                bool include_access_point) {
    auto* display = GetDisplay();
    if (display == nullptr) {
        return;
    }

    WifiSetupView view;
    view.stage = stage;
    view.network_name = network_name;
    auto& provisioning = NabiEspProvisioning::GetInstance();
    if (!provisioning.IsPaired() &&
        (stage == WifiSetupStage::kPairing || stage == WifiSetupStage::kWaiting)) {
        view.pairing_code = provisioning.GetPairingCode();
        if (stage == WifiSetupStage::kPairing && view.pairing_code.empty()) {
            view.stage = WifiSetupStage::kPairingExpired;
        }
    }
    if (include_access_point) {
        auto& wifi_manager = WifiManager::GetInstance();
        view.access_point_name = wifi_manager.GetApSsid();
        view.portal_url = wifi_manager.GetApWebUrl();
    }

    if (display->ShowWifiSetup(view)) {
        nabi_setup_screen_active_ = true;
    }
}

void WifiBoard::OnNabiSetupTimer(void* arg) {
    auto* board = static_cast<WifiBoard*>(arg);
    if (board == nullptr || !board->nabi_setup_screen_active_) {
        return;
    }
    if (board->clear_nabi_setup_on_timeout_) {
        if (auto* display = board->GetDisplay()) {
            display->ClearWifiSetup();
        }
        board->nabi_setup_screen_active_ = false;
        board->clear_nabi_setup_on_timeout_ = false;
        return;
    }
    auto& provisioning = NabiEspProvisioning::GetInstance();
    if (provisioning.IsPaired()) {
        board->UpdateNabiSetup(WifiSetupStage::kWaiting, "", board->in_config_mode_);
    } else {
        board->UpdateNabiSetup(WifiSetupStage::kPairingExpired, "", board->in_config_mode_);
    }
}
#endif

void WifiBoard::SetNetworkEventCallback(NetworkEventCallback callback) {
    network_event_callback_ = std::move(callback);
}

void WifiBoard::OnWifiConnectTimeout(void* arg) {
    auto* board = static_cast<WifiBoard*>(arg);
    ESP_LOGW(TAG, "WiFi connection timeout, entering config mode");

    WifiManager::GetInstance().StopStation();
    board->StartWifiConfigMode();
}

void WifiBoard::StartWifiConfigMode() {
    in_config_mode_ = true;
    // Transition to wifi configuring state
    Application::GetInstance().SetDeviceState(kDeviceStateWifiConfiguring);
#ifdef CONFIG_USE_HOTSPOT_WIFI_PROVISIONING
    auto& wifi_manager = WifiManager::GetInstance();

    wifi_manager.StartConfigAp();

    // Show config prompt after a short delay
    Application::GetInstance().Schedule([&wifi_manager]() {
        std::string hint = Lang::Strings::CONNECT_TO_HOTSPOT;
        hint += wifi_manager.GetApSsid();
        hint += Lang::Strings::ACCESS_VIA_BROWSER;
        hint += wifi_manager.GetApWebUrl();

        Application::GetInstance().Alert(Lang::Strings::WIFI_CONFIG_MODE, hint.c_str(), "gear",
                                         Lang::Sounds::OGG_WIFICONFIG);
    });
#elif CONFIG_USE_ESP_BLUFI_WIFI_PROVISIONING
    auto& blufi = Blufi::GetInstance();
    // initialize esp-blufi protocol
    blufi.init();
#endif
}

void WifiBoard::EnterWifiConfigMode() {
    ESP_LOGI(TAG, "EnterWifiConfigMode called");
    GetDisplay()->ShowNotification(Lang::Strings::ENTERING_WIFI_CONFIG_MODE);

    auto& app = Application::GetInstance();
    auto state = app.GetDeviceState();

    if (state == kDeviceStateSpeaking || state == kDeviceStateNotifying ||
        state == kDeviceStateListening || state == kDeviceStateIdle) {
        // Reset protocol (close audio channel, reset protocol)
        Application::GetInstance().ResetProtocol();

        xTaskCreate(
            [](void* arg) {
                auto* board = static_cast<WifiBoard*>(arg);

                // Wait for 1 second to allow speaking to finish gracefully
                vTaskDelay(pdMS_TO_TICKS(1000));

                // Stop any ongoing connection attempt
                esp_timer_stop(board->connect_timer_);
                WifiManager::GetInstance().StopStation();

                // Enter config mode
                board->StartWifiConfigMode();

                vTaskDelete(NULL);
            },
            "wifi_cfg_delay", 4096, this, 2, NULL);
        return;
    }

    if (state != kDeviceStateStarting) {
        ESP_LOGE(TAG,
                 "EnterWifiConfigMode called but device state is not starting or speaking, device "
                 "state: %d",
                 state);
        return;
    }

    // Stop any ongoing connection attempt
    esp_timer_stop(connect_timer_);
    WifiManager::GetInstance().StopStation();

    StartWifiConfigMode();
}

bool WifiBoard::IsInWifiConfigMode() const { return WifiManager::GetInstance().IsConfigMode(); }

NetworkInterface* WifiBoard::GetNetwork() {
    static EspNetwork network;
    return &network;
}

const char* WifiBoard::GetNetworkStateIcon() {
    auto& wifi = WifiManager::GetInstance();

    if (wifi.IsConfigMode()) {
        return MATERIAL_SYMBOLS_WIFI;
    }
    if (!wifi.IsConnected()) {
        return MATERIAL_SYMBOLS_WIFI_OFF;
    }

    int rssi = wifi.GetRssi();
    if (rssi >= -65) {
        return MATERIAL_SYMBOLS_WIFI;
    } else if (rssi >= -75) {
        return MATERIAL_SYMBOLS_WIFI_2_BAR;
    }
    return MATERIAL_SYMBOLS_WIFI_1_BAR;
}

std::string WifiBoard::GetBoardJson() {
    auto& wifi = WifiManager::GetInstance();
    std::string json = R"({"type":")" + std::string(BOARD_TYPE) + R"(",)";
    json += R"("name":")" + std::string(BOARD_NAME) + R"(",)";
    json += R"("manufacturer":")" + std::string(BOARD_MANUFACTURER) + R"(",)";

    if (!wifi.IsConfigMode()) {
        json += R"("ssid":")" + wifi.GetSsid() + R"(",)";
        json += R"("rssi":)" + std::to_string(wifi.GetRssi()) + R"(,)";
        json += R"("channel":)" + std::to_string(wifi.GetChannel()) + R"(,)";
        json += R"("ip":")" + wifi.GetIpAddress() + R"(",)";
    }

    json += R"("mac":")" + SystemInfo::GetMacAddress() + R"("})";
    return json;
}

void WifiBoard::SetPowerSaveLevel(PowerSaveLevel level) {
    WifiPowerSaveLevel wifi_level;
    switch (level) {
        case PowerSaveLevel::LOW_POWER:
            wifi_level = WifiPowerSaveLevel::LOW_POWER;
            break;
        case PowerSaveLevel::BALANCED:
            wifi_level = WifiPowerSaveLevel::BALANCED;
            break;
        case PowerSaveLevel::PERFORMANCE:
        default:
            wifi_level = WifiPowerSaveLevel::PERFORMANCE;
            break;
    }
    WifiManager::GetInstance().SetPowerSaveLevel(wifi_level);
}

std::string WifiBoard::GetDeviceStatusJson() {
    auto& board = Board::GetInstance();
    auto root = cJSON_CreateObject();

    // Audio speaker
    auto audio_speaker = cJSON_CreateObject();
    if (auto codec = board.GetAudioCodec()) {
        cJSON_AddNumberToObject(audio_speaker, "volume", codec->output_volume());
    }
    cJSON_AddItemToObject(root, "audio_speaker", audio_speaker);

    // Screen
    auto screen = cJSON_CreateObject();
    if (auto backlight = board.GetBacklight()) {
        cJSON_AddNumberToObject(screen, "brightness", backlight->brightness());
    }
    if (auto display = board.GetDisplay(); display && display->height() > 64) {
        if (auto theme = display->GetTheme()) {
            cJSON_AddStringToObject(screen, "theme", theme->name().c_str());
        }
    }
    cJSON_AddItemToObject(root, "screen", screen);

    // Battery
    int level = 0;
    bool charging = false, discharging = false;
    if (board.GetBatteryLevel(level, charging, discharging)) {
        auto battery = cJSON_CreateObject();
        cJSON_AddNumberToObject(battery, "level", level);
        cJSON_AddBoolToObject(battery, "charging", charging);
        cJSON_AddItemToObject(root, "battery", battery);
    }

    // Network
    auto& wifi = WifiManager::GetInstance();
    auto network = cJSON_CreateObject();
    cJSON_AddStringToObject(network, "type", "wifi");
    cJSON_AddStringToObject(network, "ssid", wifi.GetSsid().c_str());
    int rssi = wifi.GetRssi();
    const char* signal = rssi >= -60 ? "strong" : (rssi >= -70 ? "medium" : "weak");
    cJSON_AddStringToObject(network, "signal", signal);
    cJSON_AddItemToObject(root, "network", network);

    // Chip temperature
    float temp = 0.0f;
    if (board.GetTemperature(temp)) {
        auto chip = cJSON_CreateObject();
        cJSON_AddNumberToObject(chip, "temperature", temp);
        cJSON_AddItemToObject(root, "chip", chip);
    }

    auto str = cJSON_PrintUnformatted(root);
    std::string result(str);
    cJSON_free(str);
    cJSON_Delete(root);
    return result;
}
