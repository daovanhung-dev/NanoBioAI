import '../../domain/entities/lifestyle_schedule_item_entity.dart';

class LifestyleScheduleItemModel {
  final String id;
  final String? userId;
  final String scheduleDate;
  final String startTime;
  final String endTime;
  final String title;
  final String description;
  final String category;
  final String sourceType;
  final String? sourceId;
  final double targetValue;
  final double currentValue;
  final String unit;
  final bool isCompleted;
  final int sortOrder;
  final bool aiGenerated;
  final String encouragement;
  final String createdAt;
  final String updatedAt;

  const LifestyleScheduleItemModel({
    required this.id,
    this.userId,
    required this.scheduleDate,
    required this.startTime,
    this.endTime = '',
    required this.title,
    this.description = '',
    required this.category,
    required this.sourceType,
    this.sourceId,
    this.targetValue = 1,
    this.currentValue = 0,
    this.unit = 'lần',
    this.isCompleted = false,
    this.sortOrder = 0,
    this.aiGenerated = true,
    this.encouragement = '',
    required this.createdAt,
    required this.updatedAt,
  });

  factory LifestyleScheduleItemModel.fromMap(Map<String, dynamic> map) {
    return LifestyleScheduleItemModel(
      id: _readString(map['id']),
      userId: map['user_id']?.toString(),
      scheduleDate: _readString(map['schedule_date']),
      startTime: _readString(map['start_time']),
      endTime: _readString(map['end_time']),
      title: _readString(map['title']),
      description: _readString(map['description']),
      category: _readString(map['category']),
      sourceType: _readString(map['source_type']),
      sourceId: map['source_id']?.toString(),
      targetValue: _readDouble(map['target_value']) ?? 1,
      currentValue: _readDouble(map['current_value']) ?? 0,
      unit: _readString(map['unit'], fallback: 'lần'),
      isCompleted: _readBool(map['is_completed']),
      sortOrder: _readInt(map['sort_order']) ?? 0,
      aiGenerated: _readBool(map['ai_generated'], fallback: true),
      encouragement: _readString(map['encouragement']),
      createdAt: _readString(map['created_at']),
      updatedAt: _readString(map['updated_at']),
    );
  }

  factory LifestyleScheduleItemModel.fromJson(Map<String, dynamic> json) {
    return LifestyleScheduleItemModel.fromMap(json);
  }

  factory LifestyleScheduleItemModel.fromEntity(
    LifestyleScheduleItemEntity entity,
  ) {
    return LifestyleScheduleItemModel(
      id: entity.id,
      userId: entity.userId,
      scheduleDate: entity.scheduleDate,
      startTime: entity.startTime,
      endTime: entity.endTime,
      title: entity.title,
      description: entity.description,
      category: entity.category,
      sourceType: entity.sourceType,
      sourceId: entity.sourceId,
      targetValue: entity.targetValue,
      currentValue: entity.currentValue,
      unit: entity.unit,
      isCompleted: entity.isCompleted,
      sortOrder: entity.sortOrder,
      aiGenerated: entity.aiGenerated,
      encouragement: entity.encouragement,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'schedule_date': scheduleDate,
      'start_time': startTime,
      'end_time': endTime,
      'title': title,
      'description': description,
      'category': category,
      'source_type': sourceType,
      'source_id': sourceId,
      'target_value': targetValue,
      'current_value': currentValue,
      'unit': unit,
      'is_completed': isCompleted ? 1 : 0,
      'sort_order': sortOrder,
      'ai_generated': aiGenerated ? 1 : 0,
      'encouragement': encouragement,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'schedule_date': scheduleDate,
    'start_time': startTime,
    'end_time': endTime,
    'title': title,
    'description': description,
    'category': category,
    'source_type': sourceType,
    'source_id': sourceId,
    'target_value': targetValue,
    'current_value': currentValue,
    'unit': unit,
    'is_completed': isCompleted,
    'sort_order': sortOrder,
    'ai_generated': aiGenerated,
    'encouragement': encouragement,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  LifestyleScheduleItemEntity toEntity() {
    return LifestyleScheduleItemEntity(
      id: id,
      userId: userId,
      scheduleDate: scheduleDate,
      startTime: startTime,
      endTime: endTime,
      title: title,
      description: description,
      category: category,
      sourceType: sourceType,
      sourceId: sourceId,
      targetValue: targetValue,
      currentValue: currentValue,
      unit: unit,
      isCompleted: isCompleted,
      sortOrder: sortOrder,
      aiGenerated: aiGenerated,
      encouragement: encouragement,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  LifestyleScheduleItemModel copyWith({
    String? id,
    String? userId,
    String? scheduleDate,
    String? startTime,
    String? endTime,
    String? title,
    String? description,
    String? category,
    String? sourceType,
    String? sourceId,
    double? targetValue,
    double? currentValue,
    String? unit,
    bool? isCompleted,
    int? sortOrder,
    bool? aiGenerated,
    String? encouragement,
    String? createdAt,
    String? updatedAt,
  }) {
    return LifestyleScheduleItemModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      scheduleDate: scheduleDate ?? this.scheduleDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      unit: unit ?? this.unit,
      isCompleted: isCompleted ?? this.isCompleted,
      sortOrder: sortOrder ?? this.sortOrder,
      aiGenerated: aiGenerated ?? this.aiGenerated,
      encouragement: encouragement ?? this.encouragement,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static String _readString(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static bool _readBool(Object? value, {bool fallback = false}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value.toString().trim().toLowerCase();
    return text == 'true' || text == '1' || text == 'yes';
  }

  static int? _readInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double? _readDouble(Object? value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
