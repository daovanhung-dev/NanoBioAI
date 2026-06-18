import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:nano_app/core/interfaces/health_data_interface.dart';
import 'package:nano_app/core/storage/localdb/datasources/ai_catalog_local_datasource.dart';
import 'package:nano_app/core/storage/localdb/models/ai_catalog_models.dart';
import 'package:nano_app/features/daily_health_tracking/domain/entities/daily_health_profile_entity.dart';
import 'package:nano_app/features/lifestyle_schedule/data/models/exercise_task_model.dart';
import 'package:nano_app/features/lifestyle_schedule/data/models/exercise_tasks_ai_normalizer.dart';
import 'package:nano_app/features/meal_plan/data/models/meal_plan_ai_normalizer.dart';
import 'package:nano_app/features/meal_plan/data/models/meal_plan_model.dart';

import 'ai_exceptions.dart';
import 'ai_json_parser.dart';
import 'ai_json_prompt_builder.dart';
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
  static const _chunkSizes = [2, 2, 3];
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

  AIService({
    String? apiKeyOverride,
    List<String>? modelNames,
    Future<void> Function(Duration)? delay,
    Random? random,
    AITextGenerator? textGenerator,
    AiCatalogLoader? catalogLoader,
  }) {
    _delay = delay ?? ((duration) => Future<void>.delayed(duration));
    _random = random ?? Random();
    _textGenerator = textGenerator;
    _catalogLoader =
        catalogLoader ?? const AiCatalogLocalDatasource().loadActiveBundle;

    final apiKey =
        apiKeyOverride ??
        (_textGenerator == null ? dotenv.env['GEMINI_API_KEY'] : null);
    if (_textGenerator == null && (apiKey == null || apiKey.isEmpty)) {
      throw Exception('Không tìm thấy GEMINI_API_KEY');
    }

    final resolvedModelNames =
        modelNames ??
        AIModelCandidates.resolve(
          primaryModel: _textGenerator == null
              ? dotenv.env['GEMINI_MODEL']
              : null,
          fallbackModelsCsv: _textGenerator == null
              ? dotenv.env['GEMINI_FALLBACK_MODELS']
              : null,
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
    if (_models.isEmpty) {
      return const AIConnectionCheckResult.failure(
        message: 'Không có model AI để kiểm tra.',
      );
    }

    Object? lastError;
    String? lastModelName;
    final prompt = AIJsonPromptBuilder.buildArrayPrompt(_connectionCheckPrompt);

    for (final entry in _models) {
      try {
        final text = await _generateText(
          entry,
          prompt,
        ).timeout(perModelTimeout);

        if (text.trim().isEmpty) {
          throw const FormatException('Gemini returned an empty response');
        }

        final decoded = AIJsonParser.decodeArray(text);
        if (decoded.isEmpty) {
          throw const FormatException('Gemini returned an empty JSON array');
        }

        final first = decoded.first;
        if (first is! Map ||
            first['status_code']?.toString() != _connectionCheckStatusCode) {
          throw const FormatException(
            'Gemini returned an invalid connection check payload',
          );
        }

        return AIConnectionCheckResult.success(modelName: entry.name);
      } catch (error) {
        lastError = error;
        lastModelName = entry.name;
        debugPrint(
          'AI connection check failed model=${entry.name} '
          'reason=${_connectionCheckFailureMessage(error)}',
        );
      }
    }

    return AIConnectionCheckResult.failure(
      message: _connectionCheckFailureMessage(lastError),
      modelName: lastModelName,
    );
  }

  Future<List<MealPlanModel>> generateMealPlan({
    required HealthDataInterface healthData,
    required String userId,
    required DateTime startDate,
    int days = 7,
  }) async {
    final catalog = await _catalogLoader();
    final normalizer = const MealPlanAiNormalizer();
    final usedCodeCounts = <String, int>{};
    final codeItems = <Map<String, dynamic>>[];

    for (final chunk in _chunkPlan(days)) {
      final prompt = MealPlanPrompt.generate(
        healthData: healthData,
        startDate: startDate,
        startDay: chunk.startDay,
        days: chunk.days,
        catalog: catalog.meals,
        usedMealCodes: _usedCodes(usedCodeCounts),
      );

      final chunkItems = await _generateMealChunk(
        normalizer: normalizer,
        catalog: catalog,
        prompt: prompt,
        chunk: chunk,
        usedCodeCounts: usedCodeCounts,
      );
      _accumulateCodeCounts(chunkItems, 'meal_code', usedCodeCounts);
      codeItems.addAll(chunkItems);
    }

    return normalizer.normalize(
      items: codeItems,
      catalog: catalog,
      userId: userId,
      startDate: startDate,
      days: days,
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  Future<List<ExerciseTaskModel>> generateExerciseTasks({
    required DailyHealthProfileEntity profile,
    required DateTime startDate,
    int days = 7,
  }) async {
    final catalog = await _catalogLoader();
    final normalizer = const ExerciseTasksAiNormalizer();
    final usedCodeCounts = <String, int>{};
    final codeItems = <Map<String, dynamic>>[];

    for (final chunk in _chunkPlan(days)) {
      final prompt = ExerciseTasksPrompt.generate(
        profile: profile,
        startDate: startDate,
        startDay: chunk.startDay,
        days: chunk.days,
        catalog: catalog.exercises,
        usedExerciseCodes: _usedCodes(usedCodeCounts),
      );

      final chunkItems = await _generateExerciseChunk(
        normalizer: normalizer,
        catalog: catalog,
        prompt: prompt,
        chunk: chunk,
        usedCodeCounts: usedCodeCounts,
      );
      _accumulateCodeCounts(chunkItems, 'exercise_code', usedCodeCounts);
      codeItems.addAll(chunkItems);
    }

    return normalizer.normalize(
      items: codeItems,
      catalog: catalog,
      profile: profile,
      startDate: startDate,
      days: days,
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  Future<List<Map<String, dynamic>>> _generateMealChunk({
    required MealPlanAiNormalizer normalizer,
    required AiCatalogBundle catalog,
    required String prompt,
    required _AIChunk chunk,
    required Map<String, int> usedCodeCounts,
  }) async {
    try {
      return await _runWithRetry<List<Map<String, dynamic>>>(
        label: 'LỖI TẠO THỰC ĐƠN AI',
        operation: (entry) async {
          final decoded = await _generateJsonArray(entry, prompt);
          return normalizer.validateCodeItems(
            items: decoded,
            catalog: catalog,
            startDay: chunk.startDay,
            days: chunk.days,
            usedCodeCounts: usedCodeCounts,
          );
        },
      );
    } on AIOverloadedException {
      rethrow;
    } catch (error, stackTrace) {
      _logFallback(
        label: 'FALLBACK THỰC ĐƠN AI',
        chunk: chunk,
        error: error,
        stackTrace: stackTrace,
      );
      return normalizer.fallbackCodeItems(
        catalog: catalog,
        startDay: chunk.startDay,
        days: chunk.days,
        usedCodeCounts: usedCodeCounts,
      );
    }
  }

  Future<List<Map<String, dynamic>>> _generateExerciseChunk({
    required ExerciseTasksAiNormalizer normalizer,
    required AiCatalogBundle catalog,
    required String prompt,
    required _AIChunk chunk,
    required Map<String, int> usedCodeCounts,
  }) async {
    try {
      return await _runWithRetry<List<Map<String, dynamic>>>(
        label: 'LỖI TẠO BÀI TẬP AI',
        operation: (entry) async {
          final decoded = await _generateJsonArray(entry, prompt);
          return normalizer.validateCodeItems(
            items: decoded,
            catalog: catalog,
            startDay: chunk.startDay,
            days: chunk.days,
            usedCodeCounts: usedCodeCounts,
          );
        },
      );
    } on AIOverloadedException {
      rethrow;
    } catch (error, stackTrace) {
      _logFallback(
        label: 'FALLBACK BÀI TẬP AI',
        chunk: chunk,
        error: error,
        stackTrace: stackTrace,
      );
      return normalizer.fallbackCodeItems(
        catalog: catalog,
        startDay: chunk.startDay,
        days: chunk.days,
        usedCodeCounts: usedCodeCounts,
      );
    }
  }

  Future<T> _runWithRetry<T>({
    required String label,
    required Future<T> Function(_AIModelEntry entry) operation,
  }) async {
    var totalAttempts = 0;

    for (var modelIndex = 0; modelIndex < _models.length; modelIndex++) {
      final entry = _models[modelIndex];

      for (
        var modelAttempt = 1;
        modelAttempt <= AIRetryPolicy.maxAttemptsPerModel &&
            totalAttempts < AIRetryPolicy.maxAttemptsTotal;
        modelAttempt++
      ) {
        totalAttempts++;

        try {
          return await operation(entry);
        } catch (error, stackTrace) {
          final transient = AIRetryPolicy.isTransient(error);
          _logRetryError(
            label: label,
            modelName: entry.name,
            modelAttempt: modelAttempt,
            totalAttempt: totalAttempts,
            isTransient: transient,
            error: error,
            stackTrace: stackTrace,
          );

          if (!transient) {
            rethrow;
          }

          final hasMoreAttempts =
              totalAttempts < AIRetryPolicy.maxAttemptsTotal &&
              (modelAttempt < AIRetryPolicy.maxAttemptsPerModel ||
                  modelIndex < _models.length - 1);
          if (!hasMoreAttempts) {
            break;
          }

          await _delay(
            AIRetryPolicy.delayForFailureNumber(totalAttempts, random: _random),
          );
        }
      }
    }

    throw const AIOverloadedException();
  }

  Future<List<dynamic>> _generateJsonArray(
    _AIModelEntry entry,
    String prompt,
  ) async {
    final wrappedPrompt = AIJsonPromptBuilder.buildArrayPrompt(prompt);
    final text = await _generateText(
      entry,
      wrappedPrompt,
    ).timeout(const Duration(minutes: 10));

    if (text.trim().isEmpty) {
      throw Exception('Gemini trả về nội dung rỗng');
    }

    return AIJsonParser.decodeArray(text);
  }

  Future<String> _generateText(_AIModelEntry entry, String prompt) async {
    final textGenerator = _textGenerator;
    if (textGenerator != null) {
      return textGenerator(modelName: entry.name, prompt: prompt);
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

  void _logRetryError({
    required String label,
    required String modelName,
    required int modelAttempt,
    required int totalAttempt,
    required bool isTransient,
    required Object error,
    required StackTrace stackTrace,
  }) {
    debugPrint(
      '$label model=$modelName modelAttempt=$modelAttempt '
      'totalAttempt=$totalAttempt transient=$isTransient',
    );
    debugPrint(error.toString());
    debugPrint(stackTrace.toString());
  }

  void _logFallback({
    required String label,
    required _AIChunk chunk,
    required Object error,
    required StackTrace stackTrace,
  }) {
    debugPrint('$label chunkStart=${chunk.startDay} chunkDays=${chunk.days}');
    debugPrint(error.toString());
    debugPrint(stackTrace.toString());
  }
}

class AIModelCandidates {
  static const defaultPrimaryModel = 'gemini-2.5-flash-lite';
  static const defaultFallbackModel = 'gemini-2.5-flash';

  const AIModelCandidates._();

  static List<String> resolve({
    required String? primaryModel,
    required String? fallbackModelsCsv,
  }) {
    final fallbackModels = _parseCsv(fallbackModelsCsv);
    final rawModels = <String>[
      _clean(primaryModel) ?? defaultPrimaryModel,
      ...(fallbackModels.isEmpty
          ? const [defaultFallbackModel]
          : fallbackModels),
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
  static const maxAttemptsPerModel = 2;
  static const maxAttemptsTotal = 4;
  static const maxDelay = Duration(seconds: 20);

  const AIRetryPolicy._();

  static bool isTransient(Object error) => AIOverloadedException.matches(error);

  static Duration baseDelayForFailureNumber(int failureNumber) {
    return switch (failureNumber) {
      <= 1 => const Duration(seconds: 2),
      2 => const Duration(seconds: 5),
      3 => const Duration(seconds: 10),
      _ => maxDelay,
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
}
