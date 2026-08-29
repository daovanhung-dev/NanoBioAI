# NANOBIOAI — GOOGLE PLAY FINAL PASS EXECUTION PLAN
## Dành cho GPT-5.6 Luna

> **Repository:** `https://github.com/daovanhung-dev/NanoBioAI.git`
> **Branch mục tiêu:** `main`
> **Current verified HEAD tại thời điểm lập plan:** `30f62b04479a85edaab2c3ae5d73ead228f6f16a`
> **Ngày lập plan:** 2026-08-29
> **Executor:** GPT-5.6 Luna
> **Workflow execution (canonical):** `fix-issues`
> **Release profile:** `release-hardening / production-readiness`
> **Mục tiêu:** Đưa NanoBio từ trạng thái `SOURCE/LOCAL ARTIFACT GẦN PASS` sang `PRODUCTION RELEASE GO` bằng bằng chứng source + runtime + internal-track + Play Console, không đánh dấu PASS giả.
> **Trạng thái tài liệu:** `PLAN READY — CHỈ THỰC THI SAU KHI USER XÁC NHẬN`
> **Bản hoàn thiện:** `r1.1` — 2026-08-29; phiên này chỉ hoàn thiện tài liệu, không thực thi release gate.

---

# 0. MỤC TIÊU CUỐI CÙNG

GPT-5.6 Luna phải đưa dự án qua toàn bộ chuỗi:

```text
SOURCE PASS
→ TARGETED TEST PASS
→ FULL SUITE CLASSIFIED/CLEAN
→ SUPABASE RUNTIME PASS
→ ACCOUNT DELETION E2E PASS
→ AI RUNTIME PASS
→ PLAY BILLING REAL PURCHASE PASS
→ ANDROID DEVICE / FGS PASS
→ FINAL AAB PASS
→ INTERNAL TESTING PASS
→ PLAY CONSOLE DECLARATIONS PASS
→ REVIEWER ACCESS PASS
→ RELEASE GO
```

Không được sử dụng tiêu chí:

```text
build AAB thành công
```

để kết luận:

```text
Google Play Production PASS
```

## 0.1. Công thức GO bắt buộc

```text
RELEASE_GO =
    SOURCE_PASS
    AND FULL_TEST_RISK_CLOSED
    AND SUPABASE_RUNTIME_PASS
    AND DELETION_RUNTIME_PASS
    AND AI_RUNTIME_PASS
    AND BILLING_RUNTIME_PASS
    AND LEGAL_PAGES_PUBLIC_PASS
    AND DATA_SAFETY_PASS
    AND HEALTH_APPS_PASS
    AND FGS_MIC_PASS
    AND REVIEWER_ACCESS_PASS
    AND PLAY_APP_SIGNING_PASS
    AND INTERNAL_TRACK_PASS
    AND FINAL_AAB_PASS
```

Chỉ khi tất cả điều kiện trên bằng `true`, Luna mới được ghi:

```text
GO — READY FOR PRODUCTION REVIEW
```

Nếu còn bất kỳ mục bắt buộc nào thiếu quyền truy cập, dùng:

```text
BLOCKED_EXTERNAL
```

Không được tự chuyển thành `PASS`.

## 0.2. Definition of Ready trước khi execution

Plan chỉ được chuyển từ `PLAN READY` sang execution khi Luna xác nhận đủ các điều kiện sau:

| Điều kiện vào | Bằng chứng tối thiểu | Nếu thiếu |
|---|---|---|
| User đã xác nhận thực thi | Tin nhắn/command xác nhận rõ phạm vi | Giữ `PLAN READY`, không sửa runtime |
| Baseline và local work đã chụp | `git status`, branch, HEAD, diff summary | Dừng ở Phase 0 |
| Input contract đã phân loại | Form Play hoặc bảng giá trị tương đương đã redacted | Đánh từng gate liên quan `BLOCKED_EXTERNAL` |
| External access đã biết | Supabase sandbox, Play Console, tester/device, legal owner | Tiếp tục phần độc lập; không giả PASS |
| Evidence root đã chọn | `/tmp/nanobio-release-validation/<RUN_ID>/` hoặc thư mục repo đã được ignore | Không ghi log vào thư mục source |

Mỗi lần chạy phải sinh một `RUN_ID` bất biến. Mọi evidence runtime, screenshot,
hash và log tóm tắt phải gắn với `RUN_ID`, `versionCode` và AAB SHA-256; không
ghi secret, token, PII hay raw health payload vào evidence.

## 0.3. Protocol ghi nhận sau từng phase

Sau mỗi phase, Luna phải cập nhật cùng một record trước khi sang phase kế tiếp:

```text
PHASE / CHECKPOINT
OWNER ROLE
INPUTS USED
FILES TOUCHED
COMMANDS + RESULT
EVIDENCE PATH
STATUS
BLOCKER / NEXT ACTION
```

`SOURCE_PASS` hoặc `ARTIFACT_PASS` chỉ chứng minh đúng lớp đó; không được dùng
thay cho `SANDBOX_RUNTIME_PASS`, `DEVICE_RUNTIME_PASS`, `INTERNAL_TRACK_PASS`
hay `CONSOLE_PASS`. `FAIL` chỉ được đóng sau khi sửa nguyên nhân và chạy lại
đúng test; `BLOCKED_EXTERNAL` phải ghi rõ người/hệ thống cần mở quyền.

---

# 1. BASELINE HIỆN TẠI — KHÔNG ĐƯỢC FIX LẠI NHỮNG GÌ ĐÃ PASS

Tại HEAD `30f62b04479a85edaab2c3ae5d73ead228f6f16a`, các hạng mục sau đã có evidence source/local artifact và phải được bảo vệ khỏi regression:

| Hạng mục | Hiện tại | Hành động |
|---|---|---|
| `compileSdk` | 36 | Giữ nguyên |
| `targetSdk` | 36 | Giữ nguyên |
| Play Billing dependency | `8.0.0` | Không downgrade |
| `in_app_purchase` | `3.3.0` | Không downgrade |
| AAB release local | Build PASS | Rebuild cuối task |
| Package | `com.nanobioai.app` | Không đổi |
| Gemini key trong client | Không phát hiện | Không tái đưa secret vào client |
| Direct Gemini provider URL trong final arm64 app | Không phát hiện | Không regression |
| Broad photo/media permissions | Đã loại bỏ | Không thêm lại |
| 16 KB ELF alignment | Artifact PASS | Chỉ còn device/runtime gate |
| Account deletion source lifecycle | Source PASS | Cần runtime/E2E |
| AI report source | Source PASS | Cần deployed runtime |
| Billing verification source | Source PASS | Cần real purchase runtime |
| Targeted remediation tests | PASS | Không làm hỏng |

## 1.1. Những gate còn mở phải đóng

### P0 — chặn Production

1. Privacy Policy HTTPS public thật.
2. Outside-app Account Deletion HTTPS public thật.
3. Data Safety Play Console.
4. Health Apps Declaration Play Console.
5. Foreground Service microphone declaration + Android 14+ runtime.
6. Supabase SQL/RLS/functions runtime verification.
7. Account deletion runtime E2E.
8. Real Google Play Billing purchase/verify/restore/cancel/expiry.
9. Play App Signing + final AAB accepted.
10. Reviewer App Access.
11. Final Internal Testing E2E.

### P1 — release-risk phải đóng/phân loại

12. Full Flutter suite hiện còn khoảng `978 PASS / 236 FAIL` + shutdown stream error ở audit gần nhất.
13. `nabi-ai-generate` runtime.
14. `report-ai-content` runtime.
15. 16 KB device/install smoke.
16. Store Listing health/medical claim final review.
17. Exact alarm behavior Android 14+ nếu feature reachable.

## 1.2. Current gate snapshot trước execution

Đây là trạng thái mạnh nhất đã có trong repository tại thời điểm lập plan; không
phải kết quả của execution mới. Các mục `BLOCKED_EXTERNAL` vẫn là NO-GO cho
production.

