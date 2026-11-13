import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_whisper_ggml/flutter_whisper.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:nano_app/core/platform/web_runtime_support.dart' as web_support;
import '../../domain/gateways/voice_gateways.dart';

class DeviceSpeechRecognitionGateway implements SpeechRecognitionGateway {
  static const Duration _defaultStartTimeout = Duration(seconds: 3);
  static const Duration _defaultTerminalTimeout = Duration(seconds: 2);

  final SpeechToText _speech;
  final Duration _startTimeout;
  final Duration _terminalTimeout;

  bool _initialized = false;
  Future<bool>? _initializeOperation;
  Completer<String>? _activeListen;
  Completer<void>? _listenStarted;
  Completer<void>? _terminalStatus;
  Future<void>? _endOperation;
  String _latestTranscript = '';
  Object? _sessionFailure;
  bool _nativeSessionPending = false;
  bool _discardTranscript = false;
  Duration _silenceTimeout = const Duration(seconds: 1);
  bool _silenceTimeoutArmed = false;

  DeviceSpeechRecognitionGateway({
    SpeechToText? speech,
    Duration startTimeout = _defaultStartTimeout,
    Duration terminalTimeout = _defaultTerminalTimeout,
  }) : _speech = speech ?? SpeechToText(),
       _startTimeout = startTimeout,
       _terminalTimeout = terminalTimeout;

  @override
  Future<bool> initialize() async {
    if (_initialized) return _speech.isAvailable;

    final pending = _initializeOperation;
    if (pending != null) return pending;

    final operation = _initialize();
    _initializeOperation = operation;
    try {
      return await operation;
    } finally {
      if (identical(_initializeOperation, operation)) {
        _initializeOperation = null;
      }
    }
  }

  Future<bool> _initialize() async {
    _initialized = await _speech.initialize(
      onStatus: _handleStatus,
      onError: _handleError,
      options: <SpeechConfigOption>[SpeechToText.androidNoBluetooth],
    );
    if (!_initialized && !await _speech.hasPermission) {
      throw const SpeechRecognitionPermissionDeniedException();
    }
    return _initialized;
  }

  @override
  Future<String> listenOnce({
    String localeId = 'vi_VN',
    Duration listenFor = const Duration(minutes: 3),
    Duration pauseFor = const Duration(seconds: 1),
  }) async {
    if (!await initialize()) {
      throw const SpeechRecognitionUnavailableException();
    }
    if (_activeListen != null || _nativeSessionPending) {
      throw const SpeechRecognitionUnavailableException();
    }

    final completer = Completer<String>();
    final started = Completer<void>();
    final terminal = Completer<void>();
    _activeListen = completer;
    _listenStarted = started;
    _terminalStatus = terminal;
    _latestTranscript = '';
    _sessionFailure = null;
    _discardTranscript = false;
    _silenceTimeout = pauseFor;
    _silenceTimeoutArmed = false;
    _nativeSessionPending = true;

    try {
      await (() async {
        // speech_to_text 7.4.0 intentionally exposes an untyped Future here
        // and the public wrapper completes with null. Native start is confirmed
        // by the status callback instead of treating that null as a bool.
        await _speech.listen(
          onResult: _handleResult,
          listenOptions: SpeechListenOptions(
            localeId: localeId,
            listenFor: listenFor,
            // Do not pass the selected silence timeout at native start. The
            // speech_to_text timer starts immediately, so a 200 ms timeout
            // would close the microphone before the user begins speaking.
            // It is armed after the first non-empty recognition result.
            pauseFor: null,
            partialResults: true,
            cancelOnError: false,
            listenMode: ListenMode.dictation,
            autoPunctuation: true,
          ),
        );
        await started.future;
        _throwSessionFailureIfAny();
      })().timeout(_startTimeout);

      final transcript = await completer.future.timeout(
        listenFor + pauseFor + const Duration(seconds: 2),
        onTimeout: () async {
          await _endNativeSession(cancel: false);
          return _latestTranscript.trim();
        },
      );
      _throwSessionFailureIfAny();
      return transcript;
    } on SpeechRecognitionPermissionDeniedException {
      await _endNativeSession(cancel: true);
      rethrow;
    } on SpeechRecognitionUnavailableException {
      await _endNativeSession(cancel: true);
      rethrow;
    } on TimeoutException {
      await _endNativeSession(cancel: true);
      throw const SpeechRecognitionUnavailableException();
    } catch (_) {
      await _endNativeSession(cancel: true);
      throw const SpeechRecognitionUnavailableException();
    } finally {
      if (_nativeSessionPending) {
        await _endNativeSession(cancel: true);
      }
      if (identical(_activeListen, completer)) {
        _activeListen = null;
        _listenStarted = null;
        _terminalStatus = null;
      }
    }
  }

