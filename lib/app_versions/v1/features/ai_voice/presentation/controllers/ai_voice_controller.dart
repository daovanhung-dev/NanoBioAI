import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/features/ai_chat/domain/repositories/ai_chat_repository.dart';
import 'package:nano_app/app_versions/v1/features/ai_chat/providers/ai_chat_providers.dart';
import 'package:nano_app/app_versions/v1/features/nabi/providers/nabi_provider.dart';

import '../../data/gateways/speech_to_text_gateway.dart';
import '../../domain/ai_voice_copy.dart';
import '../../domain/entities/ai_voice_state.dart';
import '../../domain/gateways/voice_gateways.dart';
import '../../providers/ai_voice_providers.dart';

class AiVoiceController extends Notifier<AiVoiceState> {
  static const greeting = AiVoiceCopy.greeting;

  int _operationToken = 0;

  @override
  AiVoiceState build() => const AiVoiceState();

  SpeechRecognitionGateway get _speech =>
      ref.read(speechRecognitionGatewayProvider);
  TextToSpeechGateway get _tts => ref.read(textToSpeechGatewayProvider);
  AIChatRepository get _chat => ref.read(aiChatRepositoryProvider);

  Future<void> initializeAndGreet() async {
    if (state.isInitialized) return;
    final token = ++_operationToken;
    state = state.copyWith(
      phase: AiVoicePhase.initializing,
      isInitialized: true,
      clearError: true,
    );

    try {
      await _speech.initialize();
      await _tts.initialize();
      if (token != _operationToken) return;
      state = state.copyWith(
        phase: AiVoicePhase.greeting,
        response: greeting,
      );
      if (!state.isMuted) await _tts.speak(greeting);
      if (token == _operationToken) {
        state = state.copyWith(phase: AiVoicePhase.idle);
      }
    } on SpeechRecognitionPermissionDeniedException {
      if (token != _operationToken) return;
      state = state.copyWith(
        phase: AiVoicePhase.permissionDenied,
        errorMessage: AiVoiceCopy.permissionDenied,
      );
    } catch (_) {
      if (token != _operationToken) return;
      state = state.copyWith(
        phase: AiVoicePhase.error,
        errorMessage: AiVoiceCopy.unavailable,
      );
    }
  }

  Future<void> listenAndRespond() async {
    if (state.isBusy) return;
    final token = ++_operationToken;
    await _tts.stop();
    state = state.copyWith(
      phase: AiVoicePhase.listening,
      transcript: '',
      response: '',
      clearError: true,
    );

    try {
      final transcript = await _speech.listenOnce();
      if (token != _operationToken) return;
      state = state.copyWith(phase: AiVoicePhase.transcribing);
      final normalizedTranscript = transcript.trim();
      if (normalizedTranscript.isEmpty) {
        state = state.copyWith(
          phase: AiVoicePhase.error,
          errorMessage: AiVoiceCopy.notHeard,
        );
        return;
      }

      state = state.copyWith(
        phase: AiVoicePhase.thinking,
        transcript: normalizedTranscript,
        clearError: true,
      );
      ref.read(nabiContextProvider.notifier).setChatTyping(typing: true);

      final answer = await _chat.sendMessage(normalizedTranscript);
      if (token != _operationToken) return;

      state = state.copyWith(
        phase: AiVoicePhase.speaking,
        response: answer.content,
        clearError: true,
      );
      ref.read(nabiContextProvider.notifier).setChatAnswerReady();

      if (!state.isMuted) await _tts.speak(answer.content);
      if (token == _operationToken) {
        state = state.copyWith(phase: AiVoicePhase.idle);
      }
    } on SpeechRecognitionPermissionDeniedException {
      if (token != _operationToken) return;
      state = state.copyWith(
        phase: AiVoicePhase.permissionDenied,
        errorMessage: AiVoiceCopy.permissionDenied,
      );
    } catch (_) {
      if (token != _operationToken) return;
      ref.read(nabiContextProvider.notifier).setChatFailed();
      state = state.copyWith(
        phase: AiVoicePhase.error,
        errorMessage: AiVoiceCopy.responseUnavailable,
      );
    } finally {
      if (token == _operationToken) {
        ref.read(nabiContextProvider.notifier).setChatTyping(typing: false);
      }
    }
  }

  Future<void> replayResponse() async {
    final text = state.response.trim();
    if (text.isEmpty || state.isBusy || state.isMuted) return;
    final token = ++_operationToken;
    state = state.copyWith(phase: AiVoicePhase.speaking, clearError: true);
    try {
      await _tts.speak(text);
      if (token == _operationToken) {
        state = state.copyWith(phase: AiVoicePhase.idle);
      }
    } catch (_) {
      if (token == _operationToken) {
        state = state.copyWith(
          phase: AiVoicePhase.error,
          errorMessage: 'NaBi chưa thể phát lại câu trả lời lúc này.',
        );
      }
    }
  }

  Future<void> toggleMuted() async {
    final nextMuted = !state.isMuted;
    state = state.copyWith(isMuted: nextMuted);
    if (nextMuted) await _tts.stop();
  }

  Future<void> stop() async {
    _operationToken++;
    await _speech.cancel();
    await _tts.stop();
    ref.read(nabiContextProvider.notifier).setChatTyping(typing: false);
    state = state.copyWith(phase: AiVoicePhase.idle, clearError: true);
  }
}

final aiVoiceControllerProvider =
    NotifierProvider<AiVoiceController, AiVoiceState>(AiVoiceController.new);
