import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/features/nabi/nabi.dart';

void main() {
  group('NabiViewAnimationMapper', () {
    test('maps primary view contexts to animation types', () {
      expect(
        NabiViewAnimationMapper.fromView(NabiViewContext.onboarding),
        NabiAnimationType.greeting,
      );
      expect(
        NabiViewAnimationMapper.fromView(NabiViewContext.dashboard),
        NabiAnimationType.idle,
      );
      expect(
        NabiViewAnimationMapper.fromView(NabiViewContext.mealPlan),
        NabiAnimationType.thinking,
      );
      expect(
        NabiViewAnimationMapper.fromView(NabiViewContext.exercise),
        NabiAnimationType.cheering,
      );
      expect(
        NabiViewAnimationMapper.fromView(NabiViewContext.aiChat),
        NabiAnimationType.listening,
      );
      expect(
        NabiViewAnimationMapper.fromView(NabiViewContext.membership),
        NabiAnimationType.membership,
      );
    });

    test('maps route paths to expected animation types', () {
      expect(
        NabiViewAnimationMapper.animationForRoute('/onboarding/basic-info'),
        NabiAnimationType.greeting,
      );
      expect(
        NabiViewAnimationMapper.animationForRoute('/dashboard'),
        NabiAnimationType.idle,
      );
      expect(
        NabiViewAnimationMapper.animationForRoute('/meal-plan'),
        NabiAnimationType.thinking,
      );
      expect(
        NabiViewAnimationMapper.animationForRoute('/exercise'),
        NabiAnimationType.cheering,
      );
      expect(
        NabiViewAnimationMapper.animationForRoute('/ai-chat'),
        NabiAnimationType.listening,
      );
      expect(
        NabiViewAnimationMapper.animationForRoute('/payment'),
        NabiAnimationType.membership,
      );
    });
  });
}
