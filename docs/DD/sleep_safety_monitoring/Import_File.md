# Import / File Map — M31

## Existing files modified

- `lib/app_versions/v1/features/features_hub/presentation/pages/features_hub_page.dart`
- `lib/app_versions/v1/features/sleep_tracking/presentation/pages/sleep_tracking_page.dart`
- `lib/app_versions/v1/features/sleep_tracking/presentation/pages/sleep_safety_access_gate.dart`
- `lib/app_versions/v1/features/sleep_tracking/providers/sleep_safety_controller.dart`
- `lib/app_versions/v1/features/sleep_tracking/providers/sleep_safety_providers.dart`
- `lib/app_versions/v1/router/v1_router.dart`
- `lib/app_versions/v1/services/notifications/notification_bootstrap.dart`
- `lib/app_versions/v1/services/notifications/notification_navigation_coordinator.dart`
- `lib/core/storage/localdb/database_service.dart`
- `lib/core/storage/localdb/database_version.dart`
- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/kotlin/com/example/nano_app/MainActivity.kt`
- `ios/Runner/AppDelegate.swift`
- `ios/Runner/Info.plist`
- `docs/supabase/README.md`

## New Flutter source

`lib/app_versions/v1/features/sleep_tracking/`

- domain entities/services/repository
- data model/local/cloud/reminder/native gateway/repository implementation
- Riverpod providers/controller
- access gate, contacts, schedule, history pages
- alert/status/disclaimer/countdown widgets

## New SQLite source

- `tables/sleep_safety_tables.dart`
- `daos/sleep_safety_dao.dart`
- `migrations/migration_v21.dart`
- `migrations/migration_v26.dart`
- `migrations/migration_v27.dart` — unverified voice-alert consent, default off

No new pub package is required. Existing `permission_handler`,
`flutter_local_notifications`, `connectivity_plus`, `url_launcher`, Riverpod,
GoRouter, sqflite and Supabase are used.

## M31 direct help-call and channel-removal delta

- Domain: dispatch retry/result/exception and runtime configuration entities.
- Data: connectivity and phone gateways; cloud runtime/contact preference
  mapping; minimal SQLite outbox retry operations.
- Presentation: direct help-call selection, alert action and bounded automatic
  no-response retry in `SleepSafetyController`.
- Android: `CALL_PHONE` permission and explicit `ACTION_CALL`; permission or
  native launch failure falls back to `ACTION_DIAL`. iOS uses `tel:`.
- Supabase: canonical contract plus forward channel-removal migration
  `20261006120000_m31_remove_zalo_channel.sql`.
- Edge: dispatch and callback contain only voice/SMS for automatic no-response.
- Local database targets SQLite v28 and preserves cached contacts while
  removing the obsolete preference column.
- QA: migrations 09:00–12:00 and both changed Edge Functions are applied to
  project `rnwohifdnylqfofkydfl`; the verified QA schema has one preserved
  contact and no Zalo dispatch history. One Xiaomi call acceptance passed, the
  temporary contact was removed, and the phone-call flag is restored to `false`;
  production is unchanged.

## v1.3 unverified voice-alert delta

- Contact domain/cache/RPC add `allow_unverified_voice_alert`, default false.
- Supabase retains the legacy 5-argument contact RPC; the app uses the current
  7-argument overload.
- Edge dispatch and provider callback allow voice-only cascade to opted-in
  unverified contacts; they never send SMS to those contacts.
- SQLite v27 added this consent; SQLite v28 preserves it while removing the
  retired Zalo preference. Forward migrations `20261006110000` and
  `20261006120000` are applied on QA; earlier applied migrations remain intact.

## New Android source

`android/app/src/main/kotlin/com/example/nano_app/sleep_safety/`

- `SleepSafetyNativeEvent.kt`
- `SleepSafetyDetector.kt`
- `SleepSafetyAudioCapture.kt`
- `SleepSafetyNotificationFactory.kt`
- `SleepSafetyForegroundService.kt`
- `SleepSafetyChannelHandler.kt`

No additional Gradle library is required; Android framework audio/service APIs
are used.

## iOS source choice

M31 native bridge/runtime is placed in the existing `ios/Runner/AppDelegate.swift`
in this delivery. This avoids adding Swift source files that would also require
unsafe manual Xcode `project.pbxproj` edits in an environment without Xcode.
A later native refactor may split the classes after Xcode target membership is
verified.

## Supabase / Edge

- `docs/supabase/01_build_system.sql`
- `docs/supabase/02_seed_data.sql`
- `_shared/sleep_safety_provider.ts`
- `sleep-safety-contact-verification/`
- `sleep-safety-dispatch/`
- `sleep-safety-provider-webhook/`

`01_build_system.sql` owns M31 schema, runtime support and rollout;
`02_seed_data.sql` owns the destructive sandbox fixture reset. Run them in
that order; neither file is generated.


## Enable-paid / FeatureHub verification files

- `test/app_versions/v1/features/features_hub/sleep_safety_feature_entry_test.dart`
- `test/app_versions/v1/features/sleep_tracking/presentation/sleep_safety_access_gate_test.dart`
- `test/app_versions/v1/features/sleep_tracking/providers/sleep_safety_controller_test.dart`
- `test/docs/supabase_two_script_rebuild_contract_test.dart`

No new package is introduced by the rollout/FeatureHub activation delta.
