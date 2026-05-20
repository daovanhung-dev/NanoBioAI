class HealthGoalModel {
  final String id;

  HealthGoalModel({
    required this.id,
  });

  factory HealthGoalModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return HealthGoalModel(
      id: map['id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
    };
  }
}