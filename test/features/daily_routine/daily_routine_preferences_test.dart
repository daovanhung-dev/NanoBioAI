import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/daily_routine/data/datasources/daily_routine_preferences_local_datasource.dart';
import 'package:nano_app/app_versions/v1/features/daily_routine/domain/entities/daily_routine_preferences.dart';
import 'package:nano_app/app_versions/v1/features/daily_routine/domain/services/schedule_timing_resolver.dart';
import 'package:nano_app/core/storage/localdb/sync/sync_outbox_schema.dart';
import 'package:nano_app/core/storage/localdb/tables/survey_answers_table.dart';
import 'package:nano_app/core/storage/localdb/tables/users_table.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  test('default weekday and weekend templates are valid', () {
    expect(DailyRoutinePreferences.defaults().validate(), isEmpty);
  });

  test('sleep at or before wake time is treated as after midnight', () {
    final defaults = DailyRoutinePreferences.defaults();
    final overnight = defaults.copyWith(
      weekend: defaults.weekend.copyWith(
        wakeTime: '10:00',
        sleepTime: '01:00',
        mealTimes: ['10:30', '12:00', '14:00', '18:00', '22:00'],
        napRange: const RoutineTimeRange(start: '15:00', end: '15:30'),
        workoutRanges: const [
          RoutineTimeRange(start: '11:00', end: '11:30'),
          RoutineTimeRange(start: '23:00', end: '23:30'),
        ],
        clearBusyRange: true,
      ),
    );

    expect(overnight.validate(), isEmpty);
  });

  test('workout overlap with nap or busy range is rejected', () {
    final defaults = DailyRoutinePreferences.defaults();
    final invalid = defaults.copyWith(
      weekday: defaults.weekday.copyWith(
        workoutRanges: const [
          RoutineTimeRange(start: '12:50', end: '13:10'),
          RoutineTimeRange(start: '09:00', end: '09:30'),
        ],
      ),
    );

    expect(invalid.validate().join(' '), contains('giấc trưa'));
    expect(invalid.validate().join(' '), contains('khoảng bận'));
  });

  test('versioned JSON round-trips and resolver selects weekend timing', () {
    final preferences = DailyRoutinePreferences.defaults();
    final decoded = DailyRoutinePreferences.fromJson(
      Map<String, Object?>.from(
        jsonDecode(jsonEncode(preferences.toJson())) as Map,
      ),
    );
    final timing = const ScheduleTimingResolver().resolve(
      decoded,
      DateTime(2026, 7, 18),
    );

    expect(timing.mealRange(1).start, '08:00');
    expect(timing.workoutRange(0).start, '09:00');
    expect(timing.napRange?.start, '13:15');
  });

  test('SQLite save uses stable row and creates outbox marker', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);
    await db.execute(UsersTable.createTable);
    await db.execute(SurveyAnswersTable.createTable);
    await SyncOutboxSchema.create(db);
    await db.insert('users', {
      'id': 'user-1',
      'created_at': '2026-07-15T00:00:00.000Z',
    });
    final datasource = DailyRoutinePreferencesLocalDatasource(
      databaseOverride: db,
      currentUserId: () => 'user-1',
      now: () => DateTime.utc(2026, 7, 15),
    );

    await datasource.saveForUser('user-1', DailyRoutinePreferences.defaults());
    await datasource.saveForUser('user-1', DailyRoutinePreferences.defaults());
    final loaded = await datasource.loadForUser('user-1');
    final rows = await db.query('survey_answers');
    final outbox = await db.query(
      SyncOutboxSchema.outboxTable,
      where: 'table_name = ?',
      whereArgs: ['survey_answers'],
    );

    expect(loaded, isNotNull);
    expect(rows, hasLength(1));
    expect(rows.single['question_code'], DailyRoutinePreferences.questionCode);
    expect(outbox, isNotEmpty);
  });
}
