import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:nano_app/core/interfaces/health_data_interface.dart';
import 'package:nano_app/features/daily_health_tracking/domain/entities/daily_health_profile_entity.dart';
import 'package:nano_app/features/lifestyle_schedule/data/models/exercise_task_model.dart';
import 'package:nano_app/features/lifestyle_schedule/data/models/exercise_tasks_ai_normalizer.dart';
import 'package:nano_app/features/meal_plan/data/models/meal_plan_ai_normalizer.dart';
import 'package:nano_app/features/meal_plan/data/models/meal_plan_model.dart';

import 'ai_exceptions.dart';
import 'ai_json_prompt_builder.dart';
import 'ai_json_parser.dart';
import 'ai_vietnamese_text_validator.dart';
import 'prompts/exercise_tasks_prompt.dart';
import 'prompts/meal_plan_prompt.dart';

final aiServiceProvider = Provider<AIService>((ref) {
  return AIService();
});

class AIService {
  static const _mealDisplayFields = [
    'meal_name',
    'description',
    'cooking_instructions',
  ];
  static const _exerciseDisplayFields = [
    'title',
    'description',
    'unit',
    'encouragement',
  ];

  late final List<_AIModelEntry> _models;
  late final Future<void> Function(Duration) _delay;
  late final Random _random;

  AIService({
    String? apiKeyOverride,
    List<String>? modelNames,
    Future<void> Function(Duration)? delay,
    Random? random,
  }) {
    final apiKey = apiKeyOverride ?? dotenv.env['GEMINI_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Không tìm thấy GEMINI_API_KEY');
    }

    _delay = delay ?? ((duration) => Future<void>.delayed(duration));
    _random = random ?? Random();

    final resolvedModelNames =
        modelNames ??
        AIModelCandidates.resolve(
          primaryModel: dotenv.env['GEMINI_MODEL'],
          fallbackModelsCsv: dotenv.env['GEMINI_FALLBACK_MODELS'],
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
          model: GenerativeModel(
            model: modelName,
            apiKey: apiKey,
            generationConfig: generationConfig,
          ),
        ),
    ];
  }

  Future<List<MealPlanModel>> generateMealPlan({
    required HealthDataInterface healthData,
    required String userId,
    required DateTime startDate,
    int days = 7,
  }) async {
    final prompt = MealPlanPrompt.generate(
      healthData: healthData,
      startDate: startDate,
      days: days,
    );

    return _runWithRetry<List<MealPlanModel>>(
      label: 'LỖI TẠO THỰC ĐƠN AI',
      emptyResult: () => <MealPlanModel>[],
      operation: (model) async {
        final decoded = await _generateJsonArray(model, prompt);
        AIVietnameseTextValidator.validateJsonFields(
          items: decoded,
          fields: _mealDisplayFields,
          label: 'Meal AI response',
        );

        return const MealPlanAiNormalizer().normalize(
          items: decoded,
          userId: userId,
          startDate: startDate,
          days: days,
          createdAt: DateTime.now().toIso8601String(),
        );
      },
    );
  }

  Future<List<ExerciseTaskModel>> generateExerciseTasks({
    required DailyHealthProfileEntity profile,
    required DateTime startDate,
    int days = 7,
  }) async {
    final prompt = ExerciseTasksPrompt.generate(
      profile: profile,
      startDate: startDate,
      days: days,
    );

    return _runWithRetry<List<ExerciseTaskModel>>(
      label: 'LỖI TẠO BÀI TẬP AI',
      emptyResult: () => <ExerciseTaskModel>[],
      operation: (model) async {
        final decoded = await _generateJsonArray(model, prompt);
        AIVietnameseTextValidator.validateJsonFields(
          items: decoded,
          fields: _exerciseDisplayFields,
          label: 'Exercise AI response',
        );

        return const ExerciseTasksAiNormalizer().normalize(
          items: decoded,
          profile: profile,
          startDate: startDate,
          days: days,
          createdAt: DateTime.now().toIso8601String(),
        );
      },
    );
  }

  Future<T> _runWithRetry<T>({
    required String label,
    required Future<T> Function(GenerativeModel model) operation,
    required T Function() emptyResult,
  }) async {
    var totalAttempts = 0;
    var hasTransientError = false;

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
          return await operation(entry.model);
        } catch (error, stackTrace) {
          final transient = AIRetryPolicy.isTransient(error);
          hasTransientError = hasTransientError || transient;
          _logRetryError(
            label: label,
            modelName: entry.name,
            modelAttempt: modelAttempt,
            totalAttempt: totalAttempts,
            isTransient: transient,
            error: error,
            stackTrace: stackTrace,
          );

          final hasMoreAttempts =
              totalAttempts < AIRetryPolicy.maxAttemptsTotal &&
              (modelAttempt < AIRetryPolicy.maxAttemptsPerModel ||
                  modelIndex < _models.length - 1);
          if (!hasMoreAttempts) {
            break;
          }

          if (transient) {
            await _delay(
              AIRetryPolicy.delayForFailureNumber(
                totalAttempts,
                random: _random,
              ),
            );
          }
        }
      }
    }

    if (hasTransientError) {
      throw const AIOverloadedException();
    }

    return emptyResult();
  }

  Future<List<dynamic>> _generateJsonArray(
    GenerativeModel model,
    String prompt,
  ) async {
    final response = await model
        .generateContent([
          Content.text(AIJsonPromptBuilder.buildArrayPrompt(prompt)),
        ])
        .timeout(const Duration(minutes: 10));

    final text = response.text;
    if (text == null || text.trim().isEmpty) {
      throw Exception('Gemini trả về nội dung rỗng');
    }

    final cleaned = AIJsonParser.extractArrayText(text);
    final decoded = jsonDecode(cleaned);
    if (decoded is! List) {
      throw Exception('Gemini không trả về mảng JSON');
    }

    return decoded;
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
  final GenerativeModel model;

  const _AIModelEntry({required this.name, required this.model});
}
