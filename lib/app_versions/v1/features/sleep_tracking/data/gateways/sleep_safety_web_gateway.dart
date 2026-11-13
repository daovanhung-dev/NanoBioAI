import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:record/record.dart';

import 'sleep_safety_native_gateway.dart';

/// Foreground-only browser monitor. Audio is reduced to transient numeric
/// features; the captured PCM is never persisted or sent to a server.
class BrowserSleepSafetyGateway implements SleepSafetyNativeGateway {
  BrowserSleepSafetyGateway({AudioRecorder? recorder})
    : _recorder = recorder ?? AudioRecorder();

  static const _frameSamples = 1024;
  static const _metricsInterval = Duration(milliseconds: 160);
  static const _candidateInterval = Duration(milliseconds: 300);
  static const _calibrationDuration = Duration(seconds: 30);

  final AudioRecorder _recorder;
  final StreamController<SleepSafetyNativeEvent> _events =
      StreamController<SleepSafetyNativeEvent>.broadcast();
  final Queue<int> _samples = Queue<int>();
  StreamSubscription<Uint8List>? _audioSubscription;
  Timer? _scheduleTimer;
  Timer? _escalationTimer;
  Timer? _cooldownTimer;
  _BrowserSleepSafetyDetector? _detector;
  Map<String, Object?> _config = const {};
  Map<String, Object?>? _currentEvent;
  String? _sessionId;
  String _phase = 'idle';
  bool _active = false;
  bool _detectionSuppressed = false;
  DateTime? _lastMetricsAt;
  DateTime? _lastCandidateAt;

  @override
  Stream<SleepSafetyNativeEvent> get events => _events.stream;

  @override
  Future<bool> ensureMicrophonePermission() => _recorder.hasPermission();

