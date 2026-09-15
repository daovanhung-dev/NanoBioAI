import 'package:sqflite/sqflite.dart';

import '../tables/sleep_safety_tables.dart';

class SleepSafetyDao {
  const SleepSafetyDao(this.db);

  final Database db;

  Future<Map<String, Object?>?> getPreference(String userId) async {
    final rows = await db.query(
      SleepSafetyTables.preferences,
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    return rows.isEmpty ? null : Map<String, Object?>.from(rows.first);
  }

  Future<void> upsertPreference(Map<String, Object?> values) => db.insert(
    SleepSafetyTables.preferences,
    values,
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  Future<void> insertSession(Map<String, Object?> values) => db.insert(
    SleepSafetyTables.sessions,
    values,
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  Future<Map<String, Object?>?> getSession(String id) async {
    final rows = await db.query(
      SleepSafetyTables.sessions,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Map<String, Object?>.from(rows.first);
  }

  Future<List<Map<String, Object?>>> listSessions(
    String userId, {
    int limit = 14,
  }) async {
    final rows = await db.query(
      SleepSafetyTables.sessions,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'started_at DESC',
      limit: limit,
    );
    return rows.map(Map<String, Object?>.from).toList(growable: false);
  }

  Future<void> updateSession(String id, Map<String, Object?> values) =>
      db.update(
        SleepSafetyTables.sessions,
        values,
        where: 'id = ?',
        whereArgs: [id],
      );

  Future<void> insertEvent(Map<String, Object?> values) => db.insert(
    SleepSafetyTables.events,
    values,
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  Future<Map<String, Object?>?> getEvent(String id) async {
    final rows = await db.query(
      SleepSafetyTables.events,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Map<String, Object?>.from(rows.first);
  }

  Future<void> updateEvent(String id, Map<String, Object?> values) => db.update(
    SleepSafetyTables.events,
    values,
    where: 'id = ?',
    whereArgs: [id],
  );

  Future<List<Map<String, Object?>>> listEvents(
    String userId, {
    int limit = 50,
  }) async {
    final rows = await db.query(
      SleepSafetyTables.events,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'detected_at DESC',
      limit: limit,
    );
    return rows.map(Map<String, Object?>.from).toList(growable: false);
  }

  Future<List<Map<String, Object?>>> listEventsForSession(
    String sessionId,
  ) async {
    final rows = await db.query(
      SleepSafetyTables.events,
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'detected_at ASC',
    );
    return rows.map(Map<String, Object?>.from).toList(growable: false);
  }

  Future<void> upsertNightAnalysis(Map<String, Object?> values) => db.insert(
    SleepSafetyTables.analyses,
    values,
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  Future<Map<String, Object?>?> getNightAnalysis(String sessionId) async {
    final rows = await db.query(
      SleepSafetyTables.analyses,
      where: 'session_id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );
    return rows.isEmpty ? null : Map<String, Object?>.from(rows.first);
  }

  Future<void> replaceContacts(
    String userId,
    List<Map<String, Object?>> contacts,
  ) async {
    await db.transaction((txn) async {
      await txn.delete(
        SleepSafetyTables.contacts,
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      for (final contact in contacts) {
        await txn.insert(SleepSafetyTables.contacts, contact);
      }
    });
  }

  Future<void> upsertContact(Map<String, Object?> values) async {
    await db.transaction((txn) async {
      await txn.delete(
        SleepSafetyTables.contacts,
        where: 'user_id = ? AND (id = ? OR priority = ?)',
        whereArgs: [values['user_id'], values['id'], values['priority']],
      );
      await txn.insert(
        SleepSafetyTables.contacts,
        values,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> deleteContact(String id) =>
      db.delete(SleepSafetyTables.contacts, where: 'id = ?', whereArgs: [id]);

  Future<List<Map<String, Object?>>> listContacts(String userId) async {
    final rows = await db.query(
      SleepSafetyTables.contacts,
      where: 'user_id = ? AND active = 1',
      whereArgs: [userId],
      orderBy: 'priority ASC',
    );
    return rows.map(Map<String, Object?>.from).toList(growable: false);
  }
}
