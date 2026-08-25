import 'dart:convert';

import 'package:nano_app/core/config/app_env.dart';
import 'package:nano_app/features/nabi/domain/care/nabi_care_repository.dart';

import 'gemini_rest_client.dart';

typedef NabiCareTextGenerator = Future<String> Function({
  required String model,
  required String prompt,
  required String systemInstruction,
});

class GeminiNabiCareAiGateway implements NabiCareAiGateway {
  static const _defaultModels = <String>[
    'gemini-3.5-flash',
    'gemini-2.5-flash-lite',
  ];

  final GeminiRestClient? _client;
  final NabiCareTextGenerator? _textGenerator;
  final List<String> _models;

  GeminiNabiCareAiGateway({
    GeminiRestClient? client,
    NabiCareTextGenerator? textGenerator,
    String? apiKeyOverride,
    List<String>? modelNames,
  })  : _textGenerator = textGenerator,
        _models = _resolveModels(modelNames),
        _client = textGenerator != null
            ? client
            : client ?? _runtimeClient(apiKeyOverride);

  @override
  Future<String> generateAnalysis({
    required Map<String, Object?> payload,
    required String systemInstruction,
  }) async {
    final prompt = '''
Phân tích snapshot NaBi Care bên dưới và trả về đúng một JSON object theo schema
đã mô tả trong system instruction. Không dùng markdown.

SNAPSHOT:
${jsonEncode(payload)}
''';

    Object? lastError;
    for (final model in _models) {
      try {
        final textGenerator = _textGenerator;
        if (textGenerator != null) {
          return await textGenerator(
            model: model,
            prompt: prompt,
            systemInstruction: systemInstruction,
          );
        }

        final client = _client;
        if (client == null) {
          throw const NabiCareAiUnavailableException(
            'GEMINI_API_KEY is not configured.',
          );
        }

        return await client
            .generateText(
              model: model,
              contents: [GeminiContent.user(prompt)],
              systemInstruction: systemInstruction,
              generationConfig: const GeminiGenerationConfig(
                candidateCount: 1,
                maxOutputTokens: 2800,
                temperature: 0.15,
                topP: 0.8,
                responseMimeType: 'application/json',
              ),
            )
            .timeout(const Duration(seconds: 25));
      } on GeminiApiException catch (error) {
        lastError = error;
        if (!error.isTransient) rethrow;
      } catch (error) {
        lastError = error;
        if (error is NabiCareAiUnavailableException) rethrow;
      }
    }

    throw NabiCareAiUnavailableException(
      'All configured care models failed: ${lastError.runtimeType}',
    );
  }

  static GeminiRestClient? _runtimeClient(String? apiKeyOverride) {
    final apiKey =
        _clean(apiKeyOverride) ?? _clean(AppEnv.maybeString('GEMINI_API_KEY'));
    if (apiKey == null) return null;

    return GeminiRestClient(
      apiKey: apiKey,
      baseUrl: AppEnv.maybeString('GEMINI_BASE_URL'),
    );
  }

  static List<String> _resolveModels(List<String>? override) {
    if (override != null && override.isNotEmpty) {
      return _dedupe(override);
    }

    final carePrimary = _clean(AppEnv.maybeString('GEMINI_CARE_MODEL'));
    final legacyPrimary = _clean(AppEnv.maybeString('GEMINI_MODEL'));
    final fallbackCsv =
        _clean(AppEnv.maybeString('GEMINI_CARE_FALLBACK_MODELS'));
    final fallback = fallbackCsv == null
        ? const <String>[]
        : fallbackCsv
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList(growable: false);

    return _dedupe([
      carePrimary ?? legacyPrimary ?? _defaultModels.first,
      ...fallback,
      ..._defaultModels,
    ]);
  }

  static List<String> _dedupe(Iterable<String> source) {
    final seen = <String>{};
    final result = <String>[];
    for (final raw in source) {
      final value = raw.trim();
      if (value.isEmpty || !seen.add(value)) continue;
      result.add(value);
    }
    return result;
  }

  static String? _clean(String? value) {
    final cleaned = value?.trim();
    return cleaned == null || cleaned.isEmpty ? null : cleaned;
  }
}

class NabiCareAiUnavailableException implements Exception {
  final String message;

  const NabiCareAiUnavailableException(this.message);

  @override
  String toString() => 'NabiCareAiUnavailableException: $message';
}
