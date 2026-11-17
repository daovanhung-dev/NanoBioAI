#include "nabi_esp_provisioning.h"

#include "application.h"
#include "board.h"
#include "nabi_esp_cloud_contract.h"
#include "nabi_esp_contract.h"
#include "settings.h"

#include <esp_log.h>
#include <esp_mac.h>
#include <esp_netif.h>
#include <esp_netif_sntp.h>
#include <esp_random.h>
#include <esp_srp.h>
#include <esp_timer.h>
#include <cJSON.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <http.h>
#include <network_interface.h>
#include <protocomm_ble.h>
#include <protocomm_security.h>
#include <protocomm_security2.h>
#include <ssid_manager.h>
#include <wifi_manager.h>

#include <inttypes.h>
#include <algorithm>
#include <array>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <ctime>
#include <new>

static constexpr char TAG[] = "NabiProvision";
static constexpr int64_t PAIRING_CODE_TTL_US = 120LL * 1000 * 1000;
static constexpr uint8_t MAX_PAIRING_FAILURES = 5;
static constexpr uint16_t SEC2_SALT_LENGTH = 16;

namespace {
struct PendingWifiConfig {
    std::string ssid;
    std::string password;
};

bool PairingTokenIsValid(const char* token) {
    const auto length = token == nullptr ? 0 : strnlen(token, 161);
    if (length < 32 || length > 160) {
        return false;
    }
    return std::all_of(token, token + length, [](unsigned char value) {
        return (value >= 'a' && value <= 'z') || (value >= 'A' && value <= 'Z') ||
               (value >= '0' && value <= '9') || value == '_' || value == '-';
    });
}

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

std::string NewDeviceId() {
    std::array<uint8_t, 16> bytes{};
    esp_fill_random(bytes.data(), bytes.size());
    static constexpr char hex[] = "0123456789abcdef";
    std::string result(bytes.size() * 2, '0');
    for (size_t i = 0; i < bytes.size(); ++i) {
        result[i * 2] = hex[bytes[i] >> 4];
        result[i * 2 + 1] = hex[bytes[i] & 0x0f];
    }
    return result;
}

bool IsTokenValue(const char* value, size_t minimum, size_t maximum) {
    if (value == nullptr) {
        return false;
    }
    const auto length = strnlen(value, maximum + 1);
    if (length < minimum || length > maximum) {
        return false;
    }
    return std::all_of(value, value + length, [](unsigned char byte) {
        return (byte >= 'a' && byte <= 'z') || (byte >= 'A' && byte <= 'Z') ||
               (byte >= '0' && byte <= '9') || byte == '_' || byte == '-' || byte == '.';
    });
}

bool IsDeviceIdValue(const std::string& value) {
    return value.size() == 32 &&
           std::all_of(value.begin(), value.end(), [](unsigned char byte) {
               return (byte >= 'a' && byte <= 'f') || (byte >= '0' && byte <= '9');
           });
}

bool IsValidWifiConfig(const char* ssid, const char* password) {
    const auto ssid_len = strnlen(ssid, 33);
    const auto password_len = strnlen(password, 65);
    return ssid_len > 0 && ssid_len <= 32 && password_len >= 8 && password_len <= 63;
}

bool IsValidAccountCredential(const char* type, const char* identifier, const char* password) {
    if (type == nullptr || identifier == nullptr || password == nullptr) {
        return false;
    }
    const auto identifier_len = strnlen(identifier, 321);
    const auto password_len = strnlen(password, 129);
    const bool valid_type = strcmp(type, "phone") == 0 || strcmp(type, "email") == 0 ||
                            strcmp(type, "username") == 0;
    return valid_type && identifier_len >= 3 && identifier_len <= 320 && password_len >= 1 &&
           password_len <= 128;
}

}  // namespace

NabiEspProvisioning& NabiEspProvisioning::GetInstance() {
    static NabiEspProvisioning instance;
    return instance;
}

bool NabiEspProvisioning::IsPaired() const { return paired_; }

std::string NabiEspProvisioning::GetPairingCode() const {
    if (paired_ || pairing_locked_ || pairing_code_.empty() || pairing_started_us_ == 0 ||
        esp_timer_get_time() - pairing_started_us_ >= PAIRING_CODE_TTL_US) {
        return {};
    }
    return pairing_code_;
}

