# PLAN — M31 Zalo Alert + Offline Phone Fallback

> Project: NanoBioAI / Nabi  
> Repository: `https://github.com/daovanhung-dev/NanoBioAI.git`  
> Target branch baseline: `main`  
> Module: `M31 SLEEP_SAFETY_MONITORING`  
> Task type: `coding` + Supabase/Edge + Android/iOS integration + test + docs  
> Status: **EXECUTION AUTHORIZED — source implementation complete; live rollout stays behind verified environment and acceptance gates**  
> Execution branch: `feature/m31-zalo-phone-fallback`  
> Updated: `2026-10-06`

Execution snapshot (2026-10-06): M31 source/docs are implemented. The focused
Flutter suite passes (21/21), full `flutter analyze --no-pub` reports no issues,
and the Android debug APK builds. Two staging migrations are applied:
`20261006090000` (M31) and `20261006100000` (contact E.164 validator fix).
The fix was verified against the table constraint and both contact upsert RPCs.
PITR and physical backups are unavailable; migrations are transactional and
forward-only. The single `default` runtime row is back at
`phone_fallback_enabled=false`, `zalo_enabled=false`. No Edge deploy, cloud
dispatch, contact insert, OTP, or phone call occurred. The Xiaomi 220333QPG
(Android 11/API 30) app was restored after a device integration-test runner
reset its local session/cache; the user is signing in again. Monitoring, dialer,
and two-way call acceptance remain unverified. Do not close the plan until the
real-device call acceptance gate passes.

---

## 0. Mục tiêu cuối cùng

Nâng cấp luồng M31 hiện tại mà **không viết lại detector** và không phá state machine 30/60 giây.

Luồng mục tiêu:

```text
Native detector phát hiện confirmed safety event
    -> local alarm + vibration + notification
    -> T+30s nhắc lại
    -> T+60s hoặc user chọn "Tôi cần hỗ trợ"
    -> Emergency Dispatch Orchestrator

ONLINE / INTERNET KHẢ DỤNG
    -> sync session/event lên Supabase
    -> Edge Function xác minh auth + Plus/FamilyPlus + rollout + event + contacts
    -> gửi cảnh báo Zalo tới contact đã bật Zalo
    -> đồng thời/tiếp tục voice cascade hiện có theo P1 -> P2 -> P3
    -> SMS chỉ giữ làm cloud fallback hiện hữu nếu voice thất bại
    -> lưu dispatch evidence + idempotency

OFFLINE / KHÔNG CÓ INTERNET
    -> không cố gọi Edge Function vô hạn
    -> giữ local alarm đang chạy
    -> hiển thị hành động "Gọi ngay <P1>"
    -> mở system dialer với số P1
    -> nếu cần, người dùng có thể chuyển P2/P3
    -> enqueue cloud emergency dispatch trong local outbox
    -> chỉ retry trong freshness window hiện hành
    -> khi Internet trở lại, retry cùng idempotency key

KHÔNG CÓ INTERNET VÀ KHÔNG GỌI ĐƯỢC
    -> local alarm vẫn là lớp cuối cùng
    -> hiển thị rõ "Chưa thể gửi cảnh báo ra ngoài"
    -> không tuyên bố đã liên hệ thành công
```

### Nguyên tắc bắt buộc

1. Không lưu/upload raw audio, PCM, recording hoặc transcript.
2. Không gửi phone/contact PII cho AI.
3. Không tự động gọi `115`.
4. Không hard-code Zalo/OA/ZBS token trong Flutter, native source hoặc `.env` tracked.
5. Paid access vẫn phải lấy từ trusted Supabase `effective_user_access`.
6. Zalo/cloud dispatch không được làm mất local alarm.
7. Local phone fallback không được đánh dấu là “đã gọi thành công” chỉ vì dialer mở.
8. Giữ idempotency key chuẩn hiện tại: `sleep-safety-<eventId>`.
9. Không dùng `READ_CALL_LOG`, `WRITE_CALL_LOG`, `PROCESS_OUTGOING_CALLS`, `SEND_SMS`.
10. Production baseline dùng system dialer / `tel:` do người dùng xác nhận. Không tự gọi ngầm.

---

# 1. Quyết định kiến trúc đã khóa cho Codex

## 1.1 Zalo channel

Ưu tiên triển khai Zalo qua **trusted backend**.

Default design:

```text
Flutter
  -> Supabase Edge Function
    -> Zalo provider adapter
      -> Zalo ZBS Template Message / OA capability được tài khoản NanoBio phê duyệt
```

Không gọi Zalo API trực tiếp từ mobile app.

### Research gate trước khi bật provider

Đã kiểm tra tài liệu Zalo Developers hiện hành. Trước khi bật provider thật, cần xác nhận:

- NanoBio đang dùng OA/ZBS capability nào.
- API gửi message theo **số điện thoại** hay UID nào được phép dùng.
- Template cảnh báo có bắt buộc duyệt trước hay không.
- Token lifetime/refresh contract và quy trình rotation vận hành.
- Webhook/delivery status contract.
- Rate limit/error codes.

Adapter hiện chưa triển khai vòng đời refresh-token rotation. Vì vậy `zalo_enabled=false` bắt buộc ở staging/production cho đến khi credential lifecycle, quyền gửi theo số điện thoại và template được duyệt; response `submitted` chỉ có nghĩa Zalo nhận yêu cầu, không chứng minh tin đã được giao.

