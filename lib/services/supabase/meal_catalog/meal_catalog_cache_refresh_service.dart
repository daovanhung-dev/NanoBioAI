import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/storage/localdb/daos/ai_catalog_dao.dart';
import '../../../core/storage/localdb/database_service.dart';
import '../../../core/storage/localdb/models/ai_catalog_models.dart';

class SupabaseMealCatalogRemoteDatasource {
  final SupabaseClient client;

  const SupabaseMealCatalogRemoteDatasource(this.client);

  Future<List<MealCatalogItemModel>> fetchActiveCatalog() async {
    final response = await client
        .from('meal_catalog')
        .select(
          'code, meal_type, meal_name, description, cooking_instructions, '
          'calories, protein, carbs, fat, fiber, water_ml, '
          'health_topic_code, health_topic_name, health_topic_description, '
          'chapter_number, chapter_name, ingredients_json, cooking_steps_json, '
          'benefits, serving_size, allergen_tags_json, '
          'avoid_condition_tags_json, nutrition_status, '
          'constraint_metadata_status, metadata_status, is_plan_eligible, '
          'source_name, source_page, source_chapter, source_topic, '
          'source_recipe_order, source_hash, version, is_active, '
          'created_at, updated_at',
        )
        .eq('is_active', true)
        .order('version')
        .order('code');

    return response
        .map((row) => MealCatalogItemModel.fromMap(row))
        .where((item) => item.code.isNotEmpty && item.mealName.isNotEmpty)
        .toList(growable: false);
  }
}

class MealCatalogCacheRefreshService {
  final SupabaseMealCatalogRemoteDatasource remoteDatasource;

  const MealCatalogCacheRefreshService({required this.remoteDatasource});

  Future<int> refresh() async {
    final remoteItems = await remoteDatasource.fetchActiveCatalog();
    if (remoteItems.isEmpty) return 0;

    final database = await DatabaseService.database;
    await AiCatalogDao(database).upsertMeals(remoteItems);
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
