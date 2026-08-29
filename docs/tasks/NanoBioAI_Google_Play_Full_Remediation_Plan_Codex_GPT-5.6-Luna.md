# NANOBIOAI — GOOGLE PLAY FULL REMEDIATION EXECUTION PLAN

> **Target executor:** Codex GPT-5.6 Luna  
> **Repository:** `https://github.com/daovanhung-dev/NanoBioAI.git`  
> **Target branch:** `main`  
> **Planning baseline (audit):** `d5b7e377e973eaac8ae1dab7d99ea971bc921179`  
> **Plan type:** FULL FIX / RELEASE HARDENING / GOOGLE PLAY COMPLIANCE  
> **Status:** `PLAN ONLY — DO NOT CLAIM IMPLEMENTED OR VERIFIED`  
> **Language:** Vietnamese  
> **Primary objective:** Đóng toàn bộ P0/P1/P2 đã phát hiện trong audit Google Play, tạo bằng chứng kỹ thuật + runtime + Play Console đủ để app có thể đi từ `NO-GO` sang `GO` mà không đánh dấu PASS giả.

---

# 0. MỤC TIÊU CUỐI CÙNG

Codex phải đưa NanoBioAI từ trạng thái:

```text
BUILDABLE nhưng còn release blockers
```

sang:

```text
SOURCE PASS
+ ARTIFACT PASS
+ RUNTIME PASS
+ INTERNAL TRACK PASS
+ PLAY CONSOLE DECLARATIONS PASS
= RELEASE GO
```

Không được coi việc sửa source code là bằng chứng đủ để kết luận app sẽ được Google Play duyệt.

Các nhóm lỗi cần đóng:

| ID | Nhóm lỗi | Severity | Trạng thái audit |
|---|---|---:|---|
| GP-001 | Google Play Billing Library 7 → Billing 8+ | P0 | CONFIRMED |
| GP-002 | Health Apps Declaration + health claims/disclaimer | P0 | OPEN |
| GP-003 | Privacy Policy + Data Safety + prominent disclosure/consent | P0 | OPEN |
| GP-004 | Foreground microphone / Sleep Safety policy + runtime | P0 | OPEN |
| GP-005 | Account deletion runtime + outside-app deletion URL | P0 | OPEN |
| GP-006 | Reviewer/App Access test account | P0 | UNVERIFIED |
| GP-007 | AI report source có nhưng deployed backend chưa xác minh | P1 | PARTIAL |
| GP-008 | Supabase/RLS/Edge Functions runtime chưa nghiệm thu | P1 | OPEN |
| GP-009 | Full test suite còn failures + shutdown stream error | P1 | NOT CLEAN |
| GP-010 | Exact alarm permission/runtime/fallback Android 14+ | P2 | REVIEW |

Ngoài 10 mục trên, Codex phải chạy **preflight mismatch scan** để bắt những lỗi release-critical mới phát sinh trong quá trình nâng dependency, đặc biệt Android namespace/package, merged manifest, service class path, signing, product ID và backend contract.

---

# 1. QUY TẮC BẮT BUỘC TRƯỚC KHI CODE

## 1.1. Đọc context theo đúng repository rule

Trước bất kỳ thay đổi nào, Codex PHẢI đọc lần lượt:

1. `AGENTS.md`
2. `.codex/AGENTS.md`
3. `.codex/PROJECT_MAP.md`
4. `.codex/history/LEARNED_SKILLS.md`
5. đúng 01 workflow phù hợp, ưu tiên `.codex/workflows/fix-issues.md`
6. task skill tương ứng trong `.codex/task-skills/` nếu tồn tại
7. `.codex/history/OPEN_RISKS.md`
8. `.codex/history/WORKLOG.md` nếu tồn tại
9. toàn bộ `docs/release/google_play/`
10. các BD/DD/API/DB docs liên quan trực tiếp đến membership, auth, health, AI, sleep safety, notification.

Sau bước này phải ghi nội bộ một **Mode Record**:

```text
MODE: fix-issues / release-hardening
TASK_SKILL: <exact file selected or NONE>
SCOPE: Google Play full remediation
PRIMARY_FLOW: app release -> internal track -> policy declarations -> production readiness
DOCS_TO_UPDATE: docs/release/google_play/* + codex history
```

## 1.2. Không được dùng source tĩnh để giả runtime PASS

Dùng state model bắt buộc:

```text
PLANNED
IMPLEMENTED
SOURCE_VERIFIED
ARTIFACT_VERIFIED
RUNTIME_VERIFIED
CONSOLE_VERIFIED
```

Nếu thiếu quyền/credential/device/Play Console, dùng:

```text
BLOCKED_EXTERNAL
```

Tuyệt đối không đổi `OPEN` → `PASS` chỉ vì nhìn code thấy đúng.

## 1.3. Không được phá các remediation đã PASS

Phải giữ nguyên các nguyên tắc đã được audit đánh giá tốt:

- `targetSdk = 36`, `compileSdk = 36`.
- Không khôi phục broad media/storage permissions.
- Không đưa Gemini/API key trở lại client.
- Consumer membership trên bản Play không quay lại VietQR/manual transfer flow.
- Entitlement không được tin từ client; backend là nguồn quyết định cuối.
- Không reset/destructive production Supabase.
- Không sửa `supabase/_legacy` làm source-of-truth.
- Không ghi secrets/keystore/password/reviewer password vào Git.
- Không dùng blanket test skip để “làm xanh” suite.
- Không hard-code Play Console state trong app.

---

# 2. PHASE 0 — BASELINE, INVENTORY, REACHABILITY MAP

> **Không code trước khi phase này hoàn tất.**

## 2.1. Chốt baseline Git

Chạy:

```bash
git status --short
git rev-parse HEAD
git branch --show-current
git log -1 --oneline
```

Điều kiện:

- Nếu working tree đang có thay đổi của người dùng: KHÔNG được ghi đè.
- Ghi lại baseline SHA thực tế; nếu khác SHA trong plan thì dùng SHA mới làm nguồn chuẩn.

## 2.2. Chốt toolchain

Chạy và lưu output:

```bash
flutter --version
dart --version
java -version
./gradlew -version
```

Nếu có Supabase CLI:

```bash
supabase --version
```

## 2.3. Xác định active app version

NanoBio có nhiều version folder (`v1/v2/v3`). Codex phải truy vết từ:

- `lib/main.dart`
- `lib/app/bio_ai_app.dart`
- `lib/routes/`
- router/provider hiện hành
- route registrations
- dependency providers

Kết quả bắt buộc tạo một bảng nội bộ:

| Feature | Active implementation | Reachable route | Entry point |
|---|---|---|---|
| Paywall/Membership | exact path | route | page/controller |
| AI Chat | exact path | route | page/controller |
| Sleep Safety | exact path | route | page/controller |
| Account Settings/Delete | exact path | route | page/controller |
| Privacy | exact path | route | page |
| Health profile | exact path | route | page |
| Notifications | exact path | service | scheduler |

**Không sửa code ở version không reachable chỉ vì file tên giống nhau.**

## 2.4. Xác minh Android namespace/package/service

Đọc:

