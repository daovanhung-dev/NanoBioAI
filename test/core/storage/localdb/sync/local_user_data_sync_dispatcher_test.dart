import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/storage/localdb/sync/local_user_data_sync_dispatcher.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  tearDown(() {
    LocalUserDataSyncDispatcher.register(({Database? database}) {});
  });

  test('forwards a committed local-write signal to the registered handler', () {
    var callCount = 0;

    LocalUserDataSyncDispatcher.register(({Database? database}) {
      callCount++;
    });

    LocalUserDataSyncDispatcher.requestImmediateSync();

    expect(callCount, 1);
  });
}
