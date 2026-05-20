import 'package:sqflite/sqflite.dart';

import '../models/notification_model.dart';

class NotificationsDao {
  final Database db;

  NotificationsDao(this.db);

  Future<void> insert(
    NotificationModel model,
  ) async {
    // TODO: Insert data
  }

  Future<List<NotificationModel>> getAll() async {
    return [];
  }

  Future<void> update(
    NotificationModel model,
  ) async {
    // TODO: Update data
  }

  Future<void> delete(
    String id,
  ) async {
    // TODO: Delete data
  }
}