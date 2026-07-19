import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/interfaces/health_data_interface.dart';
import 'package:nano_app/core/config/app_env.dart';
import 'package:nano_app/core/storage/localdb/datasources/ai_catalog_local_datasource.dart';
import 'package:nano_app/core/storage/localdb/models/ai_catalog_models.dart';
import 'package:nano_app/app_versions/v1/features/daily_health_tracking/domain/entities/daily_health_profile_entity.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/data/models/exercise_task_model.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/data/models/exercise_tasks_ai_normalizer.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/data/models/meal_plan_ai_normalizer.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/data/models/meal_plan_model.dart';

import 'ai_exceptions.dart';
import 'ai_generation_result.dart';
import 'ai_json_parser.dart';
import 'ai_json_prompt_builder.dart';
import 'gemini_rest_client.dart';
import 'ai_trace_logger.dart';
import 'prompts/exercise_tasks_prompt.dart';
import 'prompts/meal_plan_prompt.dart';

typedef AITextGenerator =
    Future<String> Function({
      required String modelName,
      required String prompt,
    });

typedef AiCatalogLoader = Future<AiCatalogBundle> Function();

final aiServiceProvider = Provider<AIService>((ref) {
  return AIService();
});

class AIConnectionCheckResult {
  final bool success;
  final String message;
  final String? modelName;

  const AIConnectionCheckResult({
    required this.success,
    required this.message,
    this.modelName,
  });

  const AIConnectionCheckResult.success({required this.modelName})
    : success = true,
      message = 'AI đã sẵn sàng.';

  const AIConnectionCheckResult.failure({required this.message, this.modelName})
    : success = false;
}

class AIService {
  static const _tag = 'AI_SERVICE';
  static const _chunkSizes = [7];
  static const _connectionCheckStatusCode = 'ai_connection_ok';
  static const _connectionCheckPrompt = '''
Trả về đúng một mảng JSON theo schema sau:
[{"status_code":"ai_connection_ok"}]
Không thêm chữ giải thích, markdown hoặc dữ liệu khác.
''';

  late final List<_AIModelEntry> _models;
  late final Future<void> Function(Duration) _delay;
  late final Random _random;
  late final AITextGenerator? _textGenerator;
  late final GeminiRestClient? _geminiClient;
  late final AiCatalogLoader _catalogLoader;
  late final DateTime Function() _now;
  late final Duration _modelCooldown;
  final Map<String, DateTime> _modelCooldownUntil = {};

  AIService({
    String? apiKeyOverride,
    List<String>? modelNames,
    Future<void> Function(Duration)? delay,
    Random? random,
    AITextGenerator? textGenerator,
    GeminiRestClient? geminiClient,
    AiCatalogLoader? catalogLoader,
    DateTime Function()? now,
    Duration? modelCooldown,
  }) {
    _delay = delay ?? ((duration) => Future<void>.delayed(duration));
    _random = random ?? Random();
    _textGenerator = textGenerator;
    _now = now ?? DateTime.now;
    _modelCooldown = modelCooldown ?? AIRetryPolicy.modelCooldown;
    _catalogLoader =
        catalogLoader ?? const AiCatalogLocalDatasource().loadActiveBundle;

    final needsRuntimeClient = _textGenerator == null && geminiClient == null;
    final apiKey = apiKeyOverride != null
        ? _cleanEnv(apiKeyOverride)
        : (needsRuntimeClient ? AppEnv.maybeString('GEMINI_API_KEY') : null);
    final hasRuntimeClient =
        geminiClient != null || (apiKey != null && apiKey.isNotEmpty);
    _geminiClient = _textGenerator == null && hasRuntimeClient
        ? geminiClient ??
              GeminiRestClient(
                apiKey: apiKey!,
                baseUrl: AppEnv.maybeString('GEMINI_BASE_URL'),
              )
        : null;

    if (!hasRuntimeClient && _textGenerator == null) {
      AITraceLogger.warning(
        _tag,
        AITraceLogger.nextTraceId('ai-service-init'),
        'AIService.constructor',
        'MISSING_API_KEY',
        'AI plan generation will use local fallback because GEMINI_API_KEY is missing.',
        data: {'source': AITraceLogger.localGen},
        location: StackTrace.current,
      );
    }

    final resolvedModelNames =
        modelNames ??
        AIModelCandidates.resolve(
          primaryModel: _textGenerator == null
              ? _envWithLegacy('GEMINI_PLAN_MODEL', 'GEMINI_MODEL')
              : null,
          fallbackModelsCsv: _textGenerator == null
              ? _envWithLegacy(
                  'GEMINI_PLAN_FALLBACK_MODELS',
                  'GEMINI_FALLBACK_MODELS',
                )
              : null,
          overflowModelsCsv: _textGenerator == null
              ? AppEnv.maybeString('GEMINI_PLAN_OVERFLOW_MODELS')
              : null,
        );
    AITraceLogger.info(
      _tag,
      AITraceLogger.nextTraceId('ai-service-init'),
      'AIService.constructor',
      'MODELS_RESOLVED',
      'Resolved model names',
      data: {'models': resolvedModelNames},
      location: StackTrace.current,
    );

    _models = [
      for (final modelName in resolvedModelNames)
        _AIModelEntry(name: modelName),
    ];
  }

