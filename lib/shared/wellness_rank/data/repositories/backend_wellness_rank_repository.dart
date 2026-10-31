import '../../domain/entities/wellness_rank_summary.dart';
import '../../domain/repositories/wellness_rank_repository.dart';
import '../datasources/wellness_rank_local_store.dart';
import '../datasources/backend_wellness_rank_remote_datasource.dart';

class BackendWellnessRankRepository implements WellnessRankRepository {
  final WellnessRankRemoteDatasource remoteDatasource;
  final WellnessRankLocalStore localDatasource;
  final String? Function() currentUserId;

  const BackendWellnessRankRepository({
    required this.remoteDatasource,
    required this.localDatasource,
    required this.currentUserId,
  });

  @override
  Future<WellnessRankSummary> loadSummary(String userId) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'must not be empty');
    }
    try {
      if (currentUserId()?.trim() != normalizedUserId) {
        throw StateError('wellness_rank_auth_changed');
      }
      final remote = WellnessRankSummary.fromMap(
        await remoteDatasource.loadSummary(),
        lastSyncedAt: DateTime.now().toUtc(),
      );
      if (currentUserId()?.trim() != normalizedUserId) {
        throw StateError('wellness_rank_auth_changed');
      }
      await localDatasource.save(normalizedUserId, remote);
      return remote;
    } catch (_) {
      final cached = await localDatasource.load(normalizedUserId);
      if (cached != null) return cached.asStale();
      rethrow;
    }
  }
}
