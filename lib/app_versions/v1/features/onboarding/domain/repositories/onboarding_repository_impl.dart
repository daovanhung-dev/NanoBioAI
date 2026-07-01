import 'package:nano_app/core/utils/logger/app_logger.dart';
import 'package:nano_app/core/access/subject_access_context.dart';
import 'package:nano_app/core/storage/localdb/app_prefs.dart';
import 'package:nano_app/services/supabase/auth/current_auth_user.dart';

import '../../data/datasource/onboarding_local_datasource.dart';
import '../entities/onboarding_entity.dart';
import 'onboarding_repository.dart';

typedef CurrentUserIdReader = String? Function();
typedef SubjectAccessContextReader = SubjectAccessContext? Function();

class OnboardingRepositoryImpl implements OnboardingRepository {
  static const _tag = 'ONBOARDING_REPO';

  final OnboardingLocalDatasource localDatasource;
  final CurrentUserIdReader currentUserId;
  final SubjectAccessContextReader subjectAccessContext;

  OnboardingRepositoryImpl({
    required this.localDatasource,
    CurrentUserIdReader? currentUserId,
    SubjectAccessContextReader? subjectAccessContext,
  }) : currentUserId = currentUserId ?? currentSupabaseUserIdOrNull,
       subjectAccessContext = subjectAccessContext ?? (() => null);

  @override
  Future<void> save(OnboardingEntity entity) async {
    try {
      final authUserId = _resolvedAuthenticatedSubjectId();

      // SQLite is always written first. Version 12 database triggers create an
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
    final userId =
        _resolvedAuthenticatedSubjectId() ??
        await AppPrefs.pendingGuestUserId();
    if (userId == null || userId.trim().isEmpty) {
      AppLogger.warning(
        _tag,
        'No local user found to mark onboarding complete',
      );
      return;
    }

    await localDatasource.markOnboardingCompleted(userId);
    AppLogger.success(_tag, 'Local onboarding status marked completed');

    // The local datasource emits a post-commit sync signal. At app startup,
    // the root composition maps that signal to the authenticated Supabase
    // outbox without making V1 depend on the cloud-sync implementation.
  }

  String? _resolvedAuthenticatedSubjectId() {
    final authUserId = currentUserId();
    if (authUserId == null || authUserId.trim().isEmpty) return null;
    return (subjectAccessContext() ?? SubjectAccessContext(actorId: authUserId))
        .resolveSubjectId();
  }
}