  Future<AIConnectionCheckResult> checkConnection({
    Duration perModelTimeout = const Duration(seconds: 12),
  }) async {
    final traceId = AITraceLogger.nextTraceId('ai-connection');
    const method = 'checkConnection';
    AITraceLogger.start(
      _tag,
      traceId,
      method,
      data: {
        'perModelTimeoutMs': perModelTimeout.inMilliseconds,
        'models': _modelNames(),
      },
      location: StackTrace.current,
    );

    if (_models.isEmpty) {
      AITraceLogger.warning(
        _tag,
        traceId,
        method,
        'NO_MODELS',
        'Không có model AI để kiểm tra.',
        location: StackTrace.current,
      );
      return const AIConnectionCheckResult.failure(
        message: 'Không có model AI để kiểm tra.',
      );
    }

    if (_textGenerator == null && _geminiClient == null) {
      const message = 'Thiếu GEMINI_API_KEY hoặc key đang rỗng.';
      AITraceLogger.warning(
        _tag,
        traceId,
        method,
        'MISSING_API_KEY',
        message,
        data: {'source': AITraceLogger.localGen},
        location: StackTrace.current,
      );
      return const AIConnectionCheckResult.failure(message: message);
    }

    Object? lastError;
    String? lastModelName;
    final prompt = AIJsonPromptBuilder.buildArrayPrompt(_connectionCheckPrompt);

    for (final entry in _models) {
      try {
        AITraceLogger.info(
          _tag,
          traceId,
          method,
          'MODEL_CHECK_START',
          'Kiểm tra kết nối với model ${entry.name}',
          data: {'model': entry.name},
          location: StackTrace.current,
        );
        final text = await _generateText(
          entry,
          prompt,
          traceId: traceId,
          method: method,
          step: 'CONNECTION_CHECK_GENERATE_TEXT',
        ).timeout(perModelTimeout);

        if (text.trim().isEmpty) {
          throw const FormatException('Gemini returned an empty response');
        }

        final decoded = AIJsonParser.decodeArray(text);
        if (decoded.isEmpty) {
          throw const FormatException('Gemini returned an empty JSON array');
        }
        AITraceLogger.info(
          _tag,
          traceId,
          method,
          'CONNECTION_CHECK_RESPONSE_VALIDATED',
          'AI connection check response validated.',
          data: {'model': entry.name, 'itemCount': decoded.length},
          location: StackTrace.current,
        );

        final first = decoded.first;
        if (first is! Map ||
            first['status_code']?.toString() != _connectionCheckStatusCode) {
          throw const FormatException(
            'Gemini returned an invalid connection check payload',
          );
        }

        AITraceLogger.success(
          _tag,
          traceId,
          method,
          'SUCCESS',
          'AI connection check thành công.',
          data: {'model': entry.name, 'source': AITraceLogger.aiGen},
          location: StackTrace.current,
        );
        return AIConnectionCheckResult.success(modelName: entry.name);
      } catch (error, stackTrace) {
        lastError = error;
        lastModelName = entry.name;
        AITraceLogger.error(
          _tag,
          traceId,
          method,
          'MODEL_CHECK_FAILED',
          'AI connection check failed.',
          error,
          stackTrace,
          data: {'model': entry.name},
          location: StackTrace.current,
        );
      }
    }

    final result = AIConnectionCheckResult.failure(
      message: _connectionCheckFailureMessage(lastError),
      modelName: lastModelName,
    );
    AITraceLogger.warning(
      _tag,
      traceId,
      method,
      'FAILURE',
      result.message,
      data: {'model': lastModelName},
      location: StackTrace.current,
    );
    return result;
  }

