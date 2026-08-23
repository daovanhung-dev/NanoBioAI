import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/datasources/voice_chat_turn_datasource.dart';
import '../data/gateways/flutter_tts_gateway.dart';
import '../data/gateways/speech_to_text_gateway.dart';
import '../data/repositories/ai_voice_repository_impl.dart';
import '../domain/gateways/voice_gateways.dart';
import '../domain/repositories/ai_voice_repository.dart';

final speechRecognitionGatewayProvider = Provider<SpeechRecognitionGateway>(
  (ref) => DeviceSpeechRecognitionGateway(),
);

final textToSpeechGatewayProvider = Provider<TextToSpeechGateway>(
  (ref) => DeviceTextToSpeechGateway(),
);

final voiceChatTurnDatasourceProvider = Provider<VoiceChatTurnDatasource>(
  (ref) => GeminiVoiceChatTurnDatasource(),
);

final aiVoiceRepositoryProvider = Provider<AiVoiceRepository>((ref) {
  final repository = AiVoiceRepositoryImpl(
    ref.watch(voiceChatTurnDatasourceProvider),
  );
  ref.onDispose(repository.resetSession);
  return repository;
});

final aiVoiceTurnDelayProvider = Provider<Duration>(
  (ref) => const Duration(milliseconds: 300),
);