  @override
  Future<void> startMonitoring(Map<String, Object?> config) async {
    if (_active) return;
    if (!await ensureMicrophonePermission()) {
      throw const SleepSafetyNativeStartException('microphone_denied');
    }
    _config = Map<String, Object?>.unmodifiable(config);
    _sessionId = config['sessionId']?.toString();
    if (_sessionId == null || _sessionId!.isEmpty) {
      throw const SleepSafetyNativeStartException('invalid_session');
    }
    final requestedFloor = (config['calibrationNoiseFloor'] as num?)
        ?.toDouble();
    final calibrationRequired = config['calibrationRequired'] == true;
    _detector = _BrowserSleepSafetyDetector(
      sensitivity: config['sensitivity']?.toString() ?? 'balanced',
      initialNoiseFloor: calibrationRequired ? null : requestedFloor,
    );
    _samples.clear();

    try {
      final audioStream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
          autoGain: true,
          echoCancel: true,
          noiseSuppress: true,
        ),
      );
      _active = true;
      _phase = _detector!.isCalibrating ? 'calibrating' : 'monitoring';
      _audioSubscription = audioStream.listen(
        _handleAudio,
        onError: (Object error, StackTrace stackTrace) {
          final code = error.toString().toLowerCase().contains('permission')
              ? 'microphone_permission_lost'
              : 'audio_capture_failed';
          _emit(
            code.startsWith('microphone') ? 'permissionLost' : 'nativeFailure',
            {'code': code},
          );
          unawaited(stopMonitoring(code));
        },
        onDone: () {
          if (_active) unawaited(stopMonitoring('audio_capture_stopped'));
        },
        cancelOnError: true,
      );
      _emit('serviceStarted');
      if (_phase == 'monitoring') _emit('monitoringReady');
      final endEpochMs = (config['scheduledEndEpochMs'] as num?)?.toInt();
      if (endEpochMs != null && endEpochMs > 0) {
        final delay = DateTime.fromMillisecondsSinceEpoch(
          endEpochMs,
        ).difference(DateTime.now());
        if (delay <= Duration.zero) {
          unawaited(stopMonitoring('schedule_end'));
        } else {
          _scheduleTimer = Timer(delay, () {
            unawaited(stopMonitoring('schedule_end'));
          });
        }
      }
    } on SleepSafetyNativeStartException {
      rethrow;
    } catch (error) {
      await _cleanupCapture();
      throw SleepSafetyNativeStartException(
        error.toString().toLowerCase().contains('permission')
            ? 'microphone_denied'
            : 'browser_audio_start_failed',
      );
    }
  }

  void _handleAudio(Uint8List bytes) {
    if (!_active || bytes.length < 2) return;
    for (var index = 0; index + 1 < bytes.length; index += 2) {
      final sample = bytes[index] | (bytes[index + 1] << 8);
      _samples.add(sample >= 0x8000 ? sample - 0x10000 : sample);
    }
    while (_samples.length >= _frameSamples) {
      final frame = Int16List(_frameSamples);
      for (var index = 0; index < _frameSamples; index++) {
        frame[index] = _samples.removeFirst();
      }
      _processFrame(frame);
    }
  }

  void _processFrame(Int16List frame) {
    final detector = _detector;
    if (!_active || detector == null) return;
    final now = DateTime.now();
    final output = detector.process(frame, now);
    if (output == null) return;

    final lastMetrics = _lastMetricsAt;
    if (lastMetrics == null ||
        now.difference(lastMetrics) >= _metricsInterval) {
      _lastMetricsAt = now;
      _emit('audioMetrics', {
        'signalLevel': output.signalLevel,
        'peakLevel': output.peakLevel,
        'relativeEnergy': output.relativeEnergy,
        'baselineLevel': output.baselineLevel,
        'phase': _detectionSuppressed ? _phase : output.phase,
        'capturedAtEpochMs': now.millisecondsSinceEpoch,
      });
    }

    if (output.calibrationProgress != null) {
      _emit('calibrationProgress', {'progress': output.calibrationProgress});
    }
    if (output.completedNoiseFloor != null) {
      _phase = 'monitoring';
      _emit('calibrationCompleted', {'noiseFloor': output.completedNoiseFloor});
      _emit('monitoringReady');
    }
    if (_detectionSuppressed) return;

    final event = output.confirmedEvent;
    if (event != null) {
      _beginAlert(event, now);
      return;
    }
    final candidateType = output.candidateType;
    final lastCandidate = _lastCandidateAt;
    if (candidateType != null &&
        (lastCandidate == null ||
            now.difference(lastCandidate) >= _candidateInterval)) {
      _lastCandidateAt = now;
      _emit('detectorCandidate', {
        'eventType': candidateType,
        'relativeEnergy': output.relativeEnergy,
        'signalLevel': output.signalLevel,
      });
    }
  }

  void _beginAlert(_BrowserSafetyEvent event, DateTime now) {
    if (_currentEvent != null) return;
    final data = <String, Object?>{
      'eventId': 'web-${now.microsecondsSinceEpoch}',
      'detectedAt': now.toUtc().toIso8601String(),
      'eventType': event.eventType,
      'severity': event.relativeEnergy >= 5 || event.confidence >= 0.9
          ? 'high'
          : 'attention',
      'confidence': event.confidence,
      'relativeEnergy': event.relativeEnergy,
      'baselineDelta': event.baselineDelta,
      'repetitionCount': event.repetitionCount,
    };
    _currentEvent = data;
    _detectionSuppressed = true;
    _phase = 'alerting';
    _emit('confirmedSafetyEvent', data);
    _escalationTimer?.cancel();
    _escalationTimer = Timer(const Duration(seconds: 15), () {
      if (_currentEvent?['eventId'] == data['eventId']) {
        _phase = 'escalating';
        _emit('escalationRequired', {'eventId': data['eventId']});
      }
    });
  }

  @override
  Future<void> stopMonitoring(String reason) async {
    if (!_active) return;
    _active = false;
    _phase = 'stopping';
    _scheduleTimer?.cancel();
    _scheduleTimer = null;
    _escalationTimer?.cancel();
    _escalationTimer = null;
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
    await _cleanupCapture();
    _phase = 'idle';
    _emit('serviceStopped', {'reason': reason});
  }

  Future<void> _cleanupCapture() async {
    final subscription = _audioSubscription;
    _audioSubscription = null;
    await subscription?.cancel();
    try {
      await _recorder.stop();
    } catch (_) {
      // The browser may already have released the microphone stream.
    }
    _samples.clear();
  }

  @override
  Future<void> startCalibration() async {
    if (!_active) return;
    _detector?.startCalibration(_calibrationDuration);
    _phase = 'calibrating';
    _emit('calibrationProgress', {'progress': 0.0});
  }

  @override
  Future<void> updateRuntimeConfig(Map<String, Object?> config) async {
    _config = {..._config, ...config};
    final sensitivity = config['sensitivity']?.toString();
    if (sensitivity != null) _detector?.updateSensitivity(sensitivity);
  }

  @override
  Future<void> respondToAlert({
    required String eventId,
    required String response,
  }) async {
    if (_currentEvent?['eventId'] != eventId) return;
    _escalationTimer?.cancel();
    _escalationTimer = null;
    _currentEvent = {...?_currentEvent, 'response': response};
    _emit('userResponse', {'eventId': eventId, 'response': response});
    if (response == 'need_help') {
      _phase = 'escalating';
      return;
    }
    _currentEvent = null;
    _phase = 'cooldown';
    final cooldown = ((_config['cooldownSeconds'] as num?)?.toInt() ?? 120)
        .clamp(30, 900);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer(Duration(seconds: cooldown), () {
      if (!_active) return;
      _detectionSuppressed = false;
      _phase = 'monitoring';
      _emit('monitoringReady');
    });
  }

  @override
  Future<void> dismissAlert({required String eventId}) async {
    if (_currentEvent?['eventId'] != eventId) return;
    _escalationTimer?.cancel();
    _escalationTimer = null;
    _currentEvent = null;
    _detectionSuppressed = false;
    _phase = 'monitoring';
    _emit('monitoringReady');
  }

  @override
  Future<Map<String, Object?>> getMonitoringStatus() async => {
    'active': _active,
    if (_sessionId != null) 'sessionId': _sessionId,
    'phase': _phase,
    if (_currentEvent != null) 'currentEvent': _currentEvent,
  };

  void _emit(String type, [Map<String, Object?> data = const {}]) {
    if (!_events.isClosed) {
      _events.add(SleepSafetyNativeEvent(type: type, data: data));
    }
  }
}