| Gate | Evidence hiện có | Status hiện tại | Trạng thái cần đạt |
|---|---|---|---|
| API/target 36 | Gradle + local AAB metadata | `ARTIFACT_PASS` | Giữ trên final AAB |
| Billing 8 / client path | Dependency + source/targeted tests | `SOURCE_PASS` | `BILLING_RUNTIME_PASS` |
| Full Flutter suite | Audit: `978 PASS / 236 FAIL` + shutdown stream error | `FAIL` | 0 untriaged, 0 reachable regression |
| Supabase/RLS/functions | Canonical SQL + static contracts | `SOURCE_PASS` | `SANDBOX_RUNTIME_PASS` |
| AI generate/report | Source + handler/UI tests | `SOURCE_PASS` | `SANDBOX_RUNTIME_PASS` |
| Account deletion | Source lifecycle + contract tests | `SOURCE_PASS` | `SANDBOX_RUNTIME_PASS` |
| Privacy/deletion URLs | Publish-ready pages; no public host | `BLOCKED_EXTERNAL` | `CONSOLE_PASS` + incognito check |
| Data Safety / Health Apps | Mapping and declaration drafts | `BLOCKED_EXTERNAL` | `CONSOLE_PASS` |
| FGS microphone / exact alarm | Manifest/source evidence | `SOURCE_PASS` | `DEVICE_RUNTIME_PASS` + declaration |
| 16 KB runtime | Native ELF alignment in local AAB | `ARTIFACT_PASS` | Device/Play install evidence |
| Play signing / Internal track / reviewer | No Console evidence | `BLOCKED_EXTERNAL` | `INTERNAL_TRACK_PASS` + `CONSOLE_PASS` |

Nguồn đối chiếu cho snapshot: `docs/release/google_play/RELEASE_EVIDENCE_MATRIX.md`
và `.codex/history/OPEN_RISKS.md`. Khi execution tạo evidence mới, cập nhật
snapshot này và gate matrix Phase 13; không sửa ngược lịch sử.

---

# 2. NGUYÊN TẮC THỰC THI BẮT BUỘC CHO GPT-5.6 LUNA

## 2.1. Trước mọi thay đổi

Phải đọc theo đúng thứ tự:

1. `AGENTS.md`
2. `.codex/AGENTS.md`
3. `.codex/PROJECT_MAP.md`
4. `.codex/history/LEARNED_SKILLS.md`
5. `.codex/workflows/fix-issues.md`
6. `.codex/task-skills/fix-issues.md`
7. `.codex/history/OPEN_RISKS.md`
8. `docs/release/google_play/README.md`
9. `docs/release/google_play/RELEASE_EVIDENCE_MATRIX.md`
10. `docs/release/google_play/ACCOUNT_DELETION.md`
11. `docs/release/google_play/ACCOUNT_DELETION_PUBLIC_PAGE.md`
12. `docs/release/google_play/PRIVACY_POLICY_PUBLIC_PAGE.md`
13. `docs/release/google_play/DATA_SAFETY_MAPPING.md`
14. `docs/release/google_play/HEALTH_APPS_DECLARATION.md`
15. `docs/release/google_play/FOREGROUND_SERVICE_DECLARATION.md`
16. `docs/release/google_play/STORE_LISTING_CLAIMS_REVIEW.md`
17. `pubspec.yaml`
18. `pubspec.lock`
19. `android/app/build.gradle.kts`
20. `android/app/src/main/AndroidManifest.xml`

Sau đó mới mở source/test cụ thể theo từng phase.

## 2.2. Không brute-force repo mù

Repo rule yêu cầu context routing.

Luna phải dùng:

```bash
rg
git grep
rg --files
git diff
```

Nếu `rg` không có trong môi trường execution, dùng `git grep`, `grep`/`find`
với phạm vi tương đương và ghi rõ fallback trong evidence; không coi việc đổi
công cụ tìm kiếm là lý do để bỏ qua reachability scan.

để xác định exact reachable implementation trước khi chỉnh sửa.

Không được sửa file chỉ vì tên giống feature.

## 2.3. Source-of-truth

Thứ tự ưu tiên:

```text
reachable runtime code
> executable DB/Supabase source
> platform/package config
> executable tests
> current release docs
> historical worklog
```

## 2.4. Secret policy

Tuyệt đối không commit hoặc in ra:

- Supabase `service_role`
- Google service account private key
- Gemini/API key
- `.jks`
- keystore password
- reviewer password
- raw Google purchase token
- refresh token/JWT
- real health data
- OTP

Có thể lưu:

- public Supabase anon key
- public legal URLs
- product IDs
- certificate fingerprints
- SHA-256 của AAB
- anonymized test IDs

## 2.5. Status model

Mỗi gate chỉ được dùng một trong:

```text
PLANNED
IMPLEMENTED
SOURCE_PASS
ARTIFACT_PASS
SANDBOX_RUNTIME_PASS
DEVICE_RUNTIME_PASS
INTERNAL_TRACK_PASS
CONSOLE_PASS
BLOCKED_EXTERNAL
FAIL
```

Không dùng từ mơ hồ như:

```text
done
probably fine
should work
looks good
```

nếu không có evidence.

---

# 3. INPUT CONTRACT — NHỮNG THÔNG TIN USER PHẢI CUNG CẤP

Luna phải dùng file:

```text
NanoBio_Google_Play_PASS_Form.xlsx
```

hoặc thông tin tương đương để lấy các giá trị ngoài repo.

Nếu thiếu, Luna tiếp tục tất cả phần có thể làm và đánh đúng gate là `BLOCKED_EXTERNAL`.

## 3.1. Legal

Cần:

```text
LEGAL_ENTITY_NAME
DEVELOPER_DISPLAY_NAME
SUPPORT_EMAIL
PRIVACY_EMAIL
COUNTRY
PUBLIC_WEBSITE_OR_HOST
```

Không được tự bịa.

## 3.2. Public legal hosting

Cần 2 URL HTTPS:

```text
PRIVACY_POLICY_URL
ACCOUNT_DELETION_URL
```

Yêu cầu:

- public
- HTTPS
- không login
- không PDF
- không private Drive
- mở được Incognito
- nội dung đúng app/package

Nếu user chưa có hosting:

1. Luna được phép tạo static HTML deploy-ready.
2. Không được tự tuyên bố URL đã live.
3. Đánh `SOURCE_READY / BLOCKED_EXTERNAL`.
4. Cung cấp exact deploy steps cho GitHub Pages/Vercel/Cloudflare Pages hoặc host user chọn.

## 3.3. Retention decisions

User/legal phải quyết định:

- Health/profile retention.
- AI prompt/chat retention.
- AI safety report retention.
- Security/audit log retention.
- Purchase/fraud/reconciliation retention.
- Provider-side retention nếu có.

Nếu chưa có quyết định:

```text
LEGAL_DECISION_REQUIRED
```

Không tự chọn số ngày rồi đưa vào Privacy Policy như sự thật.

## 3.4. Production providers

Cần xác nhận:

- AI provider.
- Supabase.
- Analytics SDK.
- Crash reporting.
- Ads SDK.
- Observability provider.
- Email/push provider.
- third-party backend khác.

## 3.5. Play Console

Cần:

- app tồn tại hay chưa;
- package;
- highest uploaded versionCode;
- Internal Testing track;
- Play App Signing state;
- product IDs/base plans;
- license tester;
- reviewer account;
- App Access instructions;
- Console declaration access.

## 3.6. Kiểm tra input contract và quyền truy cập

Trước Phase 0, Luna phải kiểm tra file form mà không in nội dung nhạy cảm:

```bash
find . -maxdepth 5 -type f -iname '*Google*Play*PASS*Form*.xlsx' -print
```

Nếu không tìm thấy form, tạo bảng thiếu dữ liệu trong evidence root và tiếp tục
phần local. Không tạo giá trị giả. Phân loại từng trường như sau:

| Nhóm | Có thể lấy từ repo | Bắt buộc owner cung cấp/xác nhận |
|---|---|---|
| Build/package/product IDs | Có thể lấy source/Gradle; phải đối chiếu Console | Product/base plan và versionCode cao nhất trên Play |
| Public legal URLs | Không có URL live trong repo | Privacy URL, deletion URL, incognito access |
| Legal identity/retention | Không suy ra an toàn | Entity, support/privacy contact, retention và provider terms |
| Runtime credentials | Chỉ kiểm tra tên/presence | Supabase sandbox, Google Play API, tester/reviewer account |
| Device/Console state | Không suy ra từ source | Android 14/15/16, 16 KB, signing, declarations |

