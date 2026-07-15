import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/data/datasources/schedule_horizon_local_datasource.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/entities/schedule_horizon.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Database db;
  late ScheduleHorizonLocalDatasource datasource;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute('CREATE TABLE meal_plans (user_id TEXT, plan_date TEXT)');
    await db.execute(
      'CREATE TABLE lifestyle_schedule_items (user_id TEXT, schedule_date TEXT)',
    );
    datasource = ScheduleHorizonLocalDatasource(databaseOverride: db);
  });

  tearDown(() => db.close());

  test('no plan starts today with zero remaining days', () async {
    final horizon = await datasource.read(
      userId: 'u1',
      today: DateTime(2026, 12, 31),
    );
    expect(horizon.remainingDays, 0);
    expect(horizon.nextStartDate, DateTime(2026, 12, 31));
  });

  test('uses the later date from both schedule tables', () async {
    await db.insert('meal_plans', {'user_id': 'u1', 'plan_date': '2026-12-31'});
    await db.insert('lifestyle_schedule_items', {
      'user_id': 'u1',
      'schedule_date': '2027-01-02',
    });
    final horizon = await datasource.read(
      userId: 'u1',
      today: DateTime(2026, 12, 31),
    );
    expect(horizon.lastScheduledDate, DateTime(2027, 1, 2));
    expect(horizon.remainingDays, 3);
    expect(horizon.nextStartDate, DateTime(2027, 1, 3));
  });

  test('today is one remaining business day and allows generation', () async {
    await db.insert('meal_plans', {'user_id': 'u1', 'plan_date': '2028-02-29'});
    final horizon = await datasource.read(
      userId: 'u1',
      today: DateTime(2028, 2, 29),
    );
    expect(horizon.remainingDays, 1);
    expect(horizon.canGenerate, isTrue);
    expect(horizon.nextStartDate, DateTime(2028, 3, 1));
  });

  test('malformed date fails closed even when another date is valid', () async {
    await db.insert('meal_plans', {'user_id': 'u1', 'plan_date': '2026-07-20'});
    await db.insert('lifestyle_schedule_items', {
      'user_id': 'u1',
      'schedule_date': '20/07/2026',
    });
    await expectLater(
      datasource.read(userId: 'u1', today: DateTime(2026, 7, 15)),
      throwsA(isA<ScheduleHorizonDataException>()),
    );
  });
}
