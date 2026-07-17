import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/notifications/nabi_notification_local_repositories.dart';
import '../../domain/notifications/nabi_notification_models.dart';
import '../../domain/notifications/nabi_notification_repositories.dart';
import 'nabi_notification_engine.dart';

class NabiNotificationPresentationState {
  final NabiNotificationDefinition? definition;
  final NabiNotificationOccurrence? occurrence;
  final NabiUiContext? uiContext;
  final bool collapsed;
  final bool busy;
  final String? renderedBody;
  final String? errorCode;

  const NabiNotificationPresentationState({
    this.definition,
    this.occurrence,
    this.uiContext,
    this.collapsed = false,
    this.busy = false,
    this.renderedBody,
    this.errorCode,
  });

  bool get hasNotification => definition != null && occurrence != null;

  NabiNotificationPresentationState copyWith({
    NabiNotificationDefinition? definition,
    NabiNotificationOccurrence? occurrence,
    NabiUiContext? uiContext,
    bool? collapsed,
    bool? busy,
    String? renderedBody,
    String? errorCode,
    bool clearNotification = false,
    bool clearError = false,
  }) {
    return NabiNotificationPresentationState(
      definition: clearNotification ? null : definition ?? this.definition,
      occurrence: clearNotification ? null : occurrence ?? this.occurrence,
      uiContext: clearNotification ? null : uiContext ?? this.uiContext,
      collapsed: collapsed ?? this.collapsed,
      busy: busy ?? this.busy,
      renderedBody: clearNotification
          ? null
          : renderedBody ?? this.renderedBody,
      errorCode: clearError ? null : errorCode ?? this.errorCode,
    );
  }
}

final nabiNotificationConfigRepositoryProvider =
    Provider<NabiNotificationConfigRepository>(
      (_) => const BundledNabiNotificationConfigRepository(),
    );

final nabiNotificationStateRepositoryProvider =
    Provider<NabiNotificationStateRepository>(
      (_) => const SqliteNabiNotificationStateRepository(),
    );

final nabiNotificationAnalyticsRepositoryProvider =
    Provider<NabiNotificationAnalyticsRepository>(
      (_) => const SqliteNabiNotificationAnalyticsRepository(),
    );

final nabiNotificationNavigationGatewayProvider = Provider<NabiNavigationGateway>(
  (_) => const _NoopNabiNavigationGateway(),
);

final nabiNativeDeliveryGatewayProvider = Provider<NabiNativeDeliveryGateway>(
  (_) => const _NoopNabiNativeDeliveryGateway(),
);

final nabiNotificationEngineProvider = Provider<NabiNotificationEngine>(
  (_) => const NabiNotificationEngine(),
);

final nabiNotificationControllerProvider =
    NotifierProvider<
      NabiNotificationController,
      NabiNotificationPresentationState
    >(NabiNotificationController.new);