Evidence chỉ ghi `field: PRESENT/MISSING/REDACTED`, không ghi value của secret,
JWT, password, purchase token hoặc dữ liệu sức khỏe. `INPUT_READY` không đồng
nghĩa `RELEASE_GO`; nó chỉ cho phép bắt đầu phase tương ứng.

---

# 4. EXECUTION ORDER — KHÔNG ĐƯỢC ĐẢO BỪA

Dependency graph:

```text
PHASE 0  Fresh baseline + diff protection
   ↓
PHASE 1  Reachability + release inventory
   ↓
PHASE 2  Full test failure triage + real regressions
   ↓
PHASE 3  Supabase sandbox rebuild + RLS
   ↓
PHASE 4  AI runtime + report runtime
   ↓
PHASE 5  Account deletion E2E
   ↓
PHASE 6  Play Billing real runtime
   ↓
PHASE 7  Privacy/Data Safety/Health legal closure
   ↓
PHASE 8  Sleep Safety FGS + exact alarm Android 14/15/16
   ↓
PHASE 9  Store Listing + reviewer/App Access
   ↓
PHASE 10 Final AAB + secret/native scan
   ↓
PHASE 11 Play App Signing + Internal Testing
   ↓
PHASE 12 Play Console declarations
   ↓
PHASE 13 Final GO/NO-GO audit
   ↓
PHASE 14 Handoff ZIP
```

Lý do:

- Không khai Data Safety trước khi biết runtime cuối cùng.
- Không tạo final AAB trước khi source/test/backend ổn định.
- Không dùng AAB cũ làm evidence sau khi source thay đổi.
- Internal Testing phải chạy đúng AAB cuối cùng.
- Console declarations phải mô tả đúng final release.
- Mọi runtime evidence phải gắn với versionCode/AAB SHA cụ thể.

## 4.1. Phase exit contract và ownership

Mỗi phase phải có một owner role, một output bất biến và một checkpoint. Không
được đánh dấu phase hoàn tất chỉ vì command chạy được một phần.

| Phase | Owner role chính | Output bắt buộc | Checkpoint |
|---|---|---|---|
| 0 | Release engineering | Baseline/toolchain/diff record | `CP0` |
| 1 | Architecture/release | Reachability map + identity inventory | `CP0` |
| 2 | QA/Flutter | Classified full-test report + targeted reruns | `CP1` |
| 3 | Backend/Supabase | Rebuild log + two-user RLS matrix | `CP2` |
| 4 | Backend/AI | Generate/report HTTP + UI/DB evidence | `CP2` |
| 5 | Backend + auth | Populated-user deletion E2E + isolation witness | `CP3` |
| 6 | Billing/release | Internal Play purchase lifecycle evidence | `CP4` |
| 7 | Product/privacy | Approved copy + final Data Safety/Health inputs | `CP5` |
| 8 | Android/device | FGS matrix + exact-alarm decision + video checklist | `CP6` |
| 9 | Product/release | Listing review + reviewer dry-run instructions | `CP9` |
| 10 | Release engineering | Final AAB metadata, scan and SHA record | `CP7` |
| 11 | Release/QA | Play App Signing + fresh-install E2E + pre-launch review | `CP8` |
| 12 | Product/Console | Submitted declaration screenshots/timestamps | `CP9` |
| 13 | Release owner | Final gate matrix and GO/NO-GO decision | `CP10` |
| 14 | Release owner | Changed-file manifest + verified handoff ZIP | `CP10` |

Khi owner role hoặc external access chưa rõ, status của phase là
`BLOCKED_EXTERNAL`, không để trống và không tự gán cho cá nhân.

---

# PHASE 0 — FRESH BASELINE VÀ BẢO VỆ USER WORK

## Mục tiêu

Bảo đảm Luna không làm việc trên baseline cũ và không ghi đè local work.

## Commands

```bash
git status --short
git branch --show-current
git rev-parse HEAD
git log -1 --oneline
git diff --stat
git diff
```

Expected current baseline khi lập plan:

```text
30f62b04479a85edaab2c3ae5d73ead228f6f16a
```

Nếu HEAD khác:

1. đọc diff từ baseline plan → current HEAD;
2. cập nhật inventory;
3. không reset code mới;
4. không checkout ngược;
5. không force overwrite user changes.

## Toolchain

```bash
flutter --version
dart --version
java -version
./gradlew -version
```

Nếu Supabase/Deno có:

```bash
supabase --version
deno --version
```

## Package baseline

```bash
flutter pub get
flutter pub deps
```

Xác minh:

```text
in_app_purchase 3.3.0
com.android.billingclient:billing 8.x
```

Gradle:

```bash
cd android
./gradlew app:dependencies --configuration releaseRuntimeClasspath
```

Windows equivalent nếu cần:

```powershell
.\gradlew.bat app:dependencies --configuration releaseRuntimeClasspath
```

## Baseline evidence

Ghi:

```text
HEAD
branch
Flutter
Dart
Java
Gradle
Billing dependency
target SDK
compile SDK
versionName
versionCode
```

## PASS

`BASELINE_PASS` khi:

- HEAD xác định rõ;
- local dirty files được bảo vệ;
- toolchain đủ để chạy phần tương ứng;
- dependency graph xác định.

---

# PHASE 1 — REACHABILITY VÀ RELEASE INVENTORY

## Mục tiêu

Không fix dead code.

## Entry points

Đọc:

```text
lib/main.dart
lib/app/bio_ai_app.dart
router/provider thực tế reachable
```

Search:

```bash
rg "MembershipPaymentPage|membership_payment|in_app_purchase|purchaseStream|buyNonConsumable|buyConsumable|buySubscription" lib test
rg "delete-account|deleteAccount|ACCOUNT_DELETION_URL|xóa tài khoản|Xóa tài khoản" lib supabase test docs
rg "nabi-ai-generate|report-ai-content|ai_content_reports" lib supabase test
rg "SleepSafetyForegroundService|FOREGROUND_SERVICE_MICROPHONE|RECORD_AUDIO|sleep safety|Sleep Safety" android lib test
rg "SCHEDULE_EXACT_ALARM|canScheduleExact|exactAllowWhileIdle|zonedSchedule" android lib test
rg "PRIVACY_POLICY_URL|ACCOUNT_DELETION_URL" lib assets test docs
```

## Output

Tạo internal reachability map:

```text
Feature
→ route
→ page
→ controller/provider
→ repository
→ datasource/API
→ backend function/table
→ tests
```

Tối thiểu cho:

- membership billing;
- account deletion;
- AI generation;
- AI reporting;
- Sleep Safety;
- notification scheduling;
- privacy links;
- health pages;
- Settings;
- auth;
- internal reviewer flow.

## Android identity check

Xác minh đồng bộ:

```text
namespace
applicationId
MainActivity package
SleepSafetyForegroundService package
manifest android:name
deep-link scheme
MethodChannel names nếu còn
```

Nếu mismatch → P0.

## PASS

Không còn ambiguity file nào là active implementation.

---

# PHASE 2 — FULL TEST SUITE TRIAGE VÀ REGRESSION CLEANUP

## Mục tiêu

Đóng tình trạng khoảng:

```text
978 PASS
236 FAIL
1 shutdown stream error
```

Không được mass-skip.

## Step 2.1 — Chạy full suite

```bash
flutter test --reporter expanded
```

Lưu output:

```text
artifacts/release_validation/full_test_before.txt
```

Nếu repo policy không muốn artifacts commit, dùng temp file và chỉ ghi summary vào worklog.

## Step 2.2 — Phân loại mọi failure

Mỗi failure gắn category:

```text
A_REAL_REGRESSION
B_STALE_TEST
C_TOOLCHAIN_ENV
D_FIXTURE_MOCK
E_PLATFORM_UNAVAILABLE
F_DEAD_OR_UNREACHABLE
G_FLAKY
```

Tạo bảng:

| Test | Category | Root cause | Reachable? | Must fix before GO? | Action |
|---|---|---|---|---|---|

## Step 2.3 — SQLite FFI failures

Xác minh:

```text
sqflite_common_ffi
system libsqlite
test bootstrap
database factory setup
platform override
```

