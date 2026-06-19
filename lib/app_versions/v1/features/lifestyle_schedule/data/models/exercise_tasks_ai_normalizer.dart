import 'package:nano_app/core/storage/localdb/models/ai_catalog_models.dart';
import 'package:nano_app/app_versions/v1/features/daily_health_tracking/domain/entities/daily_health_profile_entity.dart';

import 'exercise_task_model.dart';

class ExerciseTasksAiNormalizer {
  static const exercisesPerDay = 2;
  static const forbiddenAiTextFields = {
    'meal_name',
    'description',
    'cooking_instructions',
    'title',
    'unit',
    'encouragement',
  };

  static const exerciseSlots = [
    ExerciseTaskSlot(order: 1, startTime: '08:00', endTime: '08:25'),
    ExerciseTaskSlot(order: 2, startTime: '17:30', endTime: '18:00'),
  ];

  const ExerciseTasksAiNormalizer();

  List<ExerciseTaskModel> normalize({
    required List<dynamic> items,
    required AiCatalogBundle catalog,
    required DailyHealthProfileEntity profile,
    required DateTime startDate,
    int days = 7,
    required String createdAt,
  }) {
    final validItems = validateCodeItems(
      items: items,
      catalog: catalog,
      startDay: 1,
      days: days,
      usedCodeCounts: const {},
    );
    final grouped = <int, List<Map<String, dynamic>>>{};
    for (final item in validItems) {
      grouped.putIfAbsent(item['day'] as int, () => []).add(item);
    }

    final catalogByCode = catalog.exercisesByCode;
    final result = <ExerciseTaskModel>[];
    for (var day = 1; day <= days; day++) {
      final date = _dateKey(startDate.add(Duration(days: day - 1)));
      final dayItems = grouped[day];
      if (dayItems == null || dayItems.length != exercisesPerDay) {
        throw FormatException(
          'Expected $exercisesPerDay exercises for day $day',
        );
      }

      dayItems.sort(
        (a, b) =>
            (a['start_time'] as String).compareTo(b['start_time'] as String),
      );
      for (var index = 0; index < dayItems.length; index++) {
        final map = dayItems[index];
        final catalogItem = catalogByCode[map['exercise_code']];
        if (catalogItem == null) {
          throw FormatException(
            'Unknown exercise_code: ${map['exercise_code']}',
          );
        }

        result.add(
          ExerciseTaskModel(
            id: 'exercise_${profile.userId}_${date}_${index + 1}',
            userId: profile.userId,
            scheduleDate: date,
            startTime: map['start_time'] as String,
            endTime: map['end_time'] as String,
            title: catalogItem.title,
            description: catalogItem.description,
            targetValue: _clampTarget(map['target_value'], catalogItem),
            unit: catalogItem.unit,
            encouragement: catalogItem.encouragement,
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
        );
      }
    }

    return result;
  }

  List<Map<String, dynamic>> validateCodeItems({
    required List<dynamic> items,
    required AiCatalogBundle catalog,
    required int startDay,
    required int days,
    required Map<String, int> usedCodeCounts,
  }) {
    final expectedCount = days * exercisesPerDay;
    if (items.length != expectedCount) {
      throw FormatException(
        'Exercise AI response must contain exactly $expectedCount tasks',
      );
    }

    final catalogByCode = catalog.exercisesByCode;
    final counts = Map<String, int>.from(usedCodeCounts);
    final grouped = <int, List<Map<String, dynamic>>>{};

    for (final item in items) {
      if (item is! Map) {
        throw const FormatException('Exercise AI task must be an object');
      }

      final map = Map<String, dynamic>.from(item);
      _rejectForbiddenTextFields(map, label: 'Exercise AI item');

      final day = _readInt(map['day']);
      final endDay = startDay + days - 1;
      if (day < startDay || day > endDay) {
        throw FormatException(
          'Exercise AI day must be between $startDay and $endDay',
        );
      }

      final exerciseCode = _readString(map['exercise_code']).toLowerCase();
      final catalogItem = catalogByCode[exerciseCode];
      if (catalogItem == null) {
        throw FormatException('Unknown exercise_code: $exerciseCode');
      }

      final startTime = _readTime(map['start_time']);
      final endTime = _readTime(map['end_time']);
      if (endTime.compareTo(startTime) <= 0) {
        throw FormatException('Exercise end_time must be after start_time');
      }

      final dayItems = grouped.putIfAbsent(day, () => []);
      if (dayItems.any((entry) => entry['exercise_code'] == exerciseCode)) {
        throw FormatException(
          'Duplicate exercise_code for day $day: $exerciseCode',
        );
      }

      final nextCount = (counts[exerciseCode] ?? 0) + 1;
      if (nextCount > 2 && _hasLessUsedAlternative(catalog, counts)) {
        throw FormatException(
          'Exercise code repeated too often: $exerciseCode',
        );
      }
      counts[exerciseCode] = nextCount;

      dayItems.add({
        'day': day,
        'exercise_code': exerciseCode,
        'start_time': startTime,
        'end_time': endTime,
        'intensity': _normalizeIntensity(map['intensity']),
        'target_value': _clampTarget(map['target_value'], catalogItem),
        'priority': _readOptionalInt(map['priority']) ?? dayItems.length + 1,
      });
    }

    final result = <Map<String, dynamic>>[];
    for (var day = startDay; day < startDay + days; day++) {
      final dayItems = grouped[day];
      if (dayItems == null || dayItems.length != exercisesPerDay) {
        throw FormatException(
          'Expected $exercisesPerDay exercises for day $day',
        );
      }
      dayItems.sort(
        (a, b) =>
            (a['start_time'] as String).compareTo(b['start_time'] as String),
      );
      result.addAll(dayItems);
    }

    return result;
  }

  List<Map<String, dynamic>> fallbackCodeItems({
    required AiCatalogBundle catalog,
    required int startDay,
    required int days,
    required Map<String, int> usedCodeCounts,
  }) {
    final counts = Map<String, int>.from(usedCodeCounts);
    final result = <Map<String, dynamic>>[];

    for (var day = startDay; day < startDay + days; day++) {
      final dayCodes = <String>{};
      for (final slot in exerciseSlots) {
        final item = _pickExercise(catalog, counts, dayCodes);
        counts[item.code] = (counts[item.code] ?? 0) + 1;
        dayCodes.add(item.code);
        result.add({
          'day': day,
          'exercise_code': item.code,
          'start_time': slot.startTime,
          'end_time': slot.endTime,
          'intensity': item.intensityLevel,
          'target_value': item.defaultTarget,
          'priority': slot.order,
        });
      }
    }

    return result;
  }

  static ExerciseCatalogItemModel _pickExercise(
    AiCatalogBundle catalog,
    Map<String, int> usedCodeCounts,
    Set<String> dayCodes,
  ) {
    if (catalog.exercises.isEmpty) {
      throw const FormatException('Exercise catalog is empty');
    }

    final sorted = [...catalog.exercises]
      ..sort((a, b) {
        final countCompare = (usedCodeCounts[a.code] ?? 0).compareTo(
          usedCodeCounts[b.code] ?? 0,
        );
        if (countCompare != 0) return countCompare;
        return a.code.compareTo(b.code);
      });

    return sorted.firstWhere(
      (item) => !dayCodes.contains(item.code),
      orElse: () => sorted.first,
    );
  }

  static void _rejectForbiddenTextFields(
    Map<String, dynamic> map, {
    required String label,
  }) {
    for (final field in forbiddenAiTextFields) {
      if (map.containsKey(field)) {
        throw FormatException('$label must not contain "$field"');
      }
    }
  }

  static bool _hasLessUsedAlternative(
    AiCatalogBundle catalog,
    Map<String, int> counts,
  ) {
    return catalog.exercises.any((item) => (counts[item.code] ?? 0) < 2);
  }

  static String _readString(Object? value) {
    return value?.toString().trim() ?? '';
  }

  static int _readInt(Object? value) {
    final parsed = _readOptionalInt(value);
    if (parsed == null) {
      throw FormatException('Expected integer value, got $value');
    }
    return parsed;
  }

  static int? _readOptionalInt(Object? value) {
    return switch (value) {
      final int n => n,
      final num n => n.toInt(),
      final String s => int.tryParse(s.trim()),
      _ => null,
    };
  }

  static String _readTime(Object? value) {
    final text = _readString(value);
    if (!RegExp(r'^\d{2}:\d{2}$').hasMatch(text)) {
      throw FormatException('Invalid exercise time: $text');
    }
    final hour = int.parse(text.substring(0, 2));
    final minute = int.parse(text.substring(3, 5));
    if (hour > 23 || minute > 59) {
      throw FormatException('Invalid exercise time: $text');
    }
    return text;
  }

  static double _clampTarget(
    Object? value,
    ExerciseCatalogItemModel catalogItem,
  ) {
    final parsed = switch (value) {
      final num n => n.toDouble(),
      final String s => double.tryParse(s.trim()),
      _ => null,
    };
    final target = parsed ?? catalogItem.defaultTarget;
    return target
        .clamp(catalogItem.minTarget, catalogItem.maxTarget)
        .toDouble();
  }

  static String _normalizeIntensity(Object? value) {
    final text = _readString(value).toLowerCase();
    return switch (text) {
      'moderate' || 'medium' || 'vừa' => 'moderate',
      _ => 'light',
    };
  }

  static String _dateKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}

class ExerciseTaskSlot {
  final int order;
  final String startTime;
  final String endTime;

  const ExerciseTaskSlot({
    required this.order,
    required this.startTime,
    required this.endTime,
  });
}