class _BrowserSleepSafetyDetector {
  _BrowserSleepSafetyDetector({
    required this.sensitivity,
    double? initialNoiseFloor,
  }) : noiseFloor = initialNoiseFloor == null || initialNoiseFloor <= 0.00001
           ? _defaultNoiseFloor
           : initialNoiseFloor.clamp(_minNoiseFloor, _maxNoiseFloor),
       _calibrating =
           initialNoiseFloor == null || initialNoiseFloor <= 0.00001 {
    if (_calibrating) _calibrationStartedAt = DateTime.now();
  }

  static const _minNoiseFloor = 0.0005;
  static const _maxNoiseFloor = 0.12;
  static const _defaultNoiseFloor = 0.006;
  static const _meterFloorDb = -56.0;
  static const _meterCeilingDb = -4.0;
  static const _burstWindow = Duration(milliseconds: 2500);

  String sensitivity;
  double noiseFloor;
  bool _calibrating;
  Duration _calibrationDuration = const Duration(seconds: 30);
  DateTime? _calibrationStartedAt;
  DateTime? _lastProgressAt;
  final List<double> _calibrationSamples = [];
  final Queue<double> _rollingRms = Queue<double>();
  int _sustainedFrames = 0;
  int _burstCount = 0;
  DateTime? _lastBurstAt;

  bool get isCalibrating => _calibrating;

