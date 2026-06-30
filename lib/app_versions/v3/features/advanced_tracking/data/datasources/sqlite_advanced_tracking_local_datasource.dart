import 'package:nano_app/core/storage/localdb/daos/health_goals_dao.dart';
import 'package:nano_app/core/storage/localdb/daos/health_tracking_logs_dao.dart';
import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:nano_app/core/storage/localdb/models/health_goal_model.dart';
import 'package:nano_app/core/storage/localdb/sync/local_user_data_sync_dispatcher.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/entities/advanced_tracking_models.dart';

class SqliteAdvancedTrackingLocalDatasource {
  final Database? databaseOverride;

  const SqliteAdvancedTrackingLocalDatasource({this.databaseOverride});

  Future<Database> _db() async => databaseOverride ?? DatabaseService.database;

  Future<AdvancedTrackingGoal?> loadActiveGoal({
    required String subjectUserId,
    required String goalCode,
  }) async {
    final db = await _db();
    final goals = await HealthGoalsDao(db).getActiveByUserId(subjectUserId);
    final matches = goals.where((goal) => goal.goalCode == goalCode);
    if (matches.isEmpty) return null;
    return _goalFromModel(matches.first);
  }

  Future<AdvancedTrackingGoal> createHydrationGoal({
    required String subjectUserId,
    required DateTime now,
  }) async {
    final db = await _db();
    final nowText = now.toIso8601String();
    final model = HealthGoalModel(
      id: 'advanced_goal_${_safeId(subjectUserId)}_$advancedTrackingHydrationGoalCode',
      userId: subjectUserId,
      goalCode: advancedTrackingHydrationGoalCode,
      goalName: advancedTrackingHydrationGoalName,
      isActive: true,
      createdAt: nowText,
    );

    await HealthGoalsDao(db).insert(model);
    LocalUserDataSyncDispatcher.requestImmediateSync(database: db);
    return _goalFromModel(model);
  }

  Future<List<AdvancedTrackingHydrationLog>> loadHydrationLogs({
    required String subjectUserId,
    required AdvancedTrackingPeriod period,
  }) async {
    final db = await _db();
    final logs = await HealthTrackingLogsDao(db).getByUserAndDateRange(
      userId: subjectUserId,
      fromDate: period.startDate,
      toDate: period.endDate,
    );

    return logs
        .map(
          (log) => AdvancedTrackingHydrationLog(
            date: log.logDate,
            waterMl: log.waterMl,
          ),
        )
        .toList(growable: false);
  }

  AdvancedTrackingGoal _goalFromModel(HealthGoalModel model) {
    return AdvancedTrackingGoal(
      id: model.id,
      subjectUserId: model.userId ?? '',
      goalCode: model.goalCode ?? '',
      goalName: model.goalName ?? advancedTrackingHydrationGoalName,
      isActive: model.isActive,
      createdAt: model.createdAt ?? '',
    );
  }

  String _safeId(String value) {
    return value.trim().replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
  }
}
