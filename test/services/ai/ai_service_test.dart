import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/interfaces/health_data_interface.dart';
import 'package:nano_app/core/storage/localdb/models/ai_catalog_models.dart';
import 'package:nano_app/core/storage/localdb/seeders/ai_catalog_seed_data.dart';
import 'package:nano_app/app_versions/v1/features/daily_health_tracking/domain/entities/daily_health_profile_entity.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/data/models/exercise_tasks_ai_normalizer.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/data/models/meal_plan_ai_normalizer.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_chat_service.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_exceptions.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_generation_result.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_json_parser.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_json_prompt_builder.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_service.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_trace_logger.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_vietnamese_text_validator.dart';
import 'package:nano_app/app_versions/v1/services/ai/gemini_rest_client.dart';
import 'package:nano_app/app_versions/v1/services/ai/prompts/exercise_tasks_prompt.dart';
import 'package:nano_app/app_versions/v1/services/ai/prompts/meal_plan_prompt.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  test('model token limit failures map to a clear user-facing error', () {
    const error = GeminiApiException(
      statusCode: 413,
      status: 'model_context_limit_exceeded',
      message: 'AI request exceeds the configured model context limit.',
    );
    expect(AIModelContextLimitException.matches(error), isTrue);
    expect(
      AIModelContextLimitException.userMessage,
      contains('giới hạn token của model'),
    );
  });

  test('request byte limit failures map to a clear user-facing error', () {
    const error = GeminiApiException(
      statusCode: 413,
      status: 'request_too_large',
      message: 'Request is above the transport size limit.',
    );
    expect(AIRequestTooLargeException.matches(error), isTrue);
    expect(
      AIRequestTooLargeException.userMessage,
      contains('giới hạn dung lượng request'),
    );
  });

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
        'Nabi đang bận. Bạn thử lại sau nhé.',
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
    test('meal prompt includes every SQLite code and name only', () {
      final prompt = MealPlanPrompt.generate(
        startDate: DateTime(2026, 6, 18),
        startDay: 1,
        days: 2,
        catalog: [
          _promptMeal(code: 'meal_prompt_active'),
          _promptMeal(code: 'meal_prompt_inactive', isActive: false),
        ],
        usedMealCodeCounts: const {'br_oat_egg': 1},
      );

      expect(prompt, contains('"meal_code"'));
      expect(prompt, contains('meal_prompt_active'));
      expect(
        prompt,
        contains(
          jsonEncode([
            {'code': 'meal_prompt_active', 'name': 'Yến mạch trứng'},
            {'code': 'meal_prompt_inactive', 'name': 'Yến mạch trứng'},
          ]),
        ),
      );
      expect(prompt, isNot(contains('Đào Văn Hùng')));
      expect(prompt, isNot(contains('user_id')));
      expect(prompt, isNot(contains('Dị ứng thực phẩm:')));
      expect(prompt, contains('meal_prompt_inactive'));
      expect(prompt, isNot(contains('"is_plan_eligible":')));
      expect(prompt, isNot(contains('"cooking_instructions":')));
      expect(prompt, contains('không tự tạo món hoặc mã mới'));
      expect(prompt, contains('Chỉ trả day, meal_type và meal_code'));
      expect(prompt, isNot(_containsMojibake));
    });

    test('exercise prompt splits code/name rows by selection status', () {
      final prompt = ExerciseTasksPrompt.generate(
        startDate: DateTime(2026, 6, 18),
        startDay: 3,
        days: 2,
        catalog: [
          _promptExercise(code: 'ex_prompt_active'),
          _promptExercise(code: 'ex_prompt_inactive', isActive: false),
        ],
        usedExerciseCodeCounts: const {'ex_walk_relaxed': 1},
        availableTimeWindows: const [
          {'day': '3', 'start': '08:00', 'end': '08:30'},
        ],
      );

      expect(prompt, contains('"exercise_code"'));
      expect(prompt, contains('ex_prompt_active'));
      expect(prompt, contains('"selectable"'));
      expect(prompt, contains('"context_only"'));
      expect(prompt, contains('"name":"Đi bộ thư giãn"'));
      expect(prompt, isNot(contains('"description":')));
      expect(prompt, isNot(contains('08:30')));
      expect(prompt, isNot(contains('Đào Văn Hùng')));
      expect(prompt, isNot(contains('Đau lưng nhẹ')));
      expect(prompt, contains('ex_prompt_inactive'));
      expect(prompt, isNot(contains('"encouragement":')));
      expect(prompt, contains('Không tạo mã mới;'));
      expect(prompt, contains('chỉ trả day và exercise_code'));
      expect(prompt, isNot(_containsMojibake));
    });

    test('meal prompt includes every provided row exactly once', () {
      final prompt = MealPlanPrompt.generate(
        startDate: DateTime(2026, 6, 18),
        startDay: 1,
        days: 1,
        catalog: [
          for (var index = 1; index <= 11; index++)
            _promptMeal(code: 'candidate-${index.toString().padLeft(2, '0')}'),
        ],
        usedMealCodeCounts: const {},
      );

      expect(prompt, contains('candidate-10'));
      expect(prompt, contains('candidate-11'));
      expect(_countOccurrences(prompt, '"code":"candidate-10"'), 1);
      expect(_countOccurrences(prompt, '"code":"candidate-11"'), 1);
    });

    test(
      'production meal prompt includes all 163 SQLite code/name pairs',
      () async {
        final decoded =
            jsonDecode(
                  await rootBundle.loadString(
                    'assets/data/meal_catalog_v1.json',
                  ),
                )
                as Map<String, dynamic>;
        final sourceRows = decoded['recipes'] as List;
        final meals = sourceRows
            .whereType<Map>()
            .map(
              (row) => MealCatalogItemModel.fromSourceJson(
                Map<String, Object?>.from(row),
                timestamp: '2026-06-18T00:00:00Z',
              ),
            )
            .toList(growable: false);
        final prompt = MealPlanPrompt.generate(
          startDate: DateTime(2026, 6, 18),
          startDay: 1,
          days: 1,
          catalog: meals,
          usedMealCodeCounts: const {},
        );
        expect(meals, hasLength(163));
        expect(meals.where((meal) => meal.isActive), hasLength(163));
        final catalogPayload = [
          for (final meal in meals) {'code': meal.code, 'name': meal.mealName},
        ];
        expect(prompt, contains(jsonEncode(catalogPayload)));
        expect(
          catalogPayload.map((row) => row['code']).toSet(),
          hasLength(163),
        );
        expect(
          catalogPayload.every(
            (row) =>
                row.keys.toSet().containsAll({'code', 'name'}) &&
                row.length == 2,
          ),
          isTrue,
        );
        for (final row in catalogPayload) {
          expect(_countOccurrences(prompt, '"code":"${row['code']}"'), 1);
        }
      },
    );

    test('exercise prompt sends all 16 active and 24 context-only records', () {
      final exercises = [
        for (var index = 1; index <= 40; index++)
          _promptExercise(
            code: 'exercise-${index.toString().padLeft(2, '0')}',
            isActive: index <= 16,
          ),
      ];
      final prompt = ExerciseTasksPrompt.generate(
        startDate: DateTime(2026, 6, 18),
        startDay: 1,
        days: 1,
        catalog: exercises,
        usedExerciseCodeCounts: const {},
      );

      final selectable = exercises
          .where((item) => item.isActive)
          .map((item) => {'code': item.code, 'name': item.title})
          .toList(growable: false);
      final contextOnly = exercises
          .where((item) => !item.isActive)
          .map((item) => {'code': item.code, 'name': item.title})
          .toList(growable: false);
      expect(selectable, hasLength(16));
      expect(contextOnly, hasLength(24));
      expect(
        prompt,
        contains(
          jsonEncode({'selectable': selectable, 'context_only': contextOnly}),
        ),
      );
      for (final item in exercises) {
        expect(_countOccurrences(prompt, '"code":"${item.code}"'), 1);
      }
    });

    test('meal prompt does not trim a row over 32,000 characters', () {
      final oversizedMeal = MealCatalogItemModel(
        code: 'oversized',
        mealType: 'unclassified',
        mealName: List.filled(33000, 'x').join(),
        description: '',
        cookingInstructions: '',
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
        fiber: 0,
        waterMl: 0,
        createdAt: '2026-06-18T00:00:00Z',
        updatedAt: '2026-06-18T00:00:00Z',
      );

      final prompt = MealPlanPrompt.generate(
        startDate: DateTime(2026, 6, 18),
        startDay: 1,
        days: 1,
        catalog: [oversizedMeal],
        usedMealCodeCounts: const {},
      );
      expect(prompt.length, greaterThan(32000));
      expect(prompt, contains('"code":"oversized"'));
    });

    test('AI service sends request content above 32,000 characters', () async {
      final meals = _longNameMealCatalog();
      final prompt = MealPlanPrompt.generate(
        startDate: DateTime(2026, 6, 18),
        startDay: 1,
        days: 1,
        catalog: meals,
        usedMealCodeCounts: const {},
      );
      expect(prompt.length, greaterThan(32000));

      var modelCalls = 0;
      final service = AIService(
        modelNames: const ['fake-model'],
        catalogLoader: () async => AiCatalogBundle(
          meals: meals,
          exercises: const [],
          scheduleTasks: const [],
        ),
        textGenerator: ({required modelName, required prompt}) async {
          modelCalls++;
          return jsonEncode([
            for (final slot in MealPlanAiNormalizer.mealSlots)
              {
                'day': 1,
                'meal_type': slot.type,
                'meal_code': 'large-${slot.type}',
              },
          ]);
        },
      );

      final result = await service.generateMealPlanWithSource(
        healthData: const _FakeHealthData(),
        userId: 'u1',
        startDate: DateTime(2026, 6, 18),
        days: 1,
      );
      expect(result.value, hasLength(5));
      expect(modelCalls, 1);
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
      expect(
        AIVietnameseTextValidator.isValidDisplayText(
          'ĐÃ SẴN SÀNG CHĂM SÓC SỨC KHỎE',
        ),
        isTrue,
      );
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

    test('throws typed failure when all transient attempts fail', () async {
      final modelCalls = <String>[];
      final service = AIChatService(
        modelNames: const ['primary-model', 'fallback-model'],
        delay: (_) async {},
        textGenerator: ({required modelName, required message}) async {
          modelCalls.add(modelName);
          throw TimeoutException('temporary overload');
        },
      );

      await expectLater(
        service.sendMessage('Tôi cần tư vấn'),
        throwsA(isA<AIOverloadedException>()),
      );

      expect(modelCalls, ['primary-model', 'fallback-model']);
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

    test(
      'throws a typed invalid response instead of a local chat reply',
      () async {
        final service = AIChatService(
          modelNames: const ['empty-model', 'invalid-model'],
          textGenerator: ({required modelName, required message}) async {
            return modelName == 'empty-model'
                ? ''
                : 'This response is not valid Vietnamese.';
          },
        );

        final logs = await _captureDebugPrint(() async {
          await expectLater(
            service.sendMessage('Tôi cần hỗ trợ'),
            throwsA(isA<AIResponseInvalidException>()),
          );
        });

        final joined = logs.join('\n');
        expect(joined, contains('RETRY_ATTEMPT_INVALID_RESPONSE'));
        expect(joined, contains('ERROR_TYPED_FAILURE'));
        expect(joined, isNot(contains('LOCAL_FALLBACK')));
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
    test('meal day API requests exactly one five-meal code list', () async {
      final prompts = <String>[];
      var backendInvocations = 0;
      final service = AIService(
        modelNames: const ['fake-model'],
        catalogLoader: () async => catalog,
        textGenerator: ({required modelName, required prompt}) async {
          prompts.add(prompt);
          return jsonEncode(_mealItemsForRange(startDay: 3, days: 1));
        },
      );

      final items = await service.generateMealDayCodeItems(
        startDate: DateTime(2026, 6, 18),
        day: 3,
        catalog: catalog,
        usedCodeCounts: const {'br_oat_egg': 1},
        onBackendInvocation: () async => backendInvocations++,
      );

      expect(items, hasLength(5));
      expect(items.every((item) => item['day'] == 3), isTrue);
      expect(
        items.every(
          (item) =>
              item.keys.toSet().containsAll({
                'day',
                'meal_type',
                'meal_code',
              }) &&
              item.length == 3,
        ),
        isTrue,
      );
      expect(backendInvocations, 1);
      expect(prompts.single, contains('ngày 3 đến ngày 3'));
      expect(prompts.single, contains('br_oat_egg'));
    });

    test('exercise day API requests exactly two exercise codes', () async {
      final prompts = <String>[];
      var backendInvocations = 0;
      final service = AIService(
        modelNames: const ['fake-model'],
        catalogLoader: () async => catalog,
        textGenerator: ({required modelName, required prompt}) async {
          prompts.add(prompt);
          return jsonEncode(_exerciseItemsForRange(startDay: 4, days: 1));
        },
      );

      final items = await service.generateExerciseDayCodeItems(
        startDate: DateTime(2026, 6, 18),
        day: 4,
        catalog: catalog,
        usedCodeCounts: const {},
        onBackendInvocation: () async => backendInvocations++,
      );

      expect(items, hasLength(2));
      expect(items.every((item) => item['day'] == 4), isTrue);
      expect(
        items.every(
          (item) =>
              item.keys.toSet().containsAll({'day', 'exercise_code'}) &&
              item.length == 2,
        ),
        isTrue,
      );
      expect(backendInvocations, 1);
      expect(prompts.single, contains('ngày 4 đến ngày 4'));
    });

    test(
      'meal day returns a validated local fallback for invalid AI output',
      () async {
        var backendInvocations = 0;
        final service = AIService(
          modelNames: const ['fake-model'],
          catalogLoader: () async => catalog,
          textGenerator: ({required modelName, required prompt}) async => '[]',
        );

        final result = await service.generateMealDayCodeItemsWithSource(
          startDate: DateTime(2026, 6, 18),
          day: 3,
          catalog: catalog,
          usedCodeCounts: const {},
          onBackendInvocation: () async => backendInvocations++,
        );

        expect(result.source, PlanGenerationSource.localFallback);
        expect(backendInvocations, AIRetryPolicy.maxAttemptsPerRequest);
        expect(result.value, hasLength(MealPlanAiNormalizer.mealsPerDay));
        expect(
          result.value.map((item) => item['meal_code']).toSet(),
          hasLength(5),
        );
        expect(result.value.every((item) => item['day'] == 3), isTrue);
        const MealPlanAiNormalizer().validateCodeItems(
          items: result.value,
          catalog: catalog,
          startDay: 3,
          days: 1,
          usedCodeCounts: const {},
        );
      },
    );

    test('invalid meal output escalates to the higher model', () async {
      final modelCalls = <String>[];
      final service = AIService(
        modelNames: const ['base-model', 'higher-model'],
        catalogLoader: () async => catalog,
        textGenerator: ({required modelName, required prompt}) async {
          modelCalls.add(modelName);
          return modelName == 'base-model'
              ? '[]'
              : jsonEncode(_mealItemsForRange(startDay: 3, days: 1));
        },
      );

      final result = await service.generateMealDayCodeItemsWithSource(
        startDate: DateTime(2026, 6, 18),
        day: 3,
        catalog: catalog,
        usedCodeCounts: const {},
        allowLocalFallback: false,
        onBackendInvocation: () async {},
      );

      expect(modelCalls, ['base-model', 'higher-model']);
      expect(result.source, PlanGenerationSource.ai);
      expect(result.value, hasLength(MealPlanAiNormalizer.mealsPerDay));
    });

    test('split meal generation validates one requested meal slot', () async {
      final slot = MealPlanAiNormalizer.mealSlots.first;
      final meal = catalog
          .mealsForType(slot.type)
          .firstWhere((candidate) => candidate.isActive);
      final service = AIService(
        modelNames: const ['fake-model'],
        catalogLoader: () async => catalog,
        textGenerator: ({required modelName, required prompt}) async {
          expect(prompt, contains('Chỉ tạo bữa ${slot.type}'));
          return jsonEncode([
            {'day': 2, 'meal_type': slot.type, 'meal_code': meal.code},
          ]);
        },
      );

      final result = await service.generateMealSlotCodeItemWithSource(
        startDate: DateTime(2026, 6, 18),
        day: 2,
        mealType: slot.type,
        catalog: catalog,
        usedCodeCounts: const {},
        dayMealCodes: const {},
        onBackendInvocation: () async {},
      );

      expect(result.source, PlanGenerationSource.ai);
      expect(result.value, [
        {'day': 2, 'meal_type': slot.type, 'meal_code': meal.code},
      ]);
    });

    test(
      'slot AI may use active catalog items outside local fallback subset',
      () async {
        final slot = MealPlanAiNormalizer.mealSlots.first;
        final meal = catalog
            .mealsForType(slot.type)
            .firstWhere((candidate) => candidate.isActive);
        final service = AIService(
          modelNames: const ['fake-model'],
          catalogLoader: () async => catalog,
          textGenerator: ({required modelName, required prompt}) async =>
              jsonEncode([
                {'day': 2, 'meal_type': slot.type, 'meal_code': meal.code},
              ]),
        );

        final result = await service.generateMealSlotCodeItemWithSource(
          startDate: DateTime(2026, 6, 18),
          day: 2,
          mealType: slot.type,
          catalog: catalog,
          usedCodeCounts: const {},
          dayMealCodes: const {},
          eligibleFallbackCodesByType: {slot.type: const {}},
          onBackendInvocation: () async {},
        );

        expect(result.source, PlanGenerationSource.ai);
        expect(result.value.single['meal_code'], meal.code);
      },
    );

    test(
      'split meal generation uses local choice after six failed AI calls',
      () async {
        var backendInvocations = 0;
        final service = AIService(
          modelNames: const ['fake-model'],
          catalogLoader: () async => catalog,
          textGenerator: ({required modelName, required prompt}) async => '[]',
        );

        final result = await service.generateMealSlotCodeItemWithSource(
          startDate: DateTime(2026, 6, 18),
          day: 2,
          mealType: 'breakfast',
          catalog: catalog,
          usedCodeCounts: const {},
          dayMealCodes: const {},
          onBackendInvocation: () async => backendInvocations++,
        );

        expect(backendInvocations, AIRetryPolicy.maxAttemptsPerRequest);
        expect(result.source, PlanGenerationSource.localFallback);
        expect(result.value, hasLength(1));
        expect(result.value.single['meal_type'], 'breakfast');
      },
    );

    test(
      'meal fallback fails when the eligible catalog has no unused meals',
      () async {
        final eligibleByType = {
          for (final slot in MealPlanAiNormalizer.mealSlots)
            slot.type: {
              AiCatalogSeedData.meals
                  .firstWhere((meal) => meal.mealType == slot.type)
                  .code,
            },
        };
        final usedCodeCounts = {
          for (final codes in eligibleByType.values)
            for (final code in codes) code: 2,
        };
        final service = AIService(
          modelNames: const ['fake-model'],
          catalogLoader: () async => catalog,
          textGenerator: ({required modelName, required prompt}) async => '[]',
        );

        await expectLater(
          service.generateMealDayCodeItemsWithSource(
            startDate: DateTime(2026, 6, 18),
            day: 4,
            catalog: catalog,
            usedCodeCounts: usedCodeCounts,
            eligibleFallbackCodesByType: eligibleByType,
            onBackendInvocation: () async {},
          ),
          throwsStateError,
        );
      },
    );

    test(
      'exercise day returns a validated local fallback after backend error',
      () async {
        final service = AIService(
          modelNames: const ['fake-model'],
          catalogLoader: () async => catalog,
          textGenerator: ({required modelName, required prompt}) async {
            throw const GeminiApiException(
              statusCode: 503,
              status: 'UNAVAILABLE',
              message: 'Provider unavailable.',
            );
          },
        );

        final result = await service.generateExerciseDayCodeItemsWithSource(
          startDate: DateTime(2026, 6, 18),
          day: 4,
          catalog: catalog,
          usedCodeCounts: const {},
          onBackendInvocation: () async {},
        );

        expect(result.source, PlanGenerationSource.localFallback);
        expect(result.value, hasLength(2));
        expect(
          result.value.map((item) => item['exercise_code']).toSet(),
          hasLength(2),
        );
        expect(result.value.every((item) => item['day'] == 4), isTrue);
        const ExerciseTasksAiNormalizer().validateCodeItems(
          items: result.value,
          catalog: catalog,
          startDay: 4,
          days: 1,
          usedCodeCounts: const {},
        );
      },
    );

    test(
      'exercise fallback applies repeat limits only to eligible exercises',
      () async {
        final eligibleCodes = AiCatalogSeedData.exercises
            .take(2)
            .map((exercise) => exercise.code)
            .toSet();
        final usedCodeCounts = {for (final code in eligibleCodes) code: 2};
        final service = AIService(
          modelNames: const ['fake-model'],
          catalogLoader: () async => catalog,
          textGenerator: ({required modelName, required prompt}) async {
            throw const GeminiApiException(
              statusCode: 503,
              status: 'UNAVAILABLE',
              message: 'Provider unavailable.',
            );
          },
        );

        final result = await service.generateExerciseDayCodeItemsWithSource(
          startDate: DateTime(2026, 6, 18),
          day: 5,
          catalog: catalog,
          usedCodeCounts: usedCodeCounts,
          eligibleFallbackCodes: eligibleCodes,
          onBackendInvocation: () async {},
        );

        expect(result.source, PlanGenerationSource.localFallback);
        expect(
          result.value.map((item) => item['exercise_code']).toSet(),
          eligibleCodes,
        );
      },
    );

    test('day API retries HTTP 429 using the higher model', () async {
      final modelCalls = <String>[];
      var backendInvocations = 0;
      final service = AIService(
        modelNames: const ['first-model', 'fallback-model'],
        catalogLoader: () async => catalog,
        delay: (_) async {},
        textGenerator: ({required modelName, required prompt}) async {
          modelCalls.add(modelName);
          throw const GeminiApiException(
            statusCode: 429,
            status: 'RESOURCE_EXHAUSTED',
            message: 'Rate limit exceeded.',
          );
        },
      );

      await expectLater(
        service.generateMealDayCodeItems(
          startDate: DateTime(2026, 6, 18),
          day: 1,
          catalog: catalog,
          usedCodeCounts: const {},
          onBackendInvocation: () async => backendInvocations++,
        ),
        throwsA(isA<AIOverloadedException>()),
      );
      expect(modelCalls, [
        'first-model',
        'fallback-model',
        'fallback-model',
        'fallback-model',
        'fallback-model',
        'fallback-model',
      ]);
      expect(backendInvocations, AIRetryPolicy.maxAttemptsPerRequest);
    });

    test('missing meal catalog fails before making an AI request', () async {
      var requestCount = 0;
      final service = AIService(
        modelNames: const ['fake-model'],
        catalogLoader: () async =>
            const AiCatalogBundle(meals: [], exercises: [], scheduleTasks: []),
        textGenerator: ({required modelName, required prompt}) async {
          requestCount++;
          return '[]';
        },
      );

      await expectLater(
        service.generateMealPlan(
          healthData: const _FakeHealthData(),
          userId: 'u1',
          startDate: DateTime(2026, 6, 18),
        ),
        throwsStateError,
      );
      expect(requestCount, 0);
    });

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

    test(
      'meal generation stops when any chunk has an invalid response',
      () async {
        var call = 0;
        final service = AIService(
          modelNames: const ['fake-model'],
          catalogLoader: () async => catalog,
          textGenerator: ({required modelName, required prompt}) async {
            call++;
            if (call == 2) {
              return jsonEncode([
                {
                  'day': 8,
                  'meal_type': 'breakfast',
                  'meal_code': 'unknown_meal',
                },
              ]);
            }
            return jsonEncode(
              call == 1
                  ? _mealItemsForRange(startDay: 1, days: 7)
                  : _mealItemsForRange(startDay: 8, days: 1),
            );
          },
        );

        await expectLater(
          service.generateMealPlanWithSource(
            healthData: const _FakeHealthData(),
            userId: 'u1',
            startDate: DateTime(2026, 6, 18),
            days: 8,
          ),
          throwsFormatException,
        );
        expect(call, 2);
      },
    );

    test('invalid meal code fails without a local substitute', () async {
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
        await expectLater(
          service.generateMealPlan(
            healthData: const _FakeHealthData(),
            userId: 'u1',
            startDate: DateTime(2026, 6, 18),
            days: 1,
          ),
          throwsFormatException,
        );
      });
      final joined = logs.join('\n');

      expect(joined, contains('MEAL_CHUNK_FAILED'));
      expect(joined, contains('errorType'));
      expect(joined, contains('FormatException'));
      expect(joined, isNot(contains('MEAL_CHUNK_LOCAL_FALLBACK')));
      expect(joined, isNot(contains(AITraceLogger.localGen)));
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

    test('all transient model failures stop plan generation', () async {
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

      await expectLater(
        service.generateMealPlan(
          healthData: const _FakeHealthData(),
          userId: 'u1',
          startDate: DateTime(2026, 6, 18),
          days: 1,
        ),
        throwsA(isA<AIOverloadedException>()),
      );

      expect(modelCalls, [
        'primary-model',
        'fallback-model',
        'fallback-model',
        'fallback-model',
        'fallback-model',
        'fallback-model',
      ]);
    });

    test(
      'missing runtime API key fails without a local meal substitute',
      () async {
        final logs = await _captureDebugPrint(() async {
          final service = AIService(
            apiKeyOverride: '',
            modelNames: const ['fake-model'],
            catalogLoader: () async => catalog,
            delay: (_) async {},
          );

          await expectLater(
            service.generateMealPlan(
              healthData: const _FakeHealthData(),
              userId: 'u1',
              startDate: DateTime(2026, 6, 18),
              days: 1,
            ),
            throwsA(isA<AIConfigurationUnavailableException>()),
          );
        });
        final joined = logs.join('\n');

        expect(joined, contains('MISSING_API_KEY'));
        expect(joined, isNot(contains('MEAL_CHUNK_LOCAL_FALLBACK')));
        expect(joined, isNot(contains(AITraceLogger.localGen)));
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
          ['gemini-2.5-flash', 'gemini-3.8-flash'],
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
          'gemini-3.8-flash',
        ],
      );
    });

    test('uses default fallback when fallback csv is blank', () {
      expect(
        AIModelCandidates.resolve(
          primaryModel: 'gemini-custom',
          fallbackModelsCsv: ' , ',
        ),
        ['gemini-custom', 'gemini-3.8-flash'],
      );
    });
  });

  group('AIChatModelCandidates', () {
    test('includes the verified Flash fallback when chat env is absent', () {
      expect(
        AIChatModelCandidates.resolve(
          primaryModel: null,
          fallbackModelsCsv: null,
        ),
        ['gemini-3.1-flash-lite', 'gemini-3.5-flash'],
      );
    });

    test('uses an explicit chat fallback list without adding defaults', () {
      expect(
        AIChatModelCandidates.resolve(
          primaryModel: 'chat-primary',
          fallbackModelsCsv: 'chat-secondary, chat-primary',
        ),
        ['chat-primary', 'chat-secondary'],
      );
    });
  });

  group('AIRetryPolicy', () {
    test(
      'allows one initial request and five retries per generation chunk',
      () {
        expect(AIRetryPolicy.maxAttemptsPerRequest, 6);
      },
    );

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

int _countOccurrences(String value, String match) =>
    match.isEmpty ? 0 : value.split(match).length - 1;

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

MealCatalogItemModel _promptMeal({required String code, bool isActive = true}) {
  return MealCatalogItemModel(
    code: code,
    mealType: 'unclassified',
    mealName: 'Yến mạch trứng',
    description: 'Bữa ăn thử',
    cookingInstructions: 'Không gửi nội dung này',
    calories: 420,
    protein: 21,
    carbs: 50,
    fat: 10,
    fiber: 7,
    waterMl: 250,
    healthTopicCode: 'healthy-eating',
    healthTopicName: 'Ăn uống cân bằng',
    healthTopicDescription: 'Chủ đề dinh dưỡng',
    ingredients: const ['yến mạch 40 g', 'trứng 1 quả'],
    servingSize: '1 bát',
    allergenTags: const ['trứng'],
    avoidConditionTags: const ['đái tháo đường'],
    nutritionStatus: 'estimated_from_ingredients',
    constraintMetadataStatus: 'awaiting_professional_review',
    metadataStatus: 'source_imported',
    isPlanEligible: false,
    sourceHash: 'sha256-test',
    isActive: isActive,
    createdAt: '2026-06-18T00:00:00Z',
    updatedAt: '2026-06-18T00:00:00Z',
  );
}

ExerciseCatalogItemModel _promptExercise({
  required String code,
  bool isActive = true,
}) {
  return ExerciseCatalogItemModel(
    code: code,
    category: 'cardio',
    title: 'Đi bộ thư giãn',
    description: 'Đi bộ nhẹ quanh nhà',
    unit: 'phút',
    encouragement: 'Không gửi nội dung này',
    minTarget: 10,
    maxTarget: 45,
    defaultTarget: 25,
    intensityLevel: 'light',
    isActive: isActive,
    createdAt: '2026-06-18T00:00:00Z',
    updatedAt: '2026-06-18T00:00:00Z',
  );
}

List<MealCatalogItemModel> _longNameMealCatalog() => [
  for (final slot in MealPlanAiNormalizer.mealSlots)
    MealCatalogItemModel(
      code: 'large-${slot.type}',
      mealType: slot.type,
      mealName: List.filled(7000, 'x').join(),
      description: '',
      cookingInstructions: '',
      calories: 0,
      protein: 0,
      carbs: 0,
      fat: 0,
      fiber: 0,
      waterMl: 0,
      createdAt: '2026-06-18T00:00:00Z',
      updatedAt: '2026-06-18T00:00:00Z',
    ),
];

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
      },
      {
        'day': day,
        'exercise_code':
            AiCatalogSeedData.exercises[(((day - 1) * 2) + 1) % 16].code,
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
