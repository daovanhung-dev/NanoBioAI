import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/data/datasource/onboarding_local_datasource.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/domain/entities/onboarding_entity.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/domain/repositories/onboarding_repository_impl.dart';
import 'package:nano_app/core/storage/localdb/app_prefs.dart';
import 'package:nano_app/core/storage/localdb/tables/food_allergies_table.dart';
import 'package:nano_app/core/storage/localdb/tables/health_conditions_table.dart';
import 'package:nano_app/core/storage/localdb/tables/health_goals_table.dart';
import 'package:nano_app/core/storage/localdb/tables/health_profiles_table.dart';
import 'package:nano_app/core/storage/localdb/tables/lifestyle_habits_table.dart';
import 'package:nano_app/core/storage/localdb/tables/medical_treatments_table.dart';
import 'package:nano_app/core/storage/localdb/tables/survey_answers_table.dart';
import 'package:nano_app/core/storage/localdb/tables/users_table.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await _createSchema(db);
  });

  tearDown(() => db.close());

  test('retry with empty email and phone reuses the durable guest id', () async {
    final repository = OnboardingRepositoryImpl(
      localDatasource: OnboardingLocalDatasource(database: db),
      currentUserId: () => null,
    );

    await repository.save(_guestEntity());
    final firstGuestId = await AppPrefs.pendingGuestUserId();
    expect(firstGuestId, isNotNull);

    // Simulate a downstream initial-plan failure: onboarding is not marked
    // completed, but the profile transaction already succeeded. The retry must
    // bind to the same local guest row.
    await repository.save(_guestEntity());
    final secondGuestId = await AppPrefs.pendingGuestUserId();

    expect(secondGuestId, firstGuestId);
    expect(await db.query('users'), hasLength(1));
    expect(
      await db.query(
        'health_profiles',
        where: 'user_id = ?',
        whereArgs: [firstGuestId],
      ),
      hasLength(1),
    );
  });
}

Future<void> _createSchema(Database db) async {
  await db.execute(UsersTable.createTable);
  await db.execute(HealthProfilesTable.createTable);
  await db.execute(HealthGoalsTable.createTable);
  await db.execute(HealthConditionsTable.createTable);
  await db.execute(LifestyleHabitsTable.createTable);
  await db.execute(FoodAllergiesTable.createTable);
  await db.execute(MedicalTreatmentsTable.createTable);
  await db.execute(SurveyAnswersTable.createTable);

}

OnboardingEntity _guestEntity() => const OnboardingEntity(
  email: '',
  phone: '',
  fullName: 'Guest Retry',
  gender: 'male',
  birthYear: 2000,
  occupation: 'student',
  heightCm: 170,
  weightKg: 65,
  goals: [],
  otherGoal: '',
  conditions: [],
  otherCondition: '',
  habits: [],
  sleepQuality: 'sleep_ok',
  activityLevel: 'light',
  waterPerDay: 'under_1l',
  allergyName: '',
  allergyNote: '',
  treatmentName: '',
  medicationName: '',
  treatmentNote: '',
  concernText: '',
  agreed: true,
);
