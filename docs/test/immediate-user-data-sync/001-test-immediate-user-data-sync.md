# Validation — immediate user-data sync request

Commit de xuat: `test(sync): cover the local post-commit dispatcher`

## Automated test added

- `test/core/storage/localdb/sync/local_user_data_sync_dispatcher_test.dart`
  - verifies a committed local-write signal reaches the registered app-level handler exactly once.

## Recommended validation commands

```bash
flutter test test/core/storage/localdb/sync/local_user_data_sync_dispatcher_test.dart
flutter test test/services/supabase/cloud_sync/user_data_sync_outbox_test.dart
flutter test test/app_versions/v1/features/onboarding/onboarding_local_datasource_test.dart
flutter test test/features/lifestyle_schedule/data/lifestyle_schedule_completion_test.dart
flutter test test/features/settings/profile_update_contract_test.dart
flutter analyze
```

## Runtime status

SKIPPED in this environment because the supplied workspace has no Flutter or Dart executable. No PASS claim is made.

## Manual acceptance path

1. Sign in to a test account.
2. Complete onboarding and verify a cloud snapshot is visible after plan generation and completion.
3. Complete and skip normal schedule items, then relaunch/sign in on another device or fresh local storage and verify status matches.
4. Edit profile values and avatar, then verify cloud data is updated.
5. Disable network during an action, restore it, and verify the queued outbox synchronizes without data loss.
