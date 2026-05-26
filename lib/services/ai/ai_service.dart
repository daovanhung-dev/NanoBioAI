import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:nano_app/core/storage/localdb/models/meal_plan_model.dart';

import 'package:nano_app/features/dashboard/domain/entities/dashboard_entity.dart';

import 'package:nano_app/services/ai/models/ai_meal_response_model.dart';

import 'prompts/nutrition_prompt.dart';

final aiServiceProvider = Provider<AIService>((ref) {
  final dio = Dio(
    BaseOptions(baseUrl: 'https://generativelanguage.googleapis.com/v1beta'),
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
      model: model ?? 'gemini-2.5-flash',

      apiKey: apiKey,
    );
  }

  Future<List<MealPlanModel>> generateMealPlan({
    required DashboardEntity healthData,
  }) async {
    try {
      final prompt = NutritionPrompt.generateMealPlan(healthData: healthData);

      final content = [
        Content.text('''
Generate ONLY valid JSON array.

Do not return markdown.
Do not explain.

$prompt
'''),
      ];

      final response = await _model.generateContent(content);

      final text = response.text;

      if (text == null || text.isEmpty) {
        throw Exception('Gemini response empty');
      }

      // clean markdown
      final cleaned = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      // String -> JSON
      final decoded = jsonDecode(cleaned);

      // JSON -> List<Model>
      final meals = (decoded as List).map<MealPlanModel>((e) {
        return MealPlanModel.fromJson(e);
      }).toList();

      return meals;
    } catch (e) {
      throw Exception('Generate meal plan failed: $e');
    }
  }
}
