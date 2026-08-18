import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/features/nabi/application/notifications/nabi_notification_controller.dart';
import 'package:nano_app/features/nabi/domain/notifications/nabi_notification_models.dart';
import 'package:nano_app/features/nabi/domain/notifications/nabi_notification_repositories.dart';

void main() {
  const definition = NabiNotificationDefinition(
    id: 'test-secondary',
    contentVersion: 1,
    category: NabiNotificationCategory.milestone,
    priority: 100,
    policyKey: 'first_streak_7',
    title: 'Test',
    body: 'Test body',
    emotionKey: 'happy',
    primaryDestination: NabiNotificationDestination(actionKey: 'primary'),
    secondaryDestination: NabiNotificationDestination(actionKey: 'achievement'),
    primaryLabel: 'Primary',
    secondaryLabel: 'Secondary',
    channels: {NabiNotificationChannel.inApp},
    audiences: {'free'},
    proactive: false,
  );

  final snapshot = NabiBusinessSnapshot(
    actorKey: 'user-1',
    actorKind: 'member',
    membershipPlan: 'free',
    sourceEventId: 'event-1',
    occurredAt: DateTime(2026, 8, 17, 12),
    firstStreakSeven: true,
  );
  const uiContext = NabiUiContext(
    sessionId: 'session-1',
    screenKey: 'dashboard',
    screenInstanceId: 'dashboard-1',
  );

  test('secondary navigation success persists actioned', () async {
    final stateRepository = _FakeStateRepository();
    final navigation = _FakeNavigationGateway(result: true);
    final container = _container(
      definition: definition,
      stateRepository: stateRepository,
      navigation: navigation,
    );
    addTearDown(container.dispose);

    final controller = container.read(nabiNotificationControllerProvider.notifier);
    await controller.evaluate(snapshot: snapshot, uiContext: uiContext);
    await controller.activateSecondary();

    expect(stateRepository.statuses.last.status, NabiNotificationStatus.actioned);
    expect(navigation.calls, 1);
    expect(container.read(nabiNotificationControllerProvider).hasNotification, isFalse);
  });

  test('secondary navigation failure persists failed and keeps bubble', () async {
    final stateRepository = _FakeStateRepository();
    final navigation = _FakeNavigationGateway(result: false);
    final container = _container(
      definition: definition,
      stateRepository: stateRepository,
      navigation: navigation,
    );
    addTearDown(container.dispose);

    final controller = container.read(nabiNotificationControllerProvider.notifier);
    await controller.evaluate(snapshot: snapshot, uiContext: uiContext);
    await controller.activateSecondary();

    expect(stateRepository.statuses.last.status, NabiNotificationStatus.failed);
    expect(stateRepository.statuses.last.errorCode, 'destination_invalid');
    expect(container.read(nabiNotificationControllerProvider).hasNotification, isTrue);
    expect(container.read(nabiNotificationControllerProvider).errorCode, 'destination_invalid');
  });


  test('secondary defer keeps M30 24-hour deferred state', () async {
    const deferDefinition = NabiNotificationDefinition(
      id: 'test-defer',
      contentVersion: 1,
      category: NabiNotificationCategory.milestone,
      priority: 100,
      policyKey: 'first_streak_7',
      title: 'Test',
      body: 'Test body',
      emotionKey: 'happy',
      primaryDestination: NabiNotificationDestination(actionKey: 'primary'),
      secondaryDestination: NabiNotificationDestination(actionKey: 'defer'),
      primaryLabel: 'Primary',
      secondaryLabel: 'Để sau',
      channels: {NabiNotificationChannel.inApp},
      audiences: {'free'},
      proactive: false,
    );
    final stateRepository = _FakeStateRepository();
    final navigation = _FakeNavigationGateway(result: true);
    final container = _container(
      definition: deferDefinition,
      stateRepository: stateRepository,
      navigation: navigation,
    );
    addTearDown(container.dispose);

    final controller = container.read(nabiNotificationControllerProvider.notifier);
    await controller.evaluate(snapshot: snapshot, uiContext: uiContext);
    final before = DateTime.now();
    await controller.activateSecondary();

    final write = stateRepository.statuses.last;
    expect(write.status, NabiNotificationStatus.deferred);
    expect(write.deferredUntil, isNotNull);
    expect(write.deferredUntil!.isAfter(before.add(const Duration(hours: 23))), isTrue);
    expect(navigation.calls, 0);
  });

  test('secondary double tap dispatches navigation once', () async {
    final stateRepository = _FakeStateRepository();
    final navigation = _CompleterNavigationGateway();
    final container = _container(
      definition: definition,
      stateRepository: stateRepository,
      navigation: navigation,
    );
    addTearDown(container.dispose);

    final controller = container.read(nabiNotificationControllerProvider.notifier);
    await controller.evaluate(snapshot: snapshot, uiContext: uiContext);

    final first = controller.activateSecondary();
    await Future<void>.delayed(Duration.zero);
    final second = controller.activateSecondary();

    expect(navigation.calls, 1);
    navigation.complete(true);
    await Future.wait([first, second]);
    expect(stateRepository.statuses.last.status, NabiNotificationStatus.actioned);
  });
}

