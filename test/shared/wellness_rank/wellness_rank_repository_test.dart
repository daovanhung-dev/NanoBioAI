import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/shared/wellness_rank/data/datasources/wellness_rank_local_store.dart';
import 'package:nano_app/shared/wellness_rank/data/datasources/wellness_rank_remote_datasource.dart';
import 'package:nano_app/shared/wellness_rank/data/repositories/supabase_wellness_rank_repository.dart';
import 'package:nano_app/shared/wellness_rank/domain/entities/wellness_rank_summary.dart';

void main() {
  test(
    'loads server summary and reuses only that user cache when offline',
    () async {
      final local = _FakeRankLocalStore();
      final remote = _FakeRankRemote(_summary(600));
      final repository = SupabaseWellnessRankRepository(
        remoteDatasource: remote,
        localDatasource: local,
        currentUserId: () => 'user-a',
      );

      final fresh = await repository.loadSummary('user-a');
      expect(fresh.rankLevel, 2);
      expect(fresh.isStale, isFalse);

      remote.fail = true;
      final stale = await repository.loadSummary('user-a');
      expect(stale.experiencePoints, 600);
      expect(stale.isStale, isTrue);
      await expectLater(repository.loadSummary('user-b'), throwsStateError);
    },
  );

  test('does not cache a response after the signed-in user changes', () async {
    final local = _FakeRankLocalStore();
    final remote = _FakeRankRemote(_summary(600));
    var activeUserId = 'user-a';
    remote.beforeReturn = () => activeUserId = 'user-b';
    final repository = SupabaseWellnessRankRepository(
      remoteDatasource: remote,
      localDatasource: local,
      currentUserId: () => activeUserId,
    );

    await expectLater(repository.loadSummary('user-a'), throwsStateError);
    expect(local.rows, isEmpty);
  });
}

class _FakeRankRemote implements WellnessRankRemoteDatasource {
  final Map<String, Object?> response;
  bool fail = false;
  void Function()? beforeReturn;

  _FakeRankRemote(this.response);

  @override
  Future<Map<String, Object?>> loadSummary() async {
    if (fail) throw StateError('offline');
    beforeReturn?.call();
    return response;
  }
}

class _FakeRankLocalStore implements WellnessRankLocalStore {
  final Map<String, WellnessRankSummary> rows = {};

  @override
  Future<WellnessRankSummary?> load(String userId) async => rows[userId];

  @override
  Future<void> save(String userId, WellnessRankSummary summary) async {
    rows[userId] = summary;
  }
}

Map<String, Object?> _summary(int experiencePoints) => {
  'rank_code': 'wellness_rank_2',
  'rank_level': 2,
  'title': 'Người Ươm Nếp Lành',
  'experience_points': experiencePoints,
  'current_rank_threshold': 600,
  'next_rank_threshold': 1200,
  'experience_to_next_rank': 1200 - experiencePoints,
  'rank_progress_exp': experiencePoints - 600,
  'rank_progress_target': 600,
  'computed_at': '2026-10-15T00:00:00Z',
  'next_decay_at': '2026-10-22T00:00:00Z',
};