  Future<List<MealPlanModel>> generateMealPlan({
    required HealthDataInterface healthData,
    required String userId,
    required DateTime startDate,
    int days = 7,
  }) async {
    final result = await generateMealPlanWithSource(
      healthData: healthData,
      userId: userId,
      startDate: startDate,
      days: days,
    );
    return result.value;
  }

  Future<AIGenerationResult<List<MealPlanModel>>> generateMealPlanWithSource({
    required HealthDataInterface healthData,
    required String userId,
    required DateTime startDate,
    int days = 7,
  }) async {
    final traceId = AITraceLogger.nextTraceId('meal-plan');
    const method = 'generateMealPlan';
    AITraceLogger.start(
      _tag,
      traceId,
      method,
      data: {'days': days, 'models': _modelNames()},
      location: StackTrace.current,
    );

    final catalog = await _catalogLoader();
    AITraceLogger.info(
      _tag,
      traceId,
      method,
      'CATALOG_LOADED',
      'AI catalog loaded.',
      data: _catalogCounts(catalog),
      location: StackTrace.current,
    );

    final normalizer = const MealPlanAiNormalizer();
    final usedCodeCounts = <String, int>{};
    final codeItems = <Map<String, dynamic>>[];
    final chunkSources = <PlanGenerationSource>[];
    final chunks = _chunkPlan(days);
    AITraceLogger.info(
      _tag,
      traceId,
      method,
      'CHUNK_PLAN',
      'Meal generation chunks prepared.',
      data: {'chunkCount': chunks.length, 'days': days},
      location: StackTrace.current,
    );

    for (final chunk in chunks) {
      final prompt = MealPlanPrompt.generate(
        healthData: healthData,
        startDate: startDate,
        startDay: chunk.startDay,
        days: chunk.days,
        catalog: catalog.meals,
        usedMealCodes: _usedCodes(usedCodeCounts),
      );
      final chunkResult = await _generateMealChunk(
        normalizer: normalizer,
        catalog: catalog,
        prompt: prompt,
        chunk: chunk,
        usedCodeCounts: usedCodeCounts,
        traceId: traceId,
      );
      _accumulateCodeCounts(chunkResult.items, 'meal_code', usedCodeCounts);
      codeItems.addAll(chunkResult.items);
      chunkSources.add(chunkResult.source);
      AITraceLogger.info(
        _tag,
        traceId,
        method,
        'MEAL_CHUNK_ACCUMULATED',
        'Meal chunk counts accumulated.',
        data: {
          'chunkStartDay': chunk.startDay,
          'itemCount': chunkResult.items.length,
          'distinctCodeCount': usedCodeCounts.length,
        },
        location: StackTrace.current,
      );
    }

    final createdAt = DateTime.now().toIso8601String();
    final meals = normalizer.normalize(
      items: codeItems,
      catalog: catalog,
      userId: userId,
      startDate: startDate,
      days: days,
      createdAt: createdAt,
    );
    final source = PlanGenerationSource.combine(chunkSources);
    AITraceLogger.success(
      _tag,
      traceId,
      method,
      'SUCCESS',
      'Tạo thực đơn hoàn tất.',
      data: {
        'codeItemCount': codeItems.length,
        'mealCount': meals.length,
        'source': source.storageValue,
      },
      location: StackTrace.current,
    );
    return AIGenerationResult(value: meals, source: source);
  }

  Future<List<ExerciseTaskModel>> generateExerciseTasks({
    required DailyHealthProfileEntity profile,
    required DateTime startDate,
    int days = 7,
  }) async {
    final result = await generateExerciseTasksWithSource(
      profile: profile,
      startDate: startDate,
      days: days,
    );
    return result.value;
  }

