class HealthProfileModel {
  final String id;

  HealthProfileModel({
    required this.id,
  });

  factory HealthProfileModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return HealthProfileModel(
      id: map['id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
    };
  }
}