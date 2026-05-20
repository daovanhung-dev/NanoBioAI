class NutritionLogModel {
  final String id;

  NutritionLogModel({
    required this.id,
  });

  factory NutritionLogModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return NutritionLogModel(
      id: map['id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
    };
  }
}