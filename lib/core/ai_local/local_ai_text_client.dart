import 'package:flutter/foundation.dart';

import '../../app_versions/v1/services/ai/ai_text_client.dart';
import 'local_ai_runtime_service.dart';

/// The shared text and vision client for all on-device AI features.
class LocalAiTextClient implements AiTextClient, AiContextAwareClient {
  const LocalAiTextClient({this.operation});

  static const modelId = 'ai-local-selected-model';

  final String? operation;

  @override
  Future<int> selectedContextSize() =>
      LocalAiRuntimeService.instance.selectedContextSize();

  @override
  Future<int> estimateTokens(String text) =>
      LocalAiRuntimeService.instance.estimateTokens(text);

  @override
  Future<String> generateText({
    required String model,
    required List<AiMessage> messages,
    required AiGenerationConfig generationConfig,
    String? systemInstruction,
  }) async {
    _ensurePlatform();
    try {
      return await LocalAiRuntimeService.instance.generateText(
        messages: messages,
        generationConfig: generationConfig,
        systemInstruction: systemInstruction,
      );
    } on LocalAiContextLimitException {
      throw const AiInferenceException(
        status: 'model_context_limit_exceeded',
        message: 'Nội dung vượt quá khả năng xử lý của model đã chọn.',
      );
    } on LocalAiOutputTruncatedException {
      throw const AiInferenceException(
        status: 'output_truncated',
        message: 'Model dừng trước khi hoàn tất nội dung được yêu cầu.',
      );
    } on LocalAiUnsupportedPlatformException {
      throw _unsupportedPlatform();
    } on LocalAiModelLoadException catch (error) {
      throw _modelLoadFailure(error);
    } on LocalAiInsufficientStorageException {
      throw _insufficientStorage();
    } on LocalAiDownloadFailedException {
      throw _downloadFailed();
    } on LocalAiModelIntegrityException {
      throw const AiInferenceException(
        status: 'model_checksum_failed',
        message: 'Tệp model không khớp checksum. Hãy tải model lại.',
      );
    } on StateError catch (error) {
      throw AiInferenceException(
        status: 'local_model_not_ready',
        message: error.message,
      );
    }
  }

  @override
  Stream<String> streamText({
    required String model,
    required List<AiMessage> messages,
    required AiGenerationConfig generationConfig,
    String? systemInstruction,
  }) async* {
    _ensurePlatform();
    try {
      yield* LocalAiRuntimeService.instance.streamText(
        messages: messages,
        generationConfig: generationConfig,
        systemInstruction: systemInstruction,
      );
    } on LocalAiContextLimitException {
      throw const AiInferenceException(
        status: 'model_context_limit_exceeded',
        message: 'Nội dung vượt quá khả năng xử lý của model đã chọn.',
      );
    } on LocalAiOutputTruncatedException {
      throw const AiInferenceException(
        status: 'output_truncated',
        message: 'Model dừng trước khi hoàn tất nội dung được yêu cầu.',
      );
    } on LocalAiUnsupportedPlatformException {
      throw _unsupportedPlatform();
    } on LocalAiModelLoadException catch (error) {
      throw _modelLoadFailure(error);
    } on LocalAiInsufficientStorageException {
      throw _insufficientStorage();
    } on LocalAiDownloadFailedException {
      throw _downloadFailed();
    } on LocalAiModelIntegrityException {
      throw const AiInferenceException(
        status: 'model_checksum_failed',
        message: 'Tệp model không khớp checksum. Hãy tải model lại.',
      );
    } on StateError catch (error) {
      throw AiInferenceException(
        status: 'local_model_not_ready',
        message: error.message,
      );
    }
  }

  void _ensurePlatform() {
    if (kIsWeb || !LocalAiRuntimeService.instance.isSupportedPlatform) {
      throw _unsupportedPlatform();
    }
  }

  AiInferenceException _unsupportedPlatform() => const AiInferenceException(
    status: 'unsupported_platform',
    message:
        'AI trên thiết bị hiện hỗ trợ Android, iOS và máy tính. Hãy dùng một trong các phiên bản đó để sử dụng tính năng AI.',
  );

  AiInferenceException _modelLoadFailure(
    LocalAiModelLoadException error,
  ) => AiInferenceException(
    status: error.modelId == 'qwen2-vl-2b-q4'
        ? 'vision_model_unsupported'
        : 'local_model_load_failed',
    message: error.modelId == 'qwen2-vl-2b-q4'
        ? 'Thiết bị chưa đủ tài nguyên để mở model ảnh. Ảnh vẫn ở trên thiết bị.'
        : 'Không mở được model AI đã chọn trên thiết bị.',
  );

  AiInferenceException _insufficientStorage() => const AiInferenceException(
    status: 'insufficient_storage',
    message:
        'Thiết bị không đủ dung lượng để tải model. Hãy giải phóng bộ nhớ rồi thử lại.',
  );

  AiInferenceException _downloadFailed() => const AiInferenceException(
    status: 'model_download_failed',
    message: 'Chưa tải xong model. Kiểm tra kết nối rồi thử tiếp tục tải.',
  );
}