Không hard-code máy cụ thể vào production source.

Nếu test cần native lib path, xử lý trong test bootstrap/tooling.

## Step 2.4 — Stale contract/UI test

Chỉ cập nhật expected values khi:

1. reachable source là source-of-truth mới;
2. behavior được release docs/requirement chứng minh;
3. test cũ thực sự stale.

Không sửa expected chỉ để pass.

## Step 2.5 — Shutdown stream error

Search:

```bash
rg "StreamController|Timer|listen\(|cancel\(|close\(|purchaseStream|ProviderContainer|dispose" lib test
```

Ưu tiên:

- purchase stream subscription;
- notification stream;
- voice/mic;
- Sleep Safety;
- Riverpod AsyncNotifier;
- test teardown;
- timers.

Không suppress global error.

## Validation ladder

Sau từng cluster:

```bash
dart format <touched>
flutter analyze <touched>
flutter test <cluster>
```

Cuối phase:

```bash
flutter analyze
flutter test
```

## PASS criteria

Một trong hai mô hình:

### Preferred

```text
FULL SUITE: 100% PASS
```

### Accepted only if platform test cannot run in environment

- 0 untriaged failure.
- 0 reachable production regression.
- Every environment-blocked test documented with reproduction requirement.
- CI/device job proves equivalent test.

Nếu còn real regression:

```text
FAIL — RELEASE NO-GO
```

---

# PHASE 3 — SUPABASE SANDBOX REBUILD + RLS + TRUST BOUNDARY

## Bắt buộc đọc

```text
docs/supabase/README.md
docs/supabase/01_build_system.sql
docs/supabase/02_seed_data.sql
```

và direct-related SQL/functions.

## Không được làm

- reset production;
- chạy destructive seed trên production;
- dùng `_legacy` làm canonical;
- paste service role vào log/chat;
- sửa database trực tiếp mà không cập nhật canonical script.

## Step 3.1 — Provision sandbox/local

Nếu Supabase CLI available:

```bash
supabase status
supabase start
```

Hoặc link disposable sandbox.

Canonical rebuild:

```text
01_build_system.sql
→ 02_seed_data.sql
```

## Step 3.2 — Deploy Edge Functions

Tối thiểu:

```text
nabi-ai-generate
report-ai-content
delete-account
google-play-verify-purchase
```

Các function liên quan membership/admin nếu required bởi trusted flow.

## Step 3.3 — Secret configuration

Chỉ kiểm tra presence/name.

Không in value.

Cần tối thiểu:

- Supabase URL/service role tại server side.
- Gemini/provider secret.
- Google Play API credential/config khi Billing phase đến.

## Step 3.4 — RLS matrix

Tạo:

```text
Anon
User A
User B
Service Role
```

Test cho:

- profile;
- health/body metrics;
- meal;
- exercise;
- schedules;
- sleep;
- AI reports;
- membership;
- quota;
- purchase ledger;
- family/emergency;
- referral/Sale nếu reachable.

Expected:

```text
User A cannot read/write User B private rows
User B cannot read/write User A private rows
Anon cannot access private account data
Service role only on backend trusted paths
```

## Step 3.5 — RPC trust boundary

Xác minh:

- `auth.uid()` ownership.
- user ID không lấy mù từ request.
- product ID allowlist.
- entitlement không grant từ client boolean.
- replay/idempotency.
- quota atomicity.
- family scope.
- admin role server-authoritative.

## PASS

```text
SANDBOX_RUNTIME_PASS
```

chỉ khi SQL/RLS/function HTTP smoke thật chạy thành công.

Nếu không có Supabase access:

```text
BLOCKED_EXTERNAL
```

---

# PHASE 4 — AI GENERATION + AI REPORT RUNTIME

## Mục tiêu

Đóng:

```text
SOURCE PASS
→ DEPLOYED RUNTIME PASS
```

## 4.1. `nabi-ai-generate`

Test:

- authenticated valid prompt;
- guest behavior theo contract;
- missing auth;
- invalid payload;
- oversized payload;
- rate limit;
- provider timeout;
- provider 4xx/5xx;
- fallback model nếu intended;
- no secret leakage;
- health safety response;
- urgent symptom routing;
- retry behavior.

## 4.2. `report-ai-content`

Flow:

```text
assistant message
→ Report
→ reason
→ optional bounded note
→ confirm
→ function
→ DB row
→ moderation state
```

Test:

- auth user;
- guest nếu supported;
- duplicate;
- invalid reason;
- oversized note;
- missing message;
- 401;
- 429;
- 500;
- timeout;
- retry;
- RLS isolation;
- deletion anonymization.

## 4.3. In-app generative AI policy

Xác minh:

- Report action reachable trên AI content.
- Không yêu cầu user gửi email để report.
- Không giấu report chỉ sau deep menu không discoverable.
- Failure hiển thị user-safe message.
- Không log raw sensitive prompts.

## PASS

```text
AI_RUNTIME_PASS
```

khi deployed function + UI path + DB persistence + safety handling được evidence.

---

# PHASE 5 — ACCOUNT DELETION E2E

## Mục tiêu

Đóng cả:

```text
in-app deletion
+
backend deletion
+
storage deletion
+
local deletion
+
outside-app web resource
```

## 5.1. Seed test account

Tạo User A có:

- auth account;
- profile;
- health/body data;
- meal;
- schedule;
- completion proof image;
- AI report;
- membership/purchase ledger test record;
- family/referral record nếu reachable.

Tạo User B làm isolation witness.

## 5.2. In-app flow

Expected:

```text
Settings
→ Account
→ Xóa tài khoản
→ explanation
→ explicit destructive confirmation
→ backend delete
→ local cleanup
→ sign out
→ auth entry
```

Không accidental one-tap.

## 5.3. Backend order

Expected safe order:

```text
authenticate
→ validate confirm
→ remove account-owned Storage objects
→ DB cleanup/anonymization according to canonical SQL
→ Auth user delete
→ success
```

Nếu Storage cleanup fail:

- không để Auth deleted nhưng object orphan theo source contract hiện tại.

## 5.4. Post-delete assertions

User A:

- auth login fails / account gone;
- old session invalid;
- profile gone;
- health gone;
- schedule gone;
- Storage prefix gone;
- local SQLite gone;
- prefs cleared;
- secure storage cleared;
- notifications cancelled.

Retained records:

- purchase/moderation/audit follow approved retention;
- identity link minimized/anonymized as documented.

User B:

- data unchanged.

## 5.5. Idempotency

Gọi delete lần hai:

- no sensitive information leak;
- no corruption;
- safe result.

## PASS

`DELETION_RUNTIME_PASS`

---

# PHASE 6 — REAL GOOGLE PLAY BILLING

## Không sửa lại Billing version nếu vẫn 8.x

Current source already resolves Billing 8.

## 6.1. Product inventory

Xác minh code product IDs ↔ Play Console:

```text
StoreMembershipProduct
Play Console subscription IDs
base plan IDs
regional availability
price metadata
```

Không hard-code giá tiền nếu Play trả localized price.

## 6.2. Server Google Play API

Google service account:

- created;
- linked;
- permission correct;
- secret server-side only.

Không commit JSON credential.

## 6.3. Trusted state machine

Expected:

```text
IDLE
→ QUERY_PRODUCTS
→ READY
→ PURCHASE_STARTED
→ PENDING / PURCHASED
→ VERIFYING_SERVER
→ VERIFIED
→ COMPLETE_PURCHASE
→ ENTITLEMENT_VISIBLE
```

Không grant Plus tại `PurchaseStatus.purchased` trước server verify.

## 6.4. Internal test cases

Bắt buộc:

1. Product query success.
2. Product unavailable.
3. Purchase success.
4. Pending.
5. User cancel.
6. Network loss after purchase.
7. Backend timeout.
8. Backend 401.
9. Backend 409/replay.
10. Backend 429.
11. Backend 500.
12. Duplicate purchase stream event.
13. App restart during pending.
14. Restore purchase.
15. Reinstall + restore.
16. Existing active subscription.
17. Renewal.
18. Cancellation.
19. Expiry.
20. Grace/account hold nếu applicable.
21. Double-tap purchase button.
22. Duplicate token replay.
23. Wrong product ID.
24. Wrong package/token.
25. Entitlement consistency across login/logout.

