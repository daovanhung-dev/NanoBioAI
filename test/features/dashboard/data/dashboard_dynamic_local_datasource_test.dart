import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/storage/localdb/tables/ai_insights_table.dart';
import 'package:nano_app/core/storage/localdb/tables/ai_recommendations_table.dart';
import 'package:nano_app/core/storage/localdb/tables/daily_health_tasks_table.dart';
import 'package:nano_app/core/storage/localdb/tables/health_goals_table.dart';
import 'package:nano_app/core/storage/localdb/tables/health_tracking_logs_table.dart';
import 'package:nano_app/core/storage/localdb/tables/meal_plans_table.dart';
import 'package:nano_app/core/storage/localdb/tables/notifications_table.dart';
import 'package:nano_app/core/storage/localdb/tables/nutrition_logs_table.dart';
import 'package:nano_app/core/storage/localdb/tables/users_table.dart';
import 'package:nano_app/features/dashboard/data/datasources/dashboard_dynamic_local_datasource.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute(UsersTable.createTable);
    await db.execute(HealthTrackingLogsTable.createTable);
    await db.execute(DailyHealthTasksTable.createTable);
    await db.execute(MealPlansTable.createTable);
    await db.execute(NutritionLogsTable.createTable);
    await db.execute(NotificationsTable.createTable);
    await db.execute(AIInsightsTable.createTable);
    await db.execute(AIRecommendationsTable.createTable);
    await db.execute(HealthGoalsTable.createTable);
  });

  tearDown(() async {
    await db.close();
  });

  test('fetch reads live metrics from health tracking logs', () async {
    final today = _dateKey(DateTime.now());
    await db.insert('users', {
      'id': 'u1',
      'full_name': 'User One',
      'subscription_tier': 'premium',
      'created_at': '2026-06-18T08:00:00',
    });
    await db.insert('health_tracking_logs', {
      'id': 'log-1',
      'user_id': 'u1',
      'log_date': today,
      'water_ml': 1250,
      'steps_count': 4200,
      'heart_rate_bpm': 72,
      'oxygen_saturation': 98.4,
      'daily_score': 81,
      'created_at': '2026-06-18T08:00:00',
      'updated_at': '2026-06-18T09:00:00',
    });

    final result = await DashboardDynamicLocalDatasource(db).fetch();

    expect(result.userId, 'u1');
    expect(result.metrics.heartRateBpm, 72);
    expect(result.metrics.oxygenSaturation, 98.4);
    expect(result.metrics.dailyScore, 81);
    expect(result.metrics.waterMl, 1250);
    expect(result.metrics.stepsCount, 4200);
  });
}

String _dateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
