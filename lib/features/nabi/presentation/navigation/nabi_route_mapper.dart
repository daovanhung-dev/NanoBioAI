import '../../domain/entities/Nabi_expression.dart';

/// Quy đổi tên đường dẫn sang ngữ cảnh Nabi.
///
/// Các từ khoá bên dưới khớp với các route phổ biến của NanoBio. Khi dự án có
/// route khác, chỉ bổ sung keyword ở đây, không rải điều kiện vào các màn hình.
class NabiRouteMapper {
  const NabiRouteMapper._();

  static NabiContext fromLocation(String location) {
    final path = (Uri.tryParse(location)?.path ?? location).toLowerCase();

    if (path.contains('ai-chat') || path.contains('chat')) {
      return NabiContext.aiChat;
    }
    if (path.contains('onboarding')) return NabiContext.onboarding;
    if (path.contains('calculator') || path.contains('calculation')) {
      return NabiContext.healthCalculation;
    }
    if (path.contains('meal') || path.contains('nutrition')) {
      return NabiContext.mealPlan;
    }
    if (path.contains('exercise') || path.contains('workout')) {
      return NabiContext.exercisePlan;
    }
    if (path.contains('task') ||
        path.contains('schedule') ||
        path.contains('reminder')) {
      return NabiContext.dailyTasks;
    }
    if (path.contains('login') ||
        path.contains('register') ||
        path.contains('auth')) {
      return NabiContext.authentication;
    }
    if (path.contains('error')) return NabiContext.error;
    if (path.contains('dashboard') || path == '/' || path.contains('home')) {
      return NabiContext.dashboard;
    }

    return NabiContext.app;
  }
}