  void updateSensitivity(String value) => sensitivity = value;

  void startCalibration(Duration duration) {
    _calibrationDuration = duration;
    _calibrationStartedAt = DateTime.now();
    _lastProgressAt = null;
    _calibrationSamples.clear();
    _rollingRms.clear();
    _sustainedFrames = 0;
    _burstCount = 0;
    _lastBurstAt = null;
    _calibrating = true;
  }

  _BrowserSafetyFrameResult? process(Int16List samples, DateTime now) {
    if (samples.isEmpty) return null;
    var sumSquares = 0.0;
    var peak = 0.0;
    var zeroCrossings = 0;
    var previous = 0.0;
    for (var index = 0; index < samples.length; index++) {
      final normalized = samples[index] / 32767.0;
      sumSquares += normalized * normalized;
      peak = math.max(peak, normalized.abs());
      if (index > 0 &&
          ((previous < 0 && normalized >= 0) ||
              (previous >= 0 && normalized < 0))) {
        zeroCrossings++;
      }
      previous = normalized;
    }

    final rms = math.sqrt(sumSquares / samples.length).clamp(0.000001, 1.0);
    final zeroCrossingRate = zeroCrossings / samples.length;
    final baseline = _calibrating ? _provisionalFloor : noiseFloor;
    final relative = rms / math.max(baseline, _minNoiseFloor);
    final delta = math.max(0.0, rms - baseline);
    final peakRatio = peak / math.max(rms, _minNoiseFloor);
    final priorAverage = math.max(_rollingAverage, baseline);
    final attackRatio = rms / math.max(priorAverage, _minNoiseFloor);
    _rollingRms.addLast(rms);
    while (_rollingRms.length > 12) {
      _rollingRms.removeFirst();
    }

    if (_calibrating) {
      _calibrationSamples.add(rms);
      final start = _calibrationStartedAt ?? now;
      final elapsed = now.difference(start);
      final progress =
          (elapsed.inMilliseconds / _calibrationDuration.inMilliseconds).clamp(
            0.0,
            1.0,
          );
      final shouldPublish =
          _lastProgressAt == null ||
          now.difference(_lastProgressAt!) >= const Duration(seconds: 1);
      if (shouldPublish) _lastProgressAt = now;
      _BrowserSafetyEvent? bypass;
      final threshold = _thresholds;
      if (peak >= 0.92 ||
          rms >= math.max(0.18, threshold.extremeRms) ||
          (rms >= math.max(0.075, threshold.minimumRms) &&
              peak >= 0.4 &&
              relative >= 4.8)) {
        final vocalLike = zeroCrossingRate >= 0.055 && zeroCrossingRate <= 0.36;
        final type = peakRatio >= 3.2 && peak >= 0.82
            ? 'strongImpact'
            : vocalLike && rms >= 0.10
            ? 'abnormalScream'
            : 'suddenLoudSound';
        bypass = _BrowserSafetyEvent(
          eventType: type,
          confidence: (0.76 + math.min(0.20, attackRatio / 10)).clamp(
            0.0,
            0.98,
          ),
          relativeEnergy: relative,
          baselineDelta: math.max(0.0, rms - _provisionalFloor),
          repetitionCount: 1,
        );
      }
      double? completedFloor;
      if (elapsed >= _calibrationDuration && _calibrationSamples.isNotEmpty) {
        noiseFloor = _robustFloor(_calibrationSamples);
        _calibrating = false;
        completedFloor = noiseFloor;
      }
      return _BrowserSafetyFrameResult(
        signalLevel: _amplitudeToLevel(rms),
        peakLevel: _amplitudeToLevel(peak),
        relativeEnergy: relative.clamp(0.0, 50.0),
        baselineLevel: _amplitudeToLevel(baseline),
        phase: bypass == null ? 'calibrating' : 'candidate',
        confirmedEvent: bypass,
        candidateType: bypass?.eventType,
        calibrationProgress: shouldPublish ? progress : null,
        completedNoiseFloor: completedFloor,
      );
    }

    final thresholds = _thresholds;
    final highEnergy =
        relative >= thresholds.relative && rms >= thresholds.minimumRms;
    _sustainedFrames = highEnergy
        ? math.min(12, _sustainedFrames + 1)
        : math.max(0, _sustainedFrames - 1);
    if (relative < 1.65 && peak < 0.42 && rms < thresholds.minimumRms) {
      noiseFloor = (noiseFloor * 0.996 + rms * 0.004).clamp(
        _minNoiseFloor,
        _maxNoiseFloor,
      );
    }

    final extreme =
        peak >= thresholds.extremePeak ||
        rms >= thresholds.extremeRms ||
        (rms >= thresholds.minimumRms * 1.7 &&
            peak >= thresholds.extremePeak * 0.82);
    final impact = peak >= 0.72 && peakRatio >= 3.0 && attackRatio >= 2.0;
    final vocalLike = zeroCrossingRate >= 0.055 && zeroCrossingRate <= 0.36;
    final scream =
        vocalLike &&
        _sustainedFrames >= 2 &&
        relative >= thresholds.relative * 1.15 &&
        rms >= thresholds.minimumRms;
    final shout =
        _sustainedFrames >= 2 &&
        relative >= thresholds.relative &&
        rms >= thresholds.minimumRms;
    final sudden =
        extreme ||
        (relative >= thresholds.relative * 1.35 &&
            rms >= thresholds.minimumRms) ||
        (attackRatio >= 2.35 &&
            relative >= thresholds.relative &&
            rms >= thresholds.minimumRms);
    final candidateType = impact
        ? 'strongImpact'
        : scream
        ? 'abnormalScream'
        : shout
        ? 'abnormalShout'
        : sudden
        ? 'suddenLoudSound'
        : null;
    if (candidateType != null) {
      _registerBurst(now);
    } else if (_lastBurstAt != null &&
        now.difference(_lastBurstAt!) > _burstWindow) {
      _burstCount = 0;
    }
    final repeated =
        _burstCount >= 3 &&
        _lastBurstAt != null &&
        now.difference(_lastBurstAt!) <= _burstWindow;
    final resolvedType = impact
        ? 'strongImpact'
        : scream
        ? 'abnormalScream'
        : repeated
        ? 'repeatedSuspiciousPattern'
        : shout
        ? 'abnormalShout'
        : sudden
        ? 'suddenLoudSound'
        : null;
    final confirmed =
        resolvedType != null &&
        (impact ||
            extreme ||
            repeated ||
            (scream && _sustainedFrames >= 2) ||
            (shout && (_sustainedFrames >= 3 || attackRatio >= 2.0)) ||
            (sudden &&
                (relative >= thresholds.relative * 1.6 || attackRatio >= 2.6)));
    final confidence = _confidence(
      relative: relative,
      rms: rms,
      peak: peak,
      attackRatio: attackRatio,
      thresholds: thresholds,
      extreme: extreme,
    );
    final event = confirmed
        ? _BrowserSafetyEvent(
            eventType: resolvedType,
            confidence: confidence,
            relativeEnergy: relative,
            baselineDelta: delta,
            repetitionCount: math.max(1, _burstCount),
          )
        : null;
    return _BrowserSafetyFrameResult(
      signalLevel: _amplitudeToLevel(rms),
      peakLevel: _amplitudeToLevel(peak),
      relativeEnergy: relative.clamp(0.0, 50.0),
      baselineLevel: _amplitudeToLevel(noiseFloor),
      phase: event != null
          ? 'alerting'
          : resolvedType != null
          ? 'candidate'
          : 'monitoring',
      confirmedEvent: event,
      candidateType: resolvedType,
    );
  }

