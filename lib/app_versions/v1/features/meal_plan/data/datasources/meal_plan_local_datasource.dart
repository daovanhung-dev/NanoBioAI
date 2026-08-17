import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/entities/lifestyle_schedule_item_entity.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/domain/entities/meal_catalog_detail_entity.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/domain/entities/meal_plan_entity.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/domain/entities/meal_replacement_entities.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/domain/services/meal_candidate_selector.dart';
import 'package:nano_app/app_versions/v1/features/nutrition/data/datasources/nutrition_profile_local_datasource.dart';
import 'package:nano_app/core/storage/localdb/daos/ai_catalog_dao.dart';
import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:nano_app/core/storage/localdb/models/ai_catalog_models.dart';
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

class MealReplacementNotAllowedException implements Exception {
  const MealReplacementNotAllowedException();
  static const userMessage =
      'Món này không còn phù hợp để thay thế. Bạn chọn món khác nhé.';
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

  Future<Database> _db() async => databaseOverride ?? DatabaseService.database;

  Future<List<MealPlanModel>> getMealByWeeks({String? userId}) async {
    final db = await _db();
    final normalizedUserId = await _resolveReadUserId(db, userId);
    if (normalizedUserId == null) return const [];
    return MealPlansDao(db).getByUserId(normalizedUserId);
  }

  Future<List<MealPlanEntity>> getMealEntitiesByWeeks({String? userId}) async {
    final db = await _db();
    final normalizedUserId = await _resolveReadUserId(db, userId);
    if (normalizedUserId == null) return const [];
    final meals = await MealPlansDao(db).getByUserId(normalizedUserId);
    if (meals.isEmpty) return const [];
    final catalog = await AiCatalogDao(db).getActiveMeals(planEligibleOnly: false);
    final index = _MealCatalogIndex(catalog);
    return meals.map((meal) => _hydrateMealEntity(meal, index)).toList(growable: false);
  }

  Future<void> completeMealById(
    String id, {
    String? userId,
  }) async {
    final db = await _db();
    final normalizedUserId = await _resolveMutationUserId(db, userId);
    final updated = await MealPlansDao(db).updateCompletedForUser(
      id: id,
      userId: normalizedUserId,
      isCompleted: true,
    );
    if (updated != 1) {
      throw StateError('Meal plan not found for active subject.');
    }
    LocalUserDataSyncDispatcher.requestImmediateSync(database: db);
  }

  Future<List<MealReplacementCandidateEntity>> getReplacementCandidates(
    String mealId, {
    String? userId,
  }) async {
    final db = await _db();
    final normalizedUserId = await _resolveMutationUserId(db, userId);
    final current = await _loadReplaceableMeal(
      db,
      mealId,
      userId: normalizedUserId,
    );
    final ownerId = _requireOwner(current);
    final profile = await NutritionProfileLocalDatasource(
      databaseOverride: db,
    ).load(ownerId);
    final catalog = await AiCatalogDao(db).getActiveMeals(planEligibleOnly: false);
    final candidates = candidateSelector.eligibleMeals(
      catalog: catalog,
      profile: profile,
      mealType: current.mealType,
      excludedCodes: {current.catalogCode},
    );
    final result = candidates.map(_replacementCandidateFromModel).toList();
    result.sort((left, right) {
      final byName = left.mealName.toLowerCase().compareTo(
        right.mealName.toLowerCase(),
      );
      return byName != 0 ? byName : left.code.compareTo(right.code);
    });
    return result;
  }