  Future<AIGenerationResult<List<ExerciseTaskModel>>>
  generateExerciseTasksWithSource({
    required DailyHealthProfileEntity profile,
    required DateTime startDate,
    int days = 7,
  }) async {
    final traceId = AITraceLogger.nextTraceId('exercise-tasks');
    const method = 'generateExerciseTasks';
    AITraceLogger.start(
      _tag,
      traceId,
      method,
      data: {'days': days, 'models': _modelNames()},
      location: StackTrace.current,
    );

    final catalog = await _catalogLoader();
    AITraceLogger.info(
      _tag,
      traceId,
      method,
      'CATALOG_LOADED',
      'AI catalog loaded.',
      data: _catalogCounts(catalog),
      location: StackTrace.current,
    );

    final normalizer = const ExerciseTasksAiNormalizer();
    final usedCodeCounts = <String, int>{};
    final codeItems = <Map<String, dynamic>>[];
    final chunkSources = <PlanGenerationSource>[];
    final chunks = _chunkPlan(days);
    AITraceLogger.info(
      _tag,
      traceId,
      method,
      'CHUNK_PLAN',
      'Exercise generation chunks prepared.',
      data: {'chunkCount': chunks.length, 'days': days},
      location: StackTrace.current,
    );

    for (final chunk in chunks) {
      final prompt = ExerciseTasksPrompt.generate(
        profile: profile,
        startDate: startDate,
        startDay: chunk.startDay,
        days: chunk.days,
        catalog: catalog.exercises,
        usedExerciseCodes: _usedCodes(usedCodeCounts),
      );
      final chunkResult = await _generateExerciseChunk(
        normalizer: normalizer,
        catalog: catalog,
        prompt: prompt,
        chunk: chunk,
        usedCodeCounts: usedCodeCounts,
        traceId: traceId,
      );
      _accumulateCodeCounts(chunkResult.items, 'exercise_code', usedCodeCounts);
      codeItems.addAll(chunkResult.items);
      chunkSources.add(chunkResult.source);
      AITraceLogger.info(
        _tag,
        traceId,
        method,
        'EXERCISE_CHUNK_ACCUMULATED',
        'Exercise chunk counts accumulated.',
        data: {
          'chunkStartDay': chunk.startDay,
          'itemCount': chunkResult.items.length,
          'distinctCodeCount': usedCodeCounts.length,
        },
        location: StackTrace.current,
      );
    }

    final createdAt = DateTime.now().toIso8601String();
    final exercises = normalizer.normalize(
      items: codeItems,
      catalog: catalog,
      profile: profile,
      startDate: startDate,
      days: days,
      createdAt: createdAt,
    );
    final source = PlanGenerationSource.combine(chunkSources);
    AITraceLogger.success(
      _tag,
      traceId,
      method,
      'SUCCESS',
      'Tạo bài tập hoàn tất.',
      data: {
        'codeItemCount': codeItems.length,
        'exerciseCount': exercises.length,
        'source': source.storageValue,
      },
      location: StackTrace.current,
    );
    return AIGenerationResult(value: exercises, source: source);
  }

  Future<_GeneratedPlanChunk> _generateMealChunk({
    required MealPlanAiNormalizer normalizer,
    required AiCatalogBundle catalog,
    required String prompt,
    required _AIChunk chunk,
    required Map<String, int> usedCodeCounts,
    required String traceId,
  }) async {
    const method = 'generateMealPlan';
    try {
      final items = await _runWithRetry<List<Map<String, dynamic>>>(
        traceId: traceId,
        method: method,
        label: 'LỖI TẠO THỰC ĐƠN AI',
        operation: (entry) async {
          final decoded = await _generateJsonArray(
            entry,
            prompt,
            traceId: traceId,
            method: method,
            step: 'MEAL_CHUNK day=${chunk.startDay}',
          );
          AITraceLogger.info(
            _tag,
            traceId,
            method,
            'MEAL_RESPONSE_DECODED',
            'Meal response decoded.',
            data: {
              'model': entry.name,
              'chunkStartDay': chunk.startDay,
              'itemCount': decoded.length,
            },
            location: StackTrace.current,
          );
          final validated = normalizer.validateCodeItems(
            items: decoded,
            catalog: catalog,
            startDay: chunk.startDay,
            days: chunk.days,
            usedCodeCounts: usedCodeCounts,
          );
          AITraceLogger.info(
            _tag,
            traceId,
            method,
            'MEAL_RESPONSE_VALIDATED',
            'Meal response validated.',
            data: {
              'model': entry.name,
              'source': AITraceLogger.aiGen,
              'chunkStartDay': chunk.startDay,
              'itemCount': validated.length,
            },
            location: StackTrace.current,
          );
          return validated;
        },
      );
      AITraceLogger.success(
        _tag,
        traceId,
        method,
        'MEAL_CHUNK_SUCCESS',
        'Chunk thực đơn tạo bằng AI.',
        data: {
          'source': AITraceLogger.aiGen,
          'chunkStartDay': chunk.startDay,
          'chunkDays': chunk.days,
          'itemCount': items.length,
        },
        location: StackTrace.current,
      );
      return _GeneratedPlanChunk(items: items, source: PlanGenerationSource.ai);
    } catch (error, stackTrace) {
      AITraceLogger.error(
        _tag,
        traceId,
        method,
        'MEAL_CHUNK_LOCAL_FALLBACK',
        'Chunk thực đơn chuyển sang local fallback.',
        error,
        stackTrace,
        data: {
          'source': AITraceLogger.localGen,
          'chunkStartDay': chunk.startDay,
          'chunkDays': chunk.days,
        },
        location: StackTrace.current,
      );
      final fallbackItems = normalizer.fallbackCodeItems(
        catalog: catalog,
        startDay: chunk.startDay,
        days: chunk.days,
        usedCodeCounts: usedCodeCounts,
      );
      AITraceLogger.info(
        _tag,
        traceId,
        method,
        'MEAL_LOCAL_FALLBACK_READY',
        'Meal local fallback prepared.',
        data: {
          'source': AITraceLogger.localGen,
          'chunkStartDay': chunk.startDay,
          'itemCount': fallbackItems.length,
        },
        location: StackTrace.current,
      );
      return _GeneratedPlanChunk(
        items: fallbackItems,
        source: PlanGenerationSource.localFallback,
      );
    }
  }

