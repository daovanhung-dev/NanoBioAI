import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/network/backend_ai_text_client.dart';

import 'ai_exceptions.dart';
import 'ai_text_sanitizer.dart';
import 'ai_trace_logger.dart';
import 'ai_vietnamese_text_validator.dart';
import 'ai_text_client.dart';

typedef AIChatTextGenerator =
    Future<String> Function({
      required String modelName,
      required String message,
    });

class AIChatPreparedResponse {
  final String text;
  final void Function() _onAccepted;
  bool _accepted = false;

  AIChatPreparedResponse({required this.text, void Function()? onAccepted})
    : _onAccepted = onAccepted ?? _noOp;

  void accept() {
    if (_accepted) return;
    _accepted = true;
    _onAccepted();
  }

  static void _noOp() {}
}

class AIChatPreparedStream {
  final Stream<String> stream;
  final void Function() _onAccepted;
  bool _accepted = false;

  AIChatPreparedStream({
    required this.stream,
    required void Function() onAccepted,
  }) : _onAccepted = onAccepted;

  void accept() {
    if (_accepted) return;
    _accepted = true;
    _onAccepted();
  }
}

final aiChatServiceProvider = Provider<AIChatService>((ref) {
  return AIChatService(
    aiClient: const BackendAiTextClient(),
    modelNames: const [BackendAiTextClient.modelId],
  );
});

class AIChatService {
  static const _tag = 'AI_CHAT';

  late final List<_AIChatModelEntry> _models;
  late final Future<void> Function(Duration) _delay;
  late final Random _random;
  late final AIChatTextGenerator? _textGenerator;
  late final AiTextClient? _aiClient;
  late final DateTime Function() _now;
  late final Duration _modelCooldown;
  late final Duration _perAttemptTimeout;
  final Map<String, DateTime> _modelCooldownUntil = {};

  AIChatService({
    List<String>? modelNames,
    Future<void> Function(Duration)? delay,
    Random? random,
    AIChatTextGenerator? textGenerator,
    AiTextClient? aiClient,
    DateTime Function()? now,
    Duration? modelCooldown,
    Duration? perAttemptTimeout,
  }) {
    _delay = delay ?? ((duration) => Future<void>.delayed(duration));
    _random = random ?? Random();
    _textGenerator = textGenerator;
    _now = now ?? DateTime.now;
    _modelCooldown = modelCooldown ?? AIChatRetryPolicy.modelCooldown;
    _perAttemptTimeout =
        perAttemptTimeout ?? AIChatRetryPolicy.perAttemptTimeout;

    _aiClient = _textGenerator == null
        ? aiClient ?? const BackendAiTextClient()
        : null;

    final resolvedModelNames = modelNames ?? [BackendAiTextClient.modelId];

    AITraceLogger.info(
      _tag,
      AITraceLogger.nextTraceId('ai-chat-init'),
      'AIChatService.constructor',
      'MODELS_RESOLVED',
      'Resolved chat model names',
      data: {'models': resolvedModelNames},
      location: StackTrace.current,
    );

    _models = [
      for (final modelName in resolvedModelNames)
        _AIChatModelEntry(name: modelName),
    ];
  }

  Future<String> sendMessage(String message) async {
    final preparedResponse = await prepareMessage(message);
    preparedResponse.accept();
    return preparedResponse.text;
  }

  Future<AIChatPreparedResponse> prepareMessage(String message) async {
    final traceId = AITraceLogger.nextTraceId('ai-chat-message');
    const method = 'prepareMessage';
    AITraceLogger.start(
      _tag,
      traceId,
      method,
      data: {'models': _modelNames(), 'messageLength': message.length},
      location: StackTrace.current,
    );

    if (!_hasRuntimeTextSource) {
      _throwMissingBackendClient(traceId: traceId, method: method);
    }

    try {
      final validation = await _runWithRetry(
        traceId: traceId,
        method: method,
        label: 'AI_CHAT_MESSAGE',
        operation: (entry) => _sendText(entry, message),
      );
      _logValidation(traceId, method, validation);
      return AIChatPreparedResponse(
        text: validation.text,
        onAccepted: () {
          validation.entry.rememberTurn(
            userMessage: message,
            modelMessage: validation.text,
          );
        },
      );
    } catch (error, stackTrace) {
      AITraceLogger.error(
        _tag,
        traceId,
        method,
        'ERROR_TYPED_FAILURE',
        'AI chat failed without creating a fallback response.',
        error,
        stackTrace,
        data: {'reason': 'retry_exhausted'},
        location: StackTrace.current,
      );
      _throwTypedFailure(error, stackTrace);
    }
  }

