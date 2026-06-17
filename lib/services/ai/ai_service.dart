import 'dart:convert';

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

import 'ai_json_parser.dart';
import 'prompts/exercise_tasks_prompt.dart';
import 'prompts/meal_plan_prompt.dart';

final aiServiceProvider = Provider<AIService>((ref) {
  return AIService();
});

class AIService {
  late final GenerativeModel _model;

  AIService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    final model = dotenv.env['GEMINI_MODEL'];

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Khong tim thay GEMINI_API_KEY');
    }

    _model = GenerativeModel(
      model: model ?? 'gemini-1.5-flash',
      apiKey: apiKey,
    );
  }

  Future<List<MealPlanModel>> generateMealPlan({
    required HealthDataInterface healthData,
    required String userId,
    required DateTime startDate,
    int days = 7,
  }) async {
    int retry = 0;

    while (retry < 3) {
      try {
        final prompt = MealPlanPrompt.generate(
          healthData: healthData,
          startDate: startDate,
          days: days,
        );
        final decoded = await _generateJsonArray(prompt);

        return const MealPlanAiNormalizer().normalize(
          items: decoded,
          userId: userId,
          startDate: startDate,
          days: days,
          createdAt: DateTime.now().toIso8601String(),
        );
      } catch (e, stackTrace) {
        retry++;
        _logRetryError('AI MEAL GENERATE ERROR', e, stackTrace);
        if (retry >= 3) return [];
        await Future.delayed(Duration(seconds: retry * 2));
      }
    }

    return [];
  }

  Future<List<ExerciseTaskModel>> generateExerciseTasks({
    required DailyHealthProfileEntity profile,
    required DateTime startDate,
    int days = 7,
  }) async {
    int retry = 0;

    while (retry < 3) {
      try {
        final prompt = ExerciseTasksPrompt.generate(
          profile: profile,
          startDate: startDate,
          days: days,
        );
        final decoded = await _generateJsonArray(prompt);

        return const ExerciseTasksAiNormalizer().normalize(
          items: decoded,
          profile: profile,
          startDate: startDate,
          days: days,
          createdAt: DateTime.now().toIso8601String(),
        );
      } catch (e, stackTrace) {
        retry++;
        _logRetryError('AI EXERCISE GENERATE ERROR', e, stackTrace);
        if (retry >= 3) return [];
        await Future.delayed(Duration(seconds: retry * 2));
      }
    }

    return [];
  }

  Future<List<dynamic>> _generateJsonArray(String prompt) async {
    final response = await _model
        .generateContent([
          Content.text('''
Return ONLY valid JSON array.

Rules:
- No markdown
- No explanation
- No ```json
- No extra text
- Return pure JSON only
- JSON must be valid

$prompt
'''),
        ])
        .timeout(const Duration(minutes: 10));

    final text = response.text;
    if (text == null || text.trim().isEmpty) {
      throw Exception('Gemini response empty');
    }

    final cleaned = AIJsonParser.extractArrayText(text);
    final decoded = jsonDecode(cleaned);
    if (decoded is! List) {
      throw Exception('AI response is not List');
    }

    return decoded;
  }

  void _logRetryError(String message, Object error, StackTrace stackTrace) {
    debugPrint(message);
    debugPrint(error.toString());
    debugPrint(stackTrace.toString());
  }
}
