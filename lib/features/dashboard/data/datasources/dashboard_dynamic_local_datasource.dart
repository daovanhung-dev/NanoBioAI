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
    final todayTasks = _dedupeTasks(
      await _todayTasks(userId: userId, today: today),
    );
    final todayMeals = _dedupeMeals(
      await _todayMeals(userId: userId, today: today),
    );
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
        timeLabel: _readTaskTime(row),
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
    final mealTaskIds = <String>{};

    for (final meal in _dedupeMeals(meals)) {
      final matchedTask = _findMatchingMealTask(meal, tasks);
      if (matchedTask != null && matchedTask.id.isNotEmpty) {
        mealTaskIds.add(matchedTask.id);
      }

      final timeLabel = _mealTimeLabel(meal);
      items.add(
        DashboardTimelineItem(
          id: 'meal_${meal.id}',
          timeLabel: timeLabel,
          title: meal.mealName,
          subtitle: meal.calories > 0
              ? '${_mealTypeLabel(meal.mealType)} • ${meal.calories} kcal'
              : _mealTypeLabel(meal.mealType),
          category: 'meal',
          isCompleted: meal.isCompleted || (matchedTask?.isCompleted ?? false),
          sortOrder: _timelineSortOrder(
            timeLabel,
            meal.mealOrder == 0 ? 20 : meal.mealOrder * 10,
          ),
        ),
      );
    }

    for (final task in _dedupeTasks(tasks)) {
      if (mealTaskIds.contains(task.id) || _isMealTaskCoveredByMeal(task, meals)) {
        continue;
      }

      final timeLabel = _taskTimeLabel(task);
      items.add(
        DashboardTimelineItem(
          id: 'task_${task.id}',
          timeLabel: timeLabel,
          title: task.title,
          subtitle: task.unit == null
              ? (task.description ?? '')
              : '${_formatNumber(task.currentValue)}/${_formatNumber(task.targetValue)} ${task.unit}',
          category: task.category,
          isCompleted: task.isCompleted,
          sortOrder: _timelineSortOrder(timeLabel, 100 + task.sortOrder),
        ),
      );
    }

    for (final row in notifications) {
      final timeLabel = _timeFromIso(_readString(row['scheduled_at'])) ?? '--:--';
      final title = _readString(row['title']) ?? 'Thông báo';
      final subtitle = _readString(row['body']) ?? '';

      if (_notificationDuplicatesTimeline(
        timeLabel: timeLabel,
        title: title,
        subtitle: subtitle,
        existingItems: items,
      )) {
        continue;
      }

      items.add(
        DashboardTimelineItem(
          id: 'notification_${_readString(row['id']) ?? ''}',
          timeLabel: timeLabel,
          title: title,
          subtitle: subtitle,
          category: _readString(row['type']) ?? 'notification',
          isCompleted: _readBool(row['is_read']),
          sortOrder: _timelineSortOrder(timeLabel, 300 + items.length),
        ),
      );
    }

    final uniqueItems = _dedupeTimelineItems(items);
    uniqueItems.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return uniqueItems;
  }

  List<DashboardMealItem> _dedupeMeals(List<DashboardMealItem> meals) {
    final byKey = <String, DashboardMealItem>{};

    for (final meal in meals) {
      final naturalKey = 'meal:${_mealTimeLabel(meal)}:${_normalizeForCompare(meal.mealType)}:${_normalizeForCompare(meal.mealName)}';
      final key = _normalizeForCompare(meal.mealName).isNotEmpty
          ? naturalKey
          : 'id:${meal.id}';
      final existing = byKey[key];
      byKey[key] = existing == null ? meal : _mergeMeal(existing, meal);
    }

    return byKey.values.toList();
  }

  DashboardMealItem _mergeMeal(DashboardMealItem current, DashboardMealItem next) {
    return DashboardMealItem(
      id: current.id.isNotEmpty ? current.id : next.id,
      mealType: current.mealType.isNotEmpty ? current.mealType : next.mealType,
      mealName: current.mealName.isNotEmpty ? current.mealName : next.mealName,
      description: current.description ?? next.description,
      calories: current.calories >= next.calories ? current.calories : next.calories,
      waterMl: current.waterMl >= next.waterMl ? current.waterMl : next.waterMl,
      mealOrder: current.mealOrder != 0 ? current.mealOrder : next.mealOrder,
      startTime: current.startTime ?? next.startTime,
      isCompleted: current.isCompleted || next.isCompleted,
    );
  }

  List<DashboardTaskItem> _dedupeTasks(List<DashboardTaskItem> tasks) {
    final byKey = <String, DashboardTaskItem>{};

    for (final task in tasks) {
      final naturalKey = 'task:${_taskTimeLabel(task)}:${_normalizeForCompare(task.category)}:${_normalizeForCompare(task.title)}';
      final key = _normalizeForCompare(task.title).isNotEmpty
          ? naturalKey
          : 'id:${task.id}';
      final existing = byKey[key];
      byKey[key] = existing == null ? task : _mergeTask(existing, task);
    }

    return byKey.values.toList();
  }

  DashboardTaskItem _mergeTask(DashboardTaskItem current, DashboardTaskItem next) {
    final currentDescription = current.description?.trim() ?? '';
    final nextDescription = next.description?.trim() ?? '';
    final currentEncouragement = current.encouragement?.trim() ?? '';
    final nextEncouragement = next.encouragement?.trim() ?? '';

    return DashboardTaskItem(
      id: current.id.isNotEmpty ? current.id : next.id,
      category: current.category.isNotEmpty ? current.category : next.category,
      title: current.title.isNotEmpty ? current.title : next.title,
      description: currentDescription.length >= nextDescription.length
          ? current.description
          : next.description,
      targetValue: current.targetValue >= next.targetValue
          ? current.targetValue
          : next.targetValue,
      currentValue: current.currentValue >= next.currentValue
          ? current.currentValue
          : next.currentValue,
      unit: current.unit ?? next.unit,
      isCompleted: current.isCompleted || next.isCompleted,
      sortOrder: current.sortOrder <= next.sortOrder
          ? current.sortOrder
          : next.sortOrder,
      encouragement: currentEncouragement.length >= nextEncouragement.length
          ? current.encouragement
          : next.encouragement,
      timeLabel: current.timeLabel ?? next.timeLabel,
    );
  }

  DashboardTaskItem? _findMatchingMealTask(
    DashboardMealItem meal,
    List<DashboardTaskItem> tasks,
  ) {
    for (final task in tasks) {
      if (_taskMatchesMeal(task, meal)) return task;
    }
    return null;
  }

  bool _isMealTaskCoveredByMeal(
    DashboardTaskItem task,
    List<DashboardMealItem> meals,
  ) {
    for (final meal in meals) {
      if (_taskMatchesMeal(task, meal)) return true;
    }
    return false;
  }

  bool _taskMatchesMeal(DashboardTaskItem task, DashboardMealItem meal) {
    final taskText = _normalizeForCompare(
      '${task.title} ${task.description ?? ''} ${task.category}',
    );
    final mealName = _normalizeForCompare(meal.mealName);
    final mealType = _normalizeForCompare(_mealTypeLabel(meal.mealType));
    final taskTime = _taskTimeLabel(task);
    final mealTime = _mealTimeLabel(meal);
    final sameTime = taskTime != '--:--' && mealTime != '--:--' && taskTime == mealTime;

    final hasMealKeyword = _containsAny(taskText, const [
      'an sang',
      'bua sang',
      'breakfast',
      'an trua',
      'bua trua',
      'lunch',
      'an toi',
      'bua toi',
      'dinner',
      'bua phu',
      'snack',
      'meal',
    ]);

    if (mealName.isNotEmpty && taskText.contains(mealName)) return true;
    if (sameTime && hasMealKeyword) return true;
    if (sameTime && mealType.isNotEmpty && taskText.contains(mealType)) {
      return true;
    }

    return false;
  }

  bool _notificationDuplicatesTimeline({
    required String timeLabel,
    required String title,
    required String subtitle,
    required List<DashboardTimelineItem> existingItems,
  }) {
    final notificationTitle = _normalizeForCompare(title);
    final notificationText = _normalizeForCompare('$title $subtitle');
    if (notificationText.isEmpty) return false;

    for (final item in existingItems) {
      final itemTitle = _normalizeForCompare(item.title);
      final itemText = _normalizeForCompare('${item.title} ${item.subtitle}');
      final sameTime = timeLabel == item.timeLabel || timeLabel == '--:--';

      if (sameTime && itemTitle.isNotEmpty && notificationText.contains(itemTitle)) {
        return true;
      }
      if (sameTime && notificationTitle.isNotEmpty && itemText.contains(notificationTitle)) {
        return true;
      }
      if (sameTime && itemText.isNotEmpty && notificationText == itemText) {
        return true;
      }
    }

    return false;
  }

  List<DashboardTimelineItem> _dedupeTimelineItems(
    List<DashboardTimelineItem> items,
  ) {
    final byKey = <String, DashboardTimelineItem>{};

    for (final item in items) {
      final key = [
        item.timeLabel,
        _logicalCategory(item.category),
        _normalizeForCompare(item.title),
      ].join('|');
      final existing = byKey[key];
      byKey[key] = existing == null ? item : _mergeTimelineItem(existing, item);
    }

    return byKey.values.toList();
  }

  DashboardTimelineItem _mergeTimelineItem(
    DashboardTimelineItem current,
    DashboardTimelineItem next,
  ) {
    return DashboardTimelineItem(
      id: current.id.isNotEmpty ? current.id : next.id,
      timeLabel: current.timeLabel != '--:--' ? current.timeLabel : next.timeLabel,
      title: current.title.length >= next.title.length ? current.title : next.title,
      subtitle: current.subtitle.length >= next.subtitle.length
          ? current.subtitle
          : next.subtitle,
      category: current.category,
      isCompleted: current.isCompleted || next.isCompleted,
      sortOrder: current.sortOrder <= next.sortOrder
          ? current.sortOrder
          : next.sortOrder,
    );
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

  String _taskTimeLabel(DashboardTaskItem task) {
    final explicitTime = _timeFromIso(task.timeLabel);
    if (explicitTime != null) return explicitTime;

    final titleTime = _timeFromText('${task.title} ${task.description ?? ''}');
    if (titleTime != null) return titleTime;

    switch (task.sortOrder) {
      case 0:
        return '06:00';
      case 1:
        return '06:15';
      case 2:
        return '07:00';
      case 3:
        return '08:00';
      case 4:
        return '10:30';
      case 5:
        return '12:00';
      case 6:
        return '15:00';
      case 7:
        return '18:30';
      default:
        return '20:30';
    }
  }

  String? _readTaskTime(Map<String, Object?> row) {
    const timeColumns = [
      'time_label',
      'task_time',
      'start_time',
      'scheduled_time',
      'scheduled_at',
      'reminder_time',
      'due_time',
      'due_at',
      'target_time',
    ];

    for (final column in timeColumns) {
      final time = _timeFromIso(_readString(row[column]));
      if (time != null) return time;
    }

    return _timeFromText(
      '${_readString(row['title']) ?? ''} ${_readString(row['description']) ?? ''}',
    );
  }

  String? _timeFromText(String value) {
    final match = RegExp(r'\b(\d{1,2})[:hH](\d{2})\b').firstMatch(value);
    if (match == null) return null;

    final hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '');
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  int _timelineSortOrder(String timeLabel, int fallbackPriority) {
    return _timeSortValue(timeLabel) * 1000 + fallbackPriority.clamp(0, 999).toInt();
  }

  int _timeSortValue(String timeLabel) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(timeLabel);
    if (match == null) return 24 * 60;

    final hour = int.tryParse(match.group(1) ?? '') ?? 24;
    final minute = int.tryParse(match.group(2) ?? '') ?? 0;
    return hour * 60 + minute;
  }

  String _logicalCategory(String category) {
    final normalized = _normalizeForCompare(category);
    if (_containsAny(normalized, const ['meal', 'breakfast', 'lunch', 'dinner', 'snack'])) {
      return 'meal';
    }
    if (_containsAny(normalized, const ['water', 'nuoc'])) return 'water';
    if (_containsAny(normalized, const ['notification', 'reminder', 'thong bao', 'nhac'])) {
      return 'notification';
    }
    return normalized.isEmpty ? 'health' : normalized;
  }

  bool _containsAny(String value, List<String> needles) {
    for (final needle in needles) {
      if (value.contains(needle)) return true;
    }
    return false;
  }

  String _normalizeForCompare(String value) {
    var text = value.toLowerCase().trim();
    final replacements = <String, String>{
      r'[àáạảãâầấậẩẫăằắặẳẵ]': 'a',
      r'[èéẹẻẽêềếệểễ]': 'e',
      r'[ìíịỉĩ]': 'i',
      r'[òóọỏõôồốộổỗơờớợởỡ]': 'o',
      r'[ùúụủũưừứựửữ]': 'u',
      r'[ỳýỵỷỹ]': 'y',
      r'đ': 'd',
    };

    for (final entry in replacements.entries) {
      text = text.replaceAll(RegExp(entry.key), entry.value);
    }

    return text
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
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

    final shortTime = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(value);
    if (shortTime != null) {
      final hour = int.tryParse(shortTime.group(1) ?? '');
      final minute = int.tryParse(shortTime.group(2) ?? '');
      if (hour == null || minute == null) return null;
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
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
