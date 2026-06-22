import 'dart:async';

import 'package:nano_app/core/utils/logger/app_logger.dart';
import 'package:nano_app/core/storage/localdb/app_prefs.dart';
import 'package:nano_app/services/supabase/auth/auth_profile_service.dart';
import 'package:nano_app/services/supabase/cloud_sync/user_data_sync_outbox.dart';

import '../../data/datasource/onboarding_local_datasource.dart';
import '../entities/onboarding_entity.dart';
import 'onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  static const _tag = 'ONBOARDING_REPO';

  final OnboardingLocalDatasource localDatasource;
  final AuthProfileService authProfileService;

  OnboardingRepositoryImpl({
    required this.localDatasource,
    this.authProfileService = const AuthProfileService(),
  });

  @override
  Future<void> save(OnboardingEntity entity) async {
    try {
      final authUserId = authProfileService.currentUserId;

      // SQLite is always written first. Version 9 database triggers create an
      // outbox marker in this same local transaction; authenticated sessions
      // then upload one complete snapshot. This avoids a partially completed
      // cloud onboarding record before the first AI schedule is generated.
      AppLogger.info(_tag, 'Saving onboarding to local datasource first');
      final localUserId = await localDatasource.saveOnboarding(
        entity,
        userIdOverride: authUserId,
      );

      if (authUserId == null) {
        await AppPrefs.setPendingGuestUserId(localUserId);
      } else {
        await AppPrefs.clearPendingGuestUserId();
      }
      AppLogger.success(_tag, 'Local onboarding draft saved successfully');
    } catch (e, st) {
      AppLogger.error(_tag, 'Repository save failed', e, st);
      rethrow;
    }
  }

  @override
  Future<void> markCompleted() async {
    final userId = authProfileService.currentUserId ??
        await AppPrefs.pendingGuestUserId();
    if (userId == null || userId.trim().isEmpty) {
      AppLogger.warning(_tag, 'No local user found to mark onboarding complete');
      return;
    }

    await localDatasource.markOnboardingCompleted(userId);
    AppLogger.success(_tag, 'Local onboarding status marked completed');

    // Do not block navigation on a network request. The outbox is durable and
    // retries failures, while this best-effort drain makes the completion
    // snapshot reach Supabase immediately for an authenticated account.
    if (authProfileService.currentUserId != null) {
      unawaited(UserDataSyncOutbox.drainForCurrentUser());
    }
  }
}
