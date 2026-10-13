import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/widgets/review_step.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/providers/onboarding_completion_provider.dart';

void main() {
  group('onboarding submission error message', () {
    test(
      'explains that the profile is saved when initial plan generation fails',
      () {
        expect(
          onboardingSubmissionErrorMessage(
            const OnboardingInitialPlanException(),
          ),
          OnboardingInitialPlanException.userMessage,
        );
      },
    );

    test('preserves a safe, actionable initial plan failure message', () {
      const message = 'Danh mục hiện chưa đủ dữ liệu đã xác minh.';

      expect(
        onboardingSubmissionErrorMessage(
          const OnboardingInitialPlanException(message),
        ),
        message,
      );
    });
  });
}
