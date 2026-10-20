import 'dart:convert';

import 'package:nano_app/core/ai_local/local_ai_text_client.dart';
import 'package:nano_app/features/nabi/domain/care/nabi_care_repository.dart';

import 'ai_text_client.dart';

typedef NabiCareTextGenerator =
    Future<String> Function({
      required String model,
      required String prompt,
      required String systemInstruction,
    });

class LocalNabiCareAiGateway implements NabiCareAiGateway {
  final AiTextClient _client;
  final NabiCareTextGenerator? _textGenerator;

  LocalNabiCareAiGateway({
    AiTextClient? client,
    NabiCareTextGenerator? textGenerator,
  }) : _client = client ?? const LocalAiTextClient(operation: 'nabi_care'),
       _textGenerator = textGenerator;

  @override
  Future<String> generateAnalysis({
    required Map<String, Object?> payload,
    required String systemInstruction,
  }) async {
    final prompt =
        '''
Phân tích snapshot NaBi Care bên dưới và trả về đúng một JSON object theo schema
đã mô tả trong system instruction. Không dùng markdown.

SNAPSHOT:
${jsonEncode(payload)}
''';
    try {
      final generator = _textGenerator;
      if (generator != null) {
        return await generator(
          model: LocalAiTextClient.modelId,
          prompt: prompt,
          systemInstruction: systemInstruction,
        );
      }
      return await _client
          .generateText(
            model: LocalAiTextClient.modelId,
            messages: [AiMessage.user(prompt)],
            systemInstruction: systemInstruction,
            generationConfig: const AiGenerationConfig(
              temperature: 0.15,
              topP: 0.8,
              responseFormat: AiResponseFormat.json,
            ),
          )
          .timeout(const Duration(seconds: 60));
    } on AiInferenceException catch (error) {
      throw NabiCareAiUnavailableException(error.message, status: error.status);
    } on NabiCareAiUnavailableException {
      rethrow;
    } catch (error) {
      throw NabiCareAiUnavailableException(
        'Nabi chưa thể phân tích trên thiết bị lúc này (${error.runtimeType}).',
      );
    }
  }
}

class NabiCareAiUnavailableException implements Exception {
  final String message;
  final String? status;

  const NabiCareAiUnavailableException(this.message, {this.status});

  @override
  String toString() => 'NabiCareAiUnavailableException: $message';
}
