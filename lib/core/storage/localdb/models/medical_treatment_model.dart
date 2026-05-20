class MedicalTreatmentModel {
  final String id;

  MedicalTreatmentModel({
    required this.id,
  });

  factory MedicalTreatmentModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return MedicalTreatmentModel(
      id: map['id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
    };
  }
}