  Future<MealPlanEntity> replaceMealByCatalogCode({
    required String mealId,
    required String catalogCode,
    String? userId,
  }) async {
    final db = await _db();
    final normalizedUserId = await _resolveMutationUserId(db, userId);
    final current = await _loadReplaceableMeal(
      db,
      mealId,
      userId: normalizedUserId,
    );
    final ownerId = _requireOwner(current);
    final replacement = await AiCatalogDao(db).getMealByCode(catalogCode.trim());
    if (replacement == null) {
      throw const MealReplacementNotAllowedException();
    }

    final profile = await NutritionProfileLocalDatasource(
      databaseOverride: db,
    ).load(ownerId);
    final eligible = candidateSelector.eligibleMeals(
      catalog: [replacement],
      profile: profile,
      mealType: current.mealType,
      excludedCodes: {current.catalogCode},
    );
    if (eligible.isEmpty) {
      throw const MealReplacementNotAllowedException();
    }

    final now = DateTime.now().toIso8601String();
    final updated = _applyReplacement(
      current: current,
      replacement: replacement,
      updatedAt: now,
    );
    await db.transaction((transaction) async {
      final affected = await transaction.update(
        'meal_plans',
        updated.toMap(),
        where: 'id = ? AND user_id = ?',
        whereArgs: [updated.id, normalizedUserId],
      );
      if (affected != 1) {
        throw StateError('Meal plan owner changed during replacement.');
      }
      await transaction.update(
        'lifestyle_schedule_items',
        {
          'title': _scheduleTitle(updated),
          'description': updated.description,
          'updated_at': now,
        },
        where: 'source_type = ? AND source_id = ? AND user_id = ?',
        whereArgs: [
          LifestyleScheduleSourceTypes.mealPlan,
          current.id,
          normalizedUserId,
        ],
      );
    });
    LocalUserDataSyncDispatcher.requestImmediateSync(database: db);
    return updated.toEntity().copyWith(
      catalogDetail: _catalogDetailFromModel(replacement),
    );
  }

  @Deprecated('Use getReplacementCandidates + replaceMealByCatalogCode.')
  Future<MealPlanEntity> replaceMealById(
    String id, {
    String? userId,
  }) async {
    final candidates = await getReplacementCandidates(id, userId: userId);
    if (candidates.isEmpty) {
      throw const NoMealReplacementAvailableException();
    }
    return replaceMealByCatalogCode(
      mealId: id,
      catalogCode: candidates.first.code,
      userId: userId,
    );
  }

  Future<MealPlanModel> _loadReplaceableMeal(
    Database db,
    String mealId, {
    required String userId,
  }) async {
    final current = await MealPlansDao(db).getByIdForUser(
      id: mealId,
      userId: userId,
    );
    if (current == null) {
      throw StateError('Meal plan not found for active subject.');
    }
    if (current.isCompleted) {
      throw StateError('Completed meals cannot be replaced.');
    }
    return current;
  }

  String _requireOwner(MealPlanModel current) {
    final userId = current.userId?.trim() ?? '';
    if (userId.isEmpty) throw StateError('Meal plan owner is missing.');
    return userId;
  }


  Future<String?> _resolveReadUserId(Database db, String? explicitUserId) async {
    final explicit = explicitUserId?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;

    final owners = await _distinctMealOwners(db);
    if (owners.isEmpty) return null;
    if (owners.length == 1) return owners.single;
    throw StateError('Active subject is required when multiple meal owners exist.');
  }

  Future<String> _resolveMutationUserId(
    Database db,
    String? explicitUserId,
  ) async {
    final explicit = explicitUserId?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;

    final owners = await _distinctMealOwners(db);
    if (owners.length == 1) return owners.single;
    throw StateError('Active subject is required for meal changes.');
  }

