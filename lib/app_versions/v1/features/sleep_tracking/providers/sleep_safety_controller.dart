import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v2/features/auth/providers/auth_providers.dart';
import '../data/gateways/sleep_safety_native_gateway.dart';
import '../domain/entities/safety_contact.dart';
import '../domain/entities/sleep_safety_event.dart';
import '../domain/entities/sleep_safety_preference.dart';
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
  });
  factory SleepSafetyViewState.initial() => const SleepSafetyViewState(
    machine: SleepSafetyMachineState.idle(), contacts: [], history: [],
  );
  final SleepSafetyMachineState machine;
  final SleepSafetyPreference? preference;
  final SleepSafetySession? session;
  final SleepSafetyEvent? currentEvent;
  final List<SafetyContact> contacts;
  final List<SleepSafetyEvent> history;
  final double calibrationProgress;
  final SleepSafetyAudioMetrics? audioMetrics;
  final String? detectorCandidateType;
  final bool audioSignalStale;
  final bool isBusy;
  final String? errorMessage;
  final String? notice;
  bool get monitoringActive => const {
    SleepSafetyPhase.arming, SleepSafetyPhase.calibrating, SleepSafetyPhase.monitoring,
    SleepSafetyPhase.awaitingResponse, SleepSafetyPhase.reminder, SleepSafetyPhase.escalating, SleepSafetyPhase.cooldown,
  }.contains(machine.phase);
  SleepSafetyViewState copyWith({
    SleepSafetyMachineState? machine, SleepSafetyPreference? preference, SleepSafetySession? session,
    SleepSafetyEvent? currentEvent, bool clearCurrentEvent=false, List<SafetyContact>? contacts,
    List<SleepSafetyEvent>? history, double? calibrationProgress,
    SleepSafetyAudioMetrics? audioMetrics, bool clearAudioMetrics=false,
    String? detectorCandidateType, bool clearDetectorCandidate=false,
    bool? audioSignalStale, bool? isBusy,
    String? errorMessage, bool clearError=false, String? notice, bool clearNotice=false,
  }) => SleepSafetyViewState(
    machine: machine ?? this.machine,
    preference: preference ?? this.preference,
    session: session ?? this.session,
    currentEvent: clearCurrentEvent ? null : currentEvent ?? this.currentEvent,
    contacts: contacts ?? this.contacts,
    history: history ?? this.history,
    calibrationProgress: calibrationProgress ?? this.calibrationProgress,
    audioMetrics: clearAudioMetrics ? null : audioMetrics ?? this.audioMetrics,
    detectorCandidateType: clearDetectorCandidate
        ? null
        : detectorCandidateType ?? this.detectorCandidateType,
    audioSignalStale: audioSignalStale ?? this.audioSignalStale,
    isBusy: isBusy ?? this.isBusy,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    notice: clearNotice ? null : notice ?? this.notice,
  );
}

