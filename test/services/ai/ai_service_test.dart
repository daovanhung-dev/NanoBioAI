import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:nano_app/core/interfaces/health_data_interface.dart';
import 'package:nano_app/core/storage/localdb/models/ai_catalog_models.dart';
import 'package:nano_app/core/storage/localdb/seeders/ai_catalog_seed_data.dart';
import 'package:nano_app/features/daily_health_tracking/domain/entities/daily_health_profile_entity.dart';
import 'package:nano_app/features/meal_plan/data/models/meal_plan_ai_normalizer.dart';
import 'package:nano_app/services/ai/ai_exceptions.dart';
import 'package:nano_app/services/ai/ai_json_parser.dart';
import 'package:nano_app/services/ai/ai_json_prompt_builder.dart';
import 'package:nano_app/services/ai/ai_service.dart';
import 'package:nano_app/services/ai/ai_trace_logger.dart';
import 'package:nano_app/services/ai/ai_vietnamese_text_validator.dart';
import 'package:nano_app/services/ai/prompts/exercise_tasks_prompt.dart';
import 'package:nano_app/services/ai/prompts/meal_plan_prompt.dart';

void main() {
  const catalog = AiCatalogBundle(
    meals: AiCatalogSeedData.meals,
    exercises: AiCatalogSeedData.exercises,
    scheduleTasks: AiCatalogSeedData.scheduleTasks,
  );

  group('AIOverloadedException', () {
    test('matches Gemini overload and capacity errors', () {
      expect(
        AIOverloadedException.matches(
          GenerativeAIException(
            'Server Error [503]: The model is overloaded. Try again later.',
          ),
        ),
        isTrue,
      );
      expect(
        AIOverloadedException.matches(
          ServerException(
            'Resource has been exhausted, check quota or rate limit.',
          ),
        ),
        isTrue,
      );
      expect(
        AIOverloadedException.matches(
          ServerException('Too many requests. Please retry later.'),
        ),
        isTrue,
      );
      expect(
        AIOverloadedException.matches(
          TimeoutException('Gemini request timed out'),
        ),
        isTrue,
      );
      expect(
        AIOverloadedException.matches(
          GenerativeAIException('Server Error [500]: Internal error.'),
        ),
        isTrue,
      );
      expect(
        AIOverloadedException.matches(
          GenerativeAIException('Server Error [504]: Deadline exceeded.'),
        ),
        isTrue,
      );
    });

    test('does not match unrelated validation errors', () {
      expect(
        AIOverloadedException.matches(
          const FormatException('AI response is not List'),
        ),
        isFalse,
      );
      expect(
        AIOverloadedException.matches(
          StateError('Expected 35 meal plan records, got 0'),
        ),
        isFalse,
      );
    });

    test('has user-facing Vietnamese message', () {
      expect(
        const AIOverloadedException().toString(),
        'AI đang quá tải. Bạn thử lại sau nhé.',
      );
    });
  });

  group('AIJsonParser', () {
    test('extracts arrays from markdown and removes trailing commas', () {
      final decoded = AIJsonParser.decodeArray('''
```json
[
  {"day": 1,},
]
```
''');

      expect(decoded, [
        {'day': 1},
      ]);
    });

    test('throws when response does not contain a JSON array', () {
      expect(
        () => AIJsonParser.decodeArray('{"day": 1}'),
        throwsFormatException,
      );
    });
  });

  group('AI prompts', () {
    test('meal prompt uses code-only schema and allowed catalog codes', () {
      final prompt = MealPlanPrompt.generate(
        healthData: const _FakeHealthData(),
        startDate: DateTime(2026, 6, 18),
        startDay: 1,
        days: 2,
        catalog: catalog.meals,
        usedMealCodes: const ['br_oat_egg'],
      );

      expect(prompt, contains('"meal_code"'));
      expect(prompt, contains('br_oat_egg'));
      expect(prompt, contains('Không tự tạo meal_code mới.'));
      expect(prompt, contains('Không trả về meal_name'));
      expect(prompt, isNot(contains('"meal_name":')));
      expect(prompt, isNot(_containsMojibake));
    });

    test('exercise prompt uses code-only schema and allowed catalog codes', () {
      final prompt = ExerciseTasksPrompt.generate(
        profile: const DailyHealthProfileEntity(
          userId: 'u1',
          fullName: 'Đào Văn Hùng',
          goals: ['Ngủ ngon hơn'],
          conditions: ['Đau lưng nhẹ'],
          habits: ['Đi bộ buổi sáng'],
          sleepQuality: 'Khá',
          activityLevel: 'Vừa phải',
          waterPerDay: '2 lít',
        ),
        startDate: DateTime(2026, 6, 18),
        startDay: 3,
        days: 2,
        catalog: catalog.exercises,
        usedExerciseCodes: const ['ex_walk_relaxed'],
      );

      expect(prompt, contains('"exercise_code"'));
      expect(prompt, contains('ex_walk_relaxed'));
      expect(prompt, contains('Không tự tạo exercise_code mới.'));
      expect(prompt, contains('Không trả về title'));
      expect(prompt, isNot(contains('"title":')));
      expect(prompt, isNot(_containsMojibake));
    });

    test('JSON wrapper is Vietnamese and forbids display text output', () {
      final prompt = AIJsonPromptBuilder.buildArrayPrompt(
        'Chọn mã kỹ thuật trong danh sách allowed.',
      );

      expect(prompt, contains('Chỉ trả về một mảng JSON hợp lệ.'));
      expect(prompt, contains('Không viết giải thích.'));
      expect(prompt, contains('Không tự tạo mã ngoài danh sách allowed.'));
      expect(prompt, isNot(contains('Return ONLY')));
      expect(prompt, isNot(_containsMojibake));
    });
  });

  group('AIVietnameseTextValidator', () {
    test('accepts Vietnamese text and allowed technical tokens', () {
      expect(
        AIVietnameseTextValidator.isValidDisplayText(
          'AI phân tích BMI và đề xuất 350 kcal, uống 300 ml nước.',
        ),
        isTrue,
      );
      expect(AIVietnameseTextValidator.isValidDisplayText('JSON'), isTrue);
    });

    test('rejects unaccented Vietnamese and mojibake text', () {
      expect(
        AIVietnameseTextValidator.isValidDisplayText(
          'Can bang dam va chat xo trong bua sang.',
        ),
        isFalse,
      );
      expect(
        AIVietnameseTextValidator.isValidDisplayText(
          'AI Ä‘ang quÃ¡ táº£i. Báº¡n thá»­ láº¡i sau nhÃ©.',
        ),
        isFalse,
      );
    });

    test('validates selected JSON display fields', () {
      expect(
        () => AIVietnameseTextValidator.validateJsonFields(
          items: const [
            {
              'meal_name': 'Cơm gạo lứt cá hồi',
              'description': 'Bữa trưa giàu đạm và chất xơ.',
              'cooking_instructions': 'Bước 1 hấp cá. Bước 2 trộn rau.',
            },
          ],
          fields: const ['meal_name', 'description', 'cooking_instructions'],
          label: 'Meal AI response',
        ),
        returnsNormally,
      );

      expect(
        () => AIVietnameseTextValidator.validateJsonFields(
          items: const [
            {'meal_name': 'Com gao lut ca hoi'},
          ],
          fields: const ['meal_name'],
          label: 'Meal AI response',
        ),
        throwsFormatException,
      );
    });
  });

  group('AIService connection check', () {
    test('succeeds when AI returns the expected JSON ping payload', () async {
      String? capturedPrompt;
      final service = AIService(
        modelNames: const ['fake-model'],
        textGenerator: ({required modelName, required prompt}) async {
          capturedPrompt = prompt;
          return jsonEncode([
            {'status_code': 'ai_connection_ok'},
          ]);
        },
      );

      final result = await service.checkConnection(
        perModelTimeout: const Duration(milliseconds: 100),
      );

      expect(result.success, isTrue);
      expect(result.message, 'AI đã sẵn sàng.');
      expect(result.modelName, 'fake-model');
      expect(capturedPrompt, contains('ai_connection_ok'));
    });

    test('fails when AI returns an empty response', () async {
      final service = AIService(
        modelNames: const ['fake-model'],
        textGenerator: ({required modelName, required prompt}) async => '',
      );

      final result = await service.checkConnection(
        perModelTimeout: const Duration(milliseconds: 100),
      );

      expect(result.success, isFalse);
      expect(result.message, contains('không đúng định dạng'));
      expect(result.modelName, 'fake-model');
    });

    test('fails when AI response is not a JSON array', () async {
      final service = AIService(
        modelNames: const ['fake-model'],
        textGenerator: ({required modelName, required prompt}) async {
          return jsonEncode({'status_code': 'ai_connection_ok'});
        },
      );

      final result = await service.checkConnection(
        perModelTimeout: const Duration(milliseconds: 100),
      );

      expect(result.success, isFalse);
      expect(result.message, contains('không đúng định dạng'));
    });

    test('fails when AI returns the wrong status code', () async {
      final service = AIService(
        modelNames: const ['fake-model'],
        textGenerator: ({required modelName, required prompt}) async {
          return jsonEncode([
            {'status_code': 'unexpected'},
          ]);
        },
      );

      final result = await service.checkConnection(
        perModelTimeout: const Duration(milliseconds: 100),
      );

      expect(result.success, isFalse);
      expect(result.message, contains('không đúng định dạng'));
    });

    test('fails when the text generator throws', () async {
      final service = AIService(
        modelNames: const ['fake-model'],
        textGenerator: ({required modelName, required prompt}) async {
          throw StateError('network down');
        },
      );

      final result = await service.checkConnection(
        perModelTimeout: const Duration(milliseconds: 100),
      );

      expect(result.success, isFalse);
      expect(result.message, contains('Không thể kết nối AI'));
      expect(result.modelName, 'fake-model');
    });
  });

  group('AIService chunked generation', () {
    test('meal generation splits seven days into 2-2-3 chunks', () async {
      final prompts = <String>[];
      var call = 0;
      final service = AIService(
        modelNames: const ['fake-model'],
        catalogLoader: () async => catalog,
        textGenerator: ({required modelName, required prompt}) async {
          prompts.add(prompt);
          final chunks = [
            _mealItemsForRange(startDay: 1, days: 2),
            _mealItemsForRange(startDay: 3, days: 2),
            _mealItemsForRange(startDay: 5, days: 3),
          ];
          return jsonEncode(chunks[call++]);
        },
      );

      final meals = await service.generateMealPlan(
        healthData: const _FakeHealthData(),
        userId: 'u1',
        startDate: DateTime(2026, 6, 18),
      );

      expect(meals, hasLength(35));
      expect(prompts, hasLength(3));
      expect(prompts[0], contains('ngày 1 đến ngày 2'));
      expect(prompts[1], contains('ngày 3 đến ngày 4'));
      expect(prompts[2], contains('ngày 5 đến ngày 7'));
      expect(prompts[1], contains('br_oat_egg'));
    });

    test(
      'meal generation logs trace, prompt, raw response, and AI source',
      () async {
        final rawResponse = jsonEncode(
          _mealItemsForRange(startDay: 1, days: 1),
        );
        final service = AIService(
          modelNames: const ['fake-model'],
          catalogLoader: () async => catalog,
          textGenerator: ({required modelName, required prompt}) async {
            return rawResponse;
          },
        );

        final logs = await _captureDebugPrint(() async {
          final meals = await service.generateMealPlan(
            healthData: const _FakeHealthData(),
            userId: 'u1',
            startDate: DateTime(2026, 6, 18),
            days: 1,
          );
          expect(meals, hasLength(MealPlanAiNormalizer.mealsPerDay));
        });
        final joined = logs.join('\n');

        expect(joined, contains('traceId=meal-plan-'));
        expect(joined, contains('method=generateMealPlan'));
        expect(joined, contains('PROMPT_SENT'));
        expect(joined, contains(rawResponse));
        expect(joined, contains('MEAL_CHUNK_SUCCESS'));
        expect(joined, contains('source'));
        expect(joined, contains(AITraceLogger.aiGen));
      },
    );

    test('meal generation falls back only for invalid chunks', () async {
      var call = 0;
      final service = AIService(
        modelNames: const ['fake-model'],
        catalogLoader: () async => catalog,
        textGenerator: ({required modelName, required prompt}) async {
          call++;
          if (call == 2) {
            return jsonEncode([
              {'day': 3, 'meal_type': 'breakfast', 'meal_code': 'unknown_meal'},
            ]);
          }
          return jsonEncode(
            call == 1
                ? _mealItemsForRange(startDay: 1, days: 2)
                : _mealItemsForRange(startDay: 5, days: 3),
          );
        },
      );

      final meals = await service.generateMealPlan(
        healthData: const _FakeHealthData(),
        userId: 'u1',
        startDate: DateTime(2026, 6, 18),
      );

      expect(meals, hasLength(35));
      expect(
        meals.where((meal) => meal.planDate == '2026-06-20'),
        hasLength(MealPlanAiNormalizer.mealsPerDay),
      );
      expect(meals.map((meal) => meal.mealName), isNot(contains('Bua sang')));
    });

    test(
      'meal generation logs validation failure stack and local source',
      () async {
        final service = AIService(
          modelNames: const ['fake-model'],
          catalogLoader: () async => catalog,
          textGenerator: ({required modelName, required prompt}) async {
            final items = _mealItemsForRange(startDay: 1, days: 1);
            items.first['meal_code'] = 'unknown_meal';
            return jsonEncode(items);
          },
        );

        final logs = await _captureDebugPrint(() async {
          final meals = await service.generateMealPlan(
            healthData: const _FakeHealthData(),
            userId: 'u1',
            startDate: DateTime(2026, 6, 18),
            days: 1,
          );
          expect(meals, hasLength(MealPlanAiNormalizer.mealsPerDay));
        });
        final joined = logs.join('\n');

        expect(joined, contains('MEAL_CHUNK_LOCAL_FALLBACK'));
        expect(joined, contains('Unknown meal_code'));
        expect(joined, contains('StackTrace'));
        expect(joined, contains(AITraceLogger.localGen));
        expect(joined, contains('MEAL_LOCAL_FALLBACK_ITEMS'));
      },
    );

    test('transient retry logs attempts, transient flag, and delay', () async {
      var call = 0;
      final delays = <Duration>[];
      final service = AIService(
        modelNames: const ['fake-model'],
        catalogLoader: () async => catalog,
        random: Random(0),
        delay: (duration) async {
          delays.add(duration);
        },
        textGenerator: ({required modelName, required prompt}) async {
          call++;
          if (call == 1) {
            throw TimeoutException('temporary overload');
          }
          return jsonEncode(_mealItemsForRange(startDay: 1, days: 1));
        },
      );

      final logs = await _captureDebugPrint(() async {
        final meals = await service.generateMealPlan(
          healthData: const _FakeHealthData(),
          userId: 'u1',
          startDate: DateTime(2026, 6, 18),
          days: 1,
        );
        expect(meals, hasLength(MealPlanAiNormalizer.mealsPerDay));
      });
      final joined = logs.join('\n');

      expect(call, 2);
      expect(delays, hasLength(1));
      expect(joined, contains('RETRY_ATTEMPT_FAILED'));
      expect(joined, contains('"modelAttempt": 1'));
      expect(joined, contains('"totalAttempt": 1'));
      expect(joined, contains('"transient": true'));
      expect(joined, contains('RETRY_DELAY'));
      expect(joined, contains('delayMs'));
    });

    test('exercise generation returns fourteen catalog-mapped tasks', () async {
      final prompts = <String>[];
      var call = 0;
      final service = AIService(
        modelNames: const ['fake-model'],
        catalogLoader: () async => catalog,
        textGenerator: ({required modelName, required prompt}) async {
          prompts.add(prompt);
          final chunks = [
            _exerciseItemsForRange(startDay: 1, days: 2),
            _exerciseItemsForRange(startDay: 3, days: 2),
            _exerciseItemsForRange(startDay: 5, days: 3),
          ];
          return jsonEncode(chunks[call++]);
        },
      );

      final exercises = await service.generateExerciseTasks(
        profile: const DailyHealthProfileEntity(
          userId: 'u1',
          fullName: 'Đào Văn Hùng',
          goals: ['Ngủ ngon hơn'],
          conditions: [],
          habits: [],
          sleepQuality: 'Khá',
          activityLevel: 'Nhẹ',
          waterPerDay: '2 lít',
        ),
        startDate: DateTime(2026, 6, 18),
      );

      expect(exercises, hasLength(14));
      expect(prompts, hasLength(3));
      expect(exercises.first.title, 'Đi bộ thư giãn');
      expect(exercises.first.unit, 'lần');
    });
  });

  group('AIModelCandidates', () {
    test(
      'uses default primary and fallback models when env values are absent',
      () {
        expect(
          AIModelCandidates.resolve(
            primaryModel: null,
            fallbackModelsCsv: null,
          ),
          ['gemini-2.5-flash-lite', 'gemini-2.5-flash'],
        );
      },
    );

    test(
      'prioritizes primary model, parses fallback csv, and de-duplicates',
      () {
        expect(
          AIModelCandidates.resolve(
            primaryModel: ' gemini-custom ',
            fallbackModelsCsv:
                'gemini-2.5-flash, gemini-custom, gemini-2.0-flash, ',
          ),
          ['gemini-custom', 'gemini-2.5-flash', 'gemini-2.0-flash'],
        );
      },
    );

    test('uses default fallback when fallback csv is blank', () {
      expect(
        AIModelCandidates.resolve(
          primaryModel: 'gemini-custom',
          fallbackModelsCsv: ' , ',
        ),
        ['gemini-custom', 'gemini-2.5-flash'],
      );
    });
  });

  group('AIRetryPolicy', () {
    test('classifies only transient errors as retryable with backoff', () {
      expect(
        AIRetryPolicy.isTransient(
          GenerativeAIException(
            'Server Error [503]: This model is currently experiencing high demand.',
          ),
        ),
        isTrue,
      );
      expect(
        AIRetryPolicy.isTransient(
          ServerException('Resource has been exhausted.'),
        ),
        isTrue,
      );
      expect(
        AIRetryPolicy.isTransient(
          const FormatException('AI response is not List'),
        ),
        isFalse,
      );
    });

    test('uses capped exponential-ish base delays', () {
      expect(
        AIRetryPolicy.baseDelayForFailureNumber(1),
        const Duration(seconds: 2),
      );
      expect(
        AIRetryPolicy.baseDelayForFailureNumber(2),
        const Duration(seconds: 5),
      );
      expect(
        AIRetryPolicy.baseDelayForFailureNumber(3),
        const Duration(seconds: 10),
      );
      expect(
        AIRetryPolicy.baseDelayForFailureNumber(4),
        const Duration(seconds: 20),
      );
      expect(
        AIRetryPolicy.baseDelayForFailureNumber(99),
        const Duration(seconds: 20),
      );
    });
  });
}

