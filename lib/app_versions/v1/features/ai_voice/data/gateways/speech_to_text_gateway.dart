import 'dart:async';

import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

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