- `android/app/build.gradle.kts`
- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/kotlin/**/MainActivity.kt`
- toàn bộ `android/app/src/main/kotlin/**/sleep_safety/**`

Bắt buộc so sánh:

```text
namespace
applicationId
MainActivity package
SleepSafetyForegroundService package
Manifest android:name
MethodChannel names
```

Manifest audit trước đó trỏ service tới:

```text
com.nanobioai.app.sleep_safety.SleepSafetyForegroundService
```

Codex phải xác minh class thực tế có đúng package này không. Nếu lệch, đây là release-critical crash và phải sửa trong GP-004.

## 2.5. Chụp dependency baseline

Chạy:

```bash
flutter pub get
flutter pub deps > /tmp/nanobio-pub-deps-before.txt
```

Xác nhận các version hiện tại:

```text
in_app_purchase
in_app_purchase_android
in_app_purchase_platform_interface
```

Sau đó từ Android dependency graph tìm BillingClient thực tế, không chỉ nhìn pubspec:

```bash
cd android
./gradlew app:dependencies --configuration releaseRuntimeClasspath
```

Tìm:

```text
com.android.billingclient:billing
com.android.billingclient:billing-ktx
```

## 2.6. Baseline tests

Chạy tối thiểu:

```bash
flutter analyze
flutter test
```

Lưu:

- tổng pass/fail/skip;
- danh sách failing test;
- stack trace shutdown stream error;
- thời gian;
- environment-dependent failures;
- test crash/hang.

Không sửa test lúc phase 0.

## 2.7. Baseline release artifact

Nếu signing material có sẵn local:

```bash
flutter build appbundle --release
```

Ghi:

- AAB path;
- size;
- package;
- versionName/versionCode;
- SHA-256;
- signing cert metadata.

Artifact này chỉ là baseline và sẽ bị vô hiệu sau khi code/dependency thay đổi.

---

# 3. DEPENDENCY GRAPH — THỨ TỰ TRIỂN KHAI BẮT BUỘC

Không triển khai ngẫu nhiên. Dùng thứ tự:

```text
PHASE 0 Baseline
        ↓
GP-001 Billing 8+
        ↓
GP-008 Backend/Supabase trust + runtime contracts
        ↓
GP-007 AI report backend/runtime
        ↓
GP-005 Account deletion full lifecycle
        ↓
GP-003 Privacy/Data flow/consent
        ↓
GP-002 Health claims + Health Apps declaration package
        ↓
GP-004 Foreground microphone/Sleep Safety
        ↓
GP-010 Exact alarm
        ↓
GP-009 Full regression cleanup
        ↓
Final AAB
        ↓
GP-006 Reviewer/App Access + Internal Track
        ↓
Play Console declarations
        ↓
RELEASE GO/NO-GO
```

Lý do:

- Privacy/Data Safety phải mô tả **behavior sau cùng**, không mô tả code cũ.
- Health declaration phải phản ánh feature thực tế sau remediation.
- Account deletion cần schema/RLS/backend đúng trước khi test.
- Internal track phải dùng **AAB cuối cùng**, không build trung gian.

---

# 4. GP-001 — UPGRADE GOOGLE PLAY BILLING LIBRARY 7 → 8+

## 4.1. Mục tiêu

Loại bỏ PBL 7 khỏi release runtime dependency và bảo toàn toàn bộ purchase flow server-authoritative.

## 4.2. File phải đọc trước

Tối thiểu:

- `pubspec.yaml`
- `pubspec.lock`
- `lib/app_versions/v2/features/paywall/domain/entities/store_membership_product.dart`
- `lib/app_versions/v2/features/paywall/presentation/controllers/membership_payment_controller.dart`
- `lib/app_versions/v2/features/paywall/presentation/pages/membership_payment_page.dart`
- `lib/app_versions/v2/features/paywall/presentation/widgets/membership_payment_summary_card.dart`
- `lib/app_versions/v2/features/paywall/presentation/widgets/membership_store_plan_card.dart`
- `lib/app_versions/v2/repositories/membership_billing_repository.dart`
- `lib/app_versions/v2/repositories/membership_repository.dart`
- `lib/app_versions/v2/repositories/usage_repository.dart`
- `lib/app_versions/v2/domain/membership/membership_access_evaluator.dart`
- `lib/app_versions/v2/domain/membership/membership_access_state.dart`
- `supabase/functions/google-play-verify-purchase/index.ts`
- canonical membership/purchase SQL/RPC trong `supabase/01_build_system.sql`
- các file seed/product mapping liên quan.

Tests phải đọc:

- `test/app_versions/v2/features/paywall/presentation/controllers/membership_payment_controller_test.dart`
- `test/app_versions/v2/features/paywall/presentation/pages/membership_payment_page_purchase_test.dart`
- `test/app_versions/v2/repositories/membership_billing_repository_test.dart`
- `test/app_versions/v2/repositories/membership_repository_test.dart`
- toàn bộ test domain membership/quota/purchase liên quan.

## 4.3. Dependency upgrade

Codex không được chỉ sửa `pubspec.lock` thủ công.

Quy trình:

1. Xác định bản `in_app_purchase` mới phù hợp Flutter/Dart hiện tại.
2. Chọn bản kéo `in_app_purchase_android` sử dụng Billing 8+.
3. Sửa `pubspec.yaml`.
4. `flutter pub get`.
5. Xem changelog/API break.
6. Cập nhật code compile errors.
7. Chạy Gradle dependency graph để xác minh BillingClient thực tế.

Acceptance:

```text
releaseRuntimeClasspath không còn Billing 7.x
BillingClient >= 8.x
```

## 4.4. Purchase state machine phải được giữ/siết chặt

Bắt buộc xử lý rõ các state:

```text
IDLE
QUERYING_PRODUCTS
READY
PURCHASE_STARTED
PENDING
VERIFYING_SERVER
VERIFIED
FINALIZING_ENTITLEMENT
SUCCESS
CANCELLED
ERROR
RESTORING
```

Không được:

- cấp Plus ngay khi client nhận `purchased`;
- cấp entitlement từ local flag;
- dùng purchase token raw làm primary key public;
- finalize hai lần làm tăng quota/entitlement;
- coi `pending` là success.

## 4.5. Product mapping

Xác minh 4 product/subscription hiện dùng trong Play Console/source.

Với mỗi product phải có:

- canonical product ID;
- membership tier;
- billing period/base plan/offer nếu có;
- entitlement duration logic;
- backend allowlist;
- UI label không hard-code lệch Play price.

Giá/currency hiển thị phải ưu tiên metadata trả về từ Play, không tự dựng giá nếu không cần.

## 4.6. Backend verification contract

`google-play-verify-purchase` phải kiểm tra tối thiểu:

- caller authenticated;
- packageName đúng `com.nanobioai.app`;
- productId thuộc allowlist;
- token hợp lệ;
- purchase state đúng;
- subscription state đúng;
- expiry/renewal info hợp lệ;
- không tin `userId/tier/duration` do client gửi nếu có thể suy ra server-side;
- idempotency theo trusted purchase identity/token hash/order key;
- replay không cấp lại entitlement;
- service-role/RPC finalize chạy atomic.

Nếu Google API/service-account credentials thiếu ở local, để `BLOCKED_EXTERNAL`, không mock thành PASS production.

## 4.7. Test bắt buộc

Unit/widget:

- product query success;
- product unavailable;
- duplicate product IDs;
- pending;
- user cancel;
- billing error;
- restored purchase;
- server verification 401/403/404/409/429/500;
- backend timeout;
- retry after verification failure;
- replay token;
- app restart while pending;
- purchase stream emits duplicate event;
- `completePurchase` ordering;
- UI double-tap purchase prevention.

Backend:

- unauthenticated reject;
- wrong package reject;
- unknown product reject;
- invalid token reject;
- consumed/revoked/expired reject;
- replay returns idempotent outcome;
- one token cannot grant multiple users;
- concurrent finalize only grants once.

Internal Track:

- real tester account;
- all actual products/base plans;
- purchase;
- cancellation;
- restore;
- app reinstall;
- account logout/login;
- entitlement visible after trusted verification only.

## 4.8. Definition of Done GP-001

Chỉ PASS khi:

- [ ] PBL 8+ trong release dependency graph.
- [ ] App compile/build release.
- [ ] targeted billing tests pass.
- [ ] backend verification tests pass.
- [ ] real internal-track purchase pass.
- [ ] replay/idempotency pass.
- [ ] release docs cập nhật bằng evidence thật.

---

# 5. GP-008 — SUPABASE/RLS/EDGE FUNCTIONS RUNTIME HARDENING

> Thực hiện ngay sau Billing vì các flow policy-critical phụ thuộc backend.

## 5.1. Source of truth

Ưu tiên canonical:

- `supabase/01_build_system.sql`
- `supabase/02_seed_data.sql`
- current migrations/functions nếu AGENTS/PROJECT_MAP chỉ định
- `supabase/functions/**`

Không coi `docs/supabase/**` hoặc `_legacy` là runtime source nếu repository rules không nói vậy.

## 5.2. Local/sandbox rebuild

Nếu có sandbox DB:

1. backup nếu cần;
2. reset **sandbox/local only**;
3. build schema canonical từ đầu;
4. seed;
5. deploy functions vào sandbox;
6. set sandbox secrets;
7. chạy smoke.

**Tuyệt đối không reset production.**

## 5.3. RLS matrix

Tạo test matrix ít nhất:

| Resource domain | Anonymous | User A own | User A reads B | User A writes B | Service role |
|---|---:|---:|---:|---:|---:|
| profile | expected | allow | deny | deny | controlled |
| health/body metrics | expected | allow | deny | deny | controlled |
| meals | expected | allow | deny | deny | controlled |
| schedules | expected | allow | deny | deny | controlled |
| sleep | expected | allow | deny | deny | controlled |
| AI reports | insert own only | allow intended | deny | deny | moderation only |
| purchase ledger | deny | minimal/read if intended | deny | deny | allow |
| membership | scoped | own | deny | deny | allow |
| family/emergency | feature-specific | scoped | deny | deny | allow |

Bắt buộc dùng **hai session/JWT khác nhau** để chứng minh isolation.

## 5.4. Security assertions

- Không cho client tự gửi `owner_user_id` để ghi dữ liệu cho user khác.
- RPC nhận user identity từ `auth.uid()` khi có thể.
- Service role chỉ dùng server-side.
- Không log secrets/purchase token/raw health payload không cần thiết.
- Mọi function privileged phải validate JWT và input schema.
- Rate-limit/report endpoints phải có abuse control hợp lý.

## 5.5. Membership/quota atomicity

Test race/concurrency:

- 2 request cùng lúc;
- replay purchase;
- quota decrement/increment;
- membership expiry;
- FamilyPlus scope;
- rollback khi RPC fail giữa chừng.

## 5.6. Definition of Done GP-008

- [ ] canonical rebuild chạy được sandbox.
- [ ] RLS User A/User B/anon pass.
- [ ] privileged functions không trust client ownership.
- [ ] purchase replay/atomicity pass.
- [ ] deletion prerequisites pass.
- [ ] deployed sandbox function smoke pass.
- [ ] production chưa test thì ghi đúng `BLOCKED_EXTERNAL`, không fake PASS.

---

# 6. GP-007 — AI REPORTING: SOURCE → DEPLOYED RUNTIME PASS

## 6.1. Mục tiêu

Đảm bảo người dùng có thể report/flag nội dung AI ngay trong app và request thực sự tới backend an toàn.

## 6.2. File discovery

Tìm exact active files bằng:

```bash
git grep -n "report-ai-content\|ai_content_reports\|Report" lib supabase test
```

Đọc:

- AI message widget/bubble;
- report sheet/dialog;
- report controller/provider;
- report data source/repository/entity;
- `supabase/functions/report-ai-content/index.ts`;
- canonical SQL table/RLS của `ai_content_reports`;
- tests.

## 6.3. UX bắt buộc

Trên mỗi assistant-generated message cần có đường report đủ dễ truy cập.

Flow:

```text
Assistant message
→ Report/Flag
→ reason/category
→ optional note (bounded)
→ Confirm
→ pending state
→ success/failure feedback
```

Không bắt user:

- mở website ngoài;
- gửi email thủ công;
- copy message sang trang khác.

## 6.4. Input/security

Backend phải:

- validate reason enum;
- giới hạn note length;
- giới hạn snapshot length;
- sanitize/normalize;
- không nhận arbitrary moderation state từ client;
- bind report với auth user/installation theo contract;
- rate limit reasonable;
- tránh log nguyên health/AI content nếu không cần;
- return generic safe errors.

## 6.5. Guest behavior

Nếu app cho guest chat:

- xác định policy report cho guest;
- nếu cho report: installation ID/anti-abuse phải không biến thành tracking vượt khai báo;
- nếu bắt login: UI phải giải thích rõ và policy phải phù hợp actual behavior.

## 6.6. Runtime tests

- valid report;
- duplicate report;
- offline;
- timeout;
- 401 expired session;
- 429;
- 500;
- retry;
- app restart;
- backend row created;
- RLS prevents reading other users' reports.

## 6.7. Definition of Done GP-007

- [ ] report action reachable từ assistant message.
- [ ] source tests pass.
- [ ] deployed sandbox function pass.
- [ ] report persisted with correct ownership/privacy.
- [ ] failure UX không crash.
- [ ] Data Safety mapping cập nhật đúng dữ liệu report thực tế.

---

# 7. GP-005 — ACCOUNT DELETION FULL LIFECYCLE

## 7.1. Mục tiêu

Đạt đồng thời:

1. in-app deletion;
2. backend auth deletion;
3. owned-data cleanup/anonymization;
4. storage cleanup;
5. local device cleanup;
6. public outside-app deletion resource;
7. Play Console declaration.

## 7.2. File discovery

Tìm:

```bash
git grep -n "delete-account\|deleteAccount\|Delete account\|Xóa tài khoản" lib supabase test docs
```

Đọc:

- settings/profile/account page active;
- auth controller/repository;
- local database/cache/secure storage/biometric services;
- `supabase/functions/delete-account/index.ts`;
- `supabase/01_build_system.sql` delete trigger/FKs;
- `docs/release/google_play/ACCOUNT_DELETION.md`;
- tests.

## 7.3. In-app UX

Flow đề xuất:

```text
Settings
→ Account
→ Xóa tài khoản
→ explain irreversible effects
→ optional re-auth if architecture requires
→ explicit destructive confirmation
→ loading
→ backend delete
→ local cleanup
→ sign out
→ return to unauthenticated entry
```

Không dùng dark pattern giữ user lại.

## 7.4. Server deletion transaction strategy

Phải xác định rõ thứ tự để tránh “auth user mất nhưng data còn orphaned” hoặc “data xóa nhưng auth còn”.

Khuyến nghị thiết kế idempotent:

1. authenticate caller;
2. validate `{confirm:true}`;
3. capture subject ID server-side;
4. delete/anonymize DB records theo canonical trigger/policies;
5. remove storage objects thuộc user;
6. remove auth user via Admin API;
7. return success;
8. repeated call should be safe/not leak whether another account exists.

Nếu current architecture bắt buộc auth delete trước trigger DB, phải chứng minh trigger/FK behavior vẫn chạy đúng.

## 7.5. Retention matrix

Phải chốt từng domain:

- profile;
- health metrics;
- meals;
- schedule;
- sleep;
- notifications;
- membership;
- quota;
- Google Play purchase ledger;
- AI reports;
- family/emergency;
- referral/Sale;
- audit/security;
- Storage objects.

Với dữ liệu cần giữ cho fraud/financial/audit:

- unlink `user_id` khi policy cho phép;
- xóa free-text/account identifiers không cần thiết;
- ghi retention reason;
- không tự bịa retention period: đánh `LEGAL_DECISION_REQUIRED` nếu product/legal chưa chốt.

## 7.6. Local cleanup

Sau deletion phải clear:

- Supabase session/token;
- local SQLite user data;
- preferences;
- cached AI/health data;
- biometric unlock state;
- cached membership entitlement;
- local notification schedules thuộc account;
- locally stored images/proofs nếu account-scoped.

Không để user đã xóa mở app rồi thấy data cũ offline.

## 7.7. Public deletion URL

Đây là phần **không thể hoàn tất chỉ bằng Flutter code**.

Codex phải chuẩn bị nội dung/spec cho web resource và nếu repo có web/static hosting phù hợp thì triển khai vào đúng nơi. Nếu không có hosting/credential, ghi `BLOCKED_EXTERNAL`.

Web resource phải:

- public;
- HTTPS;
- hoạt động không cần cài app;
- mô tả cách yêu cầu delete;
- định danh app/developer rõ;
- không phải file PDF thay cho page;
- link được từ privacy page nếu phù hợp.

**Không commit reviewer password hoặc account data lên page.**

## 7.8. E2E verification

Test bằng account sandbox có data ở mọi domain:

1. snapshot row counts/storage objects trước delete;
2. delete từ app;
3. auth lookup after delete;
4. DB query toàn bộ FK/domain;
5. storage list;
6. second session thử đọc dữ liệu user đã xóa;
7. reinstall/login attempt;
8. repeated delete call behavior.

## 7.9. Definition of Done GP-005

- [ ] in-app delete reachable.
- [ ] auth user deletion pass sandbox.
- [ ] DB cascade/anonymization pass.
- [ ] storage cleanup pass.
- [ ] local cache/session cleanup pass.
- [ ] two-session post-delete isolation pass.
- [ ] public deletion URL live.
- [ ] Play Console Account deletion URL entered.

---

# 8. GP-003 — PRIVACY POLICY, DATA SAFETY, DISCLOSURE & CONSENT

## 8.1. Mục tiêu

Tạo một **runtime-backed data inventory** rồi đồng bộ 4 lớp:

```text
Actual code/runtime
↕
In-app disclosure/consent
↕
Privacy Policy
↕
Google Play Data Safety
```

Không viết declaration theo mong muốn; chỉ khai behavior thực tế.

## 8.2. Data-flow inventory bắt buộc

Codex phải scan source theo domain và tạo inventory nội bộ:

| Data type | Source | Local storage | Backend table/function | Third party | Purpose | Optional/required | Retention | Delete behavior |
|---|---|---|---|---|---|---|---|---|
| account/profile | | | | | | | | |
| health/body | | | | | | | | |
| meals/exercise/schedule | | | | | | | | |
| AI prompt/response | | | | | | | | |
| AI report | | | | | | | | |
| camera/gallery | | | | | | | | |
| microphone/audio/derived signal | | | | | | | | |
| installation/device identifiers | | | | | | | | |
| diagnostics/logs | | | | | | | | |
| purchase/token/hash | | | | | | | | |
| family/emergency contacts | | | | | | | | |
| referral/Sale | | | | | | | | |

## 8.3. Prominent disclosure

Với sensitive/background behavior, disclosure phải xuất hiện **trước permission/collection** và nói bằng ngôn ngữ dễ hiểu:

- dữ liệu gì;
- dùng để làm gì;
- có gửi server/provider không;
- có hoạt động khi app background không;
- cách tắt/xóa.

Không được chỉ có một checkbox “Tôi đồng ý Privacy Policy” chung chung nếu behavior đặc biệt cần disclosure riêng.

## 8.4. Consent

Consent phải:

- affirmative action;
- không pre-checked;
- không gộp vào unrelated action;
- permission request xảy ra sau explanation hợp lý;
- denial không làm app crash;
- user có đường revoke/disable feature.

Đặc biệt với Sleep Safety microphone, xem GP-004.

## 8.5. Privacy Policy

Privacy Policy release phải:

- URL public HTTPS;
- accessible không geo/login-block;
- identity app/developer rõ;
- nói đúng collection/use/sharing;
- health data;
- AI provider/backend processing;
- microphone behavior;
- camera/image behavior;
- Google Play purchase verification;
- retention/deletion;
- account deletion contact/resource;
- security practices ở mức không gây claim sai;
- contact method thực.

Nếu repo không có website hosting, Codex chỉ tạo deployment-ready source/spec và ghi external blocker; không ghi PASS.

## 8.6. Logs/telemetry review

Search:

```bash
git grep -n "print(\|debugPrint\|logger\|log(" lib supabase
```

Kiểm tra không log:

- JWT;
- API secret;
- purchase token raw;
- full health payload;
- private AI prompt/response;
- password/OTP;
- family/emergency contact unnecessarily.

Thêm redaction utility nếu cần.

## 8.7. Data Safety form package

Update `docs/release/google_play/DATA_SAFETY_MAPPING.md` thành mapping cuối cùng nhưng vẫn tách:

```text
SOURCE_READY
RUNTIME_VERIFIED
CONSOLE_SUBMITTED
```

Không tự ghi `CONSOLE_SUBMITTED` nếu chưa thực hiện Play Console.

## 8.8. Definition of Done GP-003

- [ ] actual data inventory complete.
- [ ] disclosures precede sensitive collection/permission.
- [ ] denial/revoke flow safe.
- [ ] logs redacted.
- [ ] privacy page live + in-app link reachable.
- [ ] Data Safety answers match runtime.
- [ ] Play Console submitted/verified.

---

# 9. GP-002 — HEALTH APPS DECLARATION + HEALTH CLAIMS HARDENING

## 9.1. Mục tiêu

Giữ NanoBio ở phạm vi **wellness/self-tracking** trừ khi có bằng chứng/certification hợp lệ cho claim y tế khác.

## 9.2. Inventory toàn bộ health claims

Search toàn repo, localizations, docs/store assets/prompt templates:

```bash
git grep -ni "diagnos\|chẩn đoán\|điều trị\|chữa\|phát hiện bệnh\|cấp cứu\|sleep apnea\|ngưng thở\|seizure\|co giật\|cardiac\|tim mạch\|medical device\|bệnh" lib assets docs supabase
```

Đặc biệt đọc:

- onboarding health copy;
- dashboard/health insights;
- AI system prompts/safety prompts;
- sleep safety copy;
- notification emergency copy;
- paywall marketing copy;
- screenshots/store listing drafts;
- `docs/release/google_play/HEALTH_APPS_DECLARATION.md`;
- `docs/release/google_play/STORE_LISTING_CLAIMS_REVIEW.md`.

## 9.3. Claim classes

Phân loại mỗi claim:

```text
SAFE_WELLNESS
NEEDS_DISCLAIMER
HIGH_RISK_MEDICAL_CLAIM
REMOVE_OR_REWRITE
LEGAL_REVIEW_REQUIRED
```

## 9.4. Những claim không được để mơ hồ

Không quảng cáo Sleep Safety/AI như:

- chẩn đoán bệnh;
- phát hiện chắc chắn sleep apnea;
- phát hiện seizure/cardiac event;
- thay bác sĩ;
- thay dịch vụ cấp cứu;
- điều trị/chữa bệnh;
- bảo đảm kết quả sức khỏe.

Nếu feature chỉ phát hiện pattern âm thanh/độ lớn, copy phải nói đúng điều đó.

## 9.5. Disclaimer placement

Có ít nhất:

- store description disclaimer;
- health/AI context disclaimer;
- sleep safety disclaimer;
- urgent symptom path.

Không spam disclaimer mọi màn; đặt tại nơi người dùng có khả năng hiểu sai medical meaning.

## 9.6. Emergency behavior

AI/health guidance khi gặp dấu hiệu nghiêm trọng phải:

- không trì hoãn cấp cứu;
- khuyến nghị liên hệ dịch vụ cấp cứu/cơ sở y tế phù hợp;
- tránh chắc chắn chẩn đoán;
- không tạo false reassurance.

Nếu app có emergency contact workflow, copy phải phân biệt rõ **support feature** và **emergency service**.

## 9.7. Health Apps Declaration

Từ runtime inventory, chuẩn bị category chính xác trong:

`docs/release/google_play/HEALTH_APPS_DECLARATION.md`

Mỗi category cần:

- shipped capability;
- code/file evidence;
- store wording;
- whether data collected;
- declaration checkbox mapping;
- console status.

## 9.8. Definition of Done GP-002

- [ ] no unsupported medical claims in reachable release UI/store docs.
- [ ] disclaimers correctly placed.
- [ ] AI prompts align with public claims.
- [ ] Health Apps declaration matches runtime.
- [ ] store listing text reviewed against app behavior.
- [ ] Play Console declaration submitted.

---

# 10. GP-004 — FOREGROUND MICROPHONE / SLEEP SAFETY

## 10.1. Mục tiêu

Đảm bảo Sleep Safety vừa chạy đúng Android 14/15/16 vừa đáp ứng foreground service/microphone disclosure.

## 10.2. Android native preflight

Đọc exact:

- `AndroidManifest.xml`;
- `MainActivity.kt`;
- `SleepSafetyForegroundService.kt`;
- notification channel implementation;
- MethodChannel bridge;
- Flutter controller/service gọi native.

Xác minh package/class name tuyệt đối khớp manifest.

Nếu class package lệch `com.nanobioai.app.sleep_safety...`, sửa package/import/path hoặc manifest theo canonical namespace.

## 10.3. Permission model

Flow bắt buộc:

```text
User opens Sleep Safety
→ sees purpose/disclosure
→ actively enables feature
→ request RECORD_AUDIO
→ if granted: start foreground service
→ visible ongoing notification
→ monitor
→ user stops
→ release recorder/mic/service
```

Không:

- tự bật microphone từ boot receiver;
- start invisible background recording;
- request permission lúc app launch không liên quan;
- keep mic after user disables feature.

## 10.4. Foreground service lifecycle

Test/code review:

- `startForegroundService()` timing;
- `startForeground()` called within allowed window;
- correct notification channel;
- notification not dismissible in a way leaving mic active silently;
- `onDestroy` releases recorder/resources;
- stop action works;
- app task removed behavior defined;
- permission revoked mid-session;
- mic conflict with voice chat/call;
- low-memory/process death;
- restart behavior not auto-recording unless compliant/user-driven.

## 10.5. Audio data contract

Phải xác minh bằng source/runtime:

- raw audio có được lưu local không;
- raw audio có upload không;
- chỉ metadata/event signal hay waveform/features được lưu;
- retention duration;
- deletion behavior.

Data Safety/Privacy phải khớp chính xác.

Nếu raw audio không cần, ưu tiên không lưu/upload.

## 10.6. Android device matrix

Test ít nhất:

| Case | Android 14 | Android 15 | Android 16/API36 |
|---|---|---|---|
| fresh install | | | |
| permission allow | | | |
| permission deny | | | |
| deny permanently | | | |
| start/stop | | | |
| screen off | | | |
| app background | | | |
| notification visible | | | |
| revoke mid-session | | | |
| app force stop/reopen | | | |

Nếu thiếu device version, ghi `BLOCKED_EXTERNAL` cho version đó.

## 10.7. Play Console FGS declaration package

Update `FOREGROUND_SERVICE_DECLARATION.md` với:

- exact foreground service type;
- user benefit;
- why task cannot simply stop immediately;
- user-initiated path;
- notification behavior;
- disclosure path;
- demo video steps;
- artifact/version tested.

Quay video từ **release/internal-track build**, không video mock/debug khác behavior.

## 10.8. Definition of Done GP-004

- [ ] native package/service resolution correct.
- [ ] user-start only.
- [ ] disclosure before permission.
- [ ] permission denial safe.
- [ ] FGS notification visible.
- [ ] mic/resource release verified.
- [ ] Android 14+ runtime tested.
- [ ] Data Safety/Privacy updated.
- [ ] FGS Play Console declaration submitted with video.

---

# 11. GP-010 — EXACT ALARM PERMISSION / FALLBACK

## 11.1. Mục tiêu

Không để fresh install Android 14+ mất reminder hoặc crash vì `SCHEDULE_EXACT_ALARM` không được grant.

## 11.2. Discovery

Search:

```bash
git grep -n "SCHEDULE_EXACT_ALARM\|exactAllowWhileIdle\|exact\|canScheduleExact" android lib test
```

Map mọi scheduler của:

- meal reminders;
- schedule tasks;
- medication/health reminders nếu có;
- sleep reminder;
- notification reschedule after reboot.

## 11.3. Quyết định product-level

Với từng loại reminder, phân loại:

```text
EXACT_REQUIRED
INEXACT_ACCEPTABLE
```

Nếu app không thực sự cần exact timing cho core functionality, ưu tiên:

- bỏ exact scheduling;
- dùng inexact/approximate scheduling;
- cân nhắc xóa permission nếu không còn cần.

Nếu exact thực sự cần:

- check capability trước schedule;
- contextual user explanation;
- hướng đến system settings khi cần;
- fallback nếu user từ chối;
- không loop nagging.

## 11.4. Runtime cases

- fresh install permission absent;
- permission granted;
- permission revoked;
- device reboot;
- app update;
- timezone change;
- DST/time change nếu relevant;
- duplicate schedule prevention.

## 11.5. Definition of Done GP-010

- [ ] no unguarded exact scheduling call.
- [ ] denial has working fallback.
- [ ] no crash on Android 14/15/16 fresh install.
- [ ] manifest only keeps permission if actually required.

---

# 12. GP-009 — FULL TEST SUITE TRIAGE & RELEASE REGRESSION CLEANUP

## 12.1. Mục tiêu

Không chấp nhận tình trạng “976 pass nhưng 238 fail” mà không biết 238 fail là gì.

## 12.2. Tạo failure inventory

Chạy:

```bash
flutter test --reporter expanded
```

Mỗi failing test gắn một classification:

```text
A = REAL_RELEASE_REGRESSION
B = OUTDATED_TEST
C = ENVIRONMENT_DEPENDENT
D = MISSING_FIXTURE/MOCK
E = PLATFORM_ONLY/UNAVAILABLE_ENV
F = OBSOLETE/DEAD_FEATURE
```

Không dùng classification để lảng tránh; phải có evidence.

## 12.3. Priority order

Sửa trước failures chạm vào:

1. app startup/router;
2. auth/account deletion;
3. membership/paywall/billing;
4. Supabase/RLS contract;
5. AI/report;
6. Sleep Safety/microphone;
7. notification/exact alarm;
8. health data flows;
9. other reachable production features.

## 12.4. Shutdown stream error

Phải lấy exact stack trace, xác định:

- provider disposed too late/early;
- stream controller add after close;
- subscription leak;
- async callback after test/app teardown;
- background timer not cancelled;
- purchase stream lifecycle issue;
- voice/sleep stream lifecycle issue.

Không suppress global Flutter error để hide bug.

## 12.5. Test hygiene

Cho phép sửa test khi test sai/outdated nhưng phải chứng minh behavior canonical.

Không:

- `skip: true` hàng loạt;
- comment assert;
- catch-all exception trong test để pass;
- bỏ test release-critical.

## 12.6. Validation ladder

Sau mỗi work package:

```text
targeted tests
→ related feature tests
→ flutter analyze
→ full flutter test
→ release build
```

## 12.7. Release gate

Mục tiêu tốt nhất:

```text
flutter analyze: exit 0 hoặc chỉ warning đã triage/accepted theo repo rule
flutter test: exit 0
```

Nếu còn environment-only failures không thể chạy local, phải có:

- exact test list;
- exact missing dependency/device;
- reproduce command;
- why not release regression;
- alternate evidence.

Không được còn **untriaged** failure.

---

# 13. GP-006 — REVIEWER / APP ACCESS / TEST ACCOUNT

## 13.1. Mục tiêu

Reviewer Google Play có thể truy cập các feature cần review mà không bị chặn bởi OTP, biometric, paywall hay geo restriction.

## 13.2. Không lưu credential trong Git

Plan/code có thể mô tả quy trình, nhưng:

- password;
- OTP bypass secrets;
- production service keys;

không được commit.

## 13.3. Reviewer account requirements

Chuẩn bị account riêng:

- stable email/user;
- password reusable;
- không yêu cầu OTP mà reviewer không thể nhận;
- không bắt biometric;
- không geo/IP restriction;
- không hết hạn ngay;
- đủ data mẫu để reviewer xem UI;
- nếu feature paid cần instruction hợp lệ để reviewer truy cập.

## 13.4. Reviewer dry-run

Một người không tham gia development phải thực hiện từ fresh install:

```text
Open app
→ follow Play Console instructions only
→ login
→ open core health features
→ AI chat
→ AI report
→ Sleep Safety
→ paywall/membership
→ account deletion entry
```

Nếu họ cần hỏi developer mới biết cách vào thì App Access instructions chưa đủ.

## 13.5. Play Console App Access

Cập nhật:

- login instructions;
- credential;
- special steps;
- paid/gated access info;
- language/region assumptions nếu có.

Đánh `CONSOLE_VERIFIED` chỉ khi đã lưu trên Play Console và dry-run thành công.

---

# 14. FINAL RELEASE ARTIFACT — AAB MỚI SAU TOÀN BỘ FIX

## 14.1. Versioning

Trước build cuối:

- kiểm tra `versionName`;
- tăng `versionCode` so với artifact đã upload trước đó;
- không reuse versionCode đã tồn tại trên Play.

## 14.2. Clean build

Khuyến nghị:

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release
```

## 14.3. Artifact inspection

Xác minh:

- package = `com.nanobioai.app`;
- targetSdk = 36;
- compileSdk = 36;
- minSdk expected;
- release signing expected;
- Billing 8+;
- no broad storage/media permission regression;
- foreground service type microphone only as intended;
- exact alarm permission only if still required;
- no Gemini/provider secret/API key embedded;
- no debug endpoint;
- no localhost/private dev URL accidentally shipped;
- 16 KB native ELF alignment still acceptable.

## 14.4. Secret scan

Scan release source/artifact for:

- `AIza`/Gemini key patterns;
- Supabase service-role key;
- private service account JSON;
- keystore password;
- reviewer password;
- purchase token fixture accidentally real;
- internal dev host.

## 14.5. Hash

Tạo SHA-256 của AAB cuối và ghi vào release evidence.

Từ thời điểm đó, mọi runtime/Internal Track evidence phải gắn với **đúng SHA/versionCode này**.

Nếu code thay đổi sau test, evidence cũ không còn đủ.

---

# 15. INTERNAL TESTING / PRE-LAUNCH ACCEPTANCE

## 15.1. Upload exact final AAB

Upload AAB cuối lên Internal Testing.

Không test APK debug rồi coi là bằng chứng cho Play build.

## 15.2. Fresh-install E2E checklist

Test ít nhất:

```text
Install from Play Internal Track
Launch
Register/login
Onboarding
Health profile/body metrics
Meals
Schedule
Notifications
Camera/image picker
AI chat
AI report
Sleep Safety start/stop
Microphone permission deny/allow
Membership/paywall
Purchase each configured product
Pending/cancel path if possible
Restore/reinstall
Logout/login
Account deletion
Post-deletion local state
```

## 15.3. Billing test matrix

Cho từng subscription/product:

- product visible;
- localized price correct;
- purchase success;
- backend verified;
- correct entitlement;
- restart persists from trusted backend;
- restore works;
- cancellation handled;
- expiry/revocation handling;
- replay cannot grant duplicate.

## 15.4. Device/API matrix

Ưu tiên:

- Android 14;
- Android 15;
- Android 16/API36;
- một thiết bị/VM 16 KB page-size nếu available.

## 15.5. Pre-launch report

Review Google Play Pre-launch report:

- crashes;
- ANRs;
- permission issues;
- accessibility blockers;
- security warnings;
- unsupported APIs;
- device compatibility.

Mọi crash/ANR trong core/reviewer path = `NO-GO` tới khi fixed/retested.

---

# 16. PLAY CONSOLE COMPLETION PACKAGE

Đây là phần Codex có thể chuẩn bị nội dung/evidence nhưng nếu không có Play Console access thì không được đánh PASS.

## 16.1. Data Safety

Dùng `DATA_SAFETY_MAPPING.md` cuối cùng.

Cross-check:

```text
Data Safety answers == actual final AAB/runtime
```

## 16.2. Health Apps declaration

Dùng `HEALTH_APPS_DECLARATION.md` cuối cùng.

Không khai category không ship; không bỏ category đang ship.

## 16.3. Foreground Service declaration

Nộp:

- microphone FGS type;
- user-start use case;
- video evidence;
- explanation consistent with app.

## 16.4. Privacy Policy URL

Verify live URL:

- HTTPS;
- public;
- stable;
- content matches final behavior.

## 16.5. Account deletion URL

Verify public outside-app deletion page/resource and enter exact URL in Console.

## 16.6. App Access

Enter reviewer credentials/instructions; dry-run again.

## 16.7. Monetization configuration

Check:

- products/base plans active;
- correct package;
- tester/license test config;
- regional availability;
- renewal/cancel terms reflected in UI/store copy.

## 16.8. Store Listing

Cross-check:

- health claims;
- screenshots;
- Plus/FamilyPlus wording;
- AI wording;
- sleep safety wording;
- disclaimer;
- privacy/deletion references;
- no feature claim that is inaccessible/broken.

## 16.9. Play App Signing

Verify Play Console App Signing setup and release upload/signing state.

Local signing alone không phải bằng chứng Play App Signing.

---

# 17. DOCUMENTATION / EVIDENCE UPDATE CONTRACT

Codex phải cập nhật tối thiểu:

- `docs/release/google_play/README.md`
- `docs/release/google_play/RELEASE_EVIDENCE_MATRIX.md`
- `docs/release/google_play/ACCOUNT_DELETION.md`
- `docs/release/google_play/FOREGROUND_SERVICE_DECLARATION.md`
- `docs/release/google_play/DATA_SAFETY_MAPPING.md`
- `docs/release/google_play/HEALTH_APPS_DECLARATION.md`
- `docs/release/google_play/STORE_LISTING_CLAIMS_REVIEW.md`
- `.codex/history/WORKLOG.md` nếu repo dùng file này
- `.codex/history/OPEN_RISKS.md`

Mỗi evidence row dùng trạng thái chuẩn:

```text
SOURCE PASS
ARTIFACT PASS
SANDBOX RUNTIME PASS
INTERNAL TRACK PASS
CONSOLE PASS
BLOCKED_EXTERNAL
FAIL
```

Ví dụ không hợp lệ:

```text
“Account deletion PASS”
```

khi chỉ mới có Edge Function source.

Ví dụ hợp lệ:

```text
Account deletion:
- SOURCE PASS
- SANDBOX RUNTIME PASS
- STORAGE CLEANUP PASS
- PUBLIC URL BLOCKED_EXTERNAL
- CONSOLE OPEN
```

---

# 18. EXPECTED FILE CHANGE MAP

> Đây là expected scope, không phải permission để sửa mù. Codex phải xác minh active/reachable path trước.

## 18.1. Dependency/build

- `pubspec.yaml`
- `pubspec.lock`
- Android build/manifest chỉ khi cần cho compatibility/remediation.

## 18.2. Billing/paywall

- `lib/app_versions/v2/features/paywall/**`
- `lib/app_versions/v2/repositories/membership_billing_repository.dart`
- `lib/app_versions/v2/repositories/membership_repository.dart`
- membership domain files
- associated tests.

## 18.3. Backend

- `supabase/functions/google-play-verify-purchase/index.ts`
- `supabase/functions/report-ai-content/index.ts`
- `supabase/functions/delete-account/index.ts`
- `supabase/functions/nabi-ai-generate/index.ts` only if privacy/health/safety contract needs remediation
- `supabase/01_build_system.sql` only for canonical schema/RLS/RPC changes
- `supabase/02_seed_data.sql` only if canonical product/config seed requires update.

## 18.4. Sleep safety/native

- active Flutter Sleep Safety files found from router/grep
- `android/app/src/main/AndroidManifest.xml`
- exact Kotlin `SleepSafetyForegroundService.kt`
- exact MethodChannel/native bridge files
- tests.

## 18.5. Account/privacy/health UI

- active settings/account pages
- privacy/about/legal pages
- health/AI/sleep copy/localization files
- onboarding permission/disclosure components
- tests.

## 18.6. Notifications

- active notification scheduler/service
- exact alarm handling
- boot/reschedule logic
- tests.

## 18.7. Release docs

- all `docs/release/google_play/*` listed above.

---

# 19. COMMAND / VALIDATION MATRIX

## 19.1. Static

```bash
flutter pub get
flutter pub deps
flutter analyze
```

## 19.2. Tests

Run targeted first, e.g.:

```bash
flutter test test/app_versions/v2/features/paywall/presentation/controllers/membership_payment_controller_test.dart
flutter test test/app_versions/v2/features/paywall/presentation/pages/membership_payment_page_purchase_test.dart
flutter test test/app_versions/v2/repositories/membership_billing_repository_test.dart
flutter test test/app_versions/v2/repositories/membership_repository_test.dart
```

Sau đó related directories, rồi:

```bash
flutter test
```

## 19.3. Android dependency

```bash
cd android
./gradlew app:dependencies --configuration releaseRuntimeClasspath
```

Verify Billing 8+.

## 19.4. Release build

```bash
flutter build appbundle --release
```

## 19.5. Git diff hygiene

```bash
git status --short
git diff --check
git diff --stat
git diff
```

Kiểm tra không có:

- generated caches;
- secrets;
- `.env`;
- keystore;
- build output;
- unrelated formatting churn.

---

# 20. ROLLBACK / STOP CONDITIONS

## 20.1. Stop ngay khi

- Billing 8 migration làm purchase verification semantics không rõ.
- Backend có nguy cơ grant entitlement từ client-controlled state.
- Canonical DB source không xác định được.
- Thay đổi cần destructive production DB reset.
- Account deletion có thể xóa nhầm dữ liệu user khác.
- FGS microphone không thể chứng minh user-start/compliant behavior.
- Privacy/Data Safety không thể xác định third-party processing thực tế.

Trong các trường hợp này: ghi `BLOCKED`, không “đoán và code tiếp”.

## 20.2. Feature-disable fallback

Nếu một feature P0 policy không thể hoàn thiện kịp release, Codex có thể đề xuất **disable/remove from release build** thay vì ship không compliant, nhưng chỉ khi:

- product owner chấp nhận;
- route/UI/backend behavior bị tắt thật;
- manifest permissions được giảm tương ứng;
- Data Safety/Health declaration/store listing cập nhật theo build mới;
- test chứng minh feature không reachable.

Ví dụ Sleep Safety không thể đạt FGS compliance → phương án an toàn hơn có thể là tắt feature khỏi release thay vì giữ mic permission/route không hoàn chỉnh.

---

# 21. ACCEPTANCE MATRIX CUỐI

Codex phải trả về bảng này khi kết thúc implementation:

| Issue | Source | Unit/Widget | Backend/Sandbox | Device | Internal Track | Console | Final |
|---|---|---|---|---|---|---|---|
| GP-001 Billing 8 | | | | | | | |
| GP-002 Health | | | | | | | |
| GP-003 Privacy/Data Safety | | | | | | | |
| GP-004 FGS Mic | | | | | | | |
| GP-005 Delete Account | | | | | | | |
| GP-006 App Access | N/A | N/A | | | | | |
| GP-007 AI Report | | | | | | | |
| GP-008 Supabase/RLS | | | | N/A | | | |
| GP-009 Tests | | | N/A | | | N/A | |
| GP-010 Exact Alarm | | | N/A | | | | |

Quy tắc Final:

```text
PASS = tất cả evidence bắt buộc đã có
BLOCKED_EXTERNAL = code xong nhưng cần credential/device/Play Console
FAIL = evidence cho thấy behavior sai
OPEN = chưa thực hiện
```

---

# 22. RELEASE GO / NO-GO GATE

## 22.1. P0 — tất cả phải đóng

Không submit Production nếu bất kỳ mục nào còn FAIL/OPEN:

- Billing release runtime vẫn là PBL 7.
- Health Apps declaration chưa đúng/submitted.
- Privacy URL/Data Safety không hoàn chỉnh.
- FGS microphone declaration/runtime chưa pass khi feature vẫn ship.
- Account deletion in-app/outside-app chưa hoạt động.
- Reviewer không vào được app.

## 22.2. P1

Không được còn **untriaged release-critical failure** ở:

- AI report;
- Supabase/RLS;
- full tests.

## 22.3. P2

Exact alarm phải có safe behavior/fallback.

## 22.4. Final GO criteria

Chỉ đánh `GO` khi:

- [ ] final AAB build thành công;
- [ ] target/compile SDK 36;
- [ ] Billing 8+ verified trong release dependency;
- [ ] no secret leakage;
- [ ] 16 KB artifact check pass;
- [ ] core regression tests clean/triaged;
- [ ] internal-track E2E pass trên exact final AAB;
- [ ] real purchase pass;
- [ ] AI report runtime pass;
- [ ] account deletion runtime + web path pass;
- [ ] Sleep Safety permission/FGS test pass hoặc feature bị removed đúng cách;
- [ ] Data Safety submitted đúng;
- [ ] Health Apps declaration submitted đúng;
- [ ] Privacy URL live;
- [ ] FGS declaration/video submitted nếu applicable;
- [ ] App Access reviewer account verified;
- [ ] Play App Signing state verified;
- [ ] store claims consistent with actual app.

---

# 23. CODEX GPT-5.6 LUNA — EXECUTION CONTRACT

Codex phải làm theo vòng lặp cho từng work package:

```text
1. READ exact source-of-truth
2. REPRODUCE/VERIFY current issue
3. MAP blast radius
4. IMPLEMENT minimal coherent fix
5. RUN targeted tests
6. RUN related tests
7. RUN static validation
8. UPDATE evidence honestly
9. CONTINUE next dependency
```

Không được:

- tạo patch text thay vì sửa file trực tiếp;
- sửa unrelated files;
- overwrite user changes;
- mark Console PASS khi không có Console access;
- mark device PASS khi chưa test device;
- mark backend PASS khi chỉ unit test mock;
- commit secrets;
- tạo reviewer password trong repository;
- tăng entitlement trực tiếp từ Flutter client;
- re-enable VietQR cho digital membership trên Play build;
- dùng broad photo permission;
- suppress test failures để xanh giả.

---

# 24. BÀN GIAO SAU KHI IMPLEMENT

Sau khi toàn bộ phần có thể thực hiện đã xong, output phải gồm:

1. **Danh sách file đã sửa/tạo**, theo đường dẫn repo.
2. **Issue → file → change → test → evidence mapping**.
3. **Lệnh đã chạy + kết quả thật**.
4. **Các hạng mục BLOCKED_EXTERNAL** nếu còn.
5. **Final AAB metadata** nếu build được:
   - path;
   - package;
   - versionName;
   - versionCode;
   - SHA-256;
   - signing summary.
6. **Release GO/NO-GO** dựa trên matrix, không dựa cảm tính.
7. **ZIP chỉ chứa file mới/file sửa** với cấu trúc giống repository.

ZIP không được chứa:

- `.git/`;
- build cache;
- `.dart_tool/`;
- `build/`;
- `.env`/secrets;
- keystore;
- service account JSON;
- patch files;
- file nhận xét/temporary scratch;
- plan này nếu người dùng chỉ yêu cầu ZIP code thay đổi.

---

# 25. POLICY REFERENCES CODEx PHẢI RE-VERIFY TẠI THỜI ĐIỂM EXECUTION

Không hard-code kết luận policy nếu Google đã cập nhật sau ngày lập plan. Re-check official docs trước khi chốt Console:

- Google Play Billing deprecation FAQ: `https://developer.android.com/google/play/billing/deprecation-faq`
- Payments policy: `https://support.google.com/googleplay/android-developer/answer/10281818`
- Health Content and Services / Health Apps: `https://support.google.com/googleplay/android-developer/answer/16679511`
- User Data / Account deletion: `https://support.google.com/googleplay/android-developer/answer/10144311`
- AI-generated content policy: `https://support.google.com/googleplay/android-developer/answer/13985936`
- App Access: `https://support.google.com/googleplay/android-developer/answer/15748846`
- Foreground Service declaration: `https://support.google.com/googleplay/android-developer/answer/16559646`
- Target API requirements: `https://support.google.com/googleplay/android-developer/answer/11926878`
- Android 16 KB page size: `https://developer.android.com/guide/practices/page-sizes`

Nếu current policy khác audit, current official policy thắng.

---

# 26. DEFINITION OF DONE — TOÀN TASK

Task chỉ được coi là hoàn thành khi:

```text
P0 blockers = 0
P1 untriaged release risks = 0
P2 unsafe runtime paths = 0
Final AAB = built and inspected
Internal track = exact final AAB tested
Play Console declarations = completed where access exists
External blockers = explicitly listed where access does not exist
Evidence matrix = truthful and current
```

Nếu thiếu Play Console/device/production credentials, kết luận cuối phải là:

```text
IMPLEMENTATION COMPLETE / RELEASE VERIFICATION BLOCKED_EXTERNAL
```

chứ không được viết:

```text
FULLY FIXED / READY FOR PRODUCTION
```

khi chưa có bằng chứng tương ứng.

---

# 27. EXECUTION START CHECKLIST CHO CODEX

Trước dòng code đầu tiên, Codex phải tự tick:

- [ ] Đã đọc `AGENTS.md`.
- [ ] Đã đọc `.codex/AGENTS.md`.
- [ ] Đã đọc `PROJECT_MAP` + learned skills + fix workflow.
- [ ] Đã chốt baseline SHA và bảo vệ user changes.
- [ ] Đã xác định active v1/v2/v3 routes.
- [ ] Đã xác định canonical Supabase sources.
- [ ] Đã xác định exact Billing client version từ Gradle graph.
- [ ] Đã xác định exact native package/service path cho Sleep Safety.
- [ ] Đã chạy baseline analyze/tests.
- [ ] Đã map external credentials/devices/Play Console capability.

Sau đó mới bắt đầu GP-001.

---

**END OF PLAN**
