import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingInitialPlanException implements Exception {
  static const userMessage =
      'NaBi đã lưu hồ sơ, nhưng chưa thể tạo lịch cá nhân đầu tiên lúc này. Bạn thử lại sau một chút nhé.';

  const OnboardingInitialPlanException();

  @override
  String toString() => userMessage;
}

class OnboardingCompletionResult {
  final bool generatedInitialPlan;

  const OnboardingCompletionResult._({required this.generatedInitialPlan});

  const OnboardingCompletionResult.generatedInitialPlan()
    : this._(generatedInitialPlan: true);

  const OnboardingCompletionResult.skipped()
    : this._(generatedInitialPlan: false);
}

typedef OnboardingCompletionCallback =
    Future<OnboardingCompletionResult> Function();

final onboardingCompletionCallbackProvider =
    Provider<OnboardingCompletionCallback>((ref) {
      return () async => const OnboardingCompletionResult.skipped();
    });
