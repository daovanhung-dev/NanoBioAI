import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/widgets/conditions_step.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/widgets/goals_step.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/widgets/onboarding_compact_ui.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/widgets/onboarding_stitch_components.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/providers/onboarding_provider.dart';
import 'package:nano_app/core/theme/theme.dart';

void main() {
  testWidgets(
    'weight goals replace each other while compatible goals remain selected',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(body: GoalsStep()),
          ),
        ),
      );

      await _tapOption(tester, 'Giữ cân');
      await _tapOption(tester, 'Ngủ ngon hơn');
      await _tapOption(tester, 'Giảm cân');
      expect(container.read(onboardingProvider).goals, [
        'sleep_better',
        'lose_weight',
      ]);
      await _tapOption(tester, 'Tăng cân');

      expect(container.read(onboardingProvider).goals, [
        'sleep_better',
        'gain_weight',
      ]);
      expect(find.text('2 mục tiêu đã chọn'), findsOneWidget);
      expect(_goalSelected(tester, 'lose_weight'), isFalse);
      expect(_goalSelected(tester, 'gain_weight'), isTrue);

      await _tapOption(tester, 'Tăng cân');
      expect(container.read(onboardingProvider).goals, ['sleep_better']);
      expect(find.text('1 mục tiêu đã chọn'), findsOneWidget);
    },
  );

  testWidgets(
    'weight conditions replace each other and preserve other conditions',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(body: ConditionsStep()),
          ),
        ),
      );

      await _tapCondition(tester, 'Thừa cân');
      await _tapCondition(tester, 'Căng thẳng');
      await _tapCondition(tester, 'Gầy, khó tăng cân');

      final conditions = container.read(onboardingProvider).conditions;
      expect(conditions, containsAll(['stress', 'underweight']));
      expect(conditions, isNot(contains('overweight')));
      expect(find.text('Đã chọn: 2'), findsOneWidget);
      expect(_conditionSelected(tester, 'overweight'), isFalse);
      expect(_conditionSelected(tester, 'underweight'), isTrue);

      await _tapCondition(tester, 'Gầy, khó tăng cân');
      expect(container.read(onboardingProvider).conditions, ['stress']);

      await _tapCondition(tester, 'Không có vấn đề đặc biệt');
      expect(container.read(onboardingProvider).conditions, [
        'no_special_issue',
      ]);
      await _tapCondition(tester, 'Thừa cân');
      expect(container.read(onboardingProvider).conditions, ['overweight']);
    },
  );
}

Future<void> _tapCondition(WidgetTester tester, String label) async {
  await _tapOption(tester, label);
}

bool _goalSelected(WidgetTester tester, String code) => tester
    .widgetList<OnboardingChoiceTile>(find.byType(OnboardingChoiceTile))
    .singleWhere((tile) => tile.option.code == code)
    .selected;

bool _conditionSelected(WidgetTester tester, String code) => tester
    .widgetList<OnboardingChoiceRow>(find.byType(OnboardingChoiceRow))
    .singleWhere((row) => row.option.code == code)
    .selected;

Future<void> _tapOption(WidgetTester tester, String label) async {
  final finder = find.text(label);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
