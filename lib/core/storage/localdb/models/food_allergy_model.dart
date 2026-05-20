class FoodAllergyModel {
  final String id;

  FoodAllergyModel({
    required this.id,
  });

  factory FoodAllergyModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return FoodAllergyModel(
      id: map['id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
    };
  }
}