  Future<_GeneratedPlanChunk> _generateExerciseChunk({
    required ExerciseTasksAiNormalizer normalizer,
    required AiCatalogBundle catalog,
    required String prompt,
    required _AIChunk chunk,
    required Map<String, int> usedCodeCounts,
    required String traceId,
  }) async {
    const method = 'generateExerciseTasks';
    try {
      final items = await _runWithRetry<List<Map<String, dynamic>>>(
        traceId: traceId,
        method: method,
        label: 'LỖI TẠO BÀI TẬP AI',
        operation: (entry) async {
          final decoded = await _generateJsonArray(
            entry,
            prompt,
            traceId: traceId,
            method: method,
            step: 'EXERCISE_CHUNK day=${chunk.startDay}',
          );
          AITraceLogger.info(
            _tag,
            traceId,
            method,
            'EXERCISE_RESPONSE_DECODED',
            'Exercise response decoded.',
            data: {
              'model': entry.name,
              'chunkStartDay': chunk.startDay,
              'itemCount': decoded.length,
            },
            location: StackTrace.current,
          );
          final validated = normalizer.validateCodeItems(
            items: decoded,
            catalog: catalog,
            startDay: chunk.startDay,
            days: chunk.days,
            usedCodeCounts: usedCodeCounts,
          );
          AITraceLogger.info(
            _tag,
            traceId,
            method,
            'EXERCISE_RESPONSE_VALIDATED',
            'Exercise response validated.',
            data: {
              'model': entry.name,
              'source': AITraceLogger.aiGen,
              'chunkStartDay': chunk.startDay,
              'itemCount': validated.length,
            },
            location: StackTrace.current,
          );
          return validated;
        },
      );
      AITraceLogger.success(
        _tag,
        traceId,
        method,
        'EXERCISE_CHUNK_SUCCESS',
        'Chunk bài tập tạo bằng AI.',
        data: {
          'source': AITraceLogger.aiGen,
          'chunkStartDay': chunk.startDay,
          'chunkDays': chunk.days,
          'itemCount': items.length,
        },
        location: StackTrace.current,
      );
      return _GeneratedPlanChunk(items: items, source: PlanGenerationSource.ai);
    } catch (error, stackTrace) {
      AITraceLogger.error(
        _tag,
        traceId,
        method,
        'EXERCISE_CHUNK_LOCAL_FALLBACK',
        'Chunk bài tập chuyển sang local fallback.',
        error,
        stackTrace,
        data: {
          'source': AITraceLogger.localGen,
          'chunkStartDay': chunk.startDay,
          'chunkDays': chunk.days,
        },
        location: StackTrace.current,
      );
      final fallbackItems = normalizer.fallbackCodeItems(
        catalog: catalog,
        startDay: chunk.startDay,
        days: chunk.days,
        usedCodeCounts: usedCodeCounts,
      );
      AITraceLogger.info(
        _tag,
        traceId,
        method,
        'EXERCISE_LOCAL_FALLBACK_READY',
        'Exercise local fallback prepared.',
        data: {
          'source': AITraceLogger.localGen,
          'chunkStartDay': chunk.startDay,
          'itemCount': fallbackItems.length,
        },
        location: StackTrace.current,
      );
      return _GeneratedPlanChunk(
        items: fallbackItems,
        source: PlanGenerationSource.localFallback,
      );
    }
  }

