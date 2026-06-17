class AIInsightModel {
  final String id;
  final String? userId;
  final String? insightType;
  final String? title;
  final String? content;
  final String? riskLevel;
  final String? createdAt;

  const AIInsightModel({
    required this.id,
    this.userId,
    this.insightType,
    this.title,
    this.content,
    this.riskLevel,
    this.createdAt,
  });

  factory AIInsightModel.fromMap(Map<String, Object?> map) {
    return AIInsightModel(
      id: _readString(map['id']) ?? '',
      userId: _readString(map['user_id']),
      insightType: _readString(map['insight_type']),
      title: _readString(map['title']),
      content: _readString(map['content']),
      riskLevel: _readString(map['risk_level']),
      createdAt: _readString(map['created_at']),
    );
  }

  factory AIInsightModel.fromJson(Map<String, Object?> json) => AIInsightModel.fromMap(json);

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'insight_type': insightType,
      'title': title,
      'content': content,
      'risk_level': riskLevel,
      'created_at': createdAt,
    };
  }

  Map<String, Object?> toJson() => toMap();

  AIInsightModel copyWith({
    String? id,
    String? userId,
    String? insightType,
    String? title,
    String? content,
    String? riskLevel,
    String? createdAt,
  }) {
    return AIInsightModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      insightType: insightType ?? this.insightType,
      title: title ?? this.title,
      content: content ?? this.content,
      riskLevel: riskLevel ?? this.riskLevel,
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
