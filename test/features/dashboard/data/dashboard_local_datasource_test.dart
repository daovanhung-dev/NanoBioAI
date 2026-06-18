import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/storage/localdb/tables/food_allergies_table.dart';
import 'package:nano_app/core/storage/localdb/tables/health_conditions_table.dart';
import 'package:nano_app/core/storage/localdb/tables/health_goals_table.dart';
import 'package:nano_app/core/storage/localdb/tables/health_profiles_table.dart';
import 'package:nano_app/core/storage/localdb/tables/lifestyle_habits_table.dart';
import 'package:nano_app/core/storage/localdb/tables/medical_treatments_table.dart';
import 'package:nano_app/core/storage/localdb/tables/survey_answers_table.dart';
import 'package:nano_app/core/storage/localdb/tables/users_table.dart';
import 'package:nano_app/features/dashboard/data/datasources/dashboard_local_datasource.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute(UsersTable.createTable);
    await db.execute(HealthProfilesTable.createTable);
    await db.execute(HealthGoalsTable.createTable);
    await db.execute(HealthConditionsTable.createTable);
    await db.execute(LifestyleHabitsTable.createTable);
    await db.execute(FoodAllergiesTable.createTable);
    await db.execute(MedicalTreatmentsTable.createTable);
    await db.execute(SurveyAnswersTable.createTable);
  });

  tearDown(() async {
    await db.close();
  });

  test('fetchDashboard reads subscription tier from users table', () async {
    await db.insert('users', {
      'id': 'u1',
      'full_name': 'User One',
      'email': 'user@example.com',
      'subscription_tier': 'premium',
      'created_at': '2026-06-18T08:00:00',
    });
    await db.insert('health_profiles', {
      'id': 'profile-1',
      'user_id': 'u1',
      'height_cm': 170,
      'weight_kg': 65,
      'bmi': 22.5,
      'created_at': '2026-06-18T08:00:00',
      'updated_at': '2026-06-18T08:00:00',
    });

    final dashboard = await DashboardLocalDatasource(
      database: db,
    ).fetchDashboard();

    expect(dashboard.fullName, 'User One');
    expect(dashboard.subscriptionTier, 'premium');
    expect(dashboard.bmi, 22.5);
  });
}
