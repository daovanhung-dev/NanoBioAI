import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/features/medication_reminders/data/repositories/sqlite_medication_reminder_repository.dart';
import 'package:nano_app/app_versions/v1/features/medication_reminders/domain/entities/medication_reminder.dart';
import 'package:nano_app/app_versions/v1/features/medication_reminders/domain/repositories/medication_reminder_repository.dart';
import 'package:nano_app/app_versions/v1/services/notifications/active_notification_subject.dart';
import 'package:nano_app/app_versions/v1/services/notifications/notification_bootstrap.dart';
import 'package:shared_preferences/shared_preferences.dart';

final medicationReminderRepositoryProvider =
    Provider<MedicationReminderRepository>(
      (_) => const SqliteMedicationReminderRepository(),
    );

final medicationReminderPermissionDeniedProvider = FutureProvider<bool>((
  ref,
) async {
  final preferences = await SharedPreferences.getInstance();
  return preferences.getBool('medication_reminder_permission_denied') ?? false;
});

final medicationReminderSettingsProvider =
    AsyncNotifierProvider<
      MedicationReminderSettingsController,
      List<MedicationReminder>
    >(MedicationReminderSettingsController.new);

class MedicationReminderSettingsController
    extends AsyncNotifier<List<MedicationReminder>> {
  late MedicationReminderRepository _repository;
  String? _ownerId;

  @override
  Future<List<MedicationReminder>> build() async {
    _repository = ref.read(medicationReminderRepositoryProvider);
    _ownerId = await resolveActiveNotificationSubject();
    final owner = _ownerId;
    if (owner == null || owner.isEmpty) return const [];
    return _repository.listForUser(owner);
  }

  Future<bool> setEnabled(MedicationReminder reminder, bool enabled) async {
    final owner = _requireOwner();
    await _repository.setEnabled(
      userId: owner,
      reminderId: reminder.id,
      enabled: enabled,
    );
    await NotificationBootstrap.scheduleGeneratedReminders(
      subjectUserId: owner,
    );
    await _refresh(owner);
    return true;
  }

  Future<void> create({
    required String medicineName,
    required List<int> minutes,
  }) async {
    final owner = _requireOwner();
    final isFirstReminder = state.hasValue && state.requireValue.isEmpty;
    await _repository.create(
      userId: owner,
      medicineName: medicineName,
      minutes: minutes,
    );
    if (isFirstReminder) {
      await NotificationBootstrap.requestMedicationReminderPermissionAndEnable(
        subjectUserId: owner,
      );
    } else {
      await NotificationBootstrap.scheduleGeneratedReminders(
        subjectUserId: owner,
      );
    }
    await _refresh(owner);
  }

  Future<void> updateMedicineName(
    MedicationReminder reminder,
    String medicineName,
  ) async {
    final owner = _requireOwner();
    await _repository.updateMedicineName(
      userId: owner,
      reminderId: reminder.id,
      medicineName: medicineName,
    );
    await NotificationBootstrap.scheduleGeneratedReminders(
      subjectUserId: owner,
    );
    await _refresh(owner);
  }

  Future<void> updateTimes(
    MedicationReminder reminder,
    List<int> minutes,
  ) async {
    final owner = _requireOwner();
    await _repository.updateTimes(
      userId: owner,
      reminderId: reminder.id,
      minutes: minutes,
    );
    await NotificationBootstrap.scheduleGeneratedReminders(
      subjectUserId: owner,
    );
    await _refresh(owner);
  }

  Future<void> delete(MedicationReminder reminder) async {
    final owner = _requireOwner();
    await _repository.delete(userId: owner, reminderId: reminder.id);
    await NotificationBootstrap.scheduleGeneratedReminders(
      subjectUserId: owner,
    );
    await _refresh(owner);
  }

  Future<bool> requestPermission() async {
    final owner = _requireOwner();
    final granted =
        await NotificationBootstrap.requestMedicationReminderPermissionAndEnable(
          subjectUserId: owner,
        );
    ref.invalidate(medicationReminderPermissionDeniedProvider);
    await _refresh(owner);
    return granted;
  }

  String _requireOwner() {
    final owner = _ownerId;
    if (owner == null || owner.isEmpty) {
      throw StateError('No local user is available for medication reminders');
    }
    return owner;
  }

  Future<void> _refresh(String owner) async {
    state = AsyncData(await _repository.listForUser(owner));
    ref.invalidate(medicationReminderPermissionDeniedProvider);
  }
}
