class MedicationReminder {
  final String id;
  final String userId;
  final String medicineName;
  final List<int> reminderMinutes;
  final bool enabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MedicationReminder({
    required this.id,
    required this.userId,
    required this.medicineName,
    required this.reminderMinutes,
    required this.enabled,
    required this.createdAt,
    required this.updatedAt,
  });

  MedicationReminder copyWith({
    String? medicineName,
    List<int>? reminderMinutes,
    bool? enabled,
    DateTime? updatedAt,
  }) => MedicationReminder(
    id: id,
    userId: userId,
    medicineName: medicineName ?? this.medicineName,
    reminderMinutes: reminderMinutes ?? this.reminderMinutes,
    enabled: enabled ?? this.enabled,
    createdAt: createdAt,
    updatedAt: updatedAt ?? DateTime.now(),
  );
}
