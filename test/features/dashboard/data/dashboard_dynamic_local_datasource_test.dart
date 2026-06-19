import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/storage/localdb/tables/ai_insights_table.dart';
import 'package:nano_app/core/storage/localdb/tables/ai_recommendations_table.dart';
import 'package:nano_app/core/storage/localdb/tables/daily_health_tasks_table.dart';
import 'package:nano_app/core/storage/localdb/tables/health_goals_table.dart';
import 'package:nano_app/core/storage/localdb/tables/health_tracking_logs_table.dart';
import 'package:nano_app/core/storage/localdb/tables/lifestyle_schedule_items_table.dart';
import 'package:nano_app/core/storage/localdb/tables/meal_plans_table.dart';
import 'package:nano_app/core/storage/localdb/tables/notifications_table.dart';
import 'package:nano_app/core/storage/localdb/tables/nutrition_logs_table.dart';
import 'package:nano_app/core/storage/localdb/tables/users_table.dart';
import 'package:nano_app/features/dashboard/data/datasources/dashboard_dynamic_local_datasource.dart';
import 'package:nano_app/features/dashboard/domain/entities/dashboard_dynamic_entity.dart';
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
    await db.execute(LifestyleScheduleItemsTable.createTable);
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
      'weight_kg': 64.5,
      'steps_count': 4200,
      'heart_rate_bpm': 72,
      'oxygen_saturation': 98.4,
      'daily_score': 81,
      'mood': 'tired',
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
    expect(result.todayMood, 'tired');
    expect(result.todayWeightKg, 64.5);
  });

  test('fetch includes today lifestyle schedule items in timeline', () async {
    final today = _dateKey(DateTime.now());
    await db.insert('users', {
      'id': 'u1',
      'full_name': 'User One',
      'subscription_tier': 'premium',
      'created_at': '2026-06-18T08:00:00',
    });
    await db.insert('lifestyle_schedule_items', {
      'id': 'schedule-1',
      'user_id': 'u1',
      'schedule_date': today,
      'start_time': '00:00',
      'end_time': '00:30',
      'title': 'Ăn sáng: Cháo yến mạch',
      'description': 'Bữa sáng nhẹ nhàng cho hôm nay.',
      'category': 'meal',
      'source_type': 'meal_plan',
      'source_id': 'meal-1',
      'target_value': 1,
      'current_value': 0,
      'unit': 'lần',
      'is_completed': 0,
      'sort_order': 3,
      'ai_generated': 1,
      'created_at': '2026-06-18T08:00:00',
      'updated_at': '2026-06-18T08:00:00',
    });

    final result = await DashboardDynamicLocalDatasource(db).fetch();

    expect(result.timeline, hasLength(1));
    expect(result.timeline.first.id, 'schedule_schedule-1');
    expect(
      result.timeline.first.sourceType,
      DashboardTimelineSourceTypes.schedule,
    );
    expect(result.timeline.first.sourceId, 'schedule-1');
    expect(result.timeline.first.status, DashboardTimelineStatus.pending);
    expect(result.timeline.first.canComplete, isTrue);
    expect(result.timeline.first.timeLabel, '00:00');
    expect(result.timeline.first.title, 'Ăn sáng: Cháo yến mạch');
  });

  test(
    'fetch does not duplicate meal when schedule item links to it',
    () async {
      final today = _dateKey(DateTime.now());
      await db.insert('users', {
        'id': 'u1',
        'full_name': 'User One',
        'subscription_tier': 'premium',
        'created_at': '2026-06-18T08:00:00',
      });
      await db.insert('meal_plans', {
        'id': 'meal-1',
        'user_id': 'u1',
        'plan_date': today,
        'meal_type': 'breakfast',
        'meal_name': 'Cháo yến mạch',
        'description': 'Bữa sáng nhẹ nhàng cho hôm nay.',
        'calories': 320,
        'protein': 12,
        'carbs': 48,
        'fat': 7,
        'fiber': 6,
        'water_ml': 250,
        'meal_order': 1,
        'start_time': '07:00',
        'end_time': '07:30',
        'cooking_instructions': '',
        'is_completed': 0,
        'ai_generated': 1,
        'created_at': '2026-06-18T08:00:00',
        'updated_at': '2026-06-18T08:00:00',
      });
      await db.insert('lifestyle_schedule_items', {
        'id': 'schedule-meal-1',
        'user_id': 'u1',
        'schedule_date': today,
        'start_time': '07:00',
        'end_time': '07:30',
        'title': 'Ăn sáng: Cháo yến mạch',
        'description': 'Bữa sáng nhẹ nhàng cho hôm nay.',
        'category': 'meal',
        'source_type': 'meal_plan',
        'source_id': 'meal-1',
        'target_value': 1,
        'current_value': 0,
        'unit': 'lần',
        'is_completed': 0,
        'sort_order': 3,
        'ai_generated': 1,
        'created_at': '2026-06-18T08:00:00',
        'updated_at': '2026-06-18T08:00:00',
      });

      final result = await DashboardDynamicLocalDatasource(db).fetch();
      final mealTimelineItems = result.timeline
          .where((item) => item.category == 'meal')
          .toList();

      expect(result.todayMeals, hasLength(1));
      expect(mealTimelineItems, hasLength(1));
      expect(mealTimelineItems.first.id, 'schedule_schedule-meal-1');
    },
  );

  test('fetch marks plan status as final day when plan ends today', () async {
    final todayKey = _dateKey(DateTime.now());

    await _insertUser(db);
    await _insertMealPlanDate(db, id: 'meal-today', planDate: todayKey);

    final result = await DashboardDynamicLocalDatasource(db).fetch();

    expect(result.planStatus.lastPlanDate, todayKey);
    expect(result.planStatus.remainingDays, 1);
  });

  test('fetch marks plan status as expired after the last plan date', () async {
    final yesterdayKey = _dateKey(
      DateTime.now().subtract(const Duration(days: 1)),
    );

    await _insertUser(db);
    await _insertMealPlanDate(db, id: 'meal-yesterday', planDate: yesterdayKey);

    final result = await DashboardDynamicLocalDatasource(db).fetch();

    expect(result.planStatus.lastPlanDate, yesterdayKey);
    expect(result.planStatus.remainingDays, 0);
  });

  test('fetch computes plan status and seven-day self-care streak', () async {
    final today = DateTime.now();
    final todayKey = _dateKey(today);
    final yesterdayKey = _dateKey(today.subtract(const Duration(days: 1)));
    final twoDaysAgoKey = _dateKey(today.subtract(const Duration(days: 2)));
    final planEnd = _dateKey(today.add(const Duration(days: 4)));

    await db.insert('users', {
      'id': 'u1',
      'full_name': 'User One',
      'subscription_tier': 'premium',
      'created_at': '2026-06-18T08:00:00',
    });
    await db.insert('meal_plans', {
      'id': 'meal-end',
      'user_id': 'u1',
      'plan_date': planEnd,
      'meal_type': 'breakfast',
      'meal_name': 'Bữa sáng',
      'description': '',
      'calories': 300,
      'protein': 10,
      'carbs': 30,
      'fat': 8,
      'fiber': 4,
      'water_ml': 250,
      'meal_order': 1,
      'start_time': '07:00',
      'end_time': '07:30',
      'cooking_instructions': '',
      'is_completed': 0,
      'ai_generated': 1,
      'created_at': '2026-06-18T08:00:00',
      'updated_at': '2026-06-18T08:00:00',
    });
    await db.insert('health_tracking_logs', {
      'id': 'log-today',
      'user_id': 'u1',
      'log_date': todayKey,
      'water_ml': 500,
      'created_at': '2026-06-18T08:00:00',
      'updated_at': '2026-06-18T08:00:00',
    });
    await db.insert('daily_health_tasks', {
      'id': 'task-yesterday',
      'user_id': 'u1',
      'task_date': yesterdayKey,
      'task_code': 'water_daily',
      'category': 'water',
      'title': 'Uống nước',
      'description': '',
      'target_value': 1500,
      'current_value': 1500,
      'unit': 'ml',
      'is_completed': 1,
      'sort_order': 1,
      'source': 'test',
      'encouragement': '',
      'created_at': '2026-06-18T08:00:00',
      'updated_at': '2026-06-18T08:00:00',
    });
    await db.insert('meal_plans', {
      'id': 'meal-two-days-ago',
      'user_id': 'u1',
      'plan_date': twoDaysAgoKey,
      'meal_type': 'breakfast',
      'meal_name': 'Bữa sáng',
      'description': '',
      'calories': 300,
      'protein': 10,
      'carbs': 30,
      'fat': 8,
      'fiber': 4,
      'water_ml': 250,
      'meal_order': 1,
      'start_time': '07:00',
      'end_time': '07:30',
      'cooking_instructions': '',
      'is_completed': 1,
      'ai_generated': 1,
      'created_at': '2026-06-18T08:00:00',
      'updated_at': '2026-06-18T08:00:00',
    });

    final result = await DashboardDynamicLocalDatasource(db).fetch();

    expect(result.planStatus.lastPlanDate, planEnd);
    expect(result.planStatus.remainingDays, 5);
    expect(result.selfCareStreak.days, hasLength(7));
    expect(result.selfCareStreak.currentStreak, 3);
  });
}

String _dateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

Future<void> _insertUser(Database db) {
  return db.insert('users', {
    'id': 'u1',
    'full_name': 'User One',
    'subscription_tier': 'premium',
    'created_at': '2026-06-18T08:00:00',
  });
}

Future<void> _insertMealPlanDate(
  Database db, {
  required String id,
  required String planDate,
}) {
  return db.insert('meal_plans', {
    'id': id,
    'user_id': 'u1',
    'plan_date': planDate,
    'meal_type': 'breakfast',
    'meal_name': 'Bữa sáng',
    'description': '',
    'calories': 300,
    'protein': 10,
    'carbs': 30,
    'fat': 8,
    'fiber': 4,
    'water_ml': 250,
    'meal_order': 1,
    'start_time': '07:00',
    'end_time': '07:30',
    'cooking_instructions': '',
    'is_completed': 0,
    'ai_generated': 1,
    'created_at': '2026-06-18T08:00:00',
    'updated_at': '2026-06-18T08:00:00',
  });
}
