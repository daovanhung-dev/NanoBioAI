import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/storage/localdb/tables/meal_plans_table.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/data/daos/meal_plan_dao.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/data/datasources/meal_plan_local_datasource.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/data/models/meal_plan_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late MealPlanLocalDatasource datasource;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute(MealPlansTable.createTable);
    datasource = MealPlanLocalDatasource(databaseOverride: db);
  });

  tearDown(() async {
    await db.close();
  });

  test('completeMealById marks meal completed', () async {
    await MealPlansDao(db).insert(_meal(id: 'meal-1'));

    await datasource.completeMealById('meal-1');

    final meal = await MealPlansDao(db).getById('meal-1');
    expect(meal, isNotNull);
    expect(meal!.isCompleted, isTrue);
  });
}

MealPlanModel _meal({required String id}) {
  return MealPlanModel(
    id: id,
    userId: 'u1',
    planDate: '2026-06-19',
    mealType: 'breakfast',
    mealName: 'Bữa sáng',
    description: '',
    calories: 300,
    protein: 10,
    carbs: 30,
    fat: 8,
    fiber: 4,
    waterMl: 250,
    mealOrder: 1,
    cookingInstructions: '',
    isCompleted: false,
    aiGenerated: true,
    createdAt: '2026-06-18T08:00:00',
    updatedAt: '2026-06-18T08:00:00',
  );
}
