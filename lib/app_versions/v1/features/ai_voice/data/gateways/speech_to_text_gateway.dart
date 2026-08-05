import 'dart:async';

import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../domain/gateways/voice_gateways.dart';

class DeviceSpeechRecognitionGateway implements SpeechRecognitionGateway {
  final SpeechToText _speech;
  bool _initialized = false;
  Completer<String>? _activeCompleter;
  String _latestWords = '';

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
  Future<String> listenOnce({
    String localeId = 'vi_VN',
    Duration listenFor = const Duration(seconds: 30),
    Duration pauseFor = const Duration(seconds: 4),
  }) async {
    final available = await initialize();
    if (!available) throw const SpeechRecognitionUnavailableException();

    await cancel();
    _latestWords = '';
    final completer = Completer<String>();
    _activeCompleter = completer;

    await _speech.listen(
      onResult: _handleResult,
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        listenFor: listenFor,
        pauseFor: pauseFor,
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      ),
    );

    return completer.future.timeout(
      listenFor + const Duration(seconds: 2),
      onTimeout: () async {
        await stop();
        return _latestWords.trim();
      },
    ).whenComplete(() {
      if (identical(_activeCompleter, completer)) {
        _activeCompleter = null;
      }
    });
  }

  void _handleResult(SpeechRecognitionResult result) {
    _latestWords = result.recognizedWords;
    if (result.finalResult) _completeCurrent();
  }

  void _handleStatus(String status) {
    if (status == SpeechToText.notListeningStatus ||
        status == SpeechToText.doneStatus) {
      _completeCurrent();
    }
  }

  void _handleError(SpeechRecognitionError error) {
    final completer = _activeCompleter;
    if (completer == null || completer.isCompleted) return;
    final normalized = error.errorMsg.trim().toLowerCase();
    if (normalized.contains('permission') ||
        normalized.contains('recognizer_disabled')) {
      completer.completeError(
        SpeechRecognitionPermissionDeniedException(
          permanentlyDenied: error.permanent,
        ),
      );
      return;
    }
    completer.completeError(const SpeechRecognitionUnavailableException());
  }

  void _completeCurrent() {
    final completer = _activeCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete(_latestWords.trim());
    }
  }

  @override
  Future<void> stop() async {
    if (_speech.isListening) await _speech.stop();
    _completeCurrent();
  }

  @override
  Future<void> cancel() async {
    if (_speech.isListening) await _speech.cancel();
    final completer = _activeCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete('');
    }
    _activeCompleter = null;
  }
}

class SpeechRecognitionUnavailableException implements Exception {
  const SpeechRecognitionUnavailableException();
}

class SpeechRecognitionPermissionDeniedException implements Exception {
  final bool permanentlyDenied;

  const SpeechRecognitionPermissionDeniedException({
    this.permanentlyDenied = false,
  });
}
