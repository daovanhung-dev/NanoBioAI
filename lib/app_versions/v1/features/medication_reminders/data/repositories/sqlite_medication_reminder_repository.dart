import 'dart:convert';
import 'dart:math';

import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:nano_app/core/storage/localdb/tables/medication_reminders_table.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/entities/medication_reminder.dart';
import '../../domain/repositories/medication_reminder_repository.dart';

class SqliteMedicationReminderRepository
    implements MedicationReminderRepository {
  final Database? databaseOverride;
  final DateTime Function() now;

  const SqliteMedicationReminderRepository({
    this.databaseOverride,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  Future<Database> get _database async =>
      databaseOverride ?? await DatabaseService.database;

  @override
  Future<List<MedicationReminder>> listForUser(String userId) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return const [];
    final rows = await (await _database).query(
      MedicationRemindersTable.tableName,
      where: 'user_id = ?',
      whereArgs: [normalizedUserId],
      orderBy: 'created_at ASC, id ASC',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<void> create({
    required String userId,
    required String medicineName,
    required List<int> minutes,
  }) async {
    final normalizedUserId = userId.trim();
    final normalizedName = medicineName.trim();
    final safeMinutes = _normalizeMinutes(minutes);
    if (normalizedUserId.isEmpty) {
      throw const FormatException('A local reminder owner is required');
    }
    if (normalizedName.isEmpty) {
      throw const FormatException('A medicine name is required');
    }
    if (safeMinutes.isEmpty) {
      throw const FormatException('At least one reminder time is required');
    }

    final db = await _database;
    final timestamp = now().toUtc().toIso8601String();
    await db.insert(MedicationRemindersTable.tableName, {
      'id': newLocalId(now()),
      'user_id': normalizedUserId,
      'medicine_name': normalizedName,
      'times_json': jsonEncode(safeMinutes),
      'enabled': 1,
      'created_at': timestamp,
      'updated_at': timestamp,
    });
  }

  @override
  Future<void> updateMedicineName({
    required String userId,
    required String reminderId,
    required String medicineName,
  }) async {
    final normalizedName = medicineName.trim();
    if (normalizedName.isEmpty) {
      throw const FormatException('A medicine name is required');
    }
    await (await _database).update(
      MedicationRemindersTable.tableName,
      {
        'medicine_name': normalizedName,
        'updated_at': now().toUtc().toIso8601String(),
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [reminderId, userId.trim()],
    );
  }

  @override
  Future<void> updateTimes({
    required String userId,
    required String reminderId,
    required List<int> minutes,
  }) async {
    final safeMinutes = _normalizeMinutes(minutes);
    if (safeMinutes.isEmpty) {
      throw const FormatException('At least one reminder time is required');
    }
    await (await _database).update(
      MedicationRemindersTable.tableName,
      {
        'times_json': jsonEncode(safeMinutes),
        'updated_at': now().toUtc().toIso8601String(),
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [reminderId, userId.trim()],
    );
  }

  @override
  Future<void> setEnabled({
    required String userId,
    required String reminderId,
    required bool enabled,
  }) async {
    await (await _database).update(
      MedicationRemindersTable.tableName,
      {
        'enabled': enabled ? 1 : 0,
        'updated_at': now().toUtc().toIso8601String(),
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [reminderId, userId.trim()],
    );
  }

  @override
  Future<void> delete({
    required String userId,
    required String reminderId,
  }) async {
    await (await _database).delete(
      MedicationRemindersTable.tableName,
      where: 'id = ? AND user_id = ?',
      whereArgs: [reminderId, userId.trim()],
    );
  }

  MedicationReminder _fromRow(Map<String, Object?> row) {
    final rawTimes = jsonDecode(row['times_json']?.toString() ?? '[]');
    final times = rawTimes is List
        ? _normalizeMinutes(
            rawTimes.whereType<num>().map((value) => value.toInt()),
          )
        : const <int>[];
    return MedicationReminder(
      id: row['id']?.toString() ?? '',
      userId: row['user_id']?.toString() ?? '',
      medicineName: row['medicine_name']?.toString() ?? '',
      reminderMinutes: times,
      enabled: _asBool(row['enabled']),
      createdAt: _asDate(row['created_at']),
      updatedAt: _asDate(row['updated_at']),
    );
  }

  static List<int> normalizeMinutes(Iterable<int> minutes) =>
      _normalizeMinutes(minutes);

  static List<int> _normalizeMinutes(Iterable<int> minutes) =>
      minutes.where((minute) => minute >= 0 && minute < 1440).toSet().toList()
        ..sort();

  bool _asBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    return value?.toString() == '1' || value?.toString() == 'true';
  }

  DateTime _asDate(Object? value) =>
      DateTime.tryParse(value?.toString() ?? '')?.toLocal() ?? now();

  static String newLocalId([DateTime? at]) {
    final micros = (at ?? DateTime.now()).microsecondsSinceEpoch;
    return 'med_${micros}_${Random.secure().nextInt(1 << 32)}';
  }
}
