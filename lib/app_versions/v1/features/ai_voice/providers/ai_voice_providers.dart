import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/gateways/flutter_tts_gateway.dart';
import '../data/gateways/speech_to_text_gateway.dart';
import '../domain/entities/ai_voice_state.dart';
import '../domain/gateways/voice_gateways.dart';
import '../presentation/controllers/ai_voice_controller.dart';

export 'voice_live_dependencies.dart';

final speechRecognitionGatewayProvider = Provider<SpeechRecognitionGateway>(
  (ref) => DeviceSpeechRecognitionGateway(),
);

final textToSpeechGatewayProvider = Provider<TextToSpeechGateway>(
  (ref) => DeviceTextToSpeechGateway(),
);

final aiVoiceControllerProvider =
    NotifierProvider<AiVoiceController, AiVoiceState>(AiVoiceController.new);
