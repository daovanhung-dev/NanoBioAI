# Tài liệu chức năng hệ thống NanoBioAI

## 1. Phạm vi và baseline

- Baseline source: Git HEAD `25018e8` tại ngày 2026-08-24.
- Entrypoint duy nhất: `lib/main.dart`.
- Mức xác minh của tài liệu này: `Static-verified` theo source/config.
- Flutter runtime, thiết bị thật và Supabase sandbox: `UNVERIFIED` nếu không có
  command evidence riêng trong báo cáo audit.
- Source reachable có ưu tiên cao hơn BD/DD, README, worklog và manifest cũ.

Trạng thái capability:

| Trạng thái | Ý nghĩa |
| --- | --- |
| `Implemented` | Có consumer/route reachable và xử lý thật trong source. |
| `Partial` | Có đường chạy thật nhưng mới bao phủ một phần capability. |
| `Placeholder` | Chỉ có shell, preview hoặc thông báo “Sắp có”. |
| `Source-only` | Source/schema tồn tại nhưng không được app reachable sử dụng. |
| `Absent` | Không có source implementation. |

`Implemented` không đồng nghĩa với runtime, device hoặc sandbox đã PASS.

## 2. Bootstrap, surface và router

### 2.1 Bootstrap

`lib/main.dart` thực hiện:

1. `WidgetsFlutterBinding.ensureInitialized()`.
2. Nạp `AppEnv` theo chế độ tùy chọn.
3. Khởi tạo Supabase chỉ khi có đủ `SUPABASE_URL` và
   `SUPABASE_ANON_KEY`.
4. Tạo `ProviderScope` và override backend availability cùng onboarding
   completion callback.
5. Chạy `BioAIApp`.
6. Sau launch, bật cloud sync/meal-catalog refresh nếu Supabase sẵn sàng và
   khởi động local notifications theo cơ chế fail-safe.

Thiếu Supabase config trả về
`AuthBackendAvailability.missingConfiguration`; app vẫn mở user surface ở guest
mode. Auth/cloud/membership/quota/payment/Admin/Sale không được coi là hoạt
động khi backend chưa sẵn sàng.

### 2.2 Chọn surface

`lib/app/bio_ai_app.dart` chọn:

- `BioAIV2App` cho guest hoặc user thông thường.
- `BioAIAdminApp` chỉ khi đã đăng nhập và
  `adminAccessControllerProvider` xác nhận quyền Admin.
- Màn hình resolving trung tính trong lúc auth/admin identity đang được resolve.

Admin không phải entrypoint riêng. `lib/main_v2.dart`, `lib/main_v3.dart` và
`lib/main_admin.dart` đều không tồn tại.

### 2.3 Router

- User router: `v2RouterProvider` tại
  `lib/app_versions/v2/router/v2_router.dart`.
- Route list user được compose từ `v1Routes`, `v2Routes`, `v3Routes`.
- Admin dùng `adminRouter` riêng sau khi root app chọn Admin surface.
- Initial location của user router là `/` (Splash).

V1 guest allowlist cho onboarding/basic routes. Các route V1 cần đăng nhập gồm
AI chat, AI voice, nutrition, nutrition profile và profile. V2/V3/Sale/payment
routes được bảo vệ tại router và/hoặc provider-level access gate; entitlement
paid phải được đọc từ backend.

## 3. Runtime configuration và platform identity

### 3.1 AppEnv

`lib/core/config/app_env.dart` resolve giá trị theo thứ tự:

1. Dart define.
2. dotenv tùy chọn.
3. native runtime config.
4. bundled public auth config.

`assets/config/auth.env` chỉ cho các public auth key đã allowlist. Gemini key
không được đọc từ asset đó.

### 3.2 Gemini

- Transport: client REST nội bộ
  `lib/app_versions/v1/services/ai/gemini_rest_client.dart`.
- Endpoint mặc định: `https://generativelanguage.googleapis.com/v1beta`.
- Request: `models/{model}:generateContent` hoặc stream endpoint tương ứng.
- Auth: header `x-goog-api-key`.
- Dự án không có dependency `google_generative_ai`; mọi mô tả “Gemini SDK
  0.4.7” là lỗi thời.
- Plan model mặc định: `gemini-3.1-flash-lite`, có danh sách fallback trong
  `AIModelCandidates`.
