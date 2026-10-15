import '../entities/medication_reminder.dart';

abstract interface class MedicationReminderRepository {
  Future<List<MedicationReminder>> listForUser(String userId);

  Future<void> create({
    required String userId,
    required String medicineName,
    required List<int> minutes,
  });

  Future<void> updateMedicineName({
    required String userId,
    required String reminderId,
    required String medicineName,
  });

  Future<void> updateTimes({
    required String userId,
    required String reminderId,
    required List<int> minutes,
  });

  Future<void> setEnabled({
    required String userId,
    required String reminderId,
    required bool enabled,
  });

  Future<void> delete({required String userId, required String reminderId});
}
