class LifestyleHabitModel {
  final String id;
  final String? userId;
  final bool skipBreakfast;
  final bool eatLate;
  final bool eatSweet;
  final bool eatOily;
  final bool lowVegetable;
  final bool lowWater;
  final bool fastFood;
  final bool alcohol;
  final bool coffeeHigh;
  final String? sleepQuality;
  final String? activityLevel;
  final String? waterPerDay;
  final String? createdAt;

  const LifestyleHabitModel({
    required this.id,
    this.userId,
    this.skipBreakfast = false,
    this.eatLate = false,
    this.eatSweet = false,
    this.eatOily = false,
    this.lowVegetable = false,
    this.lowWater = false,
    this.fastFood = false,
    this.alcohol = false,
    this.coffeeHigh = false,
    this.sleepQuality,
    this.activityLevel,
    this.waterPerDay,
    this.createdAt,
  });

  factory LifestyleHabitModel.fromMap(Map<String, Object?> map) {
    return LifestyleHabitModel(
      id: _readString(map['id']) ?? '',
      userId: _readString(map['user_id']),
      skipBreakfast: _readBool(map['skip_breakfast']),
      eatLate: _readBool(map['eat_late']),
      eatSweet: _readBool(map['eat_sweet']),
      eatOily: _readBool(map['eat_oily']),
      lowVegetable: _readBool(map['low_vegetable']),
      lowWater: _readBool(map['low_water']),
      fastFood: _readBool(map['fast_food']),
      alcohol: _readBool(map['alcohol']),
      coffeeHigh: _readBool(map['coffee_high']),
      sleepQuality: _readString(map['sleep_quality']),
      activityLevel: _readString(map['activity_level']),
      waterPerDay: _readString(map['water_per_day']),
      createdAt: _readString(map['created_at']),
    );
  }

  factory LifestyleHabitModel.fromJson(Map<String, Object?> json) =>
      LifestyleHabitModel.fromMap(json);

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'skip_breakfast': skipBreakfast ? 1 : 0,
      'eat_late': eatLate ? 1 : 0,
      'eat_sweet': eatSweet ? 1 : 0,
      'eat_oily': eatOily ? 1 : 0,
      'low_vegetable': lowVegetable ? 1 : 0,
      'low_water': lowWater ? 1 : 0,
      'fast_food': fastFood ? 1 : 0,
      'alcohol': alcohol ? 1 : 0,
      'coffee_high': coffeeHigh ? 1 : 0,
      'sleep_quality': sleepQuality,
      'activity_level': activityLevel,
      'water_per_day': waterPerDay,
      'created_at': createdAt,
    };
  }

  Map<String, Object?> toJson() => toMap();

  LifestyleHabitModel copyWith({
    String? id,
    String? userId,
    bool? skipBreakfast,
    bool? eatLate,
    bool? eatSweet,
    bool? eatOily,
    bool? lowVegetable,
    bool? lowWater,
    bool? fastFood,
    bool? alcohol,
    bool? coffeeHigh,
    String? sleepQuality,
    String? activityLevel,
    String? waterPerDay,
    String? createdAt,
  }) {
    return LifestyleHabitModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      skipBreakfast: skipBreakfast ?? this.skipBreakfast,
      eatLate: eatLate ?? this.eatLate,
      eatSweet: eatSweet ?? this.eatSweet,
      eatOily: eatOily ?? this.eatOily,
      lowVegetable: lowVegetable ?? this.lowVegetable,
      lowWater: lowWater ?? this.lowWater,
      fastFood: fastFood ?? this.fastFood,
      alcohol: alcohol ?? this.alcohol,
      coffeeHigh: coffeeHigh ?? this.coffeeHigh,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      activityLevel: activityLevel ?? this.activityLevel,
      waterPerDay: waterPerDay ?? this.waterPerDay,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

String? _readString(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

bool _readBool(Object? value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value.toString().trim().toLowerCase();
  return normalized == '1' || normalized == 'true' || normalized == 'yes';
}
