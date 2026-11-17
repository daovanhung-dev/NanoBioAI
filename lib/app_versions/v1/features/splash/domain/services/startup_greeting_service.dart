import 'dart:async';

import '../../../ai_voice/domain/gateways/voice_gateways.dart';

class StartupGreetingService {
  static const String greeting = 'Chào bạn, Nabi đây!';
  static const Duration _timeout = Duration(seconds: 4);

  StartupGreetingService(this._textToSpeech, {bool enabled = true})
    : _enabled = enabled;

  final TextToSpeechGateway _textToSpeech;
  final bool _enabled;
  bool _attempted = false;

  Future<void> speakOnce() async {
    if (_attempted || !_enabled) return;
    _attempted = true;

    try {
      await _textToSpeech.speak(greeting).timeout(_timeout);
    } catch (_) {
      try {
        await _textToSpeech.stop();
      } catch (_) {
        // Startup must continue if the device has no usable Vietnamese voice.
      }
    }
  }
}