  Future<T> _runWithRetry<T>({
    required String traceId,
    required String method,
    required String label,
    required Future<T> Function(_AIModelEntry entry) operation,
  }) async {
    var totalAttempts = 0;
    var cooldownSkips = 0;

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
          'Skipping model in transient-error cooldown.',
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
        modelAttempt <= AIRetryPolicy.maxAttemptsPerModel;
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
          final result = await operation(entry);
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
          return result;
        } catch (error, stackTrace) {
          final transient = AIRetryPolicy.isTransient(error);
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
            rethrow;
          }

          _cooldownModel(entry.name);

          final hasMoreAttempts =
              modelAttempt < AIRetryPolicy.maxAttemptsPerModel ||
              _hasAvailableModelAfter(modelIndex);
          if (!hasMoreAttempts) {
            break;
          }

          final delay = AIRetryPolicy.delayForFailureNumber(
            totalAttempts,
            random: _random,
          );
          AITraceLogger.info(
            _tag,
            traceId,
            method,
            'RETRY_DELAY',
            'Chờ trước khi thử lại.',
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
      },
      location: StackTrace.current,
    );
    throw const AIOverloadedException();
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

  Future<List<dynamic>> _generateJsonArray(
    _AIModelEntry entry,
    String prompt, {
    required String traceId,
    required String method,
    required String step,
  }) async {
    final wrappedPrompt = AIJsonPromptBuilder.buildArrayPrompt(prompt);
    final text = await _generateText(
      entry,
      wrappedPrompt,
      traceId: traceId,
      method: method,
      step: '$step.GENERATE_TEXT',
    ).timeout(const Duration(minutes: 10));

    if (text.trim().isEmpty) {
      throw Exception('Gemini trả về nội dung rỗng');
    }

    final decoded = AIJsonParser.decodeArray(text);
    AITraceLogger.info(
      _tag,
      traceId,
      method,
      '$step.DECODE_ARRAY',
      'AI response decoded as an array.',
      data: {'model': entry.name, 'itemCount': decoded.length},
      location: StackTrace.current,
    );
    return decoded;
  }

  Future<String> _generateText(
    _AIModelEntry entry,
    String prompt, {
    required String traceId,
    required String method,
    required String step,
  }) async {
    final stopwatch = Stopwatch()..start();
    AITraceLogger.info(
      _tag,
      traceId,
      method,
      '$step.REQUEST_SENT',
      'AI request sent.',
      data: {'model': entry.name, 'promptLength': prompt.length},
      location: StackTrace.current,
    );

    final textGenerator = _textGenerator;
    if (textGenerator != null) {
      final text = await textGenerator(modelName: entry.name, prompt: prompt);
      stopwatch.stop();
      AITraceLogger.info(
        _tag,
        traceId,
        method,
        '$step.RESPONSE_RECEIVED',
        'AI response received.',
        data: {
          'model': entry.name,
          'responseLength': text.length,
          'durationMs': stopwatch.elapsedMilliseconds,
        },
        location: StackTrace.current,
      );
      return text;
    }

    final client = _geminiClient;
    if (client == null) {
      throw StateError('Missing Gemini REST client for ${entry.name}');
    }

    final text = await client.generateText(
      model: entry.name,
      contents: [GeminiContent.user(prompt)],
      generationConfig: const GeminiGenerationConfig(
        candidateCount: 1,
        maxOutputTokens: 8192,
        temperature: 0.2,
        topP: 0.8,
        responseMimeType: 'application/json',
      ),
    );
    stopwatch.stop();
    AITraceLogger.info(
      _tag,
      traceId,
      method,
      '$step.RESPONSE_RECEIVED',
      'AI response received.',
      data: {
        'model': entry.name,
        'responseLength': text.length,
        'durationMs': stopwatch.elapsedMilliseconds,
      },
      location: StackTrace.current,
    );
    return text;
  }

  List<_AIChunk> _chunkPlan(int days) {
    final chunks = <_AIChunk>[];
    var startDay = 1;
    var remaining = days;
    var sizeIndex = 0;

    while (remaining > 0) {
      final preferredSize = _chunkSizes[min(sizeIndex, _chunkSizes.length - 1)];
      final chunkDays = min(preferredSize, remaining);
      chunks.add(_AIChunk(startDay: startDay, days: chunkDays));
      startDay += chunkDays;
      remaining -= chunkDays;
      sizeIndex++;
    }

    return chunks;
  }

  void _accumulateCodeCounts(
    List<Map<String, dynamic>> items,
    String codeKey,
    Map<String, int> counts,
  ) {
    for (final item in items) {
      final code = item[codeKey]?.toString().trim();
      if (code == null || code.isEmpty) continue;
      counts[code] = (counts[code] ?? 0) + 1;
    }
  }

  List<String> _usedCodes(Map<String, int> counts) {
    final codes = counts.keys.toList()..sort();
    return codes;
  }

  List<String> _modelNames() {
    return _models.map((entry) => entry.name).toList(growable: false);
  }

  Map<String, Object?> _catalogCounts(AiCatalogBundle catalog) {
    return {
      'mealCount': catalog.meals.length,
      'exerciseCount': catalog.exercises.length,
      'scheduleTaskCount': catalog.scheduleTasks.length,
    };
  }

  String _connectionCheckFailureMessage(Object? error) {
    if (error == null) {
      return 'Không thể kiểm tra kết nối AI.';
    }

    if (error is TimeoutException) {
      return 'AI không phản hồi trong thời gian giới hạn.';
    }

    if (error is FormatException) {
      return 'AI có phản hồi nhưng dữ liệu không đúng định dạng.';
    }

    if (AIOverloadedException.matches(error)) {
      return AIOverloadedException.userMessage;
    }

    if (AIAuthenticationException.matches(error)) {
      return AIAuthenticationException.userMessage;
    }

    final text = error.toString();
    if (text.contains('GEMINI_API_KEY') ||
        text.contains('Missing Gemini REST client')) {
      return 'Thiếu GEMINI_API_KEY hoặc key đang rỗng.';
    }

    return 'Không thể kết nối AI. Kiểm tra GEMINI_API_KEY, model hoặc mạng.';
  }

  static String? _envWithLegacy(String key, String legacyKey) {
    return AppEnv.maybeStringWithLegacy(key, legacyKey);
  }

  static String? _cleanEnv(String? value) {
    final cleaned = value?.trim();
    if (cleaned == null || cleaned.isEmpty) {
      return null;
    }
    return cleaned;
  }
}

