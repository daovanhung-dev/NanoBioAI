import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/services/ai/prompts/exercise_tasks_prompt.dart';
import 'package:nano_app/app_versions/v1/services/ai/prompts/meal_plan_prompt.dart';
import 'package:nano_app/core/storage/localdb/daos/ai_catalog_dao.dart';
import 'package:nano_app/core/storage/localdb/models/ai_catalog_models.dart';
import 'package:nano_app/core/storage/localdb/seeders/ai_catalog_seed_data.dart';
import 'package:nano_app/core/storage/localdb/tables/exercise_catalog_table.dart';
import 'package:nano_app/core/storage/localdb/tables/meal_catalog_table.dart';
import 'package:nano_app/core/storage/localdb/tables/schedule_task_catalog_table.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'schedule DAO returns all 163 meals and all 40 exercises to prompts',
    () async {
      final decoded =
          jsonDecode(
                await rootBundle.loadString('assets/data/meal_catalog_v1.json'),
              )
              as Map<String, dynamic>;
      final meals = (decoded['recipes'] as List)
          .whereType<Map>()
          .map(
            (row) => MealCatalogItemModel.fromSourceJson(
              Map<String, Object?>.from(row),
              timestamp: '2026-06-18T00:00:00Z',
            ),
          )
          .toList(growable: false);
      final draftExerciseSource =
          jsonDecode(
                await rootBundle.loadString(
                  'assets/data/fitness_training/fitness_exercise_equipment_draft_v1.json',
                ),
              )
              as Map<String, dynamic>;
      final draftExercises = (draftExerciseSource['exercises'] as List)
          .whereType<Map>()
          .map((row) {
            final source = Map<String, Object?>.from(row);
            return ExerciseCatalogItemModel(
              code: source['id']?.toString() ?? '',
              category: source['movement_type']?.toString() ?? '',
              title: source['name_vi']?.toString() ?? '',
              description: '',
              unit: 'minutes',
              encouragement: '',
              minTarget: 1,
              maxTarget: 10,
              defaultTarget: 5,
              intensityLevel: 'light',
              isActive: false,
              createdAt: '2026-06-18T00:00:00Z',
              updatedAt: '2026-06-18T00:00:00Z',
            );
          })
          .toList(growable: false);
      final exercises = [...AiCatalogSeedData.exercises, ...draftExercises];
      expect(AiCatalogSeedData.exercises, hasLength(16));
      expect(draftExercises, hasLength(24));
      final database = _CatalogDatabaseFake({
        MealCatalogTable.tableName: meals.map((item) => item.toMap()).toList(),
        ExerciseCatalogTable.tableName: exercises
            .map((item) => item.toMap())
            .toList(),
        ScheduleTaskCatalogTable.tableName: const [],
      });

      final bundle = await AiCatalogDao(database).loadScheduleCatalogBundle();
      expect(bundle.meals, hasLength(163));
      expect(bundle.exercises, hasLength(40));
      expect(bundle.meals.map((item) => item.code).toSet(), hasLength(163));
      expect(bundle.exercises.map((item) => item.code).toSet(), hasLength(40));
      expect(bundle.meals.where((item) => item.isActive), hasLength(163));
      expect(bundle.exercises.where((item) => item.isActive), hasLength(16));
      expect(bundle.exercises.where((item) => !item.isActive), hasLength(24));
      expect(database.queryWhere[MealCatalogTable.tableName], isNull);
      expect(database.queryWhere[ExerciseCatalogTable.tableName], isNull);

      final mealPrompt = MealPlanPrompt.generate(
        startDate: DateTime(2026, 6, 18),
        startDay: 1,
        days: 1,
        catalog: bundle.meals,
        usedMealCodeCounts: const {},
      );
      final mealPairs = [
        for (final item in bundle.meals)
          {'code': item.code, 'name': item.mealName},
      ];
      expect(mealPrompt, contains(jsonEncode(mealPairs)));
      for (final item in bundle.meals) {
        expect(mealPrompt, contains('"code":"${item.code}"'));
      }

      final exercisePrompt = ExerciseTasksPrompt.generate(
        startDate: DateTime(2026, 6, 18),
        startDay: 1,
        days: 1,
        catalog: bundle.exercises,
        usedExerciseCodeCounts: const {},
      );
      final selectable = bundle.exercises
          .where((item) => item.isActive)
          .map((item) => {'code': item.code, 'name': item.title})
          .toList(growable: false);
      final contextOnly = bundle.exercises
          .where((item) => !item.isActive)
          .map((item) => {'code': item.code, 'name': item.title})
          .toList(growable: false);
      expect(
        exercisePrompt,
        contains(
          jsonEncode({'selectable': selectable, 'context_only': contextOnly}),
        ),
      );
      for (final item in bundle.exercises) {
        expect(exercisePrompt, contains('"code":"${item.code}"'));
      }
    },
  );
}

class _CatalogDatabaseFake implements Database {
  final Map<String, List<Map<String, Object?>>> rowsByTable;
  final Map<String, String?> queryWhere = {};

  _CatalogDatabaseFake(this.rowsByTable);

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    queryWhere[table] = where;
    final rows = rowsByTable[table] ?? const [];
    return rows.map((row) => Map<String, Object?>.from(row)).toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
