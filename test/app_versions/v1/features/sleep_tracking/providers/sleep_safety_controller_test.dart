import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/data/gateways/sleep_safety_native_gateway.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/data/gateways/sleep_safety_connectivity_gateway.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/data/gateways/sleep_safety_phone_gateway.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/domain/entities/safety_contact.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/domain/entities/sleep_safety_dispatch_retry.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/domain/entities/sleep_safety_dispatch_result.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/domain/entities/sleep_safety_event.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/domain/entities/sleep_night_analysis.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/domain/entities/sleep_safety_preference.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/domain/entities/sleep_safety_runtime_config.dart';
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
          sleepSafetyConnectivityGatewayProvider.overrideWithValue(
            const _NoopSleepSafetyConnectivity(),
          ),
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
        sleepSafetyConnectivityGatewayProvider.overrideWithValue(
          const _NoopSleepSafetyConnectivity(),
        ),
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
        sleepSafetyConnectivityGatewayProvider.overrideWithValue(
          const _NoopSleepSafetyConnectivity(),
        ),
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
        sleepSafetyConnectivityGatewayProvider.overrideWithValue(
          const _NoopSleepSafetyConnectivity(),
        ),
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
          sleepSafetyConnectivityGatewayProvider.overrideWithValue(
            const _NoopSleepSafetyConnectivity(),
          ),
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
        sleepSafetyConnectivityGatewayProvider.overrideWithValue(
          const _NoopSleepSafetyConnectivity(),
        ),
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
          sleepSafetyConnectivityGatewayProvider.overrideWithValue(
            const _NoopSleepSafetyConnectivity(),
          ),
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
      final savedContact = _contact(
        id: 'contact-new',
        priority: 2,
        allowUnverifiedVoiceAlert: true,
      );
      final repository = _FakeSleepSafetyRepository(
        userId,
        cachedContacts: [_contact(id: 'contact-old', priority: 1)],
        savedContact: savedContact,
      );
      final container = ProviderContainer(
        overrides: [
          currentAuthUserIdProvider.overrideWithValue(userId),
          sleepSafetyRepositoryProvider.overrideWithValue(repository),
          sleepSafetyConnectivityGatewayProvider.overrideWithValue(
            const _NoopSleepSafetyConnectivity(),
          ),
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
        allowUnverifiedVoiceAlert: true,
      );

      final contacts = container.read(sleepSafetyControllerProvider).contacts;
      expect(contacts.map((contact) => contact.id), contains('contact-new'));
      expect(repository.lastSavedPriority, 2);
      expect(repository.lastSavedUnverifiedVoiceAlert, isTrue);
      expect(
        contacts
            .singleWhere((contact) => contact.id == 'contact-new')
            .allowUnverifiedVoiceAlert,
        isTrue,
      );
      expect(
        container.read(sleepSafetyControllerProvider).notice,
        contains('Đã lưu'),
      );
    },
  );

  test(
    'Contact save waits for the initial contact load before choosing priority',
    () async {
      const userId = 'user-1';
      final existingContact = _contact(id: 'contact-existing', priority: 1);
      final contactsLoad = Completer<List<SafetyContact>>();
      final repository = _FakeSleepSafetyRepository(
        userId,
        cachedContacts: [existingContact],
        contactsLoadFuture: contactsLoad.future,
      );
      final container = ProviderContainer(
        overrides: [
          currentAuthUserIdProvider.overrideWithValue(userId),
          sleepSafetyRepositoryProvider.overrideWithValue(repository),
          sleepSafetyConnectivityGatewayProvider.overrideWithValue(
            const _NoopSleepSafetyConnectivity(),
          ),
          sleepSafetyRolloutApprovedProvider.overrideWithValue(true),
          sleepSafetyNotificationPermissionProvider.overrideWithValue(
            () async => true,
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(sleepSafetyControllerProvider.notifier);
      expect(
        container.read(sleepSafetyControllerProvider).contactsLoaded,
        isFalse,
      );
      final saveExpectation = expectLater(
        notifier.saveContact(
          name: 'Người thử nghiệm',
          relationship: 'QA',
          phoneE164: '+12025550100',
          priority: 1,
        ),
        completes,
      );
      await Future<void>.delayed(Duration.zero);
      contactsLoad.complete([existingContact]);
      await saveExpectation;

      final state = container.read(sleepSafetyControllerProvider);
      expect(state.contactsLoaded, isTrue);
      expect(repository.lastSavedPriority, 2);
      expect(
        state.contacts.map((contact) => contact.id),
        contains('contact-new'),
      );
    },
  );

  test(
    'Help directly calls the highest-priority opted-in contact without dispatch',
    () async {
      const userId = 'user-1';
      final repository = _FakeSleepSafetyRepository(
        userId,
        cachedContacts: [
          _contact(id: 'priority-3', priority: 3),
          _contact(id: 'priority-2', priority: 2),
          _contact(
            id: 'priority-1-disabled',
            priority: 1,
            allowPhoneFallback: false,
          ),
        ],
      );
      final phone = _FakeSleepSafetyPhoneGateway(directCalling: true);
      final container = ProviderContainer(
        overrides: [
          currentAuthUserIdProvider.overrideWithValue(userId),
          sleepSafetyRepositoryProvider.overrideWithValue(repository),
          sleepSafetyConnectivityGatewayProvider.overrideWithValue(
            const _NoopSleepSafetyConnectivity(),
          ),
          sleepSafetyRolloutApprovedProvider.overrideWithValue(true),
          sleepSafetyNotificationPermissionProvider.overrideWithValue(
            () async => true,
          ),
          sleepSafetyPhoneGatewayProvider.overrideWithValue(phone),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(sleepSafetyControllerProvider.notifier);
      await _waitForPreference(container);
      await notifier.startMonitoring();
      expect(phone.permissionRequestCount, 1);
      expect(phone.operations, ['permission']);
      repository.emitNative(
        const SleepSafetyNativeEvent(type: 'serviceStarted', data: {}),
      );
      repository.emitNative(
        SleepSafetyNativeEvent(
          type: 'confirmedSafetyEvent',
          data: {
            'eventId': 'manual-help-direct-call',
            'detectedAt': DateTime.now().toUtc().toIso8601String(),
            'eventType': 'abnormalScream',
            'severity': 'high',
            'confidence': 0.95,
          },
        ),
      );
      await _waitForCurrentEvent(container);

      await notifier.requestHelp();
      final state = container.read(sleepSafetyControllerProvider);
      expect(phone.lastStartedNumber, '+84901234567');
      expect(phone.lastStartedEventId, 'manual-help-direct-call');
      expect(phone.lastDialedNumber, isNull);
      expect(phone.operations, ['permission', 'direct_call']);
      expect(state.notice, contains('priority-2'));
      expect(repository.dispatchCount, 0);
      expect(repository.retries, isEmpty);
      expect(state.currentEvent?.response, SleepSafetyResponse.needHelp);
      expect(state.currentEvent?.escalationRequired, isFalse);
      expect(
        state.currentEvent?.escalationStatus,
        SleepSafetyEscalationStatus.notRequired,
      );
      expect(state.currentEvent?.state, 'manual_call_started');
      expect(state.notice, contains('chưa được xác nhận'));
      expect(state.machine.phase, SleepSafetyPhase.monitoring);
    },
  );

  test(
    'Denied call permission opens the dialer with the selected contact',
    () async {
      const userId = 'user-1';
      final repository = _FakeSleepSafetyRepository(
        userId,
        cachedContacts: [_contact(id: 'contact-1', priority: 1)],
        phoneFallbackEnabled: false,
      );
      final phone = _FakeSleepSafetyPhoneGateway(
        directCalling: true,
        permissionGranted: false,
      );
      final container = ProviderContainer(
        overrides: [
          currentAuthUserIdProvider.overrideWithValue(userId),
          sleepSafetyRepositoryProvider.overrideWithValue(repository),
          sleepSafetyConnectivityGatewayProvider.overrideWithValue(
            const _NoopSleepSafetyConnectivity(),
          ),
          sleepSafetyRolloutApprovedProvider.overrideWithValue(true),
          sleepSafetyNotificationPermissionProvider.overrideWithValue(
            () async => true,
          ),
          sleepSafetyPhoneGatewayProvider.overrideWithValue(phone),
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
            'eventId': 'manual-help-permission-denied',
            'detectedAt': '2026-10-06T04:00:00Z',
            'eventType': 'abnormalScream',
            'severity': 'high',
            'confidence': 0.95,
          },
        ),
      );
      await _waitForCurrentEvent(container);

      await notifier.requestHelp();

      expect(phone.permissionRequestCount, 1);
      expect(phone.lastStartedNumber, isNull);
      expect(phone.lastDialedNumber, '+84901234567');
      expect(phone.lastDialedEventId, 'manual-help-permission-denied');
      expect(phone.operations, ['permission', 'dialer']);
      expect(
        container.read(sleepSafetyControllerProvider).currentEvent?.state,
        'manual_call_handoff',
      );
      expect(
        container.read(sleepSafetyControllerProvider).notice,
        contains('bấm Gọi'),
      );
      expect(
        container.read(sleepSafetyControllerProvider).machine.phase,
        SleepSafetyPhase.monitoring,
      );
      expect(repository.dispatchCount, 0);
    },
  );

  test(
    'Manual phone fallback dials an unverified contact with phone fallback enabled',
    () async {
      const userId = 'user-1';
      final repository = _FakeSleepSafetyRepository(
        userId,
        cachedContacts: [
          _contact(
            id: 'contact-pending',
            priority: 1,
            verified: false,
            allowPhoneFallback: true,
          ),
        ],
      );
      final phone = _FakeSleepSafetyPhoneGateway();
      final container = ProviderContainer(
        overrides: [
          currentAuthUserIdProvider.overrideWithValue(userId),
          sleepSafetyRepositoryProvider.overrideWithValue(repository),
          sleepSafetyConnectivityGatewayProvider.overrideWithValue(
            const _NoopSleepSafetyConnectivity(),
          ),
          sleepSafetyRolloutApprovedProvider.overrideWithValue(true),
          sleepSafetyNotificationPermissionProvider.overrideWithValue(
            () async => true,
          ),
          sleepSafetyPhoneGatewayProvider.overrideWithValue(phone),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(sleepSafetyControllerProvider.notifier);
      await _waitForPreference(container);
      await notifier.callPhoneFallback();

      expect(phone.lastDialedNumber, '+84901234567');
      expect(
        container.read(sleepSafetyControllerProvider).notice,
        contains('Cuộc gọi chưa được kết nối'),
      );
    },
  );

  test(
    'Explicit help calls the selected contact when automatic calling is disabled',
    () async {
      const userId = 'user-1';
      final repository = _FakeSleepSafetyRepository(
        userId,
        cachedContacts: [_contact(id: 'contact-verified', priority: 1)],
        phoneFallbackEnabled: false,
      );
      final phone = _FakeSleepSafetyPhoneGateway(directCalling: true);
      final container = ProviderContainer(
        overrides: [
          currentAuthUserIdProvider.overrideWithValue(userId),
          sleepSafetyRepositoryProvider.overrideWithValue(repository),
          sleepSafetyConnectivityGatewayProvider.overrideWithValue(
            const _NoopSleepSafetyConnectivity(),
          ),
          sleepSafetyRolloutApprovedProvider.overrideWithValue(true),
          sleepSafetyNotificationPermissionProvider.overrideWithValue(
            () async => true,
          ),
          sleepSafetyPhoneGatewayProvider.overrideWithValue(phone),
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
            'eventId': 'manual-help-fallback-disabled',
            'detectedAt': '2026-10-06T04:00:00Z',
            'eventType': 'abnormalScream',
            'severity': 'high',
            'confidence': 0.95,
          },
        ),
      );
      await _waitForCurrentEvent(container);
      await notifier.requestHelp();

      final state = container.read(sleepSafetyControllerProvider);
      expect(state.phoneFallbackEnabled, isFalse);
      expect(state.phoneFallbackContact, isNull);
      expect(phone.lastStartedNumber, '+84901234567');
      expect(phone.lastDialedNumber, isNull);
      expect(phone.operations, ['permission', 'direct_call']);
      expect(state.notice, contains('đã yêu cầu điện thoại khởi tạo'));
      expect(state.currentEvent?.response, SleepSafetyResponse.needHelp);
      expect(state.currentEvent?.state, 'manual_call_started');
      expect(state.machine.phase, SleepSafetyPhase.monitoring);
      expect(repository.dispatchCount, 0);
      expect(repository.retries, isEmpty);
    },
  );

  test(
    'No eligible phone contact keeps the help alert and gives guidance',
    () async {
      const userId = 'user-1';
      final repository = _FakeSleepSafetyRepository(userId);
      final phone = _FakeSleepSafetyPhoneGateway(directCalling: true);
      final container = ProviderContainer(
        overrides: [
          currentAuthUserIdProvider.overrideWithValue(userId),
          sleepSafetyRepositoryProvider.overrideWithValue(repository),
          sleepSafetyConnectivityGatewayProvider.overrideWithValue(
            const _NoopSleepSafetyConnectivity(),
          ),
          sleepSafetyRolloutApprovedProvider.overrideWithValue(true),
          sleepSafetyNotificationPermissionProvider.overrideWithValue(
            () async => true,
          ),
          sleepSafetyPhoneGatewayProvider.overrideWithValue(phone),
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
            'eventId': 'manual-help-no-contact',
            'detectedAt': '2026-10-06T04:00:00Z',
            'eventType': 'abnormalScream',
            'severity': 'high',
            'confidence': 0.95,
          },
        ),
      );
      await _waitForCurrentEvent(container);

      await notifier.requestHelp();

      final state = container.read(sleepSafetyControllerProvider);
      expect(phone.permissionRequestCount, 0);
      expect(phone.operations, isEmpty);
      expect(state.errorMessage, contains('Chưa có người liên hệ'));
      expect(state.currentEvent?.response, SleepSafetyResponse.needHelp);
      expect(state.currentEvent?.state, 'manual_call_unavailable');
      expect(state.machine.phase, SleepSafetyPhase.manualHelp);
      expect(repository.dispatchCount, 0);
    },
  );

  test(
    'Failed native call launch falls back to the prefilled dialer',
    () async {
      const userId = 'user-1';
      final repository = _FakeSleepSafetyRepository(
        userId,
        cachedContacts: [_contact(id: 'contact-1', priority: 1)],
      );
      final phone = _FakeSleepSafetyPhoneGateway(
        directCalling: true,
        callStartSucceeds: false,
      );
      final container = ProviderContainer(
        overrides: [
          currentAuthUserIdProvider.overrideWithValue(userId),
          sleepSafetyRepositoryProvider.overrideWithValue(repository),
          sleepSafetyConnectivityGatewayProvider.overrideWithValue(
            const _NoopSleepSafetyConnectivity(),
          ),
          sleepSafetyRolloutApprovedProvider.overrideWithValue(true),
          sleepSafetyNotificationPermissionProvider.overrideWithValue(
            () async => true,
          ),
          sleepSafetyPhoneGatewayProvider.overrideWithValue(phone),
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
            'eventId': 'manual-help-call-launch-failed',
            'detectedAt': '2026-10-06T04:00:00Z',
            'eventType': 'abnormalScream',
            'severity': 'high',
            'confidence': 0.95,
          },
        ),
      );
      await _waitForCurrentEvent(container);

      await notifier.requestHelp();

      expect(phone.lastStartedNumber, '+84901234567');
      expect(phone.lastDialedNumber, '+84901234567');
      expect(phone.operations, ['permission', 'direct_call', 'dialer']);
      expect(repository.dispatchCount, 0);
      expect(
        container.read(sleepSafetyControllerProvider).currentEvent?.state,
        'manual_call_handoff',
      );
      expect(
        container.read(sleepSafetyControllerProvider).machine.phase,
        SleepSafetyPhase.monitoring,
      );
    },
  );

  test(
    'Failed call and dialer launch stop loading and keep an actionable alert',
    () async {
      const userId = 'user-1';
      final repository = _FakeSleepSafetyRepository(
        userId,
        cachedContacts: [_contact(id: 'contact-1', priority: 1)],
      );
      final phone = _FakeSleepSafetyPhoneGateway(
        directCalling: true,
        callStartSucceeds: false,
        dialerOpenSucceeds: false,
      );
      final container = ProviderContainer(
        overrides: [
          currentAuthUserIdProvider.overrideWithValue(userId),
          sleepSafetyRepositoryProvider.overrideWithValue(repository),
          sleepSafetyConnectivityGatewayProvider.overrideWithValue(
            const _NoopSleepSafetyConnectivity(),
          ),
          sleepSafetyRolloutApprovedProvider.overrideWithValue(true),
          sleepSafetyNotificationPermissionProvider.overrideWithValue(
            () async => true,
          ),
          sleepSafetyPhoneGatewayProvider.overrideWithValue(phone),
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
            'eventId': 'manual-help-no-handoff',
            'detectedAt': '2026-10-06T04:00:00Z',
            'eventType': 'abnormalScream',
            'severity': 'high',
            'confidence': 0.95,
          },
        ),
      );
      await _waitForCurrentEvent(container);

      await notifier.requestHelp();

      final state = container.read(sleepSafetyControllerProvider);
      expect(phone.operations, ['permission', 'direct_call', 'dialer']);
      expect(state.currentEvent?.state, 'manual_call_unavailable');
      expect(state.machine.phase, SleepSafetyPhase.manualHelp);
      expect(state.errorMessage, contains('Chưa thể mở cuộc gọi'));
      expect(repository.dispatchCount, 0);
    },
  );

  test(
    'Native acknowledgement failure does not block the direct phone call',
    () async {
      const userId = 'user-1';
      final repository = _FakeSleepSafetyRepository(
        userId,
        respondToAlertError: true,
        cachedContacts: [_contact(id: 'contact-1', priority: 1)],
      );
      final phone = _FakeSleepSafetyPhoneGateway(directCalling: true);
      final container = ProviderContainer(
        overrides: [
          currentAuthUserIdProvider.overrideWithValue(userId),
          sleepSafetyRepositoryProvider.overrideWithValue(repository),
          sleepSafetyConnectivityGatewayProvider.overrideWithValue(
            const _NoopSleepSafetyConnectivity(),
          ),
          sleepSafetyRolloutApprovedProvider.overrideWithValue(true),
          sleepSafetyNotificationPermissionProvider.overrideWithValue(
            () async => true,
          ),
          sleepSafetyPhoneGatewayProvider.overrideWithValue(phone),
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
      expect(repository.dispatchCount, 0);
      expect(repository.dismissAlertCount, 0);
      expect(phone.lastStartedNumber, '+84901234567');
      expect(
        container
            .read(sleepSafetyControllerProvider)
            .currentEvent
            ?.escalationStatus,
        SleepSafetyEscalationStatus.notRequired,
      );
      expect(
        container.read(sleepSafetyControllerProvider).machine.phase,
        SleepSafetyPhase.monitoring,
      );
    },
  );

  test(
    'Provider failure exposes retry state and retries with the same idempotency key',
    () async {
      const userId = 'user-1';
      final repository = _FakeSleepSafetyRepository(
        userId,
        dispatchFailuresRemaining: 1,
        cachedContacts: [_contact(id: 'contact-1', priority: 1)],
      );
      final container = ProviderContainer(
        overrides: [
          currentAuthUserIdProvider.overrideWithValue(userId),
          sleepSafetyRepositoryProvider.overrideWithValue(repository),
          sleepSafetyConnectivityGatewayProvider.overrideWithValue(
            const _NoopSleepSafetyConnectivity(),
          ),
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

      repository.emitNative(
        const SleepSafetyNativeEvent(
          type: 'escalationRequired',
          data: {'eventId': 'dispatch-retry'},
        ),
      );
      await _waitUntil(
        () =>
            container
                .read(sleepSafetyControllerProvider)
                .currentEvent
                ?.escalationStatus ==
            SleepSafetyEscalationStatus.failed,
      );
      expect(
        container
            .read(sleepSafetyControllerProvider)
            .currentEvent
            ?.escalationStatus,
        SleepSafetyEscalationStatus.failed,
      );
      await notifier.retryEmergencyDispatch();
      expect(repository.dispatchCount, 2);
      expect(repository.dispatchKeys, [
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

  test(
    'Offline escalation queues cloud retry and keeps phone call user-triggered',
    () async {
      const userId = 'user-1';
      final repository = _FakeSleepSafetyRepository(
        userId,
        cachedContacts: [_contact(id: 'contact-1', priority: 1)],
      );
      final connectivity = _FakeSleepSafetyConnectivity(false);
      final phone = _FakeSleepSafetyPhoneGateway();
      final container = ProviderContainer(
        overrides: [
          currentAuthUserIdProvider.overrideWithValue(userId),
          sleepSafetyRepositoryProvider.overrideWithValue(repository),
          sleepSafetyRolloutApprovedProvider.overrideWithValue(true),
          sleepSafetyNotificationPermissionProvider.overrideWithValue(
            () async => true,
          ),
          sleepSafetyConnectivityGatewayProvider.overrideWithValue(
            connectivity,
          ),
          sleepSafetyPhoneGatewayProvider.overrideWithValue(phone),
        ],
      );
      addTearDown(() async {
        await connectivity.dispose();
        container.dispose();
      });

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
            'eventId': 'dispatch-offline',
            'detectedAt': '2026-10-06T04:00:00Z',
            'eventType': 'abnormalScream',
            'severity': 'high',
            'confidence': 0.95,
          },
        ),
      );
      await _waitForCurrentEvent(container);

      repository.emitNative(
        const SleepSafetyNativeEvent(
          type: 'escalationRequired',
          data: {'eventId': 'dispatch-offline'},
        ),
      );
      await _waitUntil(
        () =>
            repository.retries.isNotEmpty &&
            repository.retries.values.single.lastErrorCode != null,
      );
      expect(repository.dispatchCount, 0);
      expect(repository.dismissAlertCount, 0);
      expect(
        repository.retries.values.single.lastErrorCode,
        'network_unavailable',
      );

      await notifier.callPhoneFallback();
      expect(phone.lastDialedNumber, '+84901234567');
      expect(repository.dismissAlertCount, 0);
      expect(
        container.read(sleepSafetyControllerProvider).notice,
        contains('Cuộc gọi chưa được kết nối'),
      );
    },
  );
}

SafetyContact _contact({
  required String id,
  required int priority,
  bool verified = true,
  bool allowPhoneFallback = true,
  bool allowUnverifiedVoiceAlert = false,
}) {
  final now = DateTime.utc(2026, 8, 24);
  return SafetyContact(
    id: id,
    userId: 'user-1',
    name: id,
    relationship: 'Gia đình',
    phoneE164: '+84901234567',
    priority: priority,
    verificationStatus: verified
        ? SafetyContactVerificationStatus.verified
        : SafetyContactVerificationStatus.pending,
    active: true,
    createdAt: now,
    updatedAt: now,
    allowPhoneFallback: allowPhoneFallback,
    allowUnverifiedVoiceAlert: allowUnverifiedVoiceAlert,
  );
}

Future<void> _waitForPreference(ProviderContainer container) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    final state = container.read(sleepSafetyControllerProvider);
    if (state.preference != null &&
        state.runtimeConfig != null &&
        state.contactsLoaded) {
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
    this.contactsLoadFuture,
    this.savedContact,
    this.respondToAlertError = false,
    this.dispatchFailuresRemaining = 0,
    this.phoneFallbackEnabled = true,
  });

  final String userId;
  final bool microphoneGranted;
  final String? nativeStartErrorCode;
  List<SafetyContact> cachedContacts;
  final Future<List<SafetyContact>>? contactsLoadFuture;
  final SafetyContact? savedContact;
  final bool respondToAlertError;
  final bool phoneFallbackEnabled;
  int dispatchFailuresRemaining;
  int rolloutFetchCount = 0;
  int microphonePermissionCount = 0;
  int nativeStartCount = 0;
  int lastSavedPriority = 0;
  bool lastSavedUnverifiedVoiceAlert = false;
  int dispatchCount = 0;
  int dismissAlertCount = 0;
  final List<String> dispatchKeys = [];
  final List<SleepSafetySession> savedSessions = [];
  final Map<String, SleepSafetyEvent> savedEvents = {};
  final Map<String, SleepSafetyDispatchRetry> retries = {};
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
  Future<SleepSafetyRuntimeConfig> loadRuntimeConfig() async =>
      SleepSafetyRuntimeConfig(
        enabled: true,
        maxDispatchesPerHour: 3,
        eventFreshnessSeconds: 600,
        phoneFallbackEnabled: phoneFallbackEnabled,
      );

  @override
  Future<void> enqueueEmergencyRetry({
    required String userId,
    required SleepSafetyEvent event,
    required String idempotencyKey,
  }) async {
    final id = 'sleep-safety-retry-${event.id}';
    retries.putIfAbsent(
      id,
      () => SleepSafetyDispatchRetry(
        id: id,
        userId: userId,
        eventId: event.id,
        idempotencyKey: idempotencyKey,
        createdAt: event.detectedAt,
        attemptCount: 0,
        status: 'pending',
      ),
    );
  }

  @override
  Future<List<SleepSafetyDispatchRetry>> listPendingEmergencyRetries() async =>
      retries.values
          .where(
            (row) =>
                row.attemptCount < 4 &&
                (row.status == 'pending' ||
                    row.status == 'sending' ||
                    row.status == 'failed' &&
                        row.lastErrorCode == 'network_unavailable') &&
                (row.nextRetryAt == null ||
                    !row.nextRetryAt!.isAfter(DateTime.now())),
          )
          .toList(growable: false);

  @override
  Future<void> markEmergencyRetrySending(String id) async {
    final row = retries[id]!;
    retries[id] = SleepSafetyDispatchRetry(
      id: row.id,
      userId: row.userId,
      eventId: row.eventId,
      idempotencyKey: row.idempotencyKey,
      createdAt: row.createdAt,
      attemptCount: row.attemptCount + 1,
      status: 'sending',
    );
  }

  @override
  Future<void> markEmergencyRetryAcknowledged(String id) async {
    final row = retries[id]!;
    retries[id] = SleepSafetyDispatchRetry(
      id: row.id,
      userId: row.userId,
      eventId: row.eventId,
      idempotencyKey: row.idempotencyKey,
      createdAt: row.createdAt,
      attemptCount: row.attemptCount,
      status: 'acknowledged',
    );
  }

  @override
  Future<void> markEmergencyRetryFailed({
    required String id,
    required String errorCode,
    DateTime? nextRetryAt,
  }) async {
    final row = retries[id]!;
    retries[id] = SleepSafetyDispatchRetry(
      id: row.id,
      userId: row.userId,
      eventId: row.eventId,
      idempotencyKey: row.idempotencyKey,
      createdAt: row.createdAt,
      attemptCount: row.attemptCount,
      status: 'failed',
      nextRetryAt: nextRetryAt,
      lastErrorCode: errorCode,
    );
  }

  @override
  Future<SleepSafetyPreference> loadPreference(String userId) async {
    return SleepSafetyPreference.defaults(userId);
  }

  @override
  Future<List<SafetyContact>> loadContacts(
    String userId, {
    bool refreshCloud = true,
  }) =>
      contactsLoadFuture ??
      Future<List<SafetyContact>>.value(List<SafetyContact>.of(cachedContacts));

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
  Future<void> saveEvent(SleepSafetyEvent value) async {
    savedEvents[value.id] = value;
  }

  @override
  Future<SleepSafetyEvent?> getEvent(String id) async => savedEvents[id];

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
    bool allowPhoneFallback = true,
    bool allowUnverifiedVoiceAlert = false,
  }) async {
    lastSavedPriority = priority;
    lastSavedUnverifiedVoiceAlert = allowUnverifiedVoiceAlert;
    if (id == null &&
        cachedContacts.any((contact) => contact.priority == priority)) {
      throw StateError('sleep_safety_contact_priority_conflict');
    }
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
  Future<SleepSafetyDispatchResult> dispatchEmergency(
    String eventId,
    String idempotencyKey,
  ) async {
    dispatchCount += 1;
    dispatchKeys.add(idempotencyKey);
    if (dispatchFailuresRemaining > 0) {
      dispatchFailuresRemaining -= 1;
      throw StateError('provider_unavailable');
    }
    return const SleepSafetyDispatchResult(
      route: SleepSafetyDispatchRoute.cloudAccepted,
    );
  }
}

class _FakeSleepSafetyConnectivity implements SleepSafetyConnectivityGateway {
  _FakeSleepSafetyConnectivity(this.available);

  bool available;
  final StreamController<bool> _controller = StreamController<bool>.broadcast(
    sync: true,
  );

  @override
  Future<bool> hasNetworkTransport() async => available;

  @override
  Stream<bool> get networkAvailable => _controller.stream;

  void setAvailable(bool value) {
    available = value;
    _controller.add(value);
  }

  Future<void> dispose() => _controller.close();
}

class _NoopSleepSafetyConnectivity implements SleepSafetyConnectivityGateway {
  const _NoopSleepSafetyConnectivity();

  @override
  Future<bool> hasNetworkTransport() async => true;

  @override
  Stream<bool> get networkAvailable => const Stream<bool>.empty();
}

class _FakeSleepSafetyPhoneGateway implements SleepSafetyPhoneGateway {
  _FakeSleepSafetyPhoneGateway({
    this.directCalling = false,
    this.permissionGranted = true,
    this.callStartSucceeds = true,
    this.dialerOpenSucceeds = true,
  });

  final bool directCalling;
  final bool permissionGranted;
  final bool callStartSucceeds;
  final bool dialerOpenSucceeds;
  String? lastDialedNumber;
  String? lastStartedNumber;
  String? lastDialedEventId;
  String? lastStartedEventId;
  int permissionRequestCount = 0;
  final List<String> operations = [];

  @override
  bool get supportsDirectCalling => directCalling;

  @override
  Future<bool> ensureDirectCallPermission() async {
    permissionRequestCount += 1;
    operations.add('permission');
    return permissionGranted;
  }

  @override
  Future<bool> startCall(String phoneE164, {String? eventId}) async {
    operations.add('direct_call');
    lastStartedNumber = phoneE164;
    lastStartedEventId = eventId;
    return permissionGranted && callStartSucceeds;
  }

  @override
  Future<bool> openDialer(String phoneE164, {String? eventId}) async {
    operations.add('dialer');
    lastDialedNumber = phoneE164;
    lastDialedEventId = eventId;
    return dialerOpenSucceeds;
  }
}

Future<void> _waitUntil(bool Function() condition) async {
  for (var attempt = 0; attempt < 30; attempt++) {
    if (condition()) return;
    await Future<void>.delayed(Duration.zero);
  }
  fail('SleepSafetyController did not reach the expected state.');
}
