import 'dart:typed_data';

enum LocalAiRuntimeStage { downloading, loading, warming, generating, ready }

class LocalAiRuntimeProgress {
  const LocalAiRuntimeProgress({
    required this.stage,
    required this.modelId,
    this.receivedBytes = 0,
    this.totalBytes = 0,
  });

  final LocalAiRuntimeStage stage;
  final String modelId;
  final int receivedBytes;
  final int totalBytes;

  double? get fraction => totalBytes <= 0 ? null : receivedBytes / totalBytes;
}

class LocalAiContextLimitException implements Exception {
  const LocalAiContextLimitException();
}

class LocalAiOutputTruncatedException implements Exception {
  const LocalAiOutputTruncatedException();
}

class LocalAiDownloadCancelledException implements Exception {
  const LocalAiDownloadCancelledException();
}

class LocalAiUnsupportedPlatformException implements Exception {
  const LocalAiUnsupportedPlatformException();
}

class LocalAiModelLoadException implements Exception {
  const LocalAiModelLoadException(this.modelId, this.cause);

  final String modelId;
  final Object cause;
}

class LocalAiInsufficientStorageException implements Exception {
  const LocalAiInsufficientStorageException();
}

class LocalAiDownloadFailedException implements Exception {
  const LocalAiDownloadFailedException();
}

class LocalAiModelIntegrityException implements Exception {
  const LocalAiModelIntegrityException(this.assetId);

  final String assetId;
}

class LocalAiMessage {
  const LocalAiMessage({
    required this.role,
    required this.text,
    this.imageBytes = const [],
    this.imageMimeTypes = const [],
    this.systemPrompt,
  });

  final String role;
  final String text;
  final List<Uint8List> imageBytes;
  final List<String> imageMimeTypes;
  final String? systemPrompt;
}
