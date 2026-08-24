# BD — M31 Giám sát giấc ngủ & cảnh báo an toàn

> **Dự án:** NanoBio / NamiAI  
> **Mã tài liệu:** BD-NANOBIO-SLEEP-SAFETY-001  
> **Module:** M31 `SLEEP_SAFETY_MONITORING`  
> **Phiên bản:** 1.0  
> **Lifecycle:** Current  
> **Business decision:** Approved  
> **Implementation:** Implemented/source-ready; paid rollout enabled by SQL 08  
> **Verification:** Runtime-unverified; Sandbox-unverified  
> **Ngày chốt:** 2026-08-24  
> **Nguồn quyết định:** yêu cầu tính năng và lựa chọn Product Owner `1B 2A 3A 4A 5B 6A 7B 8A 9A 10A`.

## 1. Mục tiêu

M31 cho phép người dùng Plus/FamilyPlus chủ động bật một phiên giám sát trong
thời gian ngủ. Điện thoại phân tích tín hiệu âm thanh tại thiết bị để nhận ra
một số **bất thường âm thanh phi y tế** có thể cần người dùng chú ý. Khi có tín
hiệu đáng ngờ, NanoBio hỏi **“Bạn có ổn không?”**; nếu người dùng yêu cầu hỗ trợ
hoặc không phản hồi trong thời gian đã chốt, hệ thống gửi yêu cầu liên hệ tới
người hỗ trợ đã xác minh.

M31 là lớp hỗ trợ cảnh báo sớm và không phải thiết bị y tế, hệ thống chẩn đoán,
hệ thống cấp cứu chuyên dụng hoặc cam kết phát hiện mọi tình huống nguy hiểm.

## 2. Phạm vi đã phê duyệt

### 2.1. Nền tảng

- Android và iOS cùng thuộc scope M31.
- Người dùng phải chủ động bắt đầu phiên giám sát khi app đang ở trạng thái cho
  phép xin quyền/bật micro.
- Lịch tự động chỉ dùng để **nhắc người dùng mở app và xác nhận bắt đầu**; lịch
  không được âm thầm bật micro khi app bị terminate/reboot hoặc khi OS không cho
  phép.
- Khi một phiên đã chạy hợp lệ, native runtime có thể tiếp tục thu tín hiệu
  audio theo quyền/background capability của từng OS.

### 2.2. Loại tín hiệu

M31 chỉ phân loại các nhóm acoustic safety signal sau:

1. `suddenLoudSound` — âm thanh lớn đột ngột.
2. `strongImpact` — tín hiệu dạng va đập mạnh.
3. `abnormalShout` — mẫu năng lượng/dao động tương tự tiếng la cần chú ý.
4. `abnormalScream` — mẫu năng lượng/dao động cao tương tự tiếng kêu cần chú ý.
5. `repeatedSuspiciousPattern` — mẫu âm bất thường lặp lại.
6. `unknownHighEnergyEvent` — tín hiệu năng lượng cao chưa phân loại.

Các nhãn trên là **acoustic labels**, không được diễn giải thành ngưng thở khi
ngủ, co giật, đột quỵ, bệnh tim, bệnh hô hấp hoặc chẩn đoán y khoa khác.

### 2.3. Privacy

- Audio được xử lý on-device.
- Không lưu file ghi âm thô.
- Không upload raw PCM/audio lên Supabase/provider.
- Không tạo transcript từ audio của M31.
- Chỉ được lưu metadata cần thiết: session, thời gian, loại tín hiệu, mức tương
  đối, confidence kỹ thuật, phản hồi, trạng thái escalation và evidence dispatch.
- Log/analytics không chứa số điện thoại đầy đủ, OTP, provider token, raw audio
  hoặc health PII không cần thiết.

## 3. Actor và access

