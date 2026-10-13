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

  static String mealNameUniquenessKey(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  static Set<String> mealNameKeysForCodes(
    Iterable<MealCatalogItemModel> meals,
    Iterable<String> codes,
  ) {
    final mealsByCode = {for (final meal in meals) meal.code: meal};
    final names = <String>{};
    for (final code in codes) {
      final meal = mealsByCode[code];
      if (meal == null) continue;
      final key = mealNameUniquenessKey(meal.mealName);
      if (key.isNotEmpty) names.add(key);
    }
    return names;
  }

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
        const factor = 1.0;
        result.add(
          MealPlanModel(
            id: 'meal_${userId}_${date}_${slot.order}',
            userId: userId,
            planDate: date,
            mealType: slot.type,
            mealName: catalogItem.mealName,
            description: catalogItem.description,
            calories: (catalogItem.calories * factor).round(),
            protein: _scaled(catalogItem.protein, factor),
            carbs: _scaled(catalogItem.carbs, factor),
            fat: _scaled(catalogItem.fat, factor),
            fiber: _scaled(catalogItem.fiber, factor),
            waterMl: (catalogItem.waterMl * factor).round(),
            sugarG: _scaledNullable(catalogItem.sugarG, factor),
            saturatedFatG: _scaledNullable(catalogItem.saturatedFatG, factor),
            sodiumMg: _scaledNullable(catalogItem.sodiumMg, factor),
            cholesterolMg: _scaledNullable(catalogItem.cholesterolMg, factor),
            potassiumMg: _scaledNullable(catalogItem.potassiumMg, factor),
            calciumMg: _scaledNullable(catalogItem.calciumMg, factor),
            ironMg: _scaledNullable(catalogItem.ironMg, factor),
            nutritionStatus: catalogItem.nutritionStatus,
            mealOrder: slot.order,
            startTime: slot.startTime,
            endTime: slot.endTime,
            cookingInstructions: catalogItem.cookingInstructions,
            catalogCode: catalogItem.code,
            servingSize: catalogItem.servingSize,
            topicCode: catalogItem.healthTopicCode,
            topicName: catalogItem.healthTopicName,
            ingredients: catalogItem.ingredients,
            cookingSteps: catalogItem.cookingSteps,
            benefits: catalogItem.benefits,
            allergenTags: catalogItem.allergenTags,
            conditionTags: catalogItem.avoidConditionTags,
            provenanceSource: catalogItem.sourceName,
            sourceHash: catalogItem.sourceHash,
            catalogSchemaVersion: catalogItem.version,
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
    Map<String, Set<String>>? eligibleCodesByType,
  }) {
    final expectedCount = days * mealsPerDay;
    if (items.length != expectedCount) {
      throw FormatException(
        'Meal AI response must contain exactly $expectedCount meals',
      );
    }
    final catalogByCode = catalog.mealsByCode;
    final counts = Map<String, int>.from(usedCodeCounts);
    final usedMealNames = mealNameKeysForCodes(
      catalog.meals,
      counts.entries
          .where((entry) => entry.value > 0)
          .map((entry) => entry.key),
    );
    final byDayAndType = <int, Map<String, Map<String, dynamic>>>{};
    for (final item in items) {
      if (item is! Map) {
        throw const FormatException('Meal AI item must be an object');
      }
      final map = Map<String, dynamic>.from(item);
      _rejectForbiddenTextFields(map, label: 'Meal AI item');
      _requireOutputKeys(map, const {'day', 'meal_type', 'meal_code'});
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
      if (!catalogItem.isActive) {
        throw FormatException('Inactive meal_code: $mealCode');
      }
      if (catalogItem.mealName.trim().isEmpty) {
        throw FormatException('Meal catalog name is empty: $mealCode');
      }
      if (catalogItem.mealType != mealType &&
          catalogItem.mealType != 'unclassified') {
        throw FormatException('meal_code $mealCode is not valid for $mealType');
      }
      final dayItems = byDayAndType.putIfAbsent(day, () => {});
      if (dayItems.containsKey(mealType)) {
        throw FormatException('Duplicate meal_type for day $day: $mealType');
      }
      if (dayItems.values.any((entry) => entry['meal_code'] == mealCode)) {
        throw FormatException('Duplicate meal_code for day $day: $mealCode');
      }
      if ((counts[mealCode] ?? 0) > 0) {
        throw const FormatException('Duplicate meal_code across the week.');
      }
      final nameKey = mealNameUniquenessKey(catalogItem.mealName);
      if (nameKey.isNotEmpty && !usedMealNames.add(nameKey)) {
        throw const FormatException('Duplicate meal_name across the week.');
      }
      counts[mealCode] = 1;
      dayItems[mealType] = {
        'day': day,
        'meal_type': mealType,
        'meal_code': mealCode,
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

  List<Map<String, dynamic>> validateCodeItemForSlot({
    required dynamic item,
    required AiCatalogBundle catalog,
    required int day,
    required String mealType,
    required Map<String, int> usedCodeCounts,
    Set<String> dayMealCodes = const {},
    Map<String, Set<String>>? eligibleCodesByType,
  }) {
    final slot = _slotForType(mealType);
    if (slot == null) {
      throw FormatException('Unsupported meal_type: $mealType');
    }
    if (item is! Map) {
      throw const FormatException('Meal AI item must be an object');
    }
    final map = Map<String, dynamic>.from(item);
    _rejectForbiddenTextFields(map, label: 'Meal AI item');
    _requireOutputKeys(map, const {'day', 'meal_type', 'meal_code'});
    if (_readInt(map['day']) != day) {
      throw FormatException('Meal AI day must equal $day');
    }
    final resolvedMealType = _readString(map['meal_type']).toLowerCase();
    if (resolvedMealType != slot.type) {
      throw FormatException('Meal AI meal_type must equal ${slot.type}');
    }
    final mealCode = _readString(map['meal_code']).toLowerCase();
    final catalogItem = catalog.mealsByCode[mealCode];
    if (catalogItem == null || !catalogItem.isActive) {
      throw FormatException('Unknown or inactive meal_code: $mealCode');
    }
    if (catalogItem.mealName.trim().isEmpty) {
      throw FormatException('Meal catalog name is empty: $mealCode');
    }
    if (catalogItem.mealType != slot.type &&
        catalogItem.mealType != 'unclassified') {
      throw FormatException(
        'meal_code $mealCode is not valid for ${slot.type}',
      );
    }
    if (eligibleCodesByType != null &&
        eligibleCodesByType[slot.type]?.contains(mealCode) != true) {
      throw FormatException(
        'meal_code $mealCode is not eligible for ${slot.type}',
      );
    }
    final usedCodes = {
      ...usedCodeCounts.entries
          .where((entry) => entry.value > 0)
          .map((entry) => entry.key),
      ...dayMealCodes,
    };
    if (usedCodes.contains(mealCode)) {
      throw const FormatException('Duplicate meal_code across the week.');
    }
    final usedMealNames = mealNameKeysForCodes(catalog.meals, usedCodes);
    final nameKey = mealNameUniquenessKey(catalogItem.mealName);
    if (nameKey.isNotEmpty && usedMealNames.contains(nameKey)) {
      throw const FormatException('Duplicate meal_name across the week.');
    }
    return [
      {'day': day, 'meal_type': slot.type, 'meal_code': mealCode},
    ];
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

  static void _requireOutputKeys(
    Map<String, dynamic> map,
    Set<String> allowed,
  ) {
    if (map.keys.any((key) => !allowed.contains(key)) ||
        !map.keys.toSet().containsAll(allowed)) {
      throw const FormatException(
        'Meal AI item must contain only day, meal_type and meal_code.',
      );
    }
  }

  static MealPlanSlot? _slotForType(String mealType) {
    for (final slot in mealSlots) {
      if (slot.type == mealType) return slot;
    }
    return null;
  }

  static String _readString(Object? value) => value?.toString().trim() ?? '';
  static int _readInt(Object? value) {
    final parsed = _readOptionalInt(value);
    if (parsed == null) {
      throw FormatException('Expected integer value, got $value');
    }
    return parsed;
  }

  static int? _readOptionalInt(Object? value) => switch (value) {
    final int n => n,
    final num n => n.toInt(),
    final String s => int.tryParse(s.trim()),
    _ => null,
  };
  static double _scaled(double value, double factor) =>
      double.parse((value * factor).toStringAsFixed(1));
  static double? _scaledNullable(double? value, double factor) =>
      value == null ? null : _scaled(value, factor);
  static String _dateKey(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
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
