#pragma once

#include <esp_err.h>
#include <esp_event.h>
#include <protocomm.h>
#include <stdint.h>
#include <sys/types.h>
#include <string>
#include <atomic>

class NabiEspProvisioning {
public:
    static NabiEspProvisioning& GetInstance();

    void Start();
    bool IsPaired() const;
    std::string GetDeviceKey() const;
    std::string GetLocalOtaUrl() const;

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
    char* sec2_salt_ = nullptr;
    char* sec2_verifier_ = nullptr;
    uint16_t sec2_salt_len_ = 0;
    int sec2_verifier_len_ = 0;
    protocomm_t* protocomm_ = nullptr;

    bool ConfigureSecurity(const std::string& secret);
    static void RefreshSecurityTask(void* context);
    static void SecurityEventHandler(void* context, esp_event_base_t event_base,
                                     int32_t event_id, void* event_data);
    static esp_err_t HandleConfig(uint32_t session_id, const uint8_t* input, ssize_t input_len,
                                  uint8_t** output, ssize_t* output_len, void* user_data);
    static void StartWifiTask(void* context);
};
