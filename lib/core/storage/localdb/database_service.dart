import 'package:nano_app/core/storage/localdb/tables/meal_plans_table.dart';
import 'package:nano_app/core/storage/localdb/tables/meal_catalog_table.dart';
import 'package:nano_app/core/storage/localdb/tables/exercise_catalog_table.dart';
import 'package:nano_app/core/storage/localdb/tables/schedule_task_catalog_table.dart';
import 'package:nano_app/core/storage/localdb/tables/daily_health_tasks_table.dart';
import 'package:nano_app/core/storage/localdb/tables/health_score_ledgers_table.dart';
import 'package:nano_app/core/storage/localdb/tables/lifestyle_schedule_items_table.dart';
import 'package:nano_app/core/storage/localdb/tables/personal_schedule_ai_requests_table.dart';
import 'package:nano_app/core/storage/localdb/tables/schedule_completion_proofs_table.dart';
import 'package:nano_app/core/storage/localdb/tables/schedule_health_checkin_outbox_table.dart';
import 'package:nano_app/core/storage/localdb/tables/wellness_point_ledgers_table.dart';
import 'package:nano_app/core/storage/localdb/tables/wellness_rewards_cache_tables.dart';
import 'package:nano_app/core/storage/localdb/tables/nabi_notification_tables.dart';
import 'package:nano_app/core/storage/localdb/tables/nutrition_profile_tables.dart';
import 'package:nano_app/core/storage/localdb/tables/sleep_safety_tables.dart';
import 'package:nano_app/core/utils/logger/app_log_category.dart';
import 'package:nano_app/core/utils/logger/app_log_level.dart';
import 'package:nano_app/core/utils/logger/app_logger.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'database_constants.dart';
import 'database_version.dart';
import 'sync/sync_outbox_schema.dart';
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
import 'migrations/migration_manager.dart';
import 'migrations/migration_v18.dart';
import 'migrations/migration_v19.dart';
import 'migrations/migration_v20.dart';
import 'migrations/migration_v21.dart';
import 'migrations/migration_v22.dart';
import 'migrations/migration_v23.dart';
import 'migrations/migration_v24.dart';
import 'seeders/ai_catalog_seeder.dart';

class DatabaseService {
  DatabaseService._();