  void _handleResult(SpeechRecognitionResult result) {
    if (!_nativeSessionPending) return;
    _latestTranscript = result.recognizedWords.trim();
    if (_latestTranscript.isNotEmpty && !_silenceTimeoutArmed) {
      _silenceTimeoutArmed = true;
      try {
        // speech_to_text enforces this timer in Dart on both Android and iOS
        // and refreshes it when subsequent recognition results arrive.
        _speech.changePauseFor(_silenceTimeout);
      } catch (_) {
        // A terminal native callback can race the final partial result. The
        // normal done/notListening path below still settles the session.
      }
    }
    if (result.finalResult && _speech.isListening) {
      unawaited(_endNativeSession(cancel: false));
    }
  }

  void _handleStatus(String status) {
    if (!_nativeSessionPending) return;
    if (status == SpeechToText.listeningStatus) {
      final started = _listenStarted;
      if (started != null && !started.isCompleted) started.complete();
      return;
    }
    if (status != SpeechToText.doneStatus &&
        status != SpeechToText.notListeningStatus) {
      return;
    }

    _nativeSessionPending = false;
    final terminal = _terminalStatus;
    if (terminal != null && !terminal.isCompleted) terminal.complete();

    final started = _listenStarted;
    if (started != null && !started.isCompleted) {
      _sessionFailure = const SpeechRecognitionUnavailableException();
      started.complete();
    }
    _completeActive(_discardTranscript ? '' : _latestTranscript.trim());
  }

  void _handleError(SpeechRecognitionError error) {
    if (!_nativeSessionPending) return;
    final normalized = error.errorMsg.trim().toLowerCase();
    final exception =
        normalized.contains('permission') ||
            normalized.contains('recognizer_disabled')
        ? SpeechRecognitionPermissionDeniedException(
            permanentlyDenied: error.permanent,
          )
        : SpeechRecognitionUnavailableException(message: error.errorMsg);
    _sessionFailure = exception;
    _completeActive('');
    final started = _listenStarted;
    if (started != null && !started.isCompleted) started.complete();
  }

  void _completeActive(String transcript) {
    final completer = _activeListen;
    if (completer != null && !completer.isCompleted) {
      completer.complete(transcript);
    }
  }

  @override
  Future<void> stop() => _endNativeSession(cancel: false);

  @override
  Future<void> cancel() => _endNativeSession(cancel: true);

  Future<void> _endNativeSession({required bool cancel}) {
    if (cancel) _discardTranscript = true;
    if (!_nativeSessionPending) {
      _completeActive(_discardTranscript ? '' : _latestTranscript.trim());
      return Future<void>.value();
    }

    final pending = _endOperation;
    if (pending != null) return pending;

    late final Future<void> operation;
    operation = _finishNativeSession(cancel: cancel).whenComplete(() {
      if (identical(_endOperation, operation)) _endOperation = null;
    });
    _endOperation = operation;
    return operation;
  }

  Future<void> _finishNativeSession({required bool cancel}) async {
    try {
      if (cancel) {
        await _speech.cancel();
      } else {
        await _speech.stop();
      }
    } catch (_) {
      // Cleanup still settles locally so a failed native stop cannot leave the
      // microphone loop permanently blocked.
    }

    final terminal = _terminalStatus;
    if (terminal != null && !terminal.isCompleted) {
      try {
        await terminal.future.timeout(_terminalTimeout);
      } on TimeoutException {
        // The native recognizer occasionally omits its terminal callback. The
        // bounded cleanup prevents a second native start from overlapping it.
      }
    }

    if (_nativeSessionPending) {
      _nativeSessionPending = false;
      if (terminal != null && !terminal.isCompleted) terminal.complete();
      final started = _listenStarted;
      if (started != null && !started.isCompleted) {
        _sessionFailure = const SpeechRecognitionUnavailableException();
        started.complete();
      }
      _completeActive(_discardTranscript ? '' : _latestTranscript.trim());
    }
  }

  void _throwSessionFailureIfAny() {
    final failure = _sessionFailure;
    if (failure is SpeechRecognitionPermissionDeniedException) throw failure;
    if (failure is SpeechRecognitionUnavailableException) throw failure;
  }
}

