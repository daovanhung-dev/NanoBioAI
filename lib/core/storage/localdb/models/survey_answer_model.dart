class SurveyAnswerModel {
  final String id;

  SurveyAnswerModel({
    required this.id,
  });

  factory SurveyAnswerModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return SurveyAnswerModel(
      id: map['id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
    };
  }
}