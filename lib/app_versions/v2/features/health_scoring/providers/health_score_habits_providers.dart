import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/services/supabase/auth/current_auth_user.dart';

import '../application/health_score_habits_fn01.dart';
import '../application/health_score_habits_fn02.dart';
import '../data/datasources/sqlite_health_score_habits_local_datasource.dart';
import '../data/repositories/local_health_score_habits_repository.dart';
import '../domain/entities/health_score_habits_models.dart';
import '../domain/repositories/health_score_habits_repository.dart';

enum HealthScoreHabitsViewStatus { authRequired, empty, ready, failure }

class HealthScoreHabitsViewModel {
  final HealthScoreHabitsViewStatus status;
  final HealthScoreHabitsResult? result;
  final String? message;

  const HealthScoreHabitsViewModel._({
    required this.status,
    this.result,
    this.message,
  });

  const HealthScoreHabitsViewModel.authRequired()
    : this._(
        status: HealthScoreHabitsViewStatus.authRequired,
        message: 'Please sign in to view health score.',
      );

  const HealthScoreHabitsViewModel.empty(HealthScoreHabitsResult result)
    : this._(
        status: HealthScoreHabitsViewStatus.empty,
        result: result,
        message: 'No local completion history is available for this period.',
      );

  const HealthScoreHabitsViewModel.ready(HealthScoreHabitsResult result)
    : this._(status: HealthScoreHabitsViewStatus.ready, result: result);

  const HealthScoreHabitsViewModel.failure(String message)
    : this._(status: HealthScoreHabitsViewStatus.failure, message: message);
}

final healthScoreHabitsCurrentUserIdProvider = Provider<String?>((ref) {
  return currentSupabaseUserIdOrNull();
});

final healthScoreHabitsNowProvider = Provider<DateTime Function()>((ref) {
  return DateTime.now;
});

final healthScoreHabitsLocalDatasourceProvider =
    Provider<SqliteHealthScoreHabitsLocalDatasource>((ref) {
      return const SqliteHealthScoreHabitsLocalDatasource();
    });

final healthScoreHabitsRepositoryProvider =
    Provider<HealthScoreHabitsRepository>((ref) {
      return LocalHealthScoreHabitsRepository(
        datasource: ref.watch(healthScoreHabitsLocalDatasourceProvider),
      );
    });

final healthScoreHabitsFn01Provider = Provider<HealthScoreHabitsFn01>((ref) {
  return HealthScoreHabitsFn01(
    repository: ref.watch(healthScoreHabitsRepositoryProvider),
  );
});

final healthScoreHabitsFn02Provider = Provider<HealthScoreHabitsFn02>((ref) {
  return HealthScoreHabitsFn02(
    repository: ref.watch(healthScoreHabitsRepositoryProvider),
  );
});

final healthScoreHabitsSummaryProvider =
    FutureProvider<HealthScoreHabitsViewModel>((ref) async {
      final userId = ref.watch(healthScoreHabitsCurrentUserIdProvider);
      if (userId == null || userId.trim().isEmpty) {
        return const HealthScoreHabitsViewModel.authRequired();
      }

      final now = ref.watch(healthScoreHabitsNowProvider)();
      try {
        final scoreResult = await ref
            .watch(healthScoreHabitsFn01Provider)
            .execute(CalculateHealthScoreCommand(actorId: userId, now: now));
        final progressResult = await ref
            .watch(healthScoreHabitsFn02Provider)
            .execute(LoadHabitProgressCommand(actorId: userId, now: now));
        final result = HealthScoreHabitsResult(
          score: scoreResult.score,
          formulaVersion: scoreResult.formulaVersion,
          period: scoreResult.period,
          hasInputs: scoreResult.hasInputs,
          breakdown: scoreResult.breakdown,
          habitProgress: progressResult.habitProgress,
        );

        if (!result.hasInputs) {
          return HealthScoreHabitsViewModel.empty(result);
        }
        return HealthScoreHabitsViewModel.ready(result);
      } on HealthScoreHabitsException catch (error) {
        if (error.code == 'AUTH_REQUIRED') {
          return const HealthScoreHabitsViewModel.authRequired();
        }
        return HealthScoreHabitsViewModel.failure(error.safeMessage);
      } catch (_) {
        return const HealthScoreHabitsViewModel.failure(
          'Health score is temporarily unavailable. Please try again later.',
        );
      }
    });