class NabiNotificationController
    extends Notifier<NabiNotificationPresentationState> {
  @override
  NabiNotificationPresentationState build() {
    return const NabiNotificationPresentationState();
  }

  Future<void> evaluate({
    required NabiBusinessSnapshot snapshot,
    required NabiUiContext uiContext,
    NabiNotificationPreferences preferences =
        const NabiNotificationPreferences(),
  }) async {
    if (state.busy || state.hasNotification) return;
    state = state.copyWith(busy: true, clearError: true);
    try {
      final definitions = await ref
          .read(nabiNotificationConfigRepositoryProvider)
          .loadActiveDefinitions();
      final repository = ref.read(nabiNotificationStateRepositoryProvider);
      final history = await repository.loadHistory(snapshot.actorKey);
      final decisions = ref
          .read(nabiNotificationEngineProvider)
          .evaluateAll(
            definitions: definitions,
            snapshot: snapshot,
            uiContext: uiContext,
            preferences: preferences,
            history: history,
            now: snapshot.occurredAt,
          );
      final eligible = decisions.where((decision) => decision.eligible);
      if (eligible.isEmpty) {
        state = state.copyWith(busy: false);
        return;
      }
      final definition = eligible.first.definition;
      final occurrence = await repository.claim(
        definition: definition,
        snapshot: snapshot,
        uiContext: uiContext,
      );
      await repository.updateStatus(
        occurrenceId: occurrence.id,
        status: NabiNotificationStatus.presented,
      );
      final presented = NabiNotificationOccurrence(
        id: occurrence.id,
        actorKey: occurrence.actorKey,
        notificationId: occurrence.notificationId,
        contentVersion: occurrence.contentVersion,
        sourceEventId: occurrence.sourceEventId,
        status: NabiNotificationStatus.presented,
        eligibleAt: occurrence.eligibleAt,
      );
      await _track(
        eventName: 'nabi_notification_shown',
        occurrence: presented,
        uiContext: uiContext,
      );
      state = NabiNotificationPresentationState(
        definition: definition,
        occurrence: presented,
        uiContext: uiContext,
        renderedBody: _render(definition.body, snapshot.variables),
      );
    } catch (_) {
      state = state.copyWith(busy: false, errorCode: 'evaluation_failed');
    }
  }

  Future<void> collapse() async {
    final occurrence = state.occurrence;
    if (occurrence == null) return;
    await ref.read(nabiNotificationStateRepositoryProvider).updateStatus(
      occurrenceId: occurrence.id,
      status: NabiNotificationStatus.collapsed,
    );
    state = state.copyWith(collapsed: true);
  }

  Future<void> reopen() async {
    final occurrence = state.occurrence;
    final uiContext = state.uiContext;
    if (occurrence == null || uiContext == null) return;
    await ref.read(nabiNotificationStateRepositoryProvider).updateStatus(
      occurrenceId: occurrence.id,
      status: NabiNotificationStatus.opened,
    );
    await _track(
      eventName: 'nabi_notification_opened',
      occurrence: occurrence,
      uiContext: uiContext,
    );
    state = state.copyWith(collapsed: false);
  }

  Future<void> dismiss() async {
    final occurrence = state.occurrence;
    final uiContext = state.uiContext;
    if (occurrence == null || uiContext == null) return;
    await ref.read(nabiNotificationStateRepositoryProvider).updateStatus(
      occurrenceId: occurrence.id,
      status: NabiNotificationStatus.cancelled,
    );
    await _track(
      eventName: 'nabi_notification_dismissed',
      occurrence: occurrence,
      uiContext: uiContext,
    );
    state = state.copyWith(clearNotification: true, collapsed: false);
  }

  Future<void> defer() async {
    final occurrence = state.occurrence;
    final uiContext = state.uiContext;
    if (occurrence == null || uiContext == null) return;
    final deferredUntil = DateTime.now().add(const Duration(hours: 24));
    await ref.read(nabiNotificationStateRepositoryProvider).updateStatus(
      occurrenceId: occurrence.id,
      status: NabiNotificationStatus.deferred,
      deferredUntil: deferredUntil,
    );
    await _track(
      eventName: 'nabi_notification_secondary_clicked',
      occurrence: occurrence,
      uiContext: uiContext,
      resultCode: 'deferred',
    );
    state = state.copyWith(clearNotification: true, collapsed: false);
  }

  Future<void> activatePrimary() async {
    final definition = state.definition;
    final occurrence = state.occurrence;
    final uiContext = state.uiContext;
    if (definition == null || occurrence == null || uiContext == null) return;
    state = state.copyWith(busy: true);
    final opened = await ref
        .read(nabiNotificationNavigationGatewayProvider)
        .open(definition.primaryDestination);
    await ref.read(nabiNotificationStateRepositoryProvider).updateStatus(
      occurrenceId: occurrence.id,
      status: opened
          ? NabiNotificationStatus.actioned
          : NabiNotificationStatus.failed,
      errorCode: opened ? null : 'destination_invalid',
    );
    await _track(
      eventName: opened
          ? 'nabi_notification_primary_clicked'
          : 'nabi_notification_failed',
      occurrence: occurrence,
      uiContext: uiContext,
      resultCode: opened ? 'opened' : 'destination_invalid',
    );
    state = state.copyWith(
      clearNotification: opened,
      busy: false,
      errorCode: opened ? null : 'destination_invalid',
      clearError: opened,
    );
  }

  Future<void> activateSecondary() async {
    final destination = state.definition?.secondaryDestination;
    if (destination == null || destination.actionKey == 'defer') {
      await defer();
      return;
    }
    final occurrence = state.occurrence;
    final uiContext = state.uiContext;
    if (occurrence == null || uiContext == null) return;
    final opened = await ref
        .read(nabiNotificationNavigationGatewayProvider)
        .open(destination);
    await _track(
      eventName: 'nabi_notification_secondary_clicked',
      occurrence: occurrence,
      uiContext: uiContext,
      resultCode: opened ? 'opened' : 'destination_invalid',
    );
    if (opened) state = state.copyWith(clearNotification: true);
  }

  Future<void> _track({
    required String eventName,
    required NabiNotificationOccurrence occurrence,
    required NabiUiContext uiContext,
    String? resultCode,
  }) {
    return ref.read(nabiNotificationAnalyticsRepositoryProvider).append(
      eventName: eventName,
      occurrence: occurrence,
      uiContext: uiContext,
      resultCode: resultCode,
    );
  }

  String _render(String template, Map<String, String> variables) {
    var rendered = template;
    for (final entry in variables.entries) {
      rendered = rendered.replaceAll('{${entry.key}}', entry.value);
    }
    return rendered;
  }
}

class InMemoryNabiBusinessEventBus implements NabiBusinessEventBus {
  final StreamController<NabiBusinessSnapshot> _controller =
      StreamController<NabiBusinessSnapshot>.broadcast();

  @override
  Stream<NabiBusinessSnapshot> get events => _controller.stream;

  @override
  void emit(NabiBusinessSnapshot snapshot) => _controller.add(snapshot);

  Future<void> dispose() => _controller.close();
}

class _NoopNabiNavigationGateway implements NabiNavigationGateway {
  const _NoopNabiNavigationGateway();

  @override
  Future<bool> open(NabiNotificationDestination destination) async => false;
}

class _NoopNabiNativeDeliveryGateway implements NabiNativeDeliveryGateway {
  const _NoopNabiNativeDeliveryGateway();

  @override
  Future<void> cancel(String occurrenceId) async {}

  @override
  Future<void> schedule({
    required NabiNotificationOccurrence occurrence,
    required NabiNotificationDefinition definition,
    required DateTime deliveryAt,
  }) async {}
}
