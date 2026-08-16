import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/data/datasources/meal_plan_local_datasource.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/data/models/meal_plan_model.dart';
import 'package:nano_app/core/storage/localdb/models/ai_catalog_models.dart';
import 'package:nano_app/core/storage/localdb/tables/lifestyle_schedule_items_table.dart';
import 'package:nano_app/core/storage/localdb/tables/meal_catalog_table.dart';
import 'package:nano_app/core/storage/localdb/tables/meal_plans_table.dart';
import 'package:nano_app/core/storage/localdb/tables/nutrition_profile_tables.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database database;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await database.execute(MealPlansTable.createTable);
    await database.execute(MealCatalogTable.createTable);
    await database.execute(LifestyleScheduleItemsTable.createTable);
    await NutritionProfileTables.create(database);
  });

  tearDown(() => database.close());

  test('lists safe candidates then replaces the exact code selected by user', () async {
    const current = MealPlanModel(
      id: 'meal-1',
      userId: 'user-1',
      planDate: '2026-08-02',
      mealType: 'breakfast',
      mealName: 'Món cũ',
      description: 'Mô tả cũ',
      calories: 300,
      protein: 10,
      carbs: 40,
      fat: 8,
      fiber: 4,
      waterMl: 0,
      mealOrder: 1,
      catalogCode: 'old-code',
      isCompleted: false,
      aiGenerated: true,
      createdAt: '2026-08-02T00:00:00Z',
      updatedAt: '2026-08-02T00:00:00Z',
    );
    const breakfast = MealCatalogItemModel(
      code: 'breakfast-code',
      mealType: 'breakfast',
      mealName: 'Món sáng',
      description: 'Mô tả sáng',
      cookingInstructions: 'Bước sáng',
      calories: 320,
      protein: 12,
      carbs: 42,
      fat: 9,
      fiber: 5,
      waterMl: 100,
      createdAt: '2026-08-02T00:00:00Z',
      updatedAt: '2026-08-02T00:00:00Z',
    );
    const unclassified = MealCatalogItemModel(
      code: 'source-recipe-code',
      mealType: 'unclassified',
      mealName: 'Cháo thịt bò bí đỏ',
      description: 'Mô tả từ Supabase',
      cookingInstructions: 'Nấu cháo. Thêm thịt bò và bí đỏ.',
      calories: 0,
      protein: 0,
      carbs: 0,
      fat: 0,
      fiber: 0,
      waterMl: 0,
      ingredients: <String>['Gạo', 'Thịt bò', 'Bí đỏ'],
      cookingSteps: <String>['Nấu cháo', 'Thêm thịt bò và bí đỏ'],
      sourceName: 'Sức Khỏe Từ Nhà Bếp',
      sourceHash: 'hash-source',
      isPlanEligible: false,
      metadataStatus: 'source_imported',
      constraintMetadataStatus: 'awaiting_professional_review',
      createdAt: '2026-08-02T00:00:00Z',
      updatedAt: '2026-08-02T00:00:00Z',
    );
    const fixture = MealCatalogItemModel(
      code: 'fixture-meal-breakfast-v1',
      mealType: 'breakfast',
      mealName: 'Fixture balanced breakfast',
      description: 'Synthetic fixture',
      cookingInstructions: 'Fixture instructions',
      calories: 420,
      protein: 22,
      carbs: 54,
      fat: 10,
      fiber: 6,
      waterMl: 300,
      createdAt: '2026-08-02T00:00:00Z',
      updatedAt: '2026-08-02T00:00:00Z',
    );
    const dinner = MealCatalogItemModel(
      code: 'dinner-only',
      mealType: 'dinner',
      mealName: 'Món tối',
      description: 'Không thuộc bữa sáng',
      cookingInstructions: 'Nấu',
      calories: 400,
      protein: 20,
      carbs: 40,
      fat: 12,
      fiber: 4,
      waterMl: 200,
      createdAt: '2026-08-02T00:00:00Z',
      updatedAt: '2026-08-02T00:00:00Z',
    );

    await database.insert(MealPlansTable.tableName, current.toMap());
    for (final item in [breakfast, unclassified, fixture, dinner]) {
      await database.insert(MealCatalogTable.tableName, item.toMap());
    }
    await database.insert(LifestyleScheduleItemsTable.tableName, {
      'id': 'schedule-1',
      'user_id': 'user-1',
      'schedule_date': '2026-08-02',
      'start_time': '07:00',
      'title': 'Ăn sáng: Món cũ',
      'category': 'nutrition',
      'source_type': 'meal_plan',
      'source_id': 'meal-1',
      'created_at': '2026-08-02T00:00:00Z',
      'updated_at': '2026-08-02T00:00:00Z',
    });

    final datasource = MealPlanLocalDatasource(databaseOverride: database);
    final candidates = await datasource.getReplacementCandidates('meal-1');
    expect(
      candidates.map((item) => item.code).toSet(),
      equals(<String>{'breakfast-code', 'source-recipe-code'}),
    );

    final updated = await datasource.replaceMealByCatalogCode(
      mealId: 'meal-1',
      catalogCode: 'source-recipe-code',
    );

    expect(updated.catalogCode, 'source-recipe-code');
    expect(updated.mealName, 'Cháo thịt bò bí đỏ');
    expect(updated.replacementCount, 1);
    expect(updated.aiGenerated, isFalse);
    expect(updated.sourceHash, 'hash-source');
    expect(updated.ingredients, <String>['Gạo', 'Thịt bò', 'Bí đỏ']);

    final timeline = await database.query(
      LifestyleScheduleItemsTable.tableName,
      where: 'id = ?',
      whereArgs: <Object?>['schedule-1'],
    );
    expect(timeline.single['title'], 'Ăn sáng: Cháo thịt bò bí đỏ');
    expect(timeline.single['description'], 'Mô tả từ Supabase');
  });
}