- Chat model mặc định: `gemini-3.1-flash-lite`, có danh sách fallback riêng
  trong `AIChatModelCandidates`.

Android có native fallback `BuildConfig.GEMINI_API_KEY`; iOS hiện không có
native handler tương ứng trong source. Dart define vẫn là nguồn ưu tiên.

### 3.3 Identity hiện tại

| Platform | Identity/name theo config |
| --- | --- |
| Android | namespace/application ID `com.nanobioai.app`, label `NanoBio` |
| iOS | bundle ID `com.example.nanoApp`, display/name `NaBi` |
| Dart package | `nano_app` |

Không dùng package channel legacy `com.example.nano_app/runtime_config` để suy
ra Android application ID; channel này chỉ là tên giao tiếp Dart/Kotlin.

## 4. V1 guest/basic và shared user experience

### 4.1 Splash và onboarding — `Implemented`

Evidence chính:

- `lib/app_versions/v1/features/splash/`
- `lib/app_versions/v1/features/onboarding/`
- `lib/core/constants/onboarding_constants.dart`

`OnboardingCatalog.totalSteps = 9`. UI map step như sau:

0. Welcome.
1. Basic info.
2. Goals.
3. Conditions.
4. Lifestyle.
5. Extras.
6. Daily routine.
7. Consent.
8. Review.

`ResultStep` có source nhưng không nằm trong switch 9 bước hiện hành, nên không
được tính là bước thứ 10.

Khi hoàn tất onboarding, callback tại `lib/main.dart` chuẩn bị meal catalog và
gọi `GeneratedPlanService.generateInitialGuestPlan(days: 7)`. Việc catalog
hoặc AI generation thất bại phải được xử lý theo source; tài liệu không được
giả định luôn thành công.

### 4.2 Dashboard, lịch và dữ liệu local — `Implemented/Partial`

Các route/source reachable gồm:

- Dashboard/menu và settings tab.
- Meal plan và nutrition.
- Lifestyle schedule, today tasks và daily routine preferences.
- Daily health tracking, water tracking, body metrics, weekly summary.
- Quick care, gentle care và Nabi surfaces.

SQLite là nguồn local-first chính. Schema runtime là
`DatabaseVersion.currentVersion = 20` tại
`lib/core/storage/localdb/database_version.dart`.

Một route có UI không tự chứng minh mọi thao tác business hoàn chỉnh. Ví dụ
personal goals ghi rõ chỉ preview và không persistence.

### 4.3 Placeholder V1

| Capability | Trạng thái | Evidence |
| --- | --- | --- |
| Sleep tracking | `Placeholder` | `MedicalComingSoonPage` |
| Stress tracking | `Placeholder` | `MedicalComingSoonPage` |
| Community | `Placeholder` | `MedicalComingSoonPage` |
| Personal goals persistence | `Placeholder` | UI nói lựa chọn không được lưu |

### 4.4 Notification — `Implemented` cho M09, `Source-only` cho M30

- M09 schedule reminder được bootstrap từ `lib/main.dart` qua
  `NotificationBootstrap`, lifecycle refresher và startup scheduler.
- Các action complete/skip và navigation có source trong V1 notification
  services.
- M30 có SQLite tables, models, engine, controller và repositories dưới
  `lib/features/nabi/`.
- Không có consumer của `nabiNotificationControllerProvider` reachable từ UI
  hoặc bootstrap tại baseline, nên M30 không được ghi là active runtime.

## 5. AI plan, chat và voice

### 5.1 Personal plan — `Implemented`

`AIService` dùng Gemini REST khi có client/key. Nếu thiếu key, plan generation
có local fallback dựa trên catalog. Output AI đi qua parser, validator và
normalizer trước khi ghi meal/schedule data.

`GeneratedPlanService` phân biệt initial guest plan và member regeneration.
Luồng member kiểm tra/commit quota qua trusted backend gateway; initial guest
plan không được mô tả như một lần member quota.

### 5.2 AI chat — `Partial`

- Route `/ai-chat` cần authenticated user.
- `AIChatService` dùng Gemini REST và validate Vietnamese display text.
- Thiếu `GEMINI_API_KEY` làm chat unavailable; chat không dùng local response
  fallback như plan generation.