  _BrowserSafetyThresholds get _thresholds => switch (sensitivity) {
    'high' => const _BrowserSafetyThresholds(1.9, 0.032, 0.12, 0.78),
    'low' => const _BrowserSafetyThresholds(3.1, 0.065, 0.20, 0.92),
    _ => const _BrowserSafetyThresholds(2.35, 0.045, 0.15, 0.86),
  };

  double get _rollingAverage => _rollingRms.isEmpty
      ? noiseFloor
      : _rollingRms.reduce((left, right) => left + right) / _rollingRms.length;

  double get _provisionalFloor => _calibrationSamples.length < 4
      ? math.max(noiseFloor, _defaultNoiseFloor)
      : _robustFloor(_calibrationSamples);

  void _registerBurst(DateTime now) {
    _burstCount =
        _lastBurstAt != null && now.difference(_lastBurstAt!) <= _burstWindow
        ? math.min(8, _burstCount + 1)
        : 1;
    _lastBurstAt = now;
  }

  double _robustFloor(List<double> values) {
    if (values.isEmpty) return _defaultNoiseFloor;
    final sorted = [...values]..sort();
    final retained = sorted.take(math.max(1, (sorted.length * 0.85).floor()));
    final list = retained.toList(growable: false);
    final middle = list.length ~/ 2;
    final median = list.length.isEven && list.length > 1
        ? (list[middle - 1] + list[middle]) / 2
        : list[middle];
    final average = list.reduce((left, right) => left + right) / list.length;
    return (median * 0.7 + average * 0.3).clamp(_minNoiseFloor, _maxNoiseFloor);
  }

