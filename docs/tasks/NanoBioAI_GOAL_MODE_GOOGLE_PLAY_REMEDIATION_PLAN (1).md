# NanoBioAI — Google Play Release Remediation Execution Plan

> **Execution target:** Codex Goal Mode
> **Model tuning:** GPT-5.6 Luna
> **Repository:** `daovanhung-dev/NanoBioAI`
> **Branch:** `main`
> **Baseline commit:** `29f9b8611aef73e82bdcd3da62512fd8506107c7`
> **Primary input:** `GOOGLE_PLAY_RELEASE_BLOCKERS_2026-08-27.md`
> **Current audit verdict:** `NO-GO`
> **Primary workflow:** `.codex/workflows/fix-issues.md`
> **Primary project rules:** `AGENTS.md` → `.codex/AGENTS.md`
> **Purpose:** close all source-code blockers and produce auditable evidence for the artifact/Play Console gates required before Google Play production submission.

---

# 0. EXECUTION CONTRACT FOR CODEX GOAL MODE

## 0.1 Persistent Goal

Bring NanoBioAI from **Google Play release status `NO-GO` to `SOURCE-READY / RELEASE-VERIFY`**, then complete all verifiable local/sandbox checks required for a final `GO/NO-GO` review.

The task is **not considered complete merely because code compiles**. Completion requires:

1. P0-01 digital membership purchase path is Google Play Billing compliant for Play-distributed Android builds, unless a documented and approved alternative-billing program is supplied by the repository/user.
2. P0-02 every AI-generated chat response has an in-app report/flag flow that actually reaches a persistent moderation/reporting backend.
3. Android release build deterministically targets API 36 or later.
4. Broad photo permission is removed unless current runtime source proves it is genuinely required as core functionality.
5. Production Android client no longer embeds a reusable Gemini API secret.
6. Supabase membership/quota/payment/referral/RLS behavior is validated in local/sandbox/staging with negative authorization tests.
7. Account deletion is demonstrated to delete/anonymize associated user data according to an explicit retention matrix.
8. Foreground microphone service, 16 KB native compatibility, release AAB, and other artifact-level checks are verified where the environment permits.
9. Repository-side source-of-truth artifacts for Privacy/Data Safety/Health/Account Deletion/Play Console declarations are prepared, while Play Console-only actions remain explicitly marked `MANUAL` until verified externally.
10. Final evidence matrix contains no unresolved P0 and no unacknowledged P1.

## 0.2 Non-negotiable project constraints

Codex MUST obey these rules throughout execution:

- Read `AGENTS.md` and `.codex/AGENTS.md` before modifying code.
- Use current reachable source as the highest implementation truth.
- Preserve project architecture:
  `Presentation → Provider/Controller → Repository → Datasource → DAO/API`.
- UI must not call Google Billing, Supabase tables, Edge Functions, Gemini, or persistence APIs directly when a repository/controller boundary exists.
- Do not introduce production mock/fake/sample data.
- Do not hardcode secrets, purchase tokens, service-account JSON, passwords, signing credentials, test cards, or real user health data.
- Do not modify a real `.env` file or commit release credentials.
- Do not replace existing working feature architecture with a new global architecture.
- Do not refactor unrelated code for style while performing release remediation.
- Keep diffs scoped to the blocker being closed.
- Preserve Vietnamese user-facing language and Nabi tone; never expose backend/internal terms such as RPC, RLS, table, exception, API key, entitlement, webhook, purchase token, etc. to end users.
- Do not mark a blocker as fixed without executable evidence.
- Do not infer Play Console state from source code.
- Do not claim device/AAB/Play Console verification if the environment did not actually perform it.
- Do not follow stale documentation over real repository state.

## 0.3 Important source-of-truth correction

`docs/supabase/README.md` currently references a larger SQL sequence that is not present in the current Git tree. At the audited/current HEAD, the actual `docs/supabase/` source tree contains:

- `docs/supabase/01_build_system.sql`
- `docs/supabase/02_seed_data.sql`
- `docs/supabase/README.md`

Therefore:

- Treat `.codex/AGENTS.md` + actual Git tree + `01_build_system.sql` + `02_seed_data.sql` as canonical.
- Do **not** invent phantom SQL files such as `01_schema_rebuild_local_sandbox.sql`, `03_membership_rls.sql`, etc. merely because stale README text mentions them.
- If Supabase documentation is touched, correct `docs/supabase/README.md` to match the real canonical pair.

## 0.4 Default policy/product decision for this plan

Unless the user supplies written proof that NanoBioAI is enrolled in a Google-approved alternative/external billing program for every intended Play market:

> **DEFAULT PATH = Google Play Billing for Plus/FamilyPlus digital membership in Play-distributed Android builds.**

Do not stop to ask whether VietQR should remain the primary consumer purchase path. The release-safe default is Play Billing.

Legacy VietQR/manual review may remain only if all of the following are true:

- it is not offered as an in-app purchase path in the Play-distributed consumer build; and
- it is still required for admin/back-office/non-Play distribution; and
- keeping it does not create ambiguous upgrade navigation that exposes external payment from the Play build.

If these conditions are not satisfied, remove/disable the consumer VietQR path from the release build.

## 0.5 Autonomy boundaries

Codex MAY autonomously:

- read repository files;
- search the repository;
- edit in-scope source/tests/docs;
- add compatible dependencies;
- run format/analyze/test/build commands;
- run local Supabase commands when the project environment is configured;
- create local test fixtures using fake/non-sensitive values;
- build unsigned/debug and locally signed release artifacts if credentials are already available in the environment.

Codex MUST STOP and report a blocked gate before:

- purchasing anything;
- creating/changing paid Google Cloud resources;
- publishing to Production;
- changing real Play Console billing products without explicit authorization;
- rotating/revoking a real production secret;
- destructive changes to production Supabase data;
- widening scope to unrelated modules;
- changing legal/privacy claims without enough runtime evidence to support the claims.

A blocked external gate must not halt other independent local work. Continue all safe phases, then list the blocked external action in the final matrix.

---

# 1. REQUIRED PRE-FLIGHT BEFORE ANY EDIT

## 1.1 Reconfirm repository state

Run:

```bash
git status --short
git branch --show-current
git rev-parse HEAD
git log -1 --oneline
```

Expected baseline:

```text
branch: main
HEAD: 29f9b8611aef73e82bdcd3da62512fd8506107c7
```

If HEAD differs:

1. Do not reset/discard user work.
2. Compare current HEAD against the audited commit.
3. Re-open every file named in this plan that changed since baseline.
4. Adapt the implementation to current source.
5. Preserve the same acceptance criteria.
6. Record the new actual baseline in the final evidence matrix.

## 1.2 Required context reads

Read in this order:

1. `AGENTS.md`
2. `.codex/AGENTS.md`
3. `.codex/PROJECT_MAP.md`
4. `.codex/workflows/README.md`
5. `.codex/workflows/fix-issues.md`
6. `.codex/task-skills/fix-issues.md`
7. `.codex/history/OPEN_RISKS.md`
8. `.codex/domains/access-membership-referral.md`
9. `.codex/domains/ai-service.md`
10. `.codex/domains/notification.md` only before foreground-service work
11. `.codex/domains/ui-nami.md` only before user-facing AI report/payment UI work
12. uploaded/source audit markdown

## 1.3 Baseline validation

Run the lightest available baseline checks before editing:

```bash
flutter pub get
flutter analyze
flutter test test/app_versions/v1/features/ai_chat/ai_chat_quota_test.dart
flutter test test/app_versions/v1/features/ai_chat/ai_chat_screen_error_test.dart
flutter test test/app_versions/v2/features/payments/membership_payment_test.dart
flutter test test/app_versions/v2/features/payments/membership_payment_rpc_contract_test.dart
flutter test test/app_versions/v2/features/payments/presentation/membership_payment_page_test.dart
```

Also run project validators when available in the execution OS:

```powershell
powershell -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1
powershell -ExecutionPolicy Bypass -File .codex/tool/codex_quick_check.ps1
```

If on Linux and PowerShell is not installed, do not mark these as passed. Record `NOT RUN — environment unavailable` and use equivalent `dart/flutter/git` checks where possible.

## 1.4 Baseline evidence rule

Before edits, record:

- commands executed;
- pass/fail;
- existing failures unrelated to this task;
- Flutter version;
- Dart version;
- Java version;
- Android SDK platforms installed;
- Gradle/AGP resolved versions;
- whether Supabase CLI is available;
- whether Android release signing credentials are available;
- whether Play Console access is available.

Do not fix unrelated baseline failures unless they directly prevent an in-scope blocker from being verified.

