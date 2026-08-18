import 'package:nano_app/core/access/local_subject_resolver.dart';
import 'package:nano_app/core/storage/localdb/app_prefs.dart';
import 'package:nano_app/services/supabase/auth/current_auth_user.dart';

import '../../data/datasources/daily_routine_preferences_local_datasource.dart';
import '../entities/daily_routine_preferences.dart';
import 'daily_routine_preferences_repository.dart';

typedef DailyRoutineSubjectIdResolver = Future<String> Function();

class DailyRoutinePreferencesRepositoryImpl
    implements DailyRoutinePreferencesRepository {
  final DailyRoutinePreferencesLocalDatasource datasource;
  final DailyRoutineSubjectIdResolver resolveSubjectId;

  const DailyRoutinePreferencesRepositoryImpl({
    required this.datasource,
    this.resolveSubjectId = _defaultResolveSubjectId,
  });

  static Future<String> _defaultResolveSubjectId() {
    return LocalSubjectResolver(
      currentActorId: currentSupabaseUserIdOrNull,
      pendingGuestUserId: AppPrefs.pendingGuestUserId,
    ).resolve();
  }

  @override
  Future<DailyRoutinePreferences?> loadForUser(String userId) {
    return datasource.loadForUser(userId);
  }

  @override
  Future<DailyRoutinePreferences?> loadForCurrentUser() async {
    return datasource.loadForUser(await resolveSubjectId());
  }

  @override
  Future<void> saveForUser(String userId, DailyRoutinePreferences preferences) {
    return datasource.saveForUser(userId, preferences);
  }

  @override
  Future<void> saveForCurrentUser(DailyRoutinePreferences preferences) async {
    await datasource.saveForUser(await resolveSubjectId(), preferences);
  }
}
