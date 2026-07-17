import 'nabi_notification_models.dart';

abstract interface class NabiNotificationConfigRepository {
  Future<List<NabiNotificationDefinition>> loadActiveDefinitions();
}

abstract interface class NabiNotificationStateRepository {
  Future<List<NabiNotificationHistoryEntry>> loadHistory(String actorKey);

  Future<NabiNotificationOccurrence> claim({
    required NabiNotificationDefinition definition,
    required NabiBusinessSnapshot snapshot,
    required NabiUiContext uiContext,
  });

  Future<void> updateStatus({
    required String occurrenceId,
    required NabiNotificationStatus status,
    DateTime? deferredUntil,
    String? errorCode,
  });
}

abstract interface class NabiNotificationAnalyticsRepository {
  Future<void> append({
    required String eventName,
    required NabiNotificationOccurrence occurrence,
    required NabiUiContext uiContext,
    String? resultCode,
  });

  Future<int> drainPending();
}

abstract interface class NabiNativeDeliveryGateway {
  Future<void> schedule({
    required NabiNotificationOccurrence occurrence,
    required NabiNotificationDefinition definition,
    required DateTime deliveryAt,
  });

  Future<void> cancel(String occurrenceId);
}

abstract interface class NabiNavigationGateway {
  Future<bool> open(NabiNotificationDestination destination);
}

abstract interface class NabiBusinessEventBus {
  Stream<NabiBusinessSnapshot> get events;
  void emit(NabiBusinessSnapshot snapshot);
}
