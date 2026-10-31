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
import 'package:nano_app/app_versions/v1/services/ai/ai_text_client.dart';
import 'package:nano_app/core/network/backend_ai_text_client.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_trace_logger.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_vietnamese_text_validator.dart';
import 'package:nano_app/app_versions/v1/services/ai/prompts/exercise_tasks_prompt.dart';
import 'package:nano_app/app_versions/v1/services/ai/prompts/meal_plan_prompt.dart';
import 'package:nano_app/core/utils/logger/terminal_log_sink.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'generic backend inference failures are not treated as auth failures',
    () {
      const error = AiInferenceException(
        status: 'model_unavailable',
        message: 'Dịch vụ AI chưa khả dụng.',
      );

      expect(AIAuthenticationException.matches(error), isFalse);
    },
  );

  test('model token limit failures map to a clear user-facing error', () {
    const error = AiInferenceException(
      status: 'model_context_limit_exceeded',
      message: 'Nội dung vượt quá giới hạn model.',
    );
    expect(AIModelContextLimitException.matches(error), isTrue);
    expect(
      AIModelContextLimitException.userMessage,
      contains('giới hạn model đã chọn'),
    );
  });

  test('request byte limit failures map to a clear user-facing error', () {
    const error = AiInferenceException(
      status: 'request_too_large',
      message: 'Prompt quá lớn.',
    );
    expect(AIRequestTooLargeException.matches(error), isTrue);
    expect(
      AIRequestTooLargeException.userMessage,
      contains('giới hạn xử lý của model'),
    );
  });

  const catalog = AiCatalogBundle(
    meals: AiCatalogSeedData.meals,
    exercises: AiCatalogSeedData.exercises,
    scheduleTasks: AiCatalogSeedData.scheduleTasks,
  );

  group('AIOverloadedException', () {
    test('matches backend capacity errors and timeouts', () {
      expect(
        AIOverloadedException.matches(
          const AiInferenceException(
            status: 'runtime_busy',
            message: 'Model is busy.',
          ),
        ),
        isTrue,
      );
      expect(
        AIOverloadedException.matches(
          const AiInferenceException(
            status: 'runtime_error',
            message: 'Backend inference is temporarily unavailable.',
          ),
        ),
        isTrue,
      );
      expect(
        AIOverloadedException.matches(
          TimeoutException('Backend inference timed out'),
        ),
        isTrue,
      );
      expect(
        AIOverloadedException.matches(
          const AiInferenceException(
            status: 'runtime_error',
            message: 'Backend inference error.',
          ),
        ),
        isTrue,
      );
      expect(
        AIOverloadedException.matches(
          const AiInferenceException(
            status: 'model_unavailable',
            message: 'Backend model is unavailable.',
          ),
        ),
        isFalse,
      );
      expect(
        AIOverloadedException.matches(
          const AiInferenceException(
            status: 'network_error',
            message: 'Network unavailable.',
          ),
        ),
        isFalse,
      );
      expect(
        AIOverloadedException.matches(
          const AiInferenceException(
            status: 'membership_required',
            message: 'Membership quota is unavailable.',
          ),
        ),
        isFalse,
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

    test('unwraps the constrained JSON items envelope', () {
      expect(AIJsonParser.decodeArray('{"items":[{"day":2}]}'), [
        {'day': 2},
      ]);
    });

    test('throws when response does not contain an items array', () {
      expect(
        () => AIJsonParser.decodeArray('{"day": 1}'),
        throwsA(
          isA<AIJsonParseException>().having(
            (error) => error.code,
            'code',
            'invalid_items_envelope',
          ),
        ),
      );
    });

    test('classifies malformed JSON without preserving response text', () {
      expect(
        () => AIJsonParser.decodeArray('{"items":[}'),
        throwsA(
          isA<AIJsonParseException>().having(
            (error) => error.code,
            'code',
            'invalid_json_syntax',
          ),
        ),
      );
    });

    test('rejects prose around a JSON array', () {
      expect(
        () => AIJsonParser.decodeArray('Here is the result: [{"day":1}]'),
        throwsFormatException,
      );
    });
  });

  group('AI prompts', () {
    test('meal prompt includes only selectable SQLite code and name rows', () {
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
          ]),
        ),
      );
      expect(prompt, isNot(contains('nutrition_summary')));
      expect(prompt, isNot(contains('Đào Văn Hùng')));
      expect(prompt, isNot(contains('user_id')));
      expect(prompt, isNot(contains('Dị ứng thực phẩm:')));
      expect(prompt, isNot(contains('meal_prompt_inactive')));
      expect(prompt, isNot(contains('"is_plan_eligible":')));
      expect(prompt, isNot(contains('"cooking_instructions":')));
      expect(prompt, contains('Never invent codes'));
      expect(prompt, contains('meal_type'));
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

      expect(prompt, contains('exercise_code'));
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
      expect(prompt, contains('Do not invent codes'));
      expect(prompt, isNot(_containsMojibake));
    });

    test('meal prompt includes every selectable provided row exactly once', () {
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
      'local meal prompt keeps a small fresh shortlist for each generated day',
      () async {
        const marker = 'Candidates (JSON):\n';
        final candidateCodesByDay = <int, Map<String, List<String>>>{};
        final client = _CapturingAiTextClient(
          response: '',
          responseBuilder: (messages) {
            final prompt = messages.single.text;
            final day = int.parse(
              RegExp(r'Days (\d+)-').firstMatch(prompt)!.group(1)!,
            );
            final catalogStart = prompt.lastIndexOf(marker);
            final rows =
                jsonDecode(
                      prompt.substring(catalogStart + marker.length).trim(),
                    )
                    as List;
            final codeByType = <String, String>{};
            final codesByType = <String, List<String>>{};
            for (final row in rows.cast<Map<String, dynamic>>()) {
              final type = row['meal_type']?.toString();
              final code = row['code']?.toString();
              if (type != null && code != null) {
                codeByType.putIfAbsent(type, () => code);
                codesByType.putIfAbsent(type, () => []).add(code);
              }
            }
            candidateCodesByDay[day] = codesByType;
            return jsonEncode({
              'items': [
                for (final slot in MealPlanAiNormalizer.mealSlots)
                  codeByType[slot.type],
              ],
            });
          },
        );
        final eligibleCodesByType = {
          for (final slot in MealPlanAiNormalizer.mealSlots)
            slot.type: catalog.meals
                .where((meal) => meal.mealType == slot.type)
                .map((meal) => meal.code)
                .toSet(),
        };

        final service = AIService(aiClient: client);
        final firstDay = await service.generateMealDayCodeItemsWithSource(
          startDate: DateTime(2026, 10, 20),
          day: 1,
          catalog: catalog,
          usedCodeCounts: const {},
          eligibleFallbackCodesByType: eligibleCodesByType,
          onBackendInvocation: () async {},
        );
        final firstDayCodes = firstDay.value
            .map((item) => item['meal_code']! as String)
            .toSet();
        final secondDay = await service.generateMealDayCodeItemsWithSource(
          startDate: DateTime(2026, 10, 20),
          day: 2,
          catalog: catalog,
          usedCodeCounts: {for (final code in firstDayCodes) code: 1},
          eligibleFallbackCodesByType: eligibleCodesByType,
          onBackendInvocation: () async {},
        );

        expect(firstDay.source, PlanGenerationSource.ai);
        expect(firstDay.value, hasLength(MealPlanAiNormalizer.mealsPerDay));
        expect(secondDay.source, PlanGenerationSource.ai);
        expect(secondDay.value, hasLength(MealPlanAiNormalizer.mealsPerDay));
        expect(
          secondDay.value
              .map((item) => item['meal_code']! as String)
              .toSet()
              .intersection(firstDayCodes),
          isEmpty,
        );
        expect(
          client.messages.first.text,
          isNot(contains('nutrition_summary')),
        );
        for (final slot in MealPlanAiNormalizer.mealSlots) {
          final firstDayCount = candidateCodesByDay[1]![slot.type]!.length;
          final secondDayCodes = candidateCodesByDay[2]![slot.type]!;
          expect(firstDayCount, 2, reason: slot.type);
          expect(secondDayCodes.length, 2, reason: slot.type);
          expect(
            secondDayCodes.toSet().intersection(firstDayCodes),
            isEmpty,
            reason: '${slot.type} should use newly shortlisted options',
          );
        }
      },
    );

    test(
      'local exercise schema constrains codes and exact daily item count',
      () async {
        const marker = 'Candidates (JSON):\n';
        final client = _CapturingAiTextClient(
          response: '',
          responseBuilder: (messages) {
            final prompt = messages.single.text;
            final start = prompt.lastIndexOf(marker);
            final root =
                jsonDecode(prompt.substring(start + marker.length).trim())
                    as Map<String, dynamic>;
            final rows = root['selectable'] as List;
            final codes = rows
                .cast<Map<String, dynamic>>()
                .map((row) => row['code']! as String)
                .toList(growable: false);
            return jsonEncode({
              'items': [
                {'day': 4, 'exercise_code': codes[0]},
                {'day': 4, 'exercise_code': codes[1]},
              ],
            });
          },
        );
        final result = await AIService(aiClient: client)
            .generateExerciseDayCodeItemsWithSource(
              startDate: DateTime(2026, 10, 20),
              day: 4,
              catalog: catalog,
              usedCodeCounts: const {},
              onBackendInvocation: () async {},
            );

        expect(result.source, PlanGenerationSource.ai);
        expect(
          result.value,
          hasLength(ExerciseTasksAiNormalizer.exercisesPerDay),
        );
        final schema = client.configurations.single.responseJsonSchema!;
        final itemsSchema =
            (schema['properties'] as Map<String, dynamic>)['items']
                as Map<String, dynamic>;
        final itemSchema = itemsSchema['items'] as Map<String, dynamic>;
        final codeSchema =
            (itemSchema['properties'] as Map<String, dynamic>)['exercise_code']
                as Map<String, dynamic>;
        expect(
          itemsSchema['minItems'],
          ExerciseTasksAiNormalizer.exercisesPerDay,
        );
        expect(
          itemsSchema['maxItems'],
          ExerciseTasksAiNormalizer.exercisesPerDay,
        );
        expect((codeSchema['enum'] as List), hasLength(4));
        expect(client.configurations.single.maxOutputTokens, 128);
      },
    );

    test(
      'meal prompt excludes unreviewed candidates without schedule eligibility',
      () {
        final prompt = MealPlanPrompt.generate(
          startDate: DateTime(2026, 6, 18),
          startDay: 1,
          days: 1,
          catalog: [
            _promptMeal(code: 'eligible-meal'),
            _unreviewedCandidateMeal(),
          ],
          usedMealCodeCounts: const {'nabi_vn_candidate': 1},
        );

        expect(prompt, contains('eligible-meal'));
        expect(prompt, isNot(contains('nabi_vn_candidate')));
        expect(prompt, isNot(contains('Món chờ rà soát')));
      },
    );

    test(
      'meal shortlist excludes selectable unclassified rows outside slot eligibility',
      () async {
        const unclassifiedCode = 'selectable_unclassified_not_eligible';
        final candidateCatalog = AiCatalogBundle(
          meals: [
            ...catalog.meals,
            _promptMeal(code: unclassifiedCode),
          ],
          exercises: catalog.exercises,
          scheduleTasks: catalog.scheduleTasks,
        );
        final eligibleCodesByType = {
          for (final slot in MealPlanAiNormalizer.mealSlots)
            slot.type: catalog.meals
                .where((meal) => meal.mealType == slot.type)
                .map((meal) => meal.code)
                .toSet(),
        };
        final client = _CapturingAiTextClient(
          response: '',
          responseBuilder: (messages) => jsonEncode({
            'items': _mealItemsFromPrompt(
              messages.single.text,
              day: 1,
            ).map((item) => item['meal_code']).toList(),
          }),
        );
        final service = AIService(aiClient: client);

        final result = await service.generateMealDayCodeItemsWithSource(
          startDate: DateTime(2026, 10, 20),
          day: 1,
          catalog: candidateCatalog,
          usedCodeCounts: const {},
          eligibleFallbackCodesByType: eligibleCodesByType,
          onBackendInvocation: () async {},
        );

        expect(result.source, PlanGenerationSource.ai);
        expect(client.messages.single.text, isNot(contains(unclassifiedCode)));
        for (final item in result.value) {
          expect(
            eligibleCodesByType[item['meal_type']]?.contains(item['meal_code']),
            isTrue,
          );
        }
      },
    );

    test(
      'invalid backend output is not replaced with local catalog choices',
      () async {
        final candidates = [
          for (var index = 1; index <= 5; index++)
            _unreviewedCandidateMeal(
              code: 'nabi_vn_candidate_$index',
              name: 'Món wellness $index',
            ),
        ];
        final candidateCatalog = AiCatalogBundle(
          meals: [...catalog.meals, ...candidates],
          exercises: catalog.exercises,
          scheduleTasks: catalog.scheduleTasks,
        );
        final eligibleCodesByType = {
          for (final slot in MealPlanAiNormalizer.mealSlots)
            slot.type: candidates.map((meal) => meal.code).toSet(),
        };
        final service = AIService(
          textGenerator: ({required modelName, required prompt}) async => '[]',
        );

        await expectLater(
          service.generateMealDayCodeItemsWithSource(
            startDate: DateTime(2026, 6, 18),
            day: 1,
            catalog: candidateCatalog,
            usedCodeCounts: const {},
            eligibleFallbackCodesByType: eligibleCodesByType,
            onBackendInvocation: () async {},
          ),
          throwsA(isA<AIResponseInvalidException>()),
        );
      },
    );

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
        expect(meals.map((meal) => meal.code).toSet(), hasLength(163));
        for (final meal in meals) {
          expect(_countOccurrences(prompt, '"code":"${meal.code}"'), 1);
          expect(
            prompt,
            contains(
              '"code":"${meal.code}","name":${jsonEncode(meal.mealName)}',
            ),
          );
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

    test('JSON wrapper is compact and forbids display text output', () {
      final prompt = AIJsonPromptBuilder.buildArrayPrompt(
        'Chọn mã kỹ thuật trong danh sách allowed.',
      );

      expect(prompt, contains('Return exactly one JSON object'));
      expect(prompt, contains('"items":[...]'));
      expect(prompt, contains('No markdown or extra text.'));
      expect(prompt, contains('Do not invent codes.'));
      expect(prompt, isNot(contains('"items": {"items":')));
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
      expect(result.message, contains('Dịch vụ AI của Nabi'));
      expect(result.modelName, 'fake-model');
    });

    test('fails safely when the backend model is unavailable', () async {
      late AIConnectionCheckResult result;

      final logs = await _captureDebugPrint(() async {
        final service = AIService(
          modelNames: const [BackendAiTextClient.modelId],
          textGenerator: ({required modelName, required prompt}) async =>
              throw const AiInferenceException(
                status: 'model_unavailable',
                message: 'Dịch vụ AI của NanoBio chưa sẵn sàng.',
              ),
        );

        result = await service.checkConnection(
          perModelTimeout: const Duration(milliseconds: 100),
        );
      });

      expect(result.success, isFalse);
      expect(result.message, 'Dịch vụ AI của NanoBio chưa sẵn sàng.');
      expect(result.modelName, BackendAiTextClient.modelId);
      expect(logs.join('\n'), isNot(contains('API_KEY')));
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

      expect(joined, contains('corr=safe-trace-id'));
      expect(joined, contains('safeMethod.SAFE_STAGE'));
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
        expect(
          await service.sendMessage(message),
          contains('Mình sẽ hỗ trợ bạn'),
        );
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
      expect(modelCalls, [BackendAiTextClient.modelId]);
    });

    test('does not use another model after a backend timeout', () async {
      final modelCalls = <String>[];
      final delays = <Duration>[];
      final service = AIChatService(
        modelNames: const [BackendAiTextClient.modelId],
        random: Random(0),
        delay: (duration) async {
          delays.add(duration);
        },
        textGenerator: ({required modelName, required message}) async {
          modelCalls.add(modelName);
          throw TimeoutException('backend timeout');
        },
      );

      await expectLater(
        service.sendMessage('Tôi căng thẳng'),
        throwsA(isA<AIInferenceTimeoutException>()),
      );

      expect(modelCalls, [BackendAiTextClient.modelId]);
      expect(delays, isEmpty);
    });

    test('throws typed failure when all transient attempts fail', () async {
      final modelCalls = <String>[];
      final service = AIChatService(
        modelNames: const ['primary-model', 'fallback-model'],
        delay: (_) async {},
        textGenerator: ({required modelName, required message}) async {
          modelCalls.add(modelName);
          throw const AiInferenceException(
            status: 'runtime_busy',
            message: 'Local model is temporarily busy.',
          );
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

    test('backend model failure stops chat without local fallback', () async {
      var attempts = 0;
      final service = AIChatService(
        modelNames: const [BackendAiTextClient.modelId],
        textGenerator: ({required modelName, required message}) async {
          attempts++;
          throw const AiInferenceException(
            status: 'model_unavailable',
            message: 'Dịch vụ AI chưa sẵn sàng.',
          );
        },
      );

      await expectLater(
        service.sendMessage('Xin chào'),
        throwsA(isA<AIModelUnavailableException>()),
      );
      expect(attempts, 1);
    });

    test('backend failure is safe without environment configuration', () async {
      var attempts = 0;
      final service = AIChatService(
        delay: (_) async {},
        textGenerator: ({required modelName, required message}) async {
          attempts++;
          throw const AiInferenceException(
            status: 'model_unavailable',
            message: 'Dịch vụ AI chưa sẵn sàng.',
          );
        },
      );

      await expectLater(
        service.sendMessage('Xin chào'),
        throwsA(isA<AIModelUnavailableException>()),
      );
      expect(attempts, 1);
    });

    test(
      'sendMessageStream surfaces a backend timeout without model fallback',
      () async {
        final modelCalls = <String>[];
        final service = AIChatService(
          modelNames: const [BackendAiTextClient.modelId],
          delay: (_) async {},
          textGenerator: ({required modelName, required message}) async {
            modelCalls.add(modelName);
            throw TimeoutException('backend timeout');
          },
        );

        await expectLater(
          service.sendMessageStream('Tôi cần hỗ trợ'),
          throwsA(isA<AIInferenceTimeoutException>()),
        );
        expect(modelCalls, [BackendAiTextClient.modelId]);
      },
    );

    test(
      'sendMessageStream stops when the backend model is unavailable',
      () async {
        var attempts = 0;
        final service = AIChatService(
          modelNames: const [BackendAiTextClient.modelId],
          textGenerator: ({required modelName, required message}) async {
            attempts++;
            throw const AiInferenceException(
              status: 'model_unavailable',
              message: 'Dịch vụ AI chưa sẵn sàng.',
            );
          },
        );

        await expectLater(
          service.sendMessageStream('Xin chào'),
          throwsA(isA<AIModelUnavailableException>()),
        );
        expect(attempts, 1);
      },
    );
  });

  group('AIService chunked generation', () {
    test('meal array uses a constrained JSON items envelope', () async {
      late Map<String, String> expectedCodesByType;
      final client = _CapturingAiTextClient(
        response: '',
        responseBuilder: (messages) {
          final items = _mealItemsFromPrompt(messages.single.text, day: 1);
          expectedCodesByType = {
            for (final item in items)
              item['meal_type']! as String: item['meal_code']! as String,
          };
          final codes = items
              .map((item) => item['meal_code'])
              .toList(growable: false);
          return jsonEncode({
            // Native local runtimes may not honor prefixItems. Keep the same
            // five AI choices but return them in a different order so the
            // slot matcher must map each code back to its eligible type.
            'items': [...codes.skip(1), codes.first],
          });
        },
      );
      final eligibleCodesByType = {
        for (final slot in MealPlanAiNormalizer.mealSlots)
          slot.type: catalog.meals
              .where((meal) => meal.mealType == slot.type)
              .map((meal) => meal.code)
              .toSet(),
      };
      final service = AIService(
        modelNames: const ['fake-local-model'],
        aiClient: client,
      );

      final result = await service.generateMealDayCodeItemsWithSource(
        startDate: DateTime(2026, 10, 20),
        day: 1,
        catalog: catalog,
        usedCodeCounts: const {},
        eligibleFallbackCodesByType: eligibleCodesByType,
        onBackendInvocation: () async {},
      );

      expect(result.source, PlanGenerationSource.ai);
      expect(result.value, hasLength(MealPlanAiNormalizer.mealsPerDay));
      for (final item in result.value) {
        expect(
          item['meal_code'],
          expectedCodesByType[item['meal_type']],
          reason: 'AI choices must be assigned to their eligible slot',
        );
      }
      expect(
        client.configurations.single.responseFormat,
        AiResponseFormat.json,
      );
      final schema = client.configurations.single.responseJsonSchema!;
      final itemsSchema =
          (schema['properties'] as Map<String, dynamic>)['items']
              as Map<String, dynamic>;
      final prefixItems = itemsSchema['prefixItems'] as List;
      expect(itemsSchema['minItems'], MealPlanAiNormalizer.mealsPerDay);
      expect(itemsSchema['maxItems'], MealPlanAiNormalizer.mealsPerDay);
      expect(prefixItems, hasLength(MealPlanAiNormalizer.mealsPerDay));
      expect(itemsSchema.containsKey('items'), isFalse);
      expect(itemsSchema.containsKey('uniqueItems'), isFalse);
      for (
        var index = 0;
        index < MealPlanAiNormalizer.mealSlots.length;
        index++
      ) {
        final slot = MealPlanAiNormalizer.mealSlots[index];
        final codeSchema = prefixItems[index] as Map<String, dynamic>;
        final mealCodes = codeSchema['enum'] as List;
        expect(codeSchema['type'], 'string');
        expect(mealCodes, isNotEmpty, reason: slot.type);
        expect(mealCodes, hasLength(2), reason: slot.type);
      }
      expect(
        client.messages.single.text,
        startsWith('Return exactly one JSON object'),
      );
      expect(
        client.messages.single.text,
        contains(
          'Use each meal slot exactly once and in this order: '
          'breakfast, morning_snack, lunch, afternoon_snack, dinner.',
        ),
      );
      expect(client.messages.single.text, contains('meal_code strings'));
      expect(client.configurations.single.maxOutputTokens, 256);
      expect(
        client.estimatedTexts.single,
        startsWith('user: Return exactly one JSON object'),
      );
    });

    test(
      'custom meal proposal has a bounded schema and no catalog payload',
      () async {
        final prompts = <String>[];
        var backendInvocations = 0;
        final service = AIService(
          modelNames: const ['fake-model'],
          textGenerator: ({required modelName, required prompt}) async {
            prompts.add(prompt);
            return jsonEncode([
              {
                'meal_type': 'breakfast',
                'meal_name': 'Cháo yến mạch',
                'description': 'Món nóng dễ chuẩn bị.',
                'ingredients': ['yến mạch', 'nước'],
                'serving_size': '1 bát',
                'cooking_steps': ['Nấu chín', 'Dọn ra bát'],
              },
            ]);
          },
        );

        final result = await service.generateCustomMealProposalWithSource(
          day: 1,
          mealType: 'breakfast',
          personalization: const {
            'goals': ['balanced_nutrition'],
          },
          onBackendInvocation: () async => backendInvocations++,
        );

        expect(result.source, PlanGenerationSource.ai);
        expect(result.value.keys.toSet(), {
          'meal_type',
          'meal_name',
          'description',
          'ingredients',
          'serving_size',
          'cooking_steps',
        });
        expect(backendInvocations, 1);
        expect(prompts.single, contains('[]'));
        expect(prompts.single, contains('balanced_nutrition'));
        expect(prompts.single, isNot(contains('br_oat_egg')));
      },
    );

    test(
      'custom meal proposal reports incomplete or extra fields safely',
      () async {
        var backendInvocations = 0;
        final service = AIService(
          modelNames: const ['fake-model'],
          textGenerator: ({required modelName, required prompt}) async =>
              jsonEncode([
                {
                  'meal_type': 'breakfast',
                  'meal_name': 'Cháo yến mạch',
                  'description': 'Món nóng dễ chuẩn bị.',
                  'ingredients': ['yến mạch', 'nước'],
                  'serving_size': '1 bát',
                  'cooking_steps': ['Nấu chín', 'Dọn ra bát'],
                  'calories': 0,
                },
              ]),
        );

        await expectLater(
          service.generateCustomMealProposalWithSource(
            day: 1,
            mealType: 'breakfast',
            onBackendInvocation: () async => backendInvocations++,
          ),
          throwsA(isA<AIResponseInvalidException>()),
        );
        expect(backendInvocations, AIRetryPolicy.maxAttemptsPerRequest);
      },
    );

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
      expect(prompts.single, contains('Days 3-3'));
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
      expect(prompts.single, contains('Days 4-4'));
    });

    test(
      'meal day reports invalid backend output without local fallback',
      () async {
        var backendInvocations = 0;
        final service = AIService(
          modelNames: const ['fake-model'],
          catalogLoader: () async => catalog,
          textGenerator: ({required modelName, required prompt}) async => '[]',
        );

        await expectLater(
          service.generateMealDayCodeItemsWithSource(
            startDate: DateTime(2026, 6, 18),
            day: 3,
            catalog: catalog,
            usedCodeCounts: const {},
            onBackendInvocation: () async => backendInvocations++,
          ),
          throwsA(isA<AIResponseInvalidException>()),
        );
        expect(backendInvocations, AIRetryPolicy.maxAttemptsPerRequest);
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
          expect(prompt, contains('Select only ${slot.type}'));
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

    test('slot AI output outside the eligible subset fails closed', () async {
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

      await expectLater(
        service.generateMealSlotCodeItemWithSource(
          startDate: DateTime(2026, 6, 18),
          day: 2,
          mealType: slot.type,
          catalog: catalog,
          usedCodeCounts: const {},
          dayMealCodes: const {},
          eligibleFallbackCodesByType: {slot.type: const {}},
          onBackendInvocation: () async {},
        ),
        throwsStateError,
      );
    });

    test(
      'active unreviewed candidate is rejected without local fallback',
      () async {
        final safeMeal = catalog.meals.firstWhere(
          (meal) => meal.mealType == 'breakfast',
        );
        final candidate = _unreviewedCandidateMeal();
        final candidateCatalog = AiCatalogBundle(
          meals: [...catalog.meals, candidate],
          exercises: catalog.exercises,
          scheduleTasks: catalog.scheduleTasks,
        );
        final service = AIService(
          modelNames: const ['fake-model'],
          catalogLoader: () async => candidateCatalog,
          textGenerator: ({required modelName, required prompt}) async {
            expect(prompt, isNot(contains(candidate.code)));
            return jsonEncode([
              {'day': 2, 'meal_type': 'breakfast', 'meal_code': candidate.code},
            ]);
          },
        );

        await expectLater(
          service.generateMealSlotCodeItemWithSource(
            startDate: DateTime(2026, 6, 18),
            day: 2,
            mealType: 'breakfast',
            catalog: candidateCatalog,
            usedCodeCounts: const {},
            dayMealCodes: const {},
            eligibleFallbackCodesByType: {
              'breakfast': {safeMeal.code},
            },
            onBackendInvocation: () async {},
          ),
          throwsA(isA<AIResponseInvalidException>()),
        );
      },
    );

    test(
      'split meal generation reports backend failure without local choice',
      () async {
        var backendInvocations = 0;
        final service = AIService(
          modelNames: const ['fake-model'],
          catalogLoader: () async => catalog,
          textGenerator: ({required modelName, required prompt}) async => '[]',
        );

        await expectLater(
          service.generateMealSlotCodeItemWithSource(
            startDate: DateTime(2026, 6, 18),
            day: 2,
            mealType: 'breakfast',
            catalog: catalog,
            usedCodeCounts: const {},
            dayMealCodes: const {},
            onBackendInvocation: () async => backendInvocations++,
          ),
          throwsA(isA<AIResponseInvalidException>()),
        );
        expect(backendInvocations, AIRetryPolicy.maxAttemptsPerRequest);
      },
    );

    test(
      'invalid meal output does not create a local catalog fallback',
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
          throwsA(isA<AIResponseInvalidException>()),
        );
      },
    );

    test('exercise day reports backend error without local fallback', () async {
      final service = AIService(
        modelNames: const ['fake-model'],
        catalogLoader: () async => catalog,
        textGenerator: ({required modelName, required prompt}) async {
          throw const AiInferenceException(
            status: 'runtime_error',
            message: 'Backend service unavailable.',
          );
        },
      );

      await expectLater(
        service.generateExerciseDayCodeItemsWithSource(
          startDate: DateTime(2026, 6, 18),
          day: 4,
          catalog: catalog,
          usedCodeCounts: const {},
          onBackendInvocation: () async {},
        ),
        throwsA(isA<AIOverloadedException>()),
      );
    });

    test('exercise backend failure does not generate a local plan', () async {
      final eligibleCodes = AiCatalogSeedData.exercises
          .take(2)
          .map((exercise) => exercise.code)
          .toSet();
      final usedCodeCounts = {for (final code in eligibleCodes) code: 2};
      final service = AIService(
        modelNames: const ['fake-model'],
        catalogLoader: () async => catalog,
        textGenerator: ({required modelName, required prompt}) async {
          throw const AiInferenceException(
            status: 'runtime_error',
            message: 'Backend service unavailable.',
          );
        },
      );

      await expectLater(
        service.generateExerciseDayCodeItemsWithSource(
          startDate: DateTime(2026, 6, 18),
          day: 5,
          catalog: catalog,
          usedCodeCounts: usedCodeCounts,
          eligibleFallbackCodes: eligibleCodes,
          onBackendInvocation: () async {},
        ),
        throwsA(isA<AIOverloadedException>()),
      );
    });

    test('local runtime errors retry within the selected model', () async {
      final modelCalls = <String>[];
      var backendInvocations = 0;
      final service = AIService(
        modelNames: const ['first-model', 'fallback-model'],
        catalogLoader: () async => catalog,
        delay: (_) async {},
        textGenerator: ({required modelName, required prompt}) async {
          modelCalls.add(modelName);
          throw const AiInferenceException(
            status: 'runtime_busy',
            message: 'Local inference is busy.',
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
      expect(prompts.single, contains('Days 1-7'));
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

        expect(joined, contains('corr=meal-plan-'));
        expect(joined, contains('[generateMealPlan.START]'));
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
      'meal generation stops when a backend chunk exhausts retries',
      () async {
        var call = 0;
        final service = AIService(
          modelNames: const ['fake-model'],
          catalogLoader: () async => catalog,
          textGenerator: ({required modelName, required prompt}) async {
            call++;
            if (call >= 2) {
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
          throwsA(isA<AIResponseInvalidException>()),
        );
        expect(call, 1 + AIRetryPolicy.maxAttemptsPerRequest);
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
          throwsA(isA<AIResponseInvalidException>()),
        );
      });
      final joined = logs.join('\n');

      expect(joined, contains('MEAL_CHUNK_FAILED'));
      expect(joined, contains('errorType'));
      expect(joined, contains('AIResponseInvalidException'));
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
      expect(joined, contains('modelAttempt=1'));
      expect(joined, contains('totalAttempt=1'));
      expect(joined, contains('transient=true'));
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
      'backend model failure never falls back to local AI for a plan',
      () async {
        var attempts = 0;
        final service = AIService(
          modelNames: const [BackendAiTextClient.modelId],
          catalogLoader: () async => catalog,
          delay: (_) async {},
          textGenerator: ({required modelName, required prompt}) async {
            attempts++;
            throw const AiInferenceException(
              status: 'model_unavailable',
              message: 'Dịch vụ AI chưa sẵn sàng.',
            );
          },
        );

        await expectLater(
          service.generateMealPlan(
            healthData: const _FakeHealthData(),
            userId: 'u1',
            startDate: DateTime(2026, 6, 18),
            days: 1,
          ),
          throwsA(isA<AiInferenceException>()),
        );
        expect(attempts, 1);
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
          [BackendAiTextClient.modelId],
        );
      },
    );

    test('prioritizes primary, fallback, overflow, and de-duplicates', () {
      expect(
        AIModelCandidates.resolve(
          primaryModel: ' local-custom ',
          fallbackModelsCsv: 'local-small, local-custom, local-medium, ',
          overflowModelsCsv: 'local-large, local-medium, local-very-large',
        ),
        [
          'local-custom',
          'local-small',
          'local-medium',
          'local-large',
          'local-very-large',
          BackendAiTextClient.modelId,
        ],
      );
    });

    test('uses default fallback when fallback csv is blank', () {
      expect(
        AIModelCandidates.resolve(
          primaryModel: 'local-custom',
          fallbackModelsCsv: ' , ',
        ),
        ['local-custom', BackendAiTextClient.modelId],
      );
    });
  });

  group('AIChatModelCandidates', () {
    test('uses the backend model identifier when chat config is absent', () {
      expect(
        AIChatModelCandidates.resolve(
          primaryModel: null,
          fallbackModelsCsv: null,
        ),
        [BackendAiTextClient.modelId],
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
          const AiInferenceException(
            status: 'runtime_busy',
            message: 'Selected model is busy.',
          ),
        ),
        isTrue,
      );
      expect(
        AIRetryPolicy.isTransient(
          const AiInferenceException(
            status: 'runtime_error',
            message: 'Selected model returned a transient error.',
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
  TerminalLogSink.setTestWriter(logs.add);

  try {
    await body();
  } finally {
    debugPrint = previousDebugPrint;
    TerminalLogSink.setTestWriter(null);
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
    cookingSteps: const ['Nấu chín'],
    servingSize: '1 bát',
    allergenTags: const ['trứng'],
    avoidConditionTags: const ['đái tháo đường'],
    nutritionStatus: 'approved',
    verifiedNutrients: const {'energy_kcal': 420},
    nutritionEvidenceSource: 'test-source',
    nutritionEvidenceDate: '2026-10-16',
    nutritionEvidenceVersion: 'v1',
    constraintMetadataStatus: 'approved',
    allergenEvidenceSource: '',
    allergenVerificationStatus: 'unknown',
    metadataStatus: 'approved',
    isPlanEligible: true,
    sourceName: '',
    sourceHash: '',
    isActive: isActive,
    createdAt: '2026-06-18T00:00:00Z',
    updatedAt: '2026-06-18T00:00:00Z',
  );
}

MealCatalogItemModel _unreviewedCandidateMeal({
  String code = 'nabi_vn_candidate',
  String name = 'Món chờ rà soát',
}) => MealCatalogItemModel(
  code: code,
  mealType: 'unclassified',
  mealName: name,
  description: 'Mô tả chưa xác minh',
  cookingInstructions: 'Bước nấu chưa duyệt',
  calories: 350,
  protein: 12,
  carbs: 40,
  fat: 10,
  fiber: 5,
  waterMl: 0,
  nutritionStatus: 'estimated_unverified',
  nutritionEvidenceSource: '',
  ingredients: const ['nguyên liệu chưa rà soát'],
  cookingSteps: const ['Bước chưa rà soát'],
  servingSize: '1 phần chưa xác minh',
  constraintMetadataStatus: 'awaiting_professional_review',
  metadataStatus: 'ai_generated_needs_review',
  isPlanEligible: false,
  sourceName: MealCatalogItemModel.unreviewedWellnessCandidateSourceName,
  sourceHash: List.filled(64, 'b').join(),
  allergenVerificationStatus: 'unknown',
  isActive: true,
  createdAt: '2026-10-16T00:00:00Z',
  updatedAt: '2026-10-16T00:00:00Z',
);

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
      mealName: '${slot.type} ${List.filled(7000, 'x').join()}',
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

List<Map<String, Object?>> _mealItemsFromPrompt(
  String prompt, {
  required int day,
}) {
  const marker = 'Candidates (JSON):\n';
  final catalogStart = prompt.lastIndexOf(marker);
  final rows =
      jsonDecode(prompt.substring(catalogStart + marker.length).trim()) as List;
  final codeByType = <String, String>{};
  for (final row in rows.cast<Map<String, dynamic>>()) {
    final type = row['meal_type']?.toString();
    final code = row['code']?.toString();
    if (type != null && code != null) codeByType.putIfAbsent(type, () => code);
  }
  return [
    for (final slot in MealPlanAiNormalizer.mealSlots)
      {'day': day, 'meal_type': slot.type, 'meal_code': codeByType[slot.type]},
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

class _CapturingAiTextClient implements AiTextClient, AiContextAwareClient {
  _CapturingAiTextClient({required this.response, this.responseBuilder});

  final String response;
  final String Function(List<AiMessage> messages)? responseBuilder;
  final configurations = <AiGenerationConfig>[];
  final messages = <AiMessage>[];
  final estimatedTexts = <String>[];

  @override
  Future<int> selectedContextSize() async => 2048;

  @override
  Future<int> estimateTokens(String text) async {
    estimatedTexts.add(text);
    return 100;
  }

  @override
  Future<String> generateText({
    required String model,
    required List<AiMessage> messages,
    required AiGenerationConfig generationConfig,
    String? systemInstruction,
  }) async {
    this.messages.addAll(messages);
    configurations.add(generationConfig);
    return responseBuilder?.call(messages) ?? response;
  }

  @override
  Stream<String> streamText({
    required String model,
    required List<AiMessage> messages,
    required AiGenerationConfig generationConfig,
    String? systemInstruction,
  }) async* {
    this.messages.addAll(messages);
    configurations.add(generationConfig);
    yield responseBuilder?.call(messages) ?? response;
  }
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
