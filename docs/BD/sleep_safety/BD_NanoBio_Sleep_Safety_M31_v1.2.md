# BD — M31 Giám sát giấc ngủ, cảnh báo dai dẳng & phân tích đêm

> **Dự án:** NanoBio / NamiAI  
> **Mã tài liệu:** BD-NANOBIO-SLEEP-SAFETY-001  
> **Module:** M31 `SLEEP_SAFETY_MONITORING`  
> **Phiên bản:** 1.2  
> **Ngày cập nhật:** 2026-10-06  
> **Kế thừa:** `BD_NanoBio_Sleep_Safety_M31_v1.1.md`

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

SQLite v23 originally added local-only table `sleep_safety_night_analyses` keyed
by `session_id`. Current M31 local schema is SQLite v28: v26 added contact
channel preferences, v27 added default-off unverified voice consent, and v28
removes the obsolete Zalo opt-in while preserving cached contact data. Tables
store numeric/JSON metadata, morning check-in, AI summary and minimal dispatch
retry metadata. Raw audio fields remain forbidden.

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

## 8. M31 v1.3 — Gọi cảnh báo cho liên hệ chưa xác minh

Quyết định này bổ sung và thay thế phần `verified-only dispatch` của
`M31-BR08`/`M31-AC07` trong BD v1.0 đối với kênh gọi điện:

- Số chưa xác minh được nhận cuộc gọi thoại tự động khi chủ tài khoản bật riêng
  `allow_unverified_voice_alert`; lựa chọn này mặc định tắt.
- Số chưa xác minh không nhận SMS. Khi voice thất bại/no-answer, hệ thống bỏ qua
  SMS cho số đó và tiếp tục contact đủ điều kiện kế tiếp.
- SMS vẫn yêu cầu số đã xác minh.
- Quyền paid access, điều kiện sự kiện, rate limit, idempotency và rollout của
  luồng tự động tiếp tục được kiểm tra như trước.
- App dùng overload RPC contact 7 tham số hiện hành; RPC 5 tham số cũ tiếp tục
  phục vụ tương thích.

## 9. M31 v1.4 — Direct help call and server-channel removal

### Explicit user help

- Khi người dùng bấm `Tôi cần hỗ trợ`, app chọn SafetyContact active có opt-in
  gọi điện với `priority` nhỏ nhất.
- Luồng này ghi nhận phản hồi local và không gọi Edge dispatch hoặc tạo outbox
  retry máy chủ.
- `phone_fallback_enabled` là cờ toàn hệ thống, mặc định `false`. Khi cờ tắt
  hoặc không có contact phù hợp, alert vẫn hoạt động và app hướng dẫn người dùng.
- Android xin quyền `CALL_PHONE` trước phiên giám sát. Nếu được cấp, app yêu cầu
  hệ điều hành gọi trực tiếp bằng `ACTION_CALL`; nếu từ chối hoặc khởi tạo lỗi,
  app mở trình gọi với số đã điền để người dùng tự bấm Gọi.
- iOS mở `tel:` và có thể yêu cầu xác nhận hệ điều hành.
- Kết quả chỉ ghi nhận hệ điều hành đã nhận yêu cầu khởi tạo hoặc app đã bàn giao
  sang trình gọi; không khẳng định cuộc gọi đã kết nối hay người nhận đã bắt máy.
- Không tự động gọi 115.

### Automatic no-response escalation

- Timer +60 giây khi không có phản hồi vẫn chạy dispatch máy chủ theo priority,
  giữ voice/SMS và bounded retry hiện hành.
- Edge chỉ chấp nhận sự kiện `noResponse`; phản hồi `needHelp` chỉ đi qua phone
  gateway tại thiết bị.
- SMS chỉ gửi tới contact đã xác minh. Contact chưa xác minh chỉ nhận voice khi
  chủ tài khoản bật consent riêng, mặc định tắt.

### Schema and QA scope

- Giữ nguyên lịch sử các migration đã áp dụng; migration tiến tới xóa các cột
  preference/kênh không còn dùng và chỉ cho phép dispatch voice/SMS.
- SQLite v28 rebuild bảng cache contact để bỏ cột cũ, giữ nguyên contact cùng
  các trường còn lại.
- QA chỉ dùng project đã xác nhận; xóa giá trị opt-in cũ nhưng giữ contact và
  dữ liệu khác. Không đổi production.
- Nghiệm thu cuộc gọi thực phải do người dùng thao tác trên Xiaomi và thiết bị
  nhận khác. Một lần kiểm thử không bảo đảm mọi cuộc gọi kết nối trong mọi điều
  kiện mạng, SIM và trạng thái máy nhận.
