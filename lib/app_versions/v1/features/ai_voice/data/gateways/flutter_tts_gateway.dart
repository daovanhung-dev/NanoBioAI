import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';

import '../../domain/gateways/voice_gateways.dart';

class DeviceTextToSpeechGateway implements TextToSpeechGateway {
  static const Duration _defaultSpeakTimeout = Duration(seconds: 60);

  final FlutterTts _tts;
  final Duration _speakTimeout;
  bool _initialized = false;

  DeviceTextToSpeechGateway({
    FlutterTts? tts,
    Duration speakTimeout = _defaultSpeakTimeout,
  }) : _tts = tts ?? FlutterTts(),
       _speakTimeout = speakTimeout;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final languageAvailable = await _tts.isLanguageAvailable('vi-VN');
      if (languageAvailable != true) {
        throw const TextToSpeechUnavailableException();
      }
      await _tts.awaitSpeakCompletion(true);
      await _tts.setLanguage('vi-VN');
      await _tts.setSpeechRate(0.55);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _initialized = true;
    } on TextToSpeechUnavailableException {
      rethrow;
    } catch (_) {
      throw const TextToSpeechUnavailableException();
    }
  }

  @override
  Future<void> speak(String text) async {
    final normalized = text.trim();
    if (normalized.isEmpty) return;
    await initialize();
    try {
      await _tts.stop();
      final result = await _tts.speak(normalized).timeout(_speakTimeout);
      if (result == 0 || result == false) {
        throw const TextToSpeechUnavailableException();
      }
    } on TimeoutException {
      await _stopSafely();
      throw const TextToSpeechUnavailableException();
    } on TextToSpeechUnavailableException {
      rethrow;
    } catch (_) {
      await _stopSafely();
      throw const TextToSpeechUnavailableException();
    }
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }

  Future<void> _stopSafely() async {
    try {
      await _tts.stop();
    } catch (_) {
      // Best-effort cleanup after a terminal TTS failure.
    }
  }
}

class TextToSpeechUnavailableException implements Exception {
  const TextToSpeechUnavailableException();
}