/// Web voice input uses a local Whisper WebAssembly worker. Captured PCM stays
/// in browser memory and is never sent to the AI backend; only its text result
/// follows the existing chat request.
class BrowserWhisperSpeechRecognitionGateway
    implements SpeechRecognitionGateway {
  BrowserWhisperSpeechRecognitionGateway({AudioRecorder? recorder})
    : _recorder = recorder ?? AudioRecorder();

  static const _silenceThreshold = 420.0;
  static const _minimumSpeech = Duration(milliseconds: 350);
  static const _trailingSilence = Duration(milliseconds: 900);
  static const _maximumCapture = Duration(seconds: 25);

  final AudioRecorder _recorder;
  FlutterWhisper? _whisper;
  Completer<void>? _cancelCapture;
  bool _disposed = false;

  @override
  Future<bool> initialize() async {
    if (_disposed) throw StateError('Whisper voice session is disposed.');
    if (!kIsWeb) return false;
    if (!web_support.isSecureCrossOriginIsolated) {
      throw const SpeechRecognitionUnavailableException(
        message:
            'WebAssembly cần kết nối an toàn và cấu hình trình duyệt phù hợp. Hãy nhấn “Nhập chữ” để tiếp tục bằng văn bản.',
      );
    }
    try {
      if (!await _recorder.hasPermission()) {
        throw const SpeechRecognitionPermissionDeniedException();
      }
      _whisper ??= await FlutterWhisper.loadModel(
        model: WhisperModels.tinyQ5_1,
        config: const WhisperModelConfig(useGpu: false),
      );
      return true;
    } on SpeechRecognitionPermissionDeniedException {
      rethrow;
    } catch (_) {
      throw const SpeechRecognitionUnavailableException(
        message:
            'Whisper trên web chưa sẵn sàng. Hãy nhấn “Nhập chữ” để tiếp tục bằng văn bản.',
      );
    }
  }

  @override
  Future<String> listenOnce({
    String localeId = 'vi_VN',
    Duration listenFor = const Duration(minutes: 3),
    Duration pauseFor = const Duration(seconds: 1),
  }) async {
    if (_disposed || _whisper == null) {
      throw const SpeechRecognitionUnavailableException();
    }
    final audio = BytesBuilder(copy: false);
    final finished = Completer<void>();
    final cancelled = Completer<void>();
    _cancelCapture = cancelled;
    var bytesReceived = 0;
    var speechStartedAt = 0;
    var lastVoiceAt = 0;
    StreamSubscription<Uint8List>? subscription;
    Timer? timeout;

    try {
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
          autoGain: true,
          echoCancel: true,
          noiseSuppress: true,
        ),
      );
      final clock = Stopwatch()..start();
      final captureDuration = listenFor < _maximumCapture
          ? listenFor
          : _maximumCapture;
      final trailingSilence = pauseFor < _trailingSilence
          ? pauseFor
          : _trailingSilence;
      timeout = Timer(captureDuration, () {
        if (!finished.isCompleted) finished.complete();
      });
      subscription = stream.listen(
        (chunk) {
          if (chunk.isEmpty || finished.isCompleted) return;
          audio.add(chunk);
          bytesReceived += chunk.length;
          final sampleCount = chunk.length ~/ 2;
          final byteData = ByteData.sublistView(chunk);
          var energy = 0.0;
          for (var index = 0; index < sampleCount; index++) {
            final sample = byteData
                .getInt16(index * 2, Endian.little)
                .toDouble();
            energy += sample * sample;
          }
          final rms = sampleCount == 0 ? 0 : math.sqrt(energy / sampleCount);
          final elapsed = clock.elapsedMilliseconds;
          if (rms >= _silenceThreshold) {
            speechStartedAt = elapsed;
            lastVoiceAt = elapsed;
          }
          final enoughSpeech =
              speechStartedAt > 0 &&
              elapsed - speechStartedAt >= _minimumSpeech.inMilliseconds;
          if (enoughSpeech &&
              elapsed - lastVoiceAt >= trailingSilence.inMilliseconds &&
              !finished.isCompleted) {
            finished.complete();
          }
          if (bytesReceived >= 16000 * 2 * captureDuration.inSeconds &&
              !finished.isCompleted) {
            finished.complete();
          }
        },
        onError: (Object error, StackTrace stack) {
          if (!finished.isCompleted) finished.completeError(error, stack);
        },
        onDone: () {
          if (!finished.isCompleted) finished.complete();
        },
        cancelOnError: true,
      );
      await Future.any([finished.future, cancelled.future]);
      if (cancelled.isCompleted) return '';
      await _recorder.stop();
      await subscription.cancel();
      subscription = null;
      timeout.cancel();
      timeout = null;

      final bytes = audio.takeBytes();
      final sampleCount = bytes.length ~/ 2;
      if (sampleCount < 16000 * 0.35) return '';
      final samples = Float32List(sampleCount);
      final byteData = ByteData.sublistView(bytes);
      for (var index = 0; index < sampleCount; index++) {
        samples[index] = byteData.getInt16(index * 2, Endian.little) / 32768.0;
      }
      final result = await _whisper!.transcribe(
        samples,
        config: const WhisperTranscribeConfig(
          language: 'vi',
          threads: 2,
          noContext: true,
        ),
      );
      return result.text.trim();
    } finally {
      if (identical(_cancelCapture, cancelled)) _cancelCapture = null;
      timeout?.cancel();
      await subscription?.cancel();
      try {
        await _recorder.stop();
      } catch (_) {
        // The browser may already have stopped the stream.
      }
    }
  }

  @override
  Future<void> stop() async {
    final cancelled = _cancelCapture;
    if (cancelled != null && !cancelled.isCompleted) cancelled.complete();
    await _recorder.stop();
  }

  @override
  Future<void> cancel() async {
    _whisper?.cancel();
    await stop();
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await cancel();
    await _recorder.dispose();
    await _whisper?.dispose();
  }
}
