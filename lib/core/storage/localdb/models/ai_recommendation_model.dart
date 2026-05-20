class AIRecommendationModel {
  final String id;

  AIRecommendationModel({
    required this.id,
  });

  factory AIRecommendationModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return AIRecommendationModel(
      id: map['id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
    };
  }
}