| Actor | Quyền | Giới hạn |
|---|---|---|
| Guest | Thấy entry theo shell hiện hành nếu có. | Không được chạy M31. |
| Free Member | Có thể được hướng tới nâng cấp. | Không được bật micro M31, tạo session/event hoặc dispatch. |
| Plus Member | Dùng M31 cho chính tài khoản. | Phải vượt trusted access check và rollout. |
| FamilyPlus Member | Dùng M31 cho chính tài khoản đang đăng nhập. | M31 v1 không dùng FamilyPlus subject sharing để giám sát người khác từ xa. |
| SafetyContact | Nhận cảnh báo sau khi được user thiết lập/xác minh. | Không trở thành tài khoản FamilyPlus/Admin và không được xem health data. |
| Edge Function | Xác minh contact và dispatch. | Phải re-check auth/paid access/rate limit/event eligibility. |
| Provider SMS/Voice | Gửi OTP/cảnh báo. | Chỉ nhận payload tối thiểu cần cho delivery. |

M31 v1 là **Plus/FamilyPlus only**. Paid access phải lấy từ trusted backend
(`effective_user_access`); route, màu UI, SQLite hoặc local cache không được tự
suy ra quyền.

## 4. SafetyContact

- Mỗi user tối đa 3 SafetyContact active.
- Priority là 1, 2 hoặc 3 và không trùng trong cùng user.
- Field tối thiểu: tên, quan hệ, số điện thoại E.164, priority, verification
  status, verified timestamp, active.
- Thay đổi số điện thoại làm verification quay về `pending`.
- Chỉ contact `verified + active` được dùng cho escalation.
- OTP không bao giờ trả về Flutter; server lưu hash và expiry.
- SafetyContact độc lập FamilyPlus.

## 5. Luồng chính

### UC-M31-01 — Bắt đầu giám sát thủ công

1. User mở `/sleep-tracking`.
2. App xác thực user và trusted Plus/FamilyPlus access.
3. App kiểm tra rollout M31.
4. User bấm **Bắt đầu giám sát đêm nay**.
5. App xin/kiểm tra microphone + notification permissions.
6. App tạo local-first session.
7. Native runtime bắt đầu microphone foreground/background audio session hợp lệ.
8. Nếu chưa calibration, chạy calibration khoảng 30 giây.
9. Trạng thái chuyển `monitoring`.

### UC-M31-02 — Nhắc theo lịch

1. User bật lịch và chọn thời gian/ngày.
2. App lên lịch notification nhắc bật giám sát.
3. Notification không tự khởi động micro.
4. User chạm notification → `/sleep-tracking?source=scheduled_reminder`.
5. User chủ động bấm bắt đầu.
6. Phiên có thể tự dừng tại `scheduledWindowEnd` nếu native runtime còn active.

### UC-M31-03 — Phát hiện và hỏi an toàn

1. Native detector chỉ giữ audio frame trong RAM đủ để tính feature.
2. Detector so sánh mức năng lượng với baseline calibration và sensitivity.
3. Candidate được xác nhận theo detector policy đang rollout.
4. App/native tạo metadata event.
5. Thiết bị phát cảnh báo và hiển thị **Bạn có ổn không?**.
6. Có hai lựa chọn: **Tôi ổn** / **Tôi cần hỗ trợ**.
7. Sau 30 giây chưa phản hồi: nhắc lần 2.
8. Sau tổng 60 giây chưa phản hồi: escalation required.

### UC-M31-04 — Người dùng xác nhận ổn

1. User chọn `Tôi ổn`.
2. Event ghi `response=ok`.
3. Không gửi cloud escalation.
4. Detector vào cooldown rồi quay lại monitoring.

### UC-M31-05 — Cần hỗ trợ / không phản hồi

1. `Tôi cần hỗ trợ` → escalation ngay; hoặc hết 60 giây → `noResponse`.
2. Client đồng bộ metadata event lên cloud nếu có mạng.
3. Client gọi `sleep-safety-dispatch` với stable idempotency key theo event.
4. Edge Function re-check auth, Plus/FamilyPlus, rollout, event freshness,
   escalation flag, rate limit và verified contacts.
