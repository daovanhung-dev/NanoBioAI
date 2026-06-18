import 'package:nano_app/core/storage/localdb/models/ai_catalog_models.dart';

import 'meal_plan_model.dart';

class MealPlanAiNormalizer {
  static const mealsPerDay = 5;
  static const forbiddenAiTextFields = {
    'meal_name',
    'description',
    'cooking_instructions',
    'title',
    'unit',
    'encouragement',
  };

  static const mealSlots = [
    MealPlanSlot(
      type: 'breakfast',
      order: 1,
      startTime: '07:00',
      endTime: '07:30',
    ),
    MealPlanSlot(
      type: 'morning_snack',
      order: 2,
      startTime: '09:30',
      endTime: '09:45',
    ),
    MealPlanSlot(type: 'lunch', order: 3, startTime: '12:00', endTime: '12:45'),
    MealPlanSlot(
      type: 'afternoon_snack',
      order: 4,
      startTime: '15:30',
      endTime: '15:45',
    ),
    MealPlanSlot(
      type: 'dinner',
      order: 5,
      startTime: '18:30',
      endTime: '19:15',
    ),
  ];

  const MealPlanAiNormalizer();

  List<MealPlanModel> normalize({
    required List<dynamic> items,
    required AiCatalogBundle catalog,
    required String userId,
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
    final byDayAndType = <int, Map<String, Map<String, dynamic>>>{};

    for (final item in validItems) {
      final day = item['day'] as int;
      final mealType = item['meal_type'] as String;
      byDayAndType.putIfAbsent(day, () => {})[mealType] = item;
    }

    final result = <MealPlanModel>[];
    final catalogByCode = catalog.mealsByCode;
    for (var day = 1; day <= days; day++) {
      final date = _dateKey(startDate.add(Duration(days: day - 1)));
      final dayItems = byDayAndType[day];
      if (dayItems == null) {
        throw FormatException('Missing meal day $day');
      }

      for (final slot in mealSlots) {
        final map = dayItems[slot.type];
        if (map == null) {
          throw FormatException('Expected meal_type ${slot.type} for $date');
        }

        final catalogItem = catalogByCode[map['meal_code']];
        if (catalogItem == null) {
          throw FormatException('Unknown meal_code: ${map['meal_code']}');
        }

        final portionFactor = _portionFactor(map['portion_level']);
        result.add(
          MealPlanModel(
            id: 'meal_${userId}_${date}_${slot.order}',
            userId: userId,
            planDate: date,
            mealType: slot.type,
            mealName: catalogItem.mealName,
            description: catalogItem.description,
            calories: (catalogItem.calories * portionFactor).round(),
            protein: _scaled(catalogItem.protein, portionFactor),
            carbs: _scaled(catalogItem.carbs, portionFactor),
            fat: _scaled(catalogItem.fat, portionFactor),
            fiber: _scaled(catalogItem.fiber, portionFactor),
            waterMl: catalogItem.waterMl,
            mealOrder: slot.order,
            startTime: slot.startTime,
            endTime: slot.endTime,
            cookingInstructions: catalogItem.cookingInstructions,
            isCompleted: false,
            aiGenerated: true,
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
    final expectedCount = days * mealsPerDay;
    if (items.length != expectedCount) {
      throw FormatException(
        'Meal AI response must contain exactly $expectedCount meals',
      );
    }

    final catalogByCode = catalog.mealsByCode;
    final counts = Map<String, int>.from(usedCodeCounts);
    final byDayAndType = <int, Map<String, Map<String, dynamic>>>{};

    for (final item in items) {
      if (item is! Map) {
        throw const FormatException('Meal AI item must be an object');
      }

      final map = Map<String, dynamic>.from(item);
      _rejectForbiddenTextFields(map, label: 'Meal AI item');

      final day = _readInt(map['day']);
      final endDay = startDay + days - 1;
      if (day < startDay || day > endDay) {
        throw FormatException(
          'Meal AI day must be between $startDay and $endDay',
        );
      }

      final mealType = _readString(map['meal_type']).toLowerCase();
      final slot = _slotForType(mealType);
      if (slot == null) {
        throw FormatException('Unsupported meal_type: $mealType');
      }

      final mealCode = _readString(map['meal_code']).toLowerCase();
      final catalogItem = catalogByCode[mealCode];
      if (catalogItem == null) {
        throw FormatException('Unknown meal_code: $mealCode');
      }
      if (catalogItem.mealType != mealType) {
        throw FormatException('meal_code $mealCode is not valid for $mealType');
      }

      final dayItems = byDayAndType.putIfAbsent(day, () => {});
      if (dayItems.containsKey(mealType)) {
        throw FormatException('Duplicate meal_type for day $day: $mealType');
      }
      if (dayItems.values.any((entry) => entry['meal_code'] == mealCode)) {
        throw FormatException('Duplicate meal_code for day $day: $mealCode');
      }

      final nextCount = (counts[mealCode] ?? 0) + 1;
      if (nextCount > 2 && _hasLessUsedAlternative(catalog, mealType, counts)) {
        throw FormatException('Meal code repeated too often: $mealCode');
      }
      counts[mealCode] = nextCount;

      dayItems[mealType] = {
        'day': day,
        'meal_type': mealType,
        'meal_code': mealCode,
        'portion_level': _normalizePortionLevel(map['portion_level']),
        'priority': _readOptionalInt(map['priority']) ?? slot.order,
      };
    }

    final result = <Map<String, dynamic>>[];
    for (var day = startDay; day < startDay + days; day++) {
      final dayItems = byDayAndType[day];
      if (dayItems == null) {
        throw FormatException('Missing meal day $day');
      }
      for (final slot in mealSlots) {
        final item = dayItems[slot.type];
        if (item == null) {
          throw FormatException('Expected meal_type ${slot.type} for day $day');
        }
        result.add(item);
      }
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
      for (final slot in mealSlots) {
        final item = _pickMeal(catalog, slot.type, counts, dayCodes);
        counts[item.code] = (counts[item.code] ?? 0) + 1;
        dayCodes.add(item.code);
        result.add({
          'day': day,
          'meal_type': slot.type,
          'meal_code': item.code,
          'portion_level': 'standard',
          'priority': slot.order,
        });
      }
    }

    return result;
  }

  static MealCatalogItemModel _pickMeal(
    AiCatalogBundle catalog,
    String mealType,
    Map<String, int> usedCodeCounts,
    Set<String> dayCodes,
  ) {
    final candidates = catalog.mealsForType(mealType);
    if (candidates.isEmpty) {
      throw FormatException('Meal catalog has no items for $mealType');
    }

    final sorted = [...candidates]
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
    String mealType,
    Map<String, int> counts,
  ) {
    return catalog
        .mealsForType(mealType)
        .any((item) => (counts[item.code] ?? 0) < 2);
  }

  static MealPlanSlot? _slotForType(String mealType) {
    for (final slot in mealSlots) {
      if (slot.type == mealType) return slot;
    }
    return null;
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

  static String _normalizePortionLevel(Object? value) {
    final text = _readString(value).toLowerCase();
    return switch (text) {
      'small' || 'low' || 'light' => 'small',
      'large' || 'high' => 'large',
      _ => 'standard',
    };
  }

  static double _portionFactor(Object? value) {
    return switch (_normalizePortionLevel(value)) {
      'small' => 0.85,
      'large' => 1.15,
      _ => 1.0,
    };
  }

  static double _scaled(double value, double factor) {
    return double.parse((value * factor).toStringAsFixed(1));
  }

  static String _dateKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}

class MealPlanSlot {
  final String type;
  final int order;
  final String startTime;
  final String endTime;

  const MealPlanSlot({
    required this.type,
    required this.order,
    required this.startTime,
    required this.endTime,
  });
}