## 6.5. Evidence

Không lưu raw purchase token.

Lưu:

- test case;
- timestamp;
- tester account alias;
- product ID;
- result;
- entitlement state;
- redacted server response;
- screenshots.

## PASS

`BILLING_RUNTIME_PASS`

chỉ khi real Play Internal Testing purchase đã chạy.

---

# PHASE 7 — PRIVACY POLICY + DATA SAFETY + HEALTH APPS

## Mục tiêu

Final legal declarations phải mô tả đúng runtime cuối cùng.

## 7.1. Privacy Policy

Source draft:

```text
docs/release/google_play/PRIVACY_POLICY_PUBLIC_PAGE.md
```

Luna phải thay placeholder chỉ khi user cung cấp dữ liệu thật:

- legal entity/developer;
- contact;
- effective date;
- provider names;
- retention;
- deletion URL.

Không bịa.

## 7.2. Static public page

Nếu repo không có web app:

Tạo deploy-ready package riêng, ví dụ:

```text
docs/release/google_play/public_pages/
  privacy.html
  delete-account.html
  README.md
```

CHỈ khi phù hợp repo policy và user xác nhận plan thực thi.

Không thêm framework nặng chỉ để host 2 file.

## 7.3. URL wiring

Final release config phải có:

```text
PRIVACY_POLICY_URL=https://...
ACCOUNT_DELETION_URL=https://...
```

Xác minh:

- HTTPS;
- valid URL;
- Settings link visible;
- browser opens correctly;
- Incognito opens without auth;
- no redirect loop;
- no placeholder.

## 7.4. Data Safety final inventory

Phải map runtime:

- Account/profile.
- Health/body.
- Meal/exercise/schedule.
- Sleep.
- AI prompts/responses.
- AI safety reports.
- Camera/gallery.
- Microphone.
- Device/install ID.
- Diagnostics.
- Play purchase token/state.
- Family/emergency.
- Referral/Sale.
- Storage proof images.

Mỗi loại:

```text
Collected?
Shared?
Purpose?
Required or optional?
Encrypted in transit?
Deletion?
Retention?
Third party?
```

## 7.5. Third-party SDK inventory

Run:

```bash
flutter pub deps
```

Review Android dependencies.

Xác minh không có unexpected:

- Ads SDK.
- Analytics SDK.
- tracking SDK.
- crash SDK.

Nếu có → update Data Safety + Privacy.

## 7.6. Health claim scan

Search:

```bash
rg -n -i "diagnos|chẩn đoán|điều trị|chữa|cure|treat|medical device|bác sĩ|doctor|sleep apnea|ngưng thở|seizure|co giật|cardiac|tim mạch|emergency|cấp cứu|phát hiện bệnh" lib assets docs
```

Mỗi hit phân loại:

```text
SAFE_WELLNESS
NEEDS_DISCLAIMER
REMOVE_OR_REWRITE
HIGH_RISK_CLAIM
LEGAL_REVIEW
```

## 7.7. Required positioning

NanoBio phải consistent:

```text
wellness
self-tracking
nutrition
fitness
sleep wellness/safety monitoring
AI-generated wellness guidance
```

Không quảng cáo như:

```text
diagnostic service
medical device
treatment provider
emergency replacement
AI doctor
```

trừ khi có regulatory basis mà hiện repo không claim.

## 7.8. Health Apps Declaration

Chuẩn bị exact Console answers theo final feature set.

Evidence:

- screenshot declaration;
- timestamp;
- app version.

## PASS

```text
LEGAL_PAGES_PUBLIC_PASS
DATA_SAFETY_CONSOLE_PASS
HEALTH_APPS_CONSOLE_PASS
```

---

# PHASE 8 — SLEEP SAFETY FGS + EXACT ALARM

## 8.1. Android source identity

Xác minh:

```text
android.permission.RECORD_AUDIO
android.permission.FOREGROUND_SERVICE
android.permission.FOREGROUND_SERVICE_MICROPHONE
foregroundServiceType="microphone"
SleepSafetyForegroundService package/class
```

## 8.2. Correct user-started flow

Expected:

```text
user opens Sleep Safety
→ disclosure shown
→ user explicitly Start
→ request microphone permission
→ permission granted
→ start FGS
→ startForeground quickly
→ visible ongoing notification
→ monitoring
→ user Stop
→ release microphone/resources
```

Không:

- boot auto-start mic;
- hidden mic;
- start mic before user action;
- request mic at app startup;
- keep mic after user stop;
- imply medical/emergency detection.

## 8.3. Device matrix

Tối thiểu:

| OS | Test |
|---|---|
| Android 14 | required |
| Android 15 | required |
| Android 16 | required |

Ít nhất 1 physical Android 14+ strongly preferred.

Cases:

- fresh install;
- allow mic;
- deny;
- deny permanently;
- revoke while active;
- app foreground;
- app background;
- lock screen;
- screen off;
- notification visible;
- stop from app;
- stop from notification;
- task removed;
- process death;
- reopen;
- another app using mic;
- battery restriction;
- force stop.

## 8.4. Raw audio data audit

Xác minh bằng code/runtime:

```text
raw audio stored?
raw audio uploaded?
derived amplitude/event stored?
retention?
deletion?
```

Update Privacy/Data Safety nếu behavior khác draft.

## 8.5. Foreground Service Declaration video

Video phải thể hiện:

1. mở app;
2. mở Sleep Safety;
3. disclosure;
4. Start;
5. permission;
6. foreground notification;
7. monitoring;
8. Stop.

Luna phải soạn:

- Console description;
- user benefit;
- why immediate FGS is required;
- impact if interrupted;
- video checklist.

## 8.6. Exact alarm

Search exact usage.

Mỗi scheduler:

```text
EXACT_REQUIRED
INEXACT_ACCEPTABLE
```

Nếu không cần exact:

- ưu tiên inexact;
- cân nhắc remove exact alarm permission nếu tất cả paths safe.

Nếu cần exact:

- capability check;
- safe fallback;
- user explanation;
- settings routing;
- no nag loop;
- test fresh install/grant/revoke/reboot/timezone.

## PASS

```text
FGS_MIC_DEVICE_PASS
FGS_CONSOLE_PASS
EXACT_ALARM_SAFE
```

---

# PHASE 9 — STORE LISTING + REVIEWER APP ACCESS

## 9.1. Store Listing

Review:

- App name.
- Short description.
- Full description.
- Feature graphic.
- Screenshots.
- Promo video.
- Plus/FamilyPlus copy.
- AI screenshots.
- Sleep Safety screenshots.

Không để image/copy claim vượt quá app.

## 9.2. Screenshot verification

Mỗi screenshot:

- đúng UI hiện tại;
- không feature Coming Soon giả như shipped;
- không fake health result;
- không “diagnosis” wording;
- Plus features đúng availability.

## 9.3. Reviewer account

Tạo account riêng:

```text
stable
non-expiring during review
no inaccessible OTP
no biometric requirement
no IP whitelist
```

Nếu reviewer cần Plus:

- pre-provision via trusted backend/admin flow;
- không hard-code bypass trong production app.

## 9.4. App Access instructions

Viết step-by-step:

```text
1. Open app
2. Sign in
3. Complete/skip required onboarding
4. Open Dashboard
5. Open AI
6. Use Report
7. Open Sleep Safety
8. Open Membership
9. Open Settings/Delete account
```

Nếu account bị paywall/role lock:

- instructions phải rõ.

Không ghi reviewer password vào Git.

## PASS

```text
STORE_LISTING_REVIEW_PASS
REVIEWER_ACCESS_PASS
```

---

# PHASE 10 — FINAL RELEASE AAB

## Chỉ chạy sau khi source/backend behavior ổn định

Nếu source thay đổi sau build → AAB cũ invalid.

## 10.1. Versioning

Đọc highest Play Console versionCode.

Nếu `1` đã upload:

- dùng `2` hoặc số lớn hơn current highest.

Không reuse.

## 10.2. Clean build

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release
```

Nếu release env cần defines:

```bash
flutter build appbundle --release \
  --dart-define=PRIVACY_POLICY_URL=https://... \
  --dart-define=ACCOUNT_DELETION_URL=https://...