5. Cascade mặc định: Priority 1 voice → SMS fallback khi voice fail/no-answer →
   Priority 2 → Priority 3.
6. Provider callback cập nhật dispatch; callback terminal failure có thể tiếp tục
   cascade mà không phụ thuộc app đang foreground.
7. Không tự gọi 115 hoặc cơ quan cấp cứu chính thức.

## 6. Business Rules

| ID | Rule |
|---|---|
| M31-BR01 | M31 chỉ dành cho authenticated Plus/FamilyPlus và phải fail-closed khi không xác minh được access. |
| M31-BR02 | Schema 07 tạo kill switch mặc định OFF; quyết định rollout hiện hành dùng SQL 08 để bật `default.enabled=true`. Kill switch server-side vẫn tồn tại và có thể tắt khi cần. |
| M31-BR03 | User phải chủ động bắt đầu micro; lịch chỉ nhắc/arming UI. |
| M31-BR04 | Audio M31 xử lý on-device; không lưu/upload raw audio hoặc transcript. |
| M31-BR05 | Detection là acoustic safety signal phi y tế; không chẩn đoán hoặc kết luận người dùng an toàn/nguy kịch. |
| M31-BR06 | Alert lần 1 tại T0, reminder tại T+30s, escalation tại T+60s nếu không phản hồi. |
| M31-BR07 | `needHelp` escalation ngay; `ok` không escalation và bắt đầu cooldown. |
| M31-BR08 | Có tối đa 3 SafetyContact active, unique priority 1–3; chỉ contact verified được dispatch. |
| M31-BR09 | Edge Function phải kiểm tra lại paid access, event eligibility, rollout, idempotency và rate limit. |
| M31-BR10 | Không tự gọi 115/emergency service trong M31 v1. |
| M31-BR11 | Low/Balanced/High, calibration ~30s và cooldown là capability bắt buộc; numeric detector threshold là technical rollout config/implementation evidence, không phải ngưỡng y khoa. |
| M31-BR12 | Nếu cloud/provider thất bại, local warning vẫn được giữ; UI không được nói rằng người thân đã được liên hệ khi server chưa accept. |
| M31-BR13 | M31 v1 chỉ giám sát người dùng đang sở hữu thiết bị/tài khoản; không dùng FamilyPlus để bật mic từ xa trên thiết bị thành viên khác. |
| M31-BR14 | Service không tự restart microphone sau reboot/process death nếu không có phiên user-start hợp lệ. |

## 7. Trạng thái

### Session

`idle → arming → calibrating? → monitoring → alerting/escalating → monitoring/cooldown → stopped|failed`

### Event response

`none → ok | needHelp | noResponse`

### Dispatch

`queued → submitted → delivered|answered|failed|noAnswer|cancelled`

## 8. Error/fail-safe contract

- Microphone denied/revoked → không start hoặc stop session + copy rõ ràng.
- Notification denied → không start M31 v1 vì người dùng có thể bỏ lỡ alert khi
  màn hình khóa.
- Paid access unresolved → không mount/start monitoring runtime.
- Rollout disabled/unreadable → không start; rollout hiện hành chỉ trở thành ON sau khi SQL 08 đã được áp dụng thành công.
- Không có verified contact → local monitoring có thể chạy, nhưng UI phải cảnh
  báo cloud escalation chưa sẵn sàng; Edge Function không giả accepted.
- Offline → local detection/alert vẫn chạy; cloud escalation có thể thất bại và
  UI phải nói rõ chưa liên hệ được.
- Provider error/no-answer → dùng fallback/cascade theo priority.
- Reconnect/app-engine recreation → native active-session snapshot phải cho phép
  khôi phục state và stable idempotency ngăn dispatch trùng.

