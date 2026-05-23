import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'prompts/nutrition_prompt.dart';

class AIService {

  final Dio dio;

  AIService({
    required this.dio,
  });

  Future<Map<String, dynamic>>
      generateMealPlan({

    required Map<String, dynamic>
        healthData,

  }) async {

    try {

      final prompt =
          NutritionPrompt
              .generateMealPlan(
        healthData: healthData,
      );

      final model =
          dotenv.env['GEMINI_MODEL'];

      final apiKey =
          dotenv.env['GEMINI_API_KEY'];

      final response = await dio.post(

        '/models/$model:generateContent?key=$apiKey',

        data: {

          "contents": [

            {

              "parts": [

                {

                  "text":
'''
You are BioAI nutrition assistant.

$prompt
'''

                }

              ]

            }

          ],

          "generationConfig": {

            "temperature": 0.7,

            "topK": 40,

            "topP": 0.95,

            "maxOutputTokens": 8192,

          }

        },

      );

      final content = response
          .data['candidates'][0]
              ['content']['parts'][0]
                  ['text'];

      // Gemini đôi khi trả markdown
      final cleaned =
          content
              .replaceAll(
                '```json',
                '',
              )
              .replaceAll(
                '```',
                '',
              )
              .trim();

      return jsonDecode(cleaned);

    } catch (e) {

      throw Exception(
        'Generate meal plan failed: $e',
      );

    }

  }

}