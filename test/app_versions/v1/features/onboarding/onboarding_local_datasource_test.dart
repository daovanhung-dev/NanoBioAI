import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/data/datasource/onboarding_local_datasource.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/domain/entities/onboarding_entity.dart';
import 'package:nano_app/core/storage/localdb/sync/sync_outbox_schema.dart';
import 'package:nano_app/core/storage/localdb/tables/food_allergies_table.dart';
import 'package:nano_app/core/storage/localdb/tables/health_conditions_table.dart';
import 'package:nano_app/core/storage/localdb/tables/health_goals_table.dart';
import 'package:nano_app/core/storage/localdb/tables/health_profiles_table.dart';
import 'package:nano_app/core/storage/localdb/tables/lifestyle_habits_table.dart';
import 'package:nano_app/core/storage/localdb/tables/medical_treatments_table.dart';
import 'package:nano_app/core/storage/localdb/tables/survey_answers_table.dart';
import 'package:nano_app/core/storage/localdb/tables/users_table.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late OnboardingLocalDatasource datasource;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await _createOnboardingSchema(db);
    datasource = OnboardingLocalDatasource(database: db);
  });

  tearDown(() async {
    await db.close();
  });

  group('OnboardingLocalDatasource', () {
    test('saves guest profile and durable sync marker', () async {
      final userId = await datasource.saveOnboarding(_entity());

      final user = await _singleRow(db, 'users', userId);
      expect(user['product_access_status'], 'guest');
      expect(user['onboarding_status'], 'in_progress');
      expect(user['full_name'], 'Nguyen Van Bao');

      final profile = await _singleUserRow(db, 'health_profiles', userId);
      expect(profile['occupation'], 'office_worker');
      expect(profile['height_cm'], 171);
      expect(profile['weight_kg'], 64);
      expect(profile['bmi'], closeTo(21.89, 0.01));

      final goals = await _rowsForUser(db, 'health_goals', userId);
      expect(goals.map((row) => row['goal_code']), contains('lose_weight'));
      expect(goals.map((row) => row['goal_code']), contains('other_goal'));

      final conditions = await _rowsForUser(db, 'health_conditions', userId);
      expect(
        conditions.map((row) => row['condition_code']),
        contains('stress'),
      );
      expect(
        conditions.map((row) => row['condition_code']),
        contains('other_condition'),
      );

      final lifestyle = await _singleUserRow(db, 'lifestyle_habits', userId);
      expect(lifestyle['skip_breakfast'], 1);
      expect(lifestyle['low_water'], 1);
      expect(lifestyle['sleep_quality'], 'sleep_ok');

      final allergy = await _singleUserRow(db, 'food_allergies', userId);
      expect(allergy['allergy_name'], 'peanut');

      final treatment = await _singleUserRow(db, 'medical_treatments', userId);
      expect(treatment['treatment_name'], 'therapy');
      expect(treatment['medication_name'], 'med-a');

      final surveyRows = await _rowsForUser(db, 'survey_answers', userId);
      final surveyCodes = surveyRows.map((row) => row['question_code']);
      expect(surveyCodes, contains('full_name'));
      expect(surveyCodes, contains('concern_text'));
      expect(surveyCodes, contains('lifestyle_habit_codes'));
      final habitRow = surveyRows.singleWhere(
        (row) => row['question_code'] == 'lifestyle_habit_codes',
      );
      expect(jsonDecode(habitRow['answer_value']! as String), [
        'skip_breakfast',
        'low_water',
      ]);

      final outboxRows = await db.query(
        SyncOutboxSchema.outboxTable,
        where: 'user_id = ? AND table_name = ?',
        whereArgs: [userId, 'users'],
      );
      expect(outboxRows, hasLength(1));
      expect(outboxRows.single['operation'], 'upsert');
    });

    test('re-save replaces old user-scoped onboarding rows', () async {
      final userId = await datasource.saveOnboarding(_entity());

      await datasource.saveOnboarding(
        _entity(
          goals: const ['gain_weight'],
          otherGoal: '',
          conditions: const [],
          otherCondition: '',
          habits: const ['eat_late'],
          allergyName: '',
          treatmentName: '',
          medicationName: '',
          treatmentNote: '',
        ),
      );

      final goals = await _rowsForUser(db, 'health_goals', userId);
      expect(goals, hasLength(1));
      expect(goals.single['goal_code'], 'gain_weight');

      final conditions = await _rowsForUser(db, 'health_conditions', userId);
      expect(conditions, isEmpty);

      final allergies = await _rowsForUser(db, 'food_allergies', userId);
      expect(allergies, isEmpty);

      final treatments = await _rowsForUser(db, 'medical_treatments', userId);
      expect(treatments, isEmpty);

      final lifestyle = await _singleUserRow(db, 'lifestyle_habits', userId);
      expect(lifestyle['eat_late'], 1);
      expect(lifestyle['skip_breakfast'], 0);
    });

    test('markOnboardingCompleted updates local completion state', () async {
      final userId = await datasource.saveOnboarding(_entity());

      await datasource.markOnboardingCompleted(userId);

      final user = await _singleRow(db, 'users', userId);
      expect(user['onboarding_status'], 'completed');
      expect(user['onboarding_completed_at'], isNotNull);
    });
  });
}