## 9. Acceptance Criteria

| ID | Acceptance |
|---|---|
| M31-AC01 | Free/Guest không thể start M31; Plus/FamilyPlus được dùng khi trusted access hợp lệ và server rollout từ SQL 08 đang true. |
| M31-AC02 | Android user-started monitoring dùng microphone foreground service và có persistent notification. |
| M31-AC03 | iOS user-started monitoring cấu hình background audio recording; khóa màn hình không được tự coi là stop nếu OS cho phép session tiếp tục. |
| M31-AC04 | Raw audio không xuất hiện trong SQLite/Supabase/provider payload/log. |
| M31-AC05 | Calibration 30s, Low/Balanced/High và cooldown hoạt động theo source contract. |
| M31-AC06 | Alert T0, reminder ~30s, escalation ~60s; `needHelp` không đợi 60s. |
| M31-AC07 | SafetyContact max 3, unique priority, E.164, verified-only dispatch. |
| M31-AC08 | Edge dispatch re-check trusted paid access và rollout; client không thể tự đánh dấu contact verified. |
| M31-AC09 | Stable event idempotency không tạo lại cùng cascade khi app reconnect/retry. |
| M31-AC10 | Provider terminal failure/no-answer tiếp tục SMS/next priority theo contract. |
| M31-AC11 | Không có code path tự gọi 115. |
| M31-AC12 | UI luôn hiển thị disclaimer “hỗ trợ cảnh báo sớm, không thay thế thiết bị y tế/hệ thống cấp cứu chuyên dụng”. |
| M31-AC13 | Schedule notification chỉ mở app/route; không tự start microphone. |
| M31-AC14 | Rollout hiện hành được bật bằng SQL 08; server kill switch vẫn có thể tắt ngay khi cần. Runtime/device/provider acceptance vẫn phải được ghi nhận độc lập. |
| M31-AC15 | FeatureHub hiển thị `Giám sát giấc ngủ` trong nhóm chức năng đang hoạt động; Free vẫn đi qua paid gate thay vì bị ẩn dưới “Sắp ra mắt”. |

## 10. Quyết định Product Owner 2026-08-24

| ID | Lựa chọn đã chốt |
|---|---|
| Q-M31-01 | 1B — Android + iOS cùng scope. |
| Q-M31-02 | 2A — chỉ acoustic safety signals phi y tế. |
| Q-M31-03 | 3A — on-device, không lưu/upload raw audio. |
| Q-M31-04 | 4A — hỏi an toàn, nhắc 30s, escalation 60s hoặc needHelp ngay. |
| Q-M31-05 | 5B — Supabase Edge Function → SMS/voice provider. |
| Q-M31-06 | 6A — SafetyContact riêng, tối đa 3, có priority và verification. |
| Q-M31-07 | 7B — Plus/FamilyPlus only. |
| Q-M31-08 | 8A — manual start + lịch nhắc. |
| Q-M31-09 | 9A — Low/Balanced/High + calibration ~30s + cooldown. |
| Q-M31-10 | 10A — không tự gọi 115/cơ quan cấp cứu. |

## 11. Release gate

M31 **không được chuyển rollout ON** chỉ dựa trên static source. Trước release
cần tối thiểu:

- Android device smoke foreground/background/lock-screen/permission revoke.
- iPhone device smoke foreground/background/lock-screen/interruption.
- Phiên 8 giờ battery/thermal/audio stability trên thiết bị đại diện.
- Dataset acoustic nội bộ được consent/licensed để đo false positive/false
  negative theo từng thiết bị/môi trường; không dùng dữ liệu lâm sàng để suy
  diễn diagnosis.
- Supabase sandbox rebuild/RLS/RPC/OTP/dispatch idempotency/rate-limit tests.
- Provider sandbox callback, no-answer và cascade tests.
- Privacy/copy review và store policy review cho background microphone.