- `AIChatRepositoryImpl` dùng `TrustedBackendUsageQuotaGateway` cho quota.
- History ở từng model session được giới hạn trong source; chỉ turn đã accept
  mới được nhớ.

Static source không chứng minh live Gemini request hoặc quota RPC đã PASS.

### 5.3 AI voice — `Partial`

Route `/ai-voice` cần auth và `AiVoiceAccessGate` đọc effective access. Source
có speech-to-text, text-to-speech và tái sử dụng chat service; permission,
thiết bị và live backend vẫn cần runtime verification.

## 6. V2 authenticated capabilities

| Capability | Trạng thái | Source truth |
| --- | --- | --- |
| Auth lifecycle | `Implemented` | Login/register/verify/recovery/reset/callback, controller, repository và Supabase datasource có route runtime. |
| Cloud sync | `Implemented/Partial` | Local/remote datasource, merge repository, startup/refresh triggers có source; cần backend để E2E. |
| Effective membership access | `Implemented` | `effectiveAccessProvider` đọc trusted Supabase contract. |
| AI usage quota | `Implemented` | Chat và plan dùng trusted check/commit RPC gateways. |
| `personal_schedule_quota` marker | `Source-only` | File marker khai báo `planned`; runtime quota thật nằm ở generated-plan/gateway source khác. |
| Health score habits | `Implemented` | SQLite datasource, calculator, provider và `/v2/health-score`. |
| Manual membership payment | `Partial` | VietQR/request/transfer-confirm flow có source; approval thành công thuộc backend/Admin. |
| Wellness Rewards | `Partial` | Route, local/remote datasource, secure voucher store và redeem contract có source; cần RPC/policy runtime. |
| V2 home | `Implemented` shell | Route `/v2` hiển thị entry points, không phải bằng chứng mọi child capability hoàn chỉnh. |

Auth backend thiếu hoặc init lỗi phải fail closed cho authenticated capability,
không được tạo fake session/local entitlement.

## 7. M20-M29 advanced health catalog

`advancedHealthFeatureCatalog` khai báo đúng 10 module M20–M29. Feature Hub
hiển thị section “Theo dõi chuyên sâu”; detail route dùng
`HealthModuleAccessResolver` để trả login/upgrade/coming-soon/unavailable.

Toàn bộ M20–M29 hiện là `Placeholder`: catalog card, tier label, preview và
coming-soon page. Không có business persistence, measurement flow hoặc AI
health-trend implementation cho từng module. Không có M30 trong catalog này.

## 8. V3 Plus/FamilyPlus

V3 không thể gắn một trạng thái duy nhất:

| Capability | Trạng thái | Evidence |
| --- | --- | --- |
| V3 home | `Placeholder` | `/v3` liệt kê các card “Sắp có”. |
| Advanced tracking M10 | `Partial` | `/v3/advanced-tracking`, paid access gate, SQLite repository và hydration roadmap. |
| FamilyPlus M11 | `Partial` | `/v3/familyplus`, trusted entitlement, Supabase repository/RPC và group/member context UI. |
| Premium AI | `Source-only` | marker class `status = 'planned'`, không có route/consumer. |
| Goal roadmap marker | `Source-only` | marker class `planned`; không phải M10 runtime implementation. |
| Advanced health tracking marker | `Source-only` | marker class `planned`; không phải catalog M20–M29 implementation. |
| Family onboarding/members/schedule markers | `Source-only` | các marker `planned`, không có route/consumer riêng. |

Advanced tracking và FamilyPlus chỉ mở dữ liệu sau provider-level backend
access checks. Route tồn tại không được dùng để kết luận user Free có paid
access.

## 9. Sale/referral

Sale/referral là role axis độc lập, không phải membership plan.

`Partial` theo static source:

- `/v2/sale` mở `SaleShellPage` sau authenticated route guard.
- Repository/datasource đọc Sale state, payout profile, dashboard, direct
  customers, point ledger và conversion qua Supabase RPC.
- Sale registration tạo pending request; active code cần backend/Admin approval.
- Direct commission policy là direct-only; Flutter không được tự xác nhận
  payment success hoặc tự tạo commission.
- Payment-event marker dưới `lib/sale_referral/features/payment_events/` vẫn
  `planned`.

## 10. Admin

Admin surface là `Partial` và backend-dependent:

