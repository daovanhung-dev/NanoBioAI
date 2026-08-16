import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/storage/localdb/daos/ai_catalog_dao.dart';
import 'package:nano_app/core/storage/localdb/models/ai_catalog_models.dart';
import 'package:nano_app/core/storage/localdb/tables/meal_catalog_table.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database database;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await database.execute(MealCatalogTable.createTable);
  });

  tearDown(() => database.close());

  test('replaceMeals removes legacy rows and mirrors Supabase rows', () async {
    final dao = AiCatalogDao(database);
    await dao.upsertMeals([_meal('local_legacy')]);

    await dao.replaceMeals([
      _meal(
        'src_supabase_1',
        mealType: 'unclassified',
        isPlanEligible: false,
        metadataStatus: 'source_imported',
      ),
      _meal('src_supabase_2', mealType: 'breakfast'),
    ]);

    final rows = await database.query(
      MealCatalogTable.tableName,
      orderBy: 'code ASC',
    );
    expect(rows.map((row) => row['code']), [
      'src_supabase_1',
      'src_supabase_2',
    ]);
  });

  test('active bundle includes active non-plan-eligible Supabase rows', () async {
    final dao = AiCatalogDao(database);
    await dao.replaceMeals([
      _meal(
        'src_reference',
        mealType: 'unclassified',
        isPlanEligible: false,
        metadataStatus: 'source_imported',
      ),
      _meal('inactive', isActive: false),
    ]);

    final meals = await dao.getActiveMeals();

    expect(meals.map((item) => item.code), ['src_reference']);
  });
}

MealCatalogItemModel _meal(
  String code, {
  String mealType = 'breakfast',
  bool isPlanEligible = true,
  bool isActive = true,
  String metadataStatus = 'approved',
}) {
  return MealCatalogItemModel(
    code: code,
    mealType: mealType,
    mealName: 'Món $code',
    description: 'Mô tả',
    cookingInstructions: 'Cách làm',
    calories: 0,
    protein: 0,
    carbs: 0,
    fat: 0,
    fiber: 0,
    waterMl: 0,
    metadataStatus: metadataStatus,
    constraintMetadataStatus: metadataStatus,
    isPlanEligible: isPlanEligible,
    isActive: isActive,
    createdAt: '2026-08-16T00:00:00Z',
    updatedAt: '2026-08-16T00:00:00Z',
  );
}
