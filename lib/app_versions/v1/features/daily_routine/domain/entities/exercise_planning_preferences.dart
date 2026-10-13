import 'dart:convert';

class ExercisePlanningPreferences {
  static const equipmentOptions = <String, String>{
    'chair': 'Ghế chắc chắn',
    'wall': 'Tường trống',
    'mat': 'Thảm tập',
    'resistance_band': 'Dây kháng lực',
    'stairs': 'Bậc thang thấp',
  };

  static const limitationOptions = <String, String>{
    'knee': 'Đầu gối',
    'hip': 'Hông',
    'back': 'Lưng',
    'shoulder': 'Vai',
    'wrist': 'Cổ tay',
    'balance': 'Thăng bằng',
    'other': 'Giới hạn khác',
  };

  final List<String> availableEquipment;
  final List<String> mobilityLimitations;

  const ExercisePlanningPreferences({
    this.availableEquipment = const [],
    this.mobilityLimitations = const [],
  });

  factory ExercisePlanningPreferences.fromMap(Map<String, Object?> map) =>
      ExercisePlanningPreferences(
        availableEquipment: _readList(map['equipment_json']),
        mobilityLimitations: _readList(map['limitation_tags_json']),
      );

  Map<String, Object?> toMap({
    required String userId,
    required String updatedAt,
  }) => {
    'user_id': userId,
    'equipment_json': jsonEncode(availableEquipment),
    'limitation_tags_json': jsonEncode(mobilityLimitations),
    'updated_at': updatedAt,
  };

  List<String> validate() => [
    if (availableEquipment.any((value) => !equipmentOptions.containsKey(value)))
      'Có dụng cụ chưa được hỗ trợ.',
    if (mobilityLimitations.any(
      (value) => !limitationOptions.containsKey(value),
    ))
      'Có giới hạn vận động chưa được hỗ trợ.',
  ];

  ExercisePlanningPreferences copyWith({
    List<String>? availableEquipment,
    List<String>? mobilityLimitations,
  }) => ExercisePlanningPreferences(
    availableEquipment: availableEquipment ?? this.availableEquipment,
    mobilityLimitations: mobilityLimitations ?? this.mobilityLimitations,
  );
}

List<String> _readList(Object? value) {
  if (value is List) {
    return value.map((entry) => entry.toString()).toSet().toList();
  }
  if (value is String && value.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is List) {
        return decoded
            .map((entry) => entry?.toString().trim() ?? '')
            .where((entry) => entry.isNotEmpty)
            .toSet()
            .toList(growable: false);
      }
    } catch (_) {}
  }
  return const [];
}
