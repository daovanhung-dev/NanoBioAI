import 'package:nano_app/core/storage/localdb/tables/meal_plans_table.dart';
import 'package:nano_app/core/storage/localdb/tables/daily_health_tasks_table.dart';
import 'package:nano_app/core/storage/localdb/tables/lifestyle_schedule_items_table.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'database_constants.dart';
import 'database_version.dart';

// TABLES
import 'tables/users_table.dart';
import 'tables/health_profiles_table.dart';
import 'tables/health_goals_table.dart';
import 'tables/health_conditions_table.dart';
import 'tables/lifestyle_habits_table.dart';
import 'tables/food_allergies_table.dart';
import 'tables/medical_treatments_table.dart';
import 'tables/health_tracking_logs_table.dart';
import 'tables/nutrition_logs_table.dart';
import 'tables/ai_insights_table.dart';
import 'tables/ai_recommendations_table.dart';
import 'tables/notifications_table.dart';
import 'tables/survey_answers_table.dart';

// MIGRATIONS
import 'migrations/migration_manager.dart';

class DatabaseService {
  DatabaseService._();

  static Database? _database;

  /// Global database getter
  static Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();

    return _database!;
  }

  /// Initialize database
  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();

    final path = join(dbPath, DatabaseConstants.databaseName);

    return await openDatabase(
      path,

      // DATABASE VERSION
      version: DatabaseVersion.currentVersion,

      // CONFIG
      onConfigure: (db) async {
        // Disable foreign key constraints
        await db.execute('PRAGMA foreign_keys = OFF');
      },

      // CREATE DATABASE
      onCreate: (db, version) async {
        await _createTables(db);
      },

      // DATABASE UPGRADE
      onUpgrade: (db, oldVersion, newVersion) async {
        await MigrationManager.runMigrations(db, oldVersion, newVersion);
      },

      // OPEN DATABASE
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = OFF');
      },
    );
  }

  /// Create all tables
  static Future<void> _createTables(Database db) async {
    await db.execute(UsersTable.createTable);

    await db.execute(HealthProfilesTable.createTable);

    await db.execute(HealthGoalsTable.createTable);

    await db.execute(HealthConditionsTable.createTable);

    await db.execute(LifestyleHabitsTable.createTable);

    await db.execute(FoodAllergiesTable.createTable);

    await db.execute(MedicalTreatmentsTable.createTable);

    await db.execute(HealthTrackingLogsTable.createTable);

    await db.execute(DailyHealthTasksTable.createTable);

    await db.execute(LifestyleScheduleItemsTable.createTable);
    await db.execute(LifestyleScheduleItemsTable.createDateIndex);
    await db.execute(LifestyleScheduleItemsTable.createSourceIndex);

    await db.execute(NutritionLogsTable.createTable);

    await db.execute(AIInsightsTable.createTable);

    await db.execute(AIRecommendationsTable.createTable);

    await db.execute(NotificationsTable.createTable);

    await db.execute(SurveyAnswersTable.createTable);

    await db.execute(MealPlansTable.createTable);
  }

  /// Delete database
  static Future<void> deleteDatabaseFile() async {
    final dbPath = await getDatabasesPath();

    final path = join(dbPath, DatabaseConstants.databaseName);

    await deleteDatabase(path);

    _database = null;
  }

  /// Close database
  static Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();

      _database = null;
    }
  }
}
