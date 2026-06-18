import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:nano_app/core/interfaces/health_data_interface.dart';
import 'package:nano_app/features/daily_health_tracking/domain/entities/daily_health_profile_entity.dart';
import 'package:nano_app/services/ai/ai_exceptions.dart';
import 'package:nano_app/services/ai/ai_json_prompt_builder.dart';
import 'package:nano_app/services/ai/ai_service.dart';
import 'package:nano_app/services/ai/ai_vietnamese_text_validator.dart';
import 'package:nano_app/services/ai/prompts/exercise_tasks_prompt.dart';
import 'package:nano_app/services/ai/prompts/meal_plan_prompt.dart';

void main() {
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

  group('AI prompts', () {
    test(
      'meal prompt uses Vietnamese instructions and preserves schema keys',
      () {
        final prompt = MealPlanPrompt.generate(
          healthData: const _FakeHealthData(),
          startDate: DateTime(2026, 6, 18),
          days: 7,
        );

        expect(prompt, contains('Bạn là chuyên gia dinh dưỡng.'));
        expect(prompt, contains('"meal_type": "breakfast"'));
        expect(prompt, contains('"cooking_instructions"'));
        expect(prompt, isNot(contains('Ban la')));
        expect(prompt, isNot(contains('khong')));
        expect(prompt, isNot(contains('Tra ve')));
        expect(prompt, isNot(_containsMojibake));
      },
    );

    test(
      'exercise prompt uses Vietnamese instructions and preserves schema keys',
      () {
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
          days: 7,
        );

        expect(prompt, contains('Bạn là huấn luyện viên sức khỏe cá nhân.'));
        expect(prompt, contains('"schedule_date"'));
        expect(prompt, contains('"target_value"'));
        expect(prompt, isNot(contains('Ban la')));
        expect(prompt, isNot(contains('khong')));
        expect(prompt, isNot(contains('Tra ve')));
        expect(prompt, isNot(_containsMojibake));
      },
    );

    test('JSON wrapper is Vietnamese and avoids English-only commands', () {
      final prompt = AIJsonPromptBuilder.buildArrayPrompt(
        'Tạo dữ liệu bằng tiếng Việt có dấu.',
      );

      expect(prompt, contains('Chỉ trả về một mảng JSON hợp lệ.'));
      expect(prompt, contains('Không viết giải thích.'));
      expect(prompt, isNot(contains('Return ONLY')));
      expect(prompt, isNot(contains('Rules')));
      expect(prompt, isNot(contains('No markdown')));
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
