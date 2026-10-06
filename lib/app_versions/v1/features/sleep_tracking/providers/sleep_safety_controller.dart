import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v2/features/auth/providers/auth_providers.dart';
import '../data/gateways/sleep_safety_native_gateway.dart';
import '../domain/entities/safety_contact.dart';
import '../domain/entities/sleep_safety_event.dart';
import '../domain/entities/sleep_safety_dispatch_exception.dart';
import '../domain/entities/sleep_safety_preference.dart';
import '../domain/entities/sleep_safety_runtime_config.dart';
import '../domain/entities/sleep_safety_session.dart';
import '../domain/repositories/sleep_safety_repository.dart';
import '../domain/services/sleep_safety_state_machine.dart';
import 'sleep_safety_providers.dart';

class SleepSafetyAudioMetrics {
  const SleepSafetyAudioMetrics({
    required this.signalLevel,
    required this.peakLevel,
    required this.relativeEnergy,
    required this.baselineLevel,
    required this.phase,
    required this.updatedAt,
  });

  final double signalLevel;
  final double peakLevel;
  final double relativeEnergy;
  final double baselineLevel;
  final String phase;
  final DateTime updatedAt;
}

class SleepSafetyViewState {
  const SleepSafetyViewState({
    required this.machine,
    required this.contacts,
    required this.history,
    this.contactsLoaded = false,
    this.runtimeConfig,
    this.preference,
    this.session,
    this.currentEvent,
    this.calibrationProgress = 0,
    this.audioMetrics,
    this.detectorCandidateType,
    this.audioSignalStale = false,
    this.isBusy = false,
    this.errorMessage,
    this.notice,
    this.dispatchFailure,
  });
  factory SleepSafetyViewState.initial() => const SleepSafetyViewState(
    machine: SleepSafetyMachineState.idle(),
    contacts: [],
    history: [],
  );
  final SleepSafetyMachineState machine;
  final SleepSafetyPreference? preference;
  final SleepSafetySession? session;
  final SleepSafetyEvent? currentEvent;
  final List<SafetyContact> contacts;
  final bool contactsLoaded;
  final List<SleepSafetyEvent> history;
  final SleepSafetyRuntimeConfig? runtimeConfig;
  final double calibrationProgress;
  final SleepSafetyAudioMetrics? audioMetrics;
  final String? detectorCandidateType;
  final bool audioSignalStale;
  final bool isBusy;
  final String? errorMessage;
  final String? notice;
  final SleepSafetyDispatchException? dispatchFailure;
  bool get monitoringActive => const {
    SleepSafetyPhase.arming,
    SleepSafetyPhase.calibrating,
    SleepSafetyPhase.monitoring,
    SleepSafetyPhase.awaitingResponse,
    SleepSafetyPhase.manualHelp,
    SleepSafetyPhase.escalating,
    SleepSafetyPhase.cooldown,
  }.contains(machine.phase);
  List<SafetyContact> get phoneFallbackContacts =>
      contacts
          .where(
            (contact) =>
                contact.active &&
                contact.allowPhoneFallback &&
                RegExp(r'^\+[1-9][0-9]{7,14}$').hasMatch(contact.phoneE164),
          )
          .toList()
        ..sort((a, b) {
          final priority = a.priority.compareTo(b.priority);
          return priority != 0 ? priority : a.id.compareTo(b.id);
        });
  bool get phoneFallbackEnabled => phoneFallbackContacts.isNotEmpty;
  bool get needsContactSetup =>
      currentEvent?.escalationStatus == SleepSafetyEscalationStatus.failed &&
      const {
        'eligible_contact_required',
        'verified_contact_required',
      }.contains(dispatchFailure?.code);
  SafetyContact? get phoneFallbackContact {
    final eligibleContacts = phoneFallbackContacts;
    return eligibleContacts.isEmpty ? null : eligibleContacts.first;
  }

  SleepSafetyViewState copyWith({
    SleepSafetyMachineState? machine,
    SleepSafetyPreference? preference,
    SleepSafetySession? session,
    SleepSafetyEvent? currentEvent,
    bool clearCurrentEvent = false,
    List<SafetyContact>? contacts,
    bool? contactsLoaded,
    List<SleepSafetyEvent>? history,
    SleepSafetyRuntimeConfig? runtimeConfig,
    double? calibrationProgress,
    SleepSafetyAudioMetrics? audioMetrics,
    bool clearAudioMetrics = false,
    String? detectorCandidateType,
    bool clearDetectorCandidate = false,
    bool? audioSignalStale,
    bool? isBusy,
    String? errorMessage,
    bool clearError = false,
    String? notice,
    bool clearNotice = false,
    SleepSafetyDispatchException? dispatchFailure,
    bool clearDispatchFailure = false,
  }) => SleepSafetyViewState(
    machine: machine ?? this.machine,
    preference: preference ?? this.preference,
    session: session ?? this.session,
    currentEvent: clearCurrentEvent ? null : currentEvent ?? this.currentEvent,
    contacts: contacts ?? this.contacts,
    contactsLoaded: contactsLoaded ?? this.contactsLoaded,
    history: history ?? this.history,
    runtimeConfig: runtimeConfig ?? this.runtimeConfig,
    calibrationProgress: calibrationProgress ?? this.calibrationProgress,
    audioMetrics: clearAudioMetrics ? null : audioMetrics ?? this.audioMetrics,
    detectorCandidateType: clearDetectorCandidate
        ? null
        : detectorCandidateType ?? this.detectorCandidateType,
    audioSignalStale: audioSignalStale ?? this.audioSignalStale,
    isBusy: isBusy ?? this.isBusy,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    notice: clearNotice ? null : notice ?? this.notice,
    dispatchFailure: clearDispatchFailure
        ? null
        : dispatchFailure ?? this.dispatchFailure,
  );
}

class SleepSafetyController extends Notifier<SleepSafetyViewState> {
  final _machine = const SleepSafetyStateMachine();
  StreamSubscription<SleepSafetyNativeEvent>? _nativeSubscription;
  Timer? _audioMetricsWatchdog;
  final Set<String> _handlingManualHelpEvents = <String>{};
  final Set<String> _handlingNoResponseCalls = <String>{};
  final Random _random = Random.secure();
  int _contactsRefreshGeneration = 0;
  int _lastPhoneFallbackPriority = 0;
  bool? _directCallPermissionGranted;
  SleepSafetyRepository get _repository =>
      ref.read(sleepSafetyRepositoryProvider);

  @override
  SleepSafetyViewState build() {
    ref.onDispose(() {
      _nativeSubscription?.cancel();
      _audioMetricsWatchdog?.cancel();
    });
    unawaited(_initialize());
    return SleepSafetyViewState.initial();
  }