---

# 2. WORK PACKAGE P0-01 — REPLACE PLAY-BUILD VIETQR MEMBERSHIP CHECKOUT WITH GOOGLE PLAY BILLING

## 2.1 Goal

For Android builds distributed through Google Play, users must purchase Plus/FamilyPlus digital membership through Google Play Billing. Membership entitlement must only become active after trusted-server verification of the Google Play purchase.

## 2.2 Existing source confirmed

Current payment architecture includes:

```text
lib/app_versions/v2/features/payments/
├── application/
├── data/
│   ├── datasources/
│   │   ├── bank_lookup_remote_datasource.dart
│   │   └── membership_payment_remote_datasource.dart
│   ├── mappers/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   │   └── membership_payment_models.dart
│   └── repositories/
│       └── membership_payment_repository.dart
├── presentation/pages/membership_payment_page.dart
└── providers/membership_payment_providers.dart
```

Current `membership_payment_page.dart` constructs VietQR data, creates a manual payment request, and waits for approval. Do not place Google Billing logic directly into that widget.

## 2.3 Required design

Create a separate store-billing abstraction. Keep manual bank-transfer concepts separate from Play purchase concepts.

Recommended domain flow:

```text
membership_payment_page.dart
  ↓
MembershipStorePurchaseController / providers
  ↓
MembershipStoreBillingRepository
  ↓
GooglePlayBillingDatasource
  ↓
in_app_purchase

purchase update from Google Play
  ↓
repository/controller
  ↓
trusted Supabase Edge Function
  ↓
Google Android Publisher verification
  ↓
server-side idempotent purchase ledger
  ↓
server-side membership entitlement update
  ↓
client refreshes current membership
```

The client must never grant Plus/FamilyPlus based solely on `PurchaseStatus.purchased`.

## 2.4 Files to READ before edit

Mandatory:

- `pubspec.yaml`
- `pubspec.lock`
- `lib/app_versions/v2/features/payments/presentation/pages/membership_payment_page.dart`
- `lib/app_versions/v2/features/payments/providers/membership_payment_providers.dart`
- `lib/app_versions/v2/features/payments/domain/entities/membership_payment_models.dart`
- `lib/app_versions/v2/features/payments/domain/repositories/membership_payment_repository.dart`
- `lib/app_versions/v2/features/payments/data/datasources/membership_payment_remote_datasource.dart`
- `lib/app_versions/v2/features/payments/data/repositories/membership_payment_repository_impl.dart`
- `lib/app_versions/v2/features/membership/**` relevant repository/provider files
- `docs/supabase/01_build_system.sql`
- `docs/supabase/02_seed_data.sql`
- `supabase/functions/_shared/**`
- an existing authenticated Edge Function with handler/index split
- `test/app_versions/v2/features/payments/membership_payment_test.dart`
- `test/app_versions/v2/features/payments/membership_payment_rpc_contract_test.dart`
- `test/app_versions/v2/features/payments/presentation/membership_payment_page_test.dart`
- all existing payment `data/` and `providers/` tests

Search before implementation:

```bash
rg -n "membership_payment|VietQR|qrImageUrl|transferContent|confirmTransfer|MembershipTier|FamilyPlus|plus|purchase|billing" lib test docs/supabase supabase/functions
```

## 2.5 Files expected to MODIFY

### Dependency/config

- `pubspec.yaml`
  - add `in_app_purchase` using a version compatible with the current Flutter/Dart SDK;
  - do not guess an arbitrary old version if `flutter pub add in_app_purchase` can resolve compatibility.
- `pubspec.lock`
  - generated by `flutter pub get` / dependency resolution.

### Existing payment domain/presentation

- `lib/app_versions/v2/features/payments/presentation/pages/membership_payment_page.dart`
  - Play build must display store product title/price returned by Google Play, not a hardcoded/VND database price as the purchase authority;
  - replace consumer QR transfer CTA with Play Billing CTA;
  - implement loading, store unavailable, product unavailable, pending, cancelled, purchased-awaiting-verification, verified-success, verification-failed/retry states;
  - include `Khôi phục giao dịch` / restore flow where appropriate;
  - never display purchase token/order internals;
  - after verification succeeds, invalidate/refetch membership provider and navigate according to existing app behavior;
  - legacy QR receipt/share UI must not remain reachable from the Play consumer checkout.

- `lib/app_versions/v2/features/payments/providers/membership_payment_providers.dart`
  - register store billing datasource/repository/controller providers;
  - expose deterministic purchase UI state;
  - ensure purchase stream subscription lifecycle is owned outside ephemeral button callbacks;
  - prevent duplicate simultaneous purchase attempts;
  - ensure state survives/recovers from app resume where feasible.

- `lib/app_versions/v2/features/payments/payments.dart`
  - export new domain/data/provider APIs only if this barrel file convention already exports feature members.

### SQL/backend

- `docs/supabase/01_build_system.sql`
  - add canonical schema/functions/RLS for verified store purchases if equivalent tables do not already exist;
  - all schema changes must be idempotent according to existing script style;
  - preserve canonical rebuild behavior.

- `docs/supabase/02_seed_data.sql`
  - only modify if product/base-plan mapping is legitimately seed/config data;
  - never seed fake successful purchases.

- `docs/supabase/README.md`
  - if touched, correct canonical rebuild documentation to actual files (`01_build_system.sql` then `02_seed_data.sql`).

## 2.6 Files expected to CREATE

Use project naming conventions; preferred structure:

```text
lib/app_versions/v2/features/payments/domain/entities/store_membership_purchase.dart
lib/app_versions/v2/features/payments/domain/repositories/membership_store_billing_repository.dart
lib/app_versions/v2/features/payments/data/datasources/google_play_billing_datasource.dart
lib/app_versions/v2/features/payments/data/models/google_play_purchase_dto.dart
lib/app_versions/v2/features/payments/data/repositories/membership_store_billing_repository_impl.dart
lib/app_versions/v2/features/payments/providers/membership_store_billing_providers.dart
```

If existing project style strongly favors fewer files, Codex may combine DTO/model/provider files, but MUST preserve domain/data/presentation boundaries.

Trusted backend preferred files:

```text
supabase/functions/google-play-verify-purchase/index.ts
supabase/functions/google-play-verify-purchase/handler.ts
```

Add shared Google verification client/helper under:

```text
supabase/functions/_shared/google_play/**
```

only if more than one function genuinely needs it.

## 2.7 Store product mapping contract

Define product identifiers once in code/config, not scattered across widgets.

Recommended conceptual mapping:

```text
Plus monthly       → product + monthly base plan
Plus yearly        → product + yearly base plan
FamilyPlus monthly → product + monthly base plan
FamilyPlus yearly  → product + yearly base plan
```

Exact Play Console IDs MUST be read from existing configuration if present. If not present, use one centralized compile-time/config mapping and clearly list the IDs that must be created in Play Console.

Do not infer entitlement from localized product title.

## 2.8 Backend verification requirements

`google-play-verify-purchase` must:

1. Authenticate the requesting NanoBio user.
2. Validate request schema and length.
3. Accept only known product/base-plan IDs.
4. Bind purchase to the authenticated user.
5. Verify package/application ID equals NanoBioAI Android package.
6. Verify purchase/subscription with Google server API.
7. Verify state is eligible for entitlement.
8. Handle pending/cancelled/expired/refunded/revoked states explicitly.
9. Prevent replay by unique purchase token/order identifier.
10. Persist a server-side purchase ledger.
11. Apply membership idempotently.
12. Never trust client-submitted tier/duration/expiry if server/Google data disagrees.
13. Return a minimal normalized result to the app.
14. Log operational metadata without leaking raw tokens or health/user content.
15. Return retryable vs terminal errors distinctly.

Secrets for Google verification MUST exist only in server secrets/environment.

## 2.9 SQL design requirements

Before adding schema, inspect existing membership/payment tables/functions. Reuse existing membership mutation function if it is already safe/idempotent.

If a new ledger is needed, it should conceptually contain:

- internal id;
- `user_id`;
- provider = `google_play`;
- package name;
- product id;
- base plan/offer id when available;
- hashed or protected purchase token/reference as appropriate;
- Google order/reference id if available;
- purchase state;
- verification timestamp;
- entitlement start/end;
- acknowledgement state;
- original transaction/root purchase linkage for renewals;
- created/updated timestamps.

Constraints:

- unique provider purchase identity;
- user cannot update verification state through RLS;
- client cannot directly grant membership;
- only trusted function/service role can finalize verified purchase;
- user may read only the minimum purchase status required by UI.

## 2.10 Legacy VietQR handling

