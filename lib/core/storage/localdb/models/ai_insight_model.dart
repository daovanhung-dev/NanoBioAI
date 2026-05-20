class AIInsightModel {
  final String id;

  AIInsightModel({
    required this.id,
  });

  factory AIInsightModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return AIInsightModel(
      id: map['id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
    };
  }
}