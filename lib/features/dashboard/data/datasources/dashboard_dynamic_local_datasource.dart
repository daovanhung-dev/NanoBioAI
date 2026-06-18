import 'package:sqflite/sqflite.dart';

import 'package:nano_app/features/dashboard/domain/entities/dashboard_dynamic_entity.dart';

class DashboardDynamicLocalDatasource {
  final Database db;

  DashboardDynamicLocalDatasource(this.db);

  Future<DashboardDynamicEntity> fetch() async {
    final user = await _latestUser();
    if (user == null) return DashboardDynamicEntity.empty();

    final userId = _readString(user['id']);
    if (userId == null || userId.isEmpty) return DashboardDynamicEntity.empty();

    final today = _dateKey(DateTime.now());
    final todayLog = await _todayHealthLog(userId: userId, today: today);
    final todayTasks = await _todayTasks(userId: userId, today: today);
    final todayMeals = await _todayMeals(userId: userId, today: today);
    final todayNutritionLogs = await _todayNutritionLogs(
      userId: userId,
      today: today,
    );
    final todayNotifications = await _todayNotifications(
      userId: userId,
      today: today,
    );
    final insights = await _latestInsights(userId);
    final recommendations = await _latestRecommendations(userId);
    final goals = await _goalProgress(userId, todayTasks);
    final unreadNotificationCount = await _unreadNotificationCount(userId);

    final metrics = _buildMetrics(
      todayLog: todayLog,
      tasks: todayTasks,
      meals: todayMeals,
      nutritionLogs: todayNutritionLogs,
    );

    final timeline = _buildTimeline(
      meals: todayMeals,
      tasks: todayTasks,
      notifications: todayNotifications,
    );

    return DashboardDynamicEntity(
      userId: userId,
      generatedAt: DateTime.now(),
      metrics: metrics,
      todayMeals: todayMeals,
      todayTasks: todayTasks,
      timeline: timeline,
      insights: insights,
      recommendations: recommendations,
      goalProgress: goals,
      unreadNotificationCount: unreadNotificationCount,
    );
  }

