import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v2/features/payments/data/datasources/membership_payment_payer_profile_local_datasource.dart';
import 'package:nano_app/core/storage/localdb/tables/users_table.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database database;
  late SqliteMembershipPaymentPayerProfileLocalDatasource datasource;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await database.execute(UsersTable.createTable);
    await database.insert('users', {
      'id': 'different-local-user',
      'full_name': 'Tên không được dùng',
    });
    await database.insert('users', {
      'id': 'supabase-user-1',
      'full_name': '  Nguyễn Thanh An  ',
    });
    datasource = SqliteMembershipPaymentPayerProfileLocalDatasource(
      databaseOverride: database,
    );
  });

  tearDown(() async => database.close());

  test(
    'reads users.full_name only for the authenticated Supabase user id',
    () async {
      expect(
        await datasource.readFullName('supabase-user-1'),
        'Nguyễn Thanh An',
      );
    },
  );

  test('returns null for a blank or unknown user id', () async {
    expect(await datasource.readFullName('  '), isNull);
    expect(await datasource.readFullName('missing-user'), isNull);
  });
}
