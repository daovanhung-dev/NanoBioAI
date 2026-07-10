import '../domain/nabi_animation_type.dart';
import '../domain/nabi_view_context.dart';

abstract final class NabiViewAnimationMapper {
  const NabiViewAnimationMapper._();

  static NabiAnimationType fromView(NabiViewContext context) {
    return switch (context) {
      NabiViewContext.app => NabiAnimationType.idle,
      NabiViewContext.onboarding => NabiAnimationType.greeting,
      NabiViewContext.dashboard => NabiAnimationType.idle,
      NabiViewContext.aiChat => NabiAnimationType.listening,
      NabiViewContext.mealPlan => NabiAnimationType.thinking,
      NabiViewContext.exercise => NabiAnimationType.cheering,
      NabiViewContext.reminder => NabiAnimationType.reminder,
      NabiViewContext.profile => NabiAnimationType.idle,
      NabiViewContext.membership => NabiAnimationType.membership,
      NabiViewContext.errorEmpty => NabiAnimationType.sad,
      NabiViewContext.criticalAlert => NabiAnimationType.error,
      NabiViewContext.emotionalSupport => NabiAnimationType.sad,
    };
  }

  static NabiViewContext fromRoute(String? route) {
    final path = (route ?? '').toLowerCase();
    if (path.contains('ai-chat') || path.contains('chat')) {
      return NabiViewContext.aiChat;
    }
    if (path.contains('onboarding') || path.contains('/start')) {
      return NabiViewContext.onboarding;
    }
    if (path.contains('meal') || path.contains('nutrition')) {
      return NabiViewContext.mealPlan;
    }
    if (path.contains('exercise') || path.contains('workout')) {
      return NabiViewContext.exercise;
    }
    if (path.contains('schedule') ||
        path.contains('reminder') ||
        path.contains('task')) {
      return NabiViewContext.reminder;
    }
    if (path.contains('profile') || path.contains('settings')) {
      return NabiViewContext.profile;
    }
    if (path.contains('payment') ||
        path.contains('membership') ||
        path.contains('premium')) {
      return NabiViewContext.membership;
    }
    if (path.contains('error') || path.contains('empty')) {
      return NabiViewContext.errorEmpty;
    }
    if (path.contains('dashboard') || path == '/' || path.contains('home')) {
      return NabiViewContext.dashboard;
    }
    return NabiViewContext.app;
  }

  static NabiAnimationType animationForRoute(String? route) {
    return fromView(fromRoute(route));
  }
}
