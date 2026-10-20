import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nano_app/app_versions/v1/services/ai/ai_generation_result.dart';
import 'package:nano_app/app_versions/v1/services/ai/generated_plan_service.dart';

class OnboardingInitialPlanException implements Exception {
  static const userMessage =
      'Nabi đã lưu hồ sơ, nhưng chưa thể tạo lịch cá nhân đầu tiên lúc này. Bạn thử lại sau một chút nhé.';

  final String message;

  const OnboardingInitialPlanException([this.message = userMessage]);

  @override
  String toString() => message;
}

class OnboardingCompletionResult {
  final bool generatedInitialPlan;
  final PlanGenerationSource generationSource;
  final bool awaitingMealApproval;
  final String requestId;
  final GeneratedCustomMealProposal? pendingMealProposal;

  const OnboardingCompletionResult._({
    required this.generatedInitialPlan,
    this.generationSource = PlanGenerationSource.unknown,
    this.awaitingMealApproval = false,
    this.requestId = '',
    this.pendingMealProposal,
  });

  const OnboardingCompletionResult.generatedInitialPlan({
    PlanGenerationSource generationSource = PlanGenerationSource.unknown,
  }) : this._(generatedInitialPlan: true, generationSource: generationSource);

  const OnboardingCompletionResult.skipped()
    : this._(generatedInitialPlan: false);

  const OnboardingCompletionResult.awaitingCustomMeal({
    required String requestId,
    required GeneratedCustomMealProposal proposal,
  }) : this._(
         generatedInitialPlan: false,
         awaitingMealApproval: true,
         requestId: requestId,
         pendingMealProposal: proposal,
       );
}

typedef OnboardingCompletionCallback =
    Future<OnboardingCompletionResult> Function({
      GeneratedPlanProgressCallback? onProgress,
    });

final onboardingCompletionCallbackProvider =
    Provider<OnboardingCompletionCallback>((ref) {
      return ({onProgress}) async => const OnboardingCompletionResult.skipped();
    });
