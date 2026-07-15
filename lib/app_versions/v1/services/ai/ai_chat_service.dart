import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/config/app_env.dart';

import 'ai_exceptions.dart';
import 'ai_trace_logger.dart';
import 'gemini_rest_client.dart';
import 'ai_vietnamese_text_validator.dart';

typedef AIChatTextGenerator =
    Future<String> Function({
      required String modelName,
      required String message,
    });

final aiChatServiceProvider = Provider<AIChatService>((ref) {
  return AIChatService();
});

class AIChatService {
  static const _tag = 'AI_CHAT';
  static const _emptyFallback =
      'Mình chưa hiểu rõ ý bạn. Bạn có thể diễn đạt lại ngắn hơn một chút được không?';
  static const _invalidVietnameseFallback =
      'Mình chưa tạo được câu trả lời thật rõ ràng lúc này. Bạn thử hỏi lại theo cách khác nhé.';

  late final List<_AIChatModelEntry> _models;
  late final Future<void> Function(Duration) _delay;
  late final Random _random;
  late final AIChatTextGenerator? _textGenerator;
  late final GeminiRestClient? _geminiClient;
  late final DateTime Function() _now;
  late final Duration _modelCooldown;
  final Map<String, DateTime> _modelCooldownUntil = {};

  AIChatService({
    String? apiKeyOverride,
    List<String>? modelNames,
    Future<void> Function(Duration)? delay,
    Random? random,
    AIChatTextGenerator? textGenerator,
    GeminiRestClient? geminiClient,
    DateTime Function()? now,
    Duration? modelCooldown,
  }) {
    _delay = delay ?? ((duration) => Future<void>.delayed(duration));
    _random = random ?? Random();
    _textGenerator = textGenerator;
    _now = now ?? DateTime.now;
    _modelCooldown = modelCooldown ?? AIChatRetryPolicy.modelCooldown;

    final needsRuntimeClient = _textGenerator == null && geminiClient == null;
    final apiKey = apiKeyOverride != null
        ? _cleanEnv(apiKeyOverride)
        : (needsRuntimeClient ? _env('GEMINI_API_KEY') : null);
    final hasRuntimeClient =
        geminiClient != null || (apiKey != null && apiKey.isNotEmpty);
    _geminiClient = _textGenerator == null && hasRuntimeClient
        ? geminiClient ??
              GeminiRestClient(
                apiKey: apiKey!,
                baseUrl: _env('GEMINI_BASE_URL'),
              )
        : null;

    final resolvedModelNames =
        modelNames ??
        AIChatModelCandidates.resolve(
          primaryModel: _textGenerator == null
              ? _envWithLegacy('GEMINI_CHAT_MODEL', 'GEMINI_MODEL')
              : null,
          fallbackModelsCsv: _textGenerator == null
              ? _env('GEMINI_CHAT_FALLBACK_MODELS')
              : null,
        );
    AITraceLogger.info(
      _tag,
      AITraceLogger.nextTraceId('ai-chat-init'),
      'AIChatService.constructor',
      'MODELS_RESOLVED',
      'Resolved chat model names',
      data: {'models': resolvedModelNames},
      location: StackTrace.current,
    );

    if (!hasRuntimeClient && _textGenerator == null) {
      AITraceLogger.warning(
        _tag,
        AITraceLogger.nextTraceId('ai-chat-init'),
        'AIChatService.constructor',
        'MISSING_API_KEY',
        'Chat AI will use local fallback because GEMINI_API_KEY is missing.',
        data: {'source': AITraceLogger.localGen},
        location: StackTrace.current,
      );
    }

    _models = [
      for (final modelName in resolvedModelNames)
        _AIChatModelEntry(name: modelName),
    ];
  }