std::string NabiEspProvisioning::BeginConfigSession() {
#ifdef CONFIG_NABI_ESP_CLOUD_ASSISTANT
    char code[9] = {};
    snprintf(code, sizeof(code), "%08" PRIu32, esp_random() % 100000000U);
    std::lock_guard<std::mutex> lock(config_session_mutex_);
    config_access_code_ = code;
    config_session_consumed_.store(false);
    return config_access_code_;
#else
    return {};
#endif
}

std::string NabiEspProvisioning::GetConfigAccessCode() const {
    std::lock_guard<std::mutex> lock(config_session_mutex_);
    return config_access_code_;
}

void NabiEspProvisioning::RegisterLocalApiHandlers(httpd_handle_t server) {
#ifdef CONFIG_NABI_ESP_CLOUD_ASSISTANT
    if (server == nullptr) {
        return;
    }
    httpd_uri_t status = {
        .uri = NABI_CLOUD_AP_STATUS_PATH,
        .method = HTTP_GET,
        .handler = HandleLocalStatus,
        .user_ctx = this,
    };
    httpd_uri_t provision = {
        .uri = NABI_CLOUD_AP_PROVISION_PATH,
        .method = HTTP_POST,
        .handler = HandleLocalProvision,
        .user_ctx = this,
    };
    const auto status_result = httpd_register_uri_handler(server, &status);
    const auto provision_result = httpd_register_uri_handler(server, &provision);
    if (status_result != ESP_OK || provision_result != ESP_OK) {
        ESP_LOGE(TAG, "Could not register Nabi local provisioning routes");
    }
#else
    (void)server;
#endif
}

std::string NabiEspProvisioning::GetDeviceKey() const {
    if (!device_key_.empty()) {
        return device_key_;
    }
    Settings settings("nabi_esp", false);
    return settings.GetString("pair_key");
}

