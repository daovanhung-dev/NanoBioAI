import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:llamadart/llamadart.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app_versions/v1/services/ai/ai_text_client.dart';
import 'local_ai_model_catalog.dart';
import 'local_ai_runtime_contract.dart';
import 'local_ai_runtime_diagnostics.dart';

class LocalAiRuntimeService {
  LocalAiRuntimeService._();

  static final LocalAiRuntimeService instance = LocalAiRuntimeService._();
  static const selectedModelPreferenceKey = 'nanobioai_local_ai_model_id';
  static const _maxInferenceThreads = 3;
  static const _streamBatchTokenThreshold = 8;

  final ValueNotifier<LocalAiRuntimeProgress?> progress =
      ValueNotifier<LocalAiRuntimeProgress?>(null);
  final Map<String, http.Client> _activeDownloads = {};
  Future<void> _operationTail = Future<void>.value();
  LlamaEngine? _engine;
  String? _loadedModelId;

  bool get isSupportedPlatform => true;
  String? get loadedModelId => _loadedModelId;

  Future<String?> selectedModelId() async {
    final preferences = await SharedPreferences.getInstance();
    final modelId = preferences.getString(selectedModelPreferenceKey);
    if (modelId == null ||
        localAiTextModels.any((candidate) => candidate.id == modelId)) {
      return modelId;
    }
    await preferences.remove(selectedModelPreferenceKey);
    return null;
  }

  Future<void> installAndSelectTextModel(String modelId) {
    final model = localAiTextModels.firstWhere(
      (candidate) => candidate.id == modelId,
      orElse: () => throw ArgumentError.value(modelId, 'modelId'),
    );
    return _withOperation(() async {
      final modelPath = await _downloadAssets(
        modelId: model.id,
        assets: [model.asset],
      );
      await _loadModel(
        modelId: model.id,
        modelPath: modelPath.single,
        contextSize: model.contextSize,
      );
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(selectedModelPreferenceKey, model.id);
    });
  }

