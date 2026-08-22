import 'package:flutter_tts/flutter_tts.dart';

import '../../domain/gateways/voice_gateways.dart';

class DeviceTextToSpeechGateway
    implements TextToSpeechGateway, RealtimeTextToSpeechCapability {
  final FlutterTts _tts;
  bool _initialized = false;

  DeviceTextToSpeechGateway({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    await _tts.awaitSpeakCompletion(true);
    await _tts.setLanguage('vi-VN');
    await _tts.setSpeechRate(0.55);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _initialized = true;
  }

  @override
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await initialize();
    await _tts.stop();
    await _tts.speak(text.trim());
  }

  @override
  Future<void> speakRealtimeChunk(String text) async {
    if (text.trim().isEmpty) return;
    await initialize();
    await _tts.speak(text.trim());
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }

  @override
  Future<void> stopRealtimeImmediately() async {
    await _tts.stop();
  }
}
