class MedicalTreatmentModel {
  final String id;
  final String? userId;
  final String? treatmentName;
  final String? medicationName;
  final String? note;
  final String? createdAt;

  const MedicalTreatmentModel({
    required this.id,
    this.userId,
    this.treatmentName,
    this.medicationName,
    this.note,
    this.createdAt,
  });

  factory MedicalTreatmentModel.fromMap(Map<String, Object?> map) {
    return MedicalTreatmentModel(
      id: _readString(map['id']) ?? '',
      userId: _readString(map['user_id']),
      treatmentName: _readString(map['treatment_name']),
      medicationName: _readString(map['medication_name']),
      note: _readString(map['note']),
      createdAt: _readString(map['created_at']),
    );
  }

  factory MedicalTreatmentModel.fromJson(Map<String, Object?> json) =>
      MedicalTreatmentModel.fromMap(json);

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'treatment_name': treatmentName,
      'medication_name': medicationName,
      'note': note,
      'created_at': createdAt,
    };
  }

  Map<String, Object?> toJson() => toMap();

  MedicalTreatmentModel copyWith({
    String? id,
    String? userId,
    String? treatmentName,
    String? medicationName,
    String? note,
    String? createdAt,
  }) {
    return MedicalTreatmentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      treatmentName: treatmentName ?? this.treatmentName,
      medicationName: medicationName ?? this.medicationName,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

String? _readString(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}
