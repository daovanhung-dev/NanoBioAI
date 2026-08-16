import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/storage/localdb/daos/ai_catalog_dao.dart';
import '../../../core/storage/localdb/database_service.dart';
import '../../../core/storage/localdb/models/ai_catalog_models.dart';
import '../../../core/storage/localdb/seeders/meal_nutrition_estimator.dart';

class SupabaseMealCatalogRemoteDatasource {
  final SupabaseClient client;

  const SupabaseMealCatalogRemoteDatasource(this.client);

  static const _legacyProjection =
      'code, meal_type, meal_name, description, cooking_instructions, '
      'calories, protein, carbs, fat, fiber, water_ml, '
      'health_topic_code, health_topic_name, health_topic_description, '
      'chapter_number, chapter_name, ingredients_json, cooking_steps_json, '
      'benefits, serving_size, allergen_tags_json, '
      'avoid_condition_tags_json, nutrition_status, '
      'constraint_metadata_status, metadata_status, is_plan_eligible, '
      'source_name, source_page, source_chapter, source_topic, '
      'source_recipe_order, source_hash, version, is_active, '
      'created_at, updated_at';

  static const _nutritionProjection =
      'code, meal_type, meal_name, description, cooking_instructions, '
      'calories, protein, carbs, fat, fiber, water_ml, '
      'sugar_g, saturated_fat_g, sodium_mg, cholesterol_mg, '
      'potassium_mg, calcium_mg, iron_mg, '
      'health_topic_code, health_topic_name, health_topic_description, '
      'chapter_number, chapter_name, ingredients_json, cooking_steps_json, '
      'benefits, serving_size, allergen_tags_json, '
      'avoid_condition_tags_json, nutrition_status, '
      'constraint_metadata_status, metadata_status, is_plan_eligible, '
      'source_name, source_page, source_chapter, source_topic, '
      'source_recipe_order, source_hash, version, is_active, '
      'created_at, updated_at';

  Future<List<MealCatalogItemModel>> fetchActiveCatalog() async {
    late final List<Map<String, dynamic>> response;
    try {
      response = await _fetch(_nutritionProjection);
    } on PostgrestException catch (error) {
      if (!_isMissingNutritionColumn(error)) rethrow;
      // Allow app/backend rollout in either order. Before the v18 Supabase
      // migration is applied, use the legacy projection and estimate locally.
      response = await _fetch(_legacyProjection);
    }

    return response
        .map((row) => MealCatalogItemModel.fromMap(row))
        .map(MealNutritionEstimator.enrichIfMissing)
        .where(
          (item) =>
              item.isActive &&
              item.code.isNotEmpty &&
              item.mealName.isNotEmpty &&
              !_isFixtureCode(item.code),
        )
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> _fetch(String projection) async {
    final response = await client
        .from('meal_catalog')
        .select(projection)
        .eq('is_active', true)
        .order('version')
        .order('code');
    return response.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  bool _isMissingNutritionColumn(PostgrestException error) {
    if (error.code == '42703' || error.code == 'PGRST204') return true;
    final message = error.message.toLowerCase();
    return _nutritionColumnNames.any(
      (column) => message.contains(column) && message.contains('column'),
    );
  }
}

const _nutritionColumnNames = <String>{
  'sugar_g',
  'saturated_fat_g',
  'sodium_mg',
  'cholesterol_mg',
  'potassium_mg',
  'calcium_mg',
  'iron_mg',
};

bool _isFixtureCode(String code) {
  return code.trim().toLowerCase().startsWith('fixture-');
}

class MealCatalogCacheRefreshService {
  final SupabaseMealCatalogRemoteDatasource remoteDatasource;

  const MealCatalogCacheRefreshService({required this.remoteDatasource});

  Future<int> refresh() async {
    final remoteItems = await remoteDatasource.fetchActiveCatalog();
    final database = await DatabaseService.database;

    // Supabase is the single source of truth for meals. Replace the complete
    // local meal cache so stale bundled/removed/inactive rows cannot leak into
    // AI generation.
    await AiCatalogDao(database).replaceMeals(remoteItems);
    return remoteItems.length;
  }

  static Future<int> refreshFromInitializedSupabase() {
    return MealCatalogCacheRefreshService(
      remoteDatasource: SupabaseMealCatalogRemoteDatasource(
        Supabase.instance.client,
      ),
    ).refresh();
  }
}
