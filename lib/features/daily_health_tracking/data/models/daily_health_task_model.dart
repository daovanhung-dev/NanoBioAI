import '../../domain/entities/daily_health_task_entity.dart';

class DailyHealthTaskModel {
  final String id;
  final String? userId;
  final String taskDate;
  final String taskCode;
  final String category;
  final String title;
  final String description;
  final double targetValue;
  final double currentValue;
  final String unit;
  final bool isCompleted;
  final int sortOrder;
  final String source;
  final String encouragement;
  final String createdAt;
  final String updatedAt;

  const DailyHealthTaskModel({
    required this.id,
    this.userId,
    required this.taskDate,
    required this.taskCode,
    required this.category,
    required this.title,
    required this.description,
    required this.targetValue,
    required this.currentValue,
    required this.unit,
    required this.isCompleted,
    required this.sortOrder,
    required this.source,
    required this.encouragement,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DailyHealthTaskModel.fromMap(Map<String, dynamic> map) {
    return DailyHealthTaskModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString(),
      taskDate: map['task_date']?.toString() ?? '',
      taskCode: map['task_code']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      targetValue: _readDouble(map['target_value']) ?? 0,
      currentValue: _readDouble(map['current_value']) ?? 0,
      unit: map['unit']?.toString() ?? '',
      isCompleted: _readBool(map['is_completed']),
      sortOrder: _readInt(map['sort_order']) ?? 0,
      source: map['source']?.toString() ?? '',
      encouragement: map['encouragement']?.toString() ?? '',
      createdAt: map['created_at']?.toString() ?? '',
      updatedAt: map['updated_at']?.toString() ?? '',
    );
  }

  factory DailyHealthTaskModel.fromEntity(DailyHealthTaskEntity entity) {
    return DailyHealthTaskModel(
      id: entity.id,
      userId: entity.userId,
      taskDate: entity.taskDate,
      taskCode: entity.taskCode,
      category: entity.category,
      title: entity.title,
      description: entity.description,
      targetValue: entity.targetValue,
      currentValue: entity.currentValue,
      unit: entity.unit,
      isCompleted: entity.isCompleted,
      sortOrder: entity.sortOrder,
      source: entity.source,
      encouragement: entity.encouragement,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'task_date': taskDate,
      'task_code': taskCode,
      'category': category,
      'title': title,
      'description': description,
      'target_value': targetValue,
      'current_value': currentValue,
      'unit': unit,
      'is_completed': isCompleted ? 1 : 0,
      'sort_order': sortOrder,
      'source': source,
      'encouragement': encouragement,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory DailyHealthTaskModel.fromJson(Map<String, dynamic> json) {
    return DailyHealthTaskModel.fromMap(json);
  }

  DailyHealthTaskEntity toEntity() {
    return DailyHealthTaskEntity(
      id: id,
      userId: userId,
      taskDate: taskDate,
      taskCode: taskCode,
      category: category,
      title: title,
      description: description,
      targetValue: targetValue,
      currentValue: currentValue,
      unit: unit,
      isCompleted: isCompleted,
      sortOrder: sortOrder,
      source: source,
      encouragement: encouragement,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  DailyHealthTaskModel copyWith({
    String? id,
    String? userId,
    String? taskDate,
    String? taskCode,
    String? category,
    String? title,
    String? description,
    double? targetValue,
    double? currentValue,
    String? unit,
    bool? isCompleted,
    int? sortOrder,
    String? source,
    String? encouragement,
    String? createdAt,
    String? updatedAt,
  }) {
    return DailyHealthTaskModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      taskDate: taskDate ?? this.taskDate,
      taskCode: taskCode ?? this.taskCode,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      unit: unit ?? this.unit,
      isCompleted: isCompleted ?? this.isCompleted,
      sortOrder: sortOrder ?? this.sortOrder,
      source: source ?? this.source,
      encouragement: encouragement ?? this.encouragement,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static bool _readBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().trim().toLowerCase() ?? '';
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
