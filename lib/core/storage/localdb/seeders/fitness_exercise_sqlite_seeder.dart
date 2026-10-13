import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

import '../models/ai_catalog_models.dart';
import '../tables/exercise_catalog_table.dart';

class FitnessExerciseSqliteSeeder {
  const FitnessExerciseSqliteSeeder._();

  static const assetPath =
      'assets/data/fitness_training/fitness_exercise_equipment_draft_v1.json';
  static const expectedExerciseCount = 24;
  static const pendingReviewStatus = 'draft_requires_clinical_and_qa_review';

  static Future<int> seed(DatabaseExecutor db, {AssetBundle? bundle}) async {
    final source = await (bundle ?? rootBundle).loadString(assetPath);
    final decoded = jsonDecode(source);
    if (decoded is! Map || decoded['exercises'] is! List) {
      throw const FormatException('M32 exercise source has no exercises list.');
    }
    final rows = (decoded['exercises'] as List)
        .whereType<Map>()
        .map((row) => Map<String, Object?>.from(row))
        .toList(growable: false);
    if (rows.length != expectedExerciseCount) {
      throw StateError(
        'Expected $expectedExerciseCount M32 exercises, got ${rows.length}.',
      );
    }

    final items = rows.map(_toCatalogItem).toList(growable: false);
    final codes = items.map((item) => item.code).toSet();
    if (codes.length != expectedExerciseCount ||
        items.any((item) => item.code.isEmpty || item.sourceHash.isEmpty)) {
      throw StateError('M32 exercise IDs or source hashes are invalid.');
    }

    final batch = db.batch();
    for (final item in items) {
      final values = item.toMap();
      batch.insert(
        ExerciseCatalogTable.tableName,
        values,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      batch.update(
        ExerciseCatalogTable.tableName,
        values,
        where: 'code = ? AND source_catalog = ?',
        whereArgs: [item.code, 'm32_fitness_training'],
      );
    }
    await batch.commit(noResult: true);

    final stored = await db.query(
      ExerciseCatalogTable.tableName,
      columns: const ['code', 'is_active', 'review_status', 'source_hash'],
      where: 'source_catalog = ?',
      whereArgs: const ['m32_fitness_training'],
    );
    if (stored.length != expectedExerciseCount ||
        stored.any(
          (row) =>
              _readInt(row['is_active']) != 0 ||
              row['review_status'] != pendingReviewStatus ||
              (row['source_hash']?.toString().trim().isEmpty ?? true),
        )) {
      throw StateError('M32 exercise SQLite verification failed.');
    }
    return stored.length;
  }

  static ExerciseCatalogItemModel _toCatalogItem(Map<String, Object?> row) {
    final bounds = row['program_bounds_candidate'];
    final programBounds = bounds is Map
        ? Map<String, Object?>.from(bounds)
        : const <String, Object?>{};
    final usesDuration = programBounds.containsKey('duration_minutes_min');
    final min = _readDouble(
      programBounds[usesDuration ? 'duration_minutes_min' : 'reps_min'],
      fallback: 1,
    );
    final max = _readDouble(
      programBounds[usesDuration ? 'duration_minutes_max' : 'reps_max'],
      fallback: min,
    );
    final rawIntensity = _readString(
      programBounds['intensity'] ?? row['level_candidate'],
    );
    final instructions = _readStringList(row['instruction_steps_vi']);
    final safetyNotes = _readString(row['safety_notes_vi']);
    final payload = jsonEncode(row);
    return ExerciseCatalogItemModel(
      code: _readString(row['id']),
      category: _readString(row['movement_type'] ?? row['venue']),
      title: _readString(row['name_vi']),
      description: instructions.join(' '),
      unit: usesDuration ? 'minutes' : 'repetitions',
      encouragement: safetyNotes,
      minTarget: min,
      maxTarget: max < min ? min : max,
      defaultTarget: min,
      intensityLevel: _normalizedIntensity(rawIntensity),
      equipment: _readStringList(row['gear_ids']),
      movementAreas: _readStringList(row['muscle_groups']),
      safetyStatus: pendingReviewStatus,
      safetySource: _readString(row['provenance']),
      sourceCatalog: 'm32_fitness_training',
      sourceProvenance: _readString(row['provenance']),
      sourceHash: sha256.convert(utf8.encode(payload)).toString(),
      reviewStatus: _readString(row['review_status']),
      sourcePayloadJson: payload,
      isActive: false,
      createdAt: '2026-10-13T00:00:00.000',
      updatedAt: '2026-10-13T00:00:00.000',
    );
  }

  static String _normalizedIntensity(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'light' || normalized == 'moderate') return normalized;
    return 'unreviewed';
  }

  static List<String> _readStringList(Object? value) => value is List
      ? value
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .toList(growable: false)
      : const [];

  static String _readString(Object? value) => value?.toString().trim() ?? '';

  static double _readDouble(Object? value, {required double fallback}) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static int _readInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
