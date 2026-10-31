import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/interfaces/health_data_interface.dart';
import 'package:nano_app/core/network/backend_ai_text_client.dart';
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
import 'ai_text_client.dart';
import 'ai_trace_logger.dart';
import 'prompts/exercise_tasks_prompt.dart';
import 'prompts/meal_plan_prompt.dart';

typedef AITextGenerator =
    Future<String> Function({
      required String modelName,
      required String prompt,
    });

typedef AiCatalogLoader = Future<AiCatalogBundle> Function();
typedef AiBackendInvocationCallback = Future<void> Function();

final aiServiceProvider = Provider<AIService>((ref) {
  return AIService(
    aiClient: const BackendAiTextClient(),
    modelNames: const [BackendAiTextClient.modelId],
  );
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
  static const _singleMealOutputTokens = 64;
  static const _singleDayExerciseOutputTokens = 128;
  static const _singleDayMealOutputTokens = 256;
  static const _singleDayCompactMealOutputTokens = 256;
  static const _connectionCheckStatusCode = 'ai_connection_ok';
  static const _connectionCheckPrompt = '''
Trả về đúng một item trong items theo schema sau:
{"status_code":"ai_connection_ok"}
Không thêm chữ giải thích, markdown hoặc dữ liệu khác.
''';
  static const Map<String, dynamic> _connectionCheckSchema = {
    'type': 'object',
    'properties': {
      'items': {
        'type': 'array',
        'minItems': 1,
        'maxItems': 1,
        'items': {
          'type': 'object',
          'properties': {
            'status_code': {'const': _connectionCheckStatusCode},
          },
          'required': ['status_code'],
          'additionalProperties': false,
        },
      },
    },
    'required': ['items'],
    'additionalProperties': false,
  };

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
    List<String>? modelNames,
    Future<void> Function(Duration)? delay,
    Random? random,
    AITextGenerator? textGenerator,
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

    // Explicit clients remain available to focused tests. Runtime AI always
    // uses the authenticated NanoBio backend.
    _aiClient = _textGenerator == null
        ? aiClient ?? const BackendAiTextClient()
        : null;

    final resolvedModelNames = modelNames ?? [BackendAiTextClient.modelId];
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
        'Chưa có cấu hình model AI từ máy chủ để kiểm tra.',
        location: StackTrace.current,
      );
      return const AIConnectionCheckResult.failure(
        message: 'Chưa có cấu hình model AI từ máy chủ để kiểm tra.',
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
          maxOutputTokens: 64,
          responseJsonSchema: _connectionCheckSchema,
        ).timeout(perModelTimeout);

        if (text.trim().isEmpty) {
          throw const FormatException('AI backend returned an empty response');
        }

        final decoded = AIJsonParser.decodeArray(text);
        if (decoded.isEmpty) {
          throw const FormatException(
            'AI backend returned an empty JSON array',
          );
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
            'AI backend returned an invalid connection check payload',
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
      final preparedPrompt = await _prepareMealPrompt(
        traceId: traceId,
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
        prompt: preparedPrompt.prompt,
        candidateCodes: preparedPrompt.candidateCodes,
        candidateCodesByType: preparedPrompt.candidateCodesByType,
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
      final preparedPrompt = await _prepareExercisePrompt(
        traceId: traceId,
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
        prompt: preparedPrompt.prompt,
        candidateCodes: preparedPrompt.candidateCodes,
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
    Map<String, Set<String>>? eligibleCodesByType,
    Map<String, Object?> personalization = const {},
    required AiBackendInvocationCallback onBackendInvocation,
  }) async {
    if (day < 1 || day > 7) {
      throw RangeError.range(day, 1, 7, 'day');
    }
    _ensureMealCatalogAvailable(
      catalog,
      eligibleCodesByType: eligibleCodesByType,
    );
    final traceId = AITraceLogger.nextTraceId('meal-day-$day');
    final preparedPrompt = await _prepareMealPrompt(
      traceId: traceId,
      startDate: startDate,
      startDay: day,
      days: 1,
      catalog: catalog.meals,
      usedMealCodeCounts: usedCodeCounts,
      eligibleCodesByType: eligibleCodesByType,
      personalization: personalization,
    );
    final result = await _generateMealChunk(
      normalizer: const MealPlanAiNormalizer(),
      catalog: catalog,
      prompt: preparedPrompt.prompt,
      candidateCodes: preparedPrompt.candidateCodes,
      candidateCodesByType: preparedPrompt.candidateCodesByType,
      chunk: _AIChunk(startDay: day, days: 1),
      usedCodeCounts: usedCodeCounts,
      eligibleCodesByType: eligibleCodesByType,
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
    final preparedPrompt = await _prepareExercisePrompt(
      traceId: traceId,
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
      prompt: preparedPrompt.prompt,
      candidateCodes: preparedPrompt.candidateCodes,
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
    Map<String, Object?> personalization = const {},
    required AiBackendInvocationCallback onBackendInvocation,
  }) async {
    if (day < 1 || day > 7) {
      throw RangeError.range(day, 1, 7, 'day');
    }
    _ensureMealCatalogAvailable(
      catalog,
      eligibleCodesByType: eligibleFallbackCodesByType,
    );
    return AIGenerationResult(
      value: await generateMealDayCodeItems(
        startDate: startDate,
        day: day,
        catalog: catalog,
        usedCodeCounts: usedCodeCounts,
        eligibleCodesByType: eligibleFallbackCodesByType,
        personalization: personalization,
        onBackendInvocation: onBackendInvocation,
      ),
      source: PlanGenerationSource.ai,
    );
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
    _ensureMealCatalogAvailable(
      catalog,
      eligibleCodesByType: eligibleFallbackCodesByType,
    );
    final slotIndex = MealPlanAiNormalizer.mealSlots.indexWhere(
      (candidate) => candidate.type == mealType.trim().toLowerCase(),
    );
    if (slotIndex < 0) {
      throw ArgumentError.value(mealType, 'mealType');
    }
    final slot = MealPlanAiNormalizer.mealSlots[slotIndex];
    final candidateCodesByType = _mealCandidateCodesByType(
      catalog: catalog.meals,
      usedCodeCounts: usedCodeCounts,
      eligibleCodesByType: eligibleFallbackCodesByType,
      perSlotLimit: 4,
      minimumUniqueCount: 1,
    );
    final candidateCodes = candidateCodesByType[slot.type] ?? const <String>{};
    if (candidateCodes.isEmpty) {
      throw StateError('No eligible local meal candidates for this slot.');
    }
    final traceId = AITraceLogger.nextTraceId('meal-slot-$day-${slot.type}');
    final prompt = MealPlanPrompt.generate(
      startDate: startDate,
      startDay: day,
      days: 1,
      onlyMealType: slot.type,
      catalog: catalog.meals,
      usedMealCodeCounts: usedCodeCounts,
      eligibleCodesByType: eligibleFallbackCodesByType,
      personalization: personalization,
      candidateCodes: candidateCodes,
      compactSelectionContext: true,
    );
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
          maxOutputTokens: _singleMealOutputTokens,
          responseJsonSchema: _codeItemsJsonSchema(
            codeKey: 'meal_code',
            startDay: day,
            days: 1,
            itemsPerDay: 1,
            allowedCodes: candidateCodes,
            allowedCodesByType: {slot.type: candidateCodes},
            mealTypes: [slot.type],
          ),
        );
        if (decoded.length != 1) {
          throw const FormatException(
            'Meal AI slot response must contain exactly one meal.',
          );
        }
        _ensureMealCodesWithinCandidates(decoded, candidateCodes);
        return const MealPlanAiNormalizer().validateCodeItemForSlot(
          item: decoded.single,
          catalog: catalog,
          day: day,
          mealType: slot.type,
          usedCodeCounts: usedCodeCounts,
          dayMealCodes: dayMealCodes,
          eligibleCodesByType: eligibleFallbackCodesByType,
        );
      },
    );
    return AIGenerationResult(value: items, source: PlanGenerationSource.ai);
  }

  Future<AIGenerationResult<Map<String, dynamic>>>
  generateCustomMealProposalWithSource({
    required int day,
    required String mealType,
    Map<String, Object?> personalization = const {},
    required AiBackendInvocationCallback onBackendInvocation,
  }) async {
    if (day < 1 || day > 7) {
      throw RangeError.range(day, 1, 7, 'day');
    }
    final normalizedType = mealType.trim().toLowerCase();
    if (!MealPlanAiNormalizer.mealSlots.any(
      (slot) => slot.type == normalizedType,
    )) {
      throw ArgumentError.value(mealType, 'mealType');
    }
    final traceId = AITraceLogger.nextTraceId(
      'custom-meal-$day-$normalizedType',
    );
    const method = 'generateCustomMealProposal';
    final prompt =
        '''
Bạn đề xuất một món ăn tự nấu cho bữa $normalizedType của ngày $day.
Danh sách món phù hợp từ danh mục sau lọc cho suất này: []. Không có món catalog nào được gửi cho suất này.
Tôn trọng các ràng buộc cá nhân dưới đây. Chỉ đề xuất nguyên liệu và cách chế biến cụ thể; không đưa ra tuyên bố y khoa, dinh dưỡng, dị ứng hoặc điều trị.
Trả về đúng một object trong items, theo schema:
{"meal_type":"$normalizedType","meal_name":"...","description":"...","ingredients":["..."],"serving_size":"...","cooking_steps":["..."]}
Không thêm mã catalog, dinh dưỡng, lợi ích sức khỏe, hoặc trường khác.
Ràng buộc cá nhân (JSON): ${jsonEncode(personalization)}
''';
    final value = await _runWithRetry<Map<String, dynamic>>(
      traceId: traceId,
      method: method,
      label: 'TẠO MÓN CHỜ DUYỆT',
      onBackendInvocation: onBackendInvocation,
      operation: (entry) async {
        final decoded = await _generateJsonArray(
          entry,
          prompt,
          traceId: traceId,
          method: method,
          step: 'CUSTOM_MEAL day=$day type=$normalizedType',
          maxOutputTokens: 384,
          responseJsonSchema: _customMealProposalJsonSchema(normalizedType),
        );
        if (decoded.length != 1 || decoded.single is! Map) {
          throw const FormatException(
            'Custom meal response must contain exactly one object.',
          );
        }
        final map = Map<String, dynamic>.from(decoded.single as Map);
        const allowed = {
          'meal_type',
          'meal_name',
          'description',
          'ingredients',
          'serving_size',
          'cooking_steps',
        };
        if (map.keys.toSet().length != allowed.length ||
            !map.keys.toSet().containsAll(allowed)) {
          throw const FormatException('Custom meal response keys are invalid.');
        }
        final responseType =
            map['meal_type']?.toString().trim().toLowerCase() ?? '';
        final name = map['meal_name']?.toString().trim() ?? '';
        final description = map['description']?.toString().trim() ?? '';
        final servingSize = map['serving_size']?.toString().trim() ?? '';
        final ingredients = _customMealTextList(map['ingredients']);
        final cookingSteps = _customMealTextList(map['cooking_steps']);
        if (responseType != normalizedType ||
            name.isEmpty ||
            name.length > 120 ||
            description.isEmpty ||
            description.length > 800 ||
            servingSize.isEmpty ||
            servingSize.length > 120 ||
            ingredients.isEmpty ||
            ingredients.length > 20 ||
            cookingSteps.isEmpty ||
            cookingSteps.length > 12) {
          throw const FormatException(
            'Custom meal fields are incomplete or invalid.',
          );
        }
        return {
          'meal_type': normalizedType,
          'meal_name': name,
          'description': description,
          'ingredients': ingredients,
          'serving_size': servingSize,
          'cooking_steps': cookingSteps,
        };
      },
    );
    return AIGenerationResult(value: value, source: PlanGenerationSource.ai);
  }

  List<String> _customMealTextList(Object? value) {
    if (value is! List) {
      throw const FormatException('Custom meal list field is invalid.');
    }
    final values = value.map((item) => item?.toString().trim() ?? '').toList();
    if (values.any((item) => item.isEmpty || item.length > 300)) {
      throw const FormatException('Custom meal list contains invalid text.');
    }
    return List.unmodifiable(values);
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
  }

  Future<_GeneratedPlanChunk> _generateMealChunk({
    required MealPlanAiNormalizer normalizer,
    required AiCatalogBundle catalog,
    required String prompt,
    Set<String>? candidateCodes,
    Map<String, Set<String>>? candidateCodesByType,
    required _AIChunk chunk,
    required Map<String, int> usedCodeCounts,
    Map<String, Set<String>>? eligibleCodesByType,
    required String traceId,
    AiBackendInvocationCallback? onBackendInvocation,
  }) async {
    const method = 'generateMealPlan';
    final compactSingleDayMealCodes =
        chunk.days == 1 &&
        candidateCodesByType != null &&
        MealPlanAiNormalizer.mealSlots.every(
          (slot) => candidateCodesByType[slot.type]?.isNotEmpty ?? false,
        );
    try {
      final items = await _runWithRetry<List<Map<String, dynamic>>>(
        traceId: traceId,
        method: method,
        label: 'LỖI TẠO THỰC ĐƠN AI',
        onBackendInvocation: onBackendInvocation,
        operation: (entry) async {
          final response = await _generateJsonArray(
            entry,
            prompt,
            traceId: traceId,
            method: method,
            step: 'MEAL_CHUNK day=${chunk.startDay}',
            maxOutputTokens: compactSingleDayMealCodes
                ? _singleDayCompactMealOutputTokens
                : _mealOutputTokenBudget(chunk.days),
            responseJsonSchema: compactSingleDayMealCodes
                ? _compactMealCodeArrayJsonSchema(candidateCodesByType)
                : _codeItemsJsonSchema(
                    codeKey: 'meal_code',
                    startDay: chunk.startDay,
                    days: chunk.days,
                    itemsPerDay: MealPlanAiNormalizer.mealsPerDay,
                    allowedCodes: candidateCodes,
                    allowedCodesByType: candidateCodesByType,
                    mealTypes: MealPlanAiNormalizer.mealSlots.map(
                      (slot) => slot.type,
                    ),
                  ),
          );
          final compactAlignment = compactSingleDayMealCodes
              ? _expandCompactMealCodes(
                  response,
                  chunk.startDay,
                  candidateCodesByType,
                )
              : null;
          final decoded = compactAlignment?.items ?? response;
          _ensureMealCodesWithinCandidates(decoded, candidateCodes);
          if (compactAlignment != null) {
            AITraceLogger.info(
              _tag,
              traceId,
              method,
              'MEAL_COMPACT_SLOT_ALIGNMENT',
              'Compact AI meal codes matched to eligible slots.',
              data: {
                'itemCount': decoded.length,
                'positionMatchCount': compactAlignment.positionMatchCount,
                'reassignedCount':
                    MealPlanAiNormalizer.mealSlots.length -
                    compactAlignment.positionMatchCount,
              },
              location: StackTrace.current,
            );
          }
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
            eligibleCodesByType: eligibleCodesByType,
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

  void _ensureMealCatalogAvailable(
    AiCatalogBundle catalog, {
    Map<String, Set<String>>? eligibleCodesByType,
  }) {
    for (final slot in MealPlanAiNormalizer.mealSlots) {
      final hasCandidate = catalog.meals.any(
        (item) =>
            (item.isSelectableForMealPlanAi ||
                (item.isUnreviewedWellnessScheduleCandidate &&
                    eligibleCodesByType?[slot.type]?.contains(item.code) ==
                        true) ||
                (item.isApprovedCustomScheduleMeal &&
                    eligibleCodesByType?[slot.type]?.contains(item.code) ==
                        true)) &&
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

  int _mealOutputTokenBudget(int days) =>
      min(384, max(_singleDayMealOutputTokens, days * 128)).toInt();

  int _exerciseOutputTokenBudget(int days) =>
      min(384, max(_singleDayExerciseOutputTokens, days * 64)).toInt();

  Map<String, dynamic> _codeItemsJsonSchema({
    required String codeKey,
    required int startDay,
    required int days,
    required int itemsPerDay,
    Set<String>? allowedCodes,
    Map<String, Set<String>>? allowedCodesByType,
    Iterable<String>? mealTypes,
  }) {
    final codes =
        allowedCodes
            ?.map((code) => code.trim().toLowerCase())
            .where((code) => code.isNotEmpty)
            .toSet()
            .toList()
          ?..sort();
    final normalizedMealTypes = mealTypes
        ?.map((type) => type.trim().toLowerCase())
        .where((type) => type.isNotEmpty)
        .toSet()
        .toList();
    final normalizedCodesByType = <String, List<String>>{
      for (final entry
          in allowedCodesByType?.entries ??
              const <MapEntry<String, Set<String>>>[])
        entry.key.trim().toLowerCase():
            entry.value
                .map((code) => code.trim().toLowerCase())
                .where((code) => code.isNotEmpty)
                .toSet()
                .toList()
              ..sort(),
    };
    final properties = <String, dynamic>{
      'day': {
        'type': 'integer',
        'enum': [for (var day = startDay; day < startDay + days; day++) day],
      },
      if (normalizedMealTypes != null && normalizedMealTypes.isNotEmpty)
        'meal_type': {'type': 'string', 'enum': normalizedMealTypes},
      codeKey: {
        'type': 'string',
        if (codes != null && codes.isNotEmpty) 'enum': codes,
      },
    };
    final oneMealPerSlotSchemas =
        normalizedMealTypes != null &&
            normalizedMealTypes.isNotEmpty &&
            days == 1 &&
            itemsPerDay == normalizedMealTypes.length &&
            normalizedMealTypes.every(
              (type) => normalizedCodesByType[type]?.isNotEmpty ?? false,
            )
        ? [
            for (final mealType in normalizedMealTypes)
              {
                'type': 'object',
                'properties': {
                  'day': properties['day'],
                  'meal_type': {'const': mealType},
                  codeKey: {
                    'type': 'string',
                    'enum': normalizedCodesByType[mealType],
                  },
                },
                'required': ['day', 'meal_type', codeKey],
                'additionalProperties': false,
              },
          ]
        : null;
    final itemSchema = normalizedCodesByType.isEmpty
        ? {
            'type': 'object',
            'properties': properties,
            'required': properties.keys.toList(growable: false),
            'additionalProperties': false,
          }
        : {
            'oneOf': [
              for (final entry in normalizedCodesByType.entries)
                if (entry.value.isNotEmpty)
                  {
                    'type': 'object',
                    'properties': {
                      'day': properties['day'],
                      'meal_type': {'const': entry.key},
                      codeKey: {'type': 'string', 'enum': entry.value},
                    },
                    'required': ['day', 'meal_type', codeKey],
                    'additionalProperties': false,
                  },
            ],
          };
    return {
      'type': 'object',
      'properties': {
        'items': {
          'type': 'array',
          'minItems': days * itemsPerDay,
          'maxItems': days * itemsPerDay,
          if (oneMealPerSlotSchemas == null)
            'items': itemSchema
          else
            'prefixItems': oneMealPerSlotSchemas,
        },
      },
      'required': ['items'],
      'additionalProperties': false,
    };
  }

  Map<String, dynamic> _compactMealCodeArrayJsonSchema(
    Map<String, Set<String>> allowedCodesByType,
  ) {
    final prefixItems = [
      for (final slot in MealPlanAiNormalizer.mealSlots)
        {
          'type': 'string',
          'enum': allowedCodesByType[slot.type]!.toList()..sort(),
        },
    ];
    return {
      'type': 'object',
      'properties': {
        'items': {
          'type': 'array',
          'minItems': MealPlanAiNormalizer.mealsPerDay,
          'maxItems': MealPlanAiNormalizer.mealsPerDay,
          'prefixItems': prefixItems,
        },
      },
      'required': ['items'],
      'additionalProperties': false,
    };
  }

  ({List<Map<String, dynamic>> items, int positionMatchCount})
  _expandCompactMealCodes(
    List<dynamic> response,
    int day,
    Map<String, Set<String>> allowedCodesByType,
  ) {
    final slots = MealPlanAiNormalizer.mealSlots;
    if (response.length != slots.length) {
      throw const FormatException(
        'Meal AI compact response must contain exactly five codes.',
      );
    }
    final codes = <String>[];
    for (var index = 0; index < slots.length; index++) {
      final rawCode = response[index];
      if (rawCode is! String || rawCode.trim().isEmpty) {
        throw const FormatException(
          'Meal AI compact response codes must be non-empty strings.',
        );
      }
      codes.add(rawCode.trim().toLowerCase());
    }
    if (codes.toSet().length != codes.length) {
      throw const FormatException(
        'Meal AI compact response codes must be unique.',
      );
    }
    final normalizedCodesByType = {
      for (final entry in allowedCodesByType.entries)
        entry.key.trim().toLowerCase(): entry.value
            .map((code) => code.trim().toLowerCase())
            .where((code) => code.isNotEmpty)
            .toSet(),
    };
    final assignedCodes = List<String?>.filled(slots.length, null);
    final assignedIndexes = <int>{};

    bool assignSlot(int slotIndex) {
      if (slotIndex == slots.length) return true;
      final allowedCodes = normalizedCodesByType[slots[slotIndex].type] ?? {};
      final eligibleIndexes =
          [
            for (var codeIndex = 0; codeIndex < codes.length; codeIndex++)
              if (!assignedIndexes.contains(codeIndex) &&
                  allowedCodes.contains(codes[codeIndex]))
                codeIndex,
          ]..sort((left, right) {
            final leftKeepsPosition = left == slotIndex ? 0 : 1;
            final rightKeepsPosition = right == slotIndex ? 0 : 1;
            if (leftKeepsPosition != rightKeepsPosition) {
              return leftKeepsPosition.compareTo(rightKeepsPosition);
            }
            return left.compareTo(right);
          });

      for (final codeIndex in eligibleIndexes) {
        assignedIndexes.add(codeIndex);
        assignedCodes[slotIndex] = codes[codeIndex];
        if (assignSlot(slotIndex + 1)) return true;
        assignedIndexes.remove(codeIndex);
        assignedCodes[slotIndex] = null;
      }
      return false;
    }

    if (!assignSlot(0)) {
      throw const FormatException(
        'Meal AI compact response cannot fill eligible slots.',
      );
    }
    final items = [
      for (var index = 0; index < slots.length; index++)
        {
          'day': day,
          'meal_type': slots[index].type,
          'meal_code': assignedCodes[index]!,
        },
    ];
    final positionMatchCount = [
      for (var index = 0; index < slots.length; index++)
        if (assignedCodes[index] == codes[index]) index,
    ].length;
    return (items: items, positionMatchCount: positionMatchCount);
  }

  Map<String, dynamic> _customMealProposalJsonSchema(String mealType) => {
    'type': 'object',
    'properties': {
      'items': {
        'type': 'array',
        'minItems': 1,
        'maxItems': 1,
        'items': {
          'type': 'object',
          'properties': {
            'meal_type': {'const': mealType},
            'meal_name': {'type': 'string'},
            'description': {'type': 'string'},
            'ingredients': {
              'type': 'array',
              'items': {'type': 'string'},
            },
            'serving_size': {'type': 'string'},
            'cooking_steps': {
              'type': 'array',
              'items': {'type': 'string'},
            },
          },
          'required': [
            'meal_type',
            'meal_name',
            'description',
            'ingredients',
            'serving_size',
            'cooking_steps',
          ],
          'additionalProperties': false,
        },
      },
    },
    'required': ['items'],
    'additionalProperties': false,
  };

  Future<
    ({
      String prompt,
      Set<String>? candidateCodes,
      Map<String, Set<String>>? candidateCodesByType,
    })
  >
  _prepareMealPrompt({
    required String traceId,
    required DateTime startDate,
    required int startDay,
    required int days,
    required List<MealCatalogItemModel> catalog,
    required Map<String, int> usedMealCodeCounts,
    Map<String, FoodIngredientEvidence> ingredientEvidenceByName = const {},
    Map<String, Set<String>>? eligibleCodesByType,
    Map<String, Object?> personalization = const {},
  }) async {
    String buildPrompt(Set<String>? candidateCodes) => MealPlanPrompt.generate(
      startDate: startDate,
      startDay: startDay,
      days: days,
      catalog: catalog,
      usedMealCodeCounts: usedMealCodeCounts,
      ingredientEvidenceByName: ingredientEvidenceByName,
      eligibleCodesByType: eligibleCodesByType,
      personalization: personalization,
      candidateCodes: candidateCodes,
      compactSelectionContext: true,
    );

    final contextClient = _aiClient;
    if (contextClient is! AiContextAwareClient) {
      return (
        prompt: buildPrompt(null),
        candidateCodes: null,
        candidateCodesByType: null,
      );
    }
    final contextEstimator = contextClient as AiContextAwareClient;

    final contextSize = await contextEstimator.selectedContextSize();
    final outputReserve = days == 1
        ? _singleDayCompactMealOutputTokens
        : min(_mealOutputTokenBudget(days), max(96, contextSize ~/ 4)).toInt();
    // Schedule generation commits one day at a time. Keep a small choice set
    // for each slot in this request; later days rebuild the shortlist using
    // the updated used-code counts, so every day can still get fresh choices
    // without sending the whole remaining horizon to the model at once.
    final minimumPerSlot = max(days, 2);
    var candidateLimit = minimumPerSlot;
    final targetInputTokens = min(768, max(256, contextSize ~/ 3)).toInt();
    while (true) {
      final candidatesByType = _mealCandidateCodesByType(
        catalog: catalog,
        usedCodeCounts: usedMealCodeCounts,
        eligibleCodesByType: eligibleCodesByType,
        perSlotLimit: candidateLimit,
        minimumUniqueCount: days * MealPlanAiNormalizer.mealsPerDay,
      );
      final candidates = candidatesByType.values
          .expand((codes) => codes)
          .toSet();
      final prompt = buildPrompt(candidates);
      final wrappedPrompt = AIJsonPromptBuilder.buildArrayPrompt(prompt);
      final tokenCount = await contextEstimator.estimateTokens(
        'user: $wrappedPrompt',
      );
      final availableTokens = contextSize - tokenCount - outputReserve - 32;
      AITraceLogger.info(
        _tag,
        traceId,
        'generateMealPlan',
        'MEAL_PROMPT_BUDGET',
        'Meal prompt budget measured.',
        data: {
          'contextSize': contextSize,
          'inputTokens': tokenCount,
          'outputReserveTokens': outputReserve,
          'availableTokens': availableTokens,
          'candidateCount': candidates.length,
          'candidateGroups': _mealCandidateGroupCounts(candidatesByType),
          'hasSystemInstruction': false,
          'status': availableTokens >= 32 ? 'fits' : 'shrunk',
        },
        location: StackTrace.current,
      );
      if (availableTokens >= 32 &&
          (tokenCount <= targetInputTokens ||
              candidateLimit <= minimumPerSlot)) {
        return (
          prompt: prompt,
          candidateCodes: candidates,
          candidateCodesByType: candidatesByType,
        );
      }
      if (candidateLimit <= minimumPerSlot && availableTokens < 32) {
        throw const AIRequestTooLargeException();
      }
      candidateLimit = max(minimumPerSlot, candidateLimit - 1);
    }
  }

  String _mealCandidateGroupCounts(Map<String, Set<String>> candidatesByType) =>
      MealPlanAiNormalizer.mealSlots
          .map(
            (slot) =>
                '${slot.type}=${candidatesByType[slot.type]?.length ?? 0}',
          )
          .join(',');

  Map<String, Set<String>> _mealCandidateCodesByType({
    required List<MealCatalogItemModel> catalog,
    required Map<String, int> usedCodeCounts,
    required Map<String, Set<String>>? eligibleCodesByType,
    required int perSlotLimit,
    required int minimumUniqueCount,
  }) {
    final normalizedEligibleCodesByType = {
      for (final entry
          in eligibleCodesByType?.entries ??
              const <MapEntry<String, Set<String>>>[])
        entry.key.trim().toLowerCase(): entry.value
            .map((code) => code.trim().toLowerCase())
            .where((code) => code.isNotEmpty)
            .toSet(),
    };
    final codesByType = <String, Set<String>>{};
    for (final slot in MealPlanAiNormalizer.mealSlots) {
      final candidates =
          catalog
              .where((meal) {
                final code = meal.code.trim().toLowerCase();
                final eligible =
                    normalizedEligibleCodesByType[slot.type]?.contains(code) ??
                    false;
                final allowed =
                    meal.isSelectableForMealPlanAi ||
                    (meal.isUnreviewedWellnessScheduleCandidate && eligible) ||
                    (meal.isApprovedCustomScheduleMeal && eligible);
                return allowed &&
                    (eligibleCodesByType == null || eligible) &&
                    code.isNotEmpty &&
                    meal.mealName.trim().isNotEmpty &&
                    (meal.mealType == slot.type ||
                        meal.mealType == 'unclassified');
              })
              .toList(growable: false)
            ..sort((left, right) {
              final leftCode = left.code.trim().toLowerCase();
              final rightCode = right.code.trim().toLowerCase();
              final count = (usedCodeCounts[leftCode] ?? 0).compareTo(
                usedCodeCounts[rightCode] ?? 0,
              );
              if (count != 0) return count;
              final name = normalizeFoodEvidenceName(
                left.mealName,
              ).compareTo(normalizeFoodEvidenceName(right.mealName));
              return name != 0 ? name : leftCode.compareTo(rightCode);
            });
      final seenNames = <String>{};
      final selectedCodes = <String>{};
      for (final meal in candidates) {
        final code = meal.code.trim().toLowerCase();
        final name = normalizeFoodEvidenceName(meal.mealName);
        if (!seenNames.add(name)) continue;
        selectedCodes.add(code);
        if (selectedCodes.length >= perSlotLimit) break;
      }
      codesByType[slot.type] = selectedCodes;
    }
    final codes = codesByType.values.expand((values) => values).toSet();
    if (codes.length < minimumUniqueCount) {
      throw StateError('Insufficient unique eligible meal candidates.');
    }
    return codesByType;
  }

  Future<({String prompt, Set<String>? candidateCodes})>
  _prepareExercisePrompt({
    required String traceId,
    required DateTime startDate,
    required int startDay,
    required int days,
    required List<ExerciseCatalogItemModel> catalog,
    required Map<String, int> usedExerciseCodeCounts,
    Map<String, Object?> personalization = const {},
    List<Map<String, String>> availableTimeWindows = const [],
  }) async {
    String buildPrompt(Set<String>? candidateCodes) =>
        ExerciseTasksPrompt.generate(
          startDate: startDate,
          startDay: startDay,
          days: days,
          catalog: catalog,
          usedExerciseCodeCounts: usedExerciseCodeCounts,
          personalization: personalization,
          availableTimeWindows: availableTimeWindows,
          candidateCodes: candidateCodes,
          compactSelectionContext: true,
        );

    final contextClient = _aiClient;
    if (contextClient is! AiContextAwareClient) {
      return (prompt: buildPrompt(null), candidateCodes: null);
    }
    final contextEstimator = contextClient as AiContextAwareClient;

    final contextSize = await contextEstimator.selectedContextSize();
    final outputReserve = min(
      _exerciseOutputTokenBudget(days),
      max(96, contextSize ~/ 4),
    ).toInt();
    final minimumCount = max(ExerciseTasksAiNormalizer.exercisesPerDay, days);
    final remainingScheduleDays = max(1, 8 - startDay);
    var candidateLimit = min(4, max(minimumCount, remainingScheduleDays * 2));
    while (true) {
      final candidates = _exerciseCandidateCodes(
        catalog: catalog,
        usedCodeCounts: usedExerciseCodeCounts,
        limit: candidateLimit,
      );
      final prompt = buildPrompt(candidates);
      final wrappedPrompt = AIJsonPromptBuilder.buildArrayPrompt(prompt);
      final tokenCount = await contextEstimator.estimateTokens(
        'user: $wrappedPrompt',
      );
      final availableTokens = contextSize - tokenCount - outputReserve - 32;
      AITraceLogger.info(
        _tag,
        traceId,
        'generateExerciseTasks',
        'EXERCISE_PROMPT_BUDGET',
        'Exercise prompt budget measured.',
        data: {
          'contextSize': contextSize,
          'inputTokens': tokenCount,
          'outputReserveTokens': outputReserve,
          'availableTokens': availableTokens,
          'candidateCount': candidates.length,
          'candidateGroups': 'selectable=${candidates.length}',
          'hasSystemInstruction': false,
          'status': availableTokens >= 32 ? 'fits' : 'shrunk',
        },
        location: StackTrace.current,
      );
      if (availableTokens >= 32) {
        return (prompt: prompt, candidateCodes: candidates);
      }
      if (candidateLimit <= minimumCount) {
        throw const AIRequestTooLargeException();
      }
      candidateLimit = max(minimumCount, candidateLimit ~/ 2);
    }
  }

  Set<String> _exerciseCandidateCodes({
    required List<ExerciseCatalogItemModel> catalog,
    required Map<String, int> usedCodeCounts,
    required int limit,
  }) {
    final candidates =
        catalog
            .where(
              (item) =>
                  item.isActive &&
                  item.code.trim().isNotEmpty &&
                  item.title.trim().isNotEmpty,
            )
            .toList(growable: false)
          ..sort((left, right) {
            final leftCode = left.code.trim().toLowerCase();
            final rightCode = right.code.trim().toLowerCase();
            final count = (usedCodeCounts[leftCode] ?? 0).compareTo(
              usedCodeCounts[rightCode] ?? 0,
            );
            return count != 0 ? count : leftCode.compareTo(rightCode);
          });
    return candidates
        .take(limit)
        .map((item) => item.code.trim().toLowerCase())
        .toSet();
  }

  void _ensureMealCodesWithinCandidates(
    List<dynamic> decoded,
    Set<String>? candidateCodes,
  ) {
    if (candidateCodes == null) return;
    for (final item in decoded.whereType<Map>()) {
      final code = item['meal_code']?.toString().trim().toLowerCase();
      if (code != null && code.isNotEmpty && !candidateCodes.contains(code)) {
        throw const FormatException(
          'Model selected a meal outside its prompt shortlist.',
        );
      }
    }
  }

  void _ensureExerciseCodesWithinCandidates(
    List<dynamic> decoded,
    Set<String>? candidateCodes,
  ) {
    if (candidateCodes == null) return;
    for (final item in decoded.whereType<Map>()) {
      final code = item['exercise_code']?.toString().trim().toLowerCase();
      if (code != null && code.isNotEmpty && !candidateCodes.contains(code)) {
        throw const FormatException(
          'Model selected an exercise outside its prompt shortlist.',
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
    Set<String>? candidateCodes,
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
            maxOutputTokens: _exerciseOutputTokenBudget(chunk.days),
            responseJsonSchema: _codeItemsJsonSchema(
              codeKey: 'exercise_code',
              startDay: chunk.startDay,
              days: chunk.days,
              itemsPerDay: ExerciseTasksAiNormalizer.exercisesPerDay,
              allowedCodes: candidateCodes,
            ),
          );
          _ensureExerciseCodesWithinCandidates(decoded, candidateCodes);
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
            'errorCode': _safeErrorCode(error),
          },
          location: StackTrace.current,
        );

        if (error is AiInferenceException && !transient) {
          break;
        }

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
      if (failure is FormatException) {
        Error.throwWithStackTrace(
          const AIResponseInvalidException(),
          stackTrace,
        );
      }
      Error.throwWithStackTrace(failure, stackTrace);
    }
    final providerStatus = failure is AiInferenceException
        ? failure.status?.trim()
        : null;
    throw AIOverloadedException(
      providerStatusCode: failure is AiInferenceException
          ? failure.statusCode
          : null,
      providerStatus:
          providerStatus != null &&
              RegExp(r'^[A-Za-z0-9_.-]{1,64}$').hasMatch(providerStatus)
          ? providerStatus
          : null,
      providerErrorCode:
          failure is AiInferenceException &&
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
    final status = error is AiInferenceException ? error.status : null;
    final safeStatus =
        status != null && RegExp(r'^[A-Za-z0-9_.-]{1,64}$').hasMatch(status)
        ? status
        : 'none';
    final safeModel = model.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '');
    // ignore: avoid_print
    print(
      '[NABI_AI_SCHEDULE] component=AI_SERVICE traceId=$traceId '
      'method=$method stage=$stage model=$safeModel '
      'errorType=${error.runtimeType} errorCode=${_safeErrorCode(error)} '
      'status=$safeStatus transient=$transient',
    );
    for (final line in stackTrace.toString().split('\n').take(8)) {
      if (line.trim().isEmpty) continue;
      // ignore: avoid_print
      print('[NABI_AI_SCHEDULE] stack=$line');
    }
  }

  String _safeErrorCode(Object error) {
    if (error is AiInferenceException) {
      final status = error.status?.trim();
      if (status != null &&
          RegExp(r'^[A-Za-z0-9_.-]{1,64}$').hasMatch(status)) {
        return status;
      }
      return 'inference_error';
    }
    if (error is TimeoutException) return 'inference_timeout';
    if (error is AIRequestTooLargeException) return 'request_too_large';
    if (error is AIResponseInvalidException) return 'invalid_response';
    if (error is AIJsonParseException) return error.code;
    if (error is FormatException) return _safeSchemaErrorCode(error);
    if (error is StateError) return 'runtime_state';
    return 'generation_error';
  }

  String _safeSchemaErrorCode(FormatException error) {
    final message = error.message.toString();
    if (message == 'Meal AI compact response cannot fill eligible slots.') {
      return 'meal_slot_assignment_invalid';
    }
    if (message == 'Model selected a meal outside its prompt shortlist.') {
      return 'meal_code_outside_shortlist';
    }
    if (message.startsWith('Meal AI response must contain exactly')) {
      return 'meal_item_count_invalid';
    }
    if (message == 'Meal AI item must be an object') {
      return 'meal_item_shape_invalid';
    }
    if (message.startsWith('Meal AI day must')) return 'meal_day_invalid';
    if (message.startsWith('Unsupported meal_type:')) {
      return 'meal_type_unsupported';
    }
    if (message.startsWith('Unknown meal_code:')) return 'meal_code_unknown';
    if (message.startsWith('Unapproved or ineligible meal_code:')) {
      return 'meal_code_unreviewed';
    }
    if (message.startsWith('meal_code ')) return 'meal_code_not_eligible';
    if (message.startsWith('Duplicate meal_type')) {
      return 'meal_type_duplicate';
    }
    if (message.startsWith('Duplicate meal_code')) {
      return 'meal_code_duplicate';
    }
    if (message.startsWith('Duplicate meal_name')) {
      return 'meal_name_duplicate';
    }
    if (message.startsWith('Expected meal_type')) {
      return 'meal_slot_missing';
    }
    if (message.startsWith('Meal AI item must contain only')) {
      return 'meal_item_fields_invalid';
    }
    if (message.startsWith('Exercise AI response must contain exactly')) {
      return 'exercise_item_count_invalid';
    }
    if (message.startsWith('Exercise AI day must')) {
      return 'exercise_day_invalid';
    }
    if (message.startsWith('Unknown exercise_code:')) {
      return 'exercise_code_unknown';
    }
    if (message.startsWith('Duplicate exercise_code')) {
      return 'exercise_code_duplicate';
    }
    return 'schema_validation_failed';
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
    int? maxOutputTokens,
    Map<String, dynamic>? responseJsonSchema,
  }) async {
    final wrappedPrompt = AIJsonPromptBuilder.buildArrayPrompt(prompt);
    final text = await _generateText(
      entry,
      wrappedPrompt,
      traceId: traceId,
      method: method,
      step: '$step.GENERATE_TEXT',
      maxOutputTokens: maxOutputTokens,
      responseJsonSchema: responseJsonSchema,
    ).timeout(const Duration(minutes: 10));

    if (text.trim().isEmpty) {
      throw const AIResponseInvalidException();
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
    int? maxOutputTokens,
    Map<String, dynamic>? responseJsonSchema,
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
      messages: [AiMessage.user(prompt)],
      generationConfig: AiGenerationConfig(
        maxOutputTokens: maxOutputTokens,
        temperature: 0.2,
        topP: 0.8,
        responseFormat: AiResponseFormat.json,
        responseJsonSchema: responseJsonSchema,
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

    if (AIPlatformUnsupportedException.matches(error)) {
      return AIPlatformUnsupportedException.userMessage;
    }

    if (error is AIConfigurationUnavailableException) {
      return AIConfigurationUnavailableException.userMessage;
    }

    if (error is AiInferenceException && error.status != null) {
      return error.message;
    }
    return 'Dịch vụ AI của Nabi hiện chưa khả dụng. Bạn thử lại sau nhé.';
  }
}

class AIModelCandidates {
  static const defaultPrimaryModel = BackendAiTextClient.modelId;
  static const defaultFallbackModels = <String>[];

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
      BackendAiTextClient.modelId,
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