  Future<Map<String, Object?>?> _latestUser() async {
    final rows = await db.query('users', orderBy: 'created_at DESC', limit: 1);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<Map<String, Object?>?> _todayHealthLog({
    required String userId,
    required String today,
  }) async {
    final rows = await db.query(
      'health_tracking_logs',
      where: 'user_id = ? AND (log_date = ? OR substr(log_date, 1, 10) = ?)',
      whereArgs: [userId, today, today],
      orderBy: 'updated_at DESC, created_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<List<DashboardTaskItem>> _todayTasks({
    required String userId,
    required String today,
  }) async {
    final rows = await db.query(
      'daily_health_tasks',
      where: 'user_id = ? AND (task_date = ? OR substr(task_date, 1, 10) = ?)',
      whereArgs: [userId, today, today],
      orderBy: 'sort_order ASC, created_at ASC',
    );

    return rows.map((row) {
      return DashboardTaskItem(
        id: _readString(row['id']) ?? '',
        category: _readString(row['category']) ?? 'health',
        title: _readString(row['title']) ?? 'Nhiệm vụ sức khỏe',
        description: _readString(row['description']),
        targetValue: _readDouble(row['target_value']) ?? 0,
        currentValue: _readDouble(row['current_value']) ?? 0,
        unit: _readString(row['unit']),
        isCompleted: _readBool(row['is_completed']),
        sortOrder: _readInt(row['sort_order']) ?? 0,
        encouragement: _readString(row['encouragement']),
      );
    }).toList();
  }

  Future<List<DashboardMealItem>> _todayMeals({
    required String userId,
    required String today,
  }) async {
    final rows = await db.query(
      'meal_plans',
      where: 'user_id = ? AND (plan_date = ? OR substr(plan_date, 1, 10) = ?)',
      whereArgs: [userId, today, today],
      orderBy: 'meal_order ASC, start_time ASC, created_at ASC',
    );

    return rows.map((row) {
      return DashboardMealItem(
        id: _readString(row['id']) ?? '',
        mealType: _readString(row['meal_type']) ?? 'meal',
        mealName: _readString(row['meal_name']) ?? 'Bữa ăn',
        description: _readString(row['description']),
        calories: _readInt(row['calories']) ?? 0,
        waterMl: _readInt(row['water_ml']) ?? 0,
        mealOrder: _readInt(row['meal_order']) ?? 0,
        startTime: _readString(row['start_time']),
        isCompleted: _readBool(row['is_completed']),
      );
    }).toList();
  }

  Future<List<Map<String, Object?>>> _todayNutritionLogs({
    required String userId,
    required String today,
  }) async {
    return db.query(
      'nutrition_logs',
      where: 'user_id = ? AND (eaten_at = ? OR substr(eaten_at, 1, 10) = ?)',
      whereArgs: [userId, today, today],
      orderBy: 'eaten_at ASC',
    );
  }

  Future<List<Map<String, Object?>>> _todayNotifications({
    required String userId,
    required String today,
  }) async {
    return db.query(
      'notifications',
      where:
          'user_id = ? AND scheduled_at IS NOT NULL AND substr(scheduled_at, 1, 10) = ?',
      whereArgs: [userId, today],
      orderBy: 'scheduled_at ASC, created_at ASC',
    );
  }

  Future<List<DashboardInsightItem>> _latestInsights(String userId) async {
    final rows = await db.query(
      'ai_insights',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
      limit: 5,
    );

    return rows
        .map((row) {
          return DashboardInsightItem(
            id: _readString(row['id']) ?? '',
            type: _readString(row['insight_type']) ?? 'health',
            title: _readString(row['title']) ?? 'Insight sức khỏe',
            content: _readString(row['content']) ?? '',
            riskLevel: _readString(row['risk_level']) ?? 'info',
            createdAt: _readString(row['created_at']),
          );
        })
        .where((item) => item.content.trim().isNotEmpty)
        .toList();
  }

  Future<List<DashboardRecommendationItem>> _latestRecommendations(
    String userId,
  ) async {
    final rows = await db.query(
      'ai_recommendations',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'is_read ASC, created_at DESC',
      limit: 5,
    );

    return rows
        .map((row) {
          return DashboardRecommendationItem(
            id: _readString(row['id']) ?? '',
            type: _readString(row['recommendation_type']) ?? 'health',
            title: _readString(row['title']) ?? 'Đề xuất sức khỏe',
            description: _readString(row['description']) ?? '',
            actionText: _readString(row['action_text']) ?? '',
            isRead: _readBool(row['is_read']),
            createdAt: _readString(row['created_at']),
          );
        })
        .where((item) => item.description.trim().isNotEmpty)
        .toList();
  }

  Future<List<DashboardGoalProgressItem>> _goalProgress(
    String userId,
    List<DashboardTaskItem> todayTasks,
  ) async {
    final rows = await db.query(
      'health_goals',
      where: 'user_id = ? AND is_active = ?',
      whereArgs: [userId, 1],
      orderBy: 'created_at ASC',
    );

    final completedTasks = todayTasks.where((task) => task.isCompleted).length;
    final progress = todayTasks.isEmpty
        ? 0.0
        : completedTasks / todayTasks.length;
    final subtitle = todayTasks.isEmpty
        ? 'Chưa có nhiệm vụ hôm nay để đo tiến độ'
        : '$completedTasks/${todayTasks.length} nhiệm vụ hôm nay đã hoàn thành';

    return rows.map((row) {
      return DashboardGoalProgressItem(
        id: _readString(row['id']) ?? '',
        title: _readString(row['goal_name']) ?? 'Mục tiêu sức khỏe',
        subtitle: subtitle,
        progress: progress.clamp(0, 1).toDouble(),
        isActive: _readBool(row['is_active']),
      );
    }).toList();
  }

  Future<int> _unreadNotificationCount(String userId) async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM notifications WHERE user_id = ? AND is_read = 0',
      [userId],
    );
    if (result.isEmpty) return 0;
    return _readInt(result.first['count']) ?? 0;
  }

  DashboardDailyMetrics _buildMetrics({
    required Map<String, Object?>? todayLog,
    required List<DashboardTaskItem> tasks,
    required List<DashboardMealItem> meals,
    required List<Map<String, Object?>> nutritionLogs,
  }) {
    final completedTasks = tasks.where((task) => task.isCompleted).length;
    final completedMeals = meals.where((meal) => meal.isCompleted).length;

    final caloriesFromNutrition = nutritionLogs.fold<int>(
      0,
      (sum, row) => sum + (_readInt(row['calories']) ?? 0),
    );
    final plannedCalories = meals.fold<int>(
      0,
      (sum, meal) => sum + meal.calories,
    );

    final waterFromTasks = tasks
        .where((task) => task.category == 'water')
        .fold<double>(0, (sum, task) => sum + task.currentValue);

    final waterMl = _readInt(todayLog?['water_ml']) ?? waterFromTasks.round();
    final dailyScore =
        _readInt(todayLog?['daily_score']) ??
        _estimateDailyScore(
          completedTasks: completedTasks,
          totalTasks: tasks.length,
          completedMeals: completedMeals,
          totalMeals: meals.length,
          waterMl: waterMl,
          sleepHours: _readDouble(todayLog?['sleep_hours']) ?? 0,
        );

    return DashboardDailyMetrics(
      completedTasks: completedTasks,
      totalTasks: tasks.length,
      completedMeals: completedMeals,
      totalMeals: meals.length,
      caloriesLogged: _readInt(todayLog?['calories']) ?? caloriesFromNutrition,
      caloriesPlanned: plannedCalories,
      waterMl: waterMl,
      stepsCount: _readInt(todayLog?['steps_count']) ?? 0,
      sleepHours: _readDouble(todayLog?['sleep_hours']) ?? 0,
      stressLevel: _readInt(todayLog?['stress_level']) ?? 0,
      heartRateBpm: _readInt(todayLog?['heart_rate_bpm']),
      oxygenSaturation: _readDouble(todayLog?['oxygen_saturation']),
      dailyScore: dailyScore,
      nutritionLogCount: nutritionLogs.length,
    );
  }

  int _estimateDailyScore({
    required int completedTasks,
    required int totalTasks,
    required int completedMeals,
    required int totalMeals,
    required int waterMl,
    required double sleepHours,
  }) {
    var score = 0.0;
    var weight = 0.0;

    if (totalTasks > 0) {
      score += (completedTasks / totalTasks) * 45;
      weight += 45;
    }
    if (totalMeals > 0) {
      score += (completedMeals / totalMeals) * 25;
      weight += 25;
    }
    if (waterMl > 0) {
      score += (waterMl / 2000).clamp(0, 1).toDouble() * 15;
      weight += 15;
    }
    if (sleepHours > 0) {
      score += (sleepHours / 8).clamp(0, 1).toDouble() * 15;
      weight += 15;
    }

    if (weight == 0) return 0;
    return ((score / weight) * 100).round().clamp(0, 100).toInt();
  }

  List<DashboardTimelineItem> _buildTimeline({
    required List<DashboardMealItem> meals,
    required List<DashboardTaskItem> tasks,
    required List<Map<String, Object?>> notifications,
  }) {
    final items = <DashboardTimelineItem>[];

    for (final meal in meals) {
      items.add(
        DashboardTimelineItem(
          id: 'meal_${meal.id}',
          timeLabel: _mealTimeLabel(meal),
          title: meal.mealName,
          subtitle: meal.calories > 0
              ? '${_mealTypeLabel(meal.mealType)} • ${meal.calories} kcal'
              : _mealTypeLabel(meal.mealType),
          category: 'meal',
          isCompleted: meal.isCompleted,
          sortOrder: meal.mealOrder == 0 ? 20 : meal.mealOrder * 10,
        ),
      );
    }

    for (final task in tasks) {
      items.add(
        DashboardTimelineItem(
          id: 'task_${task.id}',
          timeLabel: _taskTimeLabel(task.sortOrder),
          title: task.title,
          subtitle: task.unit == null
              ? (task.description ?? '')
              : '${_formatNumber(task.currentValue)}/${_formatNumber(task.targetValue)} ${task.unit}',
          category: task.category,
          isCompleted: task.isCompleted,
          sortOrder: 100 + task.sortOrder,
        ),
      );
    }

    for (final row in notifications) {
      items.add(
        DashboardTimelineItem(
          id: 'notification_${_readString(row['id']) ?? ''}',
          timeLabel: _timeFromIso(_readString(row['scheduled_at'])) ?? '--:--',
          title: _readString(row['title']) ?? 'Thông báo',
          subtitle: _readString(row['body']) ?? '',
          category: _readString(row['type']) ?? 'notification',
          isCompleted: _readBool(row['is_read']),
          sortOrder: 300 + items.length,
        ),
      );
    }

    items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return items;
  }

  String _mealTimeLabel(DashboardMealItem meal) {
    final fromStart = _timeFromIso(meal.startTime);
    if (fromStart != null) return fromStart;
    switch (meal.mealOrder) {
      case 1:
        return '07:00';
      case 2:
        return '12:00';
      case 3:
        return '18:30';
      default:
        return '--:--';
    }
  }

  String _taskTimeLabel(int sortOrder) {
    if (sortOrder <= 1) return '08:00';
    if (sortOrder == 2) return '10:30';
    if (sortOrder == 3) return '15:00';
    return '20:30';
  }

  String _mealTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'breakfast':
        return 'Bữa sáng';
      case 'lunch':
        return 'Bữa trưa';
      case 'dinner':
        return 'Bữa tối';
      case 'snack':
        return 'Bữa phụ';
      default:
        return 'Bữa ăn';
    }
  }

  String? _timeFromIso(String? value) {
    if (value == null || value.isEmpty) return null;
    if (RegExp(r'^\d{2}:\d{2}').hasMatch(value)) {
      return value.substring(0, 5);
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return null;
    return '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(1);
  }

  String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String? _readString(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  int? _readInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  double? _readDouble(Object? value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  bool _readBool(Object? value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value.toString().trim().toLowerCase();
    return normalized == '1' || normalized == 'true' || normalized == 'yes';
  }
}
