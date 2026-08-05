import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/gateways/flutter_tts_gateway.dart';
import '../data/gateways/speech_to_text_gateway.dart';
import '../domain/gateways/voice_gateways.dart';

final speechRecognitionGatewayProvider = Provider<SpeechRecognitionGateway>(
  (ref) => DeviceSpeechRecognitionGateway(),
);

final textToSpeechGatewayProvider = Provider<TextToSpeechGateway>(
  (ref) => DeviceTextToSpeechGateway(),
);
