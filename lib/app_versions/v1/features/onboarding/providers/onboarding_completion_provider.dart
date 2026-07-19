import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nano_app/app_versions/v1/services/ai/ai_generation_result.dart';

class OnboardingInitialPlanException implements Exception {
  static const userMessage =
      'NaBi đã lưu hồ sơ, nhưng chưa thể tạo lịch cá nhân đầu tiên lúc này. Bạn thử lại sau một chút nhé.';

  final String message;

  const OnboardingInitialPlanException([this.message = userMessage]);

  @override
  String toString() => message;
}

class OnboardingCompletionResult {
  final bool generatedInitialPlan;
  final PlanGenerationSource generationSource;

  const OnboardingCompletionResult._({
    required this.generatedInitialPlan,
    this.generationSource = PlanGenerationSource.unknown,
  });

  const OnboardingCompletionResult.generatedInitialPlan({
    PlanGenerationSource generationSource = PlanGenerationSource.unknown,
  }) : this._(generatedInitialPlan: true, generationSource: generationSource);

  const OnboardingCompletionResult.skipped()
    : this._(generatedInitialPlan: false);
}

typedef OnboardingCompletionCallback =
    Future<OnboardingCompletionResult> Function();

final onboardingCompletionCallbackProvider =
    Provider<OnboardingCompletionCallback>((ref) {
      return () async => const OnboardingCompletionResult.skipped();
    });
