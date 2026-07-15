import '../entities/daily_routine_preferences.dart';

class DailyRoutinePreferencesRequiredException implements Exception {
  static const userMessage =
      'Bạn bổ sung nhịp sinh hoạt trước để Nabi sắp lịch mới đúng giờ hơn nhé.';

  const DailyRoutinePreferencesRequiredException();

  @override
  String toString() => userMessage;
}

abstract class DailyRoutinePreferencesRepository {
  Future<DailyRoutinePreferences?> loadForUser(String userId);

  Future<DailyRoutinePreferences?> loadForCurrentUser();

  Future<void> saveForUser(String userId, DailyRoutinePreferences preferences);

  Future<void> saveForCurrentUser(DailyRoutinePreferences preferences);
}
