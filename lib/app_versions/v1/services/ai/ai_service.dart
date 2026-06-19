import 'dart:async';
import 'dart:math';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:nano_app/core/interfaces/health_data_interface.dart';
import 'package:nano_app/core/storage/localdb/datasources/ai_catalog_local_datasource.dart';
import 'package:nano_app/core/storage/localdb/models/ai_catalog_models.dart';
import 'package:nano_app/app_versions/v1/features/daily_health_tracking/domain/entities/daily_health_profile_entity.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/data/models/exercise_task_model.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/data/models/exercise_tasks_ai_normalizer.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/data/models/meal_plan_ai_normalizer.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/data/models/meal_plan_model.dart';

import 'ai_exceptions.dart';
import 'ai_json_parser.dart';
import 'ai_json_prompt_builder.dart';
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

    final apiKey =
        _cleanEnv(apiKeyOverride) ??
        (_textGenerator == null
            ? _cleanEnv(dotenv.env['GEMINI_API_KEY'])
            : null);
    if (_textGenerator == null && (apiKey == null || apiKey.isEmpty)) {
      throw Exception('Không tìm thấy GEMINI_API_KEY');
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
              ? _cleanEnv(dotenv.env['GEMINI_PLAN_OVERFLOW_MODELS'])
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

    final generationConfig = GenerationConfig(
      candidateCount: 1,
      maxOutputTokens: 8192,
      temperature: 0.2,
      topP: 0.8,
      responseMimeType: 'application/json',
    );

    _models = [
      for (final modelName in resolvedModelNames)
        _AIModelEntry(
          name: modelName,
          model: _textGenerator == null
              ? GenerativeModel(
                  model: modelName,
                  apiKey: apiKey!,
                  generationConfig: generationConfig,
                )
              : null,
        ),
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
        AITraceLogger.payload(
          _tag,
          traceId,
          method,
          'CONNECTION_CHECK_DECODED_JSON',
          decoded,
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
          'AI connection check failed model=${entry.name} '
              'reason=${_connectionCheckFailureMessage(error)}',
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
      data: {'lastModelName': lastModelName},
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
    final traceId = AITraceLogger.nextTraceId('meal-plan');
    const method = 'generateMealPlan';
    AITraceLogger.start(
      _tag,
      traceId,
      method,
      data: {
        'userId': userId,
        'startDate': startDate.toIso8601String(),
        'days': days,
        'models': _modelNames(),
        'healthData': _healthDataToMap(healthData),
      },
      location: StackTrace.current,
    );

    final catalog = await _catalogLoader();
    AITraceLogger.payload(
      _tag,
      traceId,
      method,
      'CATALOG_LOADED',
      _catalogSummary(catalog),
      location: StackTrace.current,
    );

    final normalizer = const MealPlanAiNormalizer();
    final usedCodeCounts = <String, int>{};
    final codeItems = <Map<String, dynamic>>[];
    final chunks = _chunkPlan(days);
    AITraceLogger.payload(
      _tag,
      traceId,
      method,
      'CHUNK_PLAN',
      chunks.map((chunk) => chunk.toMap()).toList(growable: false),
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
      AITraceLogger.payload(
        _tag,
        traceId,
        method,
        'MEAL_CHUNK_PROMPT_ORIGINAL day=${chunk.startDay}',
        prompt,
        location: StackTrace.current,
      );

      final chunkItems = await _generateMealChunk(
        normalizer: normalizer,
        catalog: catalog,
        prompt: prompt,
        chunk: chunk,
        usedCodeCounts: usedCodeCounts,
        traceId: traceId,
      );
      _accumulateCodeCounts(chunkItems, 'meal_code', usedCodeCounts);
      codeItems.addAll(chunkItems);
      AITraceLogger.payload(
        _tag,
        traceId,
        method,
        'MEAL_USED_CODE_COUNTS_AFTER_CHUNK day=${chunk.startDay}',
        usedCodeCounts,
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
    AITraceLogger.success(
      _tag,
      traceId,
      method,
      'SUCCESS',
      'Tạo thực đơn hoàn tất.',
      data: {
        'totalCodeItems': codeItems.length,
        'totalMeals': meals.length,
        'createdAt': createdAt,
      },
      location: StackTrace.current,
    );
    AITraceLogger.payload(
      _tag,
      traceId,
      method,
      'NORMALIZED_MEAL_PLAN_OUTPUT',
      _mealPlansToMaps(meals),
      location: StackTrace.current,
    );
    return meals;
  }

  Future<List<ExerciseTaskModel>> generateExerciseTasks({
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
      data: {
        'startDate': startDate.toIso8601String(),
        'days': days,
        'models': _modelNames(),
        'profile': _dailyHealthProfileToMap(profile),
      },
      location: StackTrace.current,
    );

    final catalog = await _catalogLoader();
    AITraceLogger.payload(
      _tag,
      traceId,
      method,
      'CATALOG_LOADED',
      _catalogSummary(catalog),
      location: StackTrace.current,
    );

    final normalizer = const ExerciseTasksAiNormalizer();
    final usedCodeCounts = <String, int>{};
    final codeItems = <Map<String, dynamic>>[];
    final chunks = _chunkPlan(days);
    AITraceLogger.payload(
      _tag,
      traceId,
      method,
      'CHUNK_PLAN',
      chunks.map((chunk) => chunk.toMap()).toList(growable: false),
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
      AITraceLogger.payload(
        _tag,
        traceId,
        method,
        'EXERCISE_CHUNK_PROMPT_ORIGINAL day=${chunk.startDay}',
        prompt,
        location: StackTrace.current,
      );

      final chunkItems = await _generateExerciseChunk(
        normalizer: normalizer,
        catalog: catalog,
        prompt: prompt,
        chunk: chunk,
        usedCodeCounts: usedCodeCounts,
        traceId: traceId,
      );
      _accumulateCodeCounts(chunkItems, 'exercise_code', usedCodeCounts);
      codeItems.addAll(chunkItems);
      AITraceLogger.payload(
        _tag,
        traceId,
        method,
        'EXERCISE_USED_CODE_COUNTS_AFTER_CHUNK day=${chunk.startDay}',
        usedCodeCounts,
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
    AITraceLogger.success(
      _tag,
      traceId,
      method,
      'SUCCESS',
      'Tạo bài tập hoàn tất.',
      data: {
        'totalCodeItems': codeItems.length,
        'totalExercises': exercises.length,
        'createdAt': createdAt,
      },
      location: StackTrace.current,
    );
    AITraceLogger.payload(
      _tag,
      traceId,
      method,
      'NORMALIZED_EXERCISE_OUTPUT',
      _exerciseTasksToMaps(exercises),
      location: StackTrace.current,
    );
    return exercises;
  }

  Future<List<Map<String, dynamic>>> _generateMealChunk({
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
          AITraceLogger.payload(
            _tag,
            traceId,
            method,
            'MEAL_DECODED_JSON day=${chunk.startDay} model=${entry.name}',
            decoded,
            location: StackTrace.current,
          );
          final validated = normalizer.validateCodeItems(
            items: decoded,
            catalog: catalog,
            startDay: chunk.startDay,
            days: chunk.days,
            usedCodeCounts: usedCodeCounts,
          );
          AITraceLogger.payload(
            _tag,
            traceId,
            method,
            'MEAL_VALIDATED_CODE_ITEMS day=${chunk.startDay} model=${entry.name}',
            validated,
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
          'chunk': chunk.toMap(),
          'itemCount': items.length,
        },
        location: StackTrace.current,
      );
      return items;
    } catch (error, stackTrace) {
      AITraceLogger.error(
        _tag,
        traceId,
        method,
        'MEAL_CHUNK_LOCAL_FALLBACK',
        'Chunk thực đơn chuyển sang local fallback.',
        error,
        stackTrace,
        data: {'source': AITraceLogger.localGen, 'chunk': chunk.toMap()},
        location: StackTrace.current,
      );
      final fallbackItems = normalizer.fallbackCodeItems(
        catalog: catalog,
        startDay: chunk.startDay,
        days: chunk.days,
        usedCodeCounts: usedCodeCounts,
      );
      AITraceLogger.payload(
        _tag,
        traceId,
        method,
        'MEAL_LOCAL_FALLBACK_ITEMS day=${chunk.startDay}',
        fallbackItems,
        location: StackTrace.current,
      );
      return fallbackItems;
    }
  }

  Future<List<Map<String, dynamic>>> _generateExerciseChunk({
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
          AITraceLogger.payload(
            _tag,
            traceId,
            method,
            'EXERCISE_DECODED_JSON day=${chunk.startDay} model=${entry.name}',
            decoded,
            location: StackTrace.current,
          );
          final validated = normalizer.validateCodeItems(
            items: decoded,
            catalog: catalog,
            startDay: chunk.startDay,
            days: chunk.days,
            usedCodeCounts: usedCodeCounts,
          );
          AITraceLogger.payload(
            _tag,
            traceId,
            method,
            'EXERCISE_VALIDATED_CODE_ITEMS day=${chunk.startDay} model=${entry.name}',
            validated,
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
          'chunk': chunk.toMap(),
          'itemCount': items.length,
        },
        location: StackTrace.current,
      );
      return items;
    } catch (error, stackTrace) {
      AITraceLogger.error(
        _tag,
        traceId,
        method,
        'EXERCISE_CHUNK_LOCAL_FALLBACK',
        'Chunk bài tập chuyển sang local fallback.',
        error,
        stackTrace,
        data: {'source': AITraceLogger.localGen, 'chunk': chunk.toMap()},
        location: StackTrace.current,
      );
      final fallbackItems = normalizer.fallbackCodeItems(
        catalog: catalog,
        startDay: chunk.startDay,
        days: chunk.days,
        usedCodeCounts: usedCodeCounts,
      );
      AITraceLogger.payload(
        _tag,
        traceId,
        method,
        'EXERCISE_LOCAL_FALLBACK_ITEMS day=${chunk.startDay}',
        fallbackItems,
        location: StackTrace.current,
      );
      return fallbackItems;
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
            'cooldownUntil': cooldownUntil.toIso8601String(),
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
    AITraceLogger.payload(
      _tag,
      traceId,
      method,
      '$step.DECODE_ARRAY',
      decoded,
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
    AITraceLogger.payload(
      _tag,
      traceId,
      method,
      '$step.PROMPT_SENT model=${entry.name}',
      prompt,
      location: StackTrace.current,
    );

    final textGenerator = _textGenerator;
    if (textGenerator != null) {
      final text = await textGenerator(modelName: entry.name, prompt: prompt);
      AITraceLogger.payload(
        _tag,
        traceId,
        method,
        '$step.RAW_RESPONSE model=${entry.name}',
        text,
        location: StackTrace.current,
      );
      return text;
    }

    final model = entry.model;
    if (model == null) {
      throw StateError('Missing Gemini model for ${entry.name}');
    }

    final response = await model.generateContent([Content.text(prompt)]);
    final text = response.text;
    if (text == null) {
      throw Exception('Gemini trả về nội dung rỗng');
    }
    AITraceLogger.payload(
      _tag,
      traceId,
      method,
      '$step.RAW_RESPONSE model=${entry.name}',
      text,
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

  Map<String, Object?> _healthDataToMap(HealthDataInterface healthData) {
    return {
      'fullName': healthData.fullName,
      'gender': healthData.gender,
      'birthYear': healthData.birthYear,
      'heightCm': healthData.heightCm,
      'weightKg': healthData.weightKg,
      'bmi': healthData.bmi,
      'goals': healthData.goals,
      'conditions': healthData.conditions,
      'habits': healthData.habits,
      'sleepQuality': healthData.sleepQuality,
      'activityLevel': healthData.activityLevel,
      'waterPerDay': healthData.waterPerDay,
      'allergyName': healthData.allergyName,
      'allergyNote': healthData.allergyNote,
      'treatmentName': healthData.treatmentName,
      'medicationName': healthData.medicationName,
      'treatmentNote': healthData.treatmentNote,
      'concernText': healthData.concernText,
    };
  }

  Map<String, Object?> _dailyHealthProfileToMap(
    DailyHealthProfileEntity profile,
  ) {
    return {
      'userId': profile.userId,
      'fullName': profile.fullName,
      'goals': profile.goals,
      'conditions': profile.conditions,
      'habits': profile.habits,
      'sleepQuality': profile.sleepQuality,
      'activityLevel': profile.activityLevel,
      'waterPerDay': profile.waterPerDay,
    };
  }

  Map<String, Object?> _catalogSummary(AiCatalogBundle catalog) {
    return {
      'mealCount': catalog.meals.length,
      'mealCodes': catalog.meals.map((item) => item.code).toList(),
      'exerciseCount': catalog.exercises.length,
      'exerciseCodes': catalog.exercises.map((item) => item.code).toList(),
      'scheduleTaskCount': catalog.scheduleTasks.length,
      'scheduleTaskCodes': catalog.scheduleTasks
          .map((item) => item.code)
          .toList(),
    };
  }

  List<Map<String, Object?>> _mealPlansToMaps(List<MealPlanModel> meals) {
    return meals.map((meal) => meal.toMap()).toList(growable: false);
  }

  List<Map<String, Object?>> _exerciseTasksToMaps(
    List<ExerciseTaskModel> exercises,
  ) {
    return exercises
        .map(
          (exercise) => {
            'id': exercise.id,
            'userId': exercise.userId,
            'scheduleDate': exercise.scheduleDate,
            'startTime': exercise.startTime,
            'endTime': exercise.endTime,
            'title': exercise.title,
            'description': exercise.description,
            'targetValue': exercise.targetValue,
            'unit': exercise.unit,
            'encouragement': exercise.encouragement,
            'createdAt': exercise.createdAt,
            'updatedAt': exercise.updatedAt,
          },
        )
        .toList(growable: false);
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

    final text = error.toString();
    if (text.contains('GEMINI_API_KEY')) {
      return 'Thiếu GEMINI_API_KEY hoặc key đang rỗng.';
    }

    return 'Không thể kết nối AI. Kiểm tra GEMINI_API_KEY, model hoặc mạng.';
  }

  static String? _envWithLegacy(String key, String legacyKey) {
    final value = dotenv.env.containsKey(key)
        ? dotenv.env[key]
        : dotenv.env[legacyKey];

    return _cleanEnv(value);
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
  final GenerativeModel? model;

  const _AIModelEntry({required this.name, required this.model});
}

class _AIChunk {
  final int startDay;
  final int days;

  const _AIChunk({required this.startDay, required this.days});

  Map<String, int> toMap() {
    return {'startDay': startDay, 'days': days};
  }
}
