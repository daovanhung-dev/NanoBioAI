import 'meal_plan_model.dart';

class MealPlanAiNormalizer {
  static const mealsPerDay = 5;

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
    required String userId,
    required DateTime startDate,
    int days = 7,
    required String createdAt,
  }) {
    final expectedCount = days * mealsPerDay;
    if (items.length != expectedCount) {
      throw FormatException(
        'Meal AI response must contain exactly $expectedCount meals',
      );
    }

    final result = <MealPlanModel>[];
    for (var dayIndex = 0; dayIndex < days; dayIndex++) {
      final date = _dateKey(startDate.add(Duration(days: dayIndex)));
      final start = dayIndex * mealsPerDay;
      final dayItems = items.sublist(start, start + mealsPerDay);
      final byType = <String, Map<String, dynamic>>{};

      for (final item in dayItems) {
        if (item is! Map) {
          throw const FormatException('Meal AI item must be an object');
        }

        final map = Map<String, dynamic>.from(item);
        final mealType = _readString(map['meal_type']).toLowerCase();
        if (mealType.isEmpty) {
          throw const FormatException('Meal AI item missing meal_type');
        }
        if (!mealSlots.any((slot) => slot.type == mealType)) {
          throw FormatException('Unsupported meal_type: $mealType');
        }
        if (byType.containsKey(mealType)) {
          throw FormatException('Duplicate meal_type for $date: $mealType');
        }

        byType[mealType] = map;
      }

      for (final slot in mealSlots) {
        final map = byType[slot.type];
        if (map == null) {
          throw FormatException('Expected meal_type ${slot.type} for $date');
        }

        result.add(
          MealPlanModel(
            id: 'meal_${userId}_${date}_${slot.order}',
            userId: userId,
            planDate: date,
            mealType: slot.type,
            mealName: _readString(
              map['meal_name'],
              fallback: _fallbackMealName(slot.type),
            ),
            description: _readString(map['description']),
            calories: _readInt(map['calories']),
            protein: _readDouble(map['protein']),
            carbs: _readDouble(map['carbs']),
            fat: _readDouble(map['fat']),
            fiber: _readDouble(map['fiber']),
            waterMl: _readInt(map['water_ml']),
            mealOrder: slot.order,
            startTime: slot.startTime,
            endTime: slot.endTime,
            cookingInstructions: _readString(map['cooking_instructions']),
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

  static String _readString(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static int _readInt(Object? value) {
    final parsed = switch (value) {
      final int n => n,
      final num n => n.toInt(),
      final String s =>
        int.tryParse(s.trim()) ?? double.tryParse(s.trim())?.toInt(),
      _ => null,
    };
    return parsed != null && parsed >= 0 ? parsed : 0;
  }

  static double _readDouble(Object? value) {
    final parsed = switch (value) {
      final double n => n,
      final num n => n.toDouble(),
      final String s => double.tryParse(s.trim()),
      _ => null,
    };
    return parsed != null && parsed >= 0 ? parsed : 0;
  }

  static String _fallbackMealName(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return 'Bua sang';
      case 'morning_snack':
        return 'Bua phu sang';
      case 'lunch':
        return 'Bua trua';
      case 'afternoon_snack':
        return 'Bua phu chieu';
      case 'dinner':
        return 'Bua toi';
      default:
        return 'Bua an';
    }
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
