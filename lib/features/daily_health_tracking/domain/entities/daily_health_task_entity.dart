class DailyHealthTaskEntity {
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

  const DailyHealthTaskEntity({
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

  bool get isQuantitative => targetValue > 1;

  double get progressRatio {
    if (targetValue <= 0) return isCompleted ? 1 : 0;
    final ratio = currentValue / targetValue;
    return ratio.clamp(0, 1).toDouble();
  }

  DailyHealthTaskEntity copyWith({
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
    return DailyHealthTaskEntity(
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
}