```

Kèm public Supabase config theo mechanism repo.

Không truyền secret client-side.

## 10.3. AAB inspection

Verify:

- package `com.nanobioai.app`;
- target 36;
- compile 36;
- minSdk expected;
- versionName;
- versionCode;
- Billing 8.x;
- no broad media permission;
- FGS permissions intended;
- exact alarm only if justified;
- legal URLs present;
- no secrets;
- no localhost/private dev host;
- no direct Gemini key;
- no service-role key;
- native page alignment;
- signing metadata.

## 10.4. Secret scan

Search source + unzipped artifact markers:

```text
AIza
service_role
BEGIN PRIVATE KEY
sk-
localhost
127.0.0.1
10.0.2.2
internal-only domain
reviewer password
real purchase token
```

False positive phải được documented.

## 10.5. SHA

Generate:

```bash
sha256sum build/app/outputs/bundle/release/app-release.aab
```

Windows:

```powershell
Get-FileHash build\app\outputs\bundle\release\app-release.aab -Algorithm SHA256
```

Record:

```text
versionName
versionCode
bytes
SHA256
signer
build timestamp
```

## PASS

`FINAL_AAB_ARTIFACT_PASS`.

---

# PHASE 11 — PLAY APP SIGNING + INTERNAL TESTING

## 11.1. Play App Signing

Verify in Console:

- enabled;
- upload certificate SHA-256;
- app signing certificate SHA-256;
- package accepted.

Không expose private key.

## 11.2. Upload exact final AAB

Internal Testing upload must correspond to exact:

```text
versionCode
SHA256
```

from Phase 10.

If Play rejects bundle, capture exact warning/error.

Fix root cause, rebuild, and invalidate old evidence.

## 11.3. Internal testing E2E

Fresh install from Play Internal Testing, not local APK.

Flow:

```text
install
→ launch
→ guest/onboarding
→ sign-up/login
→ dashboard
→ health profile
→ meal
→ schedule
→ notification
→ camera/gallery
→ AI generation
→ AI report
→ Sleep Safety deny
→ Sleep Safety allow/start/stop
→ membership purchase
→ entitlement
→ logout/login
→ restore
→ account deletion
```

## 11.4. Device coverage

At least:

- Android 14;
- Android 15;
- Android 16.

Where possible:

- physical low/mid device;
- 16 KB device/emulator.

## 11.5. Pre-launch report

Review:

- crash;
- ANR;
- permission issue;
- accessibility;
- security;
- policy warnings.

Any core-flow crash/ANR:

```text
NO-GO
```

## PASS

```text
PLAY_APP_SIGNING_PASS
INTERNAL_TRACK_PASS
```

---

# PHASE 12 — PLAY CONSOLE DECLARATIONS

Luna phải prepare exact final answers, but only mark PASS when actually submitted/verified.

## 12.1. Privacy Policy

- live URL entered;
- matches final app;
- opens.

## 12.2. Account deletion

- outside-app URL entered;
- in-app path stated;
- opens.

## 12.3. Data Safety

Cross-check with final AAB and deployed providers.

No checkbox based on assumptions.

## 12.4. Health Apps

Complete final health categories.

## 12.5. Foreground Service

Complete microphone FGS declaration + video.

## 12.6. App Access

Reviewer credentials/instructions saved in Console.

## 12.7. Ads declaration

If no ads:

- declare consistently with actual SDK inventory.

If ads later discovered:

- stop and update Data Safety/policy.

## 12.8. Content rating / target audience

Review final Console states against actual app.

## PASS

`PLAY_CONSOLE_PASS` only after screenshots/evidence.

---

# PHASE 13 — FINAL GO / NO-GO AUDIT

Luna phải build final release table.

| Gate | Required | Evidence | Status tại lúc lập plan |
|---|---:|---|---|
| API 36 | Yes | AAB/Gradle local | `ARTIFACT_PASS` |
| Billing 8 | Yes | dependency/AAB + source tests | `SOURCE_PASS` |
| Full suite regression risk | Yes | `978 PASS / 236 FAIL` + shutdown error | `FAIL` |
| Supabase RLS runtime | Yes | canonical SQL/static contracts | `BLOCKED_EXTERNAL` |
| AI generate runtime | Yes | source/handler tests; no deployed HTTP | `BLOCKED_EXTERNAL` |
| AI report runtime | Yes | source/UI/handler tests; no deployed HTTP | `BLOCKED_EXTERNAL` |
| Account deletion | Yes | source lifecycle/contract tests | `BLOCKED_EXTERNAL` |
| Privacy live | Yes | publish-ready page; no public HTTPS URL | `BLOCKED_EXTERNAL` |
| Deletion web live | Yes | publish-ready page; no public HTTPS URL | `BLOCKED_EXTERNAL` |
| Data Safety | Yes | mapping draft only | `BLOCKED_EXTERNAL` |
| Health Apps | Yes | declaration draft only | `BLOCKED_EXTERNAL` |
| FGS mic device | If shipped | manifest/source only | `BLOCKED_EXTERNAL` |
| FGS declaration | If shipped | declaration draft only | `BLOCKED_EXTERNAL` |
| Exact alarm safe | If permission kept | reachability decision pending | `PLANNED` |
| Billing purchase | If Plus shipped | no Internal Play evidence | `BLOCKED_EXTERNAL` |
| App Access | If login/gated | no Console evidence | `BLOCKED_EXTERNAL` |
| Play App Signing | Yes | local signer only | `BLOCKED_EXTERNAL` |
| 16 KB runtime | Strongly required for future-proof release | local ELF alignment only | `BLOCKED_EXTERNAL` |
| Store claims | Yes | review draft only | `PLANNED` |
| Internal E2E | Yes | no Play install evidence | `BLOCKED_EXTERNAL` |
| Final AAB | Yes | local SHA/version record | `ARTIFACT_PASS` |

`Status tại lúc lập plan` là snapshot, không phải kết quả execution. Khi một
gate có source evidence nhưng thiếu runtime/Console evidence, giữ trạng thái
source thấp hơn requirement và ghi rõ blocker; chỉ thay bằng trạng thái runtime
sau khi có command, device, sandbox hoặc Console evidence thật.

## GO criteria

Luna được viết:

```text
GO — READY FOR PRODUCTION REVIEW
```

chỉ khi:

- no P0 open;
- no untriaged P1;
- final AAB accepted by Internal Testing;
- runtime critical flows pass;
- Play Console required declarations complete;
- reviewer can access app.

## NO-GO criteria

Một trong:

- legal URL missing;
- Data Safety incomplete;
- Health Apps incomplete;
- FGS declaration incomplete while mic service shipped;
- real purchase broken while paid plan sold;
- deletion broken;
- Supabase RLS insecure;
- final AAB rejected;
- reviewer cannot login;
- crash/ANR on core flow;
- real production regression in test suite;
- secret exposed.

---

# PHASE 14 — HANDOFF ZIP VÀ ĐÓNG SESSION

## Mục tiêu

Đóng gói đúng các file do execution tạo/sửa, bảo toàn cấu trúc project và không
đưa secret, cache, AAB hoặc log nhạy cảm vào handoff. Phase này không nâng một
gate runtime lên PASS; nó chỉ tạo artifact bàn giao sau khi Phase 13 đã ghi
quyết định GO/NO-GO.

## Điều kiện vào

- Phase 13 đã có gate matrix đầy đủ, không còn ô trống.
- Mọi command/evidence trong final report là kết quả thật của `RUN_ID` hiện tại.
- `git diff --check` đã chạy; file ngoài phạm vi đã được xác nhận là user work.
- Secret scan và danh sách file đóng gói đã được review lần cuối.

## Quy trình

1. Chụp danh sách file tracked đã sửa so với baseline và file untracked do
   execution tạo; không tự đưa file untracked của user vào ZIP.
2. Đối chiếu từng file với mục `EXACT FILE CLUSTERS` và `DO-NOT-TOUCH`.
3. Tạo `changed_files.txt` trong evidence root với project-relative paths.
4. Tạo ZIP theo Section 25 bằng đường dẫn tạm; loại trừ `.git`, build/cache,
   env/keystore/private key, token, patch/diff và log chứa dữ liệu nhạy cảm.
5. Liệt kê ZIP và giải nén thử vào thư mục tạm riêng; kiểm tra path traversal,
   duplicate path, file ngoài allowlist và cấu trúc project.
6. Ghi SHA-256, kích thước, thời điểm tạo và allowlist vào final report/worklog.

## Kết quả hợp lệ

- Có thể tái tạo ZIP từ allowlist mà không phụ thuộc file tạm hoặc credential.
- ZIP `PASS` chỉ có nghĩa package hợp lệ; release vẫn là `NO-GO` nếu Phase 13
  còn gate `BLOCKED_EXTERNAL`/`FAIL`.
- Nếu chưa đủ external gate, dùng tên `SOURCE_READY` hoặc `RELEASE_VERIFY`
  trong handoff; không đặt tên khiến người nhận hiểu là Production GO.

---

# 14. EXACT FILE CLUSTERS LUNA PHẢI QUẢN LÝ

Không mặc định tất cả sẽ được sửa. Chỉ edit khi analysis chứng minh cần.

## Release docs

```text
docs/release/google_play/README.md
docs/release/google_play/RELEASE_EVIDENCE_MATRIX.md
docs/release/google_play/ACCOUNT_DELETION.md
docs/release/google_play/ACCOUNT_DELETION_PUBLIC_PAGE.md
docs/release/google_play/PRIVACY_POLICY_PUBLIC_PAGE.md
docs/release/google_play/DATA_SAFETY_MAPPING.md
docs/release/google_play/HEALTH_APPS_DECLARATION.md
docs/release/google_play/FOREGROUND_SERVICE_DECLARATION.md
docs/release/google_play/STORE_LISTING_CLAIMS_REVIEW.md
```

## Flutter/platform

```text
pubspec.yaml
pubspec.lock
android/app/build.gradle.kts
android/app/src/main/AndroidManifest.xml
lib/core/config/app_env.dart
```

## Membership

Expected cluster:

```text
lib/app_versions/v2/features/paywall/
lib/app_versions/v2/repositories/membership_billing_repository.dart
lib/app_versions/v2/repositories/membership_repository.dart
lib/app_versions/v2/domain/membership/
test/app_versions/v2/features/paywall/
test/app_versions/v2/repositories/membership_billing_repository_test.dart
```

## Backend/Supabase

```text
docs/supabase/README.md
docs/supabase/01_build_system.sql
docs/supabase/02_seed_data.sql
supabase/functions/nabi-ai-generate/
supabase/functions/report-ai-content/
supabase/functions/delete-account/
supabase/functions/google-play-verify-purchase/
```

Use search to discover exact names if current tree differs.

## Sleep/notification

Discover exact active paths with:

```bash
rg "SleepSafety|ForegroundService|SCHEDULE_EXACT_ALARM|zonedSchedule" android lib test
```

## Settings/legal

Discover with:

```bash
rg "PRIVACY_POLICY_URL|ACCOUNT_DELETION_URL|delete account|xóa tài khoản" lib test
```

---

# 15. TEST STRATEGY

## 15.1. Test pyramid

Order:

```text
unit
→ repository
→ controller/provider
→ widget
→ integration
→ backend handler
→ sandbox DB/RLS
→ Android device
→ Play Internal Testing
```

## 15.2. Never skip critical tests

Critical clusters:

- auth;
- deletion;
- billing;
- entitlement;
- RLS;
- AI safety/report;
- Sleep Safety;
- notifications;
- Settings/legal links;
- health safety claims.

## 15.3. No fake network in production tests

Unit test may mock.

Runtime PASS requires real sandbox/Internal Play where stated.

## 15.4. Evidence names

Recommended:

```text
release_validation/
  01_baseline.md
  02_full_test_summary.md
  03_supabase_rls_matrix.md
  04_ai_runtime.md
  05_deletion_e2e.md
  06_billing_internal.md
  07_fgs_device_matrix.md
  08_aab_metadata.md
  09_internal_e2e.md
  10_console_checklist.md