class AIModelCandidates {
  static const defaultPrimaryModel = 'gemini-3.1-flash-lite';
  static const defaultFallbackModels = [
    'gemini-3.5-flash',
    'gemini-2.5-flash-lite',
    'gemini-2.5-flash',
  ];

  const AIModelCandidates._();

  static List<String> resolve({
    required String? primaryModel,
    required String? fallbackModelsCsv,
    String? overflowModelsCsv,
  }) {
    final fallbackModels = _parseCsv(fallbackModelsCsv);
    final overflowModels = _parseCsv(overflowModelsCsv);
    final rawModels = <String>[
      _clean(primaryModel) ?? defaultPrimaryModel,
      ...(fallbackModels.isEmpty ? defaultFallbackModels : fallbackModels),
      ...overflowModels,
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

class AIRetryPolicy {
  static const maxAttemptsPerModel = 1;
  static const maxDelay = Duration(milliseconds: 3750);
  static const modelCooldown = Duration(minutes: 3);

  const AIRetryPolicy._();

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

class _AIModelEntry {
  final String name;

  const _AIModelEntry({required this.name});
}

class _GeneratedPlanChunk {
  final List<Map<String, dynamic>> items;
  final PlanGenerationSource source;

  const _GeneratedPlanChunk({required this.items, required this.source});
}

class _AIChunk {
  final int startDay;
  final int days;

  const _AIChunk({required this.startDay, required this.days});

  Map<String, int> toMap() {
    return {'startDay': startDay, 'days': days};
  }
}
