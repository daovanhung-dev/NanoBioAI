class HealthTrackingLogModel {
  final String id;

  HealthTrackingLogModel({
    required this.id,
  });

  factory HealthTrackingLogModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return HealthTrackingLogModel(
      id: map['id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
    };
  }
}