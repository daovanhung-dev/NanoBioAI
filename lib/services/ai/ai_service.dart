import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:nano_app/core/storage/localdb/models/meal_plan_model.dart';
import 'package:nano_app/core/interfaces/health_data_interface.dart';

import 'prompts/nutrition_prompt.dart';

final aiServiceProvider = Provider<AIService>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );

  return AIService(dio: dio);
});

class AIService {
  final Dio dio;

  late final GenerativeModel _model;

  AIService({required this.dio}) {
    final apiKey = dotenv.env['GEMINI_API_KEY'];

    final model = dotenv.env['GEMINI_MODEL'];

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Không tìm thấy GEMINI_API_KEY');
    }

    _model = GenerativeModel(
      model: model ?? 'gemini-1.5-flash',
      apiKey: apiKey,
    );
  }

  Future<List<MealPlanModel>> generateMealPlan({
    required HealthDataInterface healthData,
  }) async {
    int retry = 0;

    while (retry < 3) {
      try {
        final prompt = NutritionPrompt.generateMealPlan(healthData: healthData);

        final content = [
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
        ];

        final response = await _model
            .generateContent(content)
            .timeout(const Duration(minutes: 10));

        final text = response.text;

        if (text == null || text.trim().isEmpty) {
          throw Exception('Gemini response empty');
        }

        debugPrint('RAW AI RESPONSE:');
        debugPrint(text);

        // CLEAN RESPONSE
        String cleaned = text
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        // FIX COMMON JSON ERRORS
        cleaned = cleaned.replaceAll(RegExp(r',\s*]'), ']');
        cleaned = cleaned.replaceAll(RegExp(r',\s*}'), '}');

        // EXTRACT JSON ARRAY
        final start = cleaned.indexOf('[');
        final end = cleaned.lastIndexOf(']');

        if (start == -1 || end == -1) {
          throw Exception('Invalid JSON format');
        }

        cleaned = cleaned.substring(start, end + 1);

        debugPrint('CLEANED JSON:');
        debugPrint(cleaned);

        // JSON PARSE
        final decoded = jsonDecode(cleaned);

        if (decoded is! List) {
          throw Exception('AI response is not List');
        }

        // JSON -> MODEL
        final meals = decoded.map<MealPlanModel>((e) {
          return MealPlanModel.fromJson(Map<String, dynamic>.from(e));
        }).toList();

        return meals;
      } catch (e, stackTrace) {
        retry++;

        debugPrint('AI GENERATE ERROR:');
        debugPrint(e.toString());
        debugPrint(stackTrace.toString());

        if (retry >= 3) {
          return [];
        }

        await Future.delayed(Duration(seconds: retry * 2));
      }
    }

    return [];
  }
}
