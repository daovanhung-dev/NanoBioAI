import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nano_app/core/storage/localdb/daos/nutrition_logs_dao.dart';
import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:nano_app/core/storage/localdb/models/nutrition_log_model.dart';
import 'package:nano_app/features/meal_plan/data/daos/meal_plan_dao.dart';
import 'package:nano_app/features/meal_plan/data/models/meal_plan_model.dart';

final nutritionSummaryProvider = FutureProvider<NutritionSummary>((ref) async {
  final db = await DatabaseService.database;
  final userRows = await db.query(
    'users',
    orderBy: 'created_at DESC',
    limit: 1,
  );
  if (userRows.isEmpty) return NutritionSummary.empty();

  final user = userRows.first;
  final userId = _readString(user['id']);
  if (userId == null || userId.isEmpty) return NutritionSummary.empty();

  final logs = await NutritionLogsDao(db).getByUserId(userId);
  final meals = await MealPlansDao(db).getByUserId(userId);

  return NutritionSummary(
    userId: userId,
    fullName: _readString(user['full_name']) ?? '',
    logs: logs,
    meals: meals,
    generatedAt: DateTime.now(),
  );
});

class NutritionSummary {
  final String? userId;
  final String fullName;
  final List<NutritionLogModel> logs;
  final List<MealPlanModel> meals;
  final DateTime generatedAt;

  const NutritionSummary({
    required this.userId,
    required this.fullName,
    required this.logs,
    required this.meals,
    required this.generatedAt,
  });

  factory NutritionSummary.empty() {
    return NutritionSummary(
      userId: null,
      fullName: '',
      logs: const [],
      meals: const [],
      generatedAt: DateTime.now(),
    );
  }

  List<NutritionLogModel> get todayLogs {
    final today = _dateKey(DateTime.now());
    return logs.where((log) => _dateFromText(log.eatenAt) == today).toList();
  }

  List<MealPlanModel> get todayMeals {
    final today = _dateKey(DateTime.now());
    return meals
        .where((meal) => _dateFromText(meal.planDate) == today)
        .toList();
  }

  int get loggedCalories {
    return todayLogs.fold(0, (sum, log) => sum + (log.calories ?? 0));
  }

  int get plannedCalories {
    return todayMeals.fold(0, (sum, meal) => sum + meal.calories);
  }

  double get protein {
    return todayLogs.fold(0, (sum, log) => sum + (log.protein ?? 0));
  }

  double get carbs {
    return todayLogs.fold(0, (sum, log) => sum + (log.carbs ?? 0));
  }

  double get fat {
    return todayLogs.fold(0, (sum, log) => sum + (log.fat ?? 0));
  }

  bool get hasAnyData => logs.isNotEmpty || meals.isNotEmpty;
}

String? _readString(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

String _dateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

String? _dateFromText(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final text = value.trim();
  final parsed = DateTime.tryParse(text);
  if (parsed != null) return _dateKey(parsed);
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(text);
  if (match == null) return null;
  return '${match.group(1)}-${match.group(2)}-${match.group(3)}';
}