final Matcher _containsMojibake = matches(RegExp(r'Ã|Ä|Æ|áº|á»|Â'));

Future<List<String>> _captureDebugPrint(Future<void> Function() body) async {
  final previousDebugPrint = debugPrint;
  final logs = <String>[];
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null) {
      logs.add(message);
    }
  };

  try {
    await body();
  } finally {
    debugPrint = previousDebugPrint;
  }

  return logs;
}

List<Map<String, Object?>> _mealItemsForRange({
  required int startDay,
  required int days,
}) {
  final byType = <String, List<String>>{
    for (final slot in MealPlanAiNormalizer.mealSlots)
      slot.type: AiCatalogSeedData.meals
          .where((item) => item.mealType == slot.type)
          .map((item) => item.code)
          .toList(),
  };

  return [
    for (var day = startDay; day < startDay + days; day++)
      for (final slot in MealPlanAiNormalizer.mealSlots)
        {
          'day': day,
          'meal_type': slot.type,
          'meal_code':
              byType[slot.type]![(day - 1) % byType[slot.type]!.length],
          'portion_level': 'standard',
          'priority': slot.order,
        },
  ];
}

List<Map<String, Object?>> _exerciseItemsForRange({
  required int startDay,
  required int days,
}) {
  return [
    for (var day = startDay; day < startDay + days; day++) ...[
      {
        'day': day,
        'exercise_code': AiCatalogSeedData.exercises[((day - 1) * 2) % 16].code,
        'start_time': '08:00',
        'end_time': '08:25',
        'intensity': 'light',
        'target_value': 1,
        'priority': 1,
      },
      {
        'day': day,
        'exercise_code':
            AiCatalogSeedData.exercises[(((day - 1) * 2) + 1) % 16].code,
        'start_time': '17:30',
        'end_time': '18:00',
        'intensity': 'moderate',
        'target_value': 1,
        'priority': 2,
      },
    ],
  ];
}

class _FakeHealthData implements HealthDataInterface {
  const _FakeHealthData();

  @override
  String get activityLevel => 'Vừa phải';

  @override
  String get allergyName => '';

  @override
  String get allergyNote => '';

  @override
  int get birthYear => 1992;

  @override
  double get bmi => 22.4;

  @override
  List<String> get conditions => const ['Đau dạ dày nhẹ'];

  @override
  String get concernText => 'Muốn ăn uống lành mạnh hơn';

  @override
  String get fullName => 'Đào Văn Hùng';

  @override
  String get gender => 'Nam';

  @override
  List<String> get goals => const ['Giữ cân nặng ổn định'];

  @override
  List<String> get habits => const ['Đi bộ buổi sáng'];

  @override
  double get heightCm => 170;

  @override
  String get medicationName => '';

  @override
  String get sleepQuality => 'Khá';

  @override
  String get treatmentName => '';

  @override
  String get treatmentNote => '';

  @override
  String get waterPerDay => '2 lít';

  @override
  double get weightKg => 65;
}