  /// Prepares a streaming backend model turn without adding it to conversation
  /// history until [AIChatPreparedStream.accept] is called by the repository.
  Future<AIChatPreparedStream> prepareMessageStream(String message) async {
    if (!_hasRuntimeTextSource) {
      _throwMissingBackendClient(
        traceId: AITraceLogger.nextTraceId('ai-chat-stream'),
        method: 'prepareMessageStream',
      );
    }

    // Injected generators keep deterministic behavior in focused tests.
    if (_textGenerator != null) {
      final prepared = await prepareMessage(message);
      return AIChatPreparedStream(
        stream: Stream<String>.value(prepared.text),
        onAccepted: prepared.accept,
      );
    }

    final pending = _PendingStreamTurn(userMessage: message);
    return AIChatPreparedStream(
      stream: _streamBackendMessage(message, pending),
      onAccepted: pending.accept,
    );
  }

  Future<Stream<String>> sendMessageStream(String message) async {
    final prepared = await prepareMessageStream(message);
    return (() async* {
      var accepted = false;
      await for (final delta in prepared.stream) {
        if (!accepted && delta.isNotEmpty) {
          prepared.accept();
          accepted = true;
        }
        yield delta;
      }
    })();
  }

  Stream<String> _streamBackendMessage(
    String message,
    _PendingStreamTurn pending,
  ) async* {
    final traceId = AITraceLogger.nextTraceId('ai-chat-stream');
    const method = 'prepareMessageStream';
    Object? lastError;
    StackTrace? lastStackTrace;
    var totalAttempts = 0;
    var hasPublishedText = false;

    for (var modelIndex = 0; modelIndex < _models.length; modelIndex++) {
      final entry = _models[modelIndex];
      if (_activeCooldownUntil(entry.name) != null) continue;
      totalAttempts++;
      final buffer = StringBuffer();
      final attemptStopwatch = Stopwatch()..start();

      try {
        final client = _aiClient;
        if (client == null) {
          throw const AIConfigurationUnavailableException();
        }

        final source = client
            .streamText(
              model: entry.name,
              messages: entry.contentsWithUserMessage(message),
              generationConfig: const AiGenerationConfig(
                temperature: 0.4,
                topP: 0.8,
              ),
              systemInstruction: _systemInstruction,
            )
            .timeout(_perAttemptTimeout);

        var visibleText = '';
        await for (final delta in source) {
          if (delta.isEmpty) continue;
          buffer.write(delta);

          final sanitizedPrefix = _sanitizedStreamPrefix(buffer.toString());
          if (!AIVietnameseTextValidator.isValidDisplayText(sanitizedPrefix) ||
              !sanitizedPrefix.startsWith(visibleText)) {
            continue;
          }

          final safeDelta = sanitizedPrefix.substring(visibleText.length);
          if (safeDelta.isNotEmpty) {
            visibleText = sanitizedPrefix;
            hasPublishedText = true;
            yield safeDelta;
          }
        }

        final validated = _validatedResponse(buffer.toString());
        if (!validated.startsWith(visibleText)) {
          throw const AIResponseInvalidException();
        }
        final remainingText = validated.substring(visibleText.length);
        if (remainingText.isNotEmpty) {
          hasPublishedText = true;
          yield remainingText;
        }
        pending.complete(entry: entry, modelMessage: validated);
        AITraceLogger.success(
          _tag,
          traceId,
          method,
          'STREAM_SUCCESS',
          'AI chat stream completed.',
          data: {
            'model': entry.name,
            'textLength': validated.length,
            'totalAttempt': totalAttempts,
            'durationMs': attemptStopwatch.elapsedMilliseconds,
          },
          location: StackTrace.current,
        );
        return;
      } catch (error, stackTrace) {
        lastError = error;
        lastStackTrace = stackTrace;

        final transient = error is TimeoutException
            ? false
            : AIChatRetryPolicy.isTransient(error);
        AITraceLogger.error(
          _tag,
          traceId,
          method,
          'STREAM_ATTEMPT_FAILED',
          'Backend AI chat stream failed.',
          error,
          stackTrace,
          data: {
            'model': entry.name,
            'status': _diagnosticStatusForFailure(error),
            'durationMs': attemptStopwatch.elapsedMilliseconds,
            'transient': transient,
          },
          location: StackTrace.current,
        );

        if (error is TimeoutException) {
          Error.throwWithStackTrace(
            const AIInferenceTimeoutException(),
            stackTrace,
          );
        }

        if (hasPublishedText) _throwTypedFailure(error, stackTrace);

        if (error is AiInferenceException && error.isOutputTruncated) {
          _throwTypedFailure(error, stackTrace);
        }

        if (AIAuthenticationException.matches(error)) {
          Error.throwWithStackTrace(
            const AIAuthenticationException(),
            stackTrace,
          );
        }

        if (transient) {
          _cooldownModel(entry.name);
          if (_hasAvailableModelAfter(modelIndex)) {
            final retryDelay = AIChatRetryPolicy.delayForFailureNumber(
              totalAttempts,
              random: _random,
            );
            await _delay(retryDelay);
          }
        }
      }
    }

    _throwTypedFailure(
      lastError ?? const AIOverloadedException(),
      lastStackTrace ?? StackTrace.current,
    );
  }

