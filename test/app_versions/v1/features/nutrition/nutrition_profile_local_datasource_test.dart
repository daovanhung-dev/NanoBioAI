import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/nutrition/data/datasources/nutrition_profile_local_datasource.dart';
import 'package:nano_app/app_versions/v1/features/nutrition/domain/entities/nutrition_profile_entity.dart';
import 'package:nano_app/core/storage/localdb/tables/nutrition_profile_tables.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database database;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await NutritionProfileTables.create(database);
  });

  tearDown(() => database.close());

  test('saves and reloads the structured profile in one transaction', () async {
    final datasource = NutritionProfileLocalDatasource(
      databaseOverride: database,
    );
    final profile = NutritionProfileEntity.empty('user-1').copyWith(
      currentStatus: 'Đang ổn định',
      averageSleepHours: 7.5,
      restrictions: const <FoodRestrictionEntity>[
        FoodRestrictionEntity(type: 'intolerance', itemName: 'sữa bò'),
      ],
      goals: const <NutritionGoalEntity>[
        NutritionGoalEntity(
          code: 'balanced_diet',
          name: 'Ăn cân bằng',
          priority: 1,
        ),
      ],
    );

    await datasource.save(profile);
    final loaded = await datasource.load('user-1');

    expect(loaded.currentStatus, 'Đang ổn định');
    expect(loaded.averageSleepHours, 7.5);
    expect(loaded.restrictions.single.itemName, 'sữa bò');
    expect(loaded.goals.single.code, 'balanced_diet');
  });

  test('rejects more than three active goals before writing', () async {
    final datasource = NutritionProfileLocalDatasource(
      databaseOverride: database,
    );
    final profile = NutritionProfileEntity.empty('user-1').copyWith(
      goals: List<NutritionGoalEntity>.generate(
        4,
        (index) => NutritionGoalEntity(
          code: 'goal-$index',
          name: 'Mục tiêu $index',
          priority: (index % 3) + 1,
        ),
      ),
    );

    await expectLater(datasource.save(profile), throwsFormatException);
    final rows = await database.query(NutritionProfileTables.nutritionProfiles);
    expect(rows, isEmpty);
  });
}