```

Prefer existing `docs/release/google_play/` conventions instead of new folder if repo rules favor them.

---

# 16. ROLLBACK STRATEGY

## Flutter/package regression

If dependency/runtime change causes regression:

1. identify exact change;
2. revert only Luna-owned change;
3. preserve current Billing 8 baseline unless proven culprit;
4. rerun targeted tests.

## Supabase

Never rollback with production reset.

Use:

- reversible SQL;
- sandbox first;
- migration-safe changes;
- explicit rollback script if schema modified.

## Play Console

Do not delete working products/tracks just to retry.

Use new versionCode for new AAB.

## Legal

Do not publish guessed legal text.

If approval missing:

```text
BLOCKED_EXTERNAL
```

---

# 17. CHANGE CONTROL

Before editing any file Luna phải ghi internal:

```text
WHY
SOURCE_OF_TRUTH
EXPECTED_BEHAVIOR
TEST
ROLLBACK
```

Sau edit:

```text
FILE
CHANGE
TEST_RESULT
EVIDENCE
STATUS
```

Không refactor ngoài phạm vi release.

---

# 18. RELEASE DOCUMENTATION UPDATE RULE

Sau mỗi phase đã verify, update:

```text
docs/release/google_play/RELEASE_EVIDENCE_MATRIX.md
```

Không ghi `PASS` khi evidence không tồn tại.

Cuối session substantial:

1. worklog;
2. `.codex/history/OPEN_RISKS.md`;
3. history refresh script.

Worklog phải ghi:

- completed;
- blocked;
- commands;
- evidence;
- test result;
- self-review.

---

# 19. EXTERNAL BLOCKER HANDLING

Nếu Luna thiếu:

- Play Console;
- Supabase credentials;
- domain hosting;
- physical Android;
- legal identity;
- retention decision;

thì KHÔNG dừng toàn task ngay.

Luna phải:

1. hoàn thành mọi source/runtime phần có thể;
2. tạo exact checklist;
3. mark blocker;
4. tiếp tục phase độc lập;
5. kết luận:

```text
IMPLEMENTATION_COMPLETE
RELEASE_VERIFICATION_BLOCKED_EXTERNAL
```

Không nói app đã Production PASS.

---

# 20. SECURITY REVIEW TRƯỚC FINAL BUILD

Run source scan cho:

- API key;
- service role;
- private key;
- hard-coded password;
- raw purchase token;
- JWT;
- real user email/health data;
- insecure cleartext;
- debug endpoints.

Review:

```text
android:usesCleartextTraffic
exported components
deep links
WebView nếu có
file providers
storage
logs
```

Ensure:

- no sensitive raw logs;
- no user health payload in debug release logs;
- no secrets in crash strings.

---

# 21. QUALITY GATES CHO USER EXPERIENCE

Google Play có thể reject broken app dù policy declarations đúng.

Luna phải test:

## Auth

- fresh register;
- confirm email flow nếu required;
- login;
- logout;
- expired session;
- offline startup.

## Onboarding

- required fields;
- back;
- resume;
- no duplicate initial plan.

## Dashboard

- no infinite loading;
- empty state;
- real data.

## AI

- timeout;
- quota;
- report.

## Membership

- product load failure;
- purchase success;
- restore.

## Settings

- privacy link;
- deletion link;
- delete account.

## Notifications

- permission denied;
- scheduling;
- tap action;
- boot restore.

## Camera

- denied;
- picker cancel;
- no broad media permission.

## Sleep Safety

- all FGS cases.

Any core feature crash → NO-GO.

---

# 22. POLICY REFERENCES LUNA PHẢI RECHECK NGAY TRƯỚC EXECUTION

Vì Google Play policy thay đổi, Luna không được chỉ tin plan.

Official sources tối thiểu:

```text
Target API:
https://support.google.com/googleplay/android-developer/answer/11926878

Billing deprecation:
https://developer.android.com/google/play/billing/deprecation-faq

User Data / account deletion:
https://support.google.com/googleplay/android-developer/answer/13327111

Health Apps declaration:
https://support.google.com/googleplay/android-developer/answer/14738291

Foreground service:
https://support.google.com/googleplay/android-developer/answer/13392821

Data Safety:
https://support.google.com/googleplay/android-developer/answer/10787469

Prominent disclosure and consent:
https://support.google.com/googleplay/android-developer/answer/11150561