  Future<bool> loadSelectedTextModel() async {
    try {
      final modelId = await selectedModelId();
      if (modelId == null) return false;
      final model = localAiTextModelById(modelId);
      final path = await _installedPath(model.asset);
      if (path == null) return false;
      await _withOperation(() async {
        await _loadModel(
          modelId: model.id,
          modelPath: path,
          contextSize: model.contextSize,
        );
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> cancelDownload(String modelId) async {
    _activeDownloads.remove(modelId)?.close();
  }

  Future<void> unload() => _withOperation(_unload);

  Future<int> selectedContextSize() async {
    final modelId = await selectedModelId();
    if (modelId == null) {
      return localAiTextModelById(localAiDefaultModelId).contextSize;
    }
    return localAiTextModelById(modelId).contextSize;
  }

  Future<int> estimateTokens(String text) async {
    final release = await _acquireOperation();
    try {
      await _ensureSelectedTextModelLoaded();
      return (await _engine!.tokenize(text)).length;
    } finally {
      await release();
    }
  }

  Future<String> generateText({
    required List<AiMessage> messages,
    required AiGenerationConfig generationConfig,
    String? systemInstruction,
  }) async {
    final buffer = StringBuffer();
    await for (final chunk in streamText(
      messages: messages,
      generationConfig: generationConfig,
      systemInstruction: systemInstruction,
    )) {
      buffer.write(chunk);
    }
    return buffer.toString().trim();
  }

  Stream<String> streamText({
    required List<AiMessage> messages,
    required AiGenerationConfig generationConfig,
    String? systemInstruction,
  }) async* {
    final traceId =
        LocalAiRuntimeDiagnostics.currentTraceId ??
        LocalAiRuntimeDiagnostics.newTraceId('local-inference');
    final queueStopwatch = Stopwatch()..start();
    final release = await _acquireOperation();
    final queueWaitMs = queueStopwatch.elapsedMilliseconds;
    try {
      final hasImage = messages.any((message) => message.images.isNotEmpty);
      final String activeModelId;
      final int contextSize;
      final String modelPath;
      final String? projectorPath;
      if (hasImage) {
        final paths = await _downloadAssets(
          modelId: localAiVisionModelId,
          assets: localAiVisionAssets,
        );
        activeModelId = localAiVisionModelId;
        contextSize = localAiVisionContextSize;
        modelPath = paths[0];
        projectorPath = paths[1];
      } else {
        final selectedId = await selectedModelId();
        if (selectedId == null) {
          throw StateError('Chưa chọn model AI trên thiết bị.');
        }
        final model = localAiTextModelById(selectedId);
        final path = await _installedPath(model.asset);
        if (path == null) {
          throw StateError('Không tìm thấy model AI đã tải.');
        }
        activeModelId = model.id;
        contextSize = model.contextSize;
        modelPath = path;
        projectorPath = null;
      }

      await _loadModel(
        modelId: activeModelId,
        modelPath: modelPath,
        contextSize: contextSize,
        projectorPath: projectorPath,
      );
      final engine = _engine;
      if (engine == null) throw StateError('Model AI chưa sẵn sàng.');
      if (messages.isEmpty) {
        throw StateError('Yêu cầu AI cần có ít nhất một tin nhắn.');
      }
      final boundedMessages = List<AiMessage>.of(messages);
      final systemPrompt = systemInstruction?.trim();
      final defaultOutput = min(384, max(96, contextSize ~/ 4)).toInt();
      final outputReserve = min(
        generationConfig.maxOutputTokens ?? defaultOutput,
        max(defaultOutput, contextSize ~/ 2),
      ).toInt();
      final imageReserve = hasImage ? 512 : 0;
      final tokenizationStopwatch = Stopwatch()..start();
      var tokenCount = 0;
      while (true) {
        final contentText = boundedMessages
            .map((message) => '${message.role.name}: ${message.text}')
            .join('\n');
        final tokenizedText = [
          if (systemPrompt != null && systemPrompt.isNotEmpty) systemPrompt,
          contentText,
        ].join('\n');
        tokenCount = (await engine.tokenize(tokenizedText)).length;
        final availableTokens =
            contextSize - tokenCount - imageReserve - outputReserve - 32;
        if (availableTokens >= 32) break;
        if (boundedMessages.length <= 1) {
          throw const LocalAiContextLimitException();
        }
        boundedMessages.removeAt(0);
        while (boundedMessages.length > 1 &&
            boundedMessages.first.role == AiMessageRole.assistant) {
          boundedMessages.removeAt(0);
        }
      }
      tokenizationStopwatch.stop();
      final availableTokens = contextSize - tokenCount - imageReserve - 32;
      final maxTokens = min(outputReserve, availableTokens).toInt();
      final session = ChatSession(
        engine,
        maxContextTokens: contextSize - 32,
        systemPrompt: systemPrompt,
      );
      if (boundedMessages.length > 1) {
        for (final message in boundedMessages.take(
          boundedMessages.length - 1,
        )) {
          session.addMessage(_toHistoryMessage(message));
        }
      }
      final parts = _toLlamaParts(boundedMessages.last);
      final stream = session.create(
        parts,
        params: GenerationParams(
          maxTokens: maxTokens,
          temp: generationConfig.temperature ?? 0.2,
          topP: generationConfig.topP ?? 0.8,
          topK: 40,
          streamBatchTokenThreshold: _streamBatchTokenThreshold,
        ),
        enableThinking: false,
        responseFormat: generationConfig.responseFormat != AiResponseFormat.json
            ? null
            : generationConfig.responseJsonSchema == null
            ? const {'type': 'json_object'}
            : {
                'type': 'json_schema',
                'json_schema': {'schema': generationConfig.responseJsonSchema},
              },
      );
      progress.value = LocalAiRuntimeProgress(
        stage: LocalAiRuntimeStage.generating,
        modelId: activeModelId,
      );
      final inferenceStopwatch = Stopwatch()..start();
      LocalAiRuntimeDiagnostics.info(
        traceId: traceId,
        operation: 'streamText.LOCAL_INFERENCE_STARTED',
        message: 'Local model inference started.',
        data: {
          'model': activeModelId,
          'contextSize': contextSize,
          'inputTokens': tokenCount,
          'outputReserveTokens': outputReserve,
          'availableTokens': availableTokens,
          'maxOutputTokens': maxTokens,
          'inferenceThreads': _inferenceThreads,
          'streamBatchTokenThreshold': _streamBatchTokenThreshold,
          'queueWaitMs': queueWaitMs,
          'tokenizationDurationMs': tokenizationStopwatch.elapsedMilliseconds,
          'hasSystemInstruction':
              systemPrompt != null && systemPrompt.isNotEmpty,
        },
      );
      var yieldedText = false;
      var outputTruncated = false;
      var firstTokenMs = 0;
      var hasFirstToken = false;
      LlamaGenerationUsage? usage;
      final output = StringBuffer();
      try {
        await for (final chunk in stream) {
          usage = chunk.usage ?? usage;
          if (chunk.text.isNotEmpty) {
            yieldedText = true;
            if (!hasFirstToken) {
              firstTokenMs = inferenceStopwatch.elapsedMilliseconds;
              hasFirstToken = true;
              LocalAiRuntimeDiagnostics.info(
                traceId: traceId,
                operation: 'streamText.LOCAL_INFERENCE_FIRST_TOKEN',
                message: 'Local model produced its first output chunk.',
                data: {
                  'model': activeModelId,
                  'contextSize': contextSize,
                  'firstTokenMs':
                      usage?.timeToFirstToken?.inMilliseconds ?? firstTokenMs,
                  'queueWaitMs': queueWaitMs,
                },
              );
            }
            output.write(chunk.text);
            yield chunk.text;
          }
          if (chunk.finishReason == LlamaFinishReason.length) {
            outputTruncated = true;
          }
        }

        if (outputTruncated) throw const LocalAiOutputTruncatedException();
        if (!session.lastRequestFitContext) {
          throw const LocalAiContextLimitException();
        }
        if (!yieldedText) throw StateError('Model AI không trả về nội dung.');

        inferenceStopwatch.stop();
        final reportedUsage = usage;
        final outputTokens =
            reportedUsage?.completionTokens ??
            (await engine.tokenize(output.toString())).length;
        LocalAiRuntimeDiagnostics.info(
          traceId: traceId,
          operation: 'streamText.LOCAL_INFERENCE_COMPLETED',
          message: 'Local model inference completed.',
          data: {
            'model': activeModelId,
            'contextSize': contextSize,
            'inputTokens': reportedUsage?.promptTokens ?? tokenCount,
            'outputTokens': outputTokens,
            'outputReserveTokens': outputReserve,
            'maxOutputTokens': maxTokens,
            'firstTokenMs':
                reportedUsage?.timeToFirstToken?.inMilliseconds ??
                (hasFirstToken ? firstTokenMs : 0),
            'inferenceDurationMs':
                reportedUsage?.duration?.inMilliseconds ??
                inferenceStopwatch.elapsedMilliseconds,
            'queueWaitMs': queueWaitMs,
            'tokenizationDurationMs': tokenizationStopwatch.elapsedMilliseconds,
            'hasSystemInstruction':
                systemPrompt != null && systemPrompt.isNotEmpty,
            'status': 'success',
          },
        );
      } catch (error) {
        inferenceStopwatch.stop();
        LocalAiRuntimeDiagnostics.warning(
          traceId: traceId,
          operation: 'streamText.LOCAL_INFERENCE_FAILED',
          message: 'Local model inference failed.',
          data: {
            'model': activeModelId,
            'contextSize': contextSize,
            'inputTokens': usage?.promptTokens ?? tokenCount,
            'outputTokens': usage?.completionTokens ?? 0,
            'outputReserveTokens': outputReserve,
            'maxOutputTokens': maxTokens,
            'firstTokenMs': hasFirstToken ? firstTokenMs : 0,
            'inferenceDurationMs': inferenceStopwatch.elapsedMilliseconds,
            'queueWaitMs': queueWaitMs,
            'tokenizationDurationMs': tokenizationStopwatch.elapsedMilliseconds,
            'errorCode': _safeInferenceErrorCode(error),
            'errorType': error.runtimeType.toString(),
          },
        );
        rethrow;
      }
    } finally {
      progress.value = null;
      await release();
    }
  }

  String _safeInferenceErrorCode(Object error) => switch (error) {
    LocalAiContextLimitException() => 'context_limit',
    LocalAiOutputTruncatedException() => 'output_truncated',
    LocalAiModelLoadException() => 'model_load',
    LocalAiInsufficientStorageException() => 'insufficient_storage',
    TimeoutException() => 'timeout',
    StateError() => 'runtime_state',
    _ => 'runtime_error',
  };

  Future<void> _ensureSelectedTextModelLoaded() async {
    final modelId = await selectedModelId();
    if (modelId == null) throw StateError('Chưa chọn model AI trên thiết bị.');
    final model = localAiTextModelById(modelId);
    if (_loadedModelId == model.id && _engine != null) return;
    final path = await _installedPath(model.asset);
    if (path == null) throw StateError('Không tìm thấy model AI đã tải.');
    await _loadModel(
      modelId: model.id,
      modelPath: path,
      contextSize: model.contextSize,
    );
  }

  List<LlamaContentPart> _toLlamaParts(AiMessage message) => [
    for (final image in message.images) LlamaImageContent(bytes: image.bytes),
    if (message.text.trim().isNotEmpty) LlamaTextContent(message.text),
  ];

  LlamaChatMessage _toHistoryMessage(AiMessage message) =>
      LlamaChatMessage.withContent(
        role: message.role == AiMessageRole.assistant
            ? LlamaChatRole.assistant
            : LlamaChatRole.user,
        content: _toLlamaParts(message),
      );

  Future<void> _loadModel({
    required String modelId,
    required String modelPath,
    required int contextSize,
    String? projectorPath,
  }) async {
    if (_loadedModelId == modelId && _engine != null) return;
    await _unload();
    final traceId =
        LocalAiRuntimeDiagnostics.currentTraceId ??
        LocalAiRuntimeDiagnostics.newTraceId('local-model-load');
    final loadStopwatch = Stopwatch()..start();
    progress.value = LocalAiRuntimeProgress(
      stage: LocalAiRuntimeStage.loading,
      modelId: modelId,
    );
    try {
      final engine = await LlamaEngine.load(
        LlamaModel(
          ModelSource.path(modelPath),
          projector: projectorPath == null
              ? null
              : ModelSource.path(projectorPath),
        ),
        params: ModelParams(
          contextSize: contextSize,
          gpuLayers: Platform.isIOS ? -1 : 0,
          device: Platform.isAndroid ? ComputeDevice.cpu : ComputeDevice.auto,
          preferredBackend: Platform.isIOS ? GpuBackend.metal : GpuBackend.auto,
          // Leave CPU headroom for Flutter and Android's foreground UI while
          // local inference is active. Auto mode saturated five cores on the
          // Xiaomi device during schedule generation.
          numberOfThreads: _inferenceThreads,
          numberOfThreadsBatch: _inferenceThreads,
          useMmap: true,
        ),
      );
      _engine = engine;
      _loadedModelId = modelId;
      if (projectorPath == null) {
        final session = ChatSession(
          engine,
          maxContextTokens: contextSize - 32,
          systemPrompt: 'Bạn là Nabi, trợ lý wellness nói tiếng Việt rõ ràng.',
        );
        progress.value = LocalAiRuntimeProgress(
          stage: LocalAiRuntimeStage.warming,
          modelId: modelId,
        );
        await session
            .create(
              const [LlamaTextContent('Trả lời bằng một từ: sẵn sàng.')],
              params: const GenerationParams(
                maxTokens: 1,
                temp: 0,
                streamBatchTokenThreshold: 1,
              ),
              enableThinking: false,
            )
            .drain<void>();
      }
      progress.value = LocalAiRuntimeProgress(
        stage: LocalAiRuntimeStage.ready,
        modelId: modelId,
      );
      loadStopwatch.stop();
      LocalAiRuntimeDiagnostics.info(
        traceId: traceId,
        operation: 'loadModel.LOCAL_MODEL_READY',
        message: 'Local model loaded and warmed up.',
        data: {
          'model': modelId,
          'contextSize': contextSize,
          'durationMs': loadStopwatch.elapsedMilliseconds,
          'status': 'ready',
        },
      );
    } catch (error) {
      loadStopwatch.stop();
      LocalAiRuntimeDiagnostics.warning(
        traceId: traceId,
        operation: 'loadModel.LOCAL_MODEL_LOAD_FAILED',
        message: 'Local model could not be loaded.',
        data: {
          'model': modelId,
          'contextSize': contextSize,
          'durationMs': loadStopwatch.elapsedMilliseconds,
          'errorCode': _safeInferenceErrorCode(error),
          'errorType': error.runtimeType.toString(),
        },
      );
      await _unload();
      if (error is LocalAiModelLoadException) rethrow;
      throw LocalAiModelLoadException(modelId, error);
    }
  }

  Future<void> _unload() async {
    final oldEngine = _engine;
    _engine = null;
    _loadedModelId = null;
    if (oldEngine != null) await oldEngine.dispose();
  }

  int get _inferenceThreads => min(
    // Two native inference threads still starved input delivery on the
    // Xiaomi during prefill. Keep one Android worker so the UI can process
    // input while local inference runs.
    Platform.isAndroid ? 1 : _maxInferenceThreads,
    Platform.numberOfProcessors,
  ).toInt();

  Future<List<String>> _downloadAssets({
    required String modelId,
    required List<LocalAiModelAsset> assets,
  }) async {
    final totalBytes = assets.fold<int>(
      0,
      (sum, asset) => sum + asset.sizeBytes,
    );
    var completedBytes = 0;
    final paths = <String>[];
    try {
      for (final asset in assets) {
        final existingPath = await _installedPath(asset);
        if (existingPath != null) {
          completedBytes += asset.sizeBytes;
          paths.add(existingPath);
          continue;
        }
        paths.add(
          await _downloadAsset(
            modelId: modelId,
            asset: asset,
            onProgress: (received) {
              progress.value = LocalAiRuntimeProgress(
                stage: LocalAiRuntimeStage.downloading,
                modelId: modelId,
                receivedBytes: completedBytes + received,
                totalBytes: totalBytes,
              );
            },
          ),
        );
        completedBytes += asset.sizeBytes;
      }
    } on FileSystemException {
      throw const LocalAiInsufficientStorageException();
    }
    return paths;
  }

  Future<String> _downloadAsset({
    required String modelId,
    required LocalAiModelAsset asset,
    required void Function(int receivedBytes) onProgress,
  }) async {
    final target = File(await _assetPath(asset));
    final partial = File('${target.path}.part');
    var offset = await partial.exists() ? await partial.length() : 0;
    if (offset > asset.sizeBytes) {
      await partial.delete();
      offset = 0;
    }
    if (offset == asset.sizeBytes) {
      if (await _verify(partial, asset)) {
        final installed = await partial.rename(target.path);
        await _writeVerificationMarker(installed, asset);
        return installed.path;
      }
      await partial.delete();
      offset = 0;
    }

    final client = http.Client();
    _activeDownloads[modelId] = client;
    try {
      final request = http.Request('GET', Uri.parse(asset.sourceUrl))
        ..headers['Accept-Encoding'] = 'identity';
      if (offset > 0) request.headers['Range'] = 'bytes=$offset-';
      final response = await client.send(request);
      final append =
          offset > 0 && response.statusCode == HttpStatus.partialContent;
      if (response.statusCode != HttpStatus.ok && !append) {
        throw HttpException(
          'Không tải được model AI (HTTP ${response.statusCode}).',
        );
      }
      if (!append) offset = 0;
      final output = partial.openWrite(
        mode: append ? FileMode.append : FileMode.write,
      );
      var received = offset;
      onProgress(received);
      try {
        await for (final bytes in response.stream) {
          if (!_activeDownloads.containsKey(modelId)) {
            throw const LocalAiDownloadCancelledException();
          }
          received += bytes.length;
          if (received > asset.sizeBytes) {
            throw LocalAiModelIntegrityException(asset.id);
          }
          output.add(bytes);
          onProgress(received);
        }
      } finally {
        await output.flush();
        await output.close();
      }
      if (received != asset.sizeBytes || !await _verify(partial, asset)) {
        throw LocalAiModelIntegrityException(asset.id);
      }
      if (await target.exists()) await target.delete();
      final installed = await partial.rename(target.path);
      await _writeVerificationMarker(installed, asset);
      return installed.path;
    } on LocalAiDownloadCancelledException {
      rethrow;
    } on LocalAiModelIntegrityException {
      rethrow;
    } on FileSystemException {
      throw const LocalAiInsufficientStorageException();
    } on http.ClientException {
      if (!_activeDownloads.containsKey(modelId)) {
        throw const LocalAiDownloadCancelledException();
      }
      throw const LocalAiDownloadFailedException();
    } on HttpException {
      throw const LocalAiDownloadFailedException();
    } catch (_) {
      if (!_activeDownloads.containsKey(modelId)) {
        throw const LocalAiDownloadCancelledException();
      }
      rethrow;
    } finally {
      _activeDownloads.remove(modelId);
      client.close();
    }
  }

  Future<String?> _installedPath(LocalAiModelAsset asset) async {
    final target = File(await _assetPath(asset));
    if (!await target.exists()) return null;
    if (await target.length() != asset.sizeBytes) {
      await target.delete();
      await _deleteVerificationMarker(target);
      return null;
    }
    if (await _isVerified(target, asset)) return target.path;
    if (!await _verify(target, asset)) {
      await target.delete();
      await _deleteVerificationMarker(target);
      return null;
    }
    await _writeVerificationMarker(target, asset);
    return target.path;
  }

  Future<bool> _verify(File file, LocalAiModelAsset asset) async {
    if (!await file.exists() || await file.length() != asset.sizeBytes) {
      return false;
    }
    final checksum = await sha256.bind(file.openRead()).first;
    final valid =
        checksum.toString().toLowerCase() == asset.sha256.toLowerCase();
    return valid;
  }

  Future<bool> _isVerified(File file, LocalAiModelAsset asset) async {
    final marker = File('${file.path}.verified');
    if (!await marker.exists()) return false;
    return (await marker.readAsString()) == _verificationMarker(asset);
  }

  String _verificationMarker(LocalAiModelAsset asset) =>
      '${asset.id}\n${asset.sizeBytes}\n${asset.sha256.toLowerCase()}';

  Future<void> _writeVerificationMarker(
    File file,
    LocalAiModelAsset asset,
  ) async {
    await File(
      '${file.path}.verified',
    ).writeAsString(_verificationMarker(asset), flush: true);
  }

  Future<void> _deleteVerificationMarker(File file) async {
    final marker = File('${file.path}.verified');
    if (await marker.exists()) await marker.delete();
  }

  Future<String> _assetPath(LocalAiModelAsset asset) async {
    final support = await getApplicationSupportDirectory();
    final models = Directory(p.join(support.path, 'ai_models'));
    await models.create(recursive: true);
    return p.join(models.path, asset.fileName);
  }

  Future<Future<void> Function()> _acquireOperation() async {
    final previous = _operationTail;
    final release = Completer<void>();
    _operationTail = release.future;
    await previous;
    return () async {
      if (!release.isCompleted) release.complete();
    };
  }

  Future<T> _withOperation<T>(Future<T> Function() operation) async {
    final release = await _acquireOperation();
    try {
      return await operation();
    } finally {
      await release();
      progress.value = null;
    }
  }
}
