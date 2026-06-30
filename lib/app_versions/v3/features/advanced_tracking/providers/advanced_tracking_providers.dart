import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v2/features/membership_entitlement/domain/entities/effective_access.dart';
import 'package:nano_app/app_versions/v2/features/membership_entitlement/providers/membership_entitlement_providers.dart';
import 'package:nano_app/services/supabase/auth/current_auth_user.dart';

import '../application/advanced_tracking_goals_fn01.dart';
import '../application/advanced_tracking_goals_fn02.dart';
import '../data/datasources/sqlite_advanced_tracking_local_datasource.dart';
import '../data/repositories/local_advanced_tracking_repository.dart';
import '../domain/entities/advanced_tracking_models.dart';
import '../domain/repositories/advanced_tracking_repository.dart';

enum AdvancedTrackingViewStatus { authRequired, locked, empty, ready, failure }

class AdvancedTrackingViewModel {
  final AdvancedTrackingViewStatus status;
  final AdvancedTrackingRoadmapResult? result;
  final String? message;

  const AdvancedTrackingViewModel._({
    required this.status,
    this.result,
    this.message,
  });

  const AdvancedTrackingViewModel.authRequired()
    : this._(
        status: AdvancedTrackingViewStatus.authRequired,
        message: 'Bạn cần đăng nhập để xem lộ trình nâng cao.',
      );

  const AdvancedTrackingViewModel.locked()
    : this._(
        status: AdvancedTrackingViewStatus.locked,
        message:
            'Lộ trình nâng cao dành cho Plus và FamilyPlus. Nabi sẽ mở khi gói của bạn sẵn sàng.',
      );

  const AdvancedTrackingViewModel.empty(AdvancedTrackingRoadmapResult result)
    : this._(
        status: AdvancedTrackingViewStatus.empty,
        result: result,
        message: 'Bạn có thể bắt đầu với mục tiêu uống đủ nước mỗi ngày.',
      );

  const AdvancedTrackingViewModel.ready(AdvancedTrackingRoadmapResult result)
    : this._(status: AdvancedTrackingViewStatus.ready, result: result);

  const AdvancedTrackingViewModel.failure(String message)
    : this._(status: AdvancedTrackingViewStatus.failure, message: message);
}

final advancedTrackingCurrentUserIdProvider = Provider<String?>((ref) {
  return currentSupabaseUserIdOrNull();
});

final advancedTrackingNowProvider = Provider<DateTime Function()>((ref) {
  return DateTime.now;
});

final advancedTrackingEffectiveAccessProvider =
    FutureProvider<EffectiveAccess?>((ref) {
      return ref.watch(effectiveAccessProvider.future);
    });

final advancedTrackingLocalDatasourceProvider =
    Provider<SqliteAdvancedTrackingLocalDatasource>((ref) {
      return const SqliteAdvancedTrackingLocalDatasource();
    });

final advancedTrackingRepositoryProvider = Provider<AdvancedTrackingRepository>(
  (ref) {
    return LocalAdvancedTrackingRepository(
      datasource: ref.watch(advancedTrackingLocalDatasourceProvider),
    );
  },
);

final advancedTrackingFn01Provider = Provider<AdvancedTrackingGoalsFn01>((ref) {
  return AdvancedTrackingGoalsFn01(
    repository: ref.watch(advancedTrackingRepositoryProvider),
  );
});

final advancedTrackingFn02Provider = Provider<AdvancedTrackingGoalsFn02>((ref) {
  return AdvancedTrackingGoalsFn02(
    repository: ref.watch(advancedTrackingRepositoryProvider),
  );
});

final advancedTrackingSummaryProvider =
    FutureProvider<AdvancedTrackingViewModel>((ref) async {
      final userId = ref.watch(advancedTrackingCurrentUserIdProvider);
      if (userId == null || userId.trim().isEmpty) {
        return const AdvancedTrackingViewModel.authRequired();
      }

      final access = await ref.watch(
        advancedTrackingEffectiveAccessProvider.future,
      );
      if (access == null || !access.hasPaidAccess) {
        return const AdvancedTrackingViewModel.locked();
      }

      final now = ref.watch(advancedTrackingNowProvider)();
      final actor = _actorContextFor(userId: userId, access: access);
      try {
        final result = await ref
            .watch(advancedTrackingFn02Provider)
            .execute(LoadGoalRoadmapCommand(actor: actor, now: now));
        if (!result.hasGoal) {
          return AdvancedTrackingViewModel.empty(result);
        }
        return AdvancedTrackingViewModel.ready(result);
      } on AdvancedTrackingException catch (error) {
        if (error.code == 'AUTH_REQUIRED') {
          return const AdvancedTrackingViewModel.authRequired();
        }
        if (error.code == 'FORBIDDEN') {
          return const AdvancedTrackingViewModel.locked();
        }
        return AdvancedTrackingViewModel.failure(error.safeMessage);
      } catch (_) {
        return const AdvancedTrackingViewModel.failure(
          'Nabi chưa thể tải lộ trình lúc này. Mình thử lại sau một chút nhé.',
        );
      }
    });

final advancedTrackingCreateHydrationGoalProvider =
    Provider<Future<void> Function()>((ref) {
      return () async {
        final userId = ref.read(advancedTrackingCurrentUserIdProvider);
        final access = await ref.read(
          advancedTrackingEffectiveAccessProvider.future,
        );
        if (userId == null || userId.trim().isEmpty) {
          throw const AdvancedTrackingException.authRequired();
        }
        if (access == null || !access.hasPaidAccess) {
          throw const AdvancedTrackingException.forbidden();
        }

        final now = ref.read(advancedTrackingNowProvider)();
        final actor = _actorContextFor(userId: userId, access: access);
        await ref
            .read(advancedTrackingFn01Provider)
            .execute(CreateAdvancedGoalCommand(actor: actor, now: now));
        ref.invalidate(advancedTrackingSummaryProvider);
      };
    });

AdvancedTrackingActorContext _actorContextFor({
  required String userId,
  required EffectiveAccess access,
}) {
  return AdvancedTrackingActorContext(
    actorId: userId,
    hasPaidAccess: access.hasPaidAccess,
    isFamilyPlus: access.isFamilyPlus,
  );
}
