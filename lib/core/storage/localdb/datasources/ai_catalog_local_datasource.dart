import 'package:sqflite/sqflite.dart';

import '../daos/ai_catalog_dao.dart';
import '../database_service.dart';
import '../models/ai_catalog_models.dart';

class AiCatalogLocalDatasource {
  final Database? databaseOverride;

  const AiCatalogLocalDatasource({this.databaseOverride});

  Future<Database> _db() async => databaseOverride ?? DatabaseService.database;

  Future<AiCatalogBundle> loadActiveBundle() async {
    final db = await _db();
    return AiCatalogDao(db).loadActiveBundle();
  }
}
