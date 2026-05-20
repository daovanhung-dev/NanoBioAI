class LifestyleHabitModel {
  final String id;

  LifestyleHabitModel({
    required this.id,
  });

  factory LifestyleHabitModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return LifestyleHabitModel(
      id: map['id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
    };
  }
}