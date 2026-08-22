import 'dart:async';

import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../domain/entities/speech_recognition_event.dart';
import '../../domain/gateways/voice_gateways.dart';
import '../../domain/speech_transcript_merger.dart';

class DeviceSpeechRecognitionGateway
    implements SpeechRecognitionGateway, RealtimeSpeechRecognitionCapability {
  final SpeechToText _speech;

  bool _initialized = false;
  int _sessionSerial = 0;
  int _generation = 0;
  StreamController<SpeechRecognitionEvent>? _controller;
  Completer<void>? _segmentDone;
  String _committedTranscript = '';
  String _latestTranscript = '';
  DateTime? _firstSpeechAt;
  DateTime? _segmentStartedAt;
  bool _segmentFinal = false;
  bool _segmentHadSpeech = false;
  Object? _segmentError;
  Duration _currentListenFor = const Duration(seconds: 50);
  Duration _maxUtteranceDuration = const Duration(minutes: 3);
  bool _awaitingBoundaryContinuation = false;
  Timer? _boundaryContinuationTimer;

  DeviceSpeechRecognitionGateway({SpeechToText? speech})
      : _speech = speech ?? SpeechToText();

  @override
  Future<bool> initialize() async {
    if (_initialized) return _speech.isAvailable;

    _initialized = await _speech.initialize(
      onStatus: _handleStatus,
      onError: _handleError,
    );
    if (!_initialized && !await _speech.hasPermission) {
      throw const SpeechRecognitionPermissionDeniedException();
    }
    return _initialized;
  }

  @override
  Future<Stream<SpeechRecognitionEvent>> startRealtimeSession({
    String localeId = 'vi_VN',
    Duration maxUtteranceDuration = const Duration(minutes: 3),
    Duration segmentDuration = const Duration(seconds: 50),
    Duration pauseFor = const Duration(milliseconds: 1300),
  }) async {
    final available = await initialize();
    if (!available) throw const SpeechRecognitionUnavailableException();

    await cancel();
    final serial = ++_sessionSerial;
    _generation = 0;
    _committedTranscript = '';
    _latestTranscript = '';
    _firstSpeechAt = null;
    _segmentError = null;
    _awaitingBoundaryContinuation = false;
    _boundaryContinuationTimer?.cancel();
    _maxUtteranceDuration = maxUtteranceDuration;

    final controller = StreamController<SpeechRecognitionEvent>();
    _controller = controller;
    unawaited(
      _runSession(
        serial: serial,
        localeId: localeId,
        maxUtteranceDuration: maxUtteranceDuration,
        segmentDuration: segmentDuration,
        pauseFor: pauseFor,
      ),
    );
    return controller.stream;
  }

  Future<void> _runSession({
    required int serial,
    required String localeId,
    required Duration maxUtteranceDuration,
    required Duration segmentDuration,
    required Duration pauseFor,
  }) async {
    _emit(SpeechRecognitionEvent.started(generation: _generation));

    try {
      while (_isCurrent(serial)) {
        final firstSpeechAt = _firstSpeechAt;
        if (firstSpeechAt != null &&
            DateTime.now().difference(firstSpeechAt) >= maxUtteranceDuration) {
          await _speech.stop();
          await _completeSession(serial);
          return;
        }

        _generation++;
        _segmentStartedAt = DateTime.now();
        _segmentFinal = false;
        _segmentHadSpeech = false;
        _segmentError = null;
        _segmentDone = Completer<void>();

        final remaining = _remainingUtteranceTime(maxUtteranceDuration);
        final listenFor = remaining == null || remaining > segmentDuration
            ? segmentDuration
            : remaining;
        _currentListenFor = listenFor;

        if (listenFor <= Duration.zero) {
          await _completeSession(serial);
          return;
        }

        try {
          await _speech.listen(
            onResult: _handleResult,
            onSoundLevelChange: (level) {
              _emit(
                SpeechRecognitionEvent.soundLevel(
                  level: level,
                  generation: _generation,
                ),
              );
            },
            listenOptions: SpeechListenOptions(
              localeId: localeId,
              listenFor: listenFor,
              pauseFor: pauseFor,
              partialResults: true,
              cancelOnError: false,
              listenMode: ListenMode.dictation,
              autoPunctuation: true,
            ),
          );
          if (_awaitingBoundaryContinuation) {
            _boundaryContinuationTimer?.cancel();
            _boundaryContinuationTimer = Timer(
              pauseFor + const Duration(milliseconds: 900),
              () {
                if (_isCurrent(serial) && !_segmentHadSpeech && _speech.isListening) {
                  unawaited(_speech.stop());
                }
              },
            );
          }
        } catch (error) {
          _segmentError = error;
          _completeSegment();
        }

        try {
          await _segmentDone!.future.timeout(
            listenFor + const Duration(seconds: 3),
            onTimeout: () async {
              if (_speech.isListening) await _speech.stop();
            },
          );
        } catch (_) {
          // The session state below decides whether to recover or complete.
        }

        if (!_isCurrent(serial)) return;

        final error = _segmentError;
        if (error != null) {
          _emit(
            SpeechRecognitionEvent.failure(
              error: error,
              generation: _generation,
            ),
          );
          await _closeController();
          return;
        }

        if (_segmentFinal) {
          await _completeSession(serial);
          return;
        }

        if (_awaitingBoundaryContinuation &&
            !_segmentHadSpeech &&
            _committedTranscript.trim().isNotEmpty) {
          await _completeSession(serial);
          return;
        }

        final firstSpeech = _firstSpeechAt;
        if (firstSpeech != null &&
            DateTime.now().difference(firstSpeech) >= maxUtteranceDuration) {
          await _completeSession(serial);
          return;
        }

        final segmentElapsed = DateTime.now().difference(
          _segmentStartedAt ?? DateTime.now(),
        );
        final reachedSegmentBoundary =
            segmentElapsed >= listenFor - const Duration(milliseconds: 500);

        if (_segmentHadSpeech && !reachedSegmentBoundary) {
          // Native recognizer ended after speech before the rolling boundary.
          // Treat this as an end-of-turn even when the platform did not mark
          // the result final.
          await _completeSession(serial);
          return;
        }

        if (_latestTranscript.trim().isNotEmpty) {
          _committedTranscript = _latestTranscript.trim();
        }

        _emit(
          SpeechRecognitionEvent.restarting(
            transcript: _latestTranscript.trim(),
            generation: _generation,
          ),
        );
      }
    } finally {
      if (_isCurrent(serial)) {
        await _closeController();
      }
    }
  }

  Duration? _remainingUtteranceTime(Duration maxUtteranceDuration) {
    final firstSpeechAt = _firstSpeechAt;
    if (firstSpeechAt == null) return null;
    final elapsed = DateTime.now().difference(firstSpeechAt);
    return maxUtteranceDuration - elapsed;
  }

  void _handleResult(SpeechRecognitionResult result) {
    final words = result.recognizedWords.trim();
    if (words.isNotEmpty) {
      _segmentHadSpeech = true;
      _boundaryContinuationTimer?.cancel();
      _awaitingBoundaryContinuation = false;
      _firstSpeechAt ??= DateTime.now();
      _latestTranscript = SpeechTranscriptMerger.merge(_committedTranscript, words);
      _emit(
        SpeechRecognitionEvent.partial(
          transcript: _latestTranscript,
          generation: _generation,
        ),
      );
    }

    if (result.finalResult) {
      if (_latestTranscript.trim().isNotEmpty) {
        _committedTranscript = _latestTranscript.trim();
      }
      _emit(
        SpeechRecognitionEvent.finalSegment(
          transcript: _latestTranscript.trim(),
          generation: _generation,
        ),
      );

      final segmentElapsed = DateTime.now().difference(
        _segmentStartedAt ?? DateTime.now(),
      );
      final nearRollingBoundary =
          segmentElapsed >= _currentListenFor - const Duration(milliseconds: 500);
      final firstSpeechAt = _firstSpeechAt;
      final belowHardCap = firstSpeechAt == null ||
          DateTime.now().difference(firstSpeechAt) < _maxUtteranceDuration;

      if (nearRollingBoundary && belowHardCap) {
        _segmentFinal = false;
        _awaitingBoundaryContinuation = true;
      } else {
        _segmentFinal = true;
      }
      _completeSegment();
    }
  }

  void _handleStatus(String status) {
    if (status == SpeechToText.notListeningStatus ||
        status == SpeechToText.doneStatus) {
      _completeSegment();
    }
  }

  void _handleError(SpeechRecognitionError error) {
    final normalized = error.errorMsg.trim().toLowerCase();
    if (normalized.contains('permission') ||
        normalized.contains('recognizer_disabled')) {
      _segmentError = SpeechRecognitionPermissionDeniedException(
        permanentlyDenied: error.permanent,
      );
    } else {
      _segmentError = SpeechRecognitionUnavailableException(
        message: error.errorMsg,
      );
    }
    _completeSegment();
  }

  void _completeSegment() {
    final completer = _segmentDone;
    if (completer != null && !completer.isCompleted) completer.complete();
  }

  Future<void> _completeSession(int serial) async {
    if (!_isCurrent(serial)) return;
    _boundaryContinuationTimer?.cancel();
    _boundaryContinuationTimer = null;
    _awaitingBoundaryContinuation = false;
    final transcript = _latestTranscript.trim();
    _emit(
      SpeechRecognitionEvent.completed(
        transcript: transcript,
        generation: _generation,
      ),
    );
    await _closeController();
  }

  void _emit(SpeechRecognitionEvent event) {
    final controller = _controller;
    if (controller == null || controller.isClosed) return;
    controller.add(event);
  }

  bool _isCurrent(int serial) => serial == _sessionSerial;

  @override
  Future<void> finishRealtimeSession() async {
    if (_speech.isListening) await _speech.stop();
    final serial = _sessionSerial;
    if (_controller != null && !_controller!.isClosed) {
      await _completeSession(serial);
    }
  }

  @override
  Future<String> listenOnce({
    String localeId = 'vi_VN',
    Duration listenFor = const Duration(seconds: 30),
    Duration pauseFor = const Duration(seconds: 4),
  }) async {
    final stream = await startRealtimeSession(
      localeId: localeId,
      maxUtteranceDuration: listenFor,
      segmentDuration: listenFor,
      pauseFor: pauseFor,
    );
    String latest = '';
    await for (final event in stream) {
      if (event.transcript.trim().isNotEmpty) latest = event.transcript.trim();
      if (event.type == SpeechRecognitionEventType.error && event.error != null) {
        throw event.error!;
      }
    }
    return latest;
  }

  @override
  Future<void> stop() => finishRealtimeSession();

  @override
  Future<void> cancel() async {
    _sessionSerial++;
    _boundaryContinuationTimer?.cancel();
    _boundaryContinuationTimer = null;
    _completeSegment();
    if (_speech.isListening) await _speech.cancel();
    await _closeController();
    _segmentDone = null;
  }

  Future<void> _closeController() async {
    final controller = _controller;
    if (controller == null) return;
    if (!controller.isClosed) await controller.close();
    if (identical(_controller, controller)) _controller = null;
  }


}

class SpeechRecognitionUnavailableException implements Exception {
  final String? message;

  const SpeechRecognitionUnavailableException({this.message});

  @override
  String toString() => message ?? 'Speech recognition unavailable';
}

class SpeechRecognitionPermissionDeniedException implements Exception {
  final bool permanentlyDenied;

  const SpeechRecognitionPermissionDeniedException({
    this.permanentlyDenied = false,
  });
}