Research snapshot (2026-10-06): official send-by-phone API is
[ZBS Template Message](https://stc-developers.zdn.vn/docs/v2/zbs-template-message/gui-tin-template-qua-sdt/api-gui-tin-qua-sdt/api-gui-tin)
at `business.openapi.zalo.me/message/template`; OA authorization describes
25-hour access tokens and single-use refresh-token rotation in
[Zalo Developers authorization docs](https://stc-developers.zdn.vn/docs/v2/official-account/bat-dau/xac-thuc-va-uy-quyen-cho-ung-dung-new).
Zalo's 2026 policy notice describes moderation requirements for template
messages in [Zalo Business](https://zalo.solutions/news/thong-bao-hop-nhat-dinh-nghia-tin-uid-va-zns-thanh-zbs-template-message/cp1zx4bq8mzhhszgz0br1ocd).

Nếu capability chưa được cấp hoặc template chưa approved:

- vẫn code abstraction + feature flag + tests;
- để `zalo_enabled=false`;
- không fake response production;
- current voice/SMS provider vẫn chạy bình thường.

## 1.2 Offline phone fallback

Production-safe contract:

- Android: `ACTION_DIAL` / system dialer.
- Flutter foreground: `url_launcher` với `tel:`.
- Android lock-screen/background notification action: PendingIntent mở `ACTION_DIAL` khi **người dùng bấm**.
- iOS: `tel:` / system Phone app; người dùng quyết định tiếp tục cuộc gọi.

Không thêm auto-call background vào release baseline.

### Optional Android research branch — KHÔNG thực thi mặc định

Chỉ nghiên cứu nếu PO yêu cầu riêng:

- `ROLE_DIALER` / default phone handler;
- `MANAGE_OWN_CALLS` / Telecom/ConnectionService;
- `FOREGROUND_SERVICE_PHONE_CALL`;
- Google Play declaration/review impact.

Không trộn nhánh nghiên cứu này vào bản M31 release thông thường.

---

# 2. Bước 0 — Đồng bộ repository và đọc context bắt buộc

Thực hiện trên workspace hiện có, giữ nguyên thay đổi người dùng và không checkout/reset/pull đè working tree:

```bash
git status
git branch --show-current
```

Nếu repo đã tồn tại:

```bash
git status
git branch --show-current
```

Không được code khi working tree chứa thay đổi không rõ nguồn gốc.

Đọc theo thứ tự:

1. `AGENTS.md`
2. `.codex/AGENTS.md`
3. `.codex/PROJECT_MAP.md`
4. `.codex/history/LEARNED_SKILLS.md`
5. `.codex/workflows/coding.md`
6. `.codex/task-skills/coding.md`
7. `.codex/domains/notification.md`
8. `.codex/domains/access-membership-referral.md`
9. `docs/checklist/checklist_complete_DD.md`
10. `docs/checklist/checklist_task_coding.md`
11. toàn bộ `docs/BD/sleep_safety/`
12. toàn bộ `docs/DD/sleep_safety_monitoring/`
13. M31 source hiện hành.

Tạo branch riêng nếu chưa có branch cho task:

```bash
git checkout -b feature/m31-zalo-phone-fallback
```

---

# 3. Bước 1 — Audit source M31 trước khi sửa

Codex phải xác minh current source truth bằng `rg`, không dựa riêng vào DD/worklog cũ.

```bash
rg --files lib/app_versions/v1/features/sleep_tracking
rg --files android/app/src/main/kotlin/com/example/nano_app/sleep_safety
rg --files test/app_versions/v1/features/sleep_tracking
rg "sleep_safety|SleepSafety|dispatchEmergency|SafetyContact|idempotency|connectivity|url_launcher" \
  lib android ios supabase test docs -g '!build/**' -g '!.dart_tool/**'
```

Xác nhận tối thiểu:

- route `/sleep-tracking`;
- Plus/FamilyPlus access gate;
- rollout provider;
- current 30/60 second native timers;
- Android foreground service;
- iOS AVAudioEngine runtime;
- local SQLite version hiện hành;
- `sleep_safety_outbox` đang được dùng hay chưa;
- current dispatch Edge Function;
- current generic voice/SMS provider;
- current provider webhook;
- current contact verification flow;
- current M31 focused tests.

### Bắt buộc xử lý docs drift

Code baseline khi plan được tạo là `DatabaseVersion.currentVersion = 25`.
Không được dùng số version cũ trong `.codex` hoặc DD để tạo migration.
Migration tiếp theo phải được xác định từ **source hiện tại**; implementation của task này dùng `v26` sau khi kiểm tra source.

---

# 4. Bước 2 — Update BD/DD trước khi code behavior mới

Vì đây là thay đổi product behavior của M31, Codex phải cập nhật contract trước.

## 4.1 BD

Tạo:

```text
docs/BD/sleep_safety/BD_NanoBio_Sleep_Safety_M31_v1.2.md
```

Kế thừa v1.1 và chỉ mô tả delta:

- Zalo alert channel.
- online dispatch policy.
- offline phone fallback.
- local outbox retry.
- privacy boundary.
- Android/iOS differences.
- rollout/kill switch.
- exact definition của “accepted”, “dialer opened”, “answered” và “failed”.

## 4.2 DD

Cập nhật:

```text
docs/DD/sleep_safety_monitoring/README.md
docs/DD/sleep_safety_monitoring/Overall.md
docs/DD/sleep_safety_monitoring/List_Features.md
docs/DD/sleep_safety_monitoring/Function_List.md
docs/DD/sleep_safety_monitoring/Views.md
docs/DD/sleep_safety_monitoring/Import_File.md
docs/DD/sleep_safety_monitoring/diagrams/README.md
```

Thêm feature/function IDs mới theo numbering tiếp theo, ví dụ:

```text
M31-F11  Zalo safety alert
M31-F12  Offline phone fallback
M31-F13  Emergency dispatch outbox/retry

M31-FN23 resolve connectivity/dispatch path
M31-FN24 dispatch Zalo
M31-FN25 open local phone dialer
M31-FN26 enqueue emergency retry
M31-FN27 retry queued dispatch on reconnect
```

Tên ID cuối cùng phải được kiểm tra với DD hiện tại để không trùng.

---

# 5. Bước 3 — Thiết kế domain model

Không đặt logic connectivity/Zalo trực tiếp trong UI.

## 5.1 Contact channel preferences

Mở rộng `SafetyContact` theo hướng backward-compatible.

File:

```text
lib/app_versions/v1/features/sleep_tracking/domain/entities/safety_contact.dart
```

Thêm tối thiểu:

```dart
bool allowZaloAlert;
bool allowPhoneFallback;
```

Không thêm `zalo_user_id` nếu Zalo contract cuối cùng hỗ trợ gửi bằng verified phone number.
Chỉ thêm UID nếu official API thực sự yêu cầu và DD được cập nhật theo contract đó.

Default migration:

```text
allow_zalo_alert = false
allow_phone_fallback = true
```

Lý do:

- không tự bật kênh Zalo mới cho contact cũ;
- phone fallback bám theo số đã verified hiện có.

## 5.2 Dispatch result model

Tạo domain type rõ ràng, không trả `Map<String,Object?>` xuyên toàn bộ app.

Gợi ý:

```text
sleep_safety_dispatch_result.dart
sleep_safety_dispatch_route.dart
```

Các trạng thái cần phân biệt:

```text
cloudAccepted
cloudFailed
zaloSubmitted
zaloDelivered
voiceSubmitted
phoneFallbackRequired
dialerOpened
retryQueued
retryExpired
```

`dialerOpened` tuyệt đối không đồng nghĩa `answered`.

## 5.3 Connectivity abstraction

Tạo gateway riêng:

```text
lib/app_versions/v1/features/sleep_tracking/data/gateways/sleep_safety_connectivity_gateway.dart
```

Dùng `connectivity_plus` hiện có.

Quy tắc:

- `ConnectivityResult.none` = definite offline.
- Wi-Fi/mobile != guarantee Internet.
- Khi network type tồn tại, vẫn phải thử cloud request với timeout.
- Network error/timeout mới chuyển sang fallback.

Không thêm package mới nếu chưa cần.

---

# 6. Bước 4 — SQLite/outbox và migration

## 6.1 Reuse `sleep_safety_outbox`

Ưu tiên dùng table đã có:

```text
sleep_safety_outbox
```

Không tạo table khác nếu table hiện hành đáp ứng được.

Bổ sung DAO methods trong:

```text
lib/core/storage/localdb/daos/sleep_safety_dao.dart
```

Cần tối thiểu:

```text
enqueueDispatchRetry(...)
listPendingDispatches(...)
markDispatchSending(...)
markDispatchAcknowledged(...)
markDispatchFailed(...)
expireStaleDispatches(...)
```

## 6.2 Payload local outbox

Chỉ lưu dữ liệu tối thiểu:

```json
{
  "event_id": "...",
  "idempotency_key": "sleep-safety-...",
  "created_at": "..."
}
```

Không lưu raw audio.
Không lưu Zalo token.
Không cần lưu contact phone trong outbox nếu có thể resolve lại từ verified contact cache.

## 6.3 TTL

Tôn trọng `event_freshness_seconds` hiện tại của server.

Không gửi cảnh báo “khẩn cấp” nhiều giờ sau khi event đã cũ.

Khi hết TTL:

```text
pending -> expired/failed
```

UI phải nói rõ cloud alert không gửi được trong thời gian cho phép.

Nếu schema outbox hiện tại chưa có status `expired`, chọn một trong hai:

- migration thêm `expired`; hoặc
- dùng `failed` + `last_error_code=event_expired`.

Ưu tiên phương án ít schema drift hơn.

## 6.4 Migration

Inspect current migration inventory:

```bash
rg --files lib/core/storage/localdb/migrations | sort
```

Nếu current source vẫn v25:

```text
migration_v26.dart
DatabaseVersion.currentVersion = 26
```

Migration cần:

- add contact channel preference fields nếu local cache cần;
- không phá dữ liệu M31 cũ;
- giữ analysis tables;
- đảm bảo fresh install tạo schema tương đương migrated install.

Thêm migration tests.

---

# 7. Bước 5 — Supabase canonical schema

Theo repo contract, trước khi sửa Supabase phải đọc:

```text
docs/supabase/README.md
docs/supabase/01_build_system.sql
docs/supabase/02_seed_data.sql
```

Chỉ sửa canonical scripts; không tạo migration rời rồi bỏ quên build script.

## 7.1 `sleep_safety_contacts`

Thêm nếu business contract cần lưu server-side:

```sql
allow_zalo_alert boolean not null default false
allow_phone_fallback boolean not null default true
```

Update RPC:

```text
upsert_sleep_safety_contact
```

Server vẫn sở hữu:

- `user_id`;
- verification status;
- verified timestamps.

## 7.2 `sleep_safety_dispatches`

Current channel check đang là:

```text
sms | voice
```

Mở rộng:

```text
zalo | voice | sms
```

Không đưa local dialer vào cloud dispatch row nếu chưa có reliable server evidence.
Local dialer attempt nên được xem là local UI/native evidence riêng.

## 7.3 Runtime config

Mở rộng `sleep_safety_runtime_config` với feature kill switches:

```text
zalo_enabled boolean default false
phone_fallback_enabled boolean default false
```

Có thể thêm:

```text
zalo_send_mode
```

chỉ khi thực sự cần; tránh over-design.

Rollout sequence:

```text
M31 enabled=true
zalo_enabled=false
phone_fallback_enabled=false
```

Sau sandbox/device acceptance mới bật từng capability.

---

# 8. Bước 6 — Zalo provider adapter

## 8.1 Không sửa generic provider thành spaghetti

Current interface hỗ trợ:

```text
verification | sms | voice
```

Refactor có kiểm soát:

```text
_shared/sleep_safety_provider.ts
_shared/sleep_safety_zalo_provider.ts   // new if justified
```

Hoặc tạo composition:

```text
SleepSafetyVoiceSmsProvider
SleepSafetyZaloProvider
```

Không làm Zalo trở thành dependency bắt buộc của OTP verification.

## 8.2 Secrets

Dùng Supabase Function secrets/runtime env, ví dụ logical names:

```text
ZALO_* access credential
ZALO_* template id
ZALO_* app/OA identifier
```

Tên biến cuối cùng phải theo đúng official API contract đã verify.

Không commit secret value.

## 8.3 Message payload

Nội dung phải tối thiểu và không chẩn đoán:

```text
Nabi phát hiện một tình huống âm thanh cần chú ý trong phiên giám sát giấc ngủ.
Người dùng chưa xác nhận an toàn.
Vui lòng liên hệ hoặc kiểm tra người thân.
```

Không gửi:

- bệnh lý suy đoán;
- raw metric chi tiết không cần thiết;
- user health profile;
- recording/transcript.

## 8.4 Zalo failure behavior

Zalo phải là **best-effort additional alert channel**, không phải single point of failure.

```text
Zalo fail
  -> vẫn chạy voice cascade
  -> không đổi cloud dispatch thành failed nếu voice accepted
```

---

# 9. Bước 7 — Refactor Edge dispatch orchestration

Files chính:

```text
supabase/functions/sleep-safety-dispatch/index.ts
supabase/functions/sleep-safety-dispatch/handler.ts
supabase/functions/_shared/sleep_safety_provider.ts
supabase/functions/sleep-safety-provider-webhook/index.ts
```

## 9.1 Desired server order

Sau khi auth/access/event/rate/idempotency checks pass:

```text
verified contacts P1..P3

Phase A — Zalo fan-out
  -> contacts allow_zalo_alert=true
  -> submit Zalo best-effort
  -> record each attempt

Phase B — existing voice cascade
  -> P1 voice
  -> if terminal failure: P1 SMS
  -> if terminal failure: P2 voice -> P2 SMS
  -> P3...
```

Nếu PO muốn “Zalo trước rồi mới call”, có thể thêm delay nhỏ server-side nhưng KHÔNG nên trì hoãn safety call quá lâu.
Default plan: Zalo fire best-effort rồi voice cascade tiếp ngay.

## 9.2 Idempotency

Root:

```text
sleep-safety-<eventId>
```

Derived:

```text
<root>-<contactId>-zalo
<root>-<contactId>-voice
<root>-<contactId>-sms
```

Retry không tạo duplicate logical alert.

## 9.3 Response JSON

Trả summary an toàn:

```json
{
  "accepted": true,
  "reused": false,
  "zalo_attempts": 2,
  "voice_priority": 1,
  "voice_channel": "voice"
}
```

Không trả phone number/token/provider secret.

---

# 10. Bước 8 — Flutter Emergency Dispatch Orchestrator

Không nhồi thêm logic vào `SleepSafetyController` nếu controller trở nên quá lớn.

Tạo service/use-case riêng, ví dụ:

```text
lib/app_versions/v1/features/sleep_tracking/domain/services/
  sleep_safety_emergency_dispatch_service.dart
```

Hoặc data/application service phù hợp kiến trúc hiện hành.

Input:

```text
event
verified contacts
connectivity state
runtime config
```

Output:

```text
Cloud accepted
Phone fallback required
Retry queued
Terminal failure
```

Controller chỉ orchestration state/UI.

### Algorithm

```text
on escalationRequired(event):
  1. ensure exactly-once in-flight guard
  2. resolve verified active contacts
  3. if no verified contact:
       show local alert + no-contact warning
       do not fake dispatch
  4. connectivity == none:
       enqueue retry
       activate phone fallback
       return
  5. try cloud dispatch with bounded timeout
  6. if accepted:
       dismiss/transition native alert according to existing contract
       show trusted acceptance copy
       mark outbox acknowledged if row exists
  7. if network timeout/offline transport error:
       enqueue retry
       activate phone fallback
  8. if trusted server returns business rejection:
       do not misclassify as offline
       show mapped Vietnamese error
       phone fallback may remain available as manual safety action
```

Quan trọng:

- HTTP 403/409/429/503 business response != connectivity offline.
- only network/timeout/no-connectivity triggers automatic offline classification.

---

# 11. Bước 9 — Retry khi Internet trở lại

Dùng `connectivity_plus` stream như signal để thử lại, nhưng server response mới là authority.

Tạo component lifecycle-safe:

```text
SleepSafetyDispatchRetryCoordinator
```

Responsibilities:

- listen connectivity changes while app/service context allows;
- read pending outbox;
- drop/mark expired events;
- retry cùng idempotency key;
- exponential/bounded retry;
- never tight-loop;
- stop retry after accepted or expiry.

Suggested retry:

```text
0s reconnect
+5s
+15s
+30s
```

Không vượt event freshness.

Nếu app đã bị terminate và không có engine:

- không claim guaranteed retry;
- next app initialization drains valid outbox;
- Android native alarm vẫn local-independent.

Nếu muốn guaranteed background network retry sau này, tách thành task riêng (WorkManager/BGTask), không mở rộng scope hiện tại.

---

# 12. Bước 10 — Android phone fallback

Files:

```text
android/app/src/main/kotlin/com/example/nano_app/sleep_safety/SleepSafetyForegroundService.kt
android/app/src/main/kotlin/com/example/nano_app/sleep_safety/SleepSafetyNotificationFactory.kt
android/app/src/main/kotlin/com/example/nano_app/sleep_safety/SleepSafetyChannelHandler.kt
android/app/src/main/kotlin/com/example/nano_app/sleep_safety/SleepSafetyNativeEvent.kt
android/app/src/main/AndroidManifest.xml
```

## 12.1 Không thêm restricted permissions

Không thêm:

```text
READ_CALL_LOG
WRITE_CALL_LOG
PROCESS_OUTGOING_CALLS
SEND_SMS
```

Baseline cũng không cần `CALL_PHONE` nếu dùng dialer.

## 12.2 Notification action

Khi current event đang alerting, notification có thêm action:

```text
Gọi người liên hệ
```

Action phải là user-triggered `PendingIntent.getActivity(...)` với:

```text
Intent.ACTION_DIAL
Uri.parse("tel:<phone>")
```

Không dùng `ACTION_CALL` trong release baseline.

## 12.3 Contact snapshot đưa vào native

Khi `startMonitoring`, Flutter truyền **verified phone-fallback contact snapshot** cho native runtime, chỉ trong memory:

```text
priority
name/short display name
phone_e164
```

Không ghi file/native preferences.

Khi contact list thay đổi lúc monitoring:

```text
updateRuntimeConfig(contactFallbackSnapshot)
```

Native chỉ dùng để render phone action khi Flutter/background channel không sẵn sàng.

## 12.4 Privacy

Không log full phone number.
Nếu cần debug:

```text
contactPriority=1
phoneConfigured=true
```

---

# 13. Bước 11 — iOS phone fallback

File chính:

```text
ios/Runner/AppDelegate.swift
```

Mở rộng notification category:

```text
Tôi ổn
Tôi cần hỗ trợ
Gọi người liên hệ
```

Khi user chọn Call:

```text
UIApplication.shared.open(telURL)
```

Không claim auto-call.
Không bypass Silent/Focus.
Không claim Critical Alerts nếu entitlement chưa được Apple cấp.

Nếu iOS không thể open URL:

- emit native event `phoneFallbackUnavailable`;
- Flutter hiển thị hướng dẫn.

---

# 14. Bước 12 — Flutter UI/UX

Files dự kiến:

```text
lib/app_versions/v1/features/sleep_tracking/presentation/pages/sleep_tracking_page.dart
lib/app_versions/v1/features/sleep_tracking/presentation/pages/sleep_safety_contacts_page.dart
lib/app_versions/v1/features/sleep_tracking/presentation/widgets/sleep_safety_alert_overlay.dart
lib/app_versions/v1/features/sleep_tracking/presentation/widgets/sleep_safety_status_card.dart
```

## 14.1 Contacts page

Mỗi contact:

```text
[✓] Cho phép cảnh báo qua Zalo
[✓] Cho phép gọi số này khi không có mạng
```

Zalo default OFF với existing contacts sau migration.
Phone fallback default ON với verified contact.

Copy:

```text
Zalo cần Internet.
Khi không có Internet, Nabi có thể đề nghị bạn gọi trực tiếp người liên hệ bằng ứng dụng Điện thoại.
```

Không dùng copy “Nabi sẽ tự gọi” ở baseline.

## 14.2 Alert overlay

Bổ sung states:

```text
Đang gửi cảnh báo qua mạng...
Đã gửi yêu cầu liên hệ...
Không có Internet — hãy gọi người liên hệ
Đã mở ứng dụng Điện thoại
Đã xếp hàng gửi lại khi có mạng
Không thể gửi cảnh báo ra ngoài lúc này
```

CTA offline:

```text
Gọi ngay P1
Người tiếp theo
```

Nếu không verified contact:

```text
Thiết lập người liên hệ an toàn
```

Không đóng local alarm chỉ vì dialer đã mở.

---

# 15. Bước 13 — Repository/data source changes

Files dự kiến:

```text
lib/app_versions/v1/features/sleep_tracking/domain/repositories/sleep_safety_repository.dart
lib/app_versions/v1/features/sleep_tracking/data/repositories/sleep_safety_repository_impl.dart
lib/app_versions/v1/features/sleep_tracking/data/datasources/sleep_safety_cloud_datasource.dart
lib/app_versions/v1/features/sleep_tracking/data/datasources/sleep_safety_local_datasource.dart
lib/app_versions/v1/features/sleep_tracking/data/models/sleep_safety_models.dart
lib/app_versions/v1/features/sleep_tracking/providers/sleep_safety_providers.dart
lib/app_versions/v1/features/sleep_tracking/providers/sleep_safety_controller.dart
```

Repository contract cần có method typed:

```text
dispatchEmergency(...)
enqueueEmergencyRetry(...)
retryPendingEmergencyDispatches(...)
openPhoneFallback(...)
```

Nếu `openPhoneFallback` là platform gateway responsibility, giữ nó ngoài repository cloud/local và inject riêng.

Không cho presentation gọi datasource/native channel trực tiếp.

---

# 16. Bước 14 — Cloud error mapping

Mở rộng `SleepSafetyCloudException` với code mới, ví dụ:

```text
zalo_disabled
zalo_provider_unavailable
zalo_template_not_ready
zalo_send_failed
```

Nhưng vì Zalo là best-effort, đa số Zalo-only failure không nên làm toàn dispatch fail nếu voice được accepted.

User-facing copy luôn tiếng Việt, không lộ:

```text
PostgREST
Edge Function
provider token
webhook
HTTP 5xx
```

---

# 17. Bước 15 — Tests bắt buộc

## 17.1 Flutter domain/unit

Tạo/extend:

```text
test/app_versions/v1/features/sleep_tracking/domain/
test/app_versions/v1/features/sleep_tracking/data/
test/app_versions/v1/features/sleep_tracking/providers/
```

Cases tối thiểu:

1. online + cloud accepted.
2. offline -> phone fallback required.
3. connectivity says Wi-Fi but cloud timeout -> fallback.
4. business 403 paid failure != offline.
5. 429 rate limit != offline.
6. retry uses same idempotency key.
7. pending retry expires after freshness window.
8. duplicate reconnect event does not duplicate cloud dispatch.
9. Zalo preference default false for migrated contact.
10. phone fallback only verified active contact.
11. P1/P2/P3 order stable.
12. dialer opened != cloud accepted.
13. local alarm remains active after dialer open.
14. no phone contact -> safe local-only state.
15. no raw audio/contact phone in AI payload.

## 17.2 Controller tests

Extend:

```text
test/app_versions/v1/features/sleep_tracking/providers/sleep_safety_controller_test.dart
```

Cover:

- `needHelp` online;
- `noResponse` online;
- offline fallback;
- cloud timeout;
- retry after reconnect;
- dispatch accepted dismiss behavior;
- phone fallback does not falsely dismiss alarm;
- native channel failure still permits cloud path when online.

## 17.3 Widget tests

Add:

- offline CTA visible;
- Zalo/phone toggles;
- no “đã gọi thành công” after `dialerOpened`;
- accessibility tap target and copy.

## 17.4 SQLite migration tests

Verify:

```text
v25 -> v26
fresh install v26
existing contacts preserved
new defaults correct
outbox preserved
night analysis preserved
```

## 17.5 Supabase SQL contract tests

Verify:

- new columns exist;
- default values;
- RLS unchanged/stronger;
- clients cannot write trusted dispatch status;
- `zalo` allowed in dispatch channel;
- server config kill switches default safe.

## 17.6 Deno Edge Function tests

Cases:

1. Zalo success + voice success.
2. Zalo fail + voice success => whole dispatch accepted.
3. Zalo disabled + voice success.
4. all cloud channels fail.
5. reused idempotency returns reused.
6. no verified contact.
7. expired event.
8. Free user denied.
9. rollout disabled.
10. phone number/token never returned in response.
11. Zalo derived idempotency stable.
12. provider callback does not duplicate cascade.

## 17.7 Android static/native contract tests

Verify source contains:

- `ACTION_DIAL`, not `ACTION_CALL`;
- no restricted Call Log/SMS permissions;
- pending intent action generated from verified contact snapshot;
- notification monitoring ID and alert ID remain separate;
- stop/failure still stops alarm tone.

## 17.8 iOS contract tests/static checks

Verify:

- notification category contains Call action;
- Call action opens `tel:` only after user action;
- no Critical Alert claim/entitlement fabrication;
- existing AVAudio monitoring unaffected.

---

# 18. Bước 16 — Validation commands

Format only touched Dart files:

```bash
dart format <touched-dart-files>
```

Targeted analyze:

```bash
flutter analyze \
  lib/app_versions/v1/features/sleep_tracking \
  lib/core/storage/localdb
```

Focused Flutter tests:

```bash
flutter test test/app_versions/v1/features/sleep_tracking
flutter test test/core/storage/localdb
```

Run relevant Supabase/Deno tests according to existing repo scripts.

Then:

```bash
git diff --check
```

If runtime scope passes targeted checks, run project wrappers:

```powershell
powershell -ExecutionPolicy Bypass -File .codex/tool/codex_quick_check.ps1
```

For Android native acceptance/build:

```powershell
powershell -ExecutionPolicy Bypass -File .codex/tool/codex_check.ps1 -BuildApk
```

If PowerShell unavailable, use equivalent Flutter commands and record exact evidence.

Do not claim PASS for commands not actually executed.

---

# 19. Bước 17 — Staging rồi production trên Supabase thật

Triển khai staging và production được phép theo yêu cầu của Product Owner, với
staging làm acceptance gate bắt buộc. Chỉ dùng additive migration đã review;
không chạy `01_build_system.sql` hoặc `02_seed_data.sql` trên staging/production.

## 19.1 Staging gate

Staging project ref do người dùng cung cấp. Trước khi thay đổi dữ liệu:

1. Xác minh project ref, project name/organization, môi trường staging, schema
   migration history và đúng workspace CLI đang đăng nhập.
2. Xác minh backup/PITR hoặc recovery path và không có migration đang chờ gây
   conflict.
3. Review additive migrations `20261006090000_m31_zalo_phone_fallback.sql` and
   `20261006100000_m31_contact_phone_regex_fix.sql`; both are applied and
   verified in staging. The follow-up fixes an over-escaped E.164 validator
   found while reproducing the contact form failure. Apply through Supabase
   migration workflow, never run build/seed on staging or production.
4. Deploy `sleep-safety-dispatch` sau khi secrets provider hiện có được xác nhận
   đã cấu hình; chỉ thêm Zalo secrets khi token/template được phê duyệt.
5. Giữ `zalo_enabled=false`. Sau khi staging migration/function được xác minh,
   có thể bật tạm `phone_fallback_enabled=true` chỉ cho staging để QA Android/iOS
   với contact đã đồng ý; tắt lại sau smoke. Production vẫn giữ false cho đến
   khi QA acceptance đạt.
6. Chạy SQL/RLS, Edge tests và smoke với **một contact QA đã đồng ý**; timeout
   request cloud là 8 giây. Ghi nhận acceptance mà không đưa số điện thoại hay
   secret vào log/worklog.

## 19.2 Production gate

Sau khi staging acceptance đạt, production rollout được phép theo phạm vi đã
Product Owner phê duyệt, nhưng phải trước đó:

1. Xác minh lại đúng production project ref và tên dự án; không tái sử dụng ref
   staging hoặc nhắm theo context CLI mặc định.
2. Kiểm tra migration history, backup/PITR/recovery path và schema drift.
3. Áp dụng riêng additive migration đã review; deploy function; xác minh kết quả
   schema/function bằng read-only checks.
4. Để mọi kill switch ở `false`; bật dần phone fallback chỉ sau Android+iOS
   acceptance vì cờ hiện tại là toàn môi trường, chưa nhắm riêng platform.
5. Zalo tiếp tục tắt cho đến khi có token lifecycle/rotation bền vững, quyền
   phone-send, template được duyệt, rate-limit và delivery-status contract được
   QA. `submitted` không được báo là delivered.
6. Rollback khẩn cấp bằng cách đặt hai cờ về `false`; không xóa dispatch
   history hay revert schema bằng thao tác destructive.

Không in secret values trong log/worklog/chat. Nếu key đã bị lộ, rotate/revoke
trước khi cấu hình hoặc deploy.

---

# 20. Bước 18 — Real-device Android acceptance

Bắt buộc test máy thật vì M31 là foreground microphone + notification + dialer.

Test matrix:

## A. Online Wi-Fi

```text
start monitoring
-> confirmed event test path
-> T+60 / needHelp
-> Zalo attempt
-> voice cascade
-> correct UI status
```

## B. Online mobile data

Repeat A.

## C. No Internet, cellular voice still available

Không dùng Airplane Mode nếu nó tắt cả cellular voice.

Test bằng cách:

```text
disable Wi-Fi
disable mobile data
keep SIM registered for voice
```

Expected:

```text
cloud request skipped/fails bounded
phone fallback appears
notification has Call action
user tap -> system dialer opens P1 number
local alarm state is not falsely marked accepted
```

## D. Lock screen

- monitoring notification remains;
- safety alert appears separately;
- user can tap Call action;
- dialer opens from explicit user action;
- OK/Need help actions remain working.

## E. Background/app task removed

Verify current `stopWithTask=false` behavior.
Do not claim post-kill network retry if Flutter engine is absent unless explicitly implemented/tested.

## F. Reconnect

During valid freshness window:

```text
offline event -> reconnect Internet -> queued cloud retry -> same idempotency -> accepted once
```

## G. No verified contact

Local warning only; no fake cloud success.

Capture:

- device model/API;
- command output;
- logcat crash scan;
- screenshots/video if appropriate;
- Supabase dispatch row IDs without exposing phone numbers;
- Zalo delivery evidence without secret values.

---

# 21. Bước 19 — iOS acceptance

Chỉ claim khi chạy trên macOS/iPhone thực.

Cases:

- monitoring background audio remains;
- alert notification;
- OK;
- Need help;
- Call contact action;
- `tel:` opens system phone UI;
- user confirmation required;
- Zalo/cloud online dispatch;
- no Internet fallback copy.

Nếu không có Xcode/iPhone:

```text
Static-verified
Runtime-unverified
```

Không nâng mức claim.

---

# 22. Bước 20 — Release/Google Play guard

Trước AAB:

```bash
rg "READ_CALL_LOG|WRITE_CALL_LOG|PROCESS_OUTGOING_CALLS|SEND_SMS|ACTION_CALL" android
```

Expected: không có permission/action mới thuộc baseline M31 offline fallback.

Kiểm tra manifest vẫn giữ:

```text
RECORD_AUDIO
FOREGROUND_SERVICE
FOREGROUND_SERVICE_MICROPHONE
POST_NOTIFICATIONS
VIBRATE
```

Không tự thêm phone-call foreground service vào baseline.

Rà soát Play Console declaration vì M31 dùng foreground microphone và notification.

---

# 23. Bước 21 — Observability và privacy

Thêm structured logging nhưng không chứa:

```text
phone_e164
Zalo UID
OTP
access token
provider token
raw audio
health profile
```

Allowed diagnostic fields:

```text
eventId hash/opaque ID
contact priority
channel=zalo|voice|sms|local_dialer
status
attempt number
latency bucket
network class
error code sanitized
```

Không log full provider response nếu có PII.

---

# 24. Bước 22 — Rollout strategy

## Stage 0

```text
M31 current behavior unchanged
zalo_enabled=false
phone_fallback_enabled=false
```

## Stage 1 — staging acceptance

```text
phone_fallback_enabled=false by default; temporarily true only during consented QA
zalo_enabled=false
```

Test online, offline, lock screen, reconnect, retry expiry, no verified contact,
and one consented QA contact. Không lấy production làm staging.

## Stage 2 — production phone fallback gradual rollout

```text
phone_fallback_enabled=true
zalo_enabled=false
```

Chỉ bắt đầu sau staging acceptance, Android+iOS acceptance, SQL/RLS verification
và production migration/function checks. Roll out dần; theo dõi lỗi và có thể
đặt cờ về false ngay.

## Stage 3 — Zalo rollout riêng

Chỉ sau khi credential refresh/rotation, OA phone-send permission, ZBS template
approval, rate limits, callback/delivery semantics và real provider smoke đều
được xác nhận trong staging. Khi đó mới review riêng việc bật cờ Zalo production.

Rollback:

```text
zalo_enabled=false
phone_fallback_enabled=false
```

Core M31 monitoring can remain active.

---

# 25. Bước 23 — Docs/checklist/worklog sau implementation

Update:

```text
docs/checklist/checklist_complete_DD.md
docs/checklist/checklist_task_coding.md
```

Create worklog:

```text
docs/worklog/YYYY-MM-DD/NNN-worklog-m31-zalo-phone-fallback.md
```

Worklog phải ghi riêng:

```text
Implementation
Static verification
Android real-device verification
Zalo sandbox verification
Supabase sandbox verification
iOS verification
Blocked/Unverified
```

Không dùng “100% production ready” nếu Zalo/provider/iOS chưa test thật.

Sau worklog:

```powershell
powershell -ExecutionPolicy Bypass -File .codex/tools/update_worklog_learning.ps1
```

Sau đó:

```powershell
powershell -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1
git diff --check
```

---

# 26. Danh sách file dự kiến thay đổi

## Docs

```text
docs/BD/sleep_safety/BD_NanoBio_Sleep_Safety_M31_v1.2.md
docs/DD/sleep_safety_monitoring/README.md
docs/DD/sleep_safety_monitoring/Overall.md
docs/DD/sleep_safety_monitoring/List_Features.md
docs/DD/sleep_safety_monitoring/Function_List.md
docs/DD/sleep_safety_monitoring/Views.md
docs/DD/sleep_safety_monitoring/Import_File.md
docs/DD/sleep_safety_monitoring/diagrams/README.md
docs/checklist/checklist_complete_DD.md
docs/checklist/checklist_task_coding.md
docs/worklog/<date>/<worklog>.md
```

## Flutter/domain/data

```text
lib/app_versions/v1/features/sleep_tracking/domain/entities/safety_contact.dart
lib/app_versions/v1/features/sleep_tracking/domain/entities/<dispatch-model>.dart
lib/app_versions/v1/features/sleep_tracking/domain/repositories/sleep_safety_repository.dart
lib/app_versions/v1/features/sleep_tracking/domain/services/<emergency-dispatch-service>.dart
lib/app_versions/v1/features/sleep_tracking/data/gateways/sleep_safety_connectivity_gateway.dart
lib/app_versions/v1/features/sleep_tracking/data/gateways/sleep_safety_native_gateway.dart
lib/app_versions/v1/features/sleep_tracking/data/models/sleep_safety_models.dart
lib/app_versions/v1/features/sleep_tracking/data/datasources/sleep_safety_cloud_datasource.dart
lib/app_versions/v1/features/sleep_tracking/data/datasources/sleep_safety_local_datasource.dart
lib/app_versions/v1/features/sleep_tracking/data/repositories/sleep_safety_repository_impl.dart
lib/app_versions/v1/features/sleep_tracking/providers/sleep_safety_providers.dart
lib/app_versions/v1/features/sleep_tracking/providers/sleep_safety_controller.dart
lib/app_versions/v1/features/sleep_tracking/presentation/pages/sleep_tracking_page.dart
lib/app_versions/v1/features/sleep_tracking/presentation/pages/sleep_safety_contacts_page.dart
lib/app_versions/v1/features/sleep_tracking/presentation/widgets/sleep_safety_alert_overlay.dart
```

## SQLite

```text
lib/core/storage/localdb/database_version.dart
lib/core/storage/localdb/database_service.dart
lib/core/storage/localdb/tables/sleep_safety_tables.dart
lib/core/storage/localdb/daos/sleep_safety_dao.dart
lib/core/storage/localdb/migrations/migration_vXX.dart
```

## Android

```text
android/app/src/main/kotlin/com/example/nano_app/sleep_safety/SleepSafetyForegroundService.kt
android/app/src/main/kotlin/com/example/nano_app/sleep_safety/SleepSafetyNotificationFactory.kt
android/app/src/main/kotlin/com/example/nano_app/sleep_safety/SleepSafetyChannelHandler.kt
android/app/src/main/kotlin/com/example/nano_app/sleep_safety/SleepSafetyNativeEvent.kt
android/app/src/main/AndroidManifest.xml   # ideally no new restricted permission
```

## iOS

```text
ios/Runner/AppDelegate.swift
```

## Supabase/Edge

```text
docs/supabase/01_build_system.sql
docs/supabase/02_seed_data.sql              # only if fixture needs update
supabase/functions/_shared/sleep_safety_provider.ts
supabase/functions/_shared/<zalo-provider>.ts
supabase/functions/sleep-safety-dispatch/index.ts
supabase/functions/sleep-safety-dispatch/handler.ts
supabase/functions/sleep-safety-provider-webhook/index.ts
```

## Tests

```text
test/app_versions/v1/features/sleep_tracking/**
test/core/storage/localdb/**
test/docs/**
supabase/functions/**/_test*.ts or current Deno test layout
```

Final file list must be determined by `git diff --name-only`; không sửa file ngoài scope nếu không có lý do.

---

# 27. Definition of Done

Task chỉ được coi là hoàn thành khi:

- [ ] BD M31 v1.2 + DD delta đồng bộ source behavior.
- [ ] Zalo nằm sau trusted backend, không có secret trong client.
- [ ] `zalo_enabled` kill switch hoạt động.
- [ ] `phone_fallback_enabled` kill switch hoạt động.
- [ ] online event vẫn giữ current trusted access/event/rate/idempotency checks.
- [ ] Zalo fail không chặn voice cascade.
- [ ] definite offline/network timeout chuyển sang phone fallback.
- [ ] Android offline action dùng `ACTION_DIAL`, không auto `ACTION_CALL`.
- [ ] iOS dùng user-confirmed `tel:`.
- [ ] không thêm Call Log/SMS restricted permissions.
- [ ] phone dialer opened không bị ghi thành answered/accepted.
- [ ] local alarm không bị tắt sai khi cloud/dialer chưa accepted.
- [ ] pending dispatch retry cùng idempotency và hết hạn đúng freshness window.
- [ ] P1 -> P2 -> P3 ordering đúng.
- [ ] no verified contact fail safe.
- [ ] raw audio/PII không lọt sang AI/Zalo logs.
- [ ] Flutter targeted analyze PASS.
- [ ] Flutter focused tests PASS.
- [ ] SQLite migration tests PASS.
- [ ] Supabase/Deno tests PASS.
- [ ] Android debug/release build phù hợp scope PASS.
- [ ] Android real-device online + offline + lock-screen acceptance có evidence.
- [ ] Zalo real sandbox/template delivery có evidence trước khi bật production.
- [ ] iOS được ghi đúng `PASS` hoặc `Runtime-unverified`, không giả lập evidence.
- [ ] checklists/worklog/history được update.
- [ ] `git diff --check` PASS.

---

# 28. Packaging bắt buộc sau khi Codex thực thi

Không gửi patch file.
Không thêm file nhận xét ngoài docs/worklog chuẩn của repo.

Sau implementation, lấy modified và untracked files từ baseline `HEAD`; không
dùng riêng `git diff --name-only` vì lệnh đó bỏ sót file untracked:

```bash
git diff --name-only --diff-filter=ACMRT HEAD
git ls-files --others --exclude-standard
```

Copy chúng vào staging folder giữ nguyên project-relative structure, ví dụ:

```text
NanoBioAI_M31_Zalo_Phone_Fallback/
  lib/...
  android/...
  ios/...
  supabase/...
  docs/...
  test/...
```

Sau đó zip:

```bash
zip -r NanoBioAI_M31_Zalo_Phone_Fallback.zip NanoBioAI_M31_Zalo_Phone_Fallback/
```

ZIP phải chỉ chứa:

- file mới;
- file đã sửa;
- đúng cấu trúc tương đối của project.

Không chứa:

```text
.git/
build/
.dart_tool/
.env
secret files
patch.diff
review.txt
notes ngoài chuẩn dự án
```

---

# 29. Thứ tự thực thi ngắn gọn cho Codex

```text
01. Sync main + read AGENTS/context
02. Audit current M31 source
03. Update BD v1.2 + DD contracts
04. Add domain dispatch/connectivity/contact preference model
05. Extend SQLite outbox + migration
06. Extend canonical Supabase schema/RPC/runtime config
07. Implement Zalo backend adapter behind disabled flag
08. Refactor Edge dispatch: Zalo best-effort + existing voice/SMS cascade
09. Implement Flutter emergency dispatch orchestrator
10. Implement bounded offline detection + outbox retry
11. Implement Android ACTION_DIAL notification fallback
12. Implement iOS user-confirmed tel fallback
13. Update contacts/alert UI
14. Add unit/widget/migration/SQL/Deno/native contract tests
15. Run targeted format/analyze/tests
16. Deploy sandbox schema/functions
17. Run Zalo sandbox verification
18. Run Android real-device online/offline/lock-screen/reconnect matrix
19. Run iOS acceptance if toolchain/device exists
20. Update DD/checklists/worklog/history
21. Run final validation
22. Package only modified/new files preserving structure into ZIP
```

---

## Final execution rule

User đã xác nhận thực thi và cho phép production rollout sau staging/QA. Triển khai
thực tế chỉ chạy sau khi project ref/auth và acceptance gate tương ứng đã được
xác minh. Không bỏ qua research gate Zalo, không tự thêm restricted phone/SMS
permissions và không claim runtime/provider success nếu chưa có evidence thực tế.
