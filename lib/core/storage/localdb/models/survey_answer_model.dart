class SurveyAnswerModel {
  final String id;
  final String? userId;
  final String? questionCode;
  final String? answerValue;
  final String? createdAt;

  const SurveyAnswerModel({
    required this.id,
    this.userId,
    this.questionCode,
    this.answerValue,
    this.createdAt,
  });

  factory SurveyAnswerModel.fromMap(Map<String, Object?> map) {
    return SurveyAnswerModel(
      id: _readString(map['id']) ?? '',
      userId: _readString(map['user_id']),
      questionCode: _readString(map['question_code']),
      answerValue: _readString(map['answer_value']),
      createdAt: _readString(map['created_at']),
    );
  }

  factory SurveyAnswerModel.fromJson(Map<String, Object?> json) => SurveyAnswerModel.fromMap(json);

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'question_code': questionCode,
      'answer_value': answerValue,
      'created_at': createdAt,
    };
  }

  Map<String, Object?> toJson() => toMap();

  SurveyAnswerModel copyWith({
    String? id,
    String? userId,
    String? questionCode,
    String? answerValue,
    String? createdAt,
  }) {
    return SurveyAnswerModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      questionCode: questionCode ?? this.questionCode,
      answerValue: answerValue ?? this.answerValue,
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