- Root app chọn Admin sau trusted role resolution.
- `adminRouter` có dashboard, users, payments, sales, sale conversions,
  Wellness Rewards, reconciliation, plans, reports, audit và config routes.
- `AdminAccessGate` fail closed khi permission/session không hợp lệ.
- Mutations đi qua repository/datasource/RPC, kèm permission/reason/idempotency
  theo contract source; Flutter không chứa service-role key.

Không có evidence sandbox trong tài liệu này, vì vậy không ghi các Admin RPC
hoặc RLS là runtime PASS.

## 11. Device services và source-only utilities

| Service | Trạng thái |
| --- | --- |
| Image picker/camera | `Implemented/Partial`: camera path được lifestyle schedule dùng để lưu proof; gallery/avatar helpers chưa có caller reachable được xác nhận. |
| Biometric service | `Source-only`: service wrapper và platform permission có source nhưng không có caller trong app runtime. |
| Design-system demo | `Source-only`: `DesignSystemDemoPage` tồn tại nhưng không được router/main đăng ký. |
| Legacy AI Chat FAB | `Partial`: `DraggableAIChatButton` dùng `AIChatFAB` trên standalone dashboard; MainNavigation dùng Nabi floating overlay thay vì gắn FAB trực tiếp. |

## 12. Supabase Edge Function xóa tài khoản

`supabase/functions/delete-account/` là `Implemented` theo static source:

- Chỉ chấp nhận `POST` (ngoài preflight `OPTIONS`).
- Cần `Authorization` hợp lệ và body `{ "confirm": true }`.
- User ID lấy từ JWT qua Supabase Auth; request không được chọn user cần xóa.
- Service-role key chỉ đọc trong Edge runtime để gọi Admin delete-user API.
- Error response không lộ user ID hoặc backend detail.
- `supabase/config.toml` đặt `verify_jwt = true`.

Deploy/Deno live test vẫn là `Sandbox-unverified` nếu chưa có command evidence.

## 13. Kiến trúc và dữ liệu tin cậy

Dependency flow mục tiêu:

```text
Presentation
  -> Provider / Controller
  -> Repository
  -> Datasource
  -> DAO / Supabase RPC / external service
```

Các dữ liệu sau không được tin từ route param, SharedPreferences hoặc local
flags: membership, quota, FamilyPlus, Sale status, referral tree, payment
success, commission và Admin permission.

Local user-owned data phải được scope theo actor/subject đã resolve. FamilyPlus
cross-subject access phải đi qua trusted backend và `SubjectAccessContext`.

## 14. Validation và acceptance

Static acceptance tối thiểu:

```powershell
python tools/validate_docs_source_truth.py
python tools/audit_supabase_runtime_contract.py
python tools/build_supabase_rebuild_config.py --check
python tools/validate_meal_sync.py
python tools/validate_meal_catalog.py
python tools/validate_kinetic_aura.py
git diff --check
```

Khi tool có sẵn, chạy thêm:

```powershell
flutter test test/docs
powershell -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1
```

Flutter/device/Supabase sandbox chưa chạy phải ghi `UNVERIFIED`. Test hoặc
manifest lịch sử không được chuyển thành PASS cho baseline hiện tại nếu chưa
được chạy lại.

## 15. Evidence index

- Bootstrap: `lib/main.dart`, `lib/app/bio_ai_app.dart`.
- User router: `lib/app_versions/v2/router/v2_router.dart`.
- V1 routes: `lib/app_versions/v1/router/v1_router.dart`.
- V3 routes: `lib/app_versions/v3/router/v3_router.dart`.
- Admin routes: `lib/app_versions/admin/router/admin_router.dart`.
- AppEnv: `lib/core/config/app_env.dart`.
- AI REST: `lib/app_versions/v1/services/ai/gemini_rest_client.dart`.
- Onboarding count: `lib/core/constants/onboarding_constants.dart`.
- SQLite version: `lib/core/storage/localdb/database_version.dart`.
- Advanced catalog: `lib/shared/health_features/health_feature_catalog.dart`.
- Package/dependency truth: `pubspec.yaml`, `pubspec.lock`.
- Platform identity: `android/app/build.gradle.kts`,
  `android/app/src/main/AndroidManifest.xml`,
  `ios/Runner.xcodeproj/project.pbxproj`, `ios/Runner/Info.plist`.