  double _confidence({
    required double relative,
    required double rms,
    required double peak,
    required double attackRatio,
    required _BrowserSafetyThresholds thresholds,
    required bool extreme,
  }) {
    if (extreme) return 0.95;
    final relativeScore = (relative / (thresholds.relative * 2)).clamp(
      0.0,
      1.0,
    );
    final levelScore = (rms / (thresholds.minimumRms * 3)).clamp(0.0, 1.0);
    final peakScore = (peak / 0.90).clamp(0.0, 1.0);
    final attackScore = (attackRatio / 3).clamp(0.0, 1.0);
    final persistenceScore = (_sustainedFrames / 4).clamp(0.0, 1.0);
    return (relativeScore * 0.32 +
            levelScore * 0.22 +
            peakScore * 0.16 +
            attackScore * 0.14 +
            persistenceScore * 0.16)
        .clamp(0.0, 0.96);
  }

  double _amplitudeToLevel(double amplitude) {
    final safe = math.max(amplitude, 0.000001);
    final db = 20 * math.log(safe) / math.ln10;
    return ((db - _meterFloorDb) / (_meterCeilingDb - _meterFloorDb)).clamp(
      0.0,
      1.0,
    );
  }
}

class _BrowserSafetyThresholds {
  const _BrowserSafetyThresholds(
    this.relative,
    this.minimumRms,
    this.extremeRms,
    this.extremePeak,
  );

  final double relative;
  final double minimumRms;
  final double extremeRms;
  final double extremePeak;
}

class _BrowserSafetyEvent {
  const _BrowserSafetyEvent({
    required this.eventType,
    required this.confidence,
    required this.relativeEnergy,
    required this.baselineDelta,
    required this.repetitionCount,
  });

  final String eventType;
  final double confidence;
  final double relativeEnergy;
  final double baselineDelta;
  final int repetitionCount;
}

class _BrowserSafetyFrameResult {
  const _BrowserSafetyFrameResult({
    required this.signalLevel,
    required this.peakLevel,
    required this.relativeEnergy,
    required this.baselineLevel,
    required this.phase,
    this.confirmedEvent,
    this.candidateType,
    this.calibrationProgress,
    this.completedNoiseFloor,
  });

  final double signalLevel;
  final double peakLevel;
  final double relativeEnergy;
  final double baselineLevel;
  final String phase;
  final _BrowserSafetyEvent? confirmedEvent;
  final String? candidateType;
  final double? calibrationProgress;
  final double? completedNoiseFloor;
}
