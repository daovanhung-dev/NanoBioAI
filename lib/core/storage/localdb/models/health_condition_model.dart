class HealthConditionModel {
  final String id;

  HealthConditionModel({
    required this.id,
  });

  factory HealthConditionModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return HealthConditionModel(
      id: map['id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
    };
  }
}