  void resetChat() {
    for (final entry in _models) {
      entry.resetChat();
    }
    AITraceLogger.info(
      _tag,
      AITraceLogger.nextTraceId('ai-chat-reset'),
      'resetChat',
      'SESSION_RESET',
      'AI chat session reset.',
      data: {'models': _modelNames()},
      location: StackTrace.current,
    );
  }

  Future<_AIChatValidationResult> _runWithRetry({
    required String traceId,
    required String method,
    required String label,
    required Future<String> Function(_AIChatModelEntry entry) operation,
  }) async {
    var totalAttempts = 0;
    var cooldownSkips = 0;
    Object? lastError;
    StackTrace? lastStackTrace;

    for (var modelIndex = 0; modelIndex < _models.length; modelIndex++) {
      final entry = _models[modelIndex];
      final cooldownUntil = _activeCooldownUntil(entry.name);
      if (cooldownUntil != null) {
        cooldownSkips++;
        AITraceLogger.info(
          _tag,
          traceId,
          method,
          'MODEL_COOLDOWN_SKIP',
          'Skipping chat model in transient-error cooldown.',
          data: {
            'model': entry.name,
            'cooldownMs': cooldownUntil.difference(_now()).inMilliseconds,
          },
          location: StackTrace.current,
        );
        continue;
      }

      for (
        var modelAttempt = 1;
        modelAttempt <= AIChatRetryPolicy.maxAttemptsPerModel;
        modelAttempt++
      ) {
        totalAttempts++;
        final attemptStopwatch = Stopwatch()..start();
        try {
          AITraceLogger.info(
            _tag,
            traceId,
            method,
            'RETRY_ATTEMPT_START',
            label,
            data: {
              'model': entry.name,
              'modelAttempt': modelAttempt,
              'totalAttempt': totalAttempts,
            },
            location: StackTrace.current,
          );

          final text = await operation(entry);
          final responseText = _validatedResponse(text);
          final validation = _AIChatValidationResult(
            text: responseText,
            reason: 'valid_ai_response',
            entry: entry,
          );
          AITraceLogger.info(
            _tag,
            traceId,
            method,
            'VALIDATED_RESPONSE',
            'AI chat response validated.',
            data: {'model': entry.name, ...validation.toMap()},
            location: StackTrace.current,
          );
          AITraceLogger.success(
            _tag,
            traceId,
            method,
            'RETRY_ATTEMPT_SUCCESS',
            label,
            data: {
              'model': entry.name,
              'modelAttempt': modelAttempt,
              'totalAttempt': totalAttempts,
              'durationMs': attemptStopwatch.elapsedMilliseconds,
            },
            location: StackTrace.current,
          );
          return validation;
        } on AIResponseInvalidException catch (error, stackTrace) {
          lastError = error;
          lastStackTrace = stackTrace;
          AITraceLogger.warning(
            _tag,
            traceId,
            method,
            'RETRY_ATTEMPT_INVALID_RESPONSE',
            'Chat model returned an invalid display response.',
            data: {
              'model': entry.name,
              'modelAttempt': modelAttempt,
              'totalAttempt': totalAttempts,
              'status': 'invalid_response',
              'durationMs': attemptStopwatch.elapsedMilliseconds,
            },
            location: StackTrace.current,
          );
          break;
        } catch (error, stackTrace) {
          lastError = error;
          lastStackTrace = stackTrace;
          final timedOut = error is TimeoutException;
          final transient = !timedOut && AIChatRetryPolicy.isTransient(error);
          AITraceLogger.error(
            _tag,
            traceId,
            method,
            'RETRY_ATTEMPT_FAILED',
            label,
            error,
            stackTrace,
            data: {
              'model': entry.name,
              'modelAttempt': modelAttempt,
              'totalAttempt': totalAttempts,
              'status': _diagnosticStatusForFailure(error),
              'durationMs': attemptStopwatch.elapsedMilliseconds,
              'transient': transient,
            },
            location: StackTrace.current,
          );

          if (timedOut) {
            Error.throwWithStackTrace(
              const AIInferenceTimeoutException(),
              stackTrace,
            );
          }

          if (AIAuthenticationException.matches(error)) {
            Error.throwWithStackTrace(
              const AIAuthenticationException(),
              stackTrace,
            );
          }

          if (!transient) break;

          _cooldownModel(entry.name);
          final hasMoreAttempts =
              modelAttempt < AIChatRetryPolicy.maxAttemptsPerModel ||
              _hasAvailableModelAfter(modelIndex);
          if (!hasMoreAttempts) break;

          final retryDelay = AIChatRetryPolicy.delayForFailureNumber(
            totalAttempts,
            random: _random,
          );
          AITraceLogger.info(
            _tag,
            traceId,
            method,
            'RETRY_DELAY',
            'Waiting before chat retry.',
            data: {
              'model': entry.name,
              'nextTotalAttempt': totalAttempts + 1,
              'delayMs': retryDelay.inMilliseconds,
            },
            location: StackTrace.current,
          );
          await _delay(retryDelay);
        }
      }
    }

    AITraceLogger.warning(
      _tag,
      traceId,
      method,
      'RETRY_EXHAUSTED',
      label,
      data: {
        'totalAttempts': totalAttempts,
        'cooldownSkips': cooldownSkips,
        'models': _modelNames(),
        'lastErrorType': lastError?.runtimeType.toString(),
      },
      location: StackTrace.current,
    );
    Error.throwWithStackTrace(
      lastError ?? const AIOverloadedException(),
      lastStackTrace ?? StackTrace.current,
    );
  }

