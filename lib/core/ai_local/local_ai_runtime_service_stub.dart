import 'package:flutter/foundation.dart';

import '../../app_versions/v1/services/ai/ai_text_client.dart';
import 'local_ai_model_catalog.dart';
import 'local_ai_runtime_contract.dart';

class LocalAiRuntimeService {
  LocalAiRuntimeService._();

  static final instance = LocalAiRuntimeService._();
  static const selectedModelPreferenceKey = 'nanobioai_local_ai_model_id';

  final ValueNotifier<LocalAiRuntimeProgress?> progress =
      ValueNotifier<LocalAiRuntimeProgress?>(null);

  bool get isSupportedPlatform => false;
  String? get loadedModelId => null;

  Future<String?> selectedModelId() async => null;

  Future<bool> loadSelectedTextModel() async => false;

  Future<void> installAndSelectTextModel(String modelId) async {
    throw const LocalAiUnsupportedPlatformException();
  }

  Future<void> cancelDownload(String modelId) async {}

  Future<void> unload() async {}

  Future<int> selectedContextSize() async =>
      localAiTextModelById(localAiDefaultModelId).contextSize;

  Future<int> estimateTokens(String text) async =>
      (text.runes.length / 3).ceil();

  Future<String> generateText({
    required List<AiMessage> messages,
    required AiGenerationConfig generationConfig,
    String? systemInstruction,
  }) async {
    throw const LocalAiUnsupportedPlatformException();
  }

  Stream<String> streamText({
    required List<AiMessage> messages,
    required AiGenerationConfig generationConfig,
    String? systemInstruction,
  }) async* {
    throw const LocalAiUnsupportedPlatformException();
  }

  Future<String> generateImageText({
    required String prompt,
    required Uint8List imageBytes,
    required String mimeType,
    required AiGenerationConfig generationConfig,
  }) async {
    throw const LocalAiUnsupportedPlatformException();
  }
}
