#include "nabi_esp_provisioning.h"

#include "application.h"
#include "nabi_esp_contract.h"
#include "settings.h"

#include <esp_log.h>
#include <esp_mac.h>
#include <esp_netif.h>
#include <esp_random.h>
#include <esp_srp.h>
#include <esp_timer.h>
#include <cJSON.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <protocomm_ble.h>
#include <protocomm_security.h>
#include <protocomm_security2.h>
#include <ssid_manager.h>
#include <wifi_manager.h>

#include <inttypes.h>
#include <array>
#include <cstdio>
#include <cstdlib>
#include <cstring>

static constexpr char TAG[] = "NabiProvision";
static constexpr int64_t PAIRING_CODE_TTL_US = 120LL * 1000 * 1000;
static constexpr uint8_t MAX_PAIRING_FAILURES = 5;
static constexpr uint16_t SEC2_SALT_LENGTH = 16;

namespace {
struct PendingWifiConfig {
    std::string ssid;
    std::string password;
};

char* CopyJsonString(cJSON* root, const char* name) {
    cJSON* value = cJSON_GetObjectItemCaseSensitive(root, name);
    if (!cJSON_IsString(value) || value->valuestring == nullptr) {
        return nullptr;
    }
    return value->valuestring;
}

std::string NewDeviceKey() {
    std::array<uint8_t, 32> bytes{};
    esp_fill_random(bytes.data(), bytes.size());
    static constexpr char hex[] = "0123456789abcdef";
    std::string result(bytes.size() * 2, '0');
    for (size_t i = 0; i < bytes.size(); ++i) {
        result[i * 2] = hex[bytes[i] >> 4];
        result[i * 2 + 1] = hex[bytes[i] & 0x0f];
    }
    return result;
}

bool IsValidWifiConfig(const char* ssid, const char* password) {
    const auto ssid_len = strnlen(ssid, 33);
    const auto password_len = strnlen(password, 65);
    return ssid_len > 0 && ssid_len <= 32 && password_len >= 8 && password_len <= 63;
}

}  // namespace

NabiEspProvisioning& NabiEspProvisioning::GetInstance() {
    static NabiEspProvisioning instance;
    return instance;
}

bool NabiEspProvisioning::IsPaired() const { return paired_; }

std::string NabiEspProvisioning::GetDeviceKey() const {
    if (!device_key_.empty()) {
        return device_key_;
    }
    Settings settings("nabi_esp", false);
    return settings.GetString("pair_key");
}

std::string NabiEspProvisioning::GetLocalOtaUrl() const {
#ifdef CONFIG_NABI_ESP_ASSISTANT
    auto* netif = esp_netif_get_handle_from_ifkey("WIFI_STA_DEF");
    if (netif == nullptr) {
        return {};
    }
    esp_netif_ip_info_t info = {};
    if (esp_netif_get_ip_info(netif, &info) != ESP_OK || info.gw.addr == 0) {
        return {};
    }
    char gateway[16] = {};
    if (esp_ip4addr_ntoa(&info.gw, gateway, sizeof(gateway)) == nullptr) {
        return {};
    }
    return std::string("http://") + gateway + ":" + std::to_string(NABI_AI_PORT) + NABI_OTA_PATH;
#else
    return {};
#endif
}

bool NabiEspProvisioning::ConfigureSecurity(const std::string& secret) {
#ifdef CONFIG_NABI_ESP_ASSISTANT
    if (sec2_salt_ != nullptr) {
        free(sec2_salt_);
        sec2_salt_ = nullptr;
    }
    if (sec2_verifier_ != nullptr) {
        free(sec2_verifier_);
        sec2_verifier_ = nullptr;
    }

    const auto username = std::string(NABI_BLE_SECURITY_USERNAME);
    esp_err_t err =
        esp_srp_gen_salt_verifier(username.c_str(), static_cast<int>(username.size()),
                                  secret.c_str(), static_cast<int>(secret.size()), &sec2_salt_,
                                  SEC2_SALT_LENGTH, &sec2_verifier_, &sec2_verifier_len_);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "Could not prepare secure provisioning session");
        return false;
    }
    sec2_salt_len_ = SEC2_SALT_LENGTH;
    protocomm_security2_params_t params = {
        .salt = sec2_salt_,
        .salt_len = sec2_salt_len_,
        .verifier = sec2_verifier_,
        .verifier_len = static_cast<uint16_t>(sec2_verifier_len_),
    };
    err = protocomm_set_security(protocomm_, "prov-session", &protocomm_security2, &params);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "Could not register secure provisioning endpoint: %s", esp_err_to_name(err));
        return false;
    }
    return true;
#else
    (void)secret;
    return false;
#endif
}

void NabiEspProvisioning::RefreshSecurityTask(void* context) {
#ifdef CONFIG_NABI_ESP_ASSISTANT
    auto* self = static_cast<NabiEspProvisioning*>(context);
    vTaskDelay(pdMS_TO_TICKS(2500));
    if (self != nullptr && self->protocomm_ != nullptr) {
        protocomm_unset_security(self->protocomm_, "prov-session");
        self->ConfigureSecurity(self->device_key_);
    }
#else
    (void)context;
#endif
    vTaskDelete(nullptr);
}

