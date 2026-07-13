import 'package:sqflite/sqflite.dart';

class WellnessPointLedgersDao {
  final Database db;

  const WellnessPointLedgersDao(this.db);

  Future<int> netPointsForSource({
    required String userId,
    required String sourceType,
    required String sourceId,
    required String programCode,
  }) async {
    final rows = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(points_delta), 0) AS balance
      FROM wellness_point_ledgers
      WHERE user_id = ?
        AND source_type = ?
        AND source_id = ?
        AND program_code = ?
      ''',
      [userId, sourceType, sourceId, programCode],
    );
    if (rows.isEmpty) return 0;
    final value = rows.first['balance'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<int> balanceForUser({
    required String userId,
    required String programCode,
  }) async {
    final rows = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(points_delta), 0) AS balance
      FROM wellness_point_ledgers
      WHERE user_id = ?
        AND program_code = ?
      ''',
      [userId, programCode],
    );
    if (rows.isEmpty) return 0;
    final value = rows.first['balance'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