  static const _logScope = 'DatabaseService';
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final stopwatch = Stopwatch()..start();
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, DatabaseConstants.databaseName);
    AppLogger.event(
      level: AppLogLevel.info,
      category: AppLogCategory.database,
      scope: _logScope,
      operation: 'OPEN',
      message: 'Opening local database',
      metadata: {'version': DatabaseVersion.currentVersion},
    );

    try {
      final db = await openDatabase(
        path,
        version: DatabaseVersion.currentVersion,
        onConfigure: (db) async {
          final phase = Stopwatch()..start();
          try {
            final existingVersion = await db.getVersion();
            await db.execute(
              existingVersion == 0 || existingVersion >= 20
                  ? 'PRAGMA foreign_keys = ON'
                  : 'PRAGMA foreign_keys = OFF',
            );
            phase.stop();
            AppLogger.event(
              level: AppLogLevel.debug,
              category: AppLogCategory.database,
              scope: _logScope,
              operation: 'CONFIGURE',
              message: 'Database configured',
              duration: phase.elapsed,
              metadata: {
                'existingVersion': existingVersion,
                'foreignKeysEnabled':
                    existingVersion == 0 || existingVersion >= 20,
              },
            );
          } catch (error, stackTrace) {
            phase.stop();
            AppLogger.captureError(
              category: AppLogCategory.database,
              scope: _logScope,
              operation: 'CONFIGURE',
              message: 'Database configuration failed',
              error: error,
              stackTrace: stackTrace,
              duration: phase.elapsed,
            );
            rethrow;
          }
        },
        onCreate: (db, version) async {
          final phase = Stopwatch()..start();
          try {
            await _createTables(db);
            phase.stop();
            AppLogger.event(
              level: AppLogLevel.info,
              category: AppLogCategory.database,
              scope: _logScope,
              operation: 'CREATE',
              message: 'Database schema created',
              duration: phase.elapsed,
              metadata: {'version': version},
            );
          } catch (error, stackTrace) {
            phase.stop();
            AppLogger.captureError(
              category: AppLogCategory.database,
              scope: _logScope,
              operation: 'CREATE',
              message: 'Database schema creation failed',
              error: error,
              stackTrace: stackTrace,
              duration: phase.elapsed,
              metadata: {'version': version},
            );
            rethrow;
          }
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          final phase = Stopwatch()..start();
          try {
            await MigrationManager.runMigrations(db, oldVersion, newVersion);
            if (oldVersion < 18 && newVersion >= 18) await MigrationV18.run(db);
            if (oldVersion < 19 && newVersion >= 19) await MigrationV19.run(db);
            if (oldVersion < 20 && newVersion >= 20) await MigrationV20.run(db);
            if (oldVersion < 21 && newVersion >= 21) await MigrationV21.run(db);
            if (oldVersion < 22 && newVersion >= 22) await MigrationV22.run(db);
            if (oldVersion < 23 && newVersion >= 23) await MigrationV23.run(db);
            if (oldVersion < 24 && newVersion >= 24) await MigrationV24.run(db);
            phase.stop();
            AppLogger.event(
              level: AppLogLevel.info,
              category: AppLogCategory.database,
              scope: _logScope,
              operation: 'MIGRATE',
              message: 'Database migration completed',
              duration: phase.elapsed,
              metadata: {'fromVersion': oldVersion, 'toVersion': newVersion},
            );
          } catch (error, stackTrace) {
            phase.stop();
            AppLogger.captureError(
              category: AppLogCategory.database,
              scope: _logScope,
              operation: 'MIGRATE',
              message: 'Database migration failed',
              error: error,
              stackTrace: stackTrace,
              duration: phase.elapsed,
              metadata: {'fromVersion': oldVersion, 'toVersion': newVersion},
            );
            rethrow;
          }
        },
        onOpen: (db) async {
          final phase = Stopwatch()..start();
          try {
            await db.execute('PRAGMA foreign_keys = ON');
            await MigrationV18.ensureSchema(db);
            await MigrationV19.ensureSchema(db);
            final version = await db.getVersion();
            if (version >= 20) await MigrationV20.assertIntegrity(db);
            if (version >= 21) await MigrationV21.ensureSchema(db);
            if (version >= 22) await MigrationV22.ensureSchema(db);
            if (version >= 23) await MigrationV23.ensureSchema(db);
            phase.stop();
            AppLogger.event(
              level: AppLogLevel.info,
              category: AppLogCategory.database,
              scope: _logScope,
              operation: 'INTEGRITY_CHECK',
              message: 'Database opened and integrity checks passed',
              duration: phase.elapsed,
              metadata: {'version': version},
            );
          } catch (error, stackTrace) {
            phase.stop();
            AppLogger.captureError(
              category: AppLogCategory.database,
              scope: _logScope,
              operation: 'INTEGRITY_CHECK',
              message: 'Database open/integrity check failed',
              error: error,
              stackTrace: stackTrace,
              duration: phase.elapsed,
            );
            rethrow;
          }
        },
      );
      stopwatch.stop();
      AppLogger.event(
        level: AppLogLevel.info,
        category: AppLogCategory.database,
        scope: _logScope,
        operation: 'OPEN',
        message: 'Local database ready',
        duration: stopwatch.elapsed,
        metadata: {'version': await db.getVersion()},
      );
      return db;
    } catch (error, stackTrace) {
      stopwatch.stop();
      AppLogger.captureError(
        category: AppLogCategory.database,
        scope: _logScope,
        operation: 'OPEN',
        message: 'Failed to open local database',
        error: error,
        stackTrace: stackTrace,
        duration: stopwatch.elapsed,
        level: AppLogLevel.fatal,
      );
      rethrow;
    }
  }

  static Future<void> _createTables(Database db) async {
    await db.execute(UsersTable.createTable);
    await db.execute(HealthProfilesTable.createTable);
    await db.execute(HealthGoalsTable.createTable);
    await db.execute(HealthConditionsTable.createTable);
    await db.execute(LifestyleHabitsTable.createTable);
    await db.execute(FoodAllergiesTable.createTable);
    await db.execute(MedicalTreatmentsTable.createTable);
    await db.execute(HealthTrackingLogsTable.createTable);
    await db.execute(HealthScoreLedgersTable.createTable);
    await db.execute(HealthScoreLedgersTable.createSubjectPeriodIndex);
    await db.execute(HealthScoreLedgersTable.createUserPeriodIndex);
    await db.execute(WellnessPointLedgersTable.createTable);
    await db.execute(WellnessPointLedgersTable.createUserDateIndex);
    await db.execute(WellnessPointLedgersTable.createSourceIndex);
    await db.execute(DailyHealthTasksTable.createTable);
    await db.execute(LifestyleScheduleItemsTable.createTable);
    await db.execute(LifestyleScheduleItemsTable.createDateIndex);
    await db.execute(LifestyleScheduleItemsTable.createSourceIndex);
    await db.execute(ScheduleCompletionProofsTable.createTable);
    await db.execute(ScheduleCompletionProofsTable.createUserDateIndex);
    await db.execute(ScheduleCompletionProofsTable.createScheduleIndex);
    await db.execute(ScheduleCompletionProofsTable.createEligibilityIndex);
    await db.execute(ScheduleHealthCheckInOutboxTable.createTable);
    await db.execute(ScheduleHealthCheckInOutboxTable.createPendingIndex);
    await db.execute(ScheduleHealthCheckInOutboxTable.createScheduleIndex);
    for (final statement in wellnessRewardCacheSchema) {
      await db.execute(statement);
    }
    await NabiNotificationTables.create(db);
    await SleepSafetyTables.create(db);
    await db.execute(NutritionLogsTable.createTable);
    await db.execute(AIInsightsTable.createTable);
    await db.execute(AIRecommendationsTable.createTable);
    await db.execute(NotificationsTable.createTable);
    await db.execute(SurveyAnswersTable.createTable);
    await db.execute(MealPlansTable.createTable);
    await NutritionProfileTables.create(db);
    await db.execute(PersonalScheduleAiRequestsTable.createTable);
    await db.execute(PersonalScheduleAiRequestsTable.createUserModeIndex);
    await db.execute(MealCatalogTable.createTable);
    await db.execute(MealCatalogTable.createTypeIndex);
    await db.execute(MealCatalogTable.createTopicIndex);
    await db.execute(MealCatalogTable.createSourceHashIndex);
    await db.execute(ExerciseCatalogTable.createTable);
    await db.execute(ExerciseCatalogTable.createCategoryIndex);
    await db.execute(ScheduleTaskCatalogTable.createTable);
    await db.execute(ScheduleTaskCatalogTable.createCategoryIndex);
    await MigrationV22.ensureSchema(db);
    await MigrationV23.ensureSchema(db);
    await AiCatalogSeeder.seed(db);
    await SyncOutboxSchema.create(db);
  }

  static Future<void> deleteDatabaseFile() async {
    final stopwatch = Stopwatch()..start();
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, DatabaseConstants.databaseName);
    try {
      // Close an open handle first so account deletion cannot leave a stale
      // connection or partially removed SQLite file behind.
      await closeDatabase();
      await deleteDatabase(path);
      _database = null;
      stopwatch.stop();
      AppLogger.event(
        level: AppLogLevel.warn,
        category: AppLogCategory.database,
        scope: _logScope,
        operation: 'DELETE',
        message: 'Local database file deleted',
        duration: stopwatch.elapsed,
      );
    } catch (error, stackTrace) {
      stopwatch.stop();
      AppLogger.captureError(
        category: AppLogCategory.database,
        scope: _logScope,
        operation: 'DELETE',
        message: 'Failed to delete local database file',
        error: error,
        stackTrace: stackTrace,
        duration: stopwatch.elapsed,
      );
      rethrow;
    }
  }

  static Future<void> closeDatabase() async {
    if (_database == null) return;
    final stopwatch = Stopwatch()..start();
    try {
      await _database!.close();
      _database = null;
      stopwatch.stop();
      AppLogger.event(
        level: AppLogLevel.info,
        category: AppLogCategory.database,
        scope: _logScope,
        operation: 'CLOSE',
        message: 'Local database closed',
        duration: stopwatch.elapsed,
      );
    } catch (error, stackTrace) {
      stopwatch.stop();
      AppLogger.captureError(
        category: AppLogCategory.database,
        scope: _logScope,
        operation: 'CLOSE',
        message: 'Failed to close local database',
        error: error,
        stackTrace: stackTrace,
        duration: stopwatch.elapsed,
      );
      rethrow;
    }
  }
}