16 KB page size:
https://developer.android.com/guide/practices/page-sizes
```

Nếu current policy khác plan:

```text
CURRENT OFFICIAL POLICY WINS
```

và worklog phải ghi thay đổi.

Current planning snapshot ngày 2026-08-29:

- API 36 bắt buộc cho new app/update từ 2026-08-31.
- Billing 8 có deadline dùng cho new app/update là 2027-08-31 (extension deadline: 2027-11-01).
- Health Apps declaration áp dụng cho app trên closed/open/production.
- Account creation app cần in-app deletion + outside-app web resource.
- Android 14+ yêu cầu khai báo foreground-service type và Play Console declaration/video khi dùng FGS.
- Android 15 hỗ trợ thiết bị page size 16 KB; coi device/Play check là gate future-proof và xác nhận deadline hiện hành ngay trước submission.

Các mốc trên là planning snapshot, không thay thế việc mở lại nguồn chính thức
ở thời điểm execution. Nếu trang chính thức thay đổi wording, deadline hoặc
đường dẫn, cập nhật plan/worklog theo nguồn mới trước khi đánh giá gate.

---

# 23. DEFINITION OF DONE THEO TỪNG ISSUE

## GP-001 Billing Library

Current:

```text
ALREADY SOURCE PASS
```

Done khi:

```text
Billing 8 dependency retained
+ real Internal Play purchase PASS
```

## GP-002 Health Apps

Done:

```text
claims reviewed
+ disclaimer consistent
+ declaration submitted
+ screenshots/listing consistent
```

## GP-003 Privacy/Data Safety

Done:

```text
live privacy URL
+ in-app link
+ final provider/retention wording
+ Data Safety submitted
```

## GP-004 Foreground Mic

Done:

```text
correct Android service
+ Android 14/15/16 runtime
+ visible notification
+ user stop
+ FGS Console declaration/video
```

## GP-005 Account Deletion

Done:

```text
in-app
+ server
+ DB
+ storage
+ local
+ session invalidation
+ outside-app live URL
+ Play Console URL
```

## GP-006 Reviewer Access

Done:

```text
review account
+ instructions
+ gated feature access
+ fresh-install dry-run
```

## GP-007 AI Report

Done:

```text
UI report
+ deployed function
+ DB persistence
+ RLS
+ retry/error
```

## GP-008 Supabase

Done:

```text
canonical rebuild
+ RLS matrix
+ functions
+ replay
+ isolation
```

## GP-009 Full Tests

Done:

```text
0 untriaged
0 real reachable regression
0 suppressed shutdown error
```

## GP-010 Exact Alarm

Done:

```text
permission justified or removed
+ capability/fallback
+ Android runtime
```

---

# 24. FINAL REPORT FORMAT LUNA PHẢI TRẢ

Sau khi thực thi, response cuối phải có đúng các nhóm:

## A. Final status

```text
GO
hoặc
NO-GO
hoặc
IMPLEMENTATION COMPLETE / BLOCKED_EXTERNAL
```

## B. Current release

```text
HEAD
versionName
versionCode
AAB SHA256
package
targetSdk
Billing version
```

## C. Gate matrix

Tất cả gate + evidence + status.

## D. Files changed

Project-relative paths.

## E. Commands/tests

Chỉ ghi lệnh thật đã chạy + kết quả thật.

## F. External blockers

Exact user action còn cần.

## G. Play Console actions

Exact checklist.

## H. Risks

Không giấu known risk.

---

# 25. ZIP HANDOFF BẮT BUỘC

Chỉ tạo ZIP sau khi hoàn tất execution và Phase 13 đã ghi kết luận. Phiên hoàn
thiện plan này không tạo ZIP release và không được dùng ZIP cũ làm evidence cho
source thay đổi sau đó.

Tạo ZIP chứa CHỈ:

- file mới;
- file đã sửa;

giữ nguyên project-relative structure.

Tên đề xuất:

```text
NanoBioAI_GOOGLE_PLAY_FINAL_PASS_<YYYYMMDD>.zip
```

Không đưa vào ZIP:

```text
.git/
build/
.dart_tool/
.gradle/
.env
key.properties
*.jks
*.keystore
service account JSON
private keys
API keys
raw test tokens
temporary logs chứa sensitive data
patch files
diff files
```

Mặc định không đưa file plan vào ZIP. Nếu handoff request yêu cầu bàn giao cả
plan, đưa đúng file này và ghi rõ đó là tài liệu kế hoạch, không phải evidence
runtime.

ZIP phải giải nén ra đúng cấu trúc dự án.

---

# 26. EXECUTION CHECKPOINTS

Luna không cần xin phép lại cho từng file sau khi user đã xác nhận plan.

Nhưng phải dừng/mark blocked nếu cần business/legal decision không thể suy ra.

Checkpoint nội bộ:

```text
CP0 Baseline safe
CP1 Test risks classified
CP2 Backend trusted
CP3 Deletion trusted
CP4 Billing trusted
CP5 Legal/data declarations ready
CP6 Android FGS trusted
CP7 Final artifact trusted
CP8 Internal Track trusted
CP9 Console trusted
CP10 Release GO
```

---

# 27. ƯU TIÊN NẾU KHÔNG THỂ HOÀN THÀNH MỌI THỨ TRONG MỘT SESSION

Không bỏ dở ngẫu nhiên.

Priority:

```text
1. Security/data-loss/rejection blockers
2. Supabase RLS
3. Account deletion
4. Billing trust
5. FGS microphone
6. Privacy/Data Safety/Health
7. Full test regressions
8. Final AAB
9. Internal track
10. Console paperwork
```

Mỗi session phải để repo ở trạng thái buildable hoặc rollback change chưa ổn.

---

# 28. SUCCESS STATE MONG MUỐN

Task chỉ được xem hoàn thành khi evidence cuối tương đương:

```text
[PASS] target/compile API 36
[PASS] Billing Client 8.x
[PASS] no client secret
[PASS] full test risk closed
[PASS] Supabase RLS isolation
[PASS] AI generation runtime
[PASS] AI report runtime
[PASS] account deletion E2E
[PASS] privacy URL live
[PASS] deletion URL live
[PASS] Data Safety
[PASS] Health Apps
[PASS] Sleep Safety Android 14/15/16
[PASS] FGS declaration
[PASS] exact alarm safe
[PASS] real Google Play purchase
[PASS] restore/cancel/expiry
[PASS] reviewer App Access
[PASS] Store Listing claims
[PASS] Play App Signing
[PASS] final AAB accepted
[PASS] Internal Testing E2E
[PASS] no critical Pre-launch report issue
```

Sau đó mới kết luận:

```text
NANOBIOAI — READY FOR GOOGLE PLAY PRODUCTION REVIEW
```

Lưu ý: `READY FOR PRODUCTION REVIEW` không đồng nghĩa Google đảm bảo phê duyệt; nó có nghĩa toàn bộ known gate kỹ thuật/chính sách đã có evidence đủ để submit một cách hợp lý.

---

# 29. LỆNH KHỞI ĐỘNG DÀNH CHO GPT-5.6 LUNA SAU KHI USER XÁC NHẬN

Khi user nói:

```text
thực thi plan
```

Luna phải bắt đầu từ:

```text
PHASE 0
```

Không lập lại plan từ đầu.

Không hỏi lại những dữ liệu đã có trong form/user context.

Nếu thiếu external input, ghi blocker và tiếp tục phần độc lập.

Không push/commit bất kỳ secret nào.

Không tuyên bố Production PASS trước PHASE 13.

---

# 30. CURRENT PLAN VERDICT

Tại thời điểm lập plan:

```text
SOURCE: largely PASS
LOCAL AAB: PASS
PRODUCTION RUNTIME: PARTIAL
PLAY CONSOLE: OPEN
FINAL VERDICT: NO-GO
```

Trạng thái của chính tài liệu sau phiên hoàn thiện này:

```text
PLAN: COMPLETE / EXECUTION-READY
RELEASE: NO-GO UNTIL ALL REQUIRED GATES HAVE REAL EVIDENCE
NEXT ACTION: USER CONFIRMS EXECUTION → START PHASE 0
```

Đích của execution:

```text
FINAL VERDICT: GO — READY FOR PRODUCTION REVIEW
```
