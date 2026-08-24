import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/data/gateways/sleep_safety_native_gateway.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/domain/entities/safety_contact.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/domain/entities/sleep_safety_event.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/domain/entities/sleep_safety_preference.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/domain/entities/sleep_safety_session.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/domain/repositories/sleep_safety_repository.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/providers/sleep_safety_providers.dart';
import 'package:nano_app/app_versions/v2/features/auth/providers/auth_providers.dart';

void main() {
  test('Start consumes resolved rollout state without a second remote fetch', () async {
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
  });

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

}

Future<void> _waitForPreference(ProviderContainer container) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    if (container.read(sleepSafetyControllerProvider).preference != null) return;
    await Future<void>.delayed(Duration.zero);
  }
  fail('SleepSafetyController did not finish initialization.');
}

class _FakeSleepSafetyRepository implements SleepSafetyRepository {
  _FakeSleepSafetyRepository(
    this.userId, {
    this.microphoneGranted = true,
  });

  final String userId;
  final bool microphoneGranted;
  int rolloutFetchCount = 0;
  int microphonePermissionCount = 0;
  int nativeStartCount = 0;
  final List<SleepSafetySession> savedSessions = [];

  @override
  Stream<SleepSafetyNativeEvent> get nativeEvents =>
      Stream<SleepSafetyNativeEvent>.empty();

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
  }) async => const [];

  @override
  Future<List<SleepSafetyEvent>> listEvents(String userId) async => const [];

  @override
  Future<void> saveSession(SleepSafetySession value) async {
    savedSessions.add(value);
  }

  @override
  Future<void> startNative(Map<String, Object?> config) async {
    nativeStartCount += 1;
  }

  @override
  Future<void> stopNative(String reason) async {}

  @override
  Future<void> respondToAlert(String eventId, String response) async {}

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
  Future<SafetyContact> saveContact({
    String? id,
    required String name,
    required String relationship,
    required String phoneE164,
    required int priority,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteContact(String id) async {}

  @override
  Future<void> requestContactVerification(String id) async {}

  @override
  Future<void> confirmContactVerification(String id, String code) async {}

  @override
  Future<Map<String, Object?>> dispatchEmergency(
    String eventId,
    String idempotencyKey,
  ) async => const {};
}