  Future<String> sendMessage(String message) async {
    final traceId = AITraceLogger.nextTraceId('ai-chat-message');
    const method = 'sendMessage';
    AITraceLogger.start(
      _tag,
      traceId,
      method,
      data: {'models': _modelNames(), 'messageLength': message.length},
      location: StackTrace.current,
    );

    if (!_hasRuntimeTextSource) {
      _throwMissingConfiguration(traceId: traceId, method: method);
    }

    try {
      final validation = await _runWithRetry(
        traceId: traceId,
        method: method,
        label: 'AI_CHAT_MESSAGE',
        operation: (entry) => _sendText(entry, message),
      );
      _logValidation(traceId, method, validation);
      return validation.text;
    } catch (error, stackTrace) {
      AITraceLogger.error(
        _tag,
        traceId,
        method,
        'ERROR_LOCAL_FALLBACK',
        'AI chat failed and used local fallback.',
        error,
        stackTrace,
        data: {'source': AITraceLogger.localGen, 'reason': 'retry_exhausted'},
        location: StackTrace.current,
      );
      _throwTypedFailure(error, stackTrace);
    }
  }

  void resetChat() {
    final traceId = AITraceLogger.nextTraceId('ai-chat-reset');
    const method = 'resetChat';
    for (final entry in _models) {
      entry.resetChat();
    }
    AITraceLogger.info(
      _tag,
      traceId,
      method,
      'SESSION_RESET',
      'AI chat session reset.',
      data: {'models': _modelNames()},
      location: StackTrace.current,
    );
  }

