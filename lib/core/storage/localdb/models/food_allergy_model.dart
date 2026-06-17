class FoodAllergyModel {
  final String id;
  final String? userId;
  final String? allergyName;
  final String? note;
  final String? createdAt;

  const FoodAllergyModel({
    required this.id,
    this.userId,
    this.allergyName,
    this.note,
    this.createdAt,
  });

  factory FoodAllergyModel.fromMap(Map<String, Object?> map) {
    return FoodAllergyModel(
      id: _readString(map['id']) ?? '',
      userId: _readString(map['user_id']),
      allergyName: _readString(map['allergy_name']),
      note: _readString(map['note']),
      createdAt: _readString(map['created_at']),
    );
  }

  factory FoodAllergyModel.fromJson(Map<String, Object?> json) => FoodAllergyModel.fromMap(json);

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'allergy_name': allergyName,
      'note': note,
      'created_at': createdAt,
    };
  }

  Map<String, Object?> toJson() => toMap();

  FoodAllergyModel copyWith({
    String? id,
    String? userId,
    String? allergyName,
    String? note,
    String? createdAt,
  }) {
    return FoodAllergyModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      allergyName: allergyName ?? this.allergyName,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

String? _readString(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? _readInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double? _readDouble(Object? value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

bool _readBool(Object? value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value.toString().trim().toLowerCase();
  return normalized == '1' || normalized == 'true' || normalized == 'yes';
}