  Future<String> _sendText(_AIChatModelEntry entry, String message) async {
    final textGenerator = _textGenerator;
    if (textGenerator != null) {
      return textGenerator(
        modelName: entry.name,
        message: message,
      ).timeout(_perAttemptTimeout);
    }

    final client = _aiClient;
    if (client == null) {
      throw const AIConfigurationUnavailableException();
    }

    final response = StringBuffer();
    await for (final delta
        in client
            .streamText(
              model: entry.name,
              messages: entry.contentsWithUserMessage(message),
              generationConfig: const AiGenerationConfig(
                temperature: 0.4,
                topP: 0.8,
              ),
              systemInstruction: _systemInstruction,
            )
            .timeout(_perAttemptTimeout)) {
      response.write(delta);
    }
    return response.toString();
  }

  void _logValidation(
    String traceId,
    String method,
    _AIChatValidationResult validation,
  ) {
    AITraceLogger.success(
      _tag,
      traceId,
      method,
      'SUCCESS',
      'AI chat returned a valid response.',
      data: validation.toMap(),
      location: StackTrace.current,
    );
  }

  void _cooldownModel(String modelName) {
    if (_modelCooldown <= Duration.zero) return;
    _modelCooldownUntil[modelName] = _now().add(_modelCooldown);
  }

  DateTime? _activeCooldownUntil(String modelName) {
    final cooldownUntil = _modelCooldownUntil[modelName];
    if (cooldownUntil == null) return null;
    if (_now().isBefore(cooldownUntil)) return cooldownUntil;
    _modelCooldownUntil.remove(modelName);
    return null;
  }

