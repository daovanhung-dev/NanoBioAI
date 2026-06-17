class ExerciseTaskModel {
  final String id;
  final String? userId;
  final String scheduleDate;
  final String startTime;
  final String endTime;
  final String title;
  final String description;
  final double targetValue;
  final String unit;
  final String encouragement;
  final String createdAt;
  final String updatedAt;

  const ExerciseTaskModel({
    required this.id,
    this.userId,
    required this.scheduleDate,
    required this.startTime,
    required this.endTime,
    required this.title,
    this.description = '',
    this.targetValue = 1,
    this.unit = 'lan',
    this.encouragement = '',
    required this.createdAt,
    required this.updatedAt,
  });

  ExerciseTaskModel copyWith({
    String? id,
    String? userId,
    String? scheduleDate,
    String? startTime,
    String? endTime,
    String? title,
    String? description,
    double? targetValue,
    String? unit,
    String? encouragement,
    String? createdAt,
    String? updatedAt,
  }) {
    return ExerciseTaskModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      scheduleDate: scheduleDate ?? this.scheduleDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      title: title ?? this.title,
      description: description ?? this.description,
      targetValue: targetValue ?? this.targetValue,
      unit: unit ?? this.unit,
      encouragement: encouragement ?? this.encouragement,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
