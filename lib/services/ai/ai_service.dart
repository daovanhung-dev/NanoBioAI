import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:nano_app/core/interfaces/health_data_interface.dart';
import 'package:nano_app/features/daily_health_tracking/data/models/daily_health_ai_task_normalizer.dart';
import 'package:nano_app/features/daily_health_tracking/data/models/daily_health_task_model.dart';
import 'package:nano_app/features/daily_health_tracking/domain/entities/daily_health_profile_entity.dart';
import 'package:nano_app/features/meal_plan/data/models/meal_plan_model.dart';

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
        final cleaned = _extractJsonArrayText(text);

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

  Future<List<DailyHealthTaskModel>> generateDailyHealthTasks({
    required DailyHealthProfileEntity profile,
    required DateTime startDate,
    int days = 7,
  }) async {
    int retry = 0;

    while (retry < 3) {
      try {
        final prompt = _dailyHealthTasksPrompt(
          profile: profile,
          startDate: startDate,
          days: days,
        );

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

        debugPrint('RAW DAILY HEALTH AI RESPONSE:');
        debugPrint(text);

        final cleaned = _extractJsonArrayText(text);
        debugPrint('CLEANED DAILY HEALTH JSON:');
        debugPrint(cleaned);

        final decoded = jsonDecode(cleaned);
        if (decoded is! List) {
          throw Exception('AI daily health response is not List');
        }

        return const DailyHealthAiTaskNormalizer().normalize(
          items: decoded,
          profile: profile,
          startDate: startDate,
          days: days,
          createdAt: DateTime.now().toIso8601String(),
        );
      } catch (e, stackTrace) {
        retry++;

        debugPrint('AI DAILY HEALTH GENERATE ERROR:');
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

  String _extractJsonArrayText(String text) {
    var cleaned = text.replaceAll('```json', '').replaceAll('```', '').trim();

    cleaned = cleaned.replaceAll(RegExp(r',\s*]'), ']');
    cleaned = cleaned.replaceAll(RegExp(r',\s*}'), '}');

    final start = cleaned.indexOf('[');
    final end = cleaned.lastIndexOf(']');

    if (start == -1 || end == -1) {
      throw Exception('Invalid JSON format');
    }

    return cleaned.substring(start, end + 1);
  }

  String _dailyHealthTasksPrompt({
    required DailyHealthProfileEntity profile,
    required DateTime startDate,
    required int days,
  }) {
    final endDate = startDate.add(Duration(days: days - 1));
    final expectedCount = days * DailyHealthAiTaskNormalizer.categories.length;

    return '''
Ban la chuyen gia suc khoe loi song.
Viet hoan toan bang tieng Viet.
Tao nhiem vu suc khoe hang ngay cho $days ngay, bat dau tu ${_dateKey(startDate)} den ${_dateKey(endDate)}.
Moi ngay bat buoc co dung 4 nhiem vu, moi category dung 1 nhiem vu: water, body, mind, brain.
Tong so object bat buoc la $expectedCount.
Khong them key ngoai schema.
Gia tri so phai la number, khong phai string.
Ngay theo dinh dang YYYY-MM-DD.

Schema:
[
  {
    "task_date": "${_dateKey(startDate)}",
    "task_code": "ai_water",
    "category": "water",
    "title": "string",
    "description": "string",
    "target_value": 2000,
    "unit": "ml",
    "encouragement": "string"
  }
]

Yeu cau category:
- water: muc tieu nuoc/uong nuoc phu hop.
- body: bai tap hoac van dong an toan theo muc do hoat dong.
- mind: giam stress, ngu tot hon, tho/cham soc tinh than.
- brain: hoc mot y suc khoe, doc/review kien thuc, hoac nhan dien thoi quen.

Du lieu nguoi dung:
name: ${profile.fullName}
goals: ${profile.goals.isEmpty ? 'none' : profile.goals.join(', ')}
conditions: ${profile.conditions.isEmpty ? 'none' : profile.conditions.join(', ')}
habits: ${profile.habits.isEmpty ? 'none' : profile.habits.join(', ')}
sleep: ${profile.sleepQuality}
activity: ${profile.activityLevel}
water: ${profile.waterPerDay}
''';
  }

  String _dateKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