  Future<void> _initialize() async {
    final userId = ref.read(currentAuthUserIdProvider);
    if (userId == null) return;
    final contactsRequest = ++_contactsRefreshGeneration;
    try {
      final preference = await _repository.loadPreference(userId);
      final contacts = await _repository.loadContacts(userId);
      state = state.copyWith(
        preference: preference,
        contacts: contactsRequest == _contactsRefreshGeneration
            ? contacts
            : null,
        contactsLoaded: contactsRequest == _contactsRefreshGeneration
            ? true
            : null,
      );

      SleepSafetyRuntimeConfig? runtimeConfig;
      try {
        runtimeConfig = await _repository.loadRuntimeConfig().timeout(
          const Duration(seconds: 8),
        );
      } catch (_) {
        // Keep local monitoring available if the rollout endpoint is offline.
      }
      final history = await _repository.listEvents(userId);
      state = state.copyWith(
        history: history,
        runtimeConfig: runtimeConfig,
        clearError: true,
      );
      if (_pendingNativePhoneFallback) {
        _pendingNativePhoneFallback = false;
        unawaited(callPhoneFallback());
      }
      _nativeSubscription ??= _repository.nativeEvents.listen(
        _handleNativeEvent,
        onError: (_) {
          state = state.copyWith(
            machine: _machine.fail('native_event_stream'),
            clearAudioMetrics: true,
            clearDetectorCandidate: true,
            audioSignalStale: true,
            errorMessage: 'Giám sát âm thanh vừa bị gián đoạn.',
          );
          _stopAudioMetricsWatchdog();
        },
      );
      await _updateNativePhoneFallbackConfig();
      unawaited(_retireLegacyNoResponseRetries());
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'Nabi chưa tải được cài đặt giám sát. Bạn thử lại nhé.',
      );
    }
  }

  Future<void> startMonitoring({String source = 'manual'}) async {
    final userId = ref.read(currentAuthUserIdProvider);
    final preference = state.preference;
    if (userId == null || preference == null || state.isBusy) return;

    SleepSafetySession? startingSession;
    var nativeStartRequested = false;
    var directCallPermissionGranted = true;
    state = state.copyWith(isBusy: true, clearError: true, clearNotice: true);

    try {
      if (!ref.read(sleepSafetyRolloutApprovedProvider)) {
        throw StateError('rollout_disabled');
      }
      final phoneGateway = ref.read(sleepSafetyPhoneGatewayProvider);
      if (_phoneFallbackForNative() != null &&
          phoneGateway.supportsDirectCalling) {
        try {
          directCallPermissionGranted = _directCallPermissionGranted =
              await phoneGateway.ensureDirectCallPermission();
        } catch (_) {
          directCallPermissionGranted = _directCallPermissionGranted = false;
        }
      }
      if (!await _repository.ensureMicrophonePermission()) {
        throw StateError('microphone_denied');
      }
      final notificationsAllowed = await ref.read(
        sleepSafetyNotificationPermissionProvider,
      )();
      if (!notificationsAllowed) {
        throw StateError('notification_denied');
      }

      final now = DateTime.now();
      final sessionId = _newId('ss');
      final session = SleepSafetySession(
        id: sessionId,
        userId: userId,
        startedAt: now,
        sensitivity: preference.sensitivity,
        status: SleepSafetySessionStatus.arming,
        startSource: source,
        platform: defaultTargetPlatform.name,
        appVersion: '1.0.0',
        createdAt: now,
        updatedAt: now,
        calibrationNoiseFloor: preference.calibrationNoiseFloor,
        scheduledWindowEnd: _nextScheduleEnd(preference, now),
      );
      await _repository.saveSession(session);
      startingSession = session;

      // Persist and expose the arming session before crossing into native code.
      // If Android rejects foreground-service creation, the asynchronous native
      // failure event can still close this exact session instead of leaving a
      // ghost `arming` row behind.
      state = state.copyWith(session: session, machine: _machine.arm());
      nativeStartRequested = true;
      await _repository.startNative(<String, Object?>{
        'sessionId': sessionId,
        'userId': userId,
        'sensitivity': preference.sensitivity.name,
        'calibrationRequired': preference.calibrationRequired,
        'calibrationNoiseFloor': preference.calibrationNoiseFloor,
        'calibrationSeconds': 30,
        'cooldownSeconds': preference.cooldownSeconds,
        'scheduledEndEpochMs':
            session.scheduledWindowEnd?.millisecondsSinceEpoch,
        'phoneFallbackEnabled': _phoneFallbackForNative() != null,
        'phoneFallbackE164': _phoneFallbackForNative()?.phoneE164 ?? '',
        'phoneFallbackPriority': _phoneFallbackForNative()?.priority ?? 0,
      });

      state = state.copyWith(
        notice: !directCallPermissionGranted
            ? 'Quyền gọi trực tiếp chưa được cấp. Khi cần hỗ trợ, Nabi sẽ mở ứng dụng Điện thoại để bạn tự bấm Gọi.'
            : state.contacts.any((contact) => contact.canReceiveSafetyCall)
            ? null
            : 'Cảnh báo tại máy vẫn hoạt động. Hãy thêm người liên hệ hoặc bật quyền nhận cuộc gọi thoại để Nabi có thể liên hệ khi cần.',
      );
    } on SleepSafetyNativeStartException catch (error) {
      await _finishSession(error.code, failed: true);
      state = state.copyWith(
        errorMessage: _nativeStartErrorMessage(error.code),
      );
    } on StateError catch (error) {
      final code = error.message;
      state = state.copyWith(
        errorMessage: code == 'microphone_denied'
            ? 'NanoBio cần quyền micro để giám sát âm thanh khi bạn ngủ.'
            : code == 'notification_denied'
            ? 'NanoBio cần quyền thông báo để có thể đánh thức và hỏi bạn khi phát hiện âm thanh cần chú ý.'
            : code == 'rollout_disabled'
            ? 'Giám sát giấc ngủ đang tạm dừng từ hệ thống. Bạn có thể kiểm tra lại sau.'
            : 'Chưa thể bắt đầu giám sát.',
      );
    } catch (_) {
      if (nativeStartRequested && startingSession != null) {
        await _finishSession('native_start_failed', failed: true);
      }
      state = state.copyWith(
        errorMessage:
            'Chưa thể bắt đầu giám sát. Bạn kiểm tra quyền micro và thử lại nhé.',
      );
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  Future<void> stopMonitoring({String reason = 'user'}) async {
    if (!state.monitoringActive || state.isBusy) return;
    state = state.copyWith(isBusy: true);
    try {
      await _repository.stopNative(reason);
      await _finishSession(reason);
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'Chưa thể dừng giám sát ngay. Bạn thử lại nhé.',
      );
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  Future<void> respondOk() async {
    final event = state.currentEvent;
    if (event == null) return;
    await _repository.respondToAlert(event.id, 'ok');
    await _applyResponse(event.id, 'ok');
  }

  Future<void> requestHelp() async {
    final event = state.currentEvent;
    if (event == null) return;
    // Native acknowledgement is best-effort. Explicit help stays local and
    // never enters the cloud dispatch path.
    if (event.response != SleepSafetyResponse.needHelp) {
      try {
        await _repository
            .respondToAlert(event.id, 'need_help')
            .timeout(const Duration(seconds: 2));
      } catch (_) {}
    }
    await _applyResponse(event.id, 'need_help');
  }

  Future<void> retryNoResponsePhoneCall() async {
    final event = state.currentEvent;
    if (event == null ||
        event.response != SleepSafetyResponse.noResponse ||
        !_isNoResponseCallRetryable(event.state)) {
      return;
    }
    await _handleNoResponseTimeout(event.id, userRetry: true);
  }

  Future<void> savePreference(SleepSafetyPreference preference) async {
    final updated = preference.copyWith(updatedAt: DateTime.now());
    await _repository.savePreference(updated);
    await ref.read(sleepSafetyReminderServiceProvider).apply(updated);
    await _repository.updateNativeConfig({
      'sensitivity': updated.sensitivity.name,
      'cooldownSeconds': updated.cooldownSeconds,
    });
    state = state.copyWith(
      preference: updated,
      notice: 'Đã lưu cài đặt giám sát.',
    );
  }

  Future<void> recalibrate() async {
    if (!state.monitoringActive) {
      state = state.copyWith(
        errorMessage:
            'Hãy bắt đầu giám sát trước khi hiệu chỉnh lại âm thanh phòng.',
      );
      return;
    }
    await ref.read(sleepSafetyNativeGatewayProvider).startCalibration();
    state = state.copyWith(
      machine: _machine.calibrate(),
      calibrationProgress: 0,
    );
  }

  Future<void> saveContact({
    String? id,
    required String name,
    required String relationship,
    required String phoneE164,
    required int priority,
    bool allowPhoneFallback = true,
    bool allowUnverifiedVoiceAlert = false,
  }) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final normalizedName = name.trim();
      final normalizedRelationship = relationship.trim();
      if (normalizedName.isEmpty) {
        throw const FormatException('Bạn hãy nhập tên người liên hệ.');
      }
      if (normalizedName.length > 80) {
        throw const FormatException(
          'Tên người liên hệ không được dài quá 80 ký tự.',
        );
      }
      if (normalizedRelationship.isEmpty) {
        throw const FormatException('Bạn hãy nhập mối quan hệ.');
      }
      if (normalizedRelationship.length > 60) {
        throw const FormatException('Mối quan hệ không được dài quá 60 ký tự.');
      }
      if (priority < 1 || priority > 3) {
        throw const FormatException(
          'Mức ưu tiên cần nằm trong khoảng từ 1 đến 3.',
        );
      }
      if (!state.contactsLoaded) {
        await refreshContacts();
        if (!state.contactsLoaded) {
          throw const FormatException(
            'Danh sách người liên hệ chưa tải xong. Bạn thử lại nhé.',
          );
        }
      }
      final saved = await _repository.saveContact(
        id: id,
        name: normalizedName,
        relationship: normalizedRelationship,
        phoneE164: _normalizePhone(phoneE164),
        priority:
            id == null &&
                state.contacts.any((contact) => contact.priority == priority)
            ? _nextAvailablePriority(state.contacts)
            : priority,
        allowPhoneFallback: allowPhoneFallback,
        allowUnverifiedVoiceAlert: allowUnverifiedVoiceAlert,
      );

      // Apply the RPC result immediately. A refresh started before the save
      // can otherwise finish later and overwrite this newly saved contact.
      _mergeContact(saved);
      await _updateNativePhoneFallbackConfig();
      try {
        await refreshContacts();
      } catch (_) {
        // The RPC response already gives us a valid local view.
      }
      try {
        await _repository.cacheContact(saved);
      } catch (_) {
        // State remains correct even when the device cache is unavailable.
      }
      _mergeContact(saved);
      state = state.copyWith(
        notice: 'Đã lưu người liên hệ an toàn.',
        clearError: true,
      );
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  Future<void> deleteContact(String id) async {
    await _repository.deleteContact(id);
    await refreshContacts();
  }

  Future<void> requestVerification(String id) =>
      _repository.requestContactVerification(id);
  Future<void> confirmVerification(String id, String code) async {
    final normalizedCode = code.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(normalizedCode)) {
      throw const FormatException('Mã xác minh cần gồm 6 chữ số.');
    }
    await _repository.confirmContactVerification(id, normalizedCode);
    await refreshContacts();
  }

  Future<void> refreshContacts() async {
    final userId = ref.read(currentAuthUserIdProvider);
    if (userId == null) return;
    final request = ++_contactsRefreshGeneration;
    final contacts = await _repository.loadContacts(userId);
    if (request != _contactsRefreshGeneration) return;
    state = state.copyWith(contacts: contacts, contactsLoaded: true);
    if (state.needsContactSetup &&
        contacts.any((contact) => contact.canReceiveSafetyCall)) {
      state = state.copyWith(
        clearDispatchFailure: true,
        clearError: true,
        notice:
            'Liên hệ đã sẵn sàng nhận cuộc gọi. Bạn có thể thử gửi lại cảnh báo.',
      );
    }
    await _updateNativePhoneFallbackConfig();
    unawaited(_retireLegacyNoResponseRetries());
  }

  void _mergeContact(SafetyContact saved) {
    final contacts = [
      ...state.contacts.where((contact) => contact.id != saved.id),
      saved,
    ]..sort((a, b) => a.priority.compareTo(b.priority));
    state = state.copyWith(
      contacts: List<SafetyContact>.unmodifiable(contacts),
    );
  }

  int _nextAvailablePriority(Iterable<SafetyContact> contacts) {
    final used = contacts.map((contact) => contact.priority).toSet();
    return [
      1,
      2,
      3,
    ].firstWhere((priority) => !used.contains(priority), orElse: () => 1);
  }

  Future<void> _handleNativeEvent(SleepSafetyNativeEvent event) async {
    final now = DateTime.now();
    if (event.type == 'statusSnapshot') {
      await _restoreNativeStatus(event);
      return;
    }
    if (event.type == 'serviceStarted') {
      final preference = state.preference;
      state = state.copyWith(
        machine: preference?.calibrationRequired == true
            ? _machine.calibrate()
            : _machine.monitor(),
        clearAudioMetrics: true,
        clearDetectorCandidate: true,
        audioSignalStale: false,
      );
      _ensureAudioMetricsWatchdog();
      return;
    }
    if (event.type == 'audioMetrics') {
      final phase = event.data['phase']?.toString() ?? 'monitoring';
      state = state.copyWith(
        audioMetrics: SleepSafetyAudioMetrics(
          signalLevel: _unit(event.data['signalLevel']),
          peakLevel: _unit(event.data['peakLevel']),
          relativeEnergy:
              (event.data['relativeEnergy'] as num?)?.toDouble() ?? 0,
          baselineLevel: _unit(event.data['baselineLevel']),
          phase: phase,
          updatedAt: now,
        ),
        clearDetectorCandidate: phase == 'monitoring' || phase == 'calibrating',
        audioSignalStale: false,
      );
      _ensureAudioMetricsWatchdog();
      return;
    }
    if (event.type == 'detectorCandidate') {
      state = state.copyWith(
        detectorCandidateType: event.data['eventType']?.toString(),
      );
      return;
    }
    if (event.type == 'calibrationProgress') {
      state = state.copyWith(
        calibrationProgress: ((event.data['progress'] as num?)?.toDouble() ?? 0)
            .clamp(0, 1)
            .toDouble(),
      );
      return;
    }
    if (event.type == 'calibrationCompleted') {
      final preference = state.preference;
      final floor = (event.data['noiseFloor'] as num?)?.toDouble();
      if (preference != null) {
        final updated = preference.copyWith(
          calibrationRequired: false,
          calibrationNoiseFloor: floor,
          calibrationUpdatedAt: now,
          updatedAt: now,
        );
        await _repository.savePreference(updated);
        final alertOrCooldown = const {
          SleepSafetyPhase.awaitingResponse,
          SleepSafetyPhase.escalating,
          SleepSafetyPhase.cooldown,
        }.contains(state.machine.phase);
        state = state.copyWith(
          preference: updated,
          machine: alertOrCooldown ? state.machine : _machine.monitor(),
          calibrationProgress: 1,
        );
      }
      return;
    }
    if (event.type == 'monitoringReady') {
      state = state.copyWith(machine: _machine.monitor());
      return;
    }
    if (event.type == 'confirmedSafetyEvent') {
      await _recordConfirmedEvent(event, now);
      return;
    }
    if (event.type == 'userResponse') {
      final eventId = event.data['eventId']?.toString();
      final response = event.data['response']?.toString();
      if (eventId != null && response != null) {
        await _applyResponse(eventId, response);
      }
      return;
    }
    if (event.type == 'escalationRequired') {
      final eventId = event.data['eventId']?.toString();
      if (eventId != null) await _handleNoResponseTimeout(eventId);
      return;
    }
    if (event.type == 'serviceStopped') {
      await _finishSession(event.data['reason']?.toString() ?? 'native_stop');
      return;
    }
    if (event.type == 'permissionLost') {
      await _finishSession('permission_revoked', failed: true);
      state = state.copyWith(
        errorMessage: 'Quyền micro đã bị thu hồi nên Nabi đã dừng giám sát.',
      );
      return;
    }
    if (event.type == 'nativeFailure') {
      final code = event.data['code']?.toString() ?? 'native_failure';
      await _finishSession(code, failed: true);
      state = state.copyWith(errorMessage: _nativeStartErrorMessage(code));
      return;
    }
    if (event.type == 'phoneFallbackUnavailable') {
      state = state.copyWith(
        errorMessage: 'Chưa thể mở ứng dụng Điện thoại trên thiết bị này.',
      );
      return;
    }
    if (event.type == 'phoneFallbackRequested') {
      if (state.preference == null) {
        _pendingNativePhoneFallback = true;
      } else {
        unawaited(callPhoneFallback());
      }
    }
  }

  Future<void> _restoreNativeStatus(SleepSafetyNativeEvent native) async {
    if (native.data['active'] != true) return;
    final sessionId = native.data['sessionId']?.toString();
    if (sessionId == null || sessionId.isEmpty) return;
    final session = await _repository.getSession(sessionId);
    if (session == null) return;
    final now = DateTime.now();

    final rawCurrent = native.data['currentEvent'];
    SleepSafetyEvent? current;
    if (rawCurrent is Map) {
      final data = Map<String, Object?>.from(rawCurrent);
      final eventId = data['eventId']?.toString();
      if (eventId != null && eventId.isNotEmpty) {
        current = await _repository.getEvent(eventId);
        if (current == null) {
          current = _eventFromNativeData(data, session, DateTime.now());
          await _repository.saveEventLocally(current);
        }
      }
    }

    final phase = native.data['phase']?.toString();
    var manualHelpInterrupted = false;
    var noResponseCallInterrupted = false;
    if (current?.state == 'no_response_call_starting' &&
        current?.response == SleepSafetyResponse.noResponse &&
        !_handlingNoResponseCalls.contains(current!.id)) {
      current = _copyEvent(
        current,
        stateName: 'no_response_call_interrupted',
        updatedAt: now,
      );
      try {
        await _persistNoResponseCallEvent(current);
      } catch (_) {}
      noResponseCallInterrupted = true;
    }
    SleepSafetyMachineState machine;
    if (current?.response == SleepSafetyResponse.needHelp) {
      if (current!.state == 'manual_call_started' ||
          current.state == 'manual_call_handoff') {
        machine = _machine.monitor();
      } else {
        if (current.state == 'manual_call_starting' ||
            current.state == 'help_requested') {
          current = _copyEvent(
            current,
            stateName: 'manual_call_interrupted',
            updatedAt: now,
          );
          await _repository.saveEvent(current);
          manualHelpInterrupted = true;
        }
        machine = SleepSafetyMachineState(
          phase: SleepSafetyPhase.manualHelp,
          eventId: current.id,
          alertStartedAt: current.detectedAt,
        );
      }
    } else if (current?.response == SleepSafetyResponse.noResponse &&
        _isNoResponseCallHandedOff(current!.state)) {
      machine = _machine.monitor();
    } else if (current?.response == SleepSafetyResponse.noResponse &&
        _isNoResponseCallRetryable(current!.state)) {
      machine = SleepSafetyMachineState(
        phase: SleepSafetyPhase.escalating,
        eventId: current.id,
        alertStartedAt: current.detectedAt,
      );
    } else if (current?.response == SleepSafetyResponse.noResponse &&
        current?.escalationStatus == SleepSafetyEscalationStatus.accepted) {
      machine = _machine.monitor();
    } else if (phase == 'calibrating') {
      machine = _machine.calibrate();
    } else if (phase == 'alerting' && current != null) {
      machine = SleepSafetyMachineState(
        phase: SleepSafetyPhase.awaitingResponse,
        eventId: current.id,
        alertStartedAt: current.detectedAt,
      );
    } else if (phase == 'escalating' && current != null) {
      machine = SleepSafetyMachineState(
        phase: SleepSafetyPhase.escalating,
        eventId: current.id,
        alertStartedAt: current.detectedAt,
      );
    } else {
      machine = _machine.monitor();
    }

    final currentEvent = current;
    final restoredHistory = currentEvent == null
        ? state.history
        : state.history.any((item) => item.id == currentEvent.id)
        ? _replaceHistoryEvent(state.history, currentEvent)
        : <SleepSafetyEvent>[currentEvent, ...state.history];
    final restorationError = manualHelpInterrupted
        ? 'Nabi chưa xác định được kết quả khởi tạo cuộc gọi trước đó. Hãy thử gọi lại nếu cần.'
        : noResponseCallInterrupted
        ? 'Nabi chưa xác định được kết quả cuộc gọi tự động trước đó. Cảnh báo vẫn hoạt động; hãy kiểm tra điện thoại hoặc thử gọi lại.'
        : currentEvent != null &&
              currentEvent.response == SleepSafetyResponse.noResponse &&
              _isNoResponseCallRetryable(currentEvent.state)
        ? _noResponseCallErrorMessage(currentEvent.state)
        : null;
    state = state.copyWith(
      session: session,
      currentEvent: current,
      machine: machine,
      history: restoredHistory,
      errorMessage: restorationError,
      clearError: restorationError == null,
      calibrationProgress:
          ((native.data['calibrationProgress'] as num?)?.toDouble() ?? 0)
              .clamp(0, 1)
              .toDouble(),
    );
    await _updateNativePhoneFallbackConfig();
    _ensureAudioMetricsWatchdog();
    if (phase == 'escalating' &&
        current != null &&
        current.response != SleepSafetyResponse.needHelp &&
        current.response != SleepSafetyResponse.ok &&
        !_isNoResponseCallHandedOff(current.state) &&
        current.escalationStatus != SleepSafetyEscalationStatus.accepted) {
      await _handleNoResponseTimeout(current.id);
    }
  }

  SleepSafetyEvent _eventFromNativeData(
    Map<String, Object?> data,
    SleepSafetySession session,
    DateTime now,
  ) {
    return SleepSafetyEvent(
      id: data['eventId']?.toString() ?? _newId('event'),
      sessionId: session.id,
      userId: session.userId,
      detectedAt:
          DateTime.tryParse(data['detectedAt']?.toString() ?? '') ?? now,
      eventType: _eventType(data['eventType']?.toString()),
      severity: data['severity']?.toString() ?? 'attention',
      confidence: (data['confidence'] as num?)?.toDouble() ?? 0.7,
      relativeEnergy: (data['relativeEnergy'] as num?)?.toDouble() ?? 0,
      baselineDelta: (data['baselineDelta'] as num?)?.toDouble() ?? 0,
      repetitionCount: (data['repetitionCount'] as num?)?.toInt() ?? 1,
      state: data['response'] == 'need_help'
          ? 'help_requested'
          : 'awaiting_response',
      response: data['response'] == 'need_help'
          ? SleepSafetyResponse.needHelp
          : SleepSafetyResponse.none,
      escalationRequired: false,
      escalationStatus: SleepSafetyEscalationStatus.notRequired,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> _recordConfirmedEvent(
    SleepSafetyNativeEvent native,
    DateTime now,
  ) async {
    final session = state.session;
    final userId = ref.read(currentAuthUserIdProvider);
    if (session == null || userId == null) return;
    if (state.machine.phase != SleepSafetyPhase.monitoring &&
        state.machine.phase != SleepSafetyPhase.calibrating) {
      return;
    }
    final id = native.data['eventId']?.toString() ?? _newId('event');
    final event = SleepSafetyEvent(
      id: id,
      sessionId: session.id,
      userId: userId,
      detectedAt:
          DateTime.tryParse(native.data['detectedAt']?.toString() ?? '') ?? now,
      eventType: _eventType(native.data['eventType']?.toString()),
      severity: native.data['severity']?.toString() ?? 'attention',
      confidence: (native.data['confidence'] as num?)?.toDouble() ?? 0.7,
      relativeEnergy: (native.data['relativeEnergy'] as num?)?.toDouble() ?? 0,
      baselineDelta: (native.data['baselineDelta'] as num?)?.toDouble() ?? 0,
      repetitionCount: (native.data['repetitionCount'] as num?)?.toInt() ?? 1,
      state: 'awaiting_response',
      response: SleepSafetyResponse.none,
      escalationRequired: false,
      escalationStatus: SleepSafetyEscalationStatus.notRequired,
      createdAt: now,
      updatedAt: now,
    );
    _lastPhoneFallbackPriority = 0;
    await _repository.saveEvent(event);
    state = state.copyWith(
      currentEvent: event,
      machine: _machine.onConfirmedEvent(state.machine, eventId: id, now: now),
      history: [event, ...state.history],
    );
  }

  Future<void> _applyResponse(String eventId, String response) async {
    final current = state.currentEvent;
    if (current == null || current.id != eventId) return;
    final now = DateTime.now();
    if (response == 'ok') {
      final updated = _copyEvent(
        current,
        response: SleepSafetyResponse.ok,
        responseAt: now,
        stateName: 'resolved_ok',
        updatedAt: now,
      );
      await _repository.saveEvent(updated);
      state = state.copyWith(
        currentEvent: updated,
        machine: _machine.respondOk(
          state.machine,
          now: now,
          cooldown: Duration(seconds: state.preference?.cooldownSeconds ?? 120),
        ),
      );
      return;
    }
    if (response == 'need_help') {
      if (current.response == SleepSafetyResponse.needHelp &&
          current.escalationStatus == SleepSafetyEscalationStatus.notRequired &&
          const {
            'manual_call_starting',
            'manual_call_started',
            'manual_call_handoff',
          }.contains(current.state)) {
        return;
      }
      if (!_handlingManualHelpEvents.add(eventId)) return;
      try {
        var updated = _copyEvent(
          current,
          response: SleepSafetyResponse.needHelp,
          responseAt: now,
          stateName: 'manual_call_starting',
          escalationRequired: false,
          escalationStatus: SleepSafetyEscalationStatus.notRequired,
          updatedAt: now,
        );
        state = state.copyWith(
          currentEvent: updated,
          machine: _machine.respondNeedHelp(state.machine),
          history: _replaceHistoryEvent(state.history, updated),
          clearError: true,
          clearNotice: true,
          clearDispatchFailure: true,
        );
        await _persistManualHelpEvent(updated);

        final phonePattern = RegExp(r'^\+[1-9][0-9]{7,14}$');
        final contacts =
            state.contacts
                .where(
                  (contact) =>
                      contact.active &&
                      contact.allowPhoneFallback &&
                      phonePattern.hasMatch(contact.phoneE164),
                )
                .toList()
              ..sort((a, b) {
                final priority = a.priority.compareTo(b.priority);
                return priority != 0 ? priority : a.id.compareTo(b.id);
              });
        if (contacts.isEmpty) {
          updated = _copyEvent(
            updated,
            stateName: 'manual_call_unavailable',
            updatedAt: DateTime.now(),
          );
          state = state.copyWith(
            currentEvent: updated,
            history: _replaceHistoryEvent(state.history, updated),
            errorMessage:
                'Chưa có người liên hệ an toàn đang hoạt động cho phép gọi. Cảnh báo vẫn hiển thị; hãy thêm liên hệ hoặc gọi người hỗ trợ bằng ứng dụng Điện thoại.',
          );
          await _persistManualHelpEvent(updated);
          return;
        }

        final contact = contacts.first;
        final phoneGateway = ref.read(sleepSafetyPhoneGatewayProvider);
        var callStarted = false;
        if (phoneGateway.supportsDirectCalling) {
          try {
            final permissionGranted = _directCallPermissionGranted ??=
                await phoneGateway.ensureDirectCallPermission();
            if (permissionGranted) {
              callStarted = await phoneGateway
                  .startCall(contact.phoneE164, eventId: eventId)
                  .timeout(const Duration(seconds: 5));
            }
          } catch (_) {
            _directCallPermissionGranted = false;
            callStarted = false;
          }
        }
        var dialerOpened = false;
        if (!callStarted) {
          try {
            dialerOpened = await phoneGateway
                .openDialer(contact.phoneE164, eventId: eventId)
                .timeout(const Duration(seconds: 5));
          } catch (_) {
            dialerOpened = false;
          }
        }

        updated = _copyEvent(
          updated,
          stateName: callStarted
              ? 'manual_call_started'
              : dialerOpened
              ? 'manual_call_handoff'
              : 'manual_call_unavailable',
          updatedAt: DateTime.now(),
        );
        final callHandedOff = callStarted || dialerOpened;
        state = state.copyWith(
          currentEvent: updated,
          machine: callHandedOff ? _machine.monitor() : state.machine,
          history: _replaceHistoryEvent(state.history, updated),
          notice: callStarted
              ? 'Nabi đã yêu cầu điện thoại khởi tạo cuộc gọi cho ${contact.name}. Tình trạng kết nối chưa được xác nhận.'
              : dialerOpened
              ? defaultTargetPlatform == TargetPlatform.iOS
                    ? 'Đã mở yêu cầu gọi ${contact.name}. iPhone có thể yêu cầu xác nhận; tình trạng kết nối chưa được xác nhận.'
                    : 'Đã mở ứng dụng Điện thoại cho ${contact.name}. Hãy kiểm tra số và bấm Gọi; cuộc gọi chưa được bắt đầu.'
              : null,
          errorMessage: callHandedOff
              ? null
              : 'Chưa thể mở cuộc gọi hoặc ứng dụng Điện thoại cho ${contact.name}. Cảnh báo vẫn hiển thị; hãy thử lại hoặc mở danh bạ.',
          clearError: callHandedOff,
          clearNotice: !callHandedOff,
        );
        await _persistManualHelpEvent(updated);
      } finally {
        _handlingManualHelpEvents.remove(eventId);
      }
    }
  }

  Future<void> _persistManualHelpEvent(SleepSafetyEvent event) async {
    // Local event sync is best-effort. A slow cloud request must not delay an
    // explicitly requested safety call or keep its loading state on screen.
    try {
      await _repository.saveEvent(event).timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  Future<void> _handleNoResponseTimeout(
    String eventId, {
    bool userRetry = false,
  }) async {
    if (!_handlingNoResponseCalls.add(eventId)) return;
    final current = state.currentEvent;
    if (current == null ||
        current.id != eventId ||
        current.response == SleepSafetyResponse.needHelp ||
        current.response == SleepSafetyResponse.ok ||
        userRetry &&
            (current.response != SleepSafetyResponse.noResponse ||
                !_isNoResponseCallRetryable(current.state)) ||
        !userRetry &&
            current.response == SleepSafetyResponse.noResponse &&
            (_isNoResponseCallHandedOff(current.state) ||
                _isNoResponseCallRetryable(current.state) ||
                current.state == 'no_response_call_starting')) {
      _handlingNoResponseCalls.remove(eventId);
      return;
    }
    final now = DateTime.now();
    final updated = _copyEvent(
      current,
      response: SleepSafetyResponse.noResponse,
      responseAt: current.responseAt ?? now,
      stateName: 'no_response_call_starting',
      escalationRequired: false,
      escalationStatus: SleepSafetyEscalationStatus.notRequired,
      updatedAt: now,
    );
    state = state.copyWith(
      currentEvent: updated,
      history: _replaceHistoryEvent(state.history, updated),
      machine: SleepSafetyMachineState(
        phase: SleepSafetyPhase.escalating,
        eventId: eventId,
        alertStartedAt: state.machine.alertStartedAt,
      ),
      clearError: true,
      clearNotice: true,
      clearDispatchFailure: true,
    );
    try {
      await _retireLegacyNoResponseRetries(eventId: eventId);
      try {
        await _persistNoResponseCallEvent(updated);
      } catch (_) {
        final failed = _copyEvent(
          updated,
          stateName: 'no_response_call_failed',
          updatedAt: DateTime.now(),
        );
        state = state.copyWith(
          currentEvent: failed,
          history: _replaceHistoryEvent(state.history, failed),
          errorMessage:
              'Chưa thể lưu trạng thái cuộc gọi. Cảnh báo vẫn hoạt động; hãy bấm “Tôi cần hỗ trợ” để tiếp tục.',
        );
        return;
      }
      if (!_isNoResponseCallStarting(eventId)) return;

      final contact = _phoneFallbackForNative();
      if (contact == null) {
        await _finishNoResponseCall(
          updated,
          stateName: 'no_response_call_unavailable',
          errorMessage:
              'Chưa có người liên hệ an toàn đang hoạt động cho phép gọi. Cảnh báo vẫn hoạt động; hãy thêm liên hệ hoặc bấm “Tôi cần hỗ trợ”.',
        );
        return;
      }

      final phoneGateway = ref.read(sleepSafetyPhoneGatewayProvider);
      var callStarted = false;
      if (phoneGateway.supportsDirectCalling) {
        try {
          final permissionGranted = _directCallPermissionGranted ??=
              await phoneGateway.ensureDirectCallPermission();
          if (!_isNoResponseCallStarting(eventId)) return;
          if (permissionGranted) {
            callStarted = await phoneGateway
                .startCall(contact.phoneE164, eventId: eventId)
                .timeout(const Duration(seconds: 5));
          }
        } catch (_) {
          _directCallPermissionGranted = false;
          callStarted = false;
        }
      }
      if (!_isNoResponseCallStarting(eventId)) return;

      var dialerOpened = false;
      if (!callStarted) {
        try {
          dialerOpened = await phoneGateway
              .openDialer(contact.phoneE164, eventId: eventId)
              .timeout(const Duration(seconds: 5));
        } catch (_) {
          dialerOpened = false;
        }
      }
      if (!_isNoResponseCallStarting(eventId)) return;

      if (callStarted || dialerOpened) {
        final handedOff = _copyEvent(
          updated,
          stateName: callStarted
              ? 'no_response_call_started'
              : 'no_response_call_handoff',
          updatedAt: DateTime.now(),
        );
        state = state.copyWith(
          currentEvent: handedOff,
          history: _replaceHistoryEvent(state.history, handedOff),
          machine: _machine.monitor(),
          notice: callStarted
              ? 'Nabi đã yêu cầu điện thoại gọi ${contact.name}. Tình trạng kết nối chưa được xác nhận.'
              : defaultTargetPlatform == TargetPlatform.iOS
              ? 'Đã mở yêu cầu gọi ${contact.name}. iPhone có thể yêu cầu xác nhận; tình trạng kết nối chưa được xác nhận.'
              : 'Đã mở ứng dụng Điện thoại cho ${contact.name}. Hãy kiểm tra số và bấm Gọi; cuộc gọi chưa được bắt đầu.',
          clearError: true,
          clearDispatchFailure: true,
        );
        try {
          await _persistNoResponseCallEvent(handedOff);
        } catch (_) {}
      } else {
        await _finishNoResponseCall(
          updated,
          stateName: 'no_response_call_failed',
          errorMessage:
              'Chưa thể mở cuộc gọi hoặc ứng dụng Điện thoại cho ${contact.name}. Cảnh báo vẫn hoạt động; hãy thử lại hoặc bấm “Tôi cần hỗ trợ”.',
        );
      }
    } finally {
      _handlingNoResponseCalls.remove(eventId);
    }
  }

  bool _isNoResponseCallHandedOff(String stateName) =>
      stateName == 'no_response_call_started' ||
      stateName == 'no_response_call_handoff';

  bool _isNoResponseCallRetryable(String stateName) => const {
    'no_response_call_failed',
    'no_response_call_unavailable',
    'no_response_call_interrupted',
  }.contains(stateName);

  String _noResponseCallErrorMessage(String stateName) => switch (stateName) {
    'no_response_call_unavailable' =>
      'Chưa có người liên hệ an toàn đang hoạt động cho phép gọi. Cảnh báo vẫn hoạt động; hãy thêm liên hệ hoặc bấm “Tôi cần hỗ trợ”.',
    'no_response_call_interrupted' =>
      'Nabi chưa xác định được kết quả cuộc gọi tự động trước đó. Cảnh báo vẫn hoạt động; hãy kiểm tra điện thoại hoặc thử gọi lại.',
    _ =>
      'Chưa thể mở cuộc gọi người hỗ trợ. Cảnh báo vẫn hoạt động; hãy thử lại hoặc bấm “Tôi cần hỗ trợ”.',
  };

  bool _isNoResponseCallStarting(String eventId) =>
      state.currentEvent?.id == eventId &&
      state.currentEvent?.response == SleepSafetyResponse.noResponse &&
      state.currentEvent?.state == 'no_response_call_starting';

  Future<void> _finishNoResponseCall(
    SleepSafetyEvent event, {
    required String stateName,
    required String errorMessage,
  }) async {
    final failed = _copyEvent(
      event,
      stateName: stateName,
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(
      currentEvent: failed,
      history: _replaceHistoryEvent(state.history, failed),
      machine: SleepSafetyMachineState(
        phase: SleepSafetyPhase.escalating,
        eventId: failed.id,
        alertStartedAt: state.machine.alertStartedAt,
      ),
      errorMessage: errorMessage,
      clearNotice: true,
    );
    try {
      await _persistNoResponseCallEvent(failed);
    } catch (_) {}
  }

  Future<void> _persistNoResponseCallEvent(SleepSafetyEvent event) =>
      _repository.updateEvent(event.id, {
        'response': event.response.name,
        'response_at': event.responseAt?.toIso8601String(),
        'state': event.state,
        'escalation_required': event.escalationRequired ? 1 : 0,
        'escalation_status': event.escalationStatus.name,
        'updated_at': event.updatedAt.toIso8601String(),
      });

  bool _pendingRetryCleanup = false;
  bool _pendingNativePhoneFallback = false;

  Future<void> _retireLegacyNoResponseRetries({String? eventId}) async {
    if (eventId != null) {
      try {
        await _repository.markEmergencyRetryFailed(
          id: 'sleep-safety-retry-$eventId',
          errorCode: 'no_response_local_phone_route',
        );
      } catch (_) {}
      return;
    }
    if (_pendingRetryCleanup) return;
    _pendingRetryCleanup = true;
    try {
      final entries = await _repository.listPendingEmergencyRetries();
      for (final entry in entries) {
        try {
          await _repository.markEmergencyRetryFailed(
            id: entry.id,
            errorCode: 'no_response_local_phone_route',
          );
        } catch (_) {
          // A stale outbox row must never restart the old backend route.
        }
      }
    } catch (_) {
      // Outbox cleanup must not stop native monitoring or local calling.
    } finally {
      _pendingRetryCleanup = false;
    }
  }

  SafetyContact? _phoneFallbackForNative() {
    return state.phoneFallbackContact;
  }

  Future<void> _updateNativePhoneFallbackConfig() async {
    if (!state.monitoringActive) return;
    final contact = _phoneFallbackForNative();
    try {
      await _repository.updateNativeConfig({
        'phoneFallbackEnabled': contact != null,
        'phoneFallbackE164': contact?.phoneE164 ?? '',
        'phoneFallbackPriority': contact?.priority ?? 0,
      });
    } catch (_) {
      // Native config is best effort; Flutter retains the explicit dial action.
    }
  }

  Future<void> callPhoneFallback({bool next = false}) async {
    final contacts = state.phoneFallbackContacts;
    if (contacts.isEmpty) {
      state = state.copyWith(
        errorMessage:
            'Chưa có người liên hệ đang hoạt động cho phép gọi. Hãy thêm hoặc bật quyền nhận cuộc gọi cho một liên hệ.',
      );
      return;
    }
    SafetyContact contact = contacts.first;
    if (next) {
      contact = contacts.firstWhere(
        (candidate) => candidate.priority > _lastPhoneFallbackPriority,
        orElse: () => contacts.first,
      );
    }
    _lastPhoneFallbackPriority = contact.priority;
    try {
      final opened = await ref
          .read(sleepSafetyPhoneGatewayProvider)
          .openDialer(contact.phoneE164, eventId: state.currentEvent?.id);
      state = state.copyWith(
        notice: opened
            ? 'Đã mở ứng dụng Điện thoại cho ${contact.name}. Cuộc gọi chưa được kết nối.'
            : 'Chưa thể mở ứng dụng Điện thoại. Bạn hãy gọi ${contact.name} bằng cách khác.',
        clearError: true,
      );
    } catch (_) {
      state = state.copyWith(
        errorMessage:
            'Chưa thể mở ứng dụng Điện thoại. Bạn hãy gọi ${contact.name} bằng cách khác.',
      );
    }
  }

  Future<void> _finishSession(String reason, {bool failed = false}) async {
    final session = state.session;
    if (session == null) {
      state = state.copyWith(
        machine: failed
            ? _machine.fail(reason)
            : const SleepSafetyMachineState.idle(),
        clearAudioMetrics: true,
        clearDetectorCandidate: true,
        audioSignalStale: false,
      );
      _stopAudioMetricsWatchdog();
      return;
    }

    final now = DateTime.now();
    final targetStatus =
        failed || session.status == SleepSafetySessionStatus.failed
        ? SleepSafetySessionStatus.failed
        : SleepSafetySessionStatus.stopped;
    final updated = SleepSafetySession(
      id: session.id,
      userId: session.userId,
      startedAt: session.startedAt,
      endedAt: now,
      scheduledWindowStart: session.scheduledWindowStart,
      scheduledWindowEnd: session.scheduledWindowEnd,
      sensitivity: session.sensitivity,
      calibrationNoiseFloor: session.calibrationNoiseFloor,
      status: targetStatus,
      startSource: session.startSource,
      stopReason: reason,
      platform: session.platform,
      appVersion: session.appVersion,
      createdAt: session.createdAt,
      updatedAt: now,
    );
    await _repository.saveSession(updated);
    state = state.copyWith(
      session: updated,
      machine: targetStatus == SleepSafetySessionStatus.failed
          ? _machine.fail(reason)
          : const SleepSafetyMachineState.idle(),
      clearCurrentEvent: true,
      calibrationProgress: 0,
      clearAudioMetrics: true,
      clearDetectorCandidate: true,
      audioSignalStale: false,
    );
    _stopAudioMetricsWatchdog();
  }

  void _ensureAudioMetricsWatchdog() {
    _audioMetricsWatchdog ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.monitoringActive) {
        _stopAudioMetricsWatchdog();
        return;
      }
      final metrics = state.audioMetrics;
      if (metrics == null) return;
      if (DateTime.now().difference(metrics.updatedAt) >
          const Duration(seconds: 2)) {
        state = state.copyWith(
          clearAudioMetrics: true,
          clearDetectorCandidate: true,
          audioSignalStale: true,
        );
      }
    });
  }

  void _stopAudioMetricsWatchdog() {
    _audioMetricsWatchdog?.cancel();
    _audioMetricsWatchdog = null;
  }

  double _unit(Object? value) =>
      ((value as num?)?.toDouble() ?? 0).clamp(0.0, 1.0).toDouble();

  String _nativeStartErrorMessage(String code) {
    return switch (code) {
      'microphone_permission_missing' || 'microphone_permission_lost' =>
        'NanoBio chưa có quyền micro để bắt đầu giám sát.',
      'microphone_fgs_not_allowed' =>
        'Android chưa cho phép bật giám sát lúc này. Hãy giữ NanoBio ở màn hình này rồi thử lại.',
      'service_not_registered' =>
        'Thành phần giám sát trên thiết bị chưa sẵn sàng. Hãy khởi động lại ứng dụng và thử lại.',
      'audio_buffer_unavailable' ||
      'audio_record_init_failed' ||
      'audio_capture_failed' =>
        'NanoBio chưa mở được micro trên thiết bị. Bạn kiểm tra quyền micro và thử lại nhé.',
      _ => 'Giám sát âm thanh vừa bị gián đoạn. Bạn có thể thử bật lại.',
    };
  }

  SleepSafetyEvent _copyEvent(
    SleepSafetyEvent v, {
    SleepSafetyResponse? response,
    DateTime? responseAt,
    String? stateName,
    bool? escalationRequired,
    SleepSafetyEscalationStatus? escalationStatus,
    required DateTime updatedAt,
  }) => SleepSafetyEvent(
    id: v.id,
    sessionId: v.sessionId,
    userId: v.userId,
    detectedAt: v.detectedAt,
    eventType: v.eventType,
    severity: v.severity,
    confidence: v.confidence,
    relativeEnergy: v.relativeEnergy,
    baselineDelta: v.baselineDelta,
    repetitionCount: v.repetitionCount,
    state: stateName ?? v.state,
    response: response ?? v.response,
    responseAt: responseAt ?? v.responseAt,
    escalationRequired: escalationRequired ?? v.escalationRequired,
    escalationStatus: escalationStatus ?? v.escalationStatus,
    createdAt: v.createdAt,
    updatedAt: updatedAt,
  );

  List<SleepSafetyEvent> _replaceHistoryEvent(
    List<SleepSafetyEvent> history,
    SleepSafetyEvent updated,
  ) => [
    for (final event in history)
      if (event.id == updated.id) updated else event,
  ];

  SleepSafetyEventType _eventType(String? raw) => switch (raw) {
    'suddenLoudSound' => SleepSafetyEventType.suddenLoudSound,
    'strongImpact' => SleepSafetyEventType.strongImpact,
    'abnormalShout' => SleepSafetyEventType.abnormalShout,
    'abnormalScream' => SleepSafetyEventType.abnormalScream,
    'repeatedSuspiciousPattern' =>
      SleepSafetyEventType.repeatedSuspiciousPattern,
    _ => SleepSafetyEventType.unknownHighEnergyEvent,
  };
  DateTime? _nextScheduleEnd(SleepSafetyPreference p, DateTime now) {
    if (!p.scheduleEnabled) return null;
    final h = p.scheduleEndMinutes ~/ 60, m = p.scheduleEndMinutes % 60;
    var end = DateTime(now.year, now.month, now.day, h, m);
    if (!end.isAfter(now)) end = end.add(const Duration(days: 1));
    return end;
  }

  String _normalizePhone(String raw) {
    var value = raw.trim().replaceAll(RegExp(r'[\s().-]'), '');
    if (value.startsWith('00')) value = '+${value.substring(2)}';
    if (value.startsWith('0')) value = '+84${value.substring(1)}';
    if (!RegExp(r'^\+[1-9][0-9]{7,14}$').hasMatch(value)) {
      throw const FormatException(
        'Số điện thoại chưa đúng định dạng. Hãy nhập số Việt Nam hoặc số quốc tế hợp lệ.',
      );
    }
    return value;
  }

  String _newId(String prefix) {
    final stamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final salt = _random.nextInt(1 << 32).toRadixString(36);
    return '$prefix-$stamp-$salt';
  }
}
