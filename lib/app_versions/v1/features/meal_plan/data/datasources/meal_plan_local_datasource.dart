import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/entities/lifestyle_schedule_item_entity.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/domain/entities/meal_plan_entity.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/domain/services/meal_candidate_selector.dart';
import 'package:nano_app/app_versions/v1/features/nutrition/data/datasources/nutrition_profile_local_datasource.dart';
import 'package:nano_app/core/storage/localdb/daos/ai_catalog_dao.dart';
import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:nano_app/core/storage/localdb/sync/local_user_data_sync_dispatcher.dart';
import 'package:sqflite/sqflite.dart';

import '../daos/meal_plan_dao.dart';
import '../models/meal_plan_model.dart';

class NoMealReplacementAvailableException implements Exception {
  const NoMealReplacementAvailableException();

  static const userMessage =
      'Nabi chưa tìm thấy món thay thế phù hợp với hồ sơ của bạn.';

  @override
  String toString() => userMessage;
}

class MealPlanLocalDatasource {
  const MealPlanLocalDatasource({
    this.databaseOverride,
    this.candidateSelector = const MealCandidateSelector(),
  });

  final Database? databaseOverride;
  final MealCandidateSelector candidateSelector;

  Future<Database> _db() async {
    final override = databaseOverride;
    if (override != null) return override;
    return DatabaseService.database;
  }

  Future<List<MealPlanModel>> getMealByWeeks() async {
    final db = await _db();
    return MealPlansDao(db).getAll();
  }

  Future<void> completeMealById(String id) async {
    final db = await _db();
    await MealPlansDao(db).updateCompleted(id: id, isCompleted: true);
    LocalUserDataSyncDispatcher.requestImmediateSync(database: db);
  }

  Future<MealPlanEntity> replaceMealById(String id) async {
    final db = await _db();
    final current = await MealPlansDao(db).getById(id);
    if (current == null) {
      throw StateError('Meal plan not found.');
    }
    if (current.isCompleted) {
      throw StateError('Completed meals cannot be replaced.');
    }
    final userId = current.userId?.trim() ?? '';
    if (userId.isEmpty) {
      throw StateError('Meal plan owner is missing.');
    }

    final profile = await NutritionProfileLocalDatasource(
      databaseOverride: db,
    ).load(userId);
    final catalog = await AiCatalogDao(db).getActiveMeals(
      mealType: current.mealType,
    );
    final replacement = candidateSelector.replacementFor(
      catalog: catalog,
      profile: profile,
      mealType: current.mealType,
      currentCode: current.catalogCode,
      replacementCount: current.replacementCount,
    );
    if (replacement == null) {
      throw const NoMealReplacementAvailableException();
    }

    final now = DateTime.now().toIso8601String();
    final updated = current.copyWith(
      mealName: replacement.mealName,
      description: replacement.description,
      calories: replacement.calories,
      protein: replacement.protein,
      carbs: replacement.carbs,
      fat: replacement.fat,
      fiber: replacement.fiber,
      waterMl: replacement.waterMl,
      cookingInstructions: replacement.cookingInstructions,
      catalogCode: replacement.code,
      servingSize: replacement.servingSize,
      topicCode: replacement.healthTopicCode,
      topicName: replacement.healthTopicName,
      ingredients: replacement.ingredients,
      cookingSteps: replacement.cookingSteps,
      benefits: replacement.benefits,
      allergenTags: replacement.allergenTags,
      conditionTags: replacement.avoidConditionTags,
      provenanceSource: replacement.sourceName,
      sourceHash: replacement.sourceHash,
      catalogSchemaVersion: replacement.version,
      replacementCount: current.replacementCount + 1,
      updatedAt: now,
    );

    await db.transaction((transaction) async {
      await MealPlansDao(transaction).update(updated);
      await transaction.update(
        'lifestyle_schedule_items',
        {
          'title': _scheduleTitle(updated),
          'description': updated.description,
          'updated_at': now,
        },
        where: 'source_type = ? AND source_id = ?',
        whereArgs: [LifestyleScheduleSourceTypes.mealPlan, current.id],
      );
    });
    LocalUserDataSyncDispatcher.requestImmediateSync(database: db);
    return updated.toEntity();
  }

  String _scheduleTitle(MealPlanModel meal) {
    switch (meal.mealType.trim().toLowerCase()) {
      case 'breakfast':
        return 'Ăn sáng: ${meal.mealName}';
      case 'morning_snack':
        return 'Bữa phụ sáng: ${meal.mealName}';
      case 'lunch':
        return 'Ăn trưa: ${meal.mealName}';
      case 'afternoon_snack':
        return 'Bữa phụ chiều: ${meal.mealName}';
      case 'dinner':
        return 'Ăn tối: ${meal.mealName}';
      default:
        return 'Dùng bữa: ${meal.mealName}';
    }
  }
}