ProviderContainer _container({
  required NabiNotificationDefinition definition,
  required _FakeStateRepository stateRepository,
  required NabiNavigationGateway navigation,
}) {
  return ProviderContainer(
    overrides: [
      nabiNotificationConfigRepositoryProvider.overrideWithValue(
        _FakeConfigRepository(definition),
      ),
      nabiNotificationStateRepositoryProvider.overrideWithValue(stateRepository),
      nabiNotificationAnalyticsRepositoryProvider.overrideWithValue(
        _FakeAnalyticsRepository(),
      ),
      nabiNotificationNavigationGatewayProvider.overrideWithValue(navigation),
    ],
  );
}

class _FakeConfigRepository implements NabiNotificationConfigRepository {
  const _FakeConfigRepository(this.definition);

  final NabiNotificationDefinition definition;

  @override
  Future<List<NabiNotificationDefinition>> loadActiveDefinitions() async => [definition];
}

class _StatusWrite {
  const _StatusWrite(this.status, this.errorCode, this.deferredUntil);

  final NabiNotificationStatus status;
  final String? errorCode;
  final DateTime? deferredUntil;
}

class _FakeStateRepository implements NabiNotificationStateRepository {
  final List<_StatusWrite> statuses = [];

  @override
  Future<NabiNotificationOccurrence> claim({
    required NabiNotificationDefinition definition,
    required NabiBusinessSnapshot snapshot,
    required NabiUiContext uiContext,
  }) async {
    return NabiNotificationOccurrence(
      id: 'occurrence-1',
      actorKey: snapshot.actorKey,
      notificationId: definition.id,
      contentVersion: definition.contentVersion,
      sourceEventId: snapshot.sourceEventId,
      status: NabiNotificationStatus.eligible,
      eligibleAt: snapshot.occurredAt,
    );
  }

  @override
  Future<List<NabiNotificationHistoryEntry>> loadHistory(String actorKey) async => [];

  @override
  Future<void> updateStatus({
    required String occurrenceId,
    required NabiNotificationStatus status,
    DateTime? deferredUntil,
    String? errorCode,
  }) async {
    statuses.add(_StatusWrite(status, errorCode, deferredUntil));
  }
}

class _FakeAnalyticsRepository implements NabiNotificationAnalyticsRepository {
  @override
  Future<void> append({
    required String eventName,
    required NabiNotificationOccurrence occurrence,
    required NabiUiContext uiContext,
    String? resultCode,
  }) async {}

  @override
  Future<int> drainPending() async => 0;
}

class _FakeNavigationGateway implements NabiNavigationGateway {
  _FakeNavigationGateway({required this.result});

  final bool result;
  int calls = 0;

  @override
  Future<bool> open(NabiNotificationDestination destination) async {
    calls++;
    return result;
  }
}

class _CompleterNavigationGateway implements NabiNavigationGateway {
  final Completer<bool> _completer = Completer<bool>();
  int calls = 0;

  void complete(bool value) => _completer.complete(value);

  @override
  Future<bool> open(NabiNotificationDestination destination) {
    calls++;
    return _completer.future;
  }
}
