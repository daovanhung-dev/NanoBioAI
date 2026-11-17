import 'package:sqflite/sqflite.dart';

import '../tables/nabi_esp_credential_table.dart';

class MigrationV37 {
  const MigrationV37._();

  static Future<void> run(DatabaseExecutor db) async {
    await db.execute(NabiEspCredentialTable.createTable);
  }
}