  bool _hasAvailableModelAfter(int modelIndex) {
    for (var index = modelIndex + 1; index < _models.length; index++) {
      if (_activeCooldownUntil(_models[index].name) == null) return true;
    }
    return false;
  }

  List<String> _modelNames() =>
      _models.map((entry) => entry.name).toList(growable: false);

  bool get _hasRuntimeTextSource => _textGenerator != null || _aiClient != null;

  Never _throwMissingBackendClient({
    required String traceId,
    required String method,
  }) {
    AITraceLogger.warning(
      _tag,
      traceId,
      method,
      'BACKEND_AI_CLIENT_UNAVAILABLE',
      'Chat AI is unavailable because the backend client is not configured.',
      data: {'models': _modelNames()},
      location: StackTrace.current,
    );
    throw const AIConfigurationUnavailableException();
  }

  Never _throwTypedFailure(Object error, StackTrace stackTrace) {
    if (error is AIConfigurationUnavailableException ||
        error is AIInferenceTimeoutException ||
        error is AIPlatformUnsupportedException ||
        error is AIAuthenticationException ||
        error is AINetworkException ||
        error is AIModelUnavailableException ||
        error is AIOverloadedException ||
        error is AIResponseInvalidException) {
      Error.throwWithStackTrace(error, stackTrace);
    }
    if (AIPlatformUnsupportedException.matches(error)) {
      Error.throwWithStackTrace(
        const AIPlatformUnsupportedException(),
        stackTrace,
      );
    }
    if (AIAuthenticationException.matches(error)) {
      Error.throwWithStackTrace(const AIAuthenticationException(), stackTrace);
    }
    if (AINetworkException.matches(error)) {
      Error.throwWithStackTrace(const AINetworkException(), stackTrace);
    }
    if (AIModelUnavailableException.matches(error)) {
      Error.throwWithStackTrace(
        const AIModelUnavailableException(),
        stackTrace,
      );
    }
    if (AIOverloadedException.matches(error)) {
      Error.throwWithStackTrace(const AIOverloadedException(), stackTrace);
    }
    Error.throwWithStackTrace(const AIResponseInvalidException(), stackTrace);
  }

  static String _validatedResponse(String? rawText) {
    final text = AITextSanitizer.sanitize(rawText ?? '');
    if (text.isEmpty) throw const AIResponseInvalidException();
    if (!AIVietnameseTextValidator.isValidDisplayText(text)) {
      throw const AIResponseInvalidException();
    }
    return text;
  }

  static const String _systemInstruction = '''
Bạn là Nabi, trợ lý sức khỏe thông minh và thân thiện.

Vai trò:
- Tư vấn về dinh dưỡng, giấc ngủ, căng thẳng và lối sống lành mạnh.
- Đưa ra gợi ý cá nhân hóa dựa trên thông tin sức khỏe người dùng.
- Luôn lắng nghe, thấu hiểu và trả lời thực tế.

Phong cách:
- Luôn trả lời bằng tiếng Việt có dấu.
- Gọi người dùng là "bạn", tự xưng là "mình".
- Câu trả lời ngắn gọn, dễ hiểu, thường từ 2 đến 4 câu.
- Ưu tiên câu ngắn để phản hồi giọng nói bắt đầu nhanh.
- Không dùng markdown hoặc ký tự trang trí đặc biệt trong câu trả lời.
- Tránh thuật ngữ y khoa phức tạp khi không cần thiết.
- Có giọng thân thiện, ấm áp và chuyên nghiệp.

Nguyên tắc an toàn:
- Không đưa ra chẩn đoán y tế.
- Không thay thế bác sĩ hoặc chuyên gia điều trị.
- Khuyến khích gặp bác sĩ khi triệu chứng nghiêm trọng, kéo dài hoặc bất thường.
- Tập trung vào thói quen sinh hoạt, dinh dưỡng, vận động và nghỉ ngơi.
- Chỉ dùng token kỹ thuật phổ biến khi thật cần thiết, ví dụ AI, BMI, kcal hoặc ml.
''';
}

class _PendingStreamTurn {
  final String userMessage;
  bool _accepted = false;
  bool _completed = false;
  bool _remembered = false;
  _AIChatModelEntry? _entry;
  String _modelMessage = '';

  _PendingStreamTurn({required this.userMessage});

