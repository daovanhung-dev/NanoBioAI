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
      final existingGuestUserId = authUserId == null
          ? await AppPrefs.pendingGuestUserId()
          : null;

      AppLogger.info(_tag, 'Saving onboarding to local datasource first');
      final localUserId = await localDatasource.saveOnboarding(
        entity,
        userIdOverride: authUserId,
        existingGuestUserId: existingGuestUserId,
      );

      if (authUserId == null) {
        // Persist immediately after the first successful local transaction.
        // Any downstream AI/network failure can now retry against this exact
        // guest row instead of resolving identity from nullable email/phone.
        await AppPrefs.setPendingGuestUserId(localUserId);
      } else {
        await AppPrefs.clearPendingGuestUserId();
      }
      AppLogger.success(_tag, 'Local onboarding draft saved successfully');
    } catch (error) {
      AppLogger.error(_tag, 'Repository save failed', error);
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
  }

  String? _resolvedAuthenticatedSubjectId() {
    final authUserId = currentUserId();
    if (authUserId == null || authUserId.trim().isEmpty) return null;
    return (subjectAccessContext() ?? SubjectAccessContext(actorId: authUserId))
        .resolveSubjectId();
  }
}
