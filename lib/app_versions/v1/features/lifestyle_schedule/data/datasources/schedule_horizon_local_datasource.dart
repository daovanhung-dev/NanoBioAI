import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/entities/schedule_horizon.dart';
import '../../domain/repositories/schedule_horizon_reader.dart';

class ScheduleHorizonLocalDatasource implements ScheduleHorizonReader {
  final Database? databaseOverride;

  const ScheduleHorizonLocalDatasource({this.databaseOverride});

  Future<Database> _db() async => databaseOverride ?? DatabaseService.database;

  @override
  Future<ScheduleHorizon> read({
    required String userId,
    required DateTime today,
  }) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      throw const ScheduleHorizonDataException();
    }

    final db = await _db();
    final rows = await db.rawQuery(
      '''
      SELECT plan_date AS schedule_date
      FROM meal_plans
      WHERE user_id = ? AND plan_date IS NOT NULL
      UNION ALL
      SELECT schedule_date
      FROM lifestyle_schedule_items
      WHERE user_id = ? AND schedule_date IS NOT NULL
      ''',
      [normalizedUserId, normalizedUserId],
    );

    DateTime? lastDate;
    for (final row in rows) {
      final raw = row['schedule_date']?.toString();
      if (raw == null || raw.trim().isEmpty) {
        throw const ScheduleHorizonDataException();
      }
      final parsed = _parseDate(raw);
      if (parsed == null) throw const ScheduleHorizonDataException();
      if (lastDate == null || parsed.isAfter(lastDate)) lastDate = parsed;
    }

    final currentDate = _dateOnly(today);
    final remainingDays = lastDate == null || lastDate.isBefore(currentDate)
        ? 0
        : lastDate.difference(currentDate).inDays + 1;
    final dayAfterLast = lastDate?.add(const Duration(days: 1));
    final nextStartDate =
        dayAfterLast == null || dayAfterLast.isBefore(currentDate)
        ? currentDate
        : dayAfterLast;

    return ScheduleHorizon(
      lastScheduledDate: lastDate,
      remainingDays: remainingDays,
      nextStartDate: nextStartDate,
    );
  }

  DateTime? _parseDate(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value.trim());
    if (match == null) return null;
    final year = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final day = int.tryParse(match.group(3)!);
    if (year == null || month == null || day == null) return null;
    final parsed = DateTime(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return null;
    }
    return parsed;
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
