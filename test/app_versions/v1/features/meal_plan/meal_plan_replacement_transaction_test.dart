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

  test('updates meal snapshot and linked timeline in one transaction', () async {
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
    const replacement = MealCatalogItemModel(
      code: 'new-code',
      mealType: 'breakfast',
      mealName: 'Món mới',
      description: 'Mô tả mới',
      cookingInstructions: 'Bước mới',
      calories: 320,
      protein: 12,
      carbs: 42,
      fat: 9,
      fiber: 5,
      waterMl: 100,
      ingredients: <String>['Nguyên liệu mới'],
      cookingSteps: <String>['Bước mới'],
      sourceName: 'Nguồn tham khảo',
      sourceHash: 'hash-new',
      createdAt: '2026-08-02T00:00:00Z',
      updatedAt: '2026-08-02T00:00:00Z',
    );

    await database.insert(MealPlansTable.tableName, current.toMap());
    await database.insert(MealCatalogTable.tableName, replacement.toMap());
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

    final updated = await MealPlanLocalDatasource(
      databaseOverride: database,
    ).replaceMealById('meal-1');

    expect(updated.catalogCode, 'new-code');
    expect(updated.mealName, 'Món mới');
    expect(updated.replacementCount, 1);
    expect(updated.sourceHash, 'hash-new');

    final timeline = await database.query(
      LifestyleScheduleItemsTable.tableName,
      where: 'id = ?',
      whereArgs: <Object?>['schedule-1'],
    );
    expect(timeline.single['title'], 'Ăn sáng: Món mới');
    expect(timeline.single['description'], 'Mô tả mới');
  });
}
