import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/interfaces/health_data_interface.dart';
import 'package:nano_app/core/storage/localdb/models/ai_catalog_models.dart';
import 'package:nano_app/core/storage/localdb/seeders/ai_catalog_seed_data.dart';
import 'package:nano_app/app_versions/v1/features/daily_health_tracking/domain/entities/daily_health_profile_entity.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/data/models/meal_plan_ai_normalizer.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_chat_service.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_exceptions.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_json_parser.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_json_prompt_builder.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_service.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_trace_logger.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_vietnamese_text_validator.dart';
import 'package:nano_app/app_versions/v1/services/ai/gemini_rest_client.dart';
import 'package:nano_app/app_versions/v1/services/ai/prompts/exercise_tasks_prompt.dart';
import 'package:nano_app/app_versions/v1/services/ai/prompts/meal_plan_prompt.dart';

void main() {
  test(
    'AI authentication failures are recognized without exposing credentials',
    () {
      const error = GeminiApiException(
        statusCode: 401,
        status: 'UNAUTHENTICATED',
        message: 'Request had invalid authentication credentials.',
      );

      expect(AIAuthenticationException.matches(error), isTrue);
      expect(AIAuthenticationException.userMessage, isNot(contains('AQ.')));
      expect(AIAuthenticationException.userMessage, isNot(contains('AIza')));
    },
  );

  const catalog = AiCatalogBundle(
    meals: AiCatalogSeedData.meals,
    exercises: AiCatalogSeedData.exercises,
    scheduleTasks: AiCatalogSeedData.scheduleTasks,
  );

  group('AIOverloadedException', () {
    test('matches Gemini overload and capacity errors', () {
      expect(
        AIOverloadedException.matches(
          const GeminiApiException(
            statusCode: 503,
            status: 'UNAVAILABLE',
            message: 'The model is overloaded. Try again later.',
          ),
        ),
        isTrue,
      );
      expect(
        AIOverloadedException.matches(
          const GeminiApiException(
            statusCode: 429,
            status: 'RESOURCE_EXHAUSTED',
            message: 'Resource has been exhausted, check quota or rate limit.',
          ),
        ),
        isTrue,
      );
      expect(
        AIOverloadedException.matches(
          const GeminiApiException(
            statusCode: 429,
            message: 'Too many requests. Please retry later.',
          ),
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
          const GeminiApiException(statusCode: 500, message: 'Internal error.'),
        ),
        isTrue,
      );
      expect(
        AIOverloadedException.matches(
          const GeminiApiException(
            statusCode: 504,
            status: 'DEADLINE_EXCEEDED',
            message: 'Deadline exceeded.',
          ),
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

    test('fails safely when runtime API key is missing', () async {
      late AIConnectionCheckResult result;

      final logs = await _captureDebugPrint(() async {
        final service = AIService(
          apiKeyOverride: '',
          modelNames: const ['fake-model'],
        );

        result = await service.checkConnection(
          perModelTimeout: const Duration(milliseconds: 100),
        );
      });

      expect(result.success, isFalse);
      expect(result.message, 'Thiếu GEMINI_API_KEY hoặc key đang rỗng.');
      expect(result.modelName, isNull);
      expect(logs.join('\n'), contains('MISSING_API_KEY'));
      expect(logs.join('\n'), isNot(contains('AIza')));
    });
  });

  group('AITraceLogger redaction', () {
    test('keeps only safe metadata and error type', () async {
      final logs = await _captureDebugPrint(() async {
        AITraceLogger.error(
          'AI_TEST',
          'safe-trace-id',
          'safeMethod',
          'SAFE_STAGE',
          'AI operation failed.',
          StateError('SENSITIVE_ERROR_VALUE_90210'),
          StackTrace.fromString('SENSITIVE_STACK_VALUE_77123'),
          data: const {
            'source': AITraceLogger.localGen,
            'rawPrompt': 'SENSITIVE_PROMPT_VALUE_11991',
          },
        );
      });
      final joined = logs.join('\n');

      expect(joined, contains('traceId=safe-trace-id'));
      expect(joined, contains('step=SAFE_STAGE'));
      expect(joined, contains('errorType'));
      expect(joined, contains('StateError'));
      expect(joined, contains(AITraceLogger.localGen));
      expect(joined, isNot(contains('SENSITIVE_ERROR_VALUE_90210')));
      expect(joined, isNot(contains('SENSITIVE_STACK_VALUE_77123')));
      expect(joined, isNot(contains('SENSITIVE_PROMPT_VALUE_11991')));
      expect(joined, isNot(contains('StackTrace')));
    });
  });

  group('AIChatService', () {
    test('logs metadata without chat message or response content', () async {
      const message = 'SENSITIVE_CHAT_MESSAGE_93217';
      const response =
          'Mình sẽ hỗ trợ bạn với phản hồi riêng SENSITIVE_CHAT_RESPONSE_41723.';
      final service = AIChatService(
        modelNames: const ['fake-model'],
        textGenerator: ({required modelName, required message}) async =>
            response,
      );

      final logs = await _captureDebugPrint(() async {
        expect(await service.sendMessage(message), response);
      });
      final joined = logs.join('\n');

      expect(joined, contains('messageLength'));
      expect(joined, contains('textLength'));
      expect(joined, contains(AITraceLogger.aiGen));
      expect(joined, isNot(contains(message)));
      expect(joined, isNot(contains(response)));
      expect(joined, isNot(contains('SENSITIVE_CHAT_RESPONSE_41723')));
    });

    test('uses cheap default chat model and returns valid AI text', () async {
      final modelCalls = <String>[];
      final service = AIChatService(
        textGenerator: ({required modelName, required message}) async {
          modelCalls.add(modelName);
          return 'Mình sẽ giúp bạn bắt đầu nhẹ nhàng. Bạn thử uống thêm nước và nghỉ vài phút nhé.';
        },
      );

      final result = await service.sendMessage('Tôi hơi mệt');

      expect(result, contains('Mình sẽ giúp'));
      expect(modelCalls, ['gemini-3.1-flash-lite']);
    });

    test('fails over to the next cheap model after transient errors', () async {
      final modelCalls = <String>[];
      final delays = <Duration>[];
      final service = AIChatService(
        modelNames: const ['primary-model', 'fallback-model'],
        random: Random(0),
        delay: (duration) async {
          delays.add(duration);
        },
        textGenerator: ({required modelName, required message}) async {
          modelCalls.add(modelName);
          if (modelName == 'primary-model') {
            throw TimeoutException('temporary overload');
          }
          return 'Mình gợi ý bạn nghỉ một chút, uống nước và theo dõi cơ thể nhé.';
        },
      );

      final result = await service.sendMessage('Tôi căng thẳng');

      expect(result, contains('Mình gợi ý'));
      expect(modelCalls, ['primary-model', 'fallback-model']);
      expect(delays, hasLength(1));
    });

    test('returns local fallback when all transient attempts fail', () async {
      final modelCalls = <String>[];
      final service = AIChatService(
        modelNames: const ['primary-model', 'fallback-model'],
        delay: (_) async {},
        textGenerator: ({required modelName, required message}) async {
          modelCalls.add(modelName);
          throw TimeoutException('temporary overload');
        },
      );

      final result = await service.sendMessage('Tôi cần tư vấn');

      expect(modelCalls, ['primary-model', 'fallback-model']);
      expect(result, contains('Mình chưa thể phản hồi bằng AI'));
    });

    test(
      'retries another model after empty or invalid Vietnamese response',
      () async {
        final modelCalls = <String>[];
        final service = AIChatService(
          modelNames: const ['empty-model', 'invalid-model', 'valid-model'],
          textGenerator: ({required modelName, required message}) async {
            modelCalls.add(modelName);
            if (modelName == 'empty-model') return '';
            if (modelName == 'invalid-model') {
              return 'You should drink more water and sleep earlier.';
            }
            return 'Mình nghĩ bạn nên uống thêm nước và ngủ sớm hơn một chút nhé.';
          },
        );

        final result = await service.sendMessage('Nên làm gì hôm nay?');

        expect(result, contains('Mình nghĩ'));
        expect(modelCalls, ['empty-model', 'invalid-model', 'valid-model']);
      },
    );

    test('missing API key throws without retrying models', () async {
      final logs = await _captureDebugPrint(() async {
        final service = AIChatService(
          apiKeyOverride: '',
          modelNames: const ['fake-model'],
        );

        await expectLater(
          service.sendMessage('Xin chào'),
          throwsA(isA<AIConfigurationUnavailableException>()),
        );
      });
      final joined = logs.join('\n');

      expect(joined, contains('MISSING_API_KEY'));
      expect(joined, contains('missing_api_key'));
      expect(joined, isNot(contains('RETRY_ATTEMPT_START')));
      expect(joined, isNot(contains('RETRY_ATTEMPT_FAILED')));
      expect(joined, isNot(contains('RETRY_EXHAUSTED')));
      expect(joined, isNot(contains('StateError')));
      expect(joined, isNot(contains('AIza')));
    });

    test(
      'missing API key without dotenv or model override throws safely',
      () async {
        final logs = await _captureDebugPrint(() async {
          final service = AIChatService(
            apiKeyOverride: '',
            delay: (_) async {},
          );

          await expectLater(
            service.sendMessage('Xin chào'),
            throwsA(isA<AIConfigurationUnavailableException>()),
          );
        });

        expect(logs.join('\n'), contains('MISSING_API_KEY'));
        expect(logs.join('\n'), isNot(contains('StateError')));
      },
    );

    test(
      'sendMessageStream uses the same retry and fallback behavior',
      () async {
        final modelCalls = <String>[];
        final service = AIChatService(
          modelNames: const ['primary-model', 'fallback-model'],
          delay: (_) async {},
          textGenerator: ({required modelName, required message}) async {
            modelCalls.add(modelName);
            if (modelName == 'primary-model') {
              throw TimeoutException('temporary overload');
            }
            return 'Mình đang ở đây để hỗ trợ bạn từng bước nhỏ nhé.';
          },
        );

        final stream = await service.sendMessageStream('Tôi cần hỗ trợ');
        final result = await stream.join();

        expect(result, contains('Mình đang ở đây'));
        expect(modelCalls, ['primary-model', 'fallback-model']);
      },
    );

    test(
      'sendMessageStream throws without retry when API key is missing',
      () async {
        final logs = await _captureDebugPrint(() async {
          final service = AIChatService(
            apiKeyOverride: '',
            modelNames: const ['fake-model'],
          );

          await expectLater(
            service.sendMessageStream('Xin chào'),
            throwsA(isA<AIConfigurationUnavailableException>()),
          );
        });
        final joined = logs.join('\n');

        expect(joined, contains('MISSING_API_KEY'));
        expect(joined, isNot(contains('RETRY_ATTEMPT_START')));
        expect(joined, isNot(contains('StateError')));
      },
    );
  });

  group('AIService chunked generation', () {
    test('meal generation requests seven days in one chunk', () async {
      final prompts = <String>[];
      final service = AIService(
        modelNames: const ['fake-model'],
        catalogLoader: () async => catalog,
        textGenerator: ({required modelName, required prompt}) async {
          prompts.add(prompt);
          return jsonEncode(_mealItemsForRange(startDay: 1, days: 7));
        },
      );

      final meals = await service.generateMealPlan(
        healthData: const _FakeHealthData(),
        userId: 'u1',
        startDate: DateTime(2026, 6, 18),
      );

      expect(meals, hasLength(35));
      expect(prompts, hasLength(1));
      expect(prompts.single, contains('ngày 1 đến ngày 7'));
      expect(prompts.single, contains('br_oat_egg'));
    });

    test(
      'meal generation logs metadata without prompt, response, or health data',
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
        expect(joined, contains('REQUEST_SENT'));
        expect(joined, contains('RESPONSE_RECEIVED'));
        expect(joined, contains('promptLength'));
        expect(joined, contains('responseLength'));
        expect(joined, contains('durationMs'));
        expect(joined, contains('MEAL_CHUNK_SUCCESS'));
        expect(joined, contains('source'));
        expect(joined, contains(AITraceLogger.aiGen));
        expect(joined, isNot(contains('PROMPT_SENT')));
        expect(joined, isNot(contains('RAW_RESPONSE')));
        expect(joined, isNot(contains(rawResponse)));
        expect(joined, isNot(contains(const _FakeHealthData().fullName)));
        expect(joined, isNot(contains(const _FakeHealthData().concernText)));
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
              {'day': 8, 'meal_type': 'breakfast', 'meal_code': 'unknown_meal'},
            ]);
          }
          return jsonEncode(
            call == 1
                ? _mealItemsForRange(startDay: 1, days: 7)
                : _mealItemsForRange(startDay: 8, days: 1),
          );
        },
      );

      final meals = await service.generateMealPlan(
        healthData: const _FakeHealthData(),
        userId: 'u1',
        startDate: DateTime(2026, 6, 18),
        days: 8,
      );

      expect(meals, hasLength(40));
      expect(
        meals.where((meal) => meal.planDate == '2026-06-25'),
        hasLength(MealPlanAiNormalizer.mealsPerDay),
      );
      expect(meals.map((meal) => meal.mealName), isNot(contains('Bua sang')));
    });

    test('meal generation logs redacted error type and local source', () async {
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
      expect(joined, contains('errorType'));
      expect(joined, contains('FormatException'));
      expect(joined, contains(AITraceLogger.localGen));
      expect(joined, contains('MEAL_LOCAL_FALLBACK_READY'));
      expect(joined, isNot(contains('Unknown meal_code')));
      expect(joined, isNot(contains('unknown_meal')));
      expect(joined, isNot(contains('StackTrace')));
    });

    test('transient errors fail over to the next model', () async {
      final modelCalls = <String>[];
      final delays = <Duration>[];
      final service = AIService(
        modelNames: const ['primary-model', 'fallback-model'],
        catalogLoader: () async => catalog,
        random: Random(0),
        delay: (duration) async {
          delays.add(duration);
        },
        textGenerator: ({required modelName, required prompt}) async {
          modelCalls.add(modelName);
          if (modelName == 'primary-model') {
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

      expect(modelCalls, ['primary-model', 'fallback-model']);
      expect(delays, hasLength(1));
      expect(joined, contains('RETRY_ATTEMPT_FAILED'));
      expect(joined, contains('"modelAttempt":1'));
      expect(joined, contains('"totalAttempt":1'));
      expect(joined, contains('"transient":true'));
      expect(joined, contains('RETRY_DELAY'));
      expect(joined, contains('delayMs'));
    });

    test('models in cooldown are skipped on later chunks', () async {
      final now = DateTime(2026, 6, 18, 8);
      final modelCalls = <String>[];
      final service = AIService(
        modelNames: const ['primary-model', 'fallback-model'],
        catalogLoader: () async => catalog,
        now: () => now,
        modelCooldown: const Duration(minutes: 3),
        delay: (_) async {},
        textGenerator: ({required modelName, required prompt}) async {
          modelCalls.add(modelName);
          if (modelName == 'primary-model') {
            throw TimeoutException('temporary overload');
          }
          return jsonEncode(
            modelCalls.length == 2
                ? _mealItemsForRange(startDay: 1, days: 7)
                : _mealItemsForRange(startDay: 8, days: 1),
          );
        },
      );

      final logs = await _captureDebugPrint(() async {
        final meals = await service.generateMealPlan(
          healthData: const _FakeHealthData(),
          userId: 'u1',
          startDate: DateTime(2026, 6, 18),
          days: 8,
        );
        expect(meals, hasLength(40));
      });

      expect(modelCalls, ['primary-model', 'fallback-model', 'fallback-model']);
      expect(logs.join('\n'), contains('MODEL_COOLDOWN_SKIP'));
    });

    test('all transient model failures use local fallback', () async {
      final modelCalls = <String>[];
      final service = AIService(
        modelNames: const ['primary-model', 'fallback-model'],
        catalogLoader: () async => catalog,
        delay: (_) async {},
        textGenerator: ({required modelName, required prompt}) async {
          modelCalls.add(modelName);
          throw TimeoutException('temporary overload');
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

      expect(modelCalls, ['primary-model', 'fallback-model']);
      expect(logs.join('\n'), contains('MEAL_CHUNK_LOCAL_FALLBACK'));
      expect(logs.join('\n'), contains(AITraceLogger.localGen));
    });

    test(
      'missing runtime API key uses local meal fallback instead of crashing',
      () async {
        final logs = await _captureDebugPrint(() async {
          final service = AIService(
            apiKeyOverride: '',
            modelNames: const ['fake-model'],
            catalogLoader: () async => catalog,
            delay: (_) async {},
          );

          final meals = await service.generateMealPlan(
            healthData: const _FakeHealthData(),
            userId: 'u1',
            startDate: DateTime(2026, 6, 18),
            days: 1,
          );

          expect(meals, hasLength(MealPlanAiNormalizer.mealsPerDay));
        });
        final joined = logs.join('\n');

        expect(joined, contains('MISSING_API_KEY'));
        expect(joined, contains('MEAL_CHUNK_LOCAL_FALLBACK'));
        expect(joined, contains(AITraceLogger.localGen));
        expect(joined, isNot(contains('AIza')));
        expect(joined, isNot(contains(const _FakeHealthData().fullName)));
      },
    );

    test('exercise generation returns fourteen catalog-mapped tasks', () async {
      final prompts = <String>[];
      final service = AIService(
        modelNames: const ['fake-model'],
        catalogLoader: () async => catalog,
        textGenerator: ({required modelName, required prompt}) async {
          prompts.add(prompt);
          return jsonEncode(_exerciseItemsForRange(startDay: 1, days: 7));
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
      expect(prompts, hasLength(1));
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
          [
            'gemini-3.1-flash-lite',
            'gemini-3.5-flash',
            'gemini-2.5-flash-lite',
            'gemini-2.5-flash',
          ],
        );
      },
    );

    test('prioritizes primary, fallback, overflow, and de-duplicates', () {
      expect(
        AIModelCandidates.resolve(
          primaryModel: ' gemini-custom ',
          fallbackModelsCsv:
              'gemini-3.5-flash, gemini-custom, gemini-2.5-flash, ',
          overflowModelsCsv:
              'gemini-3-flash-preview, gemini-2.5-flash, gemini-2.5-pro',
        ),
        [
          'gemini-custom',
          'gemini-3.5-flash',
          'gemini-2.5-flash',
          'gemini-3-flash-preview',
          'gemini-2.5-pro',
        ],
      );
    });

    test('uses default fallback when fallback csv is blank', () {
      expect(
        AIModelCandidates.resolve(
          primaryModel: 'gemini-custom',
          fallbackModelsCsv: ' , ',
        ),
        [
          'gemini-custom',
          'gemini-3.5-flash',
          'gemini-2.5-flash-lite',
          'gemini-2.5-flash',
        ],
      );
    });
  });

  group('AIRetryPolicy', () {
    test('classifies only transient errors as retryable with backoff', () {
      expect(
        AIRetryPolicy.isTransient(
          const GeminiApiException(
            statusCode: 503,
            status: 'UNAVAILABLE',
            message: 'This model is currently experiencing high demand.',
          ),
        ),
        isTrue,
      );
      expect(
        AIRetryPolicy.isTransient(
          const GeminiApiException(
            statusCode: 429,
            status: 'RESOURCE_EXHAUSTED',
            message: 'Resource has been exhausted.',
          ),
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

    test('uses short capped base delays', () {
      expect(
        AIRetryPolicy.baseDelayForFailureNumber(1),
        const Duration(seconds: 1),
      );
      expect(
        AIRetryPolicy.baseDelayForFailureNumber(2),
        const Duration(seconds: 3),
      );
      expect(
        AIRetryPolicy.baseDelayForFailureNumber(3),
        const Duration(seconds: 3),
      );
      expect(
        AIRetryPolicy.baseDelayForFailureNumber(4),
        const Duration(seconds: 3),
      );
      expect(
        AIRetryPolicy.baseDelayForFailureNumber(99),
        const Duration(seconds: 3),
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