Future<void> _createOnboardingSchema(Database db) async {
  await db.execute(UsersTable.createTable);
  await db.execute(HealthProfilesTable.createTable);
  await db.execute(HealthGoalsTable.createTable);
  await db.execute(HealthConditionsTable.createTable);
  await db.execute(LifestyleHabitsTable.createTable);
  await db.execute(FoodAllergiesTable.createTable);
  await db.execute(MedicalTreatmentsTable.createTable);
  await db.execute(SurveyAnswersTable.createTable);

  const realOnboardingTables = {
    'health_profiles',
    'health_goals',
    'health_conditions',
    'lifestyle_habits',
    'food_allergies',
    'medical_treatments',
    'survey_answers',
  };

  for (final table in SyncOutboxSchema.userOwnedTables) {
    if (realOnboardingTables.contains(table)) continue;
    await db.execute('CREATE TABLE $table (id TEXT PRIMARY KEY, user_id TEXT)');
  }

  await SyncOutboxSchema.create(db);
}

Future<Map<String, Object?>> _singleRow(
  Database db,
  String table,
  String id,
) async {
  final rows = await db.query(table, where: 'id = ?', whereArgs: [id]);
  expect(rows, hasLength(1));
  return rows.single;
}

Future<Map<String, Object?>> _singleUserRow(
  Database db,
  String table,
  String userId,
) async {
  final rows = await _rowsForUser(db, table, userId);
  expect(rows, hasLength(1));
  return rows.single;
}

Future<List<Map<String, Object?>>> _rowsForUser(
  Database db,
  String table,
  String userId,
) {
  return db.query(table, where: 'user_id = ?', whereArgs: [userId]);
}

OnboardingEntity _entity({
  List<String> goals = const ['lose_weight'],
  String otherGoal = 'build stamina',
  List<String> conditions = const ['stress'],
  String otherCondition = 'neck tension',
  List<String> habits = const ['skip_breakfast', 'low_water'],
  String allergyName = 'peanut',
  String treatmentName = 'therapy',
  String medicationName = 'med-a',
  String treatmentNote = 'weekly',
}) {
  return OnboardingEntity(
    email: 'guest@example.com',
    phone: '0900000000',
    fullName: 'Nguyen Van Bao',
    gender: 'male',
    birthYear: 1994,
    occupation: 'office_worker',
    heightCm: 171,
    weightKg: 64,
    goals: goals,
    otherGoal: otherGoal,
    conditions: conditions,
    otherCondition: otherCondition,
    habits: habits,
    sleepQuality: 'sleep_ok',
    activityLevel: 'light',
    waterPerDay: 'under_1l',
    allergyName: allergyName,
    allergyNote: 'rash',
    treatmentName: treatmentName,
    medicationName: medicationName,
    treatmentNote: treatmentNote,
    concernText: 'private concern',
    agreed: true,
  );
}