  Future<List<String>> _distinctMealOwners(Database db) async {
    final rows = await db.rawQuery(
      "SELECT DISTINCT user_id FROM meal_plans "
      "WHERE user_id IS NOT NULL AND TRIM(user_id) <> '' LIMIT 2",
    );
    return rows
        .map((row) => row['user_id']?.toString().trim() ?? '')
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  MealPlanModel _applyReplacement({
    required MealPlanModel current,
    required MealCatalogItemModel replacement,
    required String updatedAt,
  }) => current.copyWith(
    mealName: replacement.mealName,
    description: replacement.description,
    calories: replacement.calories,
    protein: replacement.protein,
    carbs: replacement.carbs,
    fat: replacement.fat,
    fiber: replacement.fiber,
    waterMl: replacement.waterMl,
    sugarG: replacement.sugarG,
    saturatedFatG: replacement.saturatedFatG,
    sodiumMg: replacement.sodiumMg,
    cholesterolMg: replacement.cholesterolMg,
    potassiumMg: replacement.potassiumMg,
    calciumMg: replacement.calciumMg,
    ironMg: replacement.ironMg,
    nutritionStatus: replacement.nutritionStatus,
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
    aiGenerated: false,
    updatedAt: updatedAt,
  );

  MealReplacementCandidateEntity _replacementCandidateFromModel(
    MealCatalogItemModel item,
  ) => MealReplacementCandidateEntity(
    code: item.code,
    mealType: item.mealType,
    mealName: item.mealName,
    description: item.description,
    calories: item.calories,
    servingSize: item.servingSize,
    healthTopicName: item.healthTopicName,
  );

  MealPlanEntity _hydrateMealEntity(
    MealPlanModel meal,
    _MealCatalogIndex catalog,
  ) {
    final match = catalog.resolve(
      catalogCode: meal.catalogCode,
      mealName: meal.mealName,
    );
    return meal.toEntity().copyWith(
      catalogDetail: match == null ? null : _catalogDetailFromModel(match),
    );
  }

  MealCatalogDetailEntity _catalogDetailFromModel(MealCatalogItemModel item) =>
      MealCatalogDetailEntity(
        code: item.code,
        mealType: item.mealType,
        mealName: item.mealName,
        description: item.description,
        cookingInstructions: item.cookingInstructions,
        calories: item.calories,
        protein: item.protein,
        carbs: item.carbs,
        fat: item.fat,
        fiber: item.fiber,
        waterMl: item.waterMl,
        sugarG: item.sugarG,
        saturatedFatG: item.saturatedFatG,
        sodiumMg: item.sodiumMg,
        cholesterolMg: item.cholesterolMg,
        potassiumMg: item.potassiumMg,
        calciumMg: item.calciumMg,
        ironMg: item.ironMg,
        healthTopicCode: item.healthTopicCode,
        healthTopicName: item.healthTopicName,
        healthTopicDescription: item.healthTopicDescription,
        chapterNumber: item.chapterNumber,
        chapterName: item.chapterName,
        ingredients: item.ingredients,
        cookingSteps: item.cookingSteps,
        benefits: item.benefits,
        servingSize: item.servingSize,
        allergenTags: item.allergenTags,
        avoidConditionTags: item.avoidConditionTags,
        nutritionStatus: item.nutritionStatus,
        constraintMetadataStatus: item.constraintMetadataStatus,
        metadataStatus: item.metadataStatus,
        isPlanEligible: item.isPlanEligible,
        sourceName: item.sourceName,
        sourcePage: item.sourcePage,
        sourceChapter: item.sourceChapter,
        sourceTopic: item.sourceTopic,
        sourceRecipeOrder: item.sourceRecipeOrder,
        sourceHash: item.sourceHash,
        version: item.version,
        isActive: item.isActive,
      );

  String _scheduleTitle(MealPlanModel meal) =>
      switch (meal.mealType.trim().toLowerCase()) {
        'breakfast' => 'Ăn sáng: ${meal.mealName}',
        'morning_snack' => 'Bữa phụ sáng: ${meal.mealName}',
        'lunch' => 'Ăn trưa: ${meal.mealName}',
        'afternoon_snack' => 'Bữa phụ chiều: ${meal.mealName}',
        'dinner' => 'Ăn tối: ${meal.mealName}',
        _ => 'Dùng bữa: ${meal.mealName}',
      };
}

class _MealCatalogIndex {
  _MealCatalogIndex(List<MealCatalogItemModel> items)
    : _byCode = <String, MealCatalogItemModel>{
        for (final item in items)
          if (item.code.trim().isNotEmpty) item.code.trim(): item,
      },
      _byUniqueName = _buildUniqueNameIndex(items);

  final Map<String, MealCatalogItemModel> _byCode;
  final Map<String, MealCatalogItemModel> _byUniqueName;

  MealCatalogItemModel? resolve({
    required String catalogCode,
    required String mealName,
  }) {
    final code = catalogCode.trim();
    if (code.isNotEmpty) {
      final byCode = _byCode[code];
      if (byCode != null) return byCode;
    }
    final normalizedName = _normalizeCatalogName(mealName);
    return normalizedName.isEmpty ? null : _byUniqueName[normalizedName];
  }

  static Map<String, MealCatalogItemModel> _buildUniqueNameIndex(
    List<MealCatalogItemModel> items,
  ) {
    final buckets = <String, List<MealCatalogItemModel>>{};
    for (final item in items) {
      final key = _normalizeCatalogName(item.mealName);
      if (key.isNotEmpty) buckets.putIfAbsent(key, () => []).add(item);
    }
    return {
      for (final entry in buckets.entries)
        if (entry.value.length == 1) entry.key: entry.value.single,
    };
  }
}

String _normalizeCatalogName(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'[–—−]'), '-')
    .replaceAll(RegExp(r'\s+'), ' ');
