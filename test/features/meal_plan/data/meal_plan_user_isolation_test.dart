import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/data/daos/meal_plan_dao.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/data/datasources/meal_plan_local_datasource.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/data/models/meal_plan_model.dart';
import 'package:nano_app/core/storage/localdb/tables/meal_plans_table.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late MealPlansDao dao;
  late MealPlanLocalDatasource datasource;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute(MealPlansTable.createTable);
    dao = MealPlansDao(db);
    datasource = MealPlanLocalDatasource(databaseOverride: db);
    await dao.insert(_meal(id: 'meal-a', userId: 'user-a'));
    await dao.insert(_meal(id: 'meal-b', userId: 'user-b'));
  });

  tearDown(() => db.close());

  test('weekly read returns only the active subject rows', () async {
    final a = await datasource.getMealByWeeks(userId: 'user-a');
    final b = await datasource.getMealByWeeks(userId: 'user-b');

    expect(a.map((item) => item.id), ['meal-a']);
    expect(b.map((item) => item.id), ['meal-b']);
  });

  test('legacy unscoped mutation is rejected when multiple owners exist', () async {
    expect(
      () => datasource.completeMealById('meal-a'),
      throwsA(isA<StateError>()),
    );
  });

  test('completion cannot mutate another subject meal by global id', () async {
    expect(
      () => datasource.completeMealById('meal-a', userId: 'user-b'),
      throwsA(isA<StateError>()),
    );

    expect((await dao.getById('meal-a'))!.isCompleted, isFalse);

    await datasource.completeMealById('meal-a', userId: 'user-a');
    expect((await dao.getById('meal-a'))!.isCompleted, isTrue);
  });
}

MealPlanModel _meal({required String id, required String userId}) {
  return MealPlanModel(
    id: id,
    userId: userId,
    planDate: '2026-08-17',
    mealType: 'breakfast',
    mealName: 'Bữa sáng',
    description: '',
    calories: 300,
    protein: 10,
    carbs: 40,
    fat: 8,
    fiber: 4,
    waterMl: 200,
    mealOrder: 1,
    isCompleted: false,
    aiGenerated: true,
    createdAt: '2026-08-17T00:00:00.000Z',
    updatedAt: '2026-08-17T00:00:00.000Z',
  );
}
