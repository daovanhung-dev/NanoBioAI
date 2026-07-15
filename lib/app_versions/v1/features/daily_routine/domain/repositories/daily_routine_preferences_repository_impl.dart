import '../../data/datasources/daily_routine_preferences_local_datasource.dart';
import '../entities/daily_routine_preferences.dart';
import 'daily_routine_preferences_repository.dart';

class DailyRoutinePreferencesRepositoryImpl
    implements DailyRoutinePreferencesRepository {
  final DailyRoutinePreferencesLocalDatasource datasource;

  const DailyRoutinePreferencesRepositoryImpl({required this.datasource});

  @override
  Future<DailyRoutinePreferences?> loadForUser(String userId) {
    return datasource.loadForUser(userId);
  }

  @override
  Future<DailyRoutinePreferences?> loadForCurrentUser() async {
    final userId = await datasource.resolveCurrentUserId();
    return userId == null ? null : datasource.loadForUser(userId);
  }

  @override
  Future<void> saveForUser(String userId, DailyRoutinePreferences preferences) {
    return datasource.saveForUser(userId, preferences);
  }

  @override
  Future<void> saveForCurrentUser(DailyRoutinePreferences preferences) async {
    final userId = await datasource.resolveCurrentUserId();
    if (userId == null) throw StateError('Missing current routine user');
    await datasource.saveForUser(userId, preferences);
  }
}
