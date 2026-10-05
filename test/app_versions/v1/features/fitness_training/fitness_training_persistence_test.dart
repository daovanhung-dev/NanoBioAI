import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/fitness_training/data/datasources/fitness_training_local_datasource.dart';
import 'package:nano_app/app_versions/v1/features/fitness_training/data/datasources/fitness_training_catalog_asset_datasource.dart';
import 'package:nano_app/app_versions/v1/features/fitness_training/domain/entities/fitness_training_catalog.dart';
import 'package:nano_app/app_versions/v1/features/fitness_training/domain/entities/fitness_training_program.dart';
import 'package:nano_app/core/storage/localdb/migrations/migration_v25.dart';
import 'package:nano_app/core/storage/localdb/tables/fitness_training_programs_table.dart';
import 'package:nano_app/core/storage/localdb/tables/lifestyle_schedule_items_table.dart';
import 'package:nano_app/core/storage/localdb/tables/users_table.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(sqfliteFfiInit);

  test('migration creates the M32 program table and status index', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);

    await db.execute(UsersTable.createTable);
    await MigrationV25.ensureSchema(db);

    final columns = await db.rawQuery(
      'PRAGMA table_info(${FitnessTrainingProgramsTable.tableName})',
    );
    expect(
      columns.map((row) => row['name']),
      containsAll([
        'id',
        'user_id',
        'request_id',
        'status',
        'active_week',
        'quota_committed',
        'program_json',
      ]),
    );
    final indexes = await db.rawQuery(
      "PRAGMA index_list('${FitnessTrainingProgramsTable.tableName}')",
    );
    expect(
      indexes.map((row) => row['name']),
      contains('idx_fitness_programs_user_status'),
    );
  });

  test(
    'applying a week preserves completed, past and non-M32 schedule rows',
    () async {
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      addTearDown(db.close);
      await db.execute(UsersTable.createTable);
      await db.insert(UsersTable.tableName, {'id': 'user-1'});
      await db.execute(LifestyleScheduleItemsTable.createTable);
      await MigrationV25.ensureSchema(db);
      final catalog = await const FitnessTrainingCatalogAssetDatasource()
          .load();
      final today = DateTime(2026, 1, 1, 10);
      final program = _program(today, catalog);
      await db.insert(FitnessTrainingProgramsTable.tableName, {
        'id': program.id,
        'user_id': program.userId,
        'request_id': program.requestId,
        'status': program.status,
        'active_week': program.activeWeek,
        'quota_committed': 1,
        'program_json': jsonEncode(program.toJson()),
        'created_at': program.createdAt.toIso8601String(),
        'updated_at': program.updatedAt.toIso8601String(),
      });
      await _insertSchedule(
        db,
        id: 'completed-m32',
        date: '2026-01-01',
        time: '11:00',
        source: 'fitness_training',
        completed: true,
      );
      await _insertSchedule(
        db,
        id: 'past-m32',
        date: '2026-01-01',
        time: '08:00',
        source: 'fitness_training',
      );
      await _insertSchedule(
        db,
        id: 'future-m32',
        date: '2026-01-01',
        time: '11:00',
        source: 'fitness_training',
      );
      await _insertSchedule(
        db,
        id: 'tomorrow-m32',
        date: '2026-01-02',
        time: '08:00',
        source: 'fitness_training',
      );
      await _insertSchedule(
        db,
        id: 'health-item',
        date: '2026-01-02',
        time: '08:00',
        source: 'health_tracking',
      );

      await FitnessTrainingLocalDatasource(databaseOverride: db).applyWeek(
        userId: 'user-1',
        programId: program.id,
        week: 1,
        today: today,
        catalog: catalog,
      );

      final remaining = await db.query(LifestyleScheduleItemsTable.tableName);
      final ids = remaining.map((row) => row['id']).toSet();
      expect(ids, containsAll(['completed-m32', 'past-m32', 'health-item']));
      expect(ids, isNot(contains('future-m32')));
      expect(ids, isNot(contains('tomorrow-m32')));
      expect(
        remaining.where((row) => row['source_type'] == 'fitness_training'),
        isNotEmpty,
        reason: 'the selected week should be written to the schedule',
      );
      final todayItems = remaining
          .where(
            (row) =>
                row['source_type'] == 'fitness_training' &&
                row['schedule_date'] == '2026-01-01',
          )
          .toList();
      expect(
        todayItems.where((row) => row['start_time'] == '07:30'),
        isEmpty,
        reason: 'same-day meal times before now are not written again',
      );
      expect(
        todayItems.where((row) => row['start_time'] == '10:00'),
        hasLength(1),
        reason: 'an item exactly at the current time remains schedulable',
      );
    },
  );
}

FitnessTrainingProgram _program(
  DateTime start,
  FitnessTrainingCatalog catalog,
) {
  final intake = FitnessTrainingIntake(
    adultEligible: true,
    goal: 'general_fitness',
    experience: 'beginner',
    venue: 'home',
    equipmentIds: const [],
    trainingWeekdays: const [1, 3, 5],
    sessionMinutes: 45,
    workoutTime: '17:30',
    mealTimes: const ['07:30', '10:00', '12:30', '15:30', '19:00'],
    excludedMovementGroups: const [],
    excludedAllergens: const [],
    availableFoodGroups: const [
      'protein',
      'carbohydrate',
      'fruit_vegetable',
      'fat_source',
    ],
    sleepTime: '22:30',
    wakeTime: '06:30',
    heightCm: null,
    weightKg: null,
    sexCode: null,
    activityLevel: null,
    bmi: null,
    bmrKcal: null,
    tdeeKcal: null,
  );
  return FitnessTrainingProgram(
    id: 'program-1',
    userId: 'user-1',
    requestId: 'request-1',
    status: FitnessProgramStatus.preview,
    activeWeek: 1,
    quotaCommitted: true,
    startDate: DateTime(start.year, start.month, start.day),
    intake: intake,
    days: [
      for (var day = 0; day < 28; day++)
        FitnessProgramDay(
          dayIndex: day,
          date: DateTime(
            start.year,
            start.month,
            start.day,
          ).add(Duration(days: day)),
          isRestDay: true,
          exercises: const [],
          meals: day == 0
              ? [
                  FitnessProgramMeal(
                    mealSlot: 'breakfast',
                    recipeId: catalog.recipes
                        .firstWhere((item) => item.mealSlot == 'breakfast')
                        .id,
                    servings: 1,
                  ),
                  FitnessProgramMeal(
                    mealSlot: 'morning_snack',
                    recipeId: catalog.recipes
                        .firstWhere((item) => item.mealSlot == 'morning_snack')
                        .id,
                    servings: 1,
                  ),
                ]
              : const [],
          sleepTime: '22:30',
          wakeTime: '06:30',
        ),
    ],
    checkIns: const [],
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );
}

Future<void> _insertSchedule(
  Database db, {
  required String id,
  required String date,
  required String time,
  required String source,
  bool completed = false,
}) => db.insert(LifestyleScheduleItemsTable.tableName, {
  'id': id,
  'user_id': 'user-1',
  'schedule_date': date,
  'start_time': time,
  'end_time': '',
  'title': id,
  'description': '',
  'category': source == 'fitness_training' ? 'routine' : 'health',
  'source_type': source,
  'source_id': 'prior-source',
  'target_value': 1,
  'current_value': 0,
  'unit': 'lần',
  'is_completed': completed ? 1 : 0,
  'sort_order': 1,
  'ai_generated': 1,
  'encouragement': '',
  'created_at': '2026-01-01T00:00:00Z',
  'updated_at': '2026-01-01T00:00:00Z',
});
