class AIRecommendationModel {
  final String id;
  final String? userId;
  final String? recommendationType;
  final String? title;
  final String? description;
  final String? actionText;
  final bool isRead;
  final String? createdAt;

  const AIRecommendationModel({
    required this.id,
    this.userId,
    this.recommendationType,
    this.title,
    this.description,
    this.actionText,
    this.isRead = false,
    this.createdAt,
  });

  factory AIRecommendationModel.fromMap(Map<String, Object?> map) {
    return AIRecommendationModel(
      id: _readString(map['id']) ?? '',
      userId: _readString(map['user_id']),
      recommendationType: _readString(map['recommendation_type']),
      title: _readString(map['title']),
      description: _readString(map['description']),
      actionText: _readString(map['action_text']),
      isRead: _readBool(map['is_read']),
      createdAt: _readString(map['created_at']),
    );
  }

  factory AIRecommendationModel.fromJson(Map<String, Object?> json) =>
      AIRecommendationModel.fromMap(json);

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'recommendation_type': recommendationType,
      'title': title,
      'description': description,
      'action_text': actionText,
      'is_read': isRead ? 1 : 0,
      'created_at': createdAt,
    };
  }

  Map<String, Object?> toJson() => toMap();

  AIRecommendationModel copyWith({
    String? id,
    String? userId,
    String? recommendationType,
    String? title,
    String? description,
    String? actionText,
    bool? isRead,
    String? createdAt,
  }) {
    return AIRecommendationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      recommendationType: recommendationType ?? this.recommendationType,
      title: title ?? this.title,
      description: description ?? this.description,
      actionText: actionText ?? this.actionText,
      isRead: isRead ?? this.isRead,
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
