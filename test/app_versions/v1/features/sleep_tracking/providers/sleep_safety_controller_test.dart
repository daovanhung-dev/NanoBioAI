import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/data/gateways/sleep_safety_native_gateway.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/domain/entities/safety_contact.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/domain/entities/sleep_safety_event.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/domain/entities/sleep_night_analysis.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/domain/entities/sleep_safety_preference.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/domain/entities/sleep_safety_session.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/domain/repositories/sleep_safety_repository.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/domain/services/sleep_safety_state_machine.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/providers/sleep_safety_providers.dart';
import 'package:nano_app/app_versions/v2/features/auth/providers/auth_providers.dart';

void main() {
  test(
    'Start consumes resolved rollout state without a second remote fetch',
    () async {
      const userId = 'user-1';
      final repository = _FakeSleepSafetyRepository(userId);
      final container = ProviderContainer(
        overrides: [
          currentAuthUserIdProvider.overrideWithValue(userId),
          sleepSafetyRepositoryProvider.overrideWithValue(repository),
          sleepSafetyRolloutApprovedProvider.overrideWithValue(true),
          sleepSafetyNotificationPermissionProvider.overrideWithValue(
            () async => true,
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(sleepSafetyControllerProvider.notifier);
      await _waitForPreference(container);

      await notifier.startMonitoring();

      expect(repository.rolloutFetchCount, 0);
      expect(repository.microphonePermissionCount, 1);
      expect(repository.nativeStartCount, 1);
      expect(repository.savedSessions, hasLength(1));
    },
  );

  test('Start fails closed when resolved rollout state is false', () async {
    const userId = 'user-1';
    final repository = _FakeSleepSafetyRepository(userId);
    final container = ProviderContainer(
      overrides: [
        currentAuthUserIdProvider.overrideWithValue(userId),
        sleepSafetyRepositoryProvider.overrideWithValue(repository),
        sleepSafetyRolloutApprovedProvider.overrideWithValue(false),
        sleepSafetyNotificationPermissionProvider.overrideWithValue(
          () async => true,
        ),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(sleepSafetyControllerProvider.notifier);
    await _waitForPreference(container);

    await notifier.startMonitoring();

    expect(repository.rolloutFetchCount, 0);
    expect(repository.microphonePermissionCount, 0);
    expect(repository.nativeStartCount, 0);
    expect(
      container.read(sleepSafetyControllerProvider).errorMessage,
      contains('tạm dừng'),
    );
  });

  test('Microphone denial stops before native monitoring', () async {
    const userId = 'user-1';
    final repository = _FakeSleepSafetyRepository(
      userId,
      microphoneGranted: false,
    );
    final container = ProviderContainer(
      overrides: [
        currentAuthUserIdProvider.overrideWithValue(userId),
        sleepSafetyRepositoryProvider.overrideWithValue(repository),
        sleepSafetyRolloutApprovedProvider.overrideWithValue(true),
        sleepSafetyNotificationPermissionProvider.overrideWithValue(
          () async => true,
        ),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(sleepSafetyControllerProvider.notifier);
    await _waitForPreference(container);
    await notifier.startMonitoring();

    expect(repository.microphonePermissionCount, 1);
    expect(repository.nativeStartCount, 0);
    expect(
      container.read(sleepSafetyControllerProvider).errorMessage,
      contains('quyền micro'),
    );
  });

  test('Notification denial stops before native monitoring', () async {
    const userId = 'user-1';
    final repository = _FakeSleepSafetyRepository(userId);
    final container = ProviderContainer(
      overrides: [
        currentAuthUserIdProvider.overrideWithValue(userId),
        sleepSafetyRepositoryProvider.overrideWithValue(repository),
        sleepSafetyRolloutApprovedProvider.overrideWithValue(true),
        sleepSafetyNotificationPermissionProvider.overrideWithValue(
          () async => false,
        ),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(sleepSafetyControllerProvider.notifier);
    await _waitForPreference(container);
    await notifier.startMonitoring();

    expect(repository.microphonePermissionCount, 1);
    expect(repository.nativeStartCount, 0);
    expect(
      container.read(sleepSafetyControllerProvider).errorMessage,
      contains('quyền thông báo'),
    );
  });

  test(
    'Native foreground-service rejection fails safely and closes session',
    () async {
      const userId = 'user-1';
      final repository = _FakeSleepSafetyRepository(
        userId,
        nativeStartErrorCode: 'microphone_fgs_not_allowed',
      );
      final container = ProviderContainer(
        overrides: [
          currentAuthUserIdProvider.overrideWithValue(userId),
          sleepSafetyRepositoryProvider.overrideWithValue(repository),
          sleepSafetyRolloutApprovedProvider.overrideWithValue(true),
          sleepSafetyNotificationPermissionProvider.overrideWithValue(
            () async => true,
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(sleepSafetyControllerProvider.notifier);
      await _waitForPreference(container);
      await notifier.startMonitoring();

      final viewState = container.read(sleepSafetyControllerProvider);
      expect(repository.nativeStartCount, 1);
      expect(repository.savedSessions, hasLength(2));
      expect(
        repository.savedSessions.last.status,
        SleepSafetySessionStatus.failed,
      );
      expect(
        repository.savedSessions.last.stopReason,
        'microphone_fgs_not_allowed',
      );
      expect(viewState.monitoringActive, isFalse);
      expect(viewState.isBusy, isFalse);
      expect(viewState.errorMessage, contains('Android chưa cho phép'));
    },
  );

  test('Live native audio metrics reach transient controller state', () async {
    const userId = 'user-1';
    final repository = _FakeSleepSafetyRepository(userId);
    final container = ProviderContainer(
      overrides: [
        currentAuthUserIdProvider.overrideWithValue(userId),
        sleepSafetyRepositoryProvider.overrideWithValue(repository),
        sleepSafetyRolloutApprovedProvider.overrideWithValue(true),
        sleepSafetyNotificationPermissionProvider.overrideWithValue(
          () async => true,
        ),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(sleepSafetyControllerProvider.notifier);
    await _waitForPreference(container);
    await notifier.startMonitoring();

    repository.emitNative(
      const SleepSafetyNativeEvent(type: 'serviceStarted', data: {}),
    );
    repository.emitNative(
      const SleepSafetyNativeEvent(
        type: 'audioMetrics',
        data: {
          'signalLevel': 0.72,
          'peakLevel': 0.91,
          'relativeEnergy': 5.4,
          'baselineLevel': 0.18,
          'phase': 'candidate',
        },
      ),
    );

    final viewState = container.read(sleepSafetyControllerProvider);
    expect(viewState.audioMetrics, isNotNull);
    expect(viewState.audioMetrics!.signalLevel, closeTo(0.72, 0.001));
    expect(viewState.audioMetrics!.peakLevel, closeTo(0.91, 0.001));
    expect(viewState.audioMetrics!.relativeEnergy, closeTo(5.4, 0.001));
    expect(viewState.audioMetrics!.phase, 'candidate');
    expect(viewState.audioSignalStale, isFalse);

    repository.emitNative(
      const SleepSafetyNativeEvent(
        type: 'detectorCandidate',
        data: {'eventType': 'abnormalScream'},
      ),
    );
    expect(
      container.read(sleepSafetyControllerProvider).detectorCandidateType,
      'abnormalScream',
    );

    await notifier.stopMonitoring();
    expect(container.read(sleepSafetyControllerProvider).audioMetrics, isNull);
  });

  test(
    'Calibration safety bypass opens alert and calibration completion does not dismiss it',
    () async {
      const userId = 'user-1';
      final repository = _FakeSleepSafetyRepository(userId);
      final container = ProviderContainer(
        overrides: [
          currentAuthUserIdProvider.overrideWithValue(userId),
          sleepSafetyRepositoryProvider.overrideWithValue(repository),
          sleepSafetyRolloutApprovedProvider.overrideWithValue(true),
          sleepSafetyNotificationPermissionProvider.overrideWithValue(
            () async => true,
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(sleepSafetyControllerProvider.notifier);
      await _waitForPreference(container);
      await notifier.startMonitoring();
      repository.emitNative(
        const SleepSafetyNativeEvent(type: 'serviceStarted', data: {}),
      );
      expect(
        container.read(sleepSafetyControllerProvider).machine.phase,
        SleepSafetyPhase.calibrating,
      );

      repository.emitNative(
        const SleepSafetyNativeEvent(
          type: 'confirmedSafetyEvent',
          data: {
            'eventId': 'calibration-alert-1',
            'detectedAt': '2026-08-24T04:00:00Z',
            'eventType': 'abnormalScream',
            'severity': 'high',
            'confidence': 0.95,
            'relativeEnergy': 8.0,
            'baselineDelta': 0.12,
            'repetitionCount': 1,
          },
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(sleepSafetyControllerProvider).machine.phase,
        SleepSafetyPhase.awaitingResponse,
      );
      expect(
        container.read(sleepSafetyControllerProvider).currentEvent?.id,
        'calibration-alert-1',
      );

      repository.emitNative(
        const SleepSafetyNativeEvent(
          type: 'calibrationCompleted',
          data: {'noiseFloor': 0.008},
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(sleepSafetyControllerProvider).machine.phase,
        SleepSafetyPhase.awaitingResponse,
      );
    },
  );

  test(
    'Contact save keeps the RPC result when refresh returns stale cache',
    () async {
      const userId = 'user-1';
      final savedContact = _contact(id: 'contact-new', priority: 2);
      final repository = _FakeSleepSafetyRepository(
        userId,
        cachedContacts: [_contact(id: 'contact-old', priority: 1)],
        savedContact: savedContact,
      );
      final container = ProviderContainer(
        overrides: [
          currentAuthUserIdProvider.overrideWithValue(userId),
          sleepSafetyRepositoryProvider.overrideWithValue(repository),
          sleepSafetyRolloutApprovedProvider.overrideWithValue(true),
          sleepSafetyNotificationPermissionProvider.overrideWithValue(
            () async => true,
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(sleepSafetyControllerProvider.notifier);
      await _waitForPreference(container);
      await notifier.saveContact(
        name: '  Mẹ  ',
        relationship: 'Mẹ',
        phoneE164: '0901234567',
        priority: 1,
      );

      final contacts = container.read(sleepSafetyControllerProvider).contacts;
      expect(contacts.map((contact) => contact.id), contains('contact-new'));
      expect(repository.lastSavedPriority, 2);
      expect(
        container.read(sleepSafetyControllerProvider).notice,
        contains('Đã lưu'),
      );
    },
  );

  test(
    'Native acknowledgement failure does not block cloud dispatch',
    () async {
      const userId = 'user-1';
      final repository = _FakeSleepSafetyRepository(
        userId,
        respondToAlertError: true,
      );
      final container = ProviderContainer(
        overrides: [
          currentAuthUserIdProvider.overrideWithValue(userId),
          sleepSafetyRepositoryProvider.overrideWithValue(repository),
          sleepSafetyRolloutApprovedProvider.overrideWithValue(true),
          sleepSafetyNotificationPermissionProvider.overrideWithValue(
            () async => true,
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(sleepSafetyControllerProvider.notifier);
      await _waitForPreference(container);
      await notifier.startMonitoring();
      repository.emitNative(
        const SleepSafetyNativeEvent(type: 'serviceStarted', data: {}),
      );
      repository.emitNative(
        const SleepSafetyNativeEvent(
          type: 'confirmedSafetyEvent',
          data: {
            'eventId': 'dispatch-native-error',
            'detectedAt': '2026-08-24T04:00:00Z',
            'eventType': 'abnormalScream',
            'severity': 'high',
            'confidence': 0.95,
          },
        ),
      );
      await _waitForCurrentEvent(container);

      await notifier.requestHelp();
      expect(repository.dispatchCount, 1);
      expect(repository.dismissAlertCount, 1);
      expect(
        container
            .read(sleepSafetyControllerProvider)
            .currentEvent
            ?.escalationStatus,
        SleepSafetyEscalationStatus.accepted,
      );
    },
  );

  test(
    'Provider failure exposes retry state and retries idempotently',
    () async {
      const userId = 'user-1';
      final repository = _FakeSleepSafetyRepository(
        userId,
        dispatchFailuresRemaining: 2,
      );
      final container = ProviderContainer(
        overrides: [
          currentAuthUserIdProvider.overrideWithValue(userId),
          sleepSafetyRepositoryProvider.overrideWithValue(repository),
          sleepSafetyRolloutApprovedProvider.overrideWithValue(true),
          sleepSafetyNotificationPermissionProvider.overrideWithValue(
            () async => true,
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(sleepSafetyControllerProvider.notifier);
      await _waitForPreference(container);
      await notifier.startMonitoring();
      repository.emitNative(
        const SleepSafetyNativeEvent(type: 'serviceStarted', data: {}),
      );
      repository.emitNative(
        const SleepSafetyNativeEvent(
          type: 'confirmedSafetyEvent',
          data: {
            'eventId': 'dispatch-retry',
            'detectedAt': '2026-08-24T04:00:00Z',
            'eventType': 'abnormalScream',
            'severity': 'high',
            'confidence': 0.95,
          },
        ),
      );
      await _waitForCurrentEvent(container);

      await notifier.requestHelp();
      expect(
        container
            .read(sleepSafetyControllerProvider)
            .currentEvent
            ?.escalationStatus,
        SleepSafetyEscalationStatus.failed,
      );
      await notifier.retryEmergencyDispatch();
      expect(repository.dispatchCount, 3);
      expect(repository.dispatchKeys, [
        'sleep-safety-dispatch-retry',
        'sleep-safety-dispatch-retry',
        'sleep-safety-dispatch-retry',
      ]);
      expect(
        container
            .read(sleepSafetyControllerProvider)
            .currentEvent
            ?.escalationStatus,
        SleepSafetyEscalationStatus.accepted,
      );
    },
  );
}

SafetyContact _contact({required String id, required int priority}) {
  final now = DateTime.utc(2026, 8, 24);
  return SafetyContact(
    id: id,
    userId: 'user-1',
    name: id,
    relationship: 'Gia đình',
    phoneE164: '+84901234567',
    priority: priority,
    verificationStatus: SafetyContactVerificationStatus.verified,
    active: true,
    createdAt: now,
    updatedAt: now,
  );
}

Future<void> _waitForPreference(ProviderContainer container) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    if (container.read(sleepSafetyControllerProvider).preference != null) {
      await Future<void>.delayed(Duration.zero);
      return;
    }
    await Future<void>.delayed(Duration.zero);
  }
  fail('SleepSafetyController did not finish initialization.');
}

Future<void> _waitForCurrentEvent(ProviderContainer container) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    if (container.read(sleepSafetyControllerProvider).currentEvent != null) {
      return;
    }
    await Future<void>.delayed(Duration.zero);
  }
  fail('SleepSafetyController did not record the native safety event.');
}

class _FakeSleepSafetyRepository implements SleepSafetyRepository {
  _FakeSleepSafetyRepository(
    this.userId, {
    this.microphoneGranted = true,
    this.nativeStartErrorCode,
    this.cachedContacts = const [],
    this.savedContact,
    this.respondToAlertError = false,
    this.dispatchFailuresRemaining = 0,
  });

  final String userId;
  final bool microphoneGranted;
  final String? nativeStartErrorCode;
  final List<SafetyContact> cachedContacts;
  final SafetyContact? savedContact;
  final bool respondToAlertError;
  int dispatchFailuresRemaining;
  int rolloutFetchCount = 0;
  int microphonePermissionCount = 0;
  int nativeStartCount = 0;
  int lastSavedPriority = 0;
  int dispatchCount = 0;
  int dismissAlertCount = 0;
  final List<String> dispatchKeys = [];
  final List<SleepSafetySession> savedSessions = [];
  final StreamController<SleepSafetyNativeEvent> _nativeController =
      StreamController<SleepSafetyNativeEvent>.broadcast(sync: true);

  @override
  Stream<SleepSafetyNativeEvent> get nativeEvents => _nativeController.stream;

  void emitNative(SleepSafetyNativeEvent event) {
    _nativeController.add(event);
  }

  @override
  Future<bool> ensureMicrophonePermission() async {
    microphonePermissionCount += 1;
    return microphoneGranted;
  }

  @override
  Future<bool> isRolloutEnabled() async {
    rolloutFetchCount += 1;
    return true;
  }

  @override
  Future<SleepSafetyPreference> loadPreference(String userId) async {
    return SleepSafetyPreference.defaults(userId);
  }

  @override
  Future<List<SafetyContact>> loadContacts(
    String userId, {
    bool refreshCloud = true,
  }) async => cachedContacts;

  @override
  Future<List<SleepSafetyEvent>> listEvents(String userId) async => const [];

  @override
  Future<void> saveSession(SleepSafetySession value) async {
    savedSessions.add(value);
  }

  @override
  Future<void> startNative(Map<String, Object?> config) async {
    nativeStartCount += 1;
    final errorCode = nativeStartErrorCode;
    if (errorCode != null) {
      throw SleepSafetyNativeStartException(errorCode);
    }
  }

  @override
  Future<void> stopNative(String reason) async {}

  @override
  Future<void> respondToAlert(String eventId, String response) async {
    if (respondToAlertError) throw StateError('native_channel_unavailable');
  }

  @override
  Future<void> dismissAlert(String eventId) async {
    dismissAlertCount += 1;
  }

  @override
  Future<void> updateNativeConfig(Map<String, Object?> config) async {}

  @override
  Future<void> savePreference(SleepSafetyPreference value) async {}

  @override
  Future<SleepSafetySession?> getSession(String id) async => null;

  @override
  Future<void> updateSession(String id, Map<String, Object?> values) async {}

  @override
  Future<void> saveEvent(SleepSafetyEvent value) async {}

  @override
  Future<SleepSafetyEvent?> getEvent(String id) async => null;

  @override
  Future<void> updateEvent(String id, Map<String, Object?> values) async {}

  @override
  Future<List<SleepSafetySession>> listSessions(
    String userId, {
    int limit = 14,
  }) async {
    return const [];
  }

  @override
  Future<List<SleepSafetyEvent>> listEventsForSession(String sessionId) async {
    return const [];
  }

  @override
  Future<SleepNightAnalysis?> getNightAnalysis(String sessionId) async {
    return null;
  }

  @override
  Future<void> saveNightAnalysis(SleepNightAnalysis analysis) async {}

  @override
  Future<SafetyContact> saveContact({
    String? id,
    required String name,
    required String relationship,
    required String phoneE164,
    required int priority,
  }) async {
    lastSavedPriority = priority;
    return savedContact ??
        _contact(id: id ?? 'contact-new', priority: priority);
  }

  @override
  Future<void> deleteContact(String id) async {}

  @override
  Future<void> cacheContact(SafetyContact value) async {}

  @override
  Future<void> requestContactVerification(String id) async {}

  @override
  Future<void> confirmContactVerification(String id, String code) async {}

  @override
  Future<Map<String, Object?>> dispatchEmergency(
    String eventId,
    String idempotencyKey,
  ) async {
    dispatchCount += 1;
    dispatchKeys.add(idempotencyKey);
    if (dispatchFailuresRemaining > 0) {
      dispatchFailuresRemaining -= 1;
      throw StateError('provider_unavailable');
    }
    return const {'status': 'accepted'};
  }
}
