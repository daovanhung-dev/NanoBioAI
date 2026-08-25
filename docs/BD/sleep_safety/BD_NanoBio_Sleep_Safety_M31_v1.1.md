# BD — M31 Giám sát giấc ngủ, cảnh báo dai dẳng & phân tích đêm

> **Dự án:** NanoBio / NamiAI  
> **Mã tài liệu:** BD-NANOBIO-SLEEP-SAFETY-001  
> **Module:** M31 `SLEEP_SAFETY_MONITORING`  
> **Phiên bản:** 1.1  
> **Ngày cập nhật:** 2026-08-24  
> **Kế thừa:** `BD_NanoBio_Sleep_Safety_M31_v1.0.md`

## 1. Delta mục tiêu

M31 v1.1 giữ nguyên detector, quyền truy cập Plus/FamilyPlus, on-device audio
processing và escalation contract v1.0, đồng thời bổ sung:

1. Cảnh báo sự kiện âm thanh dai dẳng, tách khỏi foreground monitoring
   notification.
2. Âm cảnh báo Android lặp đến khi người dùng phản hồi hoặc phiên dừng/fail.
3. Phân tích định lượng sau phiên bằng công thức local, hoạt động offline.
4. Xu hướng tối đa 7 đêm theo baseline cá nhân.
5. Morning check-in tự khai báo để bổ sung dữ liệu mà micro không thể xác định.
6. Màn hình phân tích đêm riêng.
7. AI analysis do người dùng chủ động gửi bằng Gemini key đã cấu hình.

## 2. Safety/privacy boundary

- Không lưu/upload raw audio, PCM, recording hoặc transcript.
- Không gửi số điện thoại SafetyContact, OTP, token, API key hoặc user id cho AI.
- Không suy ra REM/N1/N2/N3/deep sleep từ micro.
- Không chẩn đoán sleep apnea, co giật, đột quỵ, bệnh tim/phổi từ acoustic metadata.
- `Nabi Sleep Wellness Score` và các score khác là product wellness analytics,
  không phải chỉ số y khoa.
- AI chỉ nhận JSON tổng hợp đã được client sanitize.
- AI lỗi/thiếu key không làm hỏng local analysis.

## 3. Alert contract v1.1

```text
monitoring
-> foreground notification persistent + silent
-> confirmed safety event
-> alert notification riêng + vibration + audible loop
-> T+30s reminder giữ nguyên
-> T+60s escalation giữ nguyên
-> OK / Need help / stop / native failure
-> dừng audible loop + clear alert notification
```

Foreground microphone notification không được alert notification ghi đè.
M31 không thêm exact-alarm requirement.

Trên iOS, normal notification/action vẫn là baseline. Critical Alerts chỉ được
xem là capability khi Apple entitlement tương ứng được cấp; v1.1 không tuyên bố
bypass Silent/Focus.

## 4. Local analysis

Formula version: `m31_sleep_wellness_v1_2026_08`.

Nhóm chỉ số gồm:

- monitoring duration;
- event count/rate;
- severity ratio;
- confidence/relative energy/baseline delta;
- repetition burden và acoustic diversity;
- 30-minute clustering;
- longest alert-free interval và median inter-event interval;
- response/no-response/need-help/escalation rate;
- response latency;
- weighted disturbance;
- data quality;
- safety attention;
- 7-night event/disturbance trend;
- monitoring/start-time consistency;
- personal baseline deviation;
- recent-vs-baseline change;
- trend confidence;
- composite `Nabi Sleep Wellness Score`.

Morning check-in bổ sung self-reported estimated sleep minutes, sleep efficiency,
fragmentation rate và restfulness. Nếu người dùng không nhập, hệ thống không bịa
các giá trị này.

## 5. AI analysis

AI chỉ chạy khi người dùng bấm `Phân tích với AI` và xác nhận gửi dữ liệu tổng
hợp. Client dùng Gemini REST canonical của dự án, key từ runtime configuration
`GEMINI_API_KEY` và model có thể override bằng `GEMINI_SLEEP_MODEL`.

Output structured JSON gồm 9 section:

- `overall_summary`
- `night_pattern`
- `acoustic_event_analysis`
- `seven_night_trend`
- `wellness_observations`
- `recommended_actions`
- `what_to_monitor_next`
- `data_limitations`
- `care_guidance`

## 6. Persistence

SQLite v23 thêm local-only table `sleep_safety_night_analyses` keyed by
`session_id`. Bảng chỉ lưu numeric/JSON metadata, morning check-in và AI summary.
Raw audio fields bị cấm.

Migration path phải chạy tuần tự v22 rồi v23; fresh install cũng phải ensure cả
schema v22 hiện hành và v23.

## 7. Acceptance

- Monitoring notification còn tồn tại trong lúc alert.
- Android alert có notification id riêng và audible loop idempotent.
- OK/Need help/stop/failure dừng tone.
- Local analysis hoạt động khi offline/AI thiếu key.
- Có trên 30 metric/formula định lượng và trend 7 đêm.
- AI payload không chứa raw audio/PII/key.
- UI luôn có disclaimer không thay thế bác sĩ/thiết bị chẩn đoán/cấp cứu.