  Future<Stream<String>> sendMessageStream(String message) async {
    final traceId = AITraceLogger.nextTraceId('ai-chat-stream');
    const method = 'sendMessageStream';
    AITraceLogger.start(
      _tag,
      traceId,
      method,
      data: {'models': _modelNames(), 'messageLength': message.length},
      location: StackTrace.current,
    );

    if (!_hasRuntimeTextSource) {
      _throwMissingConfiguration(traceId: traceId, method: method);
    }

    try {
      final validation = await _runWithRetry(
        traceId: traceId,
        method: method,
        label: 'AI_CHAT_STREAM',
        operation: (entry) => _sendTextStream(entry, message),
      );
      _logValidation(traceId, method, validation);
      return Stream.value(validation.text);
    } catch (error, stackTrace) {
      AITraceLogger.error(
        _tag,
        traceId,
        method,
        'ERROR_LOCAL_FALLBACK',
        'AI chat stream failed and used local fallback.',
        error,
        stackTrace,
        data: {'source': AITraceLogger.localGen, 'reason': 'retry_exhausted'},
        location: StackTrace.current,
      );
      _throwTypedFailure(error, stackTrace);
    }
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

          final text = await operation(
            entry,
          ).timeout(AIChatRetryPolicy.perAttemptTimeout);
          final validation = _validatedResponse(text);
          AITraceLogger.info(
            _tag,
            traceId,
            method,
            'VALIDATED_RESPONSE',
            'AI chat response validated.',
            data: {'model': entry.name, ...validation.toMap()},
            location: StackTrace.current,
          );
          if (validation.source == AITraceLogger.aiGen) {
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
              },
              location: StackTrace.current,
            );
            return validation;
          }

          lastError = FormatException(validation.reason);
          lastStackTrace = StackTrace.current;
          AITraceLogger.warning(
            _tag,
            traceId,
            method,
            'RETRY_ATTEMPT_INVALID_RESPONSE',
            'Chat model returned invalid display text.',
            data: {
              'model': entry.name,
              'modelAttempt': modelAttempt,
              'totalAttempt': totalAttempts,
              'reason': validation.reason,
            },
            location: StackTrace.current,
          );
        } catch (error, stackTrace) {
          lastError = error;
          lastStackTrace = stackTrace;
          final transient = AIChatRetryPolicy.isTransient(error);
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
              'transient': transient,
            },
            location: StackTrace.current,
          );

          if (!transient) {
            break;
          }

          _cooldownModel(entry.name);
          final hasMoreAttempts =
              modelAttempt < AIChatRetryPolicy.maxAttemptsPerModel ||
              _hasAvailableModelAfter(modelIndex);
          if (!hasMoreAttempts) {
            break;
          }

          final delay = AIChatRetryPolicy.delayForFailureNumber(
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
              'delayMs': delay.inMilliseconds,
            },
            location: StackTrace.current,
          );
          await _delay(delay);
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
      return textGenerator(modelName: entry.name, message: message);
    }

    final client = _geminiClient;
    if (client == null) {
      throw StateError('Missing Gemini REST client for ${entry.name}');
    }

    final response = await client.generateText(
      model: entry.name,
      contents: entry.contentsWithUserMessage(message),
      generationConfig: const GeminiGenerationConfig(
        candidateCount: 1,
        maxOutputTokens: 512,
        temperature: 0.4,
        topP: 0.8,
      ),
      systemInstruction: _systemInstruction,
    );
    entry.rememberTurn(userMessage: message, modelMessage: response);
    return response;
  }

  Future<String> _sendTextStream(
    _AIChatModelEntry entry,
    String message,
  ) async {
    final textGenerator = _textGenerator;
    if (textGenerator != null) {
      return textGenerator(modelName: entry.name, message: message);
    }

    return _sendText(entry, message);
  }

  void _logValidation(
    String traceId,
    String method,
    _AIChatValidationResult validation,
  ) {
    if (validation.source == AITraceLogger.aiGen) {
      AITraceLogger.success(
        _tag,
        traceId,
        method,
        'SUCCESS',
        'AI chat returned a valid response.',
        data: {'source': validation.source, 'reason': validation.reason},
        location: StackTrace.current,
      );
      return;
    }

    AITraceLogger.warning(
      _tag,
      traceId,
      method,
      'LOCAL_FALLBACK',
      'AI chat used local fallback.',
      data: validation.toMap(),
      location: StackTrace.current,
    );
  }

  void _cooldownModel(String modelName) {
    if (_modelCooldown <= Duration.zero) {
      return;
    }
    _modelCooldownUntil[modelName] = _now().add(_modelCooldown);
  }

  DateTime? _activeCooldownUntil(String modelName) {
    final cooldownUntil = _modelCooldownUntil[modelName];
    if (cooldownUntil == null) {
      return null;
    }
    if (_now().isBefore(cooldownUntil)) {
      return cooldownUntil;
    }
    _modelCooldownUntil.remove(modelName);
    return null;
  }

  bool _hasAvailableModelAfter(int modelIndex) {
    for (var index = modelIndex + 1; index < _models.length; index++) {
      if (_activeCooldownUntil(_models[index].name) == null) {
        return true;
      }
    }
    return false;
  }

  List<String> _modelNames() {
    return _models.map((entry) => entry.name).toList(growable: false);
  }

  bool get _hasRuntimeTextSource =>
      _textGenerator != null || _geminiClient != null;

  Never _throwMissingConfiguration({
    required String traceId,
    required String method,
  }) {
    AITraceLogger.warning(
      _tag,
      traceId,
      method,
      'MISSING_API_KEY',
      'AI chat is unavailable because GEMINI_API_KEY is missing.',
      data: {'reason': 'missing_api_key', 'models': _modelNames()},
      location: StackTrace.current,
    );
    throw const AIConfigurationUnavailableException();
  }

  Never _throwTypedFailure(Object error, StackTrace stackTrace) {
    if (error is AIConfigurationUnavailableException ||
        error is AIAuthenticationException ||
        error is AIOverloadedException ||
        error is AIResponseInvalidException) {
      Error.throwWithStackTrace(error, stackTrace);
    }
    if (AIAuthenticationException.matches(error)) {
      Error.throwWithStackTrace(const AIAuthenticationException(), stackTrace);
    }
    if (AIOverloadedException.matches(error)) {
      Error.throwWithStackTrace(const AIOverloadedException(), stackTrace);
    }
    Error.throwWithStackTrace(const AIResponseInvalidException(), stackTrace);
  }

  static String? _envWithLegacy(String key, String legacyKey) {
    return AppEnv.maybeStringWithLegacy(key, legacyKey);
  }

  static String? _env(String key) {
    return AppEnv.maybeString(key);
  }

  static String? _cleanEnv(String? value) {
    final cleaned = value?.trim();
    if (cleaned == null || cleaned.isEmpty) {
      return null;
    }
    return cleaned;
  }

  static _AIChatValidationResult _validatedResponse(String? rawText) {
    final text = rawText?.trim() ?? '';
    if (text.isEmpty) {
      return const _AIChatValidationResult(
        text: _emptyFallback,
        source: AITraceLogger.localGen,
        reason: 'empty_response',
      );
    }

    if (!AIVietnameseTextValidator.isValidDisplayText(text)) {
      return const _AIChatValidationResult(
        text: _invalidVietnameseFallback,
        source: AITraceLogger.localGen,
        reason: 'invalid_vietnamese_response',
      );
    }

    return _AIChatValidationResult(
      text: text,
      source: AITraceLogger.aiGen,
      reason: 'valid_ai_response',
    );
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
- Tránh thuật ngữ y khoa phức tạp khi không cần thiết.
- Có giọng thân thiện, ấm áp và chuyên nghiệp.

Nguyên tắc an toàn:
- Không đưa ra chẩn đoán y tế.
- Không thay thế bác sĩ hoặc chuyên gia điều trị.
- Khuyến khích gặp bác sĩ khi triệu chứng nghiêm trọng, kéo dài hoặc bất thường.
- Tập trung vào thói quen sinh hoạt, dinh dưỡng, vận động và nghỉ ngơi.
- Chỉ dùng token kỹ thuật phổ biến khi thật cần thiết, ví dụ AI, BMI, kcal hoặc ml.

Ví dụ phong cách:
"Mình hiểu bạn đang cảm thấy mệt. Bạn nên ưu tiên ngủ đủ 7 đến 8 tiếng mỗi đêm, uống đủ nước và ăn thêm rau xanh. Nếu tình trạng kéo dài hoặc nặng hơn, bạn nên trao đổi với bác sĩ nhé."
''';
}

class AIChatModelCandidates {
  static const defaultPrimaryModel = 'gemini-3.1-flash-lite';
  static const defaultFallbackModels = ['gemini-2.5-flash-lite'];

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
      if (model.isEmpty || !seen.add(model)) {
        continue;
      }
      models.add(model);
    }

    return models.isEmpty ? const [defaultPrimaryModel] : models;
  }

  static List<String> _parseCsv(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) {
      return const [];
    }

    return text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static String? _clean(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }
}

class AIChatRetryPolicy {
  static const maxAttemptsPerModel = 1;
  static const perAttemptTimeout = Duration(seconds: 20);
  static const maxDelay = Duration(milliseconds: 3750);
  static const modelCooldown = Duration(minutes: 3);

  const AIChatRetryPolicy._();

  static bool isTransient(Object error) => AIOverloadedException.matches(error);

  static Duration baseDelayForFailureNumber(int failureNumber) {
    return switch (failureNumber) {
      <= 1 => const Duration(seconds: 1),
      _ => const Duration(seconds: 3),
    };
  }

  static Duration delayForFailureNumber(int failureNumber, {Random? random}) {
    final baseDelay = baseDelayForFailureNumber(failureNumber);
    final jitter = Duration(milliseconds: random?.nextInt(751) ?? 0);
    final delay = baseDelay + jitter;

    return delay.compareTo(maxDelay) > 0 ? maxDelay : delay;
  }
}

class _AIChatModelEntry {
  static const _maxHistoryMessages = 16;

  final String name;
  final List<GeminiContent> _history = [];

  _AIChatModelEntry({required this.name});

  List<GeminiContent> contentsWithUserMessage(String message) {
    return [..._history, GeminiContent.user(message)];
  }

  void rememberTurn({
    required String userMessage,
    required String modelMessage,
  }) {
    _history
      ..add(GeminiContent.user(userMessage))
      ..add(GeminiContent.model(modelMessage));

    final overflow = _history.length - _maxHistoryMessages;
    if (overflow > 0) {
      _history.removeRange(0, overflow);
    }
  }

  void resetChat() {
    _history.clear();
  }
}

class _AIChatValidationResult {
  final String text;
  final String source;
  final String reason;

  const _AIChatValidationResult({
    required this.text,
    required this.source,
    required this.reason,
  });

  Map<String, Object?> toMap() {
    return {'source': source, 'reason': reason, 'textLength': text.length};
  }
}
