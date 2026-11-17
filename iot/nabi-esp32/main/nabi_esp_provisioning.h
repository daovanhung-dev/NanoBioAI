#pragma once

#include <esp_err.h>
#include <esp_event.h>
#include <esp_http_server.h>
#include <protocomm.h>
#include <stdint.h>
#include <sys/types.h>
#include <atomic>
#include <mutex>
#include <string>

class NabiEspProvisioning {
public:
    static NabiEspProvisioning& GetInstance();

    void Start();
    bool IsPaired() const;
    std::string GetPairingCode() const;
    std::string BeginConfigSession();
    std::string GetConfigAccessCode() const;
    void RegisterLocalApiHandlers(httpd_handle_t server);
    std::string GetDeviceKey() const;
    std::string GetLocalOtaUrl() const;
    bool AuthenticateCloud();
    bool HasCloudCredentials() const;
    std::string GetCloudDeviceId() const;
    std::string GetCloudAccessToken() const;
    std::string GetCloudWebsocketUrl() const;

private:
    NabiEspProvisioning() = default;
    bool started_ = false;
    std::atomic_bool paired_{false};
    std::atomic_bool pairing_locked_{false};
    std::atomic_uint8_t pairing_failed_attempts_{0};
    bool security_event_handler_registered_ = false;
    int64_t pairing_started_us_ = 0;
    std::string pairing_code_;
    std::string device_key_;
    std::string cloud_device_id_;
    std::string cloud_access_token_;
    std::string cloud_websocket_url_;
    char* sec2_salt_ = nullptr;
    char* sec2_verifier_ = nullptr;
    uint16_t sec2_salt_len_ = 0;
    int sec2_verifier_len_ = 0;
    protocomm_t* protocomm_ = nullptr;

    bool ConfigureSecurity(const std::string& secret);
    static void RefreshSecurityTask(void* context);
    static void SecurityEventHandler(void* context, esp_event_base_t event_base, int32_t event_id,
                                     void* event_data);
    static esp_err_t HandleConfig(uint32_t session_id, const uint8_t* input, ssize_t input_len,
                                  uint8_t** output, ssize_t* output_len, void* user_data);
    static esp_err_t HandleLocalStatus(httpd_req_t* request);
    static esp_err_t HandleLocalProvision(httpd_req_t* request);
    static void StartWifiTask(void* context);

    mutable std::mutex config_session_mutex_;
    std::string config_access_code_;
    std::atomic_bool config_session_consumed_{false};
};
