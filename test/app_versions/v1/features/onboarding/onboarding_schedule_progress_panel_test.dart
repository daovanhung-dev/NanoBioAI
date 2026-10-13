import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/widgets/onboarding_schedule_progress_panel.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/providers/onboarding_provider.dart';
import 'package:nano_app/app_versions/v1/services/ai/generated_plan_service.dart';
import 'package:nano_app/core/theme/theme.dart';

void main() {
  testWidgets('shows completion percentage and saved schedule days', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingProvider.overrideWith(_ProgressOnboardingController.new),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: OnboardingScheduleProgressPanel(),
            ),
          ),
        ),
      ),
    );

    expect(find.text('29%'), findsOneWidget);
    expect(find.text('Đã lưu 2 / 7 ngày'), findsOneWidget);
    expect(find.text('Ngày thứ nhất'), findsOneWidget);
    expect(find.text('Ngày thứ hai'), findsOneWidget);
    expect(find.text('Ngày thứ ba'), findsNothing);
  });
}

class _ProgressOnboardingController extends OnboardingController {
  @override
  OnboardingState build() => const OnboardingState(
    initialPlanProgress: GeneratedPlanProgress(totalDays: 7, savedDays: [1, 2]),
  );
}