void NabiEspProvisioning::SecurityEventHandler(void* context, esp_event_base_t event_base,
                                                int32_t event_id, void*) {
#ifdef CONFIG_NABI_ESP_ASSISTANT
    auto* self = static_cast<NabiEspProvisioning*>(context);
    if (self == nullptr || event_base != PROTOCOMM_SECURITY_SESSION_EVENT ||
        self->paired_.load() || self->pairing_locked_.load()) {
        return;
    }
    if (event_id == PROTOCOMM_SECURITY_SESSION_SETUP_OK) {
        self->pairing_failed_attempts_.store(0);
        return;
    }
    if (event_id != PROTOCOMM_SECURITY_SESSION_CREDENTIALS_MISMATCH) {
        return;
    }

    const auto failures = static_cast<uint8_t>(self->pairing_failed_attempts_.fetch_add(1) + 1);
    if (failures >= MAX_PAIRING_FAILURES && !self->pairing_locked_.exchange(true)) {
        ESP_LOGW(TAG, "Initial pairing locked after repeated invalid codes; restart ESP to retry");
    }
#else
    (void)context;
    (void)event_base;
    (void)event_id;
#endif
}

void NabiEspProvisioning::Start() {
#ifdef CONFIG_NABI_ESP_ASSISTANT
    if (started_) {
        return;
    }

    Settings settings("nabi_esp", false);
    device_key_ = settings.GetString("pair_key");
    paired_ = device_key_.size() == 64;
    if (!paired_) {
        char code[9] = {};
        snprintf(code, sizeof(code), "%08" PRIu32, esp_random() % 100000000U);
        pairing_code_ = code;
        pairing_started_us_ = esp_timer_get_time();
    }

    protocomm_ = protocomm_new();
    if (protocomm_ == nullptr) {
        ESP_LOGE(TAG, "Could not create BLE provisioning service");
        return;
    }

    esp_err_t err = ESP_OK;
    if (!security_event_handler_registered_) {
        err = esp_event_handler_register(PROTOCOMM_SECURITY_SESSION_EVENT, ESP_EVENT_ANY_ID,
                                         SecurityEventHandler, this);
        security_event_handler_registered_ = err == ESP_OK;
    }
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "Could not register BLE pairing security handler: %s", esp_err_to_name(err));
        protocomm_delete(protocomm_);
        protocomm_ = nullptr;
        return;
    }

    static protocomm_ble_name_uuid_t endpoint_lookup[] = {
        {"proto-ver", 0xFF51},
        {"prov-session", 0xFF52},
        {NABI_BLE_CONFIG_ENDPOINT, 0xFF53},
    };
    static uint8_t service_uuid[BLE_UUID128_VAL_LENGTH] = NABI_BLE_SERVICE_UUID_BYTES;
    static protocomm_ble_config_t ble_config = {};
    snprintf(ble_config.device_name, sizeof(ble_config.device_name), "%sOSTB3ST",
             NABI_BLE_NAME_PREFIX);
    memcpy(ble_config.service_uuid, service_uuid, sizeof(service_uuid));
    ble_config.nu_lookup = endpoint_lookup;
    ble_config.nu_lookup_count = sizeof(endpoint_lookup) / sizeof(endpoint_lookup[0]);
    ble_config.ble_bonding = 0;
    ble_config.ble_sm_sc = 0;
    ble_config.ble_link_encryption = 0;
    ble_config.keep_ble_on = 1;
    ble_config.ble_notify = 1;

    const char version[] =
        "{\"prov\":{\"ver\":\"v1.1\",\"cap\":[\"custom\"],\"sec_ver\":2,\"sec_patch_ver\":1}}";
    err = protocomm_set_version(protocomm_, "proto-ver", version);
    if (err == ESP_OK) {
        err = protocomm_add_endpoint(protocomm_, NABI_BLE_CONFIG_ENDPOINT, HandleConfig, this);
    }
    const std::string secret = paired_ ? device_key_ : pairing_code_;
    if (err == ESP_OK && ConfigureSecurity(secret)) {
        err = protocomm_ble_start(protocomm_, &ble_config);
    } else if (err == ESP_OK) {
        err = ESP_FAIL;
    }
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "Could not start Nabi BLE provisioning: %s", esp_err_to_name(err));
        protocomm_delete(protocomm_);
        protocomm_ = nullptr;
        return;
    }

    started_ = true;
    ESP_LOGI(TAG, "Nabi BLE provisioning is ready");
    if (!paired_) {
        const auto code = pairing_code_;
        Application::GetInstance().Schedule([code]() {
            const auto message =
                std::string("Mã ghép đôi Nabi: ") + code + "\nNhập mã này trong ứng dụng Nabi.";
            Application::GetInstance().Alert("Ghép nối Nabi", message.c_str(), "bluetooth");
        });
    }
#endif
}