After Play Billing works, inspect all navigation routes to `MembershipPaymentPage`.

For Play Android release:

- no QR transfer CTA;
- no text instructing bank transfer to unlock digital membership;
- no external browser/payment link that circumvents Play Billing;
- no fallback from billing error to VietQR.

If manual payment remains for admin/non-Play distribution, hide it behind an explicit distribution/build capability, not a normal consumer failure fallback.

## 2.11 Tests to MODIFY/CREATE

Modify existing:

- `test/app_versions/v2/features/payments/membership_payment_test.dart`
- `test/app_versions/v2/features/payments/membership_payment_rpc_contract_test.dart` only where legacy contracts intentionally change
- `test/app_versions/v2/features/payments/presentation/membership_payment_page_test.dart`

Add targeted tests, preferred names:

```text
test/app_versions/v2/features/payments/data/google_play_billing_datasource_test.dart
test/app_versions/v2/features/payments/data/membership_store_billing_repository_impl_test.dart
test/app_versions/v2/features/payments/providers/membership_store_billing_providers_test.dart
test/app_versions/v2/features/payments/presentation/membership_payment_play_billing_test.dart
supabase/functions/google-play-verify-purchase/handler_test.ts
```

Test cases MUST cover:

- store available/unavailable;
- product loaded/missing;
- Plus month/year;
- FamilyPlus month/year;
- pending purchase;
- user cancellation;
- successful Play purchase but server verification pending;
- verification success;
- verification terminal failure;
- retryable network failure;
- duplicate purchase stream event;
- replayed purchase token;
- wrong package name;
- wrong product;
- purchase belonging to another user;
- expired/revoked/refunded subscription;
- app restart/resume with unfinished transaction;
- restore purchases;
- membership is never elevated before server verification;
- Play build contains no reachable VietQR purchase flow.

Unit/widget tests MUST use fakes/mocks; do not call real Google Billing in unit tests.

## 2.12 P0-01 Definition of Done

P0-01 may be marked `CLOSED-SOURCE` only when:

- Play consumer checkout no longer uses VietQR;
- billing library is integrated behind architecture boundaries;
- server-side Google verification exists;
- verified purchase idempotently updates trusted membership state;
- restore/resume flows are implemented;
- targeted tests pass;
- Play product IDs/config needs are documented;
- no secret is embedded for Google verification.

It may be marked fully `CLOSED` only after an internal-track license-tester purchase succeeds and membership is updated from server verification.

---

# 3. WORK PACKAGE P0-02 — IN-APP REPORT/FLAG FLOW FOR AI-GENERATED RESPONSES

## 3.1 Goal

Every AI assistant message displayed in `AIChatScreen` must provide an in-app reporting mechanism. Reporting must create a durable moderation record without forcing the user to leave the app.

## 3.2 Confirmed insertion point

Current:

```text
lib/app_versions/v1/features/ai_chat/presentation/pages/ai_chat_screen.dart
```

renders messages through private `_MessageBubble`, and `_MessageBubble` currently contains only `SelectableText(message.content)`.

Existing entity:

```text
lib/app_versions/v1/features/ai_chat/domain/entities/chat_message_entity.dart
```

already has:

- `id`
- `content`
- `role`
- `timestamp`

so a report can reference a stable message id without redesigning the entire chat entity.

## 3.3 Required report categories

Use a small, understandable Vietnamese list, for example:

- `Thông tin có vẻ sai`
- `Có thể gây hại hoặc không an toàn`
- `Nội dung không phù hợp / xúc phạm`
- `Vấn đề quyền riêng tư`
- `Khác`

For a health assistant, `Có thể gây hại hoặc không an toàn` must be a first-class reason, not hidden under `Khác`.

## 3.4 Files to READ

- `lib/app_versions/v1/features/ai_chat/presentation/pages/ai_chat_screen.dart`
- `lib/app_versions/v1/features/ai_chat/presentation/controllers/ai_chat_controller.dart`
- `lib/app_versions/v1/features/ai_chat/domain/entities/chat_message_entity.dart`
- `lib/app_versions/v1/features/ai_chat/providers/ai_chat_providers.dart`
- `lib/app_versions/v1/features/ai_chat/domain/repositories/ai_chat_repository.dart`
- AI chat local/history datasource/repository files
- current auth/session provider used by v1 guest and authenticated modes
- existing Supabase Edge Function patterns
- `docs/supabase/01_build_system.sql`
- `test/app_versions/v1/features/ai_chat/ai_chat_quota_test.dart`
- `test/app_versions/v1/features/ai_chat/ai_chat_screen_error_test.dart`

Search:

```bash
rg -n "ChatMessageEntity|MessageRole.assistant|AIChatScreen|_MessageBubble|report|flag|feedback|moderation" lib test docs/supabase supabase/functions
```

## 3.5 Files expected to MODIFY

- `lib/app_versions/v1/features/ai_chat/presentation/pages/ai_chat_screen.dart`
  - add report action only for `MessageRole.assistant`;
  - preferred UI: small overflow/flag action below or beside assistant bubble;
  - tapping opens modal/bottom sheet;
  - do not interfere with text selection;
  - success/failure feedback remains inside app.

- `lib/app_versions/v1/features/ai_chat/presentation/controllers/ai_chat_controller.dart`
  - only modify if report state belongs naturally in the main controller;
  - preferred: keep message-generation state separate from reporting state unless project convention strongly favors one controller.

- `lib/app_versions/v1/features/ai_chat/providers/ai_chat_providers.dart`
  - add report repository/provider wiring if this is the feature's canonical composition root.

- `docs/supabase/01_build_system.sql`
  - add report storage/RLS/RPC only if not already present.

## 3.6 Files expected to CREATE

Preferred architecture:

```text
lib/app_versions/v1/features/ai_chat/domain/entities/ai_content_report.dart
lib/app_versions/v1/features/ai_chat/domain/repositories/ai_content_report_repository.dart
lib/app_versions/v1/features/ai_chat/data/datasources/ai_content_report_remote_datasource.dart
lib/app_versions/v1/features/ai_chat/data/repositories/ai_content_report_repository_impl.dart
lib/app_versions/v1/features/ai_chat/presentation/controllers/ai_content_report_controller.dart
lib/app_versions/v1/features/ai_chat/presentation/widgets/ai_content_report_sheet.dart
```

If guest reporting requires a server function that supports both authenticated and anonymous app sessions, create:

```text
supabase/functions/report-ai-content/index.ts
supabase/functions/report-ai-content/handler.ts
```

## 3.7 Report persistence/privacy contract

A report record should include the minimum necessary fields:

- report id;
- optional authenticated user id;
- anonymous installation/session identifier only if required;
- message id;
- message role = assistant;
- reason code;
- optional user note;
- app version/build;
- created timestamp;
- moderation status.

For AI message content:

- Prefer storing a bounded snapshot or server-known message reference.
- Do not blindly duplicate entire health conversation history.
- If storing message text is necessary for moderation, cap size and explicitly include this flow in Data Safety/Privacy mapping.
- Do not upload user messages unrelated to the reported answer.

## 3.8 Guest-mode requirement

NanoBioAI supports guest/basic mode. Therefore reporting MUST NOT silently disappear for guests.

Required behavior:

- report button remains visible for assistant responses;
- report can be submitted in release configuration even if the user is not authenticated;
- anonymous endpoint must be rate-limited/abuse-protected;
- do not expose service-role credentials to the client;
- if network is temporarily unavailable, provide a retryable error or a safe local outbox consistent with existing project patterns;
- never show fake `Đã gửi` if persistence failed.

## 3.9 UI requirements

Assistant message UI:

```text
[Nabi response text]
[small actions: Báo cáo]
```

Report sheet:

1. title: `Báo cáo phản hồi này`
2. short explanation in Nabi tone;
3. reason selection;
4. optional note field, bounded length;
5. `Gửi báo cáo` CTA;
6. loading state;
7. success: short confirmation;
8. error: retry without losing selected reason/note.

No report action on user messages.

## 3.10 Tests to ADD/MODIFY

Modify:

- `test/app_versions/v1/features/ai_chat/ai_chat_screen_error_test.dart` only if shared widget setup changes.

Add:

```text
test/app_versions/v1/features/ai_chat/ai_content_report_test.dart
test/app_versions/v1/features/ai_chat/ai_chat_screen_report_test.dart
supabase/functions/report-ai-content/handler_test.ts
```

Required cases:

