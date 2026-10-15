import 'package:nano_app/core/storage/localdb/daos/wellness_rank_summary_cache_dao.dart';
import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/entities/wellness_rank_summary.dart';
import 'wellness_rank_local_store.dart';

class WellnessRankLocalDatasource implements WellnessRankLocalStore {
  final Database? databaseOverride;

  const WellnessRankLocalDatasource({this.databaseOverride});

  Future<Database> _db() async => databaseOverride ?? DatabaseService.database;

  @override
  Future<WellnessRankSummary?> load(String userId) async {
    final row = await WellnessRankSummaryCacheDao(
      await _db(),
    ).findForUser(userId);
    if (row == null) return null;
    return WellnessRankSummary.fromCache(row);
  }

  @override
  Future<void> save(String userId, WellnessRankSummary summary) async {
    await WellnessRankSummaryCacheDao(
      await _db(),
    ).save(summary.toCacheMap(userId: userId));
  }
}