class SleepSafetyController extends Notifier<SleepSafetyViewState> {
  final _machine = const SleepSafetyStateMachine();
  StreamSubscription<SleepSafetyNativeEvent>? _nativeSubscription;
  Timer? _audioMetricsWatchdog;
  final Set<String> _dispatchingEvents = <String>{};
  final Random _random = Random.secure();
  SleepSafetyRepository get _repository => ref.read(sleepSafetyRepositoryProvider);

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
    try {
      final preference = await _repository.loadPreference(userId);
      final results = await Future.wait<Object>([
        _repository.loadContacts(userId),
        _repository.listEvents(userId),
      ]);
      state = state.copyWith(
        preference: preference,
        contacts: results[0] as List<SafetyContact>,
        history: results[1] as List<SleepSafetyEvent>,
        clearError: true,
      );
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
    } catch (_) {
      state = state.copyWith(errorMessage: 'Nabi chưa tải được cài đặt giám sát. Bạn thử lại nhé.');
    }
  }

  Future<void> startMonitoring({String source = 'manual'}) async {
    final userId = ref.read(currentAuthUserIdProvider);
    final preference = state.preference;
    if (userId == null || preference == null || state.isBusy) return;

    SleepSafetySession? startingSession;
    var nativeStartRequested = false;
    state = state.copyWith(
      isBusy: true,
      clearError: true,
      clearNotice: true,
    );

    try {
      if (!ref.read(sleepSafetyRolloutApprovedProvider)) {
        throw StateError('rollout_disabled');
      }
      if (!await _repository.ensureMicrophonePermission()) {
        throw StateError('microphone_denied');
      }
      final notificationsAllowed =
          await ref.read(sleepSafetyNotificationPermissionProvider)();
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
      });

      state = state.copyWith(
        notice: state.contacts.any((contact) => contact.isVerified)
            ? null
            : 'Bạn chưa có người liên hệ đã xác minh. Cảnh báo tại máy vẫn hoạt động nhưng Nabi chưa thể liên hệ hỗ trợ qua cloud.',
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
    try { await _repository.stopNative(reason); await _finishSession(reason); }
    catch (_) { state = state.copyWith(errorMessage: 'Chưa thể dừng giám sát ngay. Bạn thử lại nhé.'); }
    finally { state = state.copyWith(isBusy: false); }
  }

  Future<void> respondOk() async {
    final event = state.currentEvent; if (event == null) return;
    await _repository.respondToAlert(event.id, 'ok');
    await _applyResponse(event.id, 'ok');
  }
  Future<void> requestHelp() async {
    final event = state.currentEvent; if (event == null) return;
    await _repository.respondToAlert(event.id, 'need_help');
    await _applyResponse(event.id, 'need_help');
  }

  Future<void> savePreference(SleepSafetyPreference preference) async {
    final updated = preference.copyWith(updatedAt: DateTime.now());
    await _repository.savePreference(updated);
    await ref.read(sleepSafetyReminderServiceProvider).apply(updated);
    await _repository.updateNativeConfig({'sensitivity':updated.sensitivity.name,'cooldownSeconds':updated.cooldownSeconds});
    state = state.copyWith(preference: updated, notice: 'Đã lưu cài đặt giám sát.');
  }

  Future<void> recalibrate() async {
    if (!state.monitoringActive) { state = state.copyWith(errorMessage: 'Hãy bắt đầu giám sát trước khi hiệu chỉnh lại âm thanh phòng.'); return; }
    await ref.read(sleepSafetyNativeGatewayProvider).startCalibration();
    state = state.copyWith(machine: _machine.calibrate(), calibrationProgress: 0);
  }

  Future<void> saveContact({String? id, required String name, required String relationship, required String phoneE164, required int priority}) async {
    state = state.copyWith(isBusy:true,clearError:true);
    try {
      await _repository.saveContact(id:id,name:name.trim(),relationship:relationship.trim(),phoneE164:_normalizePhone(phoneE164),priority:priority);
      await refreshContacts();
    } finally { state = state.copyWith(isBusy:false); }
  }
  Future<void> deleteContact(String id) async { await _repository.deleteContact(id); await refreshContacts(); }
  Future<void> requestVerification(String id) => _repository.requestContactVerification(id);
  Future<void> confirmVerification(String id,String code) async { await _repository.confirmContactVerification(id,code.trim()); await refreshContacts(); }
  Future<void> refreshContacts() async {
    final userId=ref.read(currentAuthUserIdProvider); if(userId==null)return;
    final contacts=await _repository.loadContacts(userId); state=state.copyWith(contacts:contacts);
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
          relativeEnergy: (event.data['relativeEnergy'] as num?)?.toDouble() ?? 0,
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
        calibrationProgress:
            ((event.data['progress'] as num?)?.toDouble() ?? 0).clamp(0, 1).toDouble(),
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
          SleepSafetyPhase.reminder,
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
    if (event.type == 'alertReminder') {
      state = state.copyWith(machine: _machine.tick(state.machine, now: now));
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
      if (eventId != null) await _escalate(eventId, noResponse: true);
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
      state = state.copyWith(
        errorMessage: _nativeStartErrorMessage(code),
      );
    }
  }

  Future<void> _restoreNativeStatus(SleepSafetyNativeEvent native) async {
    if (native.data['active'] != true) return;
    final sessionId = native.data['sessionId']?.toString();
    if (sessionId == null || sessionId.isEmpty) return;
    final session = await _repository.getSession(sessionId);
    if (session == null) return;

    final rawCurrent = native.data['currentEvent'];
    SleepSafetyEvent? current;
    if (rawCurrent is Map) {
      final data = Map<String, Object?>.from(rawCurrent);
      final eventId = data['eventId']?.toString();
      if (eventId != null && eventId.isNotEmpty) {
        current = await _repository.getEvent(eventId);
        if (current == null) {
          current = _eventFromNativeData(data, session, DateTime.now());
          await _repository.saveEvent(current);
        }
      }
    }

    final phase = native.data['phase']?.toString();
    SleepSafetyMachineState machine;
    if (phase == 'calibrating') {
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
    final restoredHistory = currentEvent == null ||
            state.history.any((item) => item.id == currentEvent.id)
        ? state.history
        : <SleepSafetyEvent>[currentEvent, ...state.history];
    state = state.copyWith(
      session: session,
      currentEvent: current,
      machine: machine,
      history: restoredHistory,
      calibrationProgress:
          ((native.data['calibrationProgress'] as num?)?.toDouble() ?? 0)
              .clamp(0, 1)
              .toDouble(),
    );
    _ensureAudioMetricsWatchdog();
    if (phase == 'escalating' &&
        current != null &&
        current.escalationStatus != SleepSafetyEscalationStatus.accepted) {
      await _escalate(current.id, noResponse: current.response != SleepSafetyResponse.needHelp);
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
      detectedAt: DateTime.tryParse(data['detectedAt']?.toString() ?? '') ?? now,
      eventType: _eventType(data['eventType']?.toString()),
      severity: data['severity']?.toString() ?? 'attention',
      confidence: (data['confidence'] as num?)?.toDouble() ?? 0.7,
      relativeEnergy: (data['relativeEnergy'] as num?)?.toDouble() ?? 0,
      baselineDelta: (data['baselineDelta'] as num?)?.toDouble() ?? 0,
      repetitionCount: (data['repetitionCount'] as num?)?.toInt() ?? 1,
      state: data['response'] == 'need_help' ? 'escalating' : 'awaiting_response',
      response: data['response'] == 'need_help'
          ? SleepSafetyResponse.needHelp
          : SleepSafetyResponse.none,
      escalationRequired: data['response'] == 'need_help',
      escalationStatus: data['response'] == 'need_help'
          ? SleepSafetyEscalationStatus.pending
          : SleepSafetyEscalationStatus.notRequired,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> _recordConfirmedEvent(SleepSafetyNativeEvent native,DateTime now) async {
    final session=state.session; final userId=ref.read(currentAuthUserIdProvider);
    if (session == null || userId == null) return;
    if (state.machine.phase != SleepSafetyPhase.monitoring &&
        state.machine.phase != SleepSafetyPhase.calibrating) {
      return;
    }
    final id=native.data['eventId']?.toString() ?? _newId('event');
    final event=SleepSafetyEvent(
      id:id,sessionId:session.id,userId:userId,detectedAt:DateTime.tryParse(native.data['detectedAt']?.toString() ?? '') ?? now,
      eventType:_eventType(native.data['eventType']?.toString()),severity:native.data['severity']?.toString() ?? 'attention',
      confidence:(native.data['confidence'] as num?)?.toDouble() ?? 0.7,relativeEnergy:(native.data['relativeEnergy'] as num?)?.toDouble() ?? 0,
      baselineDelta:(native.data['baselineDelta'] as num?)?.toDouble() ?? 0,repetitionCount:(native.data['repetitionCount'] as num?)?.toInt() ?? 1,
      state:'awaiting_response',response:SleepSafetyResponse.none,escalationRequired:false,
      escalationStatus:SleepSafetyEscalationStatus.notRequired,createdAt:now,updatedAt:now,
    );
    await _repository.saveEvent(event);
    state=state.copyWith(currentEvent:event,machine:_machine.onConfirmedEvent(state.machine,eventId:id,now:now),history:[event,...state.history]);
  }

  Future<void> _applyResponse(String eventId,String response) async {
    final current=state.currentEvent; if(current==null||current.id!=eventId)return;
    final now=DateTime.now();
    if(response=='ok'){
      final updated=_copyEvent(current,response:SleepSafetyResponse.ok,responseAt:now,stateName:'resolved_ok',updatedAt:now);
      await _repository.saveEvent(updated);
      state=state.copyWith(currentEvent:updated,machine:_machine.respondOk(state.machine,now:now,cooldown:Duration(seconds:state.preference?.cooldownSeconds ?? 120)));
      return;
    }
    if(response=='need_help'){
      final updated=_copyEvent(current,response:SleepSafetyResponse.needHelp,responseAt:now,stateName:'escalating',escalationRequired:true,escalationStatus:SleepSafetyEscalationStatus.pending,updatedAt:now);
      await _repository.saveEvent(updated); state=state.copyWith(currentEvent:updated,machine:_machine.respondNeedHelp(state.machine)); await _escalate(eventId);
    }
  }

  Future<void> _escalate(String eventId,{bool noResponse=false}) async {
    if(_dispatchingEvents.contains(eventId))return;
    final current=state.currentEvent; if(current==null||current.id!=eventId)return;
    _dispatchingEvents.add(eventId);
    final now=DateTime.now();
    var updated=_copyEvent(current,response:noResponse?SleepSafetyResponse.noResponse:current.response,responseAt:noResponse?now:current.responseAt,stateName:'dispatching',escalationRequired:true,escalationStatus:SleepSafetyEscalationStatus.dispatching,updatedAt:now);
    await _repository.saveEvent(updated); state=state.copyWith(currentEvent:updated,machine:SleepSafetyMachineState(phase:SleepSafetyPhase.escalating,eventId:eventId,alertStartedAt:state.machine.alertStartedAt));
    try {
      await _repository.dispatchEmergency(eventId, 'sleep-safety-$eventId');
      updated=_copyEvent(updated,stateName:'escalated',escalationStatus:SleepSafetyEscalationStatus.accepted,updatedAt:DateTime.now());
      await _repository.saveEvent(updated); state=state.copyWith(currentEvent:updated,notice:'Nabi đã gửi yêu cầu liên hệ người hỗ trợ đã xác minh.');
    } catch (_) {
      updated=_copyEvent(updated,stateName:'dispatch_failed',escalationStatus:SleepSafetyEscalationStatus.failed,updatedAt:DateTime.now());
      await _repository.saveEvent(updated); state=state.copyWith(currentEvent:updated,errorMessage:'Nabi chưa thể liên hệ người hỗ trợ. Cảnh báo tại điện thoại vẫn tiếp tục.');
    } finally { _dispatchingEvents.remove(eventId); }
  }

  Future<void> _finishSession(
    String reason, {
    bool failed = false,
  }) async {
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
    final targetStatus = failed || session.status == SleepSafetySessionStatus.failed
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
      if (DateTime.now().difference(metrics.updatedAt) > const Duration(seconds: 2)) {
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

  SleepSafetyEvent _copyEvent(SleepSafetyEvent v,{SleepSafetyResponse? response,DateTime? responseAt,String? stateName,bool? escalationRequired,SleepSafetyEscalationStatus? escalationStatus,required DateTime updatedAt}) => SleepSafetyEvent(
    id:v.id,sessionId:v.sessionId,userId:v.userId,detectedAt:v.detectedAt,eventType:v.eventType,severity:v.severity,confidence:v.confidence,
    relativeEnergy:v.relativeEnergy,baselineDelta:v.baselineDelta,repetitionCount:v.repetitionCount,state:stateName ?? v.state,response:response ?? v.response,
    responseAt:responseAt ?? v.responseAt,escalationRequired:escalationRequired ?? v.escalationRequired,escalationStatus:escalationStatus ?? v.escalationStatus,
    createdAt:v.createdAt,updatedAt:updatedAt,
  );
  SleepSafetyEventType _eventType(String? raw) => switch(raw){'suddenLoudSound'=>SleepSafetyEventType.suddenLoudSound,'strongImpact'=>SleepSafetyEventType.strongImpact,'abnormalShout'=>SleepSafetyEventType.abnormalShout,'abnormalScream'=>SleepSafetyEventType.abnormalScream,'repeatedSuspiciousPattern'=>SleepSafetyEventType.repeatedSuspiciousPattern,_=>SleepSafetyEventType.unknownHighEnergyEvent};
  DateTime? _nextScheduleEnd(SleepSafetyPreference p,DateTime now){ if(!p.scheduleEnabled)return null; final h=p.scheduleEndMinutes~/60,m=p.scheduleEndMinutes%60; var end=DateTime(now.year,now.month,now.day,h,m); if(!end.isAfter(now))end=end.add(const Duration(days:1)); return end; }
  String _normalizePhone(String raw){ var value=raw.replaceAll(RegExp(r'[^0-9+]'),''); if(value.startsWith('0'))value='+84${value.substring(1)}'; if(!value.startsWith('+')||value.length<9)throw const FormatException('Số điện thoại chưa đúng định dạng.'); return value; }
  String _newId(String prefix){ final stamp=DateTime.now().microsecondsSinceEpoch.toRadixString(36); final salt=_random.nextInt(1<<32).toRadixString(36); return '$prefix-$stamp-$salt'; }
}
