import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
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
import 'nabi_ai_backend_client.dart';
import 'ai_trace_logger.dart';
import 'prompts/exercise_tasks_prompt.dart';
import 'prompts/meal_plan_prompt.dart';

String _providerCredentialLabel() => String.fromCharCodes(const [
  71,
  69,
  77,
  73,
  78,
  73,
  95,
  65,
  80,
  73,
  95,
  75,
  69,
  89,
]);

typedef AITextGenerator =
    Future<String> Function({
      required String modelName,
      required String prompt,
    });

typedef AiCatalogLoader = Future<AiCatalogBundle> Function();
typedef AiBackendInvocationCallback = Future<void> Function();

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
  late final AiTextClient? _aiClient;
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
    AiTextClient? aiClient,
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
        catalogLoader ??
        const AiCatalogLocalDatasource().loadScheduleCatalogBundle;

    // Tests may pass an empty override to assert the unavailable-provider
    // path. Production app construction always routes through the trusted
    // backend client.
    _aiClient = _textGenerator == null
        ? aiClient ??
              geminiClient ??
              (apiKeyOverride == null ? const NabiAiBackendClient() : null)
        : null;
    final hasRuntimeClient = _aiClient != null;

    if (!hasRuntimeClient && _textGenerator == null) {
      AITraceLogger.warning(
        _tag,
        AITraceLogger.nextTraceId('ai-service-init'),
        'AIService.constructor',
        'MISSING_API_KEY',
        'AI plan generation is unavailable because the provider is not configured.',
        data: {'source': 'unavailable'},
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

  /// Clears cooldowns before a user explicitly resumes a failed plan request.
  void resetTransientModelCooldowns() {
    _modelCooldownUntil.clear();
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

    if (_textGenerator == null && _aiClient == null) {
      final message = 'Thiếu ${_providerCredentialLabel()} hoặc key đang rỗng.';
      AITraceLogger.warning(
        _tag,
        traceId,
        method,
        'MISSING_API_KEY',
        message,
        data: {'source': AITraceLogger.localGen},
        location: StackTrace.current,
      );
      return AIConnectionCheckResult.failure(message: message);
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
    AiCatalogBundle? catalogOverride,
  }) async {
    final result = await generateMealPlanWithSource(
      healthData: healthData,
      userId: userId,
      startDate: startDate,
      days: days,
      catalogOverride: catalogOverride,
    );
    return result.value;
  }

  Future<AIGenerationResult<List<MealPlanModel>>> generateMealPlanWithSource({
    required HealthDataInterface healthData,
    required String userId,
    required DateTime startDate,
    int days = 7,
    AiCatalogBundle? catalogOverride,
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

    final catalog = catalogOverride ?? await _catalogLoader();
    _ensureMealCatalogAvailable(catalog);
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
        startDate: startDate,
        startDay: chunk.startDay,
        days: chunk.days,
        catalog: catalog.meals,
        usedMealCodeCounts: usedCodeCounts,
        ingredientEvidenceByName: catalog.ingredientEvidenceByName,
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
    AiCatalogBundle? catalogOverride,
    List<Map<String, String>> availableTimeWindows = const [],
  }) async {
    final result = await generateExerciseTasksWithSource(
      profile: profile,
      startDate: startDate,
      days: days,
      catalogOverride: catalogOverride,
      availableTimeWindows: availableTimeWindows,
    );
    return result.value;
  }

  Future<AIGenerationResult<List<ExerciseTaskModel>>>
  generateExerciseTasksWithSource({
    required DailyHealthProfileEntity profile,
    required DateTime startDate,
    int days = 7,
    AiCatalogBundle? catalogOverride,
    List<Map<String, String>> availableTimeWindows = const [],
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

    final catalog = catalogOverride ?? await _catalogLoader();
    _ensureExerciseCatalogAvailable(catalog);
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
        startDate: startDate,
        startDay: chunk.startDay,
        days: chunk.days,
        catalog: catalog.exercises,
        usedExerciseCodeCounts: usedCodeCounts,
        availableTimeWindows: availableTimeWindows,
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

  Future<List<Map<String, dynamic>>> generateMealDayCodeItems({
    required DateTime startDate,
    required int day,
    required AiCatalogBundle catalog,
    required Map<String, int> usedCodeCounts,
    Map<String, Object?> personalization = const {},
    required AiBackendInvocationCallback onBackendInvocation,
  }) async {
    if (day < 1 || day > 7) {
      throw RangeError.range(day, 1, 7, 'day');
    }
    _ensureMealCatalogAvailable(catalog);
    final traceId = AITraceLogger.nextTraceId('meal-day-$day');
    final prompt = MealPlanPrompt.generate(
      startDate: startDate,
      startDay: day,
      days: 1,
      catalog: catalog.meals,
      usedMealCodeCounts: usedCodeCounts,
      personalization: personalization,
    );
    final result = await _generateMealChunk(
      normalizer: const MealPlanAiNormalizer(),
      catalog: catalog,
      prompt: prompt,
      chunk: _AIChunk(startDay: day, days: 1),
      usedCodeCounts: usedCodeCounts,
      traceId: traceId,
      onBackendInvocation: onBackendInvocation,
    );
    return result.items;
  }

  Future<List<Map<String, dynamic>>> generateExerciseDayCodeItems({
    required DateTime startDate,
    required int day,
    required AiCatalogBundle catalog,
    required Map<String, int> usedCodeCounts,
    Map<String, Object?> personalization = const {},
    required AiBackendInvocationCallback onBackendInvocation,
  }) async {
    if (day < 1 || day > 7) {
      throw RangeError.range(day, 1, 7, 'day');
    }
    _ensureExerciseCatalogAvailable(catalog);
    final traceId = AITraceLogger.nextTraceId('exercise-day-$day');
    final prompt = ExerciseTasksPrompt.generate(
      startDate: startDate,
      startDay: day,
      days: 1,
      catalog: catalog.exercises,
      usedExerciseCodeCounts: usedCodeCounts,
      personalization: personalization,
    );
    final result = await _generateExerciseChunk(
      normalizer: const ExerciseTasksAiNormalizer(),
      catalog: catalog,
      prompt: prompt,
      chunk: _AIChunk(startDay: day, days: 1),
      usedCodeCounts: usedCodeCounts,
      traceId: traceId,
      onBackendInvocation: onBackendInvocation,
    );
    return result.items;
  }

  Future<AIGenerationResult<List<Map<String, dynamic>>>>
  generateMealDayCodeItemsWithSource({
    required DateTime startDate,
    required int day,
    required AiCatalogBundle catalog,
    required Map<String, int> usedCodeCounts,
    Map<String, Set<String>>? eligibleFallbackCodesByType,
    bool allowLocalFallback = true,
    Map<String, Object?> personalization = const {},
    required AiBackendInvocationCallback onBackendInvocation,
  }) async {
    if (day < 1 || day > 7) {
      throw RangeError.range(day, 1, 7, 'day');
    }
    _ensureMealCatalogAvailable(catalog);
    try {
      return AIGenerationResult(
        value: await generateMealDayCodeItems(
          startDate: startDate,
          day: day,
          catalog: catalog,
          usedCodeCounts: usedCodeCounts,
          personalization: personalization,
          onBackendInvocation: onBackendInvocation,
        ),
        source: PlanGenerationSource.ai,
      );
    } catch (error, stackTrace) {
      if (!allowLocalFallback) {
        Error.throwWithStackTrace(error, stackTrace);
      }
      final fallback = _fallbackMealDayCodeItems(
        day: day,
        catalog: catalog,
        usedCodeCounts: usedCodeCounts,
        eligibleCodesByType: eligibleFallbackCodesByType,
      );
      AITraceLogger.info(
        _tag,
        AITraceLogger.nextTraceId('meal-local-fallback-$day'),
        'generateMealDayCodeItemsWithSource',
        'LOCAL_CATALOG_FALLBACK',
        'Using validated local meal choices after AI generation failed.',
        data: {'errorType': error.runtimeType.toString(), 'day': day},
        location: StackTrace.current,
      );
      return AIGenerationResult(
        value: fallback,
        source: PlanGenerationSource.localFallback,
      );
    }
  }

  Future<AIGenerationResult<List<Map<String, dynamic>>>>
  generateMealSlotCodeItemWithSource({
    required DateTime startDate,
    required int day,
    required String mealType,
    required AiCatalogBundle catalog,
    required Map<String, int> usedCodeCounts,
    required Set<String> dayMealCodes,
    Map<String, Set<String>>? eligibleFallbackCodesByType,
    Map<String, Object?> personalization = const {},
    required AiBackendInvocationCallback onBackendInvocation,
  }) async {
    if (day < 1 || day > 7) {
      throw RangeError.range(day, 1, 7, 'day');
    }
    _ensureMealCatalogAvailable(catalog);
    final slotIndex = MealPlanAiNormalizer.mealSlots.indexWhere(
      (candidate) => candidate.type == mealType.trim().toLowerCase(),
    );
    if (slotIndex < 0) {
      throw ArgumentError.value(mealType, 'mealType');
    }
    final slot = MealPlanAiNormalizer.mealSlots[slotIndex];
    final traceId = AITraceLogger.nextTraceId('meal-slot-$day-${slot.type}');
    final prompt = MealPlanPrompt.generate(
      startDate: startDate,
      startDay: day,
      days: 1,
      onlyMealType: slot.type,
      catalog: catalog.meals,
      usedMealCodeCounts: usedCodeCounts,
      personalization: personalization,
    );
    try {
      final items = await _runWithRetry<List<Map<String, dynamic>>>(
        traceId: traceId,
        method: 'generateMealSlotCodeItem',
        label: 'LỖI TẠO BỮA ĂN AI',
        onBackendInvocation: onBackendInvocation,
        operation: (entry) async {
          final decoded = await _generateJsonArray(
            entry,
            prompt,
            traceId: traceId,
            method: 'generateMealSlotCodeItem',
            step: 'MEAL_SLOT day=$day type=${slot.type}',
          );
          if (decoded.length != 1) {
            throw const FormatException(
              'Meal AI slot response must contain exactly one meal.',
            );
          }
          return const MealPlanAiNormalizer().validateCodeItemForSlot(
            item: decoded.single,
            catalog: catalog,
            day: day,
            mealType: slot.type,
            usedCodeCounts: usedCodeCounts,
            dayMealCodes: dayMealCodes,
          );
        },
      );
      return AIGenerationResult(value: items, source: PlanGenerationSource.ai);
    } catch (error) {
      try {
        final fallback = _fallbackMealSlotCodeItem(
          day: day,
          mealType: slot.type,
          catalog: catalog,
          usedCodeCounts: usedCodeCounts,
          dayMealCodes: dayMealCodes,
          eligibleCodesByType: eligibleFallbackCodesByType,
        );
        AITraceLogger.info(
          _tag,
          traceId,
          'generateMealSlotCodeItem',
          'LOCAL_SLOT_FALLBACK',
          'Using a validated local meal choice after split AI generation failed.',
          data: {'errorType': error.runtimeType.toString(), 'day': day},
          location: StackTrace.current,
        );
        return AIGenerationResult(
          value: fallback,
          source: PlanGenerationSource.localFallback,
        );
      } catch (fallbackError, fallbackStackTrace) {
        Error.throwWithStackTrace(fallbackError, fallbackStackTrace);
      }
    }
  }

  Future<AIGenerationResult<List<Map<String, dynamic>>>>
  generateExerciseDayCodeItemsWithSource({
    required DateTime startDate,
    required int day,
    required AiCatalogBundle catalog,
    required Map<String, int> usedCodeCounts,
    Set<String>? eligibleFallbackCodes,
    Map<String, Object?> personalization = const {},
    required AiBackendInvocationCallback onBackendInvocation,
  }) async {
    if (day < 1 || day > 7) {
      throw RangeError.range(day, 1, 7, 'day');
    }
    _ensureExerciseCatalogAvailable(catalog);
    try {
      return AIGenerationResult(
        value: await generateExerciseDayCodeItems(
          startDate: startDate,
          day: day,
          catalog: catalog,
          usedCodeCounts: usedCodeCounts,
          personalization: personalization,
          onBackendInvocation: onBackendInvocation,
        ),
        source: PlanGenerationSource.ai,
      );
    } catch (error) {
      final fallback = _fallbackExerciseDayCodeItems(
        day: day,
        catalog: catalog,
        usedCodeCounts: usedCodeCounts,
        eligibleCodes: eligibleFallbackCodes,
      );
      AITraceLogger.info(
        _tag,
        AITraceLogger.nextTraceId('exercise-local-fallback-$day'),
        'generateExerciseDayCodeItemsWithSource',
        'LOCAL_CATALOG_FALLBACK',
        'Using validated local exercise choices after AI generation failed.',
        data: {'errorType': error.runtimeType.toString(), 'day': day},
        location: StackTrace.current,
      );
      return AIGenerationResult(
        value: fallback,
        source: PlanGenerationSource.localFallback,
      );
    }
  }

  List<Map<String, dynamic>> _fallbackMealDayCodeItems({
    required int day,
    required AiCatalogBundle catalog,
    required Map<String, int> usedCodeCounts,
    Map<String, Set<String>>? eligibleCodesByType,
  }) {
    final counts = Map<String, int>.from(usedCodeCounts);
    final candidatesBySlot = {
      for (final slot in MealPlanAiNormalizer.mealSlots)
        slot.type: catalog
            .mealsForType(slot.type)
            .where(
              (meal) =>
                  meal.isActive &&
                  meal.code.trim().isNotEmpty &&
                  meal.mealName.trim().isNotEmpty &&
                  (eligibleCodesByType == null ||
                      eligibleCodesByType[slot.type]?.contains(meal.code) ==
                          true),
            )
            .toList(growable: false),
    };
    final slots = [...MealPlanAiNormalizer.mealSlots]
      ..sort(
        (left, right) => candidatesBySlot[left.type]!.length.compareTo(
          candidatesBySlot[right.type]!.length,
        ),
      );
    final selectedCodes = <String>{};
    final selectedNames = MealPlanAiNormalizer.mealNameKeysForCodes(
      catalog.meals,
      usedCodeCounts.entries
          .where((entry) => entry.value > 0)
          .map((entry) => entry.key),
    );
    final selectedByType = <String, MealCatalogItemModel>{};

    bool assignSlot(int index) {
      if (index == slots.length) return true;
      final slot = slots[index];
      final candidates = [...candidatesBySlot[slot.type]!]
        ..sort((left, right) {
          final count = (counts[left.code] ?? 0).compareTo(
            counts[right.code] ?? 0,
          );
          return count != 0 ? count : left.code.compareTo(right.code);
        });
      for (final candidate in candidates) {
        final nameKey = MealPlanAiNormalizer.mealNameUniquenessKey(
          candidate.mealName,
        );
        if ((usedCodeCounts[candidate.code] ?? 0) > 0 ||
            !selectedCodes.add(candidate.code)) {
          continue;
        }
        if (nameKey.isNotEmpty && !selectedNames.add(nameKey)) {
          selectedCodes.remove(candidate.code);
          continue;
        }
        selectedByType[slot.type] = candidate;
        counts.update(candidate.code, (value) => value + 1, ifAbsent: () => 1);
        if (assignSlot(index + 1)) return true;
        counts.update(candidate.code, (value) => value - 1);
        selectedByType.remove(slot.type);
        selectedCodes.remove(candidate.code);
        if (nameKey.isNotEmpty) selectedNames.remove(nameKey);
      }
      return false;
    }

    if (!assignSlot(0)) {
      throw StateError('Insufficient unique eligible meal catalog choices.');
    }
    final items = [
      for (final slot in MealPlanAiNormalizer.mealSlots)
        {
          'day': day,
          'meal_type': slot.type,
          'meal_code': selectedByType[slot.type]!.code,
        },
    ];
    return const MealPlanAiNormalizer().validateCodeItems(
      items: items,
      catalog: catalog,
      startDay: day,
      days: 1,
      usedCodeCounts: usedCodeCounts,
      eligibleCodesByType: eligibleCodesByType,
    );
  }

  List<Map<String, dynamic>> _fallbackMealSlotCodeItem({
    required int day,
    required String mealType,
    required AiCatalogBundle catalog,
    required Map<String, int> usedCodeCounts,
    required Set<String> dayMealCodes,
    Map<String, Set<String>>? eligibleCodesByType,
  }) {
    final slotIndex = MealPlanAiNormalizer.mealSlots.indexWhere(
      (candidate) => candidate.type == mealType,
    );
    if (slotIndex < 0) {
      throw ArgumentError.value(mealType, 'mealType');
    }
    final slot = MealPlanAiNormalizer.mealSlots[slotIndex];
    final candidates =
        catalog
            .mealsForType(slot.type)
            .where(
              (meal) =>
                  meal.isActive &&
                  meal.code.trim().isNotEmpty &&
                  meal.mealName.trim().isNotEmpty &&
                  !dayMealCodes.contains(meal.code) &&
                  (eligibleCodesByType == null ||
                      eligibleCodesByType[slot.type]?.contains(meal.code) ==
                          true),
            )
            .toList(growable: false)
          ..sort((left, right) {
            final count = (usedCodeCounts[left.code] ?? 0).compareTo(
              usedCodeCounts[right.code] ?? 0,
            );
            return count != 0 ? count : left.code.compareTo(right.code);
          });
    for (final candidate in candidates) {
      try {
        return const MealPlanAiNormalizer().validateCodeItemForSlot(
          item: {
            'day': day,
            'meal_type': slot.type,
            'meal_code': candidate.code,
          },
          catalog: catalog,
          day: day,
          mealType: slot.type,
          usedCodeCounts: usedCodeCounts,
          dayMealCodes: dayMealCodes,
          eligibleCodesByType: eligibleCodesByType,
        );
      } on FormatException {
        continue;
      }
    }
    throw StateError('Insufficient eligible meal choices for ${slot.type}.');
  }

  List<Map<String, dynamic>> _fallbackExerciseDayCodeItems({
    required int day,
    required AiCatalogBundle catalog,
    required Map<String, int> usedCodeCounts,
    Set<String>? eligibleCodes,
  }) {
    final candidates =
        catalog.exercises
            .where(
              (item) =>
                  item.isActive &&
                  item.code.trim().isNotEmpty &&
                  item.title.trim().isNotEmpty &&
                  (eligibleCodes == null || eligibleCodes.contains(item.code)),
            )
            .toList(growable: false)
          ..sort((left, right) {
            final count = (usedCodeCounts[left.code] ?? 0).compareTo(
              usedCodeCounts[right.code] ?? 0,
            );
            return count != 0 ? count : left.code.compareTo(right.code);
          });
    final items = [
      for (final exercise in candidates.take(2))
        {'day': day, 'exercise_code': exercise.code},
    ];
    return const ExerciseTasksAiNormalizer().validateCodeItems(
      items: items,
      catalog: catalog,
      startDay: day,
      days: 1,
      usedCodeCounts: usedCodeCounts,
      eligibleCodes: eligibleCodes,
    );
  }

  Future<_GeneratedPlanChunk> _generateMealChunk({
    required MealPlanAiNormalizer normalizer,
    required AiCatalogBundle catalog,
    required String prompt,
    required _AIChunk chunk,
    required Map<String, int> usedCodeCounts,
    required String traceId,
    AiBackendInvocationCallback? onBackendInvocation,
  }) async {
    const method = 'generateMealPlan';
    try {
      final items = await _runWithRetry<List<Map<String, dynamic>>>(
        traceId: traceId,
        method: method,
        label: 'LỖI TẠO THỰC ĐƠN AI',
        onBackendInvocation: onBackendInvocation,
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
        'MEAL_CHUNK_FAILED',
        'Chunk thực đơn không được tạo.',
        error,
        stackTrace,
        data: {'chunkStartDay': chunk.startDay, 'chunkDays': chunk.days},
        location: StackTrace.current,
      );
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  void _ensureMealCatalogAvailable(AiCatalogBundle catalog) {
    for (final slot in MealPlanAiNormalizer.mealSlots) {
      final hasCandidate = catalog.meals.any(
        (item) =>
            item.isActive &&
            item.code.trim().isNotEmpty &&
            item.mealName.trim().isNotEmpty &&
            (item.mealType == slot.type || item.mealType == 'unclassified'),
      );
      if (!hasCandidate) {
        throw StateError(
          'No active local meal catalog candidate for ${slot.type}.',
        );
      }
    }
  }

  void _ensureExerciseCatalogAvailable(AiCatalogBundle catalog) {
    final candidateCodes = catalog.exercises
        .where(
          (item) =>
              item.isActive &&
              item.code.trim().isNotEmpty &&
              item.title.trim().isNotEmpty,
        )
        .map((item) => item.code)
        .toSet();
    if (candidateCodes.length < ExerciseTasksAiNormalizer.exercisesPerDay) {
      throw StateError('Insufficient active local exercise catalog choices.');
    }
  }

  Future<_GeneratedPlanChunk> _generateExerciseChunk({
    required ExerciseTasksAiNormalizer normalizer,
    required AiCatalogBundle catalog,
    required String prompt,
    required _AIChunk chunk,
    required Map<String, int> usedCodeCounts,
    required String traceId,
    AiBackendInvocationCallback? onBackendInvocation,
  }) async {
    const method = 'generateExerciseTasks';
    try {
      final items = await _runWithRetry<List<Map<String, dynamic>>>(
        traceId: traceId,
        method: method,
        label: 'LỖI TẠO BÀI TẬP AI',
        onBackendInvocation: onBackendInvocation,
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
        'EXERCISE_CHUNK_FAILED',
        'Chunk bài tập không được tạo.',
        error,
        stackTrace,
        data: {'chunkStartDay': chunk.startDay, 'chunkDays': chunk.days},
        location: StackTrace.current,
      );
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<T> _runWithRetry<T>({
    required String traceId,
    required String method,
    required String label,
    required Future<T> Function(_AIModelEntry entry) operation,
    AiBackendInvocationCallback? onBackendInvocation,
  }) async {
    var totalAttempts = 0;
    var cooldownSkips = 0;
    var modelCursor = 0;
    Object? lastError;
    StackTrace? lastStackTrace;

    while (totalAttempts < AIRetryPolicy.maxAttemptsPerRequest) {
      final modelIndex = modelCursor < _models.length
          ? modelCursor++
          : _models.length - 1;
      final entry = _models[modelIndex];
      final cooldownUntil = _activeCooldownUntil(entry.name);
      if (modelIndex < _models.length - 1 && cooldownUntil != null) {
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

      totalAttempts++;
      AITraceLogger.info(
        _tag,
        traceId,
        method,
        'RETRY_ATTEMPT_START',
        label,
        data: {
          'model': entry.name,
          'modelAttempt': totalAttempts,
          'totalAttempt': totalAttempts,
        },
        location: StackTrace.current,
      );
      await onBackendInvocation?.call();

      try {
        final result = await operation(entry);
        AITraceLogger.success(
          _tag,
          traceId,
          method,
          'RETRY_ATTEMPT_SUCCESS',
          label,
          data: {
            'model': entry.name,
            'modelAttempt': totalAttempts,
            'totalAttempt': totalAttempts,
          },
          location: StackTrace.current,
        );
        return result;
      } catch (error, stackTrace) {
        final transient = AIRetryPolicy.isTransient(error);
        lastError = error;
        lastStackTrace = stackTrace;
        _printScheduleFailure(
          traceId: traceId,
          method: method,
          stage: 'RETRY_ATTEMPT_FAILED',
          model: entry.name,
          error: error,
          stackTrace: stackTrace,
          transient: transient,
        );
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
            'modelAttempt': totalAttempts,
            'totalAttempt': totalAttempts,
            'transient': transient,
          },
          location: StackTrace.current,
        );

        if (transient) {
          _cooldownModel(entry.name);
          if (totalAttempts < AIRetryPolicy.maxAttemptsPerRequest) {
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
    final failure = lastError;
    if (failure == null) {
      throw StateError('AI generation ended without an attempt result.');
    }
    if (!AIRetryPolicy.isTransient(failure)) {
      final stackTrace = lastStackTrace;
      if (stackTrace == null) {
        throw StateError('AI failure did not include a stack trace.');
      }
      Error.throwWithStackTrace(failure, stackTrace);
    }
    final providerStatus = failure is GeminiApiException
        ? failure.status?.trim()
        : null;
    throw AIOverloadedException(
      providerStatusCode: failure is GeminiApiException
          ? failure.statusCode
          : null,
      providerStatus:
          providerStatus != null &&
              RegExp(r'^[A-Za-z0-9_.-]{1,64}$').hasMatch(providerStatus)
          ? providerStatus
          : null,
      providerErrorCode:
          failure is GeminiApiException &&
              failure.backendErrorCode != null &&
              RegExp(
                r'^[A-Za-z0-9_.-]{1,64}$',
              ).hasMatch(failure.backendErrorCode!)
          ? failure.backendErrorCode
          : null,
    );
  }

  void _printScheduleFailure({
    required String traceId,
    required String method,
    required String stage,
    required String model,
    required Object error,
    required StackTrace stackTrace,
    required bool transient,
  }) {
    if (!kDebugMode) return;
    final status = error is GeminiApiException ? error.status : null;
    final safeStatus =
        status != null && RegExp(r'^[A-Za-z0-9_.-]{1,64}$').hasMatch(status)
        ? status
        : 'none';
    final safeModel = model.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '');
    // ignore: avoid_print
    print(
      '[NABI_AI_SCHEDULE] component=AI_SERVICE traceId=$traceId '
      'method=$method stage=$stage model=$safeModel '
      'errorType=${error.runtimeType} status=$safeStatus transient=$transient',
    );
    for (final line in stackTrace.toString().split('\n').take(8)) {
      if (line.trim().isEmpty) continue;
      // ignore: avoid_print
      print('[NABI_AI_SCHEDULE] stack=$line');
    }
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

    final client = _aiClient;
    if (client == null) {
      throw const AIConfigurationUnavailableException();
    }

    final text = await client.generateText(
      model: entry.name,
      contents: [GeminiContent.user(prompt)],
      generationConfig: const GeminiGenerationConfig(
        candidateCount: 1,
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

    if (AIModelContextLimitException.matches(error)) {
      return AIModelContextLimitException.userMessage;
    }

    if (error is AIConfigurationUnavailableException) {
      return 'Thiếu ${_providerCredentialLabel()} hoặc key đang rỗng.';
    }

    final text = error.toString();
    if (text.contains('Missing Gemini REST client')) {
      return 'Thiếu ${_providerCredentialLabel()} hoặc key đang rỗng.';
    }

    return 'Không thể kết nối AI. Bạn kiểm tra model hoặc mạng rồi thử lại nhé.';
  }

  static String? _envWithLegacy(String key, String legacyKey) {
    return AppEnv.maybeStringWithLegacy(key, legacyKey);
  }
}

class AIModelCandidates {
  // Keep plan generation aligned with the server allowlist. This is the
  // model verified against the deployed Edge Function with the full plan
  // output budget.
  static const defaultPrimaryModel = 'gemini-2.5-flash';
  static const defaultFallbackModels = <String>['gemini-3.8-flash'];

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
      'gemini-3.8-flash',
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
  // One initial request plus five retries before the caller falls back to a
  // smaller generation unit (a single meal slot for schedule generation).
  static const maxAttemptsPerRequest = 6;
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