  void accept() {
    _accepted = true;
    _rememberIfReady();
  }

  void complete({
    required _AIChatModelEntry entry,
    required String modelMessage,
  }) {
    _entry = entry;
    _modelMessage = modelMessage;
    _completed = true;
    _rememberIfReady();
  }

  void _rememberIfReady() {
    if (!_accepted || !_completed || _remembered) return;
    final entry = _entry;
    if (entry == null || _modelMessage.isEmpty) return;
    _remembered = true;
    entry.rememberTurn(userMessage: userMessage, modelMessage: _modelMessage);
  }
}

class AIChatModelCandidates {
  static const defaultPrimaryModel = BackendAiTextClient.modelId;
  static const defaultFallbackModels = <String>[];

  const AIChatModelCandidates._();

  static List<String> resolve({
    required String? primaryModel,
    required String? fallbackModelsCsv,
  }) {
    final fallbackModels = _parseCsv(fallbackModelsCsv);
    final rawModels = <String>[
      _clean(primaryModel) ?? defaultPrimaryModel,
      ...(fallbackModels.isEmpty ? defaultFallbackModels : fallbackModels),
    ];
    final models = <String>[];
    final seen = <String>{};
    for (final rawModel in rawModels) {
      final model = rawModel.trim();
      if (model.isEmpty || !seen.add(model)) continue;
      models.add(model);
    }
    return models.isEmpty ? const [defaultPrimaryModel] : models;
  }

  static List<String> _parseCsv(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return const [];
    return text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static String? _clean(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }
}

class AIChatRetryPolicy {
  static const maxAttemptsPerModel = 1;
  static const perAttemptTimeout = Duration(seconds: 120);
  static const maxDelay = Duration(milliseconds: 3750);
  static const modelCooldown = Duration(minutes: 3);

  const AIChatRetryPolicy._();

  static bool isTransient(Object error) => AIOverloadedException.matches(error);

  static Duration baseDelayForFailureNumber(int failureNumber) {
    return failureNumber <= 1
        ? const Duration(seconds: 1)
        : const Duration(seconds: 3);
  }

  static Duration delayForFailureNumber(int failureNumber, {Random? random}) {
    final baseDelay = baseDelayForFailureNumber(failureNumber);
    final jitter = Duration(milliseconds: random?.nextInt(751) ?? 0);
    final delay = baseDelay + jitter;
    return delay.compareTo(maxDelay) > 0 ? maxDelay : delay;
  }
}

String _diagnosticStatusForFailure(Object error) {
  if (error is TimeoutException || error is AIInferenceTimeoutException) {
    return 'backend_inference_timeout';
  }
  if (error is AiInferenceException) {
    final status = error.status?.trim().toLowerCase();
    if (status != null && RegExp(r'^[a-z0-9_]{1,64}$').hasMatch(status)) {
      return status;
    }
  }
  if (error is StateError) return 'backend_runtime_state_error';
  return 'backend_inference_error';
}

String _sanitizedStreamPrefix(String rawText) {
  final lastOpeningTag = rawText.lastIndexOf('<');
  if (lastOpeningTag > rawText.lastIndexOf('>')) {
    rawText = rawText.substring(0, lastOpeningTag);
  }
  return AITextSanitizer.sanitize(rawText);
}

class _AIChatModelEntry {
  static const _maxHistoryMessages = 16;

  final String name;
  final List<AiMessage> _history = [];

  _AIChatModelEntry({required this.name});

  List<AiMessage> contentsWithUserMessage(String message) {
    return [..._history, AiMessage.user(message)];
  }

  void rememberTurn({
    required String userMessage,
    required String modelMessage,
  }) {
    _history
      ..add(AiMessage.user(userMessage))
      ..add(AiMessage.assistant(modelMessage));
    final overflow = _history.length - _maxHistoryMessages;
    if (overflow > 0) _history.removeRange(0, overflow);
  }

  void resetChat() => _history.clear();
}

class _AIChatValidationResult {
  final String text;
  final String reason;
  final _AIChatModelEntry entry;

  const _AIChatValidationResult({
    required this.text,
    required this.reason,
    required this.entry,
  });

  Map<String, Object?> toMap() {
    return {
      'source': AITraceLogger.aiGen,
      'reason': reason,
      'textLength': text.length,
    };
  }
}