- assistant bubble exposes report action;
- user bubble does not;
- opens reason sheet;
- cannot submit without reason;
- optional note length validation;
- authenticated report success;
- guest report success;
- duplicate tap does not create uncontrolled duplicates;
- backend/server error shows retryable state;
- no false success state;
- report data is bounded;
- reporting does not alter/delete chat message;
- chat generation safety filters remain independent.

## 3.11 P0-02 Definition of Done

- Every rendered AI answer has in-app report action.
- Flow works for guest and authenticated release flows.
- Report is durably persisted/server-received.
- Report reasons include health/safety concern.
- Tests pass.
- No sensitive credentials introduced.

---

# 4. WORK PACKAGE P0-G01 — MAKE API 36 DETERMINISTIC AND PROVE IT IN FINAL AAB

## 4.1 Goal

Release build must deterministically target Android API 36+, independent of the Flutter SDK defaults on another developer machine.

## 4.2 Files to READ

- `android/app/build.gradle.kts`
- `android/build.gradle.kts` if present
- `android/settings.gradle.kts`
- `android/gradle/wrapper/gradle-wrapper.properties`
- Flutter version manager/project files if present
- CI workflows that build Android

## 4.3 File to MODIFY

Primary:

- `android/app/build.gradle.kts`

Change from indirect target:

```kotlin
targetSdk = flutter.targetSdkVersion
```

to explicit release requirement:

```kotlin
compileSdk = 36
...
targetSdk = 36
```

or higher only if the installed/build toolchain and repository already target a higher supported API.

Keep `minSdk` unchanged unless API 36 compile reveals a direct documented incompatibility.

## 4.4 Do NOT pre-emptively change

Do not upgrade these just because warnings exist:

- AGP
- Gradle wrapper
- Kotlin
- Java

Only change them if API 36/release build fails because the current combination cannot build the project. If a toolchain change becomes necessary:

1. capture the exact build error;
2. make the smallest compatible version change;
3. run full Android regression checks;
4. document why the change was required.

## 4.5 Verification

Run:

