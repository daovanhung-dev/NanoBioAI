import 'package:supabase_flutter/supabase_flutter.dart';

import 'gemini_rest_client.dart';

/// Production AI transport. The Flutter client sends only bounded prompt
/// content to a Supabase Edge Function; the Gemini credential is held by the
/// function environment and never enters the app process.
class NabiAiBackendClient implements AiTextClient {
  final SupabaseClient? clientOverride;
  final String functionName;

  const NabiAiBackendClient({
    this.clientOverride,
    this.functionName = 'nabi-ai-generate',
  });

  SupabaseClient? get _client {
    if (clientOverride != null) return clientOverride;
    try {
      return Supabase.instance.client;
    } on AssertionError {
      return null;
    }
  }

  @override
  Future<String> generateText({
    required String model,
    required List<GeminiContent> contents,
    required GeminiGenerationConfig generationConfig,
    String? systemInstruction,
  }) async {
    final client = _client;
    if (client == null) {
      throw const GeminiApiException(
        statusCode: 503,
        status: 'backend_unavailable',
        message: 'AI backend is not configured.',
      );
    }

    try {
      final response = await client.functions.invoke(
        functionName,
        body: {
          'model': model,
          'contents': contents.map((content) => content.toJson()).toList(),
          'generation_config': generationConfig.toJson(),
          if (systemInstruction != null)
            'system_instruction': systemInstruction,
        },
      );
      final data = response.data;
      if (data is Map && data['text'] is String) {
        final text = (data['text'] as String).trim();
        if (text.isNotEmpty) return text;
      }
      throw GeminiApiException(
        statusCode: response.status,
        status: 'invalid_backend_response',
        message: 'AI backend returned an invalid response.',
      );
    } on FunctionException catch (error) {
      throw GeminiApiException(
        statusCode: error.status,
        status: 'backend_function_error',
        message: 'AI backend request failed.',
      );
    } on GeminiApiException {
      rethrow;
    } catch (_) {
      throw const GeminiApiException(
        statusCode: 503,
        status: 'network_error',
        message: 'AI backend request could not be completed.',
      );
    }
  }

  /// The Edge Function currently returns a bounded complete response. Expose
  /// it through the existing stream contract so callers retain one API while
  /// no provider endpoint or credential is reachable from the client.
  @override
  Stream<String> streamText({
    required String model,
    required List<GeminiContent> contents,
    required GeminiGenerationConfig generationConfig,
    String? systemInstruction,
  }) async* {
    yield await generateText(
      model: model,
      contents: contents,
      generationConfig: generationConfig,
      systemInstruction: systemInstruction,
    );
  }
}
