import 'package:sqflite/sqflite.dart';

import '../models/notification_model.dart';
import '../tables/notifications_table.dart';

class NotificationsDao {
  final Database db;

  NotificationsDao(this.db);

  Future<void> insert(
    NotificationModel model,
  ) async {
    await db.insert(
      NotificationsTable.tableName,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertMany(List<NotificationModel> models) async {
    final batch = db.batch();

    for (final model in models) {
      batch.insert(
        NotificationsTable.tableName,
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List<NotificationModel>> getAll() async {
    final maps = await db.query(
      NotificationsTable.tableName,
      orderBy: 'scheduled_at ASC, created_at ASC',
    );

    return maps.map(NotificationModel.fromMap).toList();
  }

  Future<NotificationModel?> getByNotificationId(int notificationId) async {
    final maps = await db.query(
      NotificationsTable.tableName,
      where: 'notification_id = ?',
      whereArgs: [notificationId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return NotificationModel.fromMap(maps.first);
  }

  Future<List<NotificationModel>> getPendingBySources({
    required String sourceType,
    required List<String> sourceIds,
  }) async {
    if (sourceIds.isEmpty) return [];

    final placeholders = List.filled(sourceIds.length, '?').join(', ');
    final maps = await db.query(
      NotificationsTable.tableName,
      where:
          'source_type = ? AND action_status = ? '
          'AND source_id IN ($placeholders)',
      whereArgs: [
        sourceType,
        NotificationActionStatuses.pending,
        ...sourceIds,
      ],
    );

    return maps.map(NotificationModel.fromMap).toList();
  }

  Future<void> deletePendingBySources({
    required String sourceType,
    required List<String> sourceIds,
  }) async {
    if (sourceIds.isEmpty) return;

    final placeholders = List.filled(sourceIds.length, '?').join(', ');
    await db.delete(
      NotificationsTable.tableName,
      where:
          'source_type = ? AND action_status = ? '
          'AND source_id IN ($placeholders)',
      whereArgs: [
        sourceType,
        NotificationActionStatuses.pending,
        ...sourceIds,
      ],
    );
  }

  Future<void> update(
    NotificationModel model,
  ) async {
    await db.update(
      NotificationsTable.tableName,
      model.toMap(),
      where: 'id = ?',
      whereArgs: [model.id],
    );
  }

  Future<void> updateActionStatus({
    required String id,
    required String actionStatus,
    required String updatedAt,
    String? respondedAt,
    bool isRead = true,
  }) async {
    await db.update(
      NotificationsTable.tableName,
      {
        'action_status': actionStatus,
        'responded_at': respondedAt,
        'updated_at': updatedAt,
        'is_read': isRead ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(
    String id,
  ) async {
    await db.delete(
      NotificationsTable.tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