std::string NabiEspProvisioning::GetLocalOtaUrl() const {
#if defined(CONFIG_NABI_ESP_ASSISTANT) && !defined(CONFIG_NABI_ESP_CLOUD_ASSISTANT)
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

bool NabiEspProvisioning::HasCloudCredentials() const {
#ifdef CONFIG_NABI_ESP_CLOUD_ASSISTANT
    return !cloud_access_token_.empty() && cloud_websocket_url_ == NABI_CLOUD_WS_URL;
#else
    return false;
#endif
}

std::string NabiEspProvisioning::GetCloudDeviceId() const {
#ifdef CONFIG_NABI_ESP_CLOUD_ASSISTANT
    if (!cloud_device_id_.empty()) {
        return cloud_device_id_;
    }
    Settings settings("nabi_cloud", false);
    return settings.GetString("device_id");
#else
    return {};
#endif
}

std::string NabiEspProvisioning::GetCloudAccessToken() const {
#ifdef CONFIG_NABI_ESP_CLOUD_ASSISTANT
    return cloud_access_token_;
#else
    return {};
#endif
}

std::string NabiEspProvisioning::GetCloudWebsocketUrl() const {
#ifdef CONFIG_NABI_ESP_CLOUD_ASSISTANT
    return cloud_websocket_url_;
#else
    return {};
#endif
}

bool NabiEspProvisioning::AuthenticateCloud() {
#ifdef CONFIG_NABI_ESP_CLOUD_ASSISTANT
    static bool sntp_initialized = false;
    if (!sntp_initialized) {
        const esp_sntp_config_t config = ESP_NETIF_SNTP_DEFAULT_CONFIG("pool.ntp.org");
        const auto init_result = esp_netif_sntp_init(&config);
        if (init_result != ESP_OK && init_result != ESP_ERR_INVALID_STATE) {
            ESP_LOGW(TAG, "Could not initialize network time sync: %s",
                     esp_err_to_name(init_result));
            return false;
        }
        sntp_initialized = true;
    }
    if (std::time(nullptr) < 1'700'000'000) {
        const auto sync_result = esp_netif_sntp_sync_wait(pdMS_TO_TICKS(15000));
        if (sync_result != ESP_OK || std::time(nullptr) < 1'700'000'000) {
            ESP_LOGW(TAG, "Network time is not synchronized; refusing cloud TLS setup");
            return false;
        }
    }

    Settings settings("nabi_cloud", false);
    const auto device_id = settings.GetString("device_id");
    const auto pairing_token = settings.GetString("pairing_token");
    const auto refresh_token = settings.GetString("refresh_token");
    const auto identifier_type = settings.GetString("identifier_type");
    const auto identifier = settings.GetString("identifier");
    const auto account_password = settings.GetString("account_password");
    const auto provision_pending = settings.GetString("provision_pending") == "1";
    if (device_id.size() != 32 ||
        !std::all_of(device_id.begin(), device_id.end(),
                     [](unsigned char value) {
                         return (value >= 'a' && value <= 'f') || (value >= '0' && value <= '9');
                     }) ||
        (pairing_token.empty() && refresh_token.empty() &&
         (!provision_pending ||
          !IsValidAccountCredential(identifier_type.c_str(), identifier.c_str(),
                                    account_password.c_str())))) {
        ESP_LOGW(TAG, "Cloud device credentials are missing");
        return false;
    }

    cJSON* body = cJSON_CreateObject();
    if (body == nullptr) {
        return false;
    }
    cJSON_AddStringToObject(body, "device_id", device_id.c_str());
    std::string url;
    if (!pairing_token.empty()) {
        cJSON_AddStringToObject(body, "pairing_token", pairing_token.c_str());
        url = std::string(NABI_CLOUD_API_BASE_URL) + NABI_CLOUD_CLAIM_PATH;
    } else if (!refresh_token.empty()) {
        cJSON_AddStringToObject(body, "refresh_token", refresh_token.c_str());
        url = std::string(NABI_CLOUD_API_BASE_URL) + NABI_CLOUD_REFRESH_PATH;
    } else {
        cJSON_AddStringToObject(body, "identifier_type", identifier_type.c_str());
        cJSON_AddStringToObject(body, "identifier", identifier.c_str());
        cJSON_AddStringToObject(body, "password", account_password.c_str());
        url = std::string(NABI_CLOUD_API_BASE_URL) + NABI_CLOUD_DEVICE_LOGIN_PATH;
    }
    char* encoded = cJSON_PrintUnformatted(body);
    cJSON_Delete(body);
    if (encoded == nullptr) {
        return false;
    }

    auto http = Board::GetInstance().GetNetwork()->CreateHttp(0);
    if (http == nullptr) {
        cJSON_free(encoded);
        return false;
    }
    http->SetTimeout(30000);
    http->SetHeader("Accept", "application/json");
    http->SetHeader("Content-Type", "application/json");
    http->SetContent(std::string(encoded));
    cJSON_free(encoded);
    if (auto opened = http->Open("POST", url); !opened) {
        ESP_LOGW(TAG, "Cloud credential request could not connect: %s",
                 opened.error().ToString().c_str());
        http->Close();
        return false;
    }
    auto status_code = http->GetStatusCode();
    if (!status_code || *status_code < 200 || *status_code >= 300) {
        ESP_LOGW(TAG, "Cloud credential request failed with HTTP %d",
                 status_code ? *status_code : 0);
        http->Close();
        return false;
    }
    std::string response = http->ReadAll();
    http->Close();
    if (response.empty() || response.size() > 4096) {
        ESP_LOGW(TAG, "Cloud credential response was empty or exceeded its limit");
        return false;
    }
    cJSON* root = cJSON_ParseWithLength(response.data(), response.size());
    if (root == nullptr) {
        ESP_LOGW(TAG, "Cloud credential response was not valid JSON");
        return false;
    }
    cJSON* success = cJSON_GetObjectItemCaseSensitive(root, "success");
    cJSON* data = cJSON_GetObjectItemCaseSensitive(root, "data");
    cJSON* access = cJSON_GetObjectItemCaseSensitive(data, "access_token");
    cJSON* refresh = cJSON_GetObjectItemCaseSensitive(data, "refresh_token");
    cJSON* websocket = cJSON_GetObjectItemCaseSensitive(data, "websocket_url");
    cJSON* protocol = cJSON_GetObjectItemCaseSensitive(data, "protocol_version");
    if (!cJSON_IsTrue(success) || !cJSON_IsObject(data) || !cJSON_IsString(access) ||
        !cJSON_IsString(refresh) || !cJSON_IsString(websocket) || !cJSON_IsNumber(protocol) ||
        protocol->valueint != NABI_CLOUD_PROTOCOL_VERSION ||
        !IsTokenValue(access->valuestring, 32, 160) ||
        !IsTokenValue(refresh->valuestring, 32, 160) ||
        strcmp(websocket->valuestring, NABI_CLOUD_WS_URL) != 0) {
        cJSON_Delete(root);
        ESP_LOGW(TAG, "Cloud credential response did not match the Nabi contract");
        return false;
    }
    cloud_access_token_ = access->valuestring;
    cloud_websocket_url_ = websocket->valuestring;
    cloud_device_id_ = device_id;
    const std::string next_refresh = refresh->valuestring;
    cJSON_Delete(root);

    Settings writable_settings("nabi_cloud", true);
    writable_settings.SetString("refresh_token", next_refresh);
    writable_settings.SetString("provision_pending", "0");
    if (!pairing_token.empty()) {
        writable_settings.EraseKey("pairing_token");
    }
    ESP_LOGI(TAG, "Nabi cloud device credentials are ready (%s)", device_id.c_str());
    return true;
#else
    return false;
#endif
}

bool NabiEspProvisioning::ConfigureSecurity(const std::string& secret) {
#if defined(CONFIG_NABI_ESP_ASSISTANT) || defined(CONFIG_NABI_ESP_CLOUD_ASSISTANT)
    if (sec2_salt_ != nullptr) {
        free(sec2_salt_);
        sec2_salt_ = nullptr;
    }
    if (sec2_verifier_ != nullptr) {
        free(sec2_verifier_);
        sec2_verifier_ = nullptr;
    }

#ifdef CONFIG_NABI_ESP_CLOUD_ASSISTANT
    const auto username = std::string(NABI_CLOUD_BLE_SECURITY_USERNAME);
#else
    const auto username = std::string(NABI_BLE_SECURITY_USERNAME);
#endif
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
#if defined(CONFIG_NABI_ESP_ASSISTANT) || defined(CONFIG_NABI_ESP_CLOUD_ASSISTANT)
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
#if defined(CONFIG_NABI_ESP_ASSISTANT) || defined(CONFIG_NABI_ESP_CLOUD_ASSISTANT)
    auto* self = static_cast<NabiEspProvisioning*>(context);
    if (self == nullptr || event_base != PROTOCOMM_SECURITY_SESSION_EVENT || self->paired_.load() ||
        self->pairing_locked_.load()) {
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
#ifdef CONFIG_NABI_ESP_CLOUD_ASSISTANT
    if (started_) {
        return;
    }
    Settings settings("nabi_cloud", true);
    auto device_id = settings.GetString("device_id");
    if (!IsDeviceIdValue(device_id)) {
        device_id = NewDeviceId();
        settings.SetString("device_id", device_id);
    }
    const auto identifier_type = settings.GetString("identifier_type");
    const auto identifier = settings.GetString("identifier");
    const auto account_password = settings.GetString("account_password");
    paired_ = !settings.GetString("pairing_token").empty() ||
              !settings.GetString("refresh_token").empty() ||
              IsValidAccountCredential(identifier_type.c_str(), identifier.c_str(),
                                        account_password.c_str());
    started_ = true;
    ESP_LOGI(TAG, "Nabi cloud setup is ready for local Wi-Fi provisioning");
#elif defined(CONFIG_NABI_ESP_ASSISTANT)
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

#ifdef CONFIG_NABI_ESP_CLOUD_ASSISTANT
    static protocomm_ble_name_uuid_t endpoint_lookup[] = {
        {"proto-ver", 0xFF51},
        {"prov-session", 0xFF52},
        {NABI_CLOUD_BLE_CONFIG_ENDPOINT, 0xFF53},
    };
    static uint8_t service_uuid[BLE_UUID128_VAL_LENGTH] = NABI_CLOUD_BLE_SERVICE_UUID_BYTES;
#else
    static protocomm_ble_name_uuid_t endpoint_lookup[] = {
        {"proto-ver", 0xFF51},
        {"prov-session", 0xFF52},
        {NABI_BLE_CONFIG_ENDPOINT, 0xFF53},
    };
    static uint8_t service_uuid[BLE_UUID128_VAL_LENGTH] = NABI_BLE_SERVICE_UUID_BYTES;
#endif
    static protocomm_ble_config_t ble_config = {};
#ifdef CONFIG_NABI_ESP_CLOUD_ASSISTANT
    snprintf(ble_config.device_name, sizeof(ble_config.device_name), "%sOSTB3ST",
             NABI_CLOUD_BLE_NAME_PREFIX);
#else
    snprintf(ble_config.device_name, sizeof(ble_config.device_name), "%sOSTB3ST",
             NABI_BLE_NAME_PREFIX);
#endif
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

esp_err_t NabiEspProvisioning::HandleLocalStatus(httpd_req_t* request) {
#ifdef CONFIG_NABI_ESP_CLOUD_ASSISTANT
    auto* self = static_cast<NabiEspProvisioning*>(request->user_ctx);
    if (self == nullptr) {
        return httpd_resp_send_err(request, HTTPD_500_INTERNAL_SERVER_ERROR, "Nabi setup unavailable");
    }
    Settings settings("nabi_cloud", false);
    const auto device_id = settings.GetString("device_id");
    if (!IsDeviceIdValue(device_id)) {
        httpd_resp_set_status(request, "503 Service Unavailable");
        return httpd_resp_send(request, "Nabi setup unavailable", HTTPD_RESP_USE_STRLEN);
    }
    cJSON* root = cJSON_CreateObject();
    cJSON* data = cJSON_CreateObject();
    if (root == nullptr || data == nullptr) {
        cJSON_Delete(root);
        cJSON_Delete(data);
        return httpd_resp_send_err(request, HTTPD_500_INTERNAL_SERVER_ERROR, "Nabi setup unavailable");
    }
    cJSON_AddBoolToObject(root, "success", true);
    cJSON_AddNumberToObject(data, "contract_version", NABI_CLOUD_CONTRACT_VERSION);
    cJSON_AddNumberToObject(data, "protocol_version", NABI_CLOUD_PROTOCOL_VERSION);
    cJSON_AddStringToObject(data, "device_id", device_id.c_str());
    cJSON_AddBoolToObject(data, "claimed", !settings.GetString("refresh_token").empty());
    cJSON_AddItemToObject(root, "data", data);
    char* encoded = cJSON_PrintUnformatted(root);
    cJSON_Delete(root);
    if (encoded == nullptr) {
        return httpd_resp_send_err(request, HTTPD_500_INTERNAL_SERVER_ERROR, "Nabi setup unavailable");
    }
    httpd_resp_set_type(request, "application/json");
    httpd_resp_set_hdr(request, "Connection", "close");
    const auto result = httpd_resp_send(request, encoded, HTTPD_RESP_USE_STRLEN);
    cJSON_free(encoded);
    return result;
#else
    return httpd_resp_send_err(request, HTTPD_404_NOT_FOUND, "Not found");
#endif
}

esp_err_t NabiEspProvisioning::HandleLocalProvision(httpd_req_t* request) {
#ifdef CONFIG_NABI_ESP_CLOUD_ASSISTANT
    auto* self = static_cast<NabiEspProvisioning*>(request->user_ctx);
    if (self == nullptr || request->content_len == 0 || request->content_len > 4096) {
        return httpd_resp_send_err(request, HTTPD_400_BAD_REQUEST, "Invalid setup request");
    }
    std::string body(request->content_len, '\0');
    size_t received_total = 0;
    while (received_total < request->content_len) {
        const int received = httpd_req_recv(request, body.data() + received_total,
                                            request->content_len - received_total);
        if (received <= 0) {
            return httpd_resp_send_err(request, HTTPD_400_BAD_REQUEST, "Invalid setup request");
        }
        received_total += static_cast<size_t>(received);
    }
    cJSON* root = cJSON_ParseWithLength(body.data(), body.size());
    if (root == nullptr) {
        return httpd_resp_send_err(request, HTTPD_400_BAD_REQUEST, "Invalid setup request");
    }
    cJSON* contract = cJSON_GetObjectItemCaseSensitive(root, "contract_version");
    cJSON* protocol = cJSON_GetObjectItemCaseSensitive(root, "protocol_version");
    char* ssid = CopyJsonString(root, "ssid");
    char* wifi_password = CopyJsonString(root, "wifi_password");
    char* identifier_type = CopyJsonString(root, "identifier_type");
    char* identifier = CopyJsonString(root, "identifier");
    char* account_password = CopyJsonString(root, "account_password");
    if (!cJSON_IsNumber(contract) || contract->valueint != NABI_CLOUD_CONTRACT_VERSION ||
        !cJSON_IsNumber(protocol) || protocol->valueint != NABI_CLOUD_PROTOCOL_VERSION ||
        ssid == nullptr || wifi_password == nullptr || !IsValidWifiConfig(ssid, wifi_password) ||
        !IsValidAccountCredential(identifier_type, identifier, account_password)) {
        cJSON_Delete(root);
        return httpd_resp_send_err(request, HTTPD_400_BAD_REQUEST, "Invalid setup request");
    }

    Settings cloud_settings("nabi_cloud", false);
    auto device_id = cloud_settings.GetString("device_id");
    if (!IsDeviceIdValue(device_id)) {
        cJSON_Delete(root);
        httpd_resp_set_status(request, "503 Service Unavailable");
        return httpd_resp_send(request, "Nabi setup unavailable", HTTPD_RESP_USE_STRLEN);
    }
    bool expected_unused = false;
    if (!self->config_session_consumed_.compare_exchange_strong(expected_unused, true)) {
        cJSON_Delete(root);
        httpd_resp_set_status(request, "409 Conflict");
        return httpd_resp_send(request, "Setup code already used", HTTPD_RESP_USE_STRLEN);
    }

    const std::string ssid_value(ssid);
    const std::string wifi_password_value(wifi_password);
    const std::string identifier_type_value(identifier_type);
    const std::string identifier_value(identifier);
    const std::string account_password_value(account_password);
    cJSON_Delete(root);

    cJSON* response = cJSON_CreateObject();
    cJSON* data = cJSON_CreateObject();
    if (response == nullptr || data == nullptr) {
        cJSON_Delete(response);
        cJSON_Delete(data);
        return httpd_resp_send_err(request, HTTPD_500_INTERNAL_SERVER_ERROR, "Could not save Nabi setup");
    }
    cJSON_AddBoolToObject(response, "success", true);
    cJSON_AddStringToObject(data, "status", "accepted");
    cJSON_AddStringToObject(data, "device_id", device_id.c_str());
    cJSON_AddItemToObject(response, "data", data);
    char* encoded = cJSON_PrintUnformatted(response);
    cJSON_Delete(response);
    if (encoded == nullptr) {
        self->config_session_consumed_.store(false);
        return httpd_resp_send_err(request, HTTPD_500_INTERNAL_SERVER_ERROR, "Could not save Nabi setup");
    }

    Settings writable_cloud_settings("nabi_cloud", true);
    const auto previous_identifier_type = writable_cloud_settings.GetString("identifier_type");
    const auto previous_identifier = writable_cloud_settings.GetString("identifier");
    const auto previous_account_password = writable_cloud_settings.GetString("account_password");
    const auto previous_refresh_token = writable_cloud_settings.GetString("refresh_token");
    const auto previous_setup_pending = writable_cloud_settings.GetString("provision_pending");
    const bool was_paired = self->paired_.load();
    writable_cloud_settings.SetString("identifier_type", identifier_type_value);
    writable_cloud_settings.SetString("identifier", identifier_value);
    writable_cloud_settings.SetString("account_password", account_password_value);
    writable_cloud_settings.SetString("provision_pending", "1");
    writable_cloud_settings.EraseKey("pairing_token");
    writable_cloud_settings.EraseKey("refresh_token");
    self->paired_ = true;

    auto* pending = new (std::nothrow) PendingWifiConfig{ssid_value, wifi_password_value};
    if (pending == nullptr ||
        xTaskCreate(StartWifiTask, "nabi_wifi", 4096, pending, 5, nullptr) != pdPASS) {
        delete pending;
        auto restore_string = [&writable_cloud_settings](const char* key,
                                                         const std::string& value) {
            if (value.empty()) {
                writable_cloud_settings.EraseKey(key);
            } else {
                writable_cloud_settings.SetString(key, value);
            }
        };
        restore_string("identifier_type", previous_identifier_type);
        restore_string("identifier", previous_identifier);
        restore_string("account_password", previous_account_password);
        restore_string("refresh_token", previous_refresh_token);
        restore_string("provision_pending", previous_setup_pending);
        self->paired_ = was_paired;
        self->config_session_consumed_.store(false);
        cJSON_free(encoded);
        return httpd_resp_send_err(request, HTTPD_500_INTERNAL_SERVER_ERROR,
                                   "Could not save Nabi setup");
    }

    httpd_resp_set_type(request, "application/json");
    httpd_resp_set_hdr(request, "Connection", "close");
    const auto result = httpd_resp_send(request, encoded, HTTPD_RESP_USE_STRLEN);
    cJSON_free(encoded);
    return result;
#else
    return httpd_resp_send_err(request, HTTPD_404_NOT_FOUND, "Not found");
#endif
}

esp_err_t NabiEspProvisioning::HandleConfig(uint32_t, const uint8_t* input, ssize_t input_len,
                                            uint8_t** output, ssize_t* output_len,
                                            void* user_data) {
#if defined(CONFIG_NABI_ESP_ASSISTANT) || defined(CONFIG_NABI_ESP_CLOUD_ASSISTANT)
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
    char* ssid = CopyJsonString(root, "ssid");
    char* password = CopyJsonString(root, "password");
#ifdef CONFIG_NABI_ESP_CLOUD_ASSISTANT
    char* mode = CopyJsonString(root, "mode");
    char* pairing_token = CopyJsonString(root, "pairing_token");
    const bool valid_contract = cJSON_IsNumber(contract_version) &&
                                contract_version->valueint == NABI_CLOUD_CONTRACT_VERSION &&
                                cJSON_IsNumber(protocol_version) &&
                                protocol_version->valueint == NABI_CLOUD_PROTOCOL_VERSION &&
                                mode != nullptr && strcmp(mode, "cloud") == 0 &&
                                PairingTokenIsValid(pairing_token);
#else
    cJSON* port = cJSON_GetObjectItemCaseSensitive(root, "port");
    char* ota_path = CopyJsonString(root, "ota_path");
    char* websocket_path = CopyJsonString(root, "websocket_path");
    const bool valid_contract =
        cJSON_IsNumber(contract_version) && contract_version->valueint == NABI_CONTRACT_VERSION &&
        cJSON_IsNumber(protocol_version) && protocol_version->valueint == NABI_PROTOCOL_VERSION &&
        cJSON_IsNumber(port) && port->valueint == NABI_AI_PORT && ota_path != nullptr &&
        strcmp(ota_path, NABI_OTA_PATH) == 0 && websocket_path != nullptr &&
        strcmp(websocket_path, NABI_WEBSOCKET_PATH) == 0;
#endif
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
#ifdef CONFIG_NABI_ESP_CLOUD_ASSISTANT
    Settings cloud_settings("nabi_cloud", true);
    std::string device_id = cloud_settings.GetString("device_id");
    if (device_id.size() != 32) {
        device_id = NewDeviceId();
        cloud_settings.SetString("device_id", device_id);
    }
    cloud_settings.SetString("pairing_token", pairing_token);
    cloud_settings.EraseKey("refresh_token");
    self->cloud_device_id_ = device_id;
    self->cloud_access_token_.clear();
    self->cloud_websocket_url_.clear();
#endif
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
#ifdef CONFIG_NABI_ESP_CLOUD_ASSISTANT
    cJSON_AddStringToObject(response, "device_id", device_id.c_str());
#endif
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
#if defined(CONFIG_NABI_ESP_ASSISTANT) || defined(CONFIG_NABI_ESP_CLOUD_ASSISTANT)
    auto* config = static_cast<PendingWifiConfig*>(context);
    vTaskDelay(pdMS_TO_TICKS(1000));
    auto& manager = WifiManager::GetInstance();
    auto& ssids = SsidManager::GetInstance();
    ssids.Clear();
    ssids.AddSsid(config->ssid, config->password);
    if (manager.IsConfigMode()) {
        manager.StopConfigAp();
    } else {
        manager.StopStation();
        manager.StartStation();
    }
    delete config;
#else
    (void)context;
#endif
    vTaskDelete(nullptr);
}
