import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/network/backend_api_client.dart';

import '../data/datasources/wellness_rank_local_datasource.dart';
import '../data/datasources/backend_wellness_rank_remote_datasource.dart';
import '../data/repositories/backend_wellness_rank_repository.dart';
import '../domain/entities/wellness_rank_summary.dart';
import '../domain/repositories/wellness_rank_repository.dart';

final wellnessRankUserIdProvider = StreamProvider<String?>((ref) async* {
  yield* BackendApiClient.shared.authChanges;
});

final wellnessRankRemoteDatasourceProvider =
    Provider<WellnessRankRemoteDatasource>(
      (ref) => const BackendWellnessRankRemoteDatasource(),
    );

final wellnessRankLocalDatasourceProvider =
    Provider<WellnessRankLocalDatasource>(
      (ref) => const WellnessRankLocalDatasource(),
    );

final wellnessRankRepositoryProvider = Provider<WellnessRankRepository>((ref) {
  return BackendWellnessRankRepository(
    remoteDatasource: ref.watch(wellnessRankRemoteDatasourceProvider),
    localDatasource: ref.watch(wellnessRankLocalDatasourceProvider),
    currentUserId: () {
      return BackendApiClient.shared.currentUserId;
    },
  );
});

final wellnessRankSummaryProvider = FutureProvider.autoDispose
    .family<WellnessRankSummary?, String>((ref, userId) async {
      final normalizedUserId = userId.trim();
      if (normalizedUserId.isEmpty) return null;
      return ref
          .watch(wellnessRankRepositoryProvider)
          .loadSummary(normalizedUserId);
    });
