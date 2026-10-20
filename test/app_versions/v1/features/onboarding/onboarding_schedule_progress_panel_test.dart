import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/widgets/onboarding_schedule_progress_panel.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/providers/onboarding_provider.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/domain/services/meal_catalog_prefilter.dart';
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
    expect(find.text('Đã lưu 20 / 70 sự kiện'), findsOneWidget);
    expect(find.textContaining('Ngày thứ 1 ('), findsOneWidget);
    expect(find.textContaining('Ngày thứ 2 ('), findsOneWidget);
    expect(find.textContaining('Ngày thứ 3 ('), findsNothing);
    expect(find.text('Chưa lọc'), findsOneWidget);
    expect(find.text('0 / 0 món'), findsNothing);
    expect(
      find.byKey(const ValueKey('filtered-meal-candidates-empty')),
      findsNothing,
    );
  });

  testWidgets('shows filtered meal groups on a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingProvider.overrideWith(
            _FilteredProgressOnboardingController.new,
          ),
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

    expect(find.text('Món còn lại sau lọc'), findsOneWidget);
    expect(find.text('5 / 3163 món'), findsOneWidget);
    expect(find.textContaining('shortlist nhỏ hơn'), findsOneWidget);
    expect(find.text('Sáng · 2'), findsOneWidget);
    expect(find.text('Trưa · 1'), findsOneWidget);
    expect(find.text('Chiều/Tối · 2'), findsOneWidget);
    expect(find.text('Cháo gà'), findsOneWidget);
    expect(
      find.text('Tối thiểu 50 món mỗi khung: Sáng 2 · Trưa 1 · Chiều/Tối 2'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('filtered-meal-general-wellness-note')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not show an empty result while filtering', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingProvider.overrideWith(
            _FilteringProgressOnboardingController.new,
          ),
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

    expect(find.text('0 / 0 món'), findsNothing);
    expect(
      find.text(
        'Đang kiểm tra các món trong danh mục theo nhãn và hồ sơ của bạn.',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('filtered-meal-candidates-empty')),
      findsNothing,
    );
  });

  testWidgets('explains when no meals remain after filtering', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingProvider.overrideWith(
            _EmptyFilteredProgressOnboardingController.new,
          ),
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

    expect(find.text('0 / 3163 món'), findsOneWidget);
    expect(
      find.textContaining('chưa có món đủ dữ liệu đã xác minh phù hợp'),
      findsOneWidget,
    );
  });

  testWidgets('handles large text scale for filtered meal names', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingProvider.overrideWith(
            _FilteredProgressOnboardingController.new,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: const Scaffold(
              body: SingleChildScrollView(
                child: OnboardingScheduleProgressPanel(),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Cháo gà'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _ProgressOnboardingController extends OnboardingController {
  @override
  OnboardingState build() => OnboardingState(
    initialPlanProgress: GeneratedPlanProgress(
      totalDays: 7,
      savedDays: [1, 2],
      totalEvents: 70,
      events: [
        for (var index = 0; index < 20; index++)
          GeneratedPlanEventProgress(
            eventId: 'progress-event-$index',
            day: index < 10 ? 1 : 2,
            time: '${(6 + index % 10).toString().padLeft(2, '0')}:00',
            title: index == 0 ? 'thời gian thức dậy' : 'sự kiện mẫu $index',
            status: 'saved',
          ),
      ],
    ),
  );
}

class _FilteredProgressOnboardingController extends OnboardingController {
  @override
  OnboardingState build() => OnboardingState(
    initialPlanProgress: GeneratedPlanProgress(
      totalDays: 7,
      mealFilterState: GeneratedPlanMealFilterState.complete,
      catalogMealCount: 3163,
      filteredMealCandidates: [
        MealCandidateClassification(
          code: 'breakfast-1',
          name: 'Cháo gà',
          mealType: 'breakfast',
          period: MealSchedulePeriod.morning,
          role: MealScheduleRole.main,
          isGeneralWellnessOnly: true,
        ),
        MealCandidateClassification(
          code: 'morning-snack-1',
          name: 'Sinh tố chuối',
          mealType: 'morning_snack',
          period: MealSchedulePeriod.morning,
          role: MealScheduleRole.side,
        ),
        MealCandidateClassification(
          code: 'lunch-1',
          name: 'Cơm gà',
          mealType: 'lunch',
          period: MealSchedulePeriod.midday,
          role: MealScheduleRole.main,
        ),
        MealCandidateClassification(
          code: 'afternoon-snack-1',
          name: 'Chè đậu xanh',
          mealType: 'afternoon_snack',
          period: MealSchedulePeriod.evening,
          role: MealScheduleRole.side,
        ),
        MealCandidateClassification(
          code: 'dinner-1',
          name: 'Canh rau ngót',
          mealType: 'dinner',
          period: MealSchedulePeriod.evening,
          role: MealScheduleRole.main,
        ),
      ],
    ),
  );
}

class _FilteringProgressOnboardingController extends OnboardingController {
  @override
  OnboardingState build() => const OnboardingState(
    initialPlanProgress: GeneratedPlanProgress.empty(
      totalDays: 7,
      mealFilterState: GeneratedPlanMealFilterState.filtering,
    ),
  );
}

class _EmptyFilteredProgressOnboardingController extends OnboardingController {
  @override
  OnboardingState build() => const OnboardingState(
    initialPlanProgress: GeneratedPlanProgress.empty(
      totalDays: 7,
      mealFilterState: GeneratedPlanMealFilterState.complete,
      catalogMealCount: 3163,
    ),
  );
}
