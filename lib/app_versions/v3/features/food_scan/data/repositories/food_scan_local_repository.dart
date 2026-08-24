import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:nano_app/core/storage/localdb/sync/local_user_data_sync_dispatcher.dart';
import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:nano_app/core/storage/localdb/models/nutrition_log_model.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/entities/food_scan_models.dart';
import '../../domain/food_scan_exception.dart';

class FoodScanLocalRepository {
  final Database? databaseOverride;
  final DateTime Function() now;

  FoodScanLocalRepository({
    this.databaseOverride,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  Future<Database> _db() async => databaseOverride ?? DatabaseService.database;

  Future<void> saveAnalysis({
    required String userId,
    required FoodScanResult result,
  }) async {
    final db = await _db();
    try {
      await db.transaction((txn) async {
        await _upsertAnalysis(txn, userId: userId, result: result);
        await _replaceItems(txn, userId: userId, result: result);
      });
    } catch (error) {
      throw FoodScanException(
        code: 'LOCAL_SCAN_SAVE_FAILED',
        userMessage:
            'Nabi đã phân tích xong nhưng chưa lưu được lịch sử trên máy. Bạn kiểm tra dung lượng rồi thử lại nhé.',
        cause: error,
      );
    }
  }

  Future<FoodScanResult> confirmConsumed({
    required String userId,
    required FoodScanResult result,
  }) async {
    final db = await _db();
    try {
      final existing = await db.query(
        'food_scan_analyses',
        columns: const ['nutrition_log_id'],
        where: 'id = ? AND user_id = ?',
        whereArgs: [result.id, userId],
        limit: 1,
      );
      final existingLogId = existing.isEmpty
          ? null
          : _text(existing.first['nutrition_log_id']);
      if (existingLogId != null) {
        return result.copyWith(nutritionLogId: existingLogId);
      }

      final logId = _uuidV4();
      final updated = result.copyWith(nutritionLogId: logId);
      final foodName = updated.items
          .map((item) => item.name.trim())
          .where((name) => name.isNotEmpty)
          .take(8)
          .join(' + ');
      final nutrition = updated.totalNutrition;
      final log = NutritionLogModel(
        id: logId,
        userId: userId,
        foodName: foodName.isEmpty ? 'Món ăn từ Food Scan' : foodName,
        calories: nutrition.caloriesKcal.round(),
        protein: nutrition.proteinG,
        carbs: nutrition.carbohydratesG,
        fat: nutrition.fatG,
        mealType: null,
        eatenAt: now().toIso8601String(),
      );

      final committedLogId = await db.transaction<String>((txn) async {
        final current = await txn.query(
          'food_scan_analyses',
          columns: const ['nutrition_log_id'],
          where: 'id = ? AND user_id = ?',
          whereArgs: [result.id, userId],
          limit: 1,
        );
        final concurrentId = current.isEmpty
            ? null
            : _text(current.first['nutrition_log_id']);
        if (concurrentId != null) return concurrentId;

        await _upsertAnalysis(txn, userId: userId, result: updated);
        await _replaceItems(txn, userId: userId, result: updated);
        await txn.insert(
          'nutrition_logs',
          log.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        return logId;
      });

      // nutrition_logs participates in SyncOutboxSchema triggers, so the
      // committed insert is already durably queued for cloud sync. Only signal
      // the registered application-level dispatcher to drain it immediately.
      LocalUserDataSyncDispatcher.requestImmediateSync(database: db);
      return result.copyWith(nutritionLogId: committedLogId);
    } catch (error) {
      if (error is FoodScanException) rethrow;
      throw FoodScanException(
        code: 'NUTRITION_LOG_SAVE_FAILED',
        userMessage:
            'Nabi chưa thể ghi bữa ăn vào nhật ký. Kết quả scan vẫn được giữ trên thiết bị để bạn thử lưu lại.',
        cause: error,
      );
    }
  }

  Future<List<FoodScanResult>> history(String userId, {int limit = 100}) async {
    final db = await _db();
    final rows = await db.query(
      'food_scan_analyses',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    final result = <FoodScanResult>[];
    for (final row in rows) {
      final payload = _text(row['result_json']);
      if (payload == null) continue;
      try {
        var item = FoodScanResult.decode(payload);
        final logId = _text(row['nutrition_log_id']);
        if (logId != null) item = item.copyWith(nutritionLogId: logId);
        result.add(item);
      } catch (_) {
        // Ignore one damaged local history row instead of breaking the list.
      }
    }
    return result;
  }

  Future<FoodScanResult?> getById({
    required String userId,
    required String scanId,
  }) async {
    final db = await _db();
    final rows = await db.query(
      'food_scan_analyses',
      where: 'id = ? AND user_id = ?',
      whereArgs: [scanId, userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final payload = _text(rows.first['result_json']);
    if (payload == null) return null;
    try {
      var result = FoodScanResult.decode(payload);
      final logId = _text(rows.first['nutrition_log_id']);
      if (logId != null) result = result.copyWith(nutritionLogId: logId);
      return result;
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteHistory({
    required String userId,
    required FoodScanResult result,
  }) async {
    final db = await _db();
    await db.delete(
      'food_scan_analyses',
      where: 'id = ? AND user_id = ?',
      whereArgs: [result.id, userId],
    );
    final imagePath = result.imageLocalPath.trim();
    if (imagePath.isNotEmpty) {
      try {
        final file = File(imagePath);
        if (await file.exists()) await file.delete();
      } catch (_) {
        // History ownership is already removed. A stale image can be cleaned by
        // a future storage-maintenance pass without exposing it to another user.
      }
    }
  }

  Future<void> _upsertAnalysis(
    DatabaseExecutor db, {
    required String userId,
    required FoodScanResult result,
  }) async {
    final timestamp = now().toUtc().toIso8601String();
    await db.insert(
      'food_scan_analyses',
      {
        'id': result.id,
        'user_id': userId,
        'image_local_path': result.imageLocalPath,
        'input_type': result.inputType,
        'analysis_confidence': result.analysisConfidence,
        'total_calories': result.displayedCalories,
        'health_status': result.healthEvaluation.status,
        'health_score': result.healthEvaluation.suitabilityScore,
        'result_json': result.encode(),
        'nutrition_log_id': result.nutritionLogId,
        'created_at': result.createdAt.toUtc().toIso8601String(),
        'updated_at': timestamp,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _replaceItems(
    DatabaseExecutor db, {
    required String userId,
    required FoodScanResult result,
  }) async {
    await db.delete(
      'food_scan_items',
      where: 'scan_id = ? AND user_id = ?',
      whereArgs: [result.id, userId],
    );
    final timestamp = now().toUtc().toIso8601String();
    for (var index = 0; index < result.items.length; index++) {
      final item = result.items[index];
      await db.insert('food_scan_items', {
        'id': item.id,
        'scan_id': result.id,
        'user_id': userId,
        'food_name': item.name,
        'estimated_weight_g': item.estimatedWeightGrams,
        'confirmed_weight_g': item.confirmedWeightGrams,
        'portion_description': item.portionDescription,
        'cooking_method': item.cookingMethod,
        'ingredients_json': jsonEncode(item.ingredients),
        'possible_allergens_json': jsonEncode(item.possibleAllergens),
        'nutrition_source': item.nutritionSource,
        'nutrition_json': jsonEncode(item.nutrition.toJson()),
        'confidence': item.confidence,
        'sort_order': index,
        'created_at': timestamp,
        'updated_at': timestamp,
      });
    }
  }
}

String? _text(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

String _uuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String hex(int value) => value.toRadixString(16).padLeft(2, '0');
  final all = bytes.map(hex).join();
  return '${all.substring(0, 8)}-'
      '${all.substring(8, 12)}-'
      '${all.substring(12, 16)}-'
      '${all.substring(16, 20)}-'
      '${all.substring(20)}';
}
