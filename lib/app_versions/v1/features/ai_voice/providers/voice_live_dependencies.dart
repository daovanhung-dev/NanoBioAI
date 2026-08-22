import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/config/app_env.dart';

import '../data/gateways/gemini_live_voice_gateway.dart';
import '../data/gateways/native_voice_audio_gateway.dart';
import '../domain/gateways/voice_audio_gateway.dart';
import '../domain/gateways/voice_live_gateway.dart';

final voiceAudioGatewayProvider = Provider<VoiceAudioGateway>(
  (ref) => NativeVoiceAudioGateway(),
);

final voiceLiveGatewayProvider = Provider<VoiceLiveGateway>(
  (ref) => GeminiLiveVoiceGateway(
    // Android supplies this through BuildConfig/AppEnv. Other platforms can
    // provide the same direct value with --dart-define(-from-file).
    apiKey: AppEnv.maybeString('GEMINI_API_KEY'),
    model:
        AppEnv.maybeString('GEMINI_LIVE_MODEL') ??
        GeminiLiveVoiceGateway.defaultModel,
    audio: ref.watch(voiceAudioGatewayProvider),
  ),
);