```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

If release credentials are unavailable, run the nearest non-secret build that still produces an AAB or document the signing block explicitly.

Inspect the built artifact using installed Android tools (`apkanalyzer`, `bundletool`, merged manifest task, or Play Console artifact explorer) and record actual target SDK.

Also verify:

```bash
./gradlew :app:processReleaseMainManifest
./gradlew :app:bundleRelease
```

when executable in the environment.

## 4.6 Definition of Done

- source explicitly targets >=36;
- build succeeds;
- artifact evidence confirms target >=36;
- Play Console internal upload has no target-API rejection before marking external gate closed.

---

# 5. WORK PACKAGE P1-01 — REMOVE UNNECESSARY BROAD PHOTO PERMISSION

## 5.1 Goal

Use system picker/camera for user-initiated individual media selection. Do not request broad library access unless source proves it is core functionality.

## 5.2 Files to READ/SEARCH

Primary:

- `android/app/src/main/AndroidManifest.xml`
- every image-selection call in `lib/**`
- permission abstraction/provider files
- avatar/profile, health-photo, task-proof/photo verification flows

Run:

```bash
rg -n "READ_MEDIA_IMAGES|READ_EXTERNAL_STORAGE|Permission\.photos|Permission\.storage|ImagePicker|pickImage|pickMultiImage|ImageSource\.gallery|ImageSource\.camera|MediaStore" android lib test
```

## 5.3 Decision rule

If all gallery access is user-initiated through `image_picker`/system picker and no feature enumerates/scans the photo library:

- remove broad media permission.

If a real feature scans/manages a persistent library collection:

- stop only this subtask;
- identify the exact feature and evidence;
- do not remove permission blindly;
- mark Play declaration required.

## 5.4 File expected to MODIFY

- `android/app/src/main/AndroidManifest.xml`

Remove:

```xml
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
```

Also remove obsolete runtime permission requests in Dart if discovered.

Do not remove `CAMERA` if camera flows remain functional.

## 5.5 Verification

- inspect merged release manifest and confirm `READ_MEDIA_IMAGES` is absent;
- test gallery selection on Android 13/14/16;
- test camera capture;
- test every user flow that selects avatar/health/task images;
- verify denial/cancel does not crash;
- verify no permission prompt for full photo library appears.

## 5.6 Definition of Done

Broad photo permission is absent from final merged manifest unless a documented, validated core use case requires it.

---

# 6. WORK PACKAGE P1-02 — REMOVE GEMINI API SECRET FROM THE ANDROID CLIENT

## 6.1 Goal

Production app must not ship a reusable Gemini API key in `BuildConfig`, Dart define, `.env` asset, URL, or APK/AAB strings. AI calls should pass through a trusted backend that owns provider credentials, quota enforcement, and request validation.

## 6.2 Confirmed current secret path

Current flow:

```text
android/app/build.gradle.kts
  → BuildConfig.GEMINI_API_KEY
  → MainActivity runtime_config MethodChannel
  → lib/core/config/app_env.dart
  → lib/main.dart
  → GeminiNabiCareAiGateway / GeminiRestClient
  → generativelanguage.googleapis.com?...key=<secret>
```

## 6.3 Files to READ

- `android/app/build.gradle.kts`
- `android/app/src/main/kotlin/com/example/nano_app/MainActivity.kt`
- `lib/core/config/app_env.dart`
- `lib/main.dart`
- `lib/app_versions/v1/services/ai/gemini_rest_client.dart`
- `lib/app_versions/v1/features/ai_chat/data/datasources/gemini_nabi_care_ai_gateway.dart`
- all other call sites of `GeminiRestClient`, `AppEnv.geminiApiKey`, `GEMINI_API_KEY`, `generativelanguage.googleapis.com`
- usage quota gateway/service
- Supabase auth/session bootstrap
- existing Edge Function coding patterns

Run:

```bash
rg -n "GEMINI_API_KEY|geminiApiKey|GeminiRestClient|generativelanguage\.googleapis\.com|generateContent" lib android test supabase
```

## 6.4 Recommended target architecture

```text
Flutter AI feature
  ↓
AI gateway/repository contract
  ↓
NanoBio trusted AI backend client
  ↓
Supabase Edge Function
  ↓
server-side auth/quota/validation/safety
  ↓
Gemini provider using server secret
```

Do not create an unrestricted generic proxy that lets a client choose arbitrary provider URL/model/request body.

## 6.5 Files expected to MODIFY

- `android/app/build.gradle.kts`
  - delete Gradle/env loading for Gemini client secret;
  - delete `buildConfigField` for `GEMINI_API_KEY`;
  - keep BuildConfig enabled only if other code actually needs it.

- `android/app/src/main/kotlin/com/example/nano_app/MainActivity.kt`
  - remove `getPrivateRuntimeConfig` Gemini response and runtime-config MethodChannel if it has no remaining purpose;
  - do not disturb Sleep Safety channel wiring.

- `lib/core/config/app_env.dart`
  - remove native Gemini secret loading;
  - remove production dependency on `geminiApiKey`;
  - keep only public/non-secret configuration such as Supabase URL/anon key according to existing project contract;
  - if a local/dev direct-Gemini mode is retained, it must be explicitly non-release and excluded from production build path.

- `lib/main.dart`
  - stop constructing production `GeminiNabiCareAiGateway(apiKey: AppEnv.geminiApiKey)`;
  - wire backend AI gateway/client through provider override.

- `lib/app_versions/v1/features/ai_chat/data/datasources/gemini_nabi_care_ai_gateway.dart`
  - adapt from direct provider key usage to trusted backend transport, or replace with a new backend gateway while preserving its interface.

- `lib/app_versions/v1/services/ai/gemini_rest_client.dart`
  - remove from production-reachable client path;
  - if retained for tests/dev tooling, ensure no release composition root references it.

- any AI services directly instantiating or depending on `GeminiRestClient`.

## 6.6 Files expected to CREATE

Preferred:

```text
lib/app_versions/v1/services/ai/nanobio_ai_backend_client.dart
supabase/functions/nabi-ai-generate/index.ts
supabase/functions/nabi-ai-generate/handler.ts
```

Potential shared helpers:

```text
supabase/functions/_shared/ai/provider_client.ts
supabase/functions/_shared/ai/request_validation.ts
supabase/functions/_shared/ai/safety.ts
```

Only create shared files when reused or needed for testability.

## 6.7 Server AI function requirements

Server function must:

- validate authenticated user when feature requires login;
- support product-approved guest behavior without exposing provider secret;
- enforce quotas/server abuse controls;
- whitelist supported operations/models;
- validate body shape/size;
- bound prompt/context sizes;
- preserve current prompt/safety/normalization behavior;
- redact secrets and sensitive payloads from logs;
- normalize provider errors to current app exception categories;
- enforce timeouts;
- use bounded retry policy;
- never return provider secret;
- never permit arbitrary URL proxying.

## 6.8 Compatibility requirement

Do not regress existing AI feature contracts:

- chat quota;
- health analysis;
- exercise guidance;
- meal/schedule generation if they share the Gemini client;
- Nabi Care safety filters;
- existing response parsing;
- offline/config-unavailable user messages.

Before deleting direct Gemini client behavior, enumerate every caller and migrate all production callers.

## 6.9 Tests

Add/modify tests for:

- backend client request mapping;
- auth/no-auth behavior by intended feature;
- quota exceeded mapping;
- timeout/network mapping;
- malformed provider response;
- safety rejection;
- response normalization;
- no direct Gemini URL in production composition;
- no `GEMINI_API_KEY` client path.

Server tests must mock provider HTTP.

Security evidence:

```bash
rg -n "GEMINI_API_KEY|generativelanguage\.googleapis\.com" android lib
```

Expected after migration:

- no production client secret injection;
- direct Google provider URL absent from production-reachable app client.

Inspect release artifact strings if tools permit.

## 6.10 Definition of Done

- release Android client does not contain Gemini secret;
- trusted backend owns provider secret;
- all production AI call sites use trusted backend;
- quotas/safety/error mapping preserved;
- targeted tests pass.

---

# 7. WORK PACKAGE P1-03 — SUPABASE/RLS/MEMBERSHIP/PAYMENT/REFERRAL RUNTIME VERIFICATION

## 7.1 Goal

Close `.codex/history/OPEN_RISKS.md` risk `NB-RISK-001` only with real local/sandbox/staging evidence.

## 7.2 Source files

Mandatory:

- `docs/supabase/01_build_system.sql`
- `docs/supabase/02_seed_data.sql`
- `docs/supabase/README.md`
- membership/quota/payment/referral data/repository code
- sale/referral module
- FamilyPlus membership code
- auth/profile sync code
- relevant integration tests

## 7.3 First action: repair docs mismatch

If confirmed after fresh tree inspection, update:

- `docs/supabase/README.md`

so canonical local/sandbox rebuild is described using only existing canonical source files:

```text
01_build_system.sql
02_seed_data.sql
```

Do not create artificial numbered files to satisfy stale README text.

## 7.4 Sandbox rebuild

Use a disposable/local/sandbox project, never production.

Apply:

1. `docs/supabase/01_build_system.sql`
2. `docs/supabase/02_seed_data.sql`

Record errors/warnings.

If scripts are not idempotent/rebuild-safe as documented, fix the owning SQL script rather than applying an undocumented manual patch.

## 7.5 Test identities

Create fake test users only:

- User A — Free
- User B — Free
- User C — Plus
- User D — FamilyPlus owner
- User E — Family member
- User S — Sale/referral role
- User Admin — Admin when required

Never use production identities.

## 7.6 Required RLS negative matrix

At minimum verify:

- A cannot read/update B profile/private health data;
- A cannot read B payment history;
- A cannot approve own payment;
- A cannot self-grant Plus/FamilyPlus;
- A cannot mutate quota counters outside trusted flow;
- non-admin cannot access admin queues;
- Sale role does not imply membership tier;
- membership tier does not imply Sale role;
- family member can access only intended family scope;
- unrelated user cannot access family scope;
- revoked membership loses gated access;
- referral ownership cannot be forged by client update;
- purchase verification rows cannot be forged/approved by client.

## 7.7 Membership lifecycle matrix

Verify:

```text
Free → Plus
Plus → expiry
Plus → renewal
Plus → FamilyPlus
FamilyPlus → expiry
cancelled/refunded Play purchase → expected entitlement behavior
repeated verification callback → idempotent
login on second device → same trusted membership state
logout/login → no stale elevated local tier
```

## 7.8 Payment/referral tests

Verify:

- duplicate payment event does not duplicate entitlement;
- manual legacy payment approval, if retained, stays admin-only and non-Play-consumer;
- rejected/cancelled payment cannot grant entitlement;
- referral reward is not applied twice;
- concurrent retries are idempotent;
- stale client state cannot overwrite server truth.

## 7.9 Source changes allowed

Only modify source when a runtime test demonstrates a contract defect.

Likely owning files:

- `docs/supabase/01_build_system.sql`
- `docs/supabase/02_seed_data.sql` only for canonical seed corrections
- related repository/datasource code in v2 membership/payment/sale-referral
- Edge Function handler that owns privileged mutation
- targeted tests

Do not create ad-hoc SQL patch files outside the canonical project convention.

## 7.10 OPEN_RISKS update

Only after evidence is real, update:

- `.codex/history/OPEN_RISKS.md`

Possible status:

- remove risk if project convention removes closed risks; or
- change to closed/verified only if this file supports closed entries.

Follow the file's existing convention. Never write “verified” from static review alone.

## 7.11 Definition of Done

- clean sandbox rebuild succeeds;
- RLS negative matrix passes;
- membership lifecycle passes;
- payment/referral idempotency passes;
- evidence is reproducible;
- `NB-RISK-001` is only closed after those checks.

---

# 8. WORK PACKAGE P1-04 — ACCOUNT DELETION DATA-LIFECYCLE VERIFICATION AND FIX

## 8.1 Goal

`auth.admin.deleteUser(userId)` must result in deletion or explicitly documented/anonymized retention of all associated NanoBio user data.

## 8.2 Existing confirmed flow

Read and preserve:

- `lib/app_versions/v2/features/auth/data/repositories/supabase_auth_repository.dart`
- `lib/app_versions/v2/features/auth/data/datasources/supabase_auth_remote_datasource.dart`
- `supabase/functions/delete-account/handler.ts`
- `supabase/functions/delete-account/index.ts`

Current Edge Function already deletes the auth user. Do not replace this with mere deactivation.

## 8.3 Build a data retention matrix from SQL

Search `docs/supabase/01_build_system.sql` for every user-associated column/FK:

```bash
rg -n "auth\.users|user_id|owner_id|member_id|created_by|reviewed_by|referred_by|profile_id|family" docs/supabase/01_build_system.sql
```

Create an execution-time matrix with columns:

```text
Table/domain | user reference | current FK delete behavior | desired behavior | reason | test query
```

Classify every relevant area:

- profile;
- health/body metrics;
- meals/schedules/tasks;
- AI/chat/report data;
- quota/usage;
- membership;
- payment/store purchase ledger;
- referral/sale;
- family data;
- notifications;
- sleep safety;
- audit/security logs;
- any uploaded/storage object metadata.

## 8.4 Retention rule

Default for personal/health app data:

- delete with user unless a legitimate documented reason requires retention.

For payment/fraud/security/audit data that must be retained:

- remove/anonymize direct user linkage where possible;
- preserve only fields necessary for the stated purpose;
- make retention period explicit in Privacy Policy/data-retention documentation;
- ensure the deleted user cannot be reconstructed from convenience copies unnecessarily.

Codex must not invent a legal retention period. If no legal/product policy exists, mark the exact field/table as a legal-policy decision required.

## 8.5 Files expected to MODIFY if gaps exist

- `docs/supabase/01_build_system.sql`
  - correct FK `ON DELETE` behavior;
  - add safe cleanup/anonymization function if necessary;
  - preserve rebuild idempotency.

- `supabase/functions/delete-account/handler.ts`
  - if cascade is insufficient, call a trusted pre-delete cleanup/anonymization RPC transaction before `auth.admin.deleteUser`;
  - fail safely if critical cleanup fails;
  - avoid partial “success” response.

- `supabase/functions/delete-account/index.ts`
  - only if additional dependencies/config are required.

Flutter auth files should be changed only if post-delete local cleanup is incomplete.

## 8.6 Local-device cleanup

After successful server deletion, verify:

- Supabase session cleared;
- local SQLite personal data cleared according to app account boundaries;
- secure storage/session token cleared;
- cached membership removed;
- AI chat/history cache cleared if owned by deleted account;
- health dashboards do not keep deleted-user data visible;
- notifications scheduled for the deleted account are cancelled when required.

Search existing logout/delete cleanup first. Reuse it rather than duplicate wipe logic.

## 8.7 Tests

Add/update:

```text
supabase/functions/delete-account/handler_test.ts
```

and relevant Flutter auth deletion tests.

Sandbox scenario:

1. create fake user;
2. populate every user-associated domain with synthetic data;
3. invoke actual delete-account function;
4. assert auth user gone;
5. run table-by-table queries from retention matrix;
6. assert personal/health data gone;
7. assert intentionally retained records are anonymized as specified;
8. assert client session/local state is cleared.

## 8.8 Definition of Done

No unexplained associated user data remains after account deletion. Any retained data has an explicit purpose, minimization rule, and documentation requirement.

---

# 9. WORK PACKAGE MANUAL-05 — FOREGROUND MICROPHONE / SLEEP SAFETY VERIFICATION

## 9.1 Status

This is a verification gate, not a confirmed source defect.

Manifest already declares:

- `FOREGROUND_SERVICE`
- `FOREGROUND_SERVICE_MICROPHONE`
- service `foregroundServiceType="microphone"`

## 9.2 Files to READ

- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/kotlin/com/example/nano_app/sleep_safety/SleepSafetyForegroundService.kt`
- `SleepSafetyForegroundBridge.kt`
- `SleepSafetyHeartbeatRecorder.kt`
- `SleepSafetyNotificationPublisher.kt`
- `SleepSafetySignalMonitor.kt`
- Flutter sleep-tracking/safety controller/service files
- relevant tests

## 9.3 Runtime scenarios

On Android 14+ and API 36 emulator/device:

- mic permission not granted → service does not illegally start;
- mic permission granted while app eligible → service starts;
- foreground notification appears immediately;
- notification correctly identifies active monitoring;
- stop action stops recording/service;
- app process/background transition behaves according to Android restrictions;
- process recreation does not create duplicate recorder;
- microphone is released when monitoring stops;
- failure does not leave stale “monitoring” UI state;
- no hidden recording outside explicit user-enabled feature behavior.

## 9.4 Source changes

Only fix source if a runtime scenario fails. Do not rewrite service merely to “look modern”.

## 9.5 Manual output

Prepare exact Play Console FGS declaration text based on actual runtime use case. Do not claim it was submitted unless Play Console submission was performed.

---

# 10. WORK PACKAGE MANUAL-06 — 16 KB MEMORY PAGE SIZE VERIFICATION

## 10.1 Goal

Prove final release AAB/native libraries are compatible with 16 KB page-size requirements.

## 10.2 Procedure

1. Build final release AAB.
2. Enumerate packaged `.so` files.
3. Use current Android tooling/bundletool/ELF inspection recommended by installed SDK to verify alignment/compatibility.
4. Identify any incompatible native library and map it back to its Flutter plugin/package.
5. Upgrade only the offending plugin to the smallest compatible version.
6. Rebuild and re-check.

## 10.3 Files that MAY change

Only if an incompatible plugin is proven:

- `pubspec.yaml`
- `pubspec.lock`
- plugin-specific Android config required by that upgrade

Do not bulk-upgrade all Flutter dependencies as a preventive measure.

## 10.4 Definition of Done

Artifact check passes or Play Console confirms no 16 KB compatibility blocker.

---

# 11. REPOSITORY-SIDE PLAY CONSOLE / PRIVACY PREPARATION

These tasks cannot by themselves complete Play Console submission, but Codex should prepare source-of-truth material so console answers are based on actual runtime behavior.

## 11.1 Create a release evidence area only if no equivalent exists

Before creating anything, search:

```bash
find docs -maxdepth 4 -type f | grep -Ei "privacy|data.?safety|health.?apps|play.?store|account.?deletion|release"
```

Reuse existing canonical docs when present.

If no equivalent exists, create:

```text
docs/release/google_play/README.md
docs/release/google_play/DATA_SAFETY_MAPPING.md
docs/release/google_play/HEALTH_APPS_DECLARATION.md
docs/release/google_play/ACCOUNT_DELETION.md
docs/release/google_play/FOREGROUND_SERVICE_DECLARATION.md
docs/release/google_play/STORE_LISTING_CLAIMS_REVIEW.md
```

A public privacy policy may be maintained in an existing site/legal location. Do not create a duplicate policy if one already exists.

## 11.2 Data Safety mapping

Build from actual data flow, not guesses.

At minimum map:

- account/profile data;
- health/body metrics;
- diet/exercise/schedule;
- photos/camera;
- microphone/audio and whether audio leaves device;
- AI prompts/responses;
- diagnostics/logging;
- device/installation identifiers;
- payment/purchase data;
- family/emergency contact data;
- referral/sale data;
- third parties receiving each category.

For each category include:

```text
Collected? | Shared? | Purpose | Required/optional | Ephemeral/persisted | Encryption | Deletion behavior | Third party
```

Do not call data “not collected” if it is transmitted off-device even temporarily under the applicable Play definition.

## 11.3 Health Apps Declaration

Map every shipped health feature to its actual category/use case. Separate:

- wellness/tracking;
- AI-generated guidance;
- safety monitoring;
- any content that could be interpreted as diagnosis/treatment.

Flag claims needing product/legal review rather than inventing certification.

## 11.4 Public Privacy Policy

Ensure policy text matches actual implementation after Gemini proxy/reporting/billing changes:

- what data is collected;
- why;
- Supabase processing;
- Gemini/AI provider processing through backend;
- AI report moderation data;
- microphone/sleep safety behavior;
- image handling;
- payments via Google Play;
- account deletion;
- retention exceptions;
- contact mechanism.

The repository file is not enough. Final gate requires a public reachable URL.

## 11.5 External account deletion URL

Prepare the exact web resource requirements:

- identifies NanoBioAI/developer;
- lets user request account deletion without reinstalling/opening app;
- authenticates/validates requester safely;
- states what is deleted vs retained;
- does not merely point back to app settings.

If the repository contains a web site capable of hosting this flow, implement there only if it is within current repo scope. Otherwise mark `MANUAL/EXTERNAL-SITE` and provide required content/contract, not a fake URL.

## 11.6 Content rating / target audience / app access

Prepare factual answers based on shipped runtime only.

- Community is `Coming Soon`; do not claim live UGC features.
- AI chat is live and must be represented.
- health content is live and must be represented.
- provide reviewer credentials/instructions using a dedicated test account; never commit real password to Git.

## 11.7 Store listing claims review

Review title, short description, long description, screenshots/captions if maintained in repo.

Reject or rewrite claims that imply:

- guaranteed diagnosis;
- treatment/cure;
- emergency medical replacement;
- medically validated accuracy without evidence;
- monitoring capabilities not actually implemented.

Keep disclaimers consistent with in-app health copy.

---

# 12. RELEASE ARTIFACT VERIFICATION

## 12.1 Mandatory build sequence

After all source changes:

```bash
dart format <all changed Dart files>
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release
```

If full `flutter test` has unrelated baseline failures, still run all targeted new/modified suites and report the baseline delta honestly.

Run project checks when available:

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_v2.ps1 -ValidateOnly
powershell -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1
powershell -ExecutionPolicy Bypass -File .codex/tool/codex_quick_check.ps1
powershell -ExecutionPolicy Bypass -File .codex/tool/codex_check.ps1 -BuildApk
```

## 12.2 Final AAB checks

Record:

- AAB path;
- versionName/versionCode;
- package/application id;
- minSdk;
- targetSdk;
- signing status/certificate identity where safe;
- requested permissions from merged manifest;
- presence/absence of `READ_MEDIA_IMAGES`;
- foreground-service declarations;
- native library/16 KB result;
- evidence that no Gemini secret is embedded;
- no consumer VietQR checkout path in Play build.

## 12.3 Internal/closed Play testing

When Play Console access is available:

1. upload AAB to Internal testing first;
2. resolve automated policy/artifact blockers;
3. add license-test accounts;
4. test each Play Billing subscription/base plan;
5. test restore/resubscribe/renewal/cancel/refund scenarios available in test environment;
6. run Pre-launch report;
7. inspect crash/ANR/accessibility/security warnings;
8. verify reviewer App Access instructions;
9. verify Data Safety/Health/FGS declarations;
10. do not promote to Production until final GO matrix is green.

---

# 13. REQUIRED FINAL GO/NO-GO MATRIX

Codex must finish with a matrix using these exact statuses:

- `CLOSED — VERIFIED`
- `CLOSED — SOURCE ONLY, EXTERNAL VERIFY PENDING`
- `OPEN — BLOCKED`
- `OPEN — FAILED VERIFY`
- `NOT APPLICABLE — EVIDENCE`

Required rows:

| ID | Gate | Required final evidence |
|---|---|---|
| P0-01 | Play Billing | internal test purchase + server-verified entitlement |
| P0-02 | AI report/flag | UI + persisted report + tests |
| P0-G01 | API 36 | final AAB metadata / Play artifact explorer |
| P1-01 | photo permission | final merged manifest |
| P1-02 | Gemini client secret | source search + release artifact check + backend flow tests |
| P1-03 | Supabase/RLS | sandbox rebuild + negative authorization matrix |
| P1-04 | deletion lifecycle | sandbox populated-user deletion matrix |
| M-01 | Health Apps declaration | Play Console confirmation |
| M-02 | Data Safety | Play Console confirmation + source mapping |
| M-03 | public privacy URL | reachable URL |
| M-04 | external deletion URL | reachable functional URL |
| M-05 | FGS | runtime Android 14+/16 + Play declaration |
| M-06 | 16 KB | artifact/Play check |
| M-07 | photo declaration | N/A if permission removed; otherwise console evidence |
| M-08 | content rating/audience | Play Console completed |
| M-09 | App Access | reviewer credentials/instructions accepted |
| M-10 | pre-launch | report has no release-blocking crash/ANR |
| M-11 | medical claims | listing review complete |
| M-12 | billing declaration | Play Billing path or approved alternative program evidence |

Production submission is `GO` only if:

- every P0 is `CLOSED — VERIFIED`;
- every P1 is `CLOSED — VERIFIED` or has an explicitly accepted non-blocking external verification status;
- all mandatory Play Console fields are complete;
- Pre-launch report contains no release blocker.

---

# 14. EXECUTION ORDER / DEPENDENCY GRAPH

Codex should follow this dependency order rather than editing everything simultaneously:

```text
PHASE A — baseline/context
  ↓
PHASE B — P0-01 Play Billing
  ├─ depends on membership + Supabase understanding
  └─ produces new backend purchase contract
  ↓
PHASE C — P0-02 AI reporting
  └─ may share new moderation/backend patterns but must remain independent
  ↓
PHASE D — API 36 + media permission
  ↓
PHASE E — Gemini backend migration
  ↓
PHASE F — rebuild/verify Supabase + RLS
  ├─ validates billing backend
  └─ validates new AI-report persistence if Supabase-backed
  ↓
PHASE G — account deletion lifecycle
  └─ must include newly-created billing/report tables
  ↓
PHASE H — foreground service + 16 KB artifact verification
  ↓
PHASE I — privacy/Data Safety/Health/release docs
  └─ must be written AFTER final runtime data flows are known
  ↓
PHASE J — final AAB + internal Play test + GO/NO-GO
```

Critical dependency rule:

> Do not finalize Data Safety or Privacy mapping before billing, AI-report, and Gemini transport are finalized, because those changes alter data flows.

---

# 15. LUNA-SPECIFIC EXECUTION STRATEGY

GPT-5.6 Luna should be given a persistent, testable outcome and allowed to execute bounded sub-goals. To reduce drift on a long repository task:

## 15.1 One active sub-goal at a time

At any moment maintain:

```text
ACTIVE GOAL
FILES IN SCOPE
EXPECTED STATE CHANGE
VALIDATION
DONE CONDITION
```

Do not simultaneously refactor billing + AI + auth + Android config in one edit batch.

## 15.2 Before each sub-goal

Re-read only:

- owning source files;
- direct dependencies;
- relevant tests;
- one relevant domain rule.

Do not repeatedly load the entire repository.

## 15.3 After each sub-goal

Immediately:

1. format changed files;
2. run targeted analyzer/test;
3. inspect diff;
4. repair failures;
5. confirm no unrelated files changed;
6. mark sub-goal done only with evidence;
7. continue automatically to next safe sub-goal.

## 15.4 Drift prevention

If a planned path no longer exists:

- search for the current owning implementation;
- update path mapping;
- preserve requirement;
- do not create duplicate architecture merely to match this plan.

If a source contract differs materially:

- prefer source truth;
- explain the deviation in final evidence;
- stop only if the deviation changes product/policy semantics.

## 15.5 No fake completion

Never use phrases equivalent to:

- “should work”;
- “likely compliant”;
- “probably passes”;
- “assumed configured in Play Console”

as evidence.

Use one of:

- executed test output;
- build output;
- artifact inspection;
- sandbox query/result;
- Play Console result;
- clearly marked manual/blocker status.

---

# 16. EXPECTED CHANGED/NEW FILE SET BY WORK PACKAGE

This is the planned set, not permission to modify every file blindly. Codex must re-read and touch only files required by actual implementation.

## 16.1 P0-01 Billing

Expected modifications:

```text
pubspec.yaml
pubspec.lock
lib/app_versions/v2/features/payments/presentation/pages/membership_payment_page.dart
lib/app_versions/v2/features/payments/providers/membership_payment_providers.dart
lib/app_versions/v2/features/payments/payments.dart                     # if barrel export needed
docs/supabase/01_build_system.sql
docs/supabase/02_seed_data.sql                                        # only if product mapping seed needed
docs/supabase/README.md                                                # canonical doc correction
```

Expected new files:

```text
lib/app_versions/v2/features/payments/domain/entities/store_membership_purchase.dart
lib/app_versions/v2/features/payments/domain/repositories/membership_store_billing_repository.dart
lib/app_versions/v2/features/payments/data/datasources/google_play_billing_datasource.dart
lib/app_versions/v2/features/payments/data/models/google_play_purchase_dto.dart
lib/app_versions/v2/features/payments/data/repositories/membership_store_billing_repository_impl.dart
lib/app_versions/v2/features/payments/providers/membership_store_billing_providers.dart
supabase/functions/google-play-verify-purchase/index.ts
supabase/functions/google-play-verify-purchase/handler.ts
```

Tests:

```text
test/app_versions/v2/features/payments/membership_payment_test.dart
test/app_versions/v2/features/payments/membership_payment_rpc_contract_test.dart
test/app_versions/v2/features/payments/presentation/membership_payment_page_test.dart
test/app_versions/v2/features/payments/data/google_play_billing_datasource_test.dart
test/app_versions/v2/features/payments/data/membership_store_billing_repository_impl_test.dart
test/app_versions/v2/features/payments/providers/membership_store_billing_providers_test.dart
test/app_versions/v2/features/payments/presentation/membership_payment_play_billing_test.dart
supabase/functions/google-play-verify-purchase/handler_test.ts
```

## 16.2 P0-02 AI reporting

Expected modifications:

```text
lib/app_versions/v1/features/ai_chat/presentation/pages/ai_chat_screen.dart
lib/app_versions/v1/features/ai_chat/providers/ai_chat_providers.dart
docs/supabase/01_build_system.sql
```

Possible modification:

```text
lib/app_versions/v1/features/ai_chat/presentation/controllers/ai_chat_controller.dart
```

Preferred new files:

```text
lib/app_versions/v1/features/ai_chat/domain/entities/ai_content_report.dart
lib/app_versions/v1/features/ai_chat/domain/repositories/ai_content_report_repository.dart
lib/app_versions/v1/features/ai_chat/data/datasources/ai_content_report_remote_datasource.dart
lib/app_versions/v1/features/ai_chat/data/repositories/ai_content_report_repository_impl.dart
lib/app_versions/v1/features/ai_chat/presentation/controllers/ai_content_report_controller.dart
lib/app_versions/v1/features/ai_chat/presentation/widgets/ai_content_report_sheet.dart
supabase/functions/report-ai-content/index.ts
supabase/functions/report-ai-content/handler.ts
```

Tests:

```text
test/app_versions/v1/features/ai_chat/ai_content_report_test.dart
test/app_versions/v1/features/ai_chat/ai_chat_screen_report_test.dart
supabase/functions/report-ai-content/handler_test.ts
```

## 16.3 Android release/media

```text
android/app/build.gradle.kts
android/app/src/main/AndroidManifest.xml
```

Only modify additional Gradle/toolchain files if a proven build error requires it.

## 16.4 Gemini backend migration

Expected modifications:

```text
android/app/build.gradle.kts
android/app/src/main/kotlin/com/example/nano_app/MainActivity.kt
lib/core/config/app_env.dart
lib/main.dart
lib/app_versions/v1/features/ai_chat/data/datasources/gemini_nabi_care_ai_gateway.dart
lib/app_versions/v1/services/ai/gemini_rest_client.dart                 # remove from production path or replace semantics
```

Expected new:

```text
lib/app_versions/v1/services/ai/nanobio_ai_backend_client.dart
supabase/functions/nabi-ai-generate/index.ts
supabase/functions/nabi-ai-generate/handler.ts
```

Additional AI service files only if search proves they directly depend on direct Gemini transport.

## 16.5 Supabase/deletion

```text
docs/supabase/01_build_system.sql
docs/supabase/02_seed_data.sql       # only if needed
docs/supabase/README.md
supabase/functions/delete-account/handler.ts
supabase/functions/delete-account/index.ts   # only if wiring/config changes
.codex/history/OPEN_RISKS.md                  # only after real verification
```

## 16.6 Release documentation

Create/reuse equivalent paths:

```text
docs/release/google_play/README.md
docs/release/google_play/DATA_SAFETY_MAPPING.md
docs/release/google_play/HEALTH_APPS_DECLARATION.md
docs/release/google_play/ACCOUNT_DELETION.md
docs/release/google_play/FOREGROUND_SERVICE_DECLARATION.md
docs/release/google_play/STORE_LISTING_CLAIMS_REVIEW.md
```

Do not create duplicates when canonical legal/release docs already exist elsewhere.

---

# 17. DO-NOT-TOUCH / ANTI-SCOPE-CREEP LIST

Unless required by a direct failing dependency, do not modify:

- Nabi image assets;
- meal catalog/content;
- onboarding flow;
- unrelated dashboard modules;
- unrelated health calculators;
- admin UI outside payment moderation needed by migration;
- Sale/referral UX unless runtime verification exposes a release-critical defect;
- iOS platform code for this Android Google Play task;
- AGP/Gradle versions merely to silence future-warning messages;
- community Coming Soon feature;
- SQLite version unless this task truly adds required local schema;
- unrelated DD/BD files;
- old worklogs.

---

# 18. FAILURE/ROLLBACK RULES

## 18.1 Billing migration failure

If Play Billing implementation cannot be completed because Play product IDs/service credentials/console configuration are unavailable:

- complete client abstraction + backend contract + tests using fakes;
- keep Play consumer VietQR disabled for release path;
- mark P0-01 `OPEN — BLOCKED` for real purchase verification;
- do not restore non-compliant QR fallback as a convenience workaround.

## 18.2 Gemini proxy failure

If backend deployment credentials are unavailable:

- implement/test server function locally;
- remove production client secret path only when production backend endpoint can be configured safely;
- if removing it makes release AI unusable, mark release blocked rather than re-embedding secret.

## 18.3 Supabase verification unavailable

If local/sandbox Supabase cannot run:

- do static schema review;
- add tests/scripts that can run when environment is available;
- do not close `NB-RISK-001`.

## 18.4 Release signing unavailable

- build debug/profile or unsigned-equivalent artifacts where useful;
- do not create/commit a fake release keystore;
- mark signed-AAB checks blocked.

## 18.5 Play Console unavailable

- finish repository work;
- generate exact manual checklist/data mappings;
- leave manual gates open.

---

# 19. FINAL DELIVERABLES

## 19.1 Repository result

A working repository state containing only necessary source/test/config/docs changes for release remediation.

## 19.2 Evidence summary

At the end, Codex must report:

```text
1. Baseline commit used
2. Changed files grouped by blocker
3. New files grouped by blocker
4. Tests run + result
5. Builds run + result
6. Supabase sandbox checks + result
7. Final AAB metadata if built
8. P0/P1 GO-NO-GO matrix
9. Manual Play Console gates still open
10. Any deviations from this plan and why
```

## 19.3 ZIP packaging rule

When execution is fully complete, create a ZIP containing **only new/modified project files**, preserving project-relative paths.

Example:

```text
NanoBioAI_google_play_release_remediation.zip
├── android/
├── lib/
├── supabase/
├── test/
├── docs/                 # only intentionally modified/new canonical docs
├── pubspec.yaml
└── pubspec.lock
```

Do NOT include:

- `.git/`
- build outputs;
- `.dart_tool/`
- generated caches;
- APK/AAB unless explicitly requested as part of delivery;
- secret files;
- keystore;
- local `.env`;
- patch/diff files;
- temporary notes;
- private execution scratchpads;
- unrelated reports.

## 19.4 Completion message

Do not say “Google Play ready” if any Play Console/manual/runtime gate remains open.

Use one of:

- `SOURCE-READY — external Play verification pending`
- `RELEASE-VERIFY — internal track validation pending`
- `GO — all required evidence verified`
- `NO-GO — blocker(s) remain`

---

# 20. DEFINITION OF DONE FOR THE ENTIRE GOAL

The Goal Mode run is complete only when all safe in-repo work has been executed and every remaining external dependency is explicitly identified.

Minimum acceptable completion state before attempting Production:

### P0

- [ ] Play Billing consumer flow implemented.
- [ ] Server-side purchase verification implemented.
- [ ] Real/internal-track billing verification completed.
- [ ] AI report/flag action visible on every assistant message.
- [ ] AI report persists successfully.
- [ ] Final AAB target API >= 36 proven.

### P1

- [ ] `READ_MEDIA_IMAGES` removed or justified by proven core use case.
- [ ] Gemini reusable secret removed from production client.
- [ ] Supabase sandbox rebuild passes.
- [ ] RLS negative tests pass.
- [ ] Membership/payment/referral lifecycle tests pass.
- [ ] Account deletion associated-data matrix passes.

### Artifact/runtime

- [ ] Foreground microphone service tested on modern Android.
- [ ] 16 KB compatibility verified.
- [ ] Release AAB builds.
- [ ] Pre-launch report reviewed.
- [ ] No release-blocking crash/ANR.

### Play Console/legal

- [ ] Health Apps Declaration complete.
- [ ] Data Safety complete and matches runtime.
- [ ] public Privacy Policy URL works.
- [ ] external account deletion URL works.
- [ ] FGS declaration complete.
- [ ] content rating/target audience complete.
- [ ] App Access reviewer instructions complete.
- [ ] store listing medical claims reviewed.
- [ ] billing declaration/product setup complete.

### Delivery

- [ ] targeted tests pass.
- [ ] full analyzer/test result recorded.
- [ ] project integrity validator result recorded.
- [ ] final changed-file review performed.
- [ ] final ZIP contains only intended changed/new files in project structure.

If any required P0 remains unchecked, final status MUST remain `NO-GO`.

---

# 21. COPY-PASTE GOAL MODE PROMPT FOR GPT-5.6 LUNA

Use the following as the Goal Mode instruction after placing this plan inside/alongside the repository:

```text
GOAL
Bring NanoBioAI from the Google Play audit status NO-GO to the strongest verifiable release-ready state by executing NanoBioAI_GOAL_MODE_GOOGLE_PLAY_REMEDIATION_PLAN.md against the current repository.

SOURCE OF TRUTH
1. AGENTS.md
2. .codex/AGENTS.md
3. current reachable source code
4. executable Supabase/SQLite/config
5. tests
6. current docs
7. the remediation plan
If the plan and current source conflict, preserve the plan's requirement/acceptance criteria but adapt the implementation to current source. Do not invent missing files merely because stale docs mention them.

AUTONOMY
You are authorized to inspect files, make all in-scope local code/test/config/documentation changes, run non-destructive validation, build artifacts, and use disposable/local/sandbox test data. Continue through independent phases without asking for approval after each normal edit.

STOP / REQUIRE CONFIRMATION ONLY FOR
- destructive production operations;
- purchases or paid resource creation;
- Production Play Store submission;
- production secret rotation/revocation;
- a material product-policy decision that changes the stated Goal;
- material expansion outside this release-remediation scope.
External blockers must not prevent completion of independent local work.

EXECUTION RULES
- Follow the plan's phase/dependency order.
- Work on one active sub-goal at a time.
- Before changing a sub-goal, re-read its owning files/direct tests.
- Preserve Presentation → Provider/Controller → Repository → Datasource → DAO/API.
- Do not put billing/Supabase/Gemini persistence logic directly in UI.
- Do not ship mock data or secrets.
- Do not use VietQR as a fallback purchase path in the Google Play consumer build unless approved alternative-billing evidence exists.
- Never activate paid membership from client-reported purchase state without trusted server verification.
- AI report/flag must work in-app and persist; safety prompts alone are not a substitute.
- Do not close Supabase/account-deletion risks from static review alone.
- Do not claim Play Console/AAB/device evidence unless actually observed.
- After every sub-goal: format, run targeted tests/analyzer, inspect diff, repair, then continue.
- Avoid unrelated refactors.

DONE WHEN
All in-repo P0/P1 remediations are implemented, tests/builds are run, sandbox verification is completed where available, final AAB evidence is gathered where available, and the final GO/NO-GO matrix explicitly shows every remaining external/manual gate. Package only changed/new project files preserving repository structure; include no patches, secrets, caches, temporary notes, or unrelated files.

FINAL RESPONSE
Return:
1. actual baseline commit;
2. changed/new file list grouped by blocker;
3. validation/test/build evidence;
4. sandbox/runtime evidence;
5. final P0/P1/manual gate matrix;
6. remaining blockers;
7. ZIP path containing only changed/new project files.
Do not call the app Google-Play-ready unless every required release gate has real evidence.
```