esp_err_t NabiEspProvisioning::HandleConfig(uint32_t, const uint8_t* input, ssize_t input_len,
                                            uint8_t** output, ssize_t* output_len,
                                            void* user_data) {
#ifdef CONFIG_NABI_ESP_ASSISTANT
    auto* self = static_cast<NabiEspProvisioning*>(user_data);
    if (self == nullptr || input == nullptr || input_len <= 0 || input_len > 1024 ||
        output == nullptr || output_len == nullptr) {
        return ESP_ERR_INVALID_ARG;
    }
    if (!self->paired_ && self->pairing_locked_.load()) {
        const char response[] = "{\"ok\":false,\"reason\":\"pairing_locked\"}";
        *output = static_cast<uint8_t*>(malloc(sizeof(response)));
        if (*output == nullptr) {
            return ESP_ERR_NO_MEM;
        }
        memcpy(*output, response, sizeof(response));
        *output_len = sizeof(response) - 1;
        return ESP_OK;
    }
    std::string request(reinterpret_cast<const char*>(input), static_cast<size_t>(input_len));
    cJSON* root = cJSON_Parse(request.c_str());
    if (root == nullptr) {
        return ESP_ERR_INVALID_ARG;
    }
    cJSON* contract_version = cJSON_GetObjectItemCaseSensitive(root, "contract_version");
    cJSON* protocol_version = cJSON_GetObjectItemCaseSensitive(root, "protocol_version");
    cJSON* port = cJSON_GetObjectItemCaseSensitive(root, "port");
    char* ota_path = CopyJsonString(root, "ota_path");
    char* websocket_path = CopyJsonString(root, "websocket_path");
    char* ssid = CopyJsonString(root, "ssid");
    char* password = CopyJsonString(root, "password");

    const bool valid_contract =
        cJSON_IsNumber(contract_version) && contract_version->valueint == NABI_CONTRACT_VERSION &&
        cJSON_IsNumber(protocol_version) && protocol_version->valueint == NABI_PROTOCOL_VERSION &&
        cJSON_IsNumber(port) && port->valueint == NABI_AI_PORT && ota_path != nullptr &&
        strcmp(ota_path, NABI_OTA_PATH) == 0 && websocket_path != nullptr &&
        strcmp(websocket_path, NABI_WEBSOCKET_PATH) == 0;
    if (!valid_contract || ssid == nullptr || password == nullptr ||
        !IsValidWifiConfig(ssid, password)) {
        cJSON_Delete(root);
        return ESP_ERR_INVALID_ARG;
    }
    if (!self->paired_ && esp_timer_get_time() - self->pairing_started_us_ > PAIRING_CODE_TTL_US) {
        cJSON_Delete(root);
        const char expired[] = "{\"ok\":false,\"reason\":\"pairing_expired\"}";
        *output = static_cast<uint8_t*>(malloc(sizeof(expired)));
        if (*output == nullptr)
            return ESP_ERR_NO_MEM;
        memcpy(*output, expired, sizeof(expired));
        *output_len = sizeof(expired) - 1;
        return ESP_OK;
    }

    std::string new_key;
    if (!self->paired_) {
        new_key = NewDeviceKey();
        Settings settings("nabi_esp", true);
        settings.SetString("pair_key", new_key);
        self->device_key_ = new_key;
        self->paired_ = true;
    }
    auto* pending = new PendingWifiConfig{ssid, password};
    if (xTaskCreate(StartWifiTask, "nabi_wifi", 4096, pending, 5, nullptr) != pdPASS) {
        delete pending;
        cJSON_Delete(root);
        return ESP_ERR_NO_MEM;
    }

    cJSON* response = cJSON_CreateObject();
    cJSON_AddBoolToObject(response, "ok", true);
    cJSON_AddBoolToObject(response, "paired", self->paired_);
    if (!new_key.empty()) {
        cJSON_AddStringToObject(response, "pairing_key", new_key.c_str());
        xTaskCreate(RefreshSecurityTask, "nabi_sec_refresh", 4096, self, 5, nullptr);
    }
    char* encoded = cJSON_PrintUnformatted(response);
    cJSON_Delete(response);
    cJSON_Delete(root);
    if (encoded == nullptr) {
        return ESP_ERR_NO_MEM;
    }
    *output = reinterpret_cast<uint8_t*>(encoded);
    *output_len = strlen(encoded);
    return ESP_OK;
#else
    (void)input;
    (void)input_len;
    (void)output;
    (void)output_len;
    (void)user_data;
    return ESP_ERR_NOT_SUPPORTED;
#endif
}

void NabiEspProvisioning::StartWifiTask(void* context) {
#ifdef CONFIG_NABI_ESP_ASSISTANT
    auto* config = static_cast<PendingWifiConfig*>(context);
    vTaskDelay(pdMS_TO_TICKS(1500));
    auto& manager = WifiManager::GetInstance();
    manager.StopStation();
    auto& ssids = SsidManager::GetInstance();
    ssids.Clear();
    ssids.AddSsid(config->ssid, config->password);
    manager.StartStation();
    delete config;
#else
    (void)context;
#endif
    vTaskDelete(nullptr